/* ============================================================================
   MIGRACION 28 - AJUSTES INCREMENTALES POSTERIORES A LA 26
   ----------------------------------------------------------------------------
   Corrige tres defectos detectados al ejecutar las pruebas funcionales:

   1) PAGOS DE NOMINA BLOQUEADOS (error 547)
      dbo.PayrollPayments.EmployeeId era NOT NULL con FK a dbo.Employees, pero
      usp_RegisterPayrollPayment insertaba el literal '*planilla*' cuando el pago
      es a nivel de planilla. Ningun pago podia registrarse.
      -> EmployeeId pasa a NULL (el FK sigue validando cuando hay empleado) y el
         procedimiento inserta @EmployeeId tal cual.

   2) SALDO ACUMULADO DE CAJA
      vw_MovimientoCajaSaldo ordenaba solo por fecha e identificador aleatorio, y
      sumaba todas las aperturas historicas (al reabrir una caja, el saldo se
      duplicaba). Se ordena por fecha + hora + identificador estable y cada
      apertura reinicia el bloque de saldo. Las filas historicas sin apertura
      parten de 0: el sistema no inventa un saldo inicial que nunca se registro.

   3) RESUMEN DE CAJA
      vw_ResumenCaja sumaba todas las aperturas de la cuenta. Ahora resume el
      ultimo bloque (la ultima sesion abierta) y, si la cuenta solo tiene
      movimientos historicos sin sesion, los resume desde 0.

   4) DIAS Y HORAS DEL BORRADOR DE NOMINA
      usp_CreatePayrollDraft asignaba 15/120 o 30/240 a todos los trabajadores,
      sin importar ingreso, retiro ni tipo de periodo, y pagaba salario completo
      a un catorcenal o a un ingreso a mitad de periodo. Ahora calcula los dias
      efectivos dentro del periodo y del vinculo laboral, con tope segun el tipo
      (15 quincenal, 14 catorcenal, 30 mensual), prorratea el salario mensual
      sobre 30 dias y deja los periodos especiales (aguinaldo, liquidacion) en 0
      para que se calculen con su propia logica.

   No elimina ni reconstruye datos. Solo altera la nulabilidad de una columna,
   regenera procedimientos y vistas, y verifica el resultado al final.
   ============================================================================ */
USE [Instalaciones Raquel];
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

PRINT N'28: respaldo de control (solo conteos, no copia masiva)';
SELECT
    (SELECT COUNT(*) FROM dbo.PayrollPayments) AS PagosAntes,
    (SELECT COUNT(*) FROM dbo.CashMoves)      AS MovimientosCajaAntes,
    (SELECT COUNT(*) FROM dbo.CashSessions)   AS SesionesCajaAntes;
GO

/* ---------------------------------------------------------------------------
   1) PayrollPayments.EmployeeId nullable (pago a nivel de planilla)
   --------------------------------------------------------------------------- */
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.PayrollPayments')
      AND name = N'EmployeeId' AND is_nullable = 0
)
BEGIN
    ALTER TABLE dbo.PayrollPayments ALTER COLUMN EmployeeId NVARCHAR(100) NULL;
    PRINT N'28: PayrollPayments.EmployeeId ahora admite NULL (pago por planilla).';
END
ELSE
    PRINT N'28: PayrollPayments.EmployeeId ya admite NULL.';
GO

/* ---------------------------------------------------------------------------
   2) usp_RegisterPayrollPayment: insertar @EmployeeId sin literal falso
   --------------------------------------------------------------------------- */
/*
   Reordenamiento de usp_RegisterPayrollPayment:
   1. Movimiento de caja (CashMove) primero.
   2. Recibo PayrollPayments despues (tiene FK a CashMoves).
   3. Estado economico de la planilla.
   4. Items y evento de historial.
   La logica de validacion, idempotencia y montos se mantiene intacta.
*/
CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PayrollRunId       NVARCHAR(100),
    @Amount             DECIMAL(19,4),
    @PaymentMethod      NVARCHAR(60),
    @PaymentReference   NVARCHAR(120) = NULL,
    @PaymentDate        DATE = NULL,
    @Notes              NVARCHAR(1000) = NULL,
    @IdempotencyKey     UNIQUEIDENTIFIER = NULL,
    @EmployeeId         NVARCHAR(100) = NULL,
    @ActorId            NVARCHAR(100),
    @ActorName          NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @CalculatedAt DATETIMEOFFSET(3);
    DECLARE @Stale BIT;
    DECLARE @NetTotal DECIMAL(19,4);
    DECLARE @CalcVersion INT;
    DECLARE @Revision VARBINARY(8);

    -- 1. Validaciones de negocio (sin cambios respecto de la migracion 26).

    SELECT
        @CurrentStatus = Status,
        @NetTotal = Net,
        @CalculatedAt = CalculatedAt,
        @Stale = ISNULL(CalculationStale, 0),
        @Revision = Revision,
        @CalcVersion = CalculationVersion
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50529, 'La planilla indicada no existe.', 1;

    IF @Amount IS NULL OR @Amount <= 0
        THROW 50531, 'El monto del pago debe ser mayor que cero.', 1;

    -- Bloqueo de pago sin calculo confirmado ni vigente.
    IF @CalculatedAt IS NULL
        THROW 50589, 'La planilla no tiene un calculo confirmado: no se puede registrar el pago.', 1;

    IF @Stale = 1
        THROW 50590, 'El calculo de la planilla quedo desactualizado. Recalcula y vuelve a aprobar antes de pagar.', 1;

    IF @CurrentStatus NOT IN (N'aprobada', N'pago_registrado')
        THROW 50530, 'Solo se puede registrar pago en planillas que han sido formalmente aprobadas.', 1;

    -- Idempotencia: la misma operacion devuelve el mismo pago confirmado.
    IF @IdempotencyKey IS NOT NULL AND EXISTS (SELECT 1 FROM dbo.PayrollPayments WHERE IdempotencyKey = @IdempotencyKey)
    BEGIN
        SELECT N'repetida' AS Resultado,
               p.PaymentId, p.PayrollRunId, p.Amount, p.PaymentMethod, p.TransactionReference AS PaymentReference,
               p.PaymentDate, p.ConfirmedAt, p.ConfirmedByName, p.IdempotencyKey,
               r.Status AS runStatus, r.ConfirmedPaymentsTotal, r.Net AS netTotal,
               (r.Net - r.ConfirmedPaymentsTotal) AS pendingPayment,
               CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision
        FROM dbo.PayrollPayments AS p
        JOIN dbo.PayrollRuns AS r ON r.PayrollRunId = p.PayrollRunId
        WHERE p.IdempotencyKey = @IdempotencyKey;
        RETURN;
    END;

    DECLARE @AlreadyPaid DECIMAL(19,4) =
        (SELECT ISNULL(SUM(p.Amount), 0) FROM dbo.PayrollPayments AS p WHERE p.PayrollRunId = @PayrollRunId);
    DECLARE @Pending DECIMAL(19,4) = @NetTotal - @AlreadyPaid;

    IF @Pending <= 0
        THROW 50591, 'La planilla ya no tiene saldo pendiente por pagar.', 1;

    IF @Amount > @Pending
        THROW 50592, 'El pago supera el pendiente de la planilla. Registre el neto pendiente restante.', 1;

    DECLARE @MethodKey NVARCHAR(60) = LOWER(LTRIM(RTRIM(ISNULL(@PaymentMethod, N'transferencia'))));
    DECLARE @CashAccount NVARCHAR(30) = CASE WHEN @MethodKey IN (N'efectivo', N'caja') THEN N'caja' ELSE N'banco' END;
    DECLARE @PaymentId NVARCHAR(100) = N'pay-' + LOWER(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''));
    DECLARE @NewPaid DECIMAL(19,4) = @AlreadyPaid + @Amount;
    DECLARE @CashMoveId NVARCHAR(100) = N'cash-nom-' + @PayrollRunId;
    DECLARE @FullyPaid BIT = CASE WHEN @NewPaid >= @NetTotal THEN 1 ELSE 0 END;
    DECLARE @PaymentDateIso NVARCHAR(30) = CONVERT(NVARCHAR(30), ISNULL(@PaymentDate, CAST(SYSUTCDATETIME() AS DATE)), 120);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 2. Movimiento de caja/banco PRIMERO: un solo movimiento por planilla,
        --    con el importe acumulado de los pagos confirmados.
        IF EXISTS (SELECT 1 FROM dbo.CashMoves WHERE CashMoveId = @CashMoveId)
            UPDATE dbo.CashMoves
            SET Amount = @NewPaid,
                Account = @CashAccount,
                Method = @MethodKey,
                MoveType = N'salida',
                Concept = N'Dispersión de nómina ' + @PayrollRunId + N' (pagos confirmados acumulados)',
                OperationKey = N'nomina:' + @PayrollRunId,
                DocumentType = N'nomina',
                DocumentRef = @PayrollRunId,
                ResponsibleAppUserId = @ActorId,
                ResponsibleName = @ActorName,
                MoveDate = CONVERT(DATETIMEOFFSET(3), @PaymentDateIso)
            WHERE CashMoveId = @CashMoveId;
        ELSE
            INSERT INTO dbo.CashMoves (
                CashMoveId, Account, MoveType, Amount, MoveDate, Concept, Method,
                DocumentType, DocumentRef, PayrollRunId,
                ResponsibleAppUserId, ResponsibleName, MoveState, OperationKey, CreatedBy
            )
            VALUES (
                @CashMoveId, @CashAccount, N'salida', @NewPaid,
                CONVERT(DATETIMEOFFSET(3), @PaymentDateIso),
                N'Dispersión de nómina ' + @PayrollRunId + N' (pagos confirmados acumulados)',
                @MethodKey, N'nomina', @PayrollRunId, @PayrollRunId,
                @ActorId, @ActorName, N'confirmado', N'nomina:' + @PayrollRunId, @ActorName
            );


        -- 3. Recibo del pago (ahora el CashMove ya existe).
        INSERT INTO dbo.PayrollPayments (
            PaymentId, PayrollRunId, EmployeeId, Amount, PaymentMethod, TransactionReference,
            PaymentDate, CashMoveId, Notes, ConfirmedAt, ConfirmedByAppUserId, ConfirmedByName,
            CalculationVersion, Status, IdempotencyKey, OperationKey, RequestHash
        )
        VALUES (
            @PaymentId, @PayrollRunId, @EmployeeId, @Amount, @PaymentMethod, @PaymentReference,
            CONVERT(DATE, @PaymentDateIso), @CashMoveId, @Notes,
            TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), @ActorId, @ActorName,
            @CalcVersion, N'confirmado', @IdempotencyKey,
            CASE WHEN @IdempotencyKey IS NULL THEN NULL ELSE N'pago-nomina:' + CAST(@IdempotencyKey AS NVARCHAR(36)) END,
            HASHBYTES('SHA2_256', CONCAT(
                @PayrollRunId, N'|', @Amount, N'|', ISNULL(@PaymentMethod, N''), N'|',
                ISNULL(@PaymentReference, N''), N'|', @PaymentDateIso, N'|', CONVERT(NVARCHAR(20), @Revision)
            ))
        );

        -- 4. Estado economico de la planilla: siempre suma de pagos confirmados.
        UPDATE dbo.PayrollRuns
        SET ConfirmedPaymentsTotal = @NewPaid,
            UpdatedAt = SYSUTCDATETIME()
        WHERE PayrollRunId = @PayrollRunId;

        -- 5. Los items solo se marcan pagados cuando se cubre el neto completo.
        IF @FullyPaid = 1
            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'pagado',
                PaymentMethod = @PaymentMethod,
                PaymentReference = @PaymentReference,
                PaymentConfirmedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
            WHERE PayrollRunId = @PayrollRunId;
        ELSE
            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'pago_parcial'
            WHERE PayrollRunId = @PayrollRunId AND ISNULL(PaymentStatus, N'') <> N'pagado';

        -- 6. Trazabilidad.
        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'pago', @CurrentStatus, @CurrentStatus,
            N'Pago de C$ ' + CAST(@Amount AS NVARCHAR(20)) + N' confirmado. Acumulado C$ '
              + CAST(@NewPaid AS NVARCHAR(20)) + N' de C$ ' + CAST(@NetTotal AS NVARCHAR(20))
              + CASE WHEN @FullyPaid = 1 THEN N' (neto cubierto).' ELSE N' (pago parcial pendiente).' END
        );

        COMMIT TRANSACTION;

        SELECT N'confirmada' AS Resultado,
               @PaymentId AS PaymentId,
               @PayrollRunId AS PayrollRunId,
               @Amount AS Amount,
               @NewPaid AS ConfirmedPaymentsTotal,
               @NetTotal AS netTotal,
               (@NetTotal - @NewPaid) AS pendingPayment,
               @FullyPaid AS fullyPaid,
               @IdempotencyKey AS IdempotencyKey,
               @CashMoveId AS CashMoveId,
               CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision
        FROM dbo.PayrollRuns AS r
        WHERE r.PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* ---------------------------------------------------------------------------
   3) usp_CreatePayrollDraft: dias y horas reales por periodo y vinculo
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_CreatePayrollDraft
    @PayrollRunId   NVARCHAR(100),
    @Period         NVARCHAR(40),
    @PeriodType     NVARCHAR(30),
    @StartDate      DATE,
    @EndDate        DATE,
    @PaymentDate    DATE,
    @Notes          NVARCHAR(MAX) = NULL,
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF EXISTS (
        SELECT 1 FROM dbo.PayrollRuns
        WHERE Period = @Period AND Status <> N'cerrada'
    )
        THROW 50501, 'Ya existe una planilla activa para el mismo periodo.', 1;

    IF @StartDate > @EndDate
        THROW 50502, 'La fecha de inicio no puede ser posterior a la fecha de finalizacion.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.PayrollRuns (
            PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate,
            PaidAt, Actor, ActorUserId, Status, CalculationVersion,
            Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
            OtherDeductionsTotal, AguinaldoProvTotal, VacacionesProvTotal, IndemnizacionProvTotal,
            ConfirmedPaymentsTotal, PendingDiscrepancyTotal,
            PreparedByAppUserId, PreparedAt, Notes
        )
        VALUES (
            @PayrollRunId, @Period, @PeriodType, @StartDate, @EndDate, @PaymentDate,
            TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), @ActorName, @ActorId, N'borrador', 1,
            0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0,
            @ActorId, SYSUTCDATETIME(), @Notes
        );

        -- Poblar trabajadores activos (o retirados dentro del periodo).
        -- Dias efectivos = interseccion entre el periodo y el vinculo laboral,
        -- con tope del tipo de periodo. El salario mensual se prorratea /30.
        INSERT INTO dbo.PayrollRunItems (
            PayrollRunId, EmployeeId, PayrollItemId, PositionSnapshot, AreaSnapshot,
            BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
            OvertimeHours, OvertimeAmount, BonusesAmount, CommissionsAmount,
            VacationDisfruteAmount, OtherTaxableIncome, Gross,
            InssBase, InssLaboral, IrBase, IncomeTax, OtherDeductions, TotalDeductions, Net,
            InssPatronal, Inatec, Aguinaldo, VacacionesProv, IndemnizacionProv, EmployerCost,
            PaymentStatus, PaymentMethod, ReceiptStatus
        )
        SELECT
            @PayrollRunId,
            e.EmployeeId,
            @PayrollRunId + N'-' + e.EmployeeId,
            e.Position,
            e.Area,
            e.Salary,
            w.Days,
            ROUND(w.Days * 8.0, 2),
            ROUND(e.Salary / 30.0 * w.Days, 2),
            0, 0, 0, 0, 0, 0,
            ROUND(e.Salary / 30.0 * w.Days, 2),
            ROUND(e.Salary / 30.0 * w.Days, 2),
            0, 0, 0, 0, 0,
            ROUND(e.Salary / 30.0 * w.Days, 2),
            0, 0, 0, 0, 0,
            ROUND(e.Salary / 30.0 * w.Days, 2),
            N'pendiente', N'transferencia_bancaria', N'no_generado'
        FROM dbo.Employees AS e
        CROSS APPLY (
            SELECT DATEDIFF(
                DAY,
                CASE WHEN e.HireDate IS NULL OR e.HireDate < @StartDate
                     THEN @StartDate ELSE e.HireDate END,
                CASE WHEN e.DismissalDate IS NULL OR e.DismissalDate > @EndDate
                     THEN @EndDate ELSE e.DismissalDate END
            ) + 1 AS RawDays
        ) AS d
        CROSS APPLY (
            SELECT CAST(
                CASE
                    WHEN @PeriodType IN (N'especial_aguinaldo', N'liquidacion') THEN 0
                    WHEN @PeriodType = N'quincenal'
                        THEN CASE WHEN d.RawDays > 15 THEN 15 WHEN d.RawDays < 0 THEN 0 ELSE d.RawDays END
                    WHEN @PeriodType = N'catorcenal'
                        THEN CASE WHEN d.RawDays > 14 THEN 14 WHEN d.RawDays < 0 THEN 0 ELSE d.RawDays END
                    ELSE CASE WHEN d.RawDays > 30 THEN 30 WHEN d.RawDays < 0 THEN 0 ELSE d.RawDays END
                END AS DECIMAL(9,2)
            ) AS Days
        ) AS w
        WHERE (e.EmploymentStatus = N'activo'
               OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate))
          AND (e.HireDate IS NULL OR e.HireDate <= @EndDate);

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'creacion', NULL, N'borrador',
            N'Planilla creada en estado borrador con dias y horas calculados por periodo.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.Gross AS grossTotal, r.Net AS netTotal,
               (SELECT COUNT(1) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
               CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision
        FROM dbo.PayrollRuns r
        WHERE r.PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* ---------------------------------------------------------------------------
   4) vw_MovimientoCajaSaldo: orden estable y saldo por bloque de apertura
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_MovimientoCajaSaldo
AS
WITH Movs AS (
    SELECT
        m.CashMoveId, m.Account, m.MoveType, m.Amount, m.MoveDate, m.MoveTime,
        m.Concept, m.Method, m.DocumentType, m.DocumentRef, m.SaleId, m.PurchaseId,
        m.PayrollRunId, m.SessionId, m.ResponsibleAppUserId, m.ResponsibleName, m.OperationKey,
        ROW_NUMBER() OVER (
            PARTITION BY m.Account
            ORDER BY m.MoveDate,
                     ISNULL(m.MoveTime, CAST('00:00:00' AS TIME(0))),
                     -- La apertura de una sesion siempre precede a sus movimientos,
                     -- incluso si comparten fecha y hora (mismo segundo): si no, el
                     -- bloque de saldo podria empezar en el movimiento equivocado.
                     CASE WHEN m.DocumentType = N'apertura' THEN 0 ELSE 1 END,
                     m.CashMoveId
        ) AS Rn
    FROM dbo.CashMoves AS m
    WHERE m.MoveState = N'confirmado'
),
Bloques AS (
    SELECT v.*,
        MAX(CASE WHEN v.DocumentType = N'apertura' THEN v.Rn END)
            OVER (PARTITION BY v.Account ORDER BY v.Rn ROWS UNBOUNDED PRECEDING) AS Bloque
    FROM Movs AS v
),
Saldos AS (
    SELECT b.*,
        SUM(CASE WHEN b.DocumentType = N'apertura' THEN 0
                 WHEN b.MoveType = N'entrada' THEN b.Amount
                 ELSE -b.Amount END)
            OVER (PARTITION BY b.Account, b.Bloque ORDER BY b.Rn ROWS UNBOUNDED PRECEDING) AS MovimientoAcumulado,
        SUM(CASE WHEN b.DocumentType = N'apertura' THEN b.Amount ELSE 0 END)
            OVER (PARTITION BY b.Account, b.Bloque) AS SaldoBase
    FROM Bloques AS b
)
SELECT
    v.CashMoveId,
    v.Account,
    v.MoveDate,
    v.MoveTime,
    v.MoveType,
    CASE WHEN v.MoveType = N'entrada' THEN v.Amount ELSE NULL END AS Entrada,
    CASE WHEN v.MoveType = N'salida'  THEN v.Amount ELSE NULL END AS Salida,
    ISNULL(v.SaldoBase, 0) + v.MovimientoAcumulado AS SaldoAcumulado,
    v.Concept,
    v.Method,
    v.DocumentType,
    v.DocumentRef,
    v.SaleId,
    v.PurchaseId,
    v.PayrollRunId,
    v.SessionId,
    v.ResponsibleName,
    v.OperationKey
FROM Saldos AS v;
GO

/* ---------------------------------------------------------------------------
   5) vw_ResumenCaja: resumen del ultimo bloque (ultima sesion de la cuenta)
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_ResumenCaja
AS
WITH UltimaSesion AS (
    SELECT x.Account, x.CashSessionId, x.OpeningBalance
    FROM (
        SELECT s.Account, s.CashSessionId, s.OpeningBalance,
               ROW_NUMBER() OVER (
                   PARTITION BY s.Account
                   ORDER BY s.OpenedAt DESC, s.CashSessionId DESC
               ) AS Rn
        FROM dbo.CashSessions AS s
    ) AS x
    WHERE x.Rn = 1
),
Periodo AS (
    SELECT
        u.Account,
        u.OpeningBalance AS SaldoInicial,
        ISNULL(SUM(CASE WHEN m.MoveType = N'entrada'
                         AND ISNULL(m.DocumentType, N'') <> N'apertura'
                        THEN m.Amount ELSE 0 END), 0) AS TotalEntradas,
        ISNULL(SUM(CASE WHEN m.MoveType = N'salida' THEN m.Amount ELSE 0 END), 0) AS TotalSalidas,
        COUNT(m.CashMoveId) AS Movimientos,
        MAX(m.MoveDate) AS UltimoMovimiento
    FROM UltimaSesion AS u
    LEFT JOIN dbo.CashMoves AS m
        ON m.SessionId = u.CashSessionId AND m.MoveState = N'confirmado'
    GROUP BY u.Account, u.OpeningBalance
),
SinSesion AS (
    SELECT
        m.Account,
        CAST(0 AS DECIMAL(19,4)) AS SaldoInicial,
        ISNULL(SUM(CASE WHEN m.MoveType = N'entrada' THEN m.Amount ELSE 0 END), 0) AS TotalEntradas,
        ISNULL(SUM(CASE WHEN m.MoveType = N'salida' THEN m.Amount ELSE 0 END), 0) AS TotalSalidas,
        COUNT(m.CashMoveId) AS Movimientos,
        MAX(m.MoveDate) AS UltimoMovimiento
    FROM dbo.CashMoves AS m
    WHERE m.MoveState = N'confirmado'
      AND m.SessionId IS NULL
      AND NOT EXISTS (SELECT 1 FROM UltimaSesion AS u WHERE u.Account = m.Account)
    GROUP BY m.Account
)
SELECT
    p.Account, p.SaldoInicial, p.TotalEntradas, p.TotalSalidas,
    p.SaldoInicial + p.TotalEntradas - p.TotalSalidas AS SaldoFinal,
    p.Movimientos, p.UltimoMovimiento
FROM Periodo AS p
UNION ALL
SELECT
    s.Account, s.SaldoInicial, s.TotalEntradas, s.TotalSalidas,
    s.SaldoInicial + s.TotalEntradas - s.TotalSalidas,
    s.Movimientos, s.UltimoMovimiento
FROM SinSesion AS s;
GO

/* ---------------------------------------------------------------------------
   6) vw_SaldoSugeridoApertura: saldo a arrastrar al abrir una nueva sesion
   ---------------------------------------------------------------------------
   Caja se trabaja con el saldo del dia anterior: al abrir la sesion del dia, el
   saldo final de la ultima sesion cerrada de esa cuenta se propone como saldo
   inicial (arrastre). El responsable lo confirma o lo ajusta con su conteo.

   Regla del saldo a arrastrar, por cuenta:
     - Si hubo sesiones cerradas: se toma el efectivo CONTADO de la ultima sesion
       cerrada (lo realmente arqueado y contado), en su defecto el esperado.
     - Si no hay sesion cerrada pero hay sesion abierta: su saldo inicial + sus
       movimientos confirmados (saldo vivo de la sesion vigente).
     - Si no hay sesiones (solo movimientos historicos sin sesion): el saldo
       acumulado del ultimo movimiento confirmado; si no hay movimientos, 0.

   Es una SUGERENCIA de solo lectura: no crea ni modifica movimientos. El importe
   real de apertura lo decide y firma el responsable al abrir la caja.
   --------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_SaldoSugeridoApertura
AS
WITH UltimaCerrada AS (
    SELECT x.Account, x.CashSessionId, x.CountedCash, x.ExpectedCash, x.ClosedAt
    FROM (
        SELECT s.Account, s.CashSessionId, s.CountedCash, s.ExpectedCash, s.ClosedAt,
               ROW_NUMBER() OVER (
                   PARTITION BY s.Account
                   ORDER BY ISNULL(s.ClosedAt, s.OpenedAt) DESC, s.CashSessionId DESC
               ) AS Rn
        FROM dbo.CashSessions AS s
        WHERE s.Status = N'cerrada'
    ) AS x
    WHERE x.Rn = 1
),
SesionVigente AS (
    SELECT x.Account, x.CashSessionId, x.OpeningBalance
    FROM (
        SELECT s.Account, s.CashSessionId, s.OpeningBalance,
               ROW_NUMBER() OVER (
                   PARTITION BY s.Account
                   ORDER BY s.OpenedAt DESC, s.CashSessionId DESC
               ) AS Rn
        FROM dbo.CashSessions AS s
        WHERE s.Status = N'abierta'
    ) AS x
    WHERE x.Rn = 1
),
UltimoMovimiento AS (
    SELECT v.Account, v.SaldoAcumulado,
           ROW_NUMBER() OVER (
               PARTITION BY v.Account
               ORDER BY v.MoveDate DESC,
                        ISNULL(v.MoveTime, CAST('00:00:00' AS TIME(0))) DESC,
                        v.CashMoveId DESC
           ) AS Rn
    FROM dbo.vw_MovimientoCajaSaldo AS v
),
Cuentas AS (
    SELECT N'caja' AS Account
    UNION ALL SELECT N'banco'
)
SELECT
    c.Account,
    CASE
        WHEN uc.CashSessionId IS NOT NULL
            THEN ISNULL(uc.CountedCash, uc.ExpectedCash)
        WHEN sv.CashSessionId IS NOT NULL
            THEN sv.OpeningBalance
                 + ISNULL((SELECT SUM(CASE WHEN ISNULL(m.DocumentType, N'') = N'apertura' THEN 0
                                           WHEN m.MoveType = N'entrada' THEN m.Amount
                                           ELSE -m.Amount END)
                           FROM dbo.CashMoves AS m
                           WHERE m.SessionId = sv.CashSessionId
                             AND m.MoveState = N'confirmado'), 0)
        ELSE ISNULL((SELECT um.SaldoAcumulado FROM UltimoMovimiento AS um
                     WHERE um.Account = c.Account AND um.Rn = 1), 0)
    END AS SaldoSugerido,
    CASE
        WHEN uc.CashSessionId IS NOT NULL THEN N'sesion_cerrada'
        WHEN sv.CashSessionId IS NOT NULL THEN N'sesion_abierta'
        ELSE N'sin_sesion'
    END AS Origen,
    uc.CashSessionId AS SesionOrigen,
    uc.ClosedAt AS CerradaEn
FROM Cuentas AS c
LEFT JOIN UltimaCerrada  AS uc ON uc.Account = c.Account
LEFT JOIN SesionVigente  AS sv ON sv.Account = c.Account;
GO

/* ---------------------------------------------------------------------------
   7) Verificacion posterior
   --------------------------------------------------------------------------- */
PRINT N'28: verificacion';

SELECT Account, SaldoSugerido, Origen, SesionOrigen
FROM dbo.vw_SaldoSugeridoApertura
ORDER BY Account;
SELECT
    c.name AS Columna,
    CASE WHEN c.is_nullable = 1 THEN N'NULL permitido' ELSE N'NOT NULL' END AS Nulabilidad
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID(N'dbo.PayrollPayments') AND c.name = N'EmployeeId';

SELECT
    (SELECT COUNT(*) FROM dbo.PayrollPayments) AS PagosDespues,
    (SELECT COUNT(*) FROM dbo.CashMoves)      AS MovimientosCajaDespues,
    (SELECT COUNT(*) FROM dbo.CashSessions)   AS SesionesCajaDespues;

SELECT Account, SaldoInicial, TotalEntradas, TotalSalidas, SaldoFinal, Movimientos
FROM dbo.vw_ResumenCaja
ORDER BY Account;
GO

PRINT N'28: migracion aplicada correctamente.';
GO

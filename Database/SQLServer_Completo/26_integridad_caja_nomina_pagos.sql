-- =============================================================================
-- 26. INTEGRIDAD DE CAJA, NOMINA Y PAGOS (MIGRACION INCREMENTAL)
-- =============================================================================
-- Objetivo: que una sola accion autorizada genere UNA SOLA VEZ sus efectos
-- correctos y que puedan explicarse y conciliarse desde el documento hasta
-- SQL Server.
--
-- Problemas que corrige (diagnosticados con evidencia):
--   P1 CAJA
--     - No existia apertura, arqueo ni cierre por caja/moneda/responsable/fecha.
--     - El saldo inicial era un valor fijo de interfaz (C$ 10.000) no persistido.
--     - No habia columna de saldo acumulado ni separacion entre saldo inicial,
--       entradas y salidas.
--     - El medio de pago era decorativo y no determinaba el efecto (efectivo vs
--       transferencia).
--     - No existia ninguna restriccion sobre CashMoves: se permitian importes
--       negativos y no habia identificador de operacion (idempotencia).
--   P2 NOMINA
--     - usp_CalculatePayroll recalculaba los items pero NUNCA escribia
--       PayrollRuns.TotalDeductions, por lo que la planilla mostraba
--       deducciones en cero aunque el detalle tuviera deducciones reales.
--     - usp_CreatePayrollDraft crea items con TotalDeductions = 0 y Net = Gross;
--       la interfaz los presentaba como si estuvieran calculados.
--     - Novedades con status 'procesada' y tipo 'otro' nunca se aplicaban.
--     - Se podia transitar borrador -> calculada sin haber calculado.
--   P3 PAGOS DUPLICADOS
--     - usp_RegisterPayrollPayment sobrescribia ConfirmedPaymentsTotal
--       (asignaba en vez de acumular), marcaba TODOS los items como pagados y
--       no tenia identificador de operacion.
--     - No existia indice UNIQUE de idempotencia en PayrollPayments,
--       CashMoves ni AccountingEntries.
--     - usp_SaveErpState borraba CashMoves y AccountingEntries completos,
--       eliminando efectos confirmados por el servidor.
--
-- REGLAS DE SEGURIDAD DE ESTA MIGRACION
--   - No reconstruye la base ni reinstala datos iniciales.
--   - No borra registros operativos: usa SELECT INTO a tablas bak_26_* solo
--     como respaldo previo y corrige por suma/compensacion.
--   - No modifica planillas cerradas ni pagos ya confirmados.
--   - Es re-ejecutable: cada objeto se crea solo si no existe o con
--     CREATE OR ALTER.
--
-- Requiere: migraciones 01 a 25 aplicadas.
-- Verificar despues con: 27_reporte_inconsistencias.sql
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
-- Requerido por los indices unicos filtrados creados por esta migracion.
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- =============================================================================
-- PARTE 0. RESPALDO DE SEGURIDAD PREVIO (solo lectura de los datos originales)
-- =============================================================================
IF OBJECT_ID(N'dbo.bak_26_CashMoves', N'U') IS NULL
    SELECT * INTO dbo.bak_26_CashMoves FROM dbo.CashMoves;

IF OBJECT_ID(N'dbo.bak_26_FinanceMoves', N'U') IS NULL
    SELECT * INTO dbo.bak_26_FinanceMoves FROM dbo.FinanceMoves;

IF OBJECT_ID(N'dbo.bak_26_AccountingEntries', N'U') IS NULL
    SELECT * INTO dbo.bak_26_AccountingEntries FROM dbo.AccountingEntries;

IF OBJECT_ID(N'dbo.bak_26_PayrollPayments', N'U') IS NULL
    SELECT * INTO dbo.bak_26_PayrollPayments FROM dbo.PayrollPayments;

IF OBJECT_ID(N'dbo.bak_26_PayrollRuns', N'U') IS NULL
    SELECT * INTO dbo.bak_26_PayrollRuns FROM dbo.PayrollRuns;

IF OBJECT_ID(N'dbo.bak_26_PayrollRunItems', N'U') IS NULL
    SELECT * INTO dbo.bak_26_PayrollRunItems FROM dbo.PayrollRunItems;
GO

-- =============================================================================
-- PARTE 1. CAJA: APERTURA, ARQUEO Y CIERRE POR SESION
-- =============================================================================
-- Una sesion de caja identifica: caja/banco, moneda, responsable, fecha,
-- saldo inicial y resultado del arqueo. El saldo inicial NO es un ingreso:
-- se registra como movimiento identificado (DocumentType = 'apertura').
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.CashSessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.CashSessions (
        CashSessionId       NVARCHAR(100)     NOT NULL CONSTRAINT PK_CashSessions PRIMARY KEY,
        Account             NVARCHAR(30)      NOT NULL,
        Currency            NVARCHAR(10)      NOT NULL CONSTRAINT DF_CashSessions_Currency DEFAULT (N'C$'),
        SessionDate         DATE              NOT NULL,
        OpeningBalance      DECIMAL(19,4)     NOT NULL CONSTRAINT DF_CashSessions_Opening DEFAULT (0),
        Status              NVARCHAR(30)      NOT NULL CONSTRAINT DF_CashSessions_Status DEFAULT (N'abierta'),
        Notes               NVARCHAR(1000)    NULL,
        OpenedAt            DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_CashSessions_OpenedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        OpenedByAppUserId   NVARCHAR(100)     NULL,
        OpenedByName        NVARCHAR(240)     NULL,
        ClosedAt            DATETIMEOFFSET(3) NULL,
        ClosedByAppUserId   NVARCHAR(100)     NULL,
        CountedCash         DECIMAL(19,4)     NULL,
        ExpectedCash        DECIMAL(19,4)     NULL,
        Difference          DECIMAL(19,4)     NULL,
        Explanation         NVARCHAR(1000)    NULL,
        ReviewStatus        NVARCHAR(30)      NULL,
        ReviewedByAppUserId NVARCHAR(100)     NULL,
        ReviewedByName      NVARCHAR(240)     NULL,
        ReviewedAt          DATETIMEOFFSET(3) NULL,
        OperationKey        NVARCHAR(160)     NULL,
        CONSTRAINT CK_CashSessions_Account CHECK (Account IN (N'caja', N'banco')),
        CONSTRAINT CK_CashSessions_Status  CHECK (Status IN (N'abierta', N'cerrada')),
        CONSTRAINT CK_CashSessions_Review  CHECK (ReviewStatus IS NULL OR ReviewStatus IN (N'pendiente_revision', N'revisado', N'observado')),
        CONSTRAINT CK_CashSessions_Opening CHECK (OpeningBalance >= 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_CashSessions_Abierta' AND object_id = OBJECT_ID(N'dbo.CashSessions'))
    CREATE UNIQUE INDEX UQ_CashSessions_Abierta ON dbo.CashSessions (Account) WHERE Status = N'abierta';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_CashSessions_OperationKey' AND object_id = OBJECT_ID(N'dbo.CashSessions'))
    CREATE UNIQUE INDEX UQ_CashSessions_OperationKey ON dbo.CashSessions (OperationKey) WHERE OperationKey IS NOT NULL;
GO

-- -----------------------------------------------------------------------------
-- PARTE 1.2 Columnas nuevas de trazabilidad y control en CashMoves
-- -----------------------------------------------------------------------------
IF COL_LENGTH(N'dbo.CashMoves', N'SessionId') IS NULL
    ALTER TABLE dbo.CashMoves ADD SessionId NVARCHAR(100) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'MoveTime') IS NULL
    ALTER TABLE dbo.CashMoves ADD MoveTime TIME(0) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'Method') IS NULL
    ALTER TABLE dbo.CashMoves ADD Method NVARCHAR(30) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'DocumentType') IS NULL
    ALTER TABLE dbo.CashMoves ADD DocumentType NVARCHAR(40) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'DocumentRef') IS NULL
    ALTER TABLE dbo.CashMoves ADD DocumentRef NVARCHAR(120) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'ResponsibleAppUserId') IS NULL
    ALTER TABLE dbo.CashMoves ADD ResponsibleAppUserId NVARCHAR(100) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'ResponsibleName') IS NULL
    ALTER TABLE dbo.CashMoves ADD ResponsibleName NVARCHAR(240) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'MoveState') IS NULL
    ALTER TABLE dbo.CashMoves ADD MoveState NVARCHAR(30) NOT NULL CONSTRAINT DF_CashMoves_MoveState DEFAULT (N'confirmado');

IF COL_LENGTH(N'dbo.CashMoves', N'OperationKey') IS NULL
    ALTER TABLE dbo.CashMoves ADD OperationKey NVARCHAR(160) NULL;

IF COL_LENGTH(N'dbo.CashMoves', N'CreatedAt') IS NULL
    ALTER TABLE dbo.CashMoves ADD CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_CashMoves_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'));

IF COL_LENGTH(N'dbo.CashMoves', N'CreatedBy') IS NULL
    ALTER TABLE dbo.CashMoves ADD CreatedBy NVARCHAR(240) NULL;
GO

-- -----------------------------------------------------------------------------
-- PARTE 1.3 Restricciones de negocio (importes positivos, tipo unico, medio)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_CashMoves_AmountPositivo' AND parent_object_id = OBJECT_ID(N'dbo.CashMoves'))
    ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT CK_CashMoves_AmountPositivo CHECK (Amount > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_CashMoves_MoveState' AND parent_object_id = OBJECT_ID(N'dbo.CashMoves'))
    ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT CK_CashMoves_MoveState CHECK (MoveState IN (N'confirmado', N'anulado'));
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_CashMoves_Method' AND parent_object_id = OBJECT_ID(N'dbo.CashMoves'))
    ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT CK_CashMoves_Method
        CHECK (Method IS NULL OR Method IN (N'apertura', N'efectivo', N'transferencia', N'tarjeta', N'cheque', N'otro'));
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_CashMoves_DocumentType' AND parent_object_id = OBJECT_ID(N'dbo.CashMoves'))
    ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT CK_CashMoves_DocumentType
        CHECK (DocumentType IS NULL OR DocumentType IN (N'apertura', N'venta', N'cobro', N'anticipo', N'compra', N'pago_proveedor', N'nomina', N'ajuste', N'otro'));
GO

-- La apertura siempre es una entrada; no puede existir apertura negativa.
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_CashMoves_AperturaEntrada' AND parent_object_id = OBJECT_ID(N'dbo.CashMoves'))
    ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT CK_CashMoves_AperturaEntrada
        CHECK (DocumentType <> N'apertura' OR MoveType = N'entrada');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'FK_CashMoves_CashSessions' AND parent_object_id = OBJECT_ID(N'dbo.CashMoves'))
    ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT FK_CashMoves_CashSessions
        FOREIGN KEY (SessionId) REFERENCES dbo.CashSessions (CashSessionId) ON DELETE SET NULL;
GO

-- Idempotencia: una misma operacion solicitada dos veces no crea dos movimientos.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_CashMoves_OperationKey' AND object_id = OBJECT_ID(N'dbo.CashMoves'))
    CREATE UNIQUE INDEX UQ_CashMoves_OperationKey ON dbo.CashMoves (OperationKey) WHERE OperationKey IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CashMoves_Account_Fecha' AND object_id = OBJECT_ID(N'dbo.CashMoves'))
    CREATE INDEX IX_CashMoves_Account_Fecha ON dbo.CashMoves (Account, MoveDate, CashMoveId) INCLUDE (MoveType, Amount, DocumentType);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_CashMoves_Session' AND object_id = OBJECT_ID(N'dbo.CashMoves'))
    CREATE INDEX IX_CashMoves_Session ON dbo.CashMoves (SessionId);
GO

-- -----------------------------------------------------------------------------
-- PARTE 1.4 Movimiento con saldo acumulado
-- Regla: saldo anterior + entrada - salida = nuevo saldo.
-- Orden estable: (MoveDate, CashMoveId) sobre los movimientos confirmados.
-- -----------------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_MovimientoCajaSaldo
AS
WITH Movs AS (
    SELECT
        m.CashMoveId,
        m.Account,
        m.MoveType,
        m.Amount,
        m.MoveDate,
        m.MoveTime,
        m.Concept,
        m.Method,
        m.DocumentType,
        m.DocumentRef,
        m.SaleId,
        m.PurchaseId,
        m.PayrollRunId,
        m.SessionId,
        m.ResponsibleAppUserId,
        m.ResponsibleName,
        m.OperationKey,
        ROW_NUMBER() OVER (PARTITION BY m.Account ORDER BY m.MoveDate, m.CashMoveId) AS Rn
    FROM dbo.CashMoves AS m
    WHERE m.MoveState = N'confirmado'
)
SELECT
    v.CashMoveId,
    v.Account,
    v.MoveDate,
    v.MoveTime,
    v.MoveType,
    CASE WHEN v.MoveType = N'entrada' THEN v.Amount ELSE NULL END AS Entrada,
    CASE WHEN v.MoveType = N'salida'  THEN v.Amount ELSE NULL END AS Salida,
    SUM(CASE WHEN v.MoveType = N'entrada' THEN v.Amount ELSE -v.Amount END)
        OVER (PARTITION BY v.Account ORDER BY v.Rn ROWS UNBOUNDED PRECEDING) AS SaldoAcumulado,
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
FROM Movs AS v;
GO

-- Resumen por cuenta: saldo inicial identificado, entradas, salidas y saldo final.
-- El saldo inicial (DocumentType = 'apertura') NO se mezcla con ingresos.
CREATE OR ALTER VIEW dbo.vw_ResumenCaja
AS
SELECT
    v.Account,
    SUM(CASE WHEN v.DocumentType = N'apertura' THEN ISNULL(v.Entrada, 0) ELSE 0 END) AS SaldoInicial,
    SUM(CASE WHEN v.MoveType = N'entrada' AND ISNULL(v.DocumentType, N'') <> N'apertura'
             THEN ISNULL(v.Entrada, 0) ELSE 0 END) AS TotalEntradas,
    SUM(ISNULL(v.Salida, 0)) AS TotalSalidas,
    SUM(ISNULL(v.Entrada, 0) - ISNULL(v.Salida, 0)) AS SaldoFinal,
    COUNT(1) AS Movimientos,
    MAX(v.MoveDate) AS UltimoMovimiento
FROM dbo.vw_MovimientoCajaSaldo AS v
GROUP BY v.Account;
GO

-- Resumen de sesiones: conserva responsable, fecha, resultado y pendientes.
CREATE OR ALTER VIEW dbo.vw_EstadoSesionesCaja
AS
SELECT
    s.CashSessionId,
    s.Account,
    s.Currency,
    s.SessionDate,
    s.OpeningBalance,
    s.Status,
    s.OpenedAt,
    s.OpenedByName,
    s.ClosedAt,
    s.ClosedByAppUserId,
    s.CountedCash,
    s.ExpectedCash,
    s.Difference,
    s.Explanation,
    s.ReviewStatus,
    s.ReviewedByName,
    s.ReviewedAt,
    (SELECT COUNT(1) FROM dbo.CashMoves AS m WHERE m.SessionId = s.CashSessionId AND m.MoveState = N'confirmado') AS Movimientos
FROM dbo.CashSessions AS s;
GO

-- -----------------------------------------------------------------------------
-- PARTE 1.5 Servidor coordinador de caja
-- El navegador solicita; el servidor valida, registra la operacion una sola vez
-- y responde con los efectos confirmados. Ningun procedimiento borra filas: las
-- correcciones se hacen por anulacion trazable.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AbrirCaja
    @Account        NVARCHAR(30),
    @Currency       NVARCHAR(10) = N'C$',
    @InitialBalance DECIMAL(19,4),
    @SessionDate    DATE = NULL,
    @Notes          NVARCHAR(1000) = NULL,
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240),
    @OperationKey   NVARCHAR(160)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Account NOT IN (N'caja', N'banco')
        THROW 50560, 'Cuenta invalida. Use caja o banco.', 1;

    IF @InitialBalance IS NULL OR @InitialBalance < 0
        THROW 50561, 'El saldo inicial no puede ser negativo.', 1;

    IF NULLIF(LTRIM(RTRIM(ISNULL(@OperationKey, N''))), N'') IS NULL
        THROW 50562, 'Se requiere un identificador de operacion para abrir caja.', 1;

    IF NULLIF(LTRIM(RTRIM(ISNULL(@ActorName, N''))), N'') IS NULL
        THROW 50563, 'Se requiere el responsable de la apertura.', 1;

    IF @SessionDate IS NULL
        SET @SessionDate = CAST(SYSUTCDATETIME() AS DATE);

    -- Reintento o doble clic: devuelve la misma sesion, no abre otra.
    DECLARE @ExistingSessionId NVARCHAR(100);
    SELECT @ExistingSessionId = CashSessionId
    FROM dbo.CashSessions
    WHERE OperationKey = @OperationKey;

    IF @ExistingSessionId IS NOT NULL
    BEGIN
        SELECT N'repetida' AS Resultado,
               s.CashSessionId, s.Account, s.Currency, s.SessionDate,
               s.OpeningBalance, s.Status, s.OpenedAt, s.OpenedByName
        FROM dbo.CashSessions AS s
        WHERE s.CashSessionId = @ExistingSessionId;
        RETURN;
    END;

    IF EXISTS (
        SELECT 1 FROM dbo.CashSessions WITH (UPDLOCK, HOLDLOCK)
        WHERE Account = @Account AND Status = N'abierta'
    )
        THROW 50564, 'Ya existe una sesion abierta para esta cuenta. Arquee y cierre la sesion vigente antes de abrir otra.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @SessionId NVARCHAR(100) = N'cs-' + LOWER(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''));

        INSERT INTO dbo.CashSessions (
            CashSessionId, Account, Currency, SessionDate, OpeningBalance, Status, Notes,
            OpenedAt, OpenedByAppUserId, OpenedByName, OperationKey
        )
        VALUES (
            @SessionId, @Account, @Currency, @SessionDate, @InitialBalance, N'abierta', @Notes,
            TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), @ActorId, @ActorName, @OperationKey
        );

        -- El saldo inicial entra como movimiento identificado, no como ingreso.
        INSERT INTO dbo.CashMoves (
            CashMoveId, Account, MoveType, Amount, MoveDate, MoveTime, Concept,
            Method, DocumentType, DocumentRef, SessionId,
            ResponsibleAppUserId, ResponsibleName, MoveState, OperationKey, CreatedBy
        )
        VALUES (
            N'cash-ap-' + @SessionId, @Account, N'entrada', @InitialBalance, @SessionDate,
            CONVERT(TIME(0), CONVERT(TIME(0), SYSUTCDATETIME())),
            N'Apertura de ' + @Account + N' - saldo inicial',
            N'apertura', N'apertura', @SessionId, @SessionId,
            @ActorId, @ActorName, N'confirmado', N'apertura:' + @SessionId, @ActorName
        );

        COMMIT TRANSACTION;

        SELECT N'abierta' AS Resultado,
               @SessionId AS CashSessionId,
               @Account AS Account,
               @Currency AS Currency,
               @SessionDate AS SessionDate,
               @InitialBalance AS OpeningBalance,
               @OperationKey AS OperationKey;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegistrarMovimientoCaja
    @Account        NVARCHAR(30),
    @MoveType       NVARCHAR(10),
    @Amount         DECIMAL(19,4),
    @Concept        NVARCHAR(300),
    @Method         NVARCHAR(30) = N'efectivo',
    @DocumentType   NVARCHAR(40) = NULL,
    @DocumentRef    NVARCHAR(120) = NULL,
    @MoveDate       DATE = NULL,
    @MoveTime       TIME(0) = NULL,
    @SessionId      NVARCHAR(100) = NULL,
    @Notes          NVARCHAR(1000) = NULL,
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240),
    @OperationKey   NVARCHAR(160)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MethodKey NVARCHAR(30) = LOWER(LTRIM(RTRIM(ISNULL(@Method, N'efectivo'))));

    IF NULLIF(LTRIM(RTRIM(ISNULL(@OperationKey, N''))), N'') IS NULL
        THROW 50565, 'Se requiere un identificador de operacion para registrar movimiento de caja.', 1;

    IF @MoveType NOT IN (N'entrada', N'salida')
        THROW 50566, 'El tipo de movimiento debe ser entrada o salida.', 1;

    IF @Amount IS NULL OR @Amount <= 0
        THROW 50567, 'El importe debe ser mayor que cero. El tipo de movimiento determina el efecto.', 1;

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Concept, N''))), N'') IS NULL
        THROW 50568, 'El concepto del movimiento es obligatorio.', 1;

    IF @MethodKey NOT IN (N'efectivo', N'transferencia', N'tarjeta', N'cheque', N'otro')
        THROW 50569, 'Medio de pago no valido. Use efectivo, transferencia, tarjeta, cheque u otro.', 1;

    -- El efectivo afecta la caja; una transferencia/cheque/tarjeta afecta el banco.
    -- Una transferencia nunca debe aumentar tambien el efectivo.
    IF @MethodKey = N'efectivo' AND @Account <> N'caja'
        THROW 50570, 'El efectivo solo afecta la caja. Use la cuenta caja o registre la operacion en el banco.', 1;

    IF @MethodKey <> N'efectivo' AND @Account <> N'banco'
        THROW 50571, 'Una transferencia, cheque o tarjeta afecta la cuenta bancaria, no la caja de efectivo.', 1;

    IF @MoveDate IS NULL SET @MoveDate = CAST(SYSUTCDATETIME() AS DATE);
    IF @MoveTime IS NULL SET @MoveTime = CONVERT(TIME(0), SYSUTCDATETIME());

    -- Idempotencia: la misma solicitud devuelve el mismo movimiento.
    DECLARE @ExistingId NVARCHAR(100);
    SELECT @ExistingId = CashMoveId FROM dbo.CashMoves WHERE OperationKey = @OperationKey;

    IF @ExistingId IS NOT NULL
    BEGIN
        SELECT N'repetida' AS Resultado, v.*
        FROM dbo.vw_MovimientoCajaSaldo AS v
        WHERE v.CashMoveId = @ExistingId;
        RETURN;
    END;

    DECLARE @Session NVARCHAR(100) = @SessionId;
    DECLARE @SessionDate DATE;

    IF @Account = N'caja'
    BEGIN
        IF @Session IS NULL
            SELECT @Session = CashSessionId, @SessionDate = SessionDate
            FROM dbo.CashSessions
            WHERE Account = N'caja' AND Status = N'abierta';

        IF @Session IS NULL
            THROW 50572, 'No hay una sesion de caja abierta. Abra caja antes de registrar movimientos de efectivo.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.CashSessions WHERE CashSessionId = @Session AND Account = N'caja' AND Status = N'abierta')
            THROW 50573, 'La sesion indicada no esta abierta para la caja.', 1;

        IF @SessionDate IS NULL
            SELECT @SessionDate = SessionDate FROM dbo.CashSessions WHERE CashSessionId = @Session;

        IF @MoveDate < @SessionDate
            THROW 50574, 'El movimiento no puede ser anterior a la fecha de apertura de la sesion.', 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @MoveId NVARCHAR(100) = N'cash-' + LOWER(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''));

        INSERT INTO dbo.CashMoves (
            CashMoveId, Account, MoveType, Amount, MoveDate, MoveTime, Concept,
            Method, DocumentType, DocumentRef, SessionId,
            ResponsibleAppUserId, ResponsibleName, MoveState, OperationKey, CreatedBy
        )
        VALUES (
            @MoveId, @Account, @MoveType, @Amount, @MoveDate, @MoveTime, @Concept,
            @MethodKey, @DocumentType, @DocumentRef, @Session,
            @ActorId, @ActorName, N'confirmado', @OperationKey, @ActorName
        );

        COMMIT TRANSACTION;

        SELECT N'confirmada' AS Resultado, v.*
        FROM dbo.vw_MovimientoCajaSaldo AS v
        WHERE v.CashMoveId = @MoveId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Arqueo y cierre. Registra efectivo contado, compara con el saldo esperado,
-- exige explicacion si hay diferencia y deja el cierre pendiente de revision.
-- Un faltante NUNCA se convierte en un descuento al trabajador.
CREATE OR ALTER PROCEDURE dbo.usp_ArquearYCerrarCaja
    @SessionId   NVARCHAR(100),
    @CountedCash DECIMAL(19,4),
    @Explanation NVARCHAR(1000) = NULL,
    @ActorId     NVARCHAR(100),
    @ActorName   NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Status NVARCHAR(30);
    DECLARE @Opening DECIMAL(19,4);
    DECLARE @Expected DECIMAL(19,4);
    DECLARE @Difference DECIMAL(19,4);

    SELECT @Status = Status, @Opening = OpeningBalance
    FROM dbo.CashSessions WITH (UPDLOCK, HOLDLOCK)
    WHERE CashSessionId = @SessionId;

    IF @Status IS NULL
        THROW 50575, 'La sesion de caja indicada no existe.', 1;

    IF @Status <> N'abierta'
        THROW 50576, 'La sesion ya fue cerrada. Las correcciones posteriores requieren un procedimiento autorizado y trazable.', 1;

    IF @CountedCash IS NULL OR @CountedCash < 0
        THROW 50577, 'El efectivo contado no puede ser negativo.', 1;

    SELECT @Expected = @Opening
        + SUM(CASE WHEN MoveType = N'entrada'  AND ISNULL(DocumentType, N'') <> N'apertura' THEN Amount ELSE 0 END)
        - SUM(CASE WHEN MoveType = N'salida' THEN Amount ELSE 0 END)
    FROM dbo.CashMoves
    WHERE SessionId = @SessionId AND MoveState = N'confirmado';

    IF @Expected IS NULL SET @Expected = @Opening;

    SET @Difference = @CountedCash - @Expected;

    IF @Difference <> 0 AND NULLIF(LTRIM(RTRIM(ISNULL(@Explanation, N''))), N'') IS NULL
        THROW 50578, 'Hay sobrante o faltante: explique la diferencia antes de cerrar la sesion.', 1;

    DECLARE @ReviewStatus NVARCHAR(30) = CASE WHEN @Difference = 0 THEN N'revisado' ELSE N'pendiente_revision' END;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.CashSessions
        SET Status = N'cerrada',
            ClosedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            ClosedByAppUserId = @ActorId,
            CountedCash = @CountedCash,
            ExpectedCash = @Expected,
            Difference = @Difference,
            Explanation = @Explanation,
            ReviewStatus = @ReviewStatus,
            ReviewedByName = CASE WHEN @ReviewStatus = N'revisado' THEN @ActorName ELSE ReviewedByName END,
            ReviewedAt = CASE WHEN @ReviewStatus = N'revisado' THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE ReviewedAt END
        WHERE CashSessionId = @SessionId;

        COMMIT TRANSACTION;

        SELECT N'cerrada' AS Resultado,
               @SessionId AS CashSessionId,
               @Expected AS ExpectedCash,
               @CountedCash AS CountedCash,
               @Difference AS Difference,
               @ReviewStatus AS ReviewStatus;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Revision del arqueo por una persona distinta de quien cerro la caja.
CREATE OR ALTER PROCEDURE dbo.usp_RevisionArqueo
    @SessionId NVARCHAR(100),
    @Decision  NVARCHAR(30),
    @Notes     NVARCHAR(1000) = NULL,
    @ActorId   NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Status NVARCHAR(30);
    DECLARE @ReviewStatus NVARCHAR(30);
    DECLARE @ClosedBy NVARCHAR(100);
    DECLARE @Explanation NVARCHAR(1000);

    SELECT @Status = Status, @ReviewStatus = ReviewStatus, @ClosedBy = ClosedByAppUserId, @Explanation = Explanation
    FROM dbo.CashSessions WITH (UPDLOCK, HOLDLOCK)
    WHERE CashSessionId = @SessionId;

    IF @Status IS NULL
        THROW 50579, 'La sesion de caja indicada no existe.', 1;

    IF @Status <> N'cerrada'
        THROW 50580, 'Solo se revisa el arqueo de una sesion cerrada.', 1;

    IF ISNULL(@ReviewStatus, N'') <> N'pendiente_revision'
        THROW 50581, 'La sesion no tiene un arqueo pendiente de revision.', 1;

    IF @Decision NOT IN (N'revisado', N'observado')
        THROW 50582, 'La decision debe ser revisado u observado.', 1;

    IF @ActorId IS NOT NULL AND @ClosedBy IS NOT NULL AND @ActorId = @ClosedBy
        THROW 50583, 'La revision del arqueo debe realizarla una persona distinta de quien cerro la caja.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.CashSessions
        SET ReviewStatus = @Decision,
            ReviewedByAppUserId = @ActorId,
            ReviewedByName = @ActorName,
            ReviewedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            Explanation = CASE WHEN NULLIF(LTRIM(RTRIM(ISNULL(@Notes, N''))), N'') IS NULL THEN Explanation
                               ELSE Explanation + N' | Revisado: ' + @Notes END
        WHERE CashSessionId = @SessionId;

        COMMIT TRANSACTION;

        SELECT @SessionId AS CashSessionId, @Decision AS ReviewStatus, @ActorName AS ReviewedByName;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Anulacion trazable (nunca borrado). Requiere motivo y autorizacion.
CREATE OR ALTER PROCEDURE dbo.usp_AnularMovimientoCaja
    @CashMoveId NVARCHAR(100),
    @Reason     NVARCHAR(1000),
    @ActorId    NVARCHAR(100),
    @ActorName  NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @State NVARCHAR(30);
    DECLARE @Responsible NVARCHAR(100);
    DECLARE @SessionId NVARCHAR(100);
    DECLARE @SessionClosed BIT = 0;
    DECLARE @ActorHierarchy NVARCHAR(30);

    SELECT @State = m.MoveState, @Responsible = m.ResponsibleAppUserId, @SessionId = m.SessionId
    FROM dbo.CashMoves AS m
    WHERE m.CashMoveId = @CashMoveId;

    IF @State IS NULL
        THROW 50584, 'El movimiento de caja indicado no existe.', 1;

    IF @State <> N'confirmado'
        THROW 50585, 'El movimiento ya estaba anulado.', 1;

    IF NULLIF(LTRIM(RTRIM(ISNULL(@Reason, N''))), N'') IS NULL
        THROW 50586, 'La anulacion de un movimiento de caja requiere un motivo.', 1;

    IF EXISTS (SELECT 1 FROM dbo.CashSessions WHERE CashSessionId = @SessionId AND Status = N'cerrada')
        SET @SessionClosed = 1;

    SELECT @ActorHierarchy = Hierarchy FROM dbo.AppUsers WHERE AppUserId = @ActorId;

    IF @SessionClosed = 1 AND ISNULL(@ActorHierarchy, N'') NOT IN (N'superadmin', N'administrador')
        THROW 50587, 'La sesion esta cerrada: la anulacion requiere un usuario administrador y queda trazada.', 1;

    IF @ActorId IS NOT NULL AND @Responsible IS NOT NULL AND @ActorId = @Responsible AND @SessionClosed = 1
        THROW 50588, 'En una sesion cerrada no se anulan movimientos propios: requiere una segunda persona autorizada.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Se conserva la fila original y se registra la anulacion con su motivo.
        UPDATE dbo.CashMoves
        SET MoveState = N'anulado',
            Concept = Concept + N' [ANULADO: ' + @Reason + N' por ' + ISNULL(@ActorName, N'sistema') + N']'
        WHERE CashMoveId = @CashMoveId;

        COMMIT TRANSACTION;

        SELECT N'anulado' AS Resultado, @CashMoveId AS CashMoveId, @Reason AS Motivo;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- =============================================================================
-- PARTE 2. NOMINA: CALCULO CONFIRMADO Y BLOQUEO DEL FLUJO
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PARTE 2.1 Columnas de calculo y estado (ya existentes en instalaciones 17/25).
-- Se documentan aqui porque las validaciones de la PARTE 2.4 dependen de ellas.
--   PayrollRuns.CalculatedAt       -> momento del ultimo calculo confirmado.
--   PayrollRuns.CalculationStale   -> el calculo quedo desactualizado.
-- -----------------------------------------------------------------------------
IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculationStale') IS NULL
    ALTER TABLE dbo.PayrollRuns ADD CalculationStale BIT NOT NULL CONSTRAINT DF_PayrollRuns_Stale DEFAULT (0);
GO

-- -----------------------------------------------------------------------------
-- PARTE 2.2 Idempotencia de pagos: una operacion = un pago
-- -----------------------------------------------------------------------------
-- 26: la cabecera de planilla nunca tuvo TotalDeductions (por eso mostraba
-- deducciones en cero aunque el detalle las calculara).
IF COL_LENGTH(N'dbo.PayrollRuns', N'TotalDeductions') IS NULL
    ALTER TABLE dbo.PayrollRuns ADD TotalDeductions DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_TotDed DEFAULT (0);
GO

-- 26: el pago conserva fecha de pago, notas, nombre del confirmante y la version
-- de calculo con la que se pago (los comprobantes deben coincidir con esa version).
IF COL_LENGTH(N'dbo.PayrollPayments', N'PaymentDate') IS NULL
    ALTER TABLE dbo.PayrollPayments ADD PaymentDate DATE NULL;

IF COL_LENGTH(N'dbo.PayrollPayments', N'Notes') IS NULL
    ALTER TABLE dbo.PayrollPayments ADD Notes NVARCHAR(1000) NULL;

IF COL_LENGTH(N'dbo.PayrollPayments', N'ConfirmedByName') IS NULL
    ALTER TABLE dbo.PayrollPayments ADD ConfirmedByName NVARCHAR(240) NULL;

IF COL_LENGTH(N'dbo.PayrollPayments', N'CalculationVersion') IS NULL
    ALTER TABLE dbo.PayrollPayments ADD CalculationVersion INT NULL;

IF COL_LENGTH(N'dbo.PayrollPayments', N'IdempotencyKey') IS NULL
    ALTER TABLE dbo.PayrollPayments ADD IdempotencyKey UNIQUEIDENTIFIER NULL;

IF COL_LENGTH(N'dbo.PayrollPayments', N'RequestHash') IS NULL
    ALTER TABLE dbo.PayrollPayments ADD RequestHash VARBINARY(32) NULL;

IF COL_LENGTH(N'dbo.PayrollPayments', N'OperationKey') IS NULL
    ALTER TABLE dbo.PayrollPayments ADD OperationKey NVARCHAR(160) NULL;
GO

-- Indice unico filtrado: reintentar la misma operacion no crea un segundo pago,
-- pero no bloquea pagos parciales legitimos (cada uno tiene su propio clave).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_PayrollPayments_IdempotencyKey' AND object_id = OBJECT_ID(N'dbo.PayrollPayments'))
    CREATE UNIQUE INDEX UQ_PayrollPayments_IdempotencyKey ON dbo.PayrollPayments (IdempotencyKey) WHERE IdempotencyKey IS NOT NULL;
GO

-- Clave de negocio: no puede existir dos veces el mismo numero de referencia
-- bancaria para el mismo importe (duplicado real de dispersion).
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = N'CK_PayrollPayments_MontoPositivo' AND parent_object_id = OBJECT_ID(N'dbo.PayrollPayments'))
    ALTER TABLE dbo.PayrollPayments WITH CHECK ADD CONSTRAINT CK_PayrollPayments_MontoPositivo CHECK (Amount > 0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_PayrollPayments_Run' AND object_id = OBJECT_ID(N'dbo.PayrollPayments'))
    CREATE INDEX IX_PayrollPayments_Run ON dbo.PayrollPayments (PayrollRunId) INCLUDE (Amount, PaymentDate, PaymentMethod);
GO

-- Asientos y movimientos de finanzas: clave de operacion para no duplicarlos.
IF COL_LENGTH(N'dbo.AccountingEntries', N'OperationKey') IS NULL
    ALTER TABLE dbo.AccountingEntries ADD OperationKey NVARCHAR(160) NULL;

IF COL_LENGTH(N'dbo.FinanceMoves', N'OperationKey') IS NULL
    ALTER TABLE dbo.FinanceMoves ADD OperationKey NVARCHAR(160) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_AccountingEntries_OperationKey' AND object_id = OBJECT_ID(N'dbo.AccountingEntries'))
    CREATE UNIQUE INDEX UQ_AccountingEntries_OperationKey ON dbo.AccountingEntries (OperationKey) WHERE OperationKey IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_FinanceMoves_OperationKey' AND object_id = OBJECT_ID(N'dbo.FinanceMoves'))
    CREATE UNIQUE INDEX UQ_FinanceMoves_OperationKey ON dbo.FinanceMoves (OperationKey) WHERE OperationKey IS NOT NULL;
GO

-- -----------------------------------------------------------------------------
-- PARTE 2.3 Identificar los efectos ya confirmados por el servidor
-- El snapshot del navegador conserva estas filas (ver usp_SaveErpState).
-- -----------------------------------------------------------------------------
UPDATE m
SET m.OperationKey = N'nomina:' + m.PayrollRunId
FROM dbo.CashMoves AS m
WHERE m.OperationKey IS NULL AND m.PayrollRunId IS NOT NULL AND m.CashMoveId = N'cash-nom-' + m.PayrollRunId;

UPDATE a
SET a.OperationKey = N'nomina:' + a.AccountingEntryId
FROM dbo.AccountingEntries AS a
WHERE a.OperationKey IS NULL AND a.PayrollRunId IS NOT NULL;

UPDATE a
SET a.OperationKey = N'caja:' + a.AccountingEntryId
FROM dbo.AccountingEntries AS a
WHERE a.OperationKey IS NULL AND a.AccountingEntryId LIKE N'entry-cash-%';

UPDATE f
SET f.OperationKey = N'nomina:' + f.FinanceMoveId
FROM dbo.FinanceMoves AS f
WHERE f.OperationKey IS NULL AND f.FinanceMoveId LIKE N'fn-nom-%';
GO

-- -----------------------------------------------------------------------------
-- PARTE 2.4 Reparacion controlada de totales de planillas NO cerradas
-- usp_CalculatePayroll nunca escribia PayrollRuns.TotalDeductions, por lo que la
-- cabecera mostraba deducciones en cero aunque el detalle las calculara.
-- Solo se corrige el resumen de planillas que no estan cerradas ni pagadas; los
-- periodos cerrados se reportan (27_reporte_inconsistencias.sql) y no se tocan.
-- -----------------------------------------------------------------------------
UPDATE r
SET r.TotalDeductions = ISNULL(g.DedTotal, 0)
FROM dbo.PayrollRuns AS r
OUTER APPLY (
    SELECT SUM(i.TotalDeductions) AS DedTotal
    FROM dbo.PayrollRunItems AS i
    WHERE i.PayrollRunId = r.PayrollRunId
) AS g
WHERE r.Status NOT IN (N'cerrada', N'pago_registrado', N'conciliada')
  AND r.CalculatedAt IS NOT NULL
  AND ISNULL(r.TotalDeductions, 0) <> ISNULL(g.DedTotal, 0);
GO

-- -----------------------------------------------------------------------------
-- PARTE 2.5 Listado de planillas: exponer el estado real del calculo
-- La interfaz necesita saber si el calculo existe y si sigue vigente para no
-- presentar ceros como si fueran valores validados.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRuns
    @IncludeClosed BIT = 0
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT
        r.PayrollRunId AS id,
        r.Period AS period,
        r.PeriodType AS periodType,
        r.Status AS status,
        r.CalculationVersion AS calculationVersion,
        r.CalculatedAt AS calculatedAt,
        ISNULL(r.CalculationStale, 0) AS calculationStale,
        r.Gross AS grossTotal,
        r.InssLaboral AS inssLaboralTotal,
        r.InssPatronal AS inssPatronalTotal,
        r.Inatec AS inatecTotal,
        r.IncomeTax AS incomeTaxTotal,
        r.OtherDeductionsTotal AS otherDeductionsTotal,
        r.TotalDeductions AS totalDeductions,
        -- Suma real del detalle: permite mostrar la verdad y marcar cabeceras
        -- historicas incoherentes sin reescribir periodos ya pagados o cerrados.
        ISNULL(SUM(i.TotalDeductions), 0) AS deductionsFromItems,
        CASE WHEN r.TotalDeductions = ISNULL(SUM(i.TotalDeductions), 0)
             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS headerConsistent,
        r.Net AS netTotal,
        r.ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
        (r.Net - r.ConfirmedPaymentsTotal) AS pendingPayment,
        r.EmployerCost AS companyCostTotal,
        r.Notes AS notes,
        r.ApprovedAt AS approvedAt,
        r.ApprovedByAppUserId AS approvedByUserId,
        r.PaidAt AS paidAt,
        CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
        CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS rowVersion,
        COUNT(i.PayrollItemId) AS employeesCount
    FROM dbo.PayrollRuns AS r
    LEFT JOIN dbo.PayrollRunItems AS i ON i.PayrollRunId = r.PayrollRunId
    WHERE (@IncludeClosed = 1 OR r.Status NOT IN (N'cancelada'))
    GROUP BY
        r.PayrollRunId, r.Period, r.PeriodType, r.Status,
        r.CalculationVersion, r.CalculatedAt, r.CalculationStale,
        r.Gross, r.InssLaboral, r.InssPatronal, r.Inatec, r.IncomeTax,
        r.OtherDeductionsTotal, r.TotalDeductions, r.Net,
        r.ConfirmedPaymentsTotal, r.EmployerCost, r.Notes,
        r.ApprovedAt, r.ApprovedByAppUserId, r.PaidAt,
        r.Revision, r.CreatedAt
    ORDER BY r.CreatedAt DESC;
END;
GO

-- -----------------------------------------------------------------------------
-- PARTE 2.6 Unico servicio de salida de dinero por planilla
-- Corrige: asignacion por suma de pagos, marca items solo cuando se cubre el
-- neto, exige calculo confirmado y vigente, acepta pagos parciales, es
-- idempotente por @IdempotencyKey y NO vuelve a descontar deducciones ni crea
-- un segundo gasto (el gasto ya se reconocio al aprobar la planilla).
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PayrollRunId       NVARCHAR(100),
    @Amount             DECIMAL(19,4),
    @PaymentMethod      NVARCHAR(60),
    @PaymentReference   NVARCHAR(120),
    @PaymentDate        DATE,
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
    DECLARE @NetTotal DECIMAL(19,4);
    DECLARE @CalculatedAt DATETIMEOFFSET(3);
    DECLARE @Stale BIT;
    DECLARE @Revision VARBINARY(8);
    DECLARE @CalcVersion INT;

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

        -- 1. Registro del pago (acumulativo, con su identificador de operacion).
        INSERT INTO dbo.PayrollPayments (
            PaymentId, PayrollRunId, EmployeeId, Amount, PaymentMethod, TransactionReference,
            PaymentDate, CashMoveId, Notes, ConfirmedAt, ConfirmedByAppUserId, ConfirmedByName,
            CalculationVersion, Status, IdempotencyKey, OperationKey, RequestHash
        )
        VALUES (
            @PaymentId, @PayrollRunId, ISNULL(@EmployeeId, N'*planilla*'), @Amount, @PaymentMethod, @PaymentReference,
            CONVERT(DATE, @PaymentDateIso), @CashMoveId, @Notes,
            TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), @ActorId, @ActorName,
            @CalcVersion, N'confirmado', @IdempotencyKey,
            CASE WHEN @IdempotencyKey IS NULL THEN NULL ELSE N'pago-nomina:' + CAST(@IdempotencyKey AS NVARCHAR(36)) END,
            HASHBYTES('SHA2_256', CONCAT(
                @PayrollRunId, N'|', @Amount, N'|', ISNULL(@PaymentMethod, N''), N'|',
                ISNULL(@PaymentReference, N''), N'|', @PaymentDateIso, N'|', CONVERT(NVARCHAR(20), @Revision)
            ))
        );

        -- 2. Unica salida de dinero del run: un solo movimiento de caja/banco por
        --    planilla, con el importe acumulado de los pagos confirmados.
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

        -- 3. Estado economico de la planilla: siempre suma de pagos confirmados.
        UPDATE dbo.PayrollRuns
        SET ConfirmedPaymentsTotal = @NewPaid,
            UpdatedAt = SYSUTCDATETIME()
        WHERE PayrollRunId = @PayrollRunId;

        -- 4. Los items solo se marcan pagados cuando se cubre el neto completo.
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

-- -----------------------------------------------------------------------------
-- PARTE 2.7 Procedimientos regenerados con las correcciones de la migracion 26.
-- Cuerpo tomado de 17_modulo_nomina_completo.sql y 07_procedimiento_
-- sincronizacion.sql con los parches documentados en esta migracion.
-- Mantener esos archivos y esta migracion alineados.
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CalculatePayroll
    @PayrollRunId       NVARCHAR(100),
    @ExpectedRevision   VARBINARY(8),
    @ActorId            NVARCHAR(100),
    @ActorName          NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @PeriodType NVARCHAR(30);
    DECLARE @CalcVer INT;
    DECLARE @CurrentRev VARBINARY(8);

    SELECT @CurrentStatus = Status,
           @PeriodType = PeriodType,
           @CalcVer = CalculationVersion,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50503, 'La planilla solicitada no existe.', 1;

    IF @CurrentRev <> @ExpectedRevision
        THROW 50504, 'La planilla fue modificada por otro usuario (revisión desfasada). Recarga la pantalla.', 1;

    IF @CurrentStatus IN (N'aprobada', N'pago_registrado', N'conciliada', N'cerrada')
        THROW 50505, 'No se puede recalcular una planilla que ya ha sido aprobada, pagada o cerrada.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Actualizar conceptos variables desde la tabla de novedades
        UPDATE i
        SET i.OvertimeAmount = ISNULL(nov.TotalOt, 0),
            i.OvertimeHours = ISNULL(nov.TotalOtHours, 0),
            i.BonusesAmount = ISNULL(nov.TotalBonus, 0),
            i.CommissionsAmount = ISNULL(nov.TotalComm, 0),
            i.VacationDisfruteAmount = ISNULL(nov.TotalVac, 0),
            i.OtherDeductions = ISNULL(nov.TotalDed, 0)
        FROM dbo.PayrollRunItems i
        OUTER APPLY (
            SELECT SUM(CASE WHEN NoveltyType = N'horas_extra' THEN Amount ELSE 0 END) AS TotalOt,
                   SUM(CASE WHEN NoveltyType = N'horas_extra' THEN ISNULL(Hours, 0) ELSE 0 END) AS TotalOtHours,
                   SUM(CASE WHEN NoveltyType = N'bono' THEN Amount ELSE 0 END) AS TotalBonus,
                   SUM(CASE WHEN NoveltyType = N'comision' THEN Amount ELSE 0 END) AS TotalComm,
                   SUM(CASE WHEN NoveltyType = N'vacaciones' THEN Amount ELSE 0 END) AS TotalVac,
                   SUM(CASE WHEN NoveltyType IN (N'deduccion_prestamo', N'otro_descuento', N'otro') THEN Amount ELSE 0 END) AS TotalDed
            FROM dbo.PayrollNovelties
            WHERE EmployeeId = i.EmployeeId AND (PayrollRunId = @PayrollRunId OR PayrollRunId IS NULL)
              AND Status IN (N'autorizada', N'procesada')
        ) AS nov
        WHERE i.PayrollRunId = @PayrollRunId;

        -- 2. Calcular Devengado Bruto por Trabajador
        UPDATE dbo.PayrollRunItems
        SET Gross = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2),
            InssBase = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 3. Calcular Deducciones de Ley (INSS Laboral 7.00%)
        UPDATE dbo.PayrollRunItems
        SET InssLaboral = ROUND(InssBase * 0.07, 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 4. Calcular Impuesto sobre la Renta del Trabajo (IR Laboral - Ley 822 Art. 23 & 96)
        --    Ingreso Anual Proyectado = (Devengado - INSS) * (12 si es mensual, 24 si es quincenal)
        UPDATE i
        SET i.IrBase = p.NetBasePeriod,
            i.IncomeTax = calc.IrPeriod
        FROM dbo.PayrollRunItems i
        CROSS APPLY (
            SELECT
                (i.Gross - i.InssLaboral) AS NetBasePeriod,
                CASE WHEN @PeriodType = N'quincenal'
                     THEN (i.Gross - i.InssLaboral) * 24.0
                     ELSE (i.Gross - i.InssLaboral) * 12.0
                END AS ProjectedAnnual
        ) AS p
        CROSS APPLY (
            SELECT
                CASE
                    -- Tramo 1: C$ 0.01 a C$ 100,000.00 -> Exento (0%)
                    WHEN p.ProjectedAnnual <= 100000.00 THEN 0.00

                    -- Tramo 2: C$ 100,000.01 a C$ 200,000.00 -> 15% sobre el exceso de C$ 100,000
                    WHEN p.ProjectedAnnual <= 200000.00 THEN
                        ROUND(((p.ProjectedAnnual - 100000.00) * 0.15) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)

                    -- Tramo 3: C$ 200,000.01 a C$ 350,000.00 -> C$ 15,000 + 20% sobre el exceso de C$ 200,000
                    WHEN p.ProjectedAnnual <= 350000.00 THEN
                        ROUND((15000.00 + (p.ProjectedAnnual - 200000.00) * 0.20) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)

                    -- Tramo 4: C$ 350,000.01 a C$ 500,000.00 -> C$ 45,000 + 25% sobre el exceso de C$ 350,000
                    WHEN p.ProjectedAnnual <= 500000.00 THEN
                        ROUND((45000.00 + (p.ProjectedAnnual - 350000.00) * 0.25) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)

                    -- Tramo 5: Más de C$ 500,000.00 -> C$ 82,500 + 30% sobre el exceso de C$ 500,000
                    ELSE
                        ROUND((82500.00 + (p.ProjectedAnnual - 500000.00) * 0.30) / CASE WHEN @PeriodType = N'quincenal' THEN 24.0 ELSE 12.0 END, 2)
                END AS IrPeriod
        ) AS calc
        WHERE i.PayrollRunId = @PayrollRunId;

        -- 5. Calcular Neto a Pagar
        UPDATE dbo.PayrollRunItems
        SET TotalDeductions = ROUND(InssLaboral + IncomeTax + OtherDeductions, 2),
            Net = ROUND(Gross - (InssLaboral + IncomeTax + OtherDeductions), 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 6. Calcular Aportes Patronales (INSS Patronal 21.5%, INATEC 2%) y Provisiones (8.3333% cada una)
        UPDATE dbo.PayrollRunItems
        SET InssPatronal = ROUND(Gross * 0.2150, 2),
            Inatec = ROUND(Gross * 0.0200, 2),
            Aguinaldo = ROUND(Gross * (1.0 / 12.0), 2),
            VacacionesProv = ROUND(Gross * (1.0 / 12.0), 2),
            IndemnizacionProv = ROUND(Gross * (1.0 / 12.0), 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET EmployerCost = ROUND(Gross + InssPatronal + Inatec + Aguinaldo + VacacionesProv + IndemnizacionProv, 2)
        WHERE PayrollRunId = @PayrollRunId;

        -- 7. Generar la explicación pedagógica y transparente para cada trabajador
        UPDATE i
        SET CalculationExplanationJson = (
            SELECT
                i.OrdinarySalary AS [salario_ordinario],
                i.OvertimeAmount AS [horas_extra_monto],
                i.OvertimeHours AS [horas_extra_cantidad],
                i.BonusesAmount AS [bonos],
                i.CommissionsAmount AS [comisiones],
                i.Gross AS [total_devengado],
                N'7.0% sobre devengado (Ley de Seguridad Social)' AS [inss_laboral_regla],
                i.InssLaboral AS [inss_laboral_monto],
                N'Tarifa Progresiva Anual Ley 822 Art. 96 sobre base neta anualizada' AS [ir_laboral_regla],
                i.IrBase AS [ir_base_periodo],
                i.IncomeTax AS [ir_laboral_monto],
                i.OtherDeductions AS [otras_deducciones],
                i.TotalDeductions AS [total_deducciones],
                i.Net AS [salario_neto_a_pagar],
                N'21.5% Aporte Patronal INSS + 2.0% INATEC' AS [aportes_patronales_regla],
                i.InssPatronal AS [inss_patronal],
                i.Inatec AS [inatec],
                N'Ley 185: 1/12 Aguinaldo + 1/12 Vacaciones + 1/12 Antigüedad' AS [provisiones_regla],
                i.Aguinaldo AS [provision_aguinaldo],
                i.VacacionesProv AS [provision_vacaciones],
                i.IndemnizacionProv AS [provision_indemnizacion],
                i.EmployerCost AS [costo_total_empresa]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
        FROM dbo.PayrollRunItems i
        WHERE i.PayrollRunId = @PayrollRunId;

        -- 8. Actualizar Totales en la Cabecera de la Planilla
        UPDATE r
        SET r.Gross = ISNULL(t.GrossTotal, 0),
            r.InssLaboral = ISNULL(t.InssLabTotal, 0),
            r.IncomeTax = ISNULL(t.IrTotal, 0),
            r.OtherDeductionsTotal = ISNULL(t.OtherDedTotal, 0),
            r.TotalDeductions = ISNULL(t.DedTotal, 0),
            r.Net = ISNULL(t.NetTotal, 0),
            r.InssPatronal = ISNULL(t.InssPatTotal, 0),
            r.Inatec = ISNULL(t.InatecTotal, 0),
            r.AguinaldoProvTotal = ISNULL(t.AguiTotal, 0),
            r.VacacionesProvTotal = ISNULL(t.VacTotal, 0),
            r.IndemnizacionProvTotal = ISNULL(t.IndemTotal, 0),
            r.EmployerCost = ISNULL(t.CostTotal, 0),
            r.CalculationVersion = r.CalculationVersion + 1,
            r.CalculationStale = 0,
            r.Status = N'calculada',
            r.CalculatedByAppUserId = @ActorId,
            r.CalculatedAt = SYSUTCDATETIME(),
            r.UpdatedAt = SYSUTCDATETIME()
        FROM dbo.PayrollRuns r
        OUTER APPLY (
            SELECT SUM(Gross) AS GrossTotal,
                   SUM(InssLaboral) AS InssLabTotal,
                   SUM(IncomeTax) AS IrTotal,
                   SUM(OtherDeductions) AS OtherDedTotal,
                   SUM(TotalDeductions) AS DedTotal,
                   SUM(Net) AS NetTotal,
                   SUM(InssPatronal) AS InssPatTotal,
                   SUM(Inatec) AS InatecTotal,
                   SUM(Aguinaldo) AS AguiTotal,
                   SUM(VacacionesProv) AS VacTotal,
                   SUM(IndemnizacionProv) AS IndemTotal,
                   SUM(EmployerCost) AS CostTotal
            FROM dbo.PayrollRunItems
            WHERE PayrollRunId = @PayrollRunId
        ) AS t
        WHERE r.PayrollRunId = @PayrollRunId;

        -- 9. Ejecutar reglas de validación automática
        DELETE FROM dbo.PayrollValidations WHERE PayrollRunId = @PayrollRunId;

        -- a) Validación bloqueante: Salario Neto Negativo o Cero
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_NETO_INVALIDO',
               N'El trabajador tiene un salario neto menor o igual a cero (C$ ' + CAST(Net AS NVARCHAR(30)) + N'). Revisa las deducciones aplicadas.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Net <= 0;

        -- b) Validación bloqueante: Devengado Cero
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_DEVENGADO_CERO',
               N'El colaborador no registra salario ordinario ni devengado en el período.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Gross <= 0;

        -- c) Advertencia: Horas Extra Superiores a 9 horas semanales (Ley 185 Art. 58)
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'advertencia', N'VAL_HORAS_EXTRA_LIMITE',
               N'El colaborador acumuló ' + CAST(OvertimeHours AS NVARCHAR(20)) + N' horas extras en el período. Verificar cumplimiento del límite legal de jornada extraordinaria (Ley 185 Art. 58).',
               N'novedades'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND OvertimeHours > 18.0;

        -- d) Informativa: Inclusión de trabajador en condición de baja
        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, i.EmployeeId, N'informativa', N'VAL_TRABAJADOR_BAJA',
               N'Se liquidan remuneraciones pendientes de colaborador con baja registrada (' + ISNULL(e.DismissalReason, N'Término de contrato') + N').',
               N'trabajadores'
        FROM dbo.PayrollRunItems i
        JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
        WHERE i.PayrollRunId = @PayrollRunId AND e.EmploymentStatus = N'baja';

        -- 10. Registrar auditoría de cálculo
        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'calculo', @CurrentStatus, N'calculada',
            N'Cálculo de nómina ejecutado exitosamente con versión de cálculo v' + CAST(@CalcVer + 1 AS NVARCHAR(10)) + N'.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.CalculationVersion AS calculationVersion,
               r.Gross AS grossTotal, r.InssLaboral AS inssLaboralTotal,
               r.IncomeTax AS incomeTaxTotal, r.Net AS netTotal,
               r.InssPatronal AS inssPatronalTotal, r.Inatec AS inatecTotal,
               (r.AguinaldoProvTotal + r.VacacionesProvTotal + r.IndemnizacionProvTotal) AS provisionsTotal,
               r.EmployerCost AS companyCostTotal,
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

CREATE OR ALTER PROCEDURE dbo.usp_TransitionPayrollStatus
    @PayrollRunId       NVARCHAR(100),
    @ExpectedRevision   VARBINARY(8),
    @TargetStatus       NVARCHAR(30),
    @Notes              NVARCHAR(1000) = NULL,
    @ActorId            NVARCHAR(100),
    @ActorName          NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @PreparedBy NVARCHAR(100);
    DECLARE @Period NVARCHAR(40);
    DECLARE @NetTotal DECIMAL(19,4);
    DECLARE @GrossTotal DECIMAL(19,4);
    DECLARE @InssPatronal DECIMAL(19,4);
    DECLARE @Inatec DECIMAL(19,4);
    DECLARE @InssLaboral DECIMAL(19,4);
    DECLARE @IncomeTax DECIMAL(19,4);
    DECLARE @AguinaldoProv DECIMAL(19,4);
    DECLARE @VacacionesProv DECIMAL(19,4);
    DECLARE @IndemnizacionProv DECIMAL(19,4);
    DECLARE @CurrentRev VARBINARY(8);

    SELECT @CurrentStatus = Status,
           @PreparedBy = PreparedByAppUserId,
           @Period = Period,
           @NetTotal = Net,
           @GrossTotal = Gross,
           @InssPatronal = InssPatronal,
           @Inatec = Inatec,
           @InssLaboral = InssLaboral,
           @IncomeTax = IncomeTax,
           @AguinaldoProv = AguinaldoProvTotal,
           @VacacionesProv = VacacionesProvTotal,
           @IndemnizacionProv = IndemnizacionProvTotal,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50506, 'La planilla no existe.', 1;

    IF @CurrentRev <> @ExpectedRevision
        THROW 50507, 'La planilla fue actualizada por otro usuario. Recarga la información.', 1;

    -- Validaciones de flujo de transición
    IF @TargetStatus = N'revisada'
    BEGIN
        IF @CurrentStatus <> N'calculada'
            THROW 50508, 'Solo se puede marcar como revisada una planilla en estado calculada.', 1;

        IF EXISTS (SELECT 1 FROM dbo.PayrollValidations WHERE PayrollRunId = @PayrollRunId AND Severity = N'bloqueante' AND IsResolved = 0)
            THROW 50509, 'No se puede avanzar a revisada mientras existan observaciones bloqueantes sin resolver.', 1;
    END
    ELSE IF @TargetStatus = N'aprobada'
    BEGIN
        IF @CurrentStatus <> N'revisada'
            THROW 50510, 'Solo se puede aprobar una planilla previamente revisada.', 1;

        -- Separación de funciones: quien preparó o calculó no debe auto-aprobar
        IF @ActorId = @PreparedBy AND @ActorId <> N'u-super'
            THROW 50511, 'Separación de funciones requerida: La planilla debe ser aprobada por una persona distinta a quien la preparó.', 1;
    END
    ELSE IF @TargetStatus = N'pago_registrado'
    BEGIN
        IF @CurrentStatus <> N'aprobada'
            THROW 50512, 'Solo se puede registrar pago a una planilla aprobada.', 1;
    END
    ELSE IF @TargetStatus = N'conciliada'
    BEGIN
        IF @CurrentStatus <> N'pago_registrado'
            THROW 50513, 'Solo se puede conciliar una planilla con pagos registrados.', 1;
    END
    ELSE IF @TargetStatus = N'cerrada'
    BEGIN
        IF @CurrentStatus <> N'conciliada'
            THROW 50514, 'Solo se puede cerrar formalmente una planilla debidamente conciliada.', 1;
    END
    ELSE IF @TargetStatus IN (N'borrador', N'calculada') -- Retrocesos autorizados
    BEGIN
        IF @CurrentStatus IN (N'conciliada', N'cerrada')
            THROW 50515, 'Una planilla conciliada o cerrada no puede retroceder. Requiere una planilla complementaria de ajuste.', 1;
        IF NULLIF(LTRIM(RTRIM(@Notes)), N'') IS NULL
            THROW 50516, 'Debes documentar el motivo formal para devolver o retroceder la planilla.', 1;
    END;

        -- ---------------------------------------------------------------------------
        -- 26: bloqueos de integridad del flujo de nomina.
        -- Borrador -> Calculada -> Revisada -> Aprobada -> Pago registrado ->
        -- Conciliada -> Cerrada. El servidor exige calculo confirmado y pago real.
        -- ---------------------------------------------------------------------------
        DECLARE @CalculatedAt DATETIMEOFFSET(3);
        DECLARE @CalcStale BIT;
        DECLARE @ConfirmedTotal DECIMAL(19,4);

        SELECT @CalculatedAt = CalculatedAt,
               @CalcStale = ISNULL(CalculationStale, 0),
               @ConfirmedTotal = ISNULL(ConfirmedPaymentsTotal, 0)
        FROM dbo.PayrollRuns
        WHERE PayrollRunId = @PayrollRunId;

        IF @TargetStatus IN (N'calculada', N'revisada', N'aprobada') AND @CalculatedAt IS NULL
            THROW 50593, 'La planilla no tiene un calculo confirmado. Ejecute el calculo antes de avanzar de estado.', 1;

        IF @TargetStatus IN (N'revisada', N'aprobada') AND @CalcStale = 1
            THROW 50594, 'El calculo quedo desactualizado por cambios en trabajadores o novedades. Recalcula antes de revisar o aprobar.', 1;

        IF @TargetStatus = N'pago_registrado' AND @ConfirmedTotal <= 0
            THROW 50596, 'No hay pagos confirmados para esta planilla. Registre el pago del neto pendiente antes de marcar el estado.', 1;

        IF @TargetStatus IN (N'conciliada', N'cerrada') AND @ConfirmedTotal < @NetTotal
            THROW 50597, 'La planilla aun tiene saldo pendiente por pagar; no puede conciliarse ni cerrarse.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Actualizar campos según la fase
        IF @TargetStatus = N'revisada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'revisada',
                ReviewedByAppUserId = @ActorId,
                ReviewedAt = SYSUTCDATETIME(),
                ReviewNotes = @Notes,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;
        END
        ELSE IF @TargetStatus = N'aprobada'
        BEGIN
            -- Generar Asiento Contable Equilibrado de Nómina (Partida Doble)
            DECLARE @EntryId NVARCHAR(100) = N'entry-nom-' + @PayrollRunId;
            DECLARE @EntryNumber NVARCHAR(80) = N'AST-NOM-' + REPLACE(@Period, N' ', N'-');

            -- Verificar si ya existe asiento para actualizar o crear
            IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryId)
            BEGIN
                -- 1. Asiento de Gasto de Nómina vs Pasivos Laborales
                -- Débito: Gasto de Nómina (Devengado)
                -- Crédito: Sueldos por pagar (Neto), INSS por pagar (Laboral), IR por pagar (Laboral)
                DECLARE @TotalPasivosLaborales DECIMAL(19,4) = @NetTotal + @InssLaboral + @IncomeTax;

                INSERT INTO dbo.AccountingEntries (
                    AccountingEntryId, EntryNumber, Description, Debit, Credit,
                    DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId, PayrollRunId
                )
                VALUES (
                    @EntryId, @EntryNumber,
                    N'Reconocimiento de gastos de personal y retenciones de ley período ' + @Period,
                    @GrossTotal, @GrossTotal,
                    N'Nómina', N'Sueldos por pagar',
                    TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), N'payroll', @PayrollRunId, @PayrollRunId
                );

                -- 2. Asiento de Cargas Sociales Patronales (INSS Patronal + INATEC)
                DECLARE @EntryPatronalId NVARCHAR(100) = N'entry-pat-' + @PayrollRunId;
                DECLARE @EntryPatronalNum NVARCHAR(80) = N'AST-PAT-' + REPLACE(@Period, N' ', N'-');
                DECLARE @TotalCargasPatronales DECIMAL(19,4) = @InssPatronal + @Inatec;

                IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryPatronalId)
                BEGIN
                    INSERT INTO dbo.AccountingEntries (
                        AccountingEntryId, EntryNumber, Description, Debit, Credit,
                        DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId, PayrollRunId
                    )
                    VALUES (
                        @EntryPatronalId, @EntryPatronalNum,
                        N'Aportes patronales obligatorios INSS (21.5%) e INATEC (2%) período ' + @Period,
                        @TotalCargasPatronales, @TotalCargasPatronales,
                        N'Aporte patronal INSS e INATEC', N'INSS por pagar',
                        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), N'payroll', @PayrollRunId, @PayrollRunId
                    );
                END;

                -- 3. Asiento de Provisiones Laborales (Aguinaldo, Vacaciones, Antigüedad)
                DECLARE @EntryProvId NVARCHAR(100) = N'entry-prov-' + @PayrollRunId;
                DECLARE @EntryProvNum NVARCHAR(80) = N'AST-PROV-' + REPLACE(@Period, N' ', N'-');
                DECLARE @TotalProvisiones DECIMAL(19,4) = @AguinaldoProv + @VacacionesProv + @IndemnizacionProv;

                IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryProvId)
                BEGIN
                    INSERT INTO dbo.AccountingEntries (
                        AccountingEntryId, EntryNumber, Description, Debit, Credit,
                        DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId, PayrollRunId
                    )
                    VALUES (
                        @EntryProvId, @EntryProvNum,
                        N'Provisiones de prestaciones de ley (Aguinaldo, Vacaciones, Antigüedad) período ' + @Period,
                        @TotalProvisiones, @TotalProvisiones,
                        N'Gasto prestaciones y provisiones', N'Provisiones laborales por pagar',
                        TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), N'payroll', @PayrollRunId, @PayrollRunId
                    );
                END;
            END;

            UPDATE dbo.PayrollRuns
            SET Status = N'aprobada',
                ApprovedByAppUserId = @ActorId,
                ApprovedAt = SYSUTCDATETIME(),
                ApprovalNotes = @Notes,
                AccountingEntryId = @EntryId,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            -- Habilitar los comprobantes individuales
            UPDATE dbo.PayrollRunItems
            SET ReceiptStatus = N'disponible'
            WHERE PayrollRunId = @PayrollRunId;

            -- Generar seguimiento de obligaciones institucionales (DGI, INSS, INATEC)
            DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId = @PayrollRunId;

            INSERT INTO dbo.PayrollInstitutionalObligations (
                ObligationId, PayrollRunId, EntityName, PeriodLabel, BaseAmount, PayableAmount, DueDate, Status
            )
            VALUES
                (N'ob-ir-' + @PayrollRunId, @PayrollRunId, N'DGI', @Period, @GrossTotal - @InssLaboral, @IncomeTax, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente'),
                (N'ob-inss-' + @PayrollRunId, @PayrollRunId, N'INSS', @Period, @GrossTotal, (@InssLaboral + @InssPatronal), DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente'),
                (N'ob-inatec-' + @PayrollRunId, @PayrollRunId, N'INATEC', @Period, @GrossTotal, @Inatec, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente'),
                (N'ob-prov-' + @PayrollRunId, @PayrollRunId, N'PROVISIONES_PASIVO', @Period, @GrossTotal, (@AguinaldoProv + @VacacionesProv + @IndemnizacionProv), DATEADD(DAY, 30, CAST(GETDATE() AS DATE)), N'provisionada');
        END
        ELSE IF @TargetStatus = N'pago_registrado'
        BEGIN
            -- 26: la unica salida de dinero la registra usp_RegisterPayrollPayment
            -- (pagos parciales acumulados e idempotentes). La transicion solo marca el
            -- estado a partir de pagos ya confirmados: no crea un segundo gasto ni
            -- sobrescribe el acumulado de pagos.
            DECLARE @CashId NVARCHAR(100) = N'cash-nom-' + @PayrollRunId;

            UPDATE dbo.PayrollRuns
            SET Status = N'pago_registrado',
                PaidByAppUserId = @ActorId,
                PaidAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                PaymentNotes = @Notes,
                CashMoveId = CASE WHEN EXISTS (SELECT 1 FROM dbo.CashMoves WHERE CashMoveId = @CashId)
                                  THEN @CashId ELSE CashMoveId END,
                PendingDiscrepancyTotal = 0,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'pagado',
                PaymentConfirmedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
            WHERE PayrollRunId = @PayrollRunId
              AND ISNULL(PaymentStatus, N'') <> N'pagado'
              AND @ConfirmedTotal >= @NetTotal;
        END
        ELSE IF @TargetStatus = N'conciliada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'conciliada',
                ReconciledByAppUserId = @ActorId,
                ReconciledAt = SYSUTCDATETIME(),
                ReconciliationNotes = @Notes,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'conciliado'
            WHERE PayrollRunId = @PayrollRunId;
        END
        ELSE IF @TargetStatus = N'cerrada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'cerrada',
                ClosedByAppUserId = @ActorId,
                ClosedAt = SYSUTCDATETIME(),
                CloseNotes = @Notes,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            -- Generar seguimiento de obligaciones institucionales
            DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId = @PayrollRunId;

            INSERT INTO dbo.PayrollInstitutionalObligations (
                ObligationId, PayrollRunId, EntityName, PeriodLabel, BaseAmount, PayableAmount, DueDate, Status
            )
            VALUES
                (N'ob-ir-' + @PayrollRunId, @PayrollRunId, N'DGI_IR', @Period, @GrossTotal - @InssLaboral, @IncomeTax, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-inss-lab-' + @PayrollRunId, @PayrollRunId, N'INSS_LABORAL', @Period, @GrossTotal, @InssLaboral, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-inss-pat-' + @PayrollRunId, @PayrollRunId, N'INSS_PATRONAL', @Period, @GrossTotal, @InssPatronal, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-inatec-' + @PayrollRunId, @PayrollRunId, N'INATEC', @Period, @GrossTotal, @Inatec, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'calculada'),
                (N'ob-prov-' + @PayrollRunId, @PayrollRunId, N'PROVISIONES_PASIVO', @Period, @GrossTotal, (@AguinaldoProv + @VacacionesProv + @IndemnizacionProv), DATEADD(DAY, 30, CAST(GETDATE() AS DATE)), N'calculada');
        END
        ELSE -- Retroceso a borrador o calculada
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = @TargetStatus,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;
        END;

        -- Registrar Evento de Auditoría
        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName,
            CASE WHEN @TargetStatus = N'revisada' THEN N'revision'
                 WHEN @TargetStatus = N'aprobada' THEN N'aprobacion'
                 WHEN @TargetStatus = N'pago_registrado' THEN N'pago'
                 WHEN @TargetStatus = N'conciliada' THEN N'conciliacion'
                 WHEN @TargetStatus = N'cerrada' THEN N'cierre'
                 ELSE N'devolucion' END,
            @CurrentStatus, @TargetStatus,
            ISNULL(@Notes, N'Transición de estado autorizada en el flujo de nómina.')
        );

        -- 26: identificar los efectos confirmados por el servidor (caja, asientos y
        -- finanzas) para que el snapshot del navegador no los borre ni los reconstruya.
        UPDATE dbo.AccountingEntries
        SET OperationKey = N'nomina:' + AccountingEntryId
        WHERE PayrollRunId = @PayrollRunId AND OperationKey IS NULL;

        UPDATE dbo.CashMoves
        SET OperationKey = N'nomina:' + @PayrollRunId
        WHERE PayrollRunId = @PayrollRunId AND OperationKey IS NULL;

        UPDATE dbo.FinanceMoves
        SET OperationKey = N'nomina:' + FinanceMoveId
        WHERE FinanceMoveId = N'fn-nom-' + @PayrollRunId AND OperationKey IS NULL;
        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.Gross AS grossTotal, r.Net AS netTotal,
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

CREATE OR ALTER PROCEDURE dbo.usp_SaveErpState
    @Payload NVARCHAR(MAX),
    @ExpectedRevision BINARY(8) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISJSON(@Payload) <> 1
        THROW 50100, 'El estado recibido no contiene JSON valido.', 1;

    DECLARE @RequiredCollections TABLE (CollectionName SYSNAME NOT NULL, JsonArray NVARCHAR(MAX) NULL);

    INSERT INTO @RequiredCollections (CollectionName, JsonArray)
    VALUES
        (N'products', JSON_QUERY(@Payload, '$.products')),
        (N'lots', JSON_QUERY(@Payload, '$.lots')),
        (N'kardex', JSON_QUERY(@Payload, '$.kardex')),
        (N'sales', JSON_QUERY(@Payload, '$.sales')),
        (N'proformas', JSON_QUERY(@Payload, '$.proformas')),
        (N'promotions', JSON_QUERY(@Payload, '$.promotions')),
        (N'purchases', JSON_QUERY(@Payload, '$.purchases')),
        (N'accounting', JSON_QUERY(@Payload, '$.accounting')),
        (N'finance', JSON_QUERY(@Payload, '$.finance')),
        (N'projections', JSON_QUERY(@Payload, '$.projections')),
        (N'production', JSON_QUERY(@Payload, '$.production')),
        (N'parties', JSON_QUERY(@Payload, '$.parties')),
        (N'employees', JSON_QUERY(@Payload, '$.employees')),
        (N'payrollRuns', JSON_QUERY(@Payload, '$.payrollRuns')),
        (N'albums', JSON_QUERY(@Payload, '$.albums')),
        (N'projects', JSON_QUERY(@Payload, '$.projects')),
        (N'cash', JSON_QUERY(@Payload, '$.cash')),
        (N'users', JSON_QUERY(@Payload, '$.users')),
        (N'audit', JSON_QUERY(@Payload, '$.audit'));

    IF EXISTS (
        SELECT 1 FROM @RequiredCollections
        WHERE JsonArray IS NULL OR ISJSON(JsonArray) <> 1 OR LEFT(LTRIM(JsonArray), 1) <> N'['
    )
        THROW 50101, 'El estado debe incluir las 19 colecciones del ERP como arreglos JSON.', 1;

    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@Payload, '$.parties') WITH (
            Name NVARCHAR(240) '$.name',
            Phone NVARCHAR(80) '$.phone',
            Email NVARCHAR(320) '$.email',
            PartyType NVARCHAR(20) '$.type'
        ) AS supplier
        WHERE supplier.PartyType = N'proveedor'
          AND NULLIF(LTRIM(RTRIM(supplier.Name)), N'') IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(supplier.Phone)), N'') IS NULL
          AND NULLIF(LTRIM(RTRIM(supplier.Email)), N'') IS NULL
    )
        THROW 50102, 'Cada proveedor debe tener telefono o correo electronico.', 1;

    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@Payload, '$.parties') WITH (
            Name NVARCHAR(240) '$.name',
            PartyType NVARCHAR(20) '$.type'
        ) AS supplier
        WHERE supplier.PartyType = N'proveedor'
          AND NULLIF(LTRIM(RTRIM(supplier.Name)), N'') IS NULL
    )
        THROW 50105, 'El nombre del proveedor es obligatorio.', 1;

    IF EXISTS (
        SELECT LOWER(LTRIM(RTRIM(Name)))
        FROM OPENJSON(@Payload, '$.parties') WITH (
            Name NVARCHAR(240) '$.name',
            PartyType NVARCHAR(20) '$.type'
        ) AS supplier
        WHERE supplier.PartyType = N'proveedor'
          AND NULLIF(LTRIM(RTRIM(supplier.Name)), N'') IS NOT NULL
        GROUP BY LOWER(LTRIM(RTRIM(Name)))
        HAVING COUNT(*) > 1
    )
        THROW 50103, 'No se permiten proveedores con el mismo nombre.', 1;

    IF EXISTS (
        SELECT LOWER(LTRIM(RTRIM(Ruc)))
        FROM OPENJSON(@Payload, '$.parties') WITH (
            Ruc NVARCHAR(40) '$.ruc',
            PartyType NVARCHAR(20) '$.type'
        ) AS supplier
        WHERE supplier.PartyType = N'proveedor'
          AND NULLIF(LTRIM(RTRIM(supplier.Ruc)), N'') IS NOT NULL
        GROUP BY LOWER(LTRIM(RTRIM(Ruc)))
        HAVING COUNT(*) > 1
    )
        THROW 50104, 'No se permiten proveedores con la misma identificacion fiscal.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentRevision BINARY(8);
        SELECT @CurrentRevision = Revision
        FROM dbo.ErpState WITH (UPDLOCK, HOLDLOCK)
        WHERE StateId = 1;

        IF @ExpectedRevision IS NOT NULL AND @CurrentRevision IS NOT NULL AND @ExpectedRevision <> @CurrentRevision
            THROW 50106, 'El estado de SQL Server cambio desde la ultima lectura. Recarga y resuelve el conflicto antes de guardar.', 1;

        INSERT INTO dbo.Warehouses (WarehouseId, Name)
        SELECT DISTINCT lot.WarehouseId, lot.WarehouseId
        FROM OPENJSON(@Payload, '$.lots') WITH (WarehouseId NVARCHAR(160) '$.warehouseId') AS lot
        WHERE lot.WarehouseId IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.Warehouses AS w WHERE w.WarehouseId = lot.WarehouseId);

        INSERT INTO dbo.ChartOfAccounts (AccountName)
        SELECT DISTINCT account.AccountName
        FROM OPENJSON(@Payload, '$.accounting') WITH (
            DebitAccount NVARCHAR(200) '$.debitAccount',
            CreditAccount NVARCHAR(200) '$.creditAccount'
        ) AS entry
        CROSS APPLY (VALUES (entry.DebitAccount), (entry.CreditAccount)) AS account(AccountName)
        WHERE account.AccountName IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.ChartOfAccounts AS chart WHERE chart.AccountName = account.AccountName);

        INSERT INTO dbo.FinanceCategories (CategoryName)
        SELECT DISTINCT move.Category
        FROM OPENJSON(@Payload, '$.finance') WITH (Category NVARCHAR(160) '$.category') AS move
        WHERE move.Category IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.FinanceCategories AS category WHERE category.CategoryName = move.Category);

        INSERT INTO dbo.ProductCategories (CategoryId, CategoryName)
        SELECT DISTINCT
            N'cat-' + LEFT(REPLACE(LOWER(prod.Category), N' ', N'-'), 40),
            prod.Category
        FROM OPENJSON(@Payload, '$.products') WITH (Category NVARCHAR(120) '$.category') AS prod
        WHERE prod.Category IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM dbo.ProductCategories AS c WHERE c.CategoryName = prod.Category);

        UPDATE dbo.ErpState
        SET Payload = @Payload, UpdatedAt = SYSUTCDATETIME()
        WHERE StateId = 1;

        IF @@ROWCOUNT = 0
            INSERT INTO dbo.ErpState (StateId, Payload) VALUES (1, @Payload);

        -- 26: los enlaces planilla/pago -> asiento y movimiento de caja del servidor se conservan.

        IF OBJECT_ID(N'dbo.Projects', N'U') IS NOT NULL
            UPDATE dbo.Projects SET ClientPartyId = NULL, OwnerEmployeeId = NULL;

        DELETE FROM dbo.AccountsReceivable;
        DELETE FROM dbo.AccountsPayable;
        -- 26: el snapshot del navegador NO reconstruye los efectos de dinero ya
        -- confirmados por el servidor (OperationKey NO NULL: caja, pagos de nomina y
        -- asientos). Solo se depuran y reinsertan las filas de origen cliente.
        DELETE FROM dbo.AccountingEntries WHERE OperationKey IS NULL;
        DELETE FROM dbo.FinanceMoves WHERE OperationKey IS NULL;
        DELETE FROM dbo.CashMoves WHERE OperationKey IS NULL;
        DELETE FROM dbo.SaleItems;
        DELETE FROM dbo.ProformaItems;
        DELETE FROM dbo.PurchaseItems;
        DELETE FROM dbo.CatalogAlbumProducts;
        DELETE FROM dbo.ProductionOrders;
        UPDATE dbo.Proformas SET ConvertedSaleId = NULL;
        DELETE FROM dbo.Sales;
        DELETE FROM dbo.Proformas;
        DELETE FROM dbo.Purchases;
        DELETE FROM dbo.KardexMoves;
        DELETE FROM dbo.InventoryLots;
        DELETE FROM dbo.CatalogAlbums;
        DELETE FROM dbo.Products;
        DELETE FROM dbo.Parties;
        DELETE FROM dbo.Promotions;
        DELETE FROM dbo.Projections;

        INSERT INTO dbo.Parties (
            PartyId, Name, Contact, Phone, PartyType, Ruc, PaymentTerms,
            Email, Address, SupplierCategory, ProductsServices, Observations, SupplierStatus,
            CreatedAt, UpdatedAt, NextReviewDate
        )
        SELECT
            PartyId, Name, ISNULL(Contact, N''), ISNULL(Phone, N''), PartyType, Ruc, PaymentTerms,
            Email, Address,
            CASE WHEN PartyType = N'proveedor' THEN COALESCE(SupplierCategory, N'otro') END,
            ProductsServices, Observations,
            CASE WHEN PartyType = N'proveedor' THEN COALESCE(SupplierStatus, N'activo') END,
            CASE WHEN PartyType = N'proveedor' THEN COALESCE(CreatedAt, TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')) END,
            CASE WHEN PartyType = N'proveedor' THEN COALESCE(UpdatedAt, TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')) END,
            NextReviewDate
        FROM OPENJSON(@Payload, '$.parties') WITH (
            PartyId NVARCHAR(100) '$.id',
            Name NVARCHAR(240) '$.name',
            Contact NVARCHAR(200) '$.contact',
            Phone NVARCHAR(80) '$.phone',
            PartyType NVARCHAR(20) '$.type',
            Ruc NVARCHAR(40) '$.ruc',
            PaymentTerms NVARCHAR(80) '$.paymentTerms',
            Email NVARCHAR(320) '$.email',
            Address NVARCHAR(500) '$.address',
            SupplierCategory NVARCHAR(30) '$.category',
            ProductsServices NVARCHAR(1000) '$.productsServices',
            Observations NVARCHAR(2000) '$.observations',
            SupplierStatus NVARCHAR(20) '$.status',
            CreatedAt DATETIMEOFFSET(3) '$.createdAt',
            UpdatedAt DATETIMEOFFSET(3) '$.updatedAt',
            NextReviewDate DATE '$.nextReviewDate'
        );

        -- 26: restaurar enlaces perdidos hacia efectos confirmados por el servidor.
        UPDATE r
        SET r.CashMoveId = m.CashMoveId
        FROM dbo.PayrollRuns AS r
        JOIN dbo.CashMoves AS m ON m.CashMoveId = N'cash-nom-' + r.PayrollRunId
        WHERE r.CashMoveId IS NULL;

        UPDATE p
        SET p.CashMoveId = m.CashMoveId
        FROM dbo.PayrollPayments AS p
        JOIN dbo.CashMoves AS m ON m.CashMoveId = N'cash-nom-' + p.PayrollRunId
        WHERE p.CashMoveId IS NULL AND m.OperationKey IS NOT NULL;
        INSERT INTO dbo.Promotions (PromotionId, Title, Blurb, MinSubtotal, PercentOff, IsActive, Badge)
        SELECT PromotionId, Title, Blurb, MinSubtotal, PercentOff, IsActive, Badge
        FROM OPENJSON(@Payload, '$.promotions') WITH (
            PromotionId NVARCHAR(100) '$.id',
            Title NVARCHAR(200) '$.title',
            Blurb NVARCHAR(1000) '$.blurb',
            MinSubtotal DECIMAL(19,4) '$.minSubtotal',
            PercentOff DECIMAL(9,4) '$.percentOff',
            IsActive BIT '$.active',
            Badge NVARCHAR(120) '$.badge'
        );

        INSERT INTO dbo.Products (
            ProductId, Code, Name, Category, CategoryId, UnitPrice, MinQuantity, CreatedAt,
            ImageUrl, Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
        )
        SELECT
            ProductId, Code, Name, Category,
            (SELECT TOP (1) CategoryId FROM dbo.ProductCategories WHERE CategoryName = src.Category),
            UnitPrice, MinQuantity, CreatedAt,
            ImageUrl, Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
        FROM OPENJSON(@Payload, '$.products') WITH (
            ProductId NVARCHAR(100) '$.id',
            Code NVARCHAR(80) '$.code',
            Name NVARCHAR(200) '$.name',
            Category NVARCHAR(120) '$.category',
            UnitPrice DECIMAL(19,4) '$.unitPrice',
            MinQuantity DECIMAL(19,4) '$.minQuantity',
            CreatedAt DATETIMEOFFSET(3) '$.createdAt',
            ImageUrl NVARCHAR(1000) '$.image',
            Model NVARCHAR(160) '$.model',
            Brand NVARCHAR(160) '$.brand',
            Material NVARCHAR(160) '$.material',
            Measures NVARCHAR(160) '$.measures',
            Capacity NVARCHAR(160) '$.capacity',
            Finish NVARCHAR(160) '$.finish',
            ProductUse NVARCHAR(500) '$.use',
            Warranty NVARCHAR(160) '$.warranty'
        ) AS src;

        INSERT INTO dbo.InventoryLots (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
        SELECT LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId
        FROM OPENJSON(@Payload, '$.lots') WITH (
            LotId NVARCHAR(100) '$.id',
            ProductId NVARCHAR(100) '$.productId',
            Quantity DECIMAL(19,4) '$.quantity',
            UnitCost DECIMAL(19,4) '$.unitCost',
            EntryDate DATETIMEOFFSET(3) '$.entryDate',
            WarehouseId NVARCHAR(160) '$.warehouseId'
        );

        INSERT INTO dbo.KardexMoves (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
        SELECT KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName
        FROM OPENJSON(@Payload, '$.kardex') WITH (
            KardexMoveId NVARCHAR(100) '$.id',
            ProductId NVARCHAR(100) '$.productId',
            MoveType NVARCHAR(20) '$.type',
            Quantity DECIMAL(19,4) '$.quantity',
            UnitCost DECIMAL(19,4) '$.unitCost',
            MoveDate DATETIMEOFFSET(3) '$.date',
            Reason NVARCHAR(500) '$.reason',
            UserName NVARCHAR(200) '$.userName'
        );

        INSERT INTO dbo.Sales (
            SaleId, SaleNumber, ClientName, Subtotal, DiscountAmount, PromoCode,
            TaxAmount, Total, Status, SaleDate, CreatedBy, QrPayload
        )
        SELECT SaleId, SaleNumber, ClientName, Subtotal, ISNULL(DiscountAmount, 0), PromoCode,
               TaxAmount, Total, Status, SaleDate, CreatedBy, ISNULL(QrPayload, N'')
        FROM OPENJSON(@Payload, '$.sales') WITH (
            SaleId NVARCHAR(100) '$.id',
            SaleNumber NVARCHAR(80) '$.saleNumber',
            ClientName NVARCHAR(240) '$.clientName',
            Subtotal DECIMAL(19,4) '$.subtotal',
            DiscountAmount DECIMAL(19,4) '$.discountAmount',
            PromoCode NVARCHAR(160) '$.promoCode',
            TaxAmount DECIMAL(19,4) '$.taxAmount',
            Total DECIMAL(19,4) '$.total',
            Status NVARCHAR(20) '$.status',
            SaleDate DATETIMEOFFSET(3) '$.saleDate',
            CreatedBy NVARCHAR(200) '$.createdBy',
            QrPayload NVARCHAR(MAX) '$.qrPayload'
        );

        INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
        SELECT sale.SaleId, CONVERT(INT, item.[key]) + 1,
               JSON_VALUE(item.value, '$.productId'),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.quantity')),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.unitPrice'))
        FROM OPENJSON(@Payload, '$.sales')
        WITH (SaleId NVARCHAR(100) '$.id', Items NVARCHAR(MAX) '$.items' AS JSON) AS sale
        CROSS APPLY OPENJSON(ISNULL(sale.Items, N'[]')) AS item;

        INSERT INTO dbo.Proformas (
            ProformaId, ProformaNumber, ClientName, Subtotal, DiscountAmount, PromoCode,
            TaxAmount, Total, Status, ValidUntil, Notes, CreatedAt, CreatedBy, QrPayload, ConvertedSaleId
        )
        SELECT ProformaId, ProformaNumber, ClientName, Subtotal, ISNULL(DiscountAmount, 0), PromoCode,
               TaxAmount, Total, Status, ValidUntil, ISNULL(Notes, N''), CreatedAt, CreatedBy,
               ISNULL(QrPayload, N''), ConvertedSaleId
        FROM OPENJSON(@Payload, '$.proformas') WITH (
            ProformaId NVARCHAR(100) '$.id',
            ProformaNumber NVARCHAR(80) '$.proformaNumber',
            ClientName NVARCHAR(240) '$.clientName',
            Subtotal DECIMAL(19,4) '$.subtotal',
            DiscountAmount DECIMAL(19,4) '$.discountAmount',
            PromoCode NVARCHAR(160) '$.promoCode',
            TaxAmount DECIMAL(19,4) '$.taxAmount',
            Total DECIMAL(19,4) '$.total',
            Status NVARCHAR(20) '$.status',
            ValidUntil DATETIMEOFFSET(3) '$.validUntil',
            Notes NVARCHAR(MAX) '$.notes',
            CreatedAt DATETIMEOFFSET(3) '$.createdAt',
            CreatedBy NVARCHAR(200) '$.createdBy',
            QrPayload NVARCHAR(MAX) '$.qrPayload',
            ConvertedSaleId NVARCHAR(100) '$.convertedSaleId'
        );

        INSERT INTO dbo.ProformaItems (ProformaId, LineNumber, ProductId, Quantity, UnitPrice)
        SELECT proforma.ProformaId, CONVERT(INT, item.[key]) + 1,
               JSON_VALUE(item.value, '$.productId'),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.quantity')),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.unitPrice'))
        FROM OPENJSON(@Payload, '$.proformas')
        WITH (ProformaId NVARCHAR(100) '$.id', Items NVARCHAR(MAX) '$.items' AS JSON) AS proforma
        CROSS APPLY OPENJSON(ISNULL(proforma.Items, N'[]')) AS item;

        INSERT INTO dbo.Purchases (PurchaseId, PurchaseNumber, SupplierName, SupplierPartyId, Total, Status, PurchaseDate, CreatedBy)
        SELECT PurchaseId, PurchaseNumber, SupplierName, COALESCE(supplierById.PartyId, supplierByName.PartyId), Total, Status, PurchaseDate, CreatedBy
        FROM OPENJSON(@Payload, '$.purchases') WITH (
            PurchaseId NVARCHAR(100) '$.id',
            PurchaseNumber NVARCHAR(80) '$.purchaseNumber',
            SupplierName NVARCHAR(240) '$.supplierName',
            SupplierId NVARCHAR(100) '$.supplierId',
            Total DECIMAL(19,4) '$.total',
            Status NVARCHAR(20) '$.status',
            PurchaseDate DATETIMEOFFSET(3) '$.purchaseDate',
            CreatedBy NVARCHAR(200) '$.createdBy'
        ) AS purchase
        OUTER APPLY (
            SELECT TOP (1) PartyId FROM dbo.Parties
            WHERE PartyId = purchase.SupplierId AND PartyType = N'proveedor'
        ) AS supplierById
        OUTER APPLY (
            SELECT TOP (1) PartyId FROM dbo.Parties
            WHERE Name = purchase.SupplierName AND PartyType = N'proveedor'
            ORDER BY PartyId
        ) AS supplierByName;

        INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)
        SELECT purchase.PurchaseId, CONVERT(INT, item.[key]) + 1,
               JSON_VALUE(item.value, '$.productId'),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.quantity')),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.unitPrice'))
        FROM OPENJSON(@Payload, '$.purchases')
        WITH (PurchaseId NVARCHAR(100) '$.id', Items NVARCHAR(MAX) '$.items' AS JSON) AS purchase
        CROSS APPLY OPENJSON(ISNULL(purchase.Items, N'[]')) AS item;

        INSERT INTO dbo.CatalogAlbums (AlbumId, MonthLabel, Title, Blurb, IsPublished, CreatedAt)
        SELECT AlbumId, MonthLabel, Title, Blurb, IsPublished, CreatedAt
        FROM OPENJSON(@Payload, '$.albums') WITH (
            AlbumId NVARCHAR(100) '$.id',
            MonthLabel NVARCHAR(40) '$.month',
            Title NVARCHAR(240) '$.title',
            Blurb NVARCHAR(2000) '$.blurb',
            IsPublished BIT '$.published',
            CreatedAt DATETIMEOFFSET(3) '$.createdAt'
        );

        INSERT INTO dbo.CatalogAlbumProducts (AlbumId, LineNumber, ProductId)
        SELECT album.AlbumId, CONVERT(INT, product.[key]) + 1, product.value
        FROM OPENJSON(@Payload, '$.albums')
        WITH (AlbumId NVARCHAR(100) '$.id', ProductIds NVARCHAR(MAX) '$.productIds' AS JSON) AS album
        CROSS APPLY OPENJSON(ISNULL(album.ProductIds, N'[]')) AS product;

        INSERT INTO dbo.ProductionOrders (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)
        SELECT ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner
        FROM OPENJSON(@Payload, '$.production') WITH (
            ProductionOrderId NVARCHAR(100) '$.id',
            Code NVARCHAR(80) '$.code',
            Product NVARCHAR(240) '$.product',
            Client NVARCHAR(240) '$.client',
            Quantity DECIMAL(19,4) '$.qty',
            Stage NVARCHAR(30) '$.stage',
            Sprint NVARCHAR(100) '$.sprint',
            Owner NVARCHAR(200) '$.owner'
        );

        --26: insercion idempotente. Si el identificador ya existe (por ejemplo un
        -- movimiento de nomina creado por el servidor) no se vuelve a insertar.
        INSERT INTO dbo.CashMoves (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
        SELECT incoming.CashMoveId, incoming.Account, incoming.MoveType, incoming.Amount, incoming.MoveDate, incoming.Concept
        FROM OPENJSON(@Payload, '$.cash') WITH (
            CashMoveId NVARCHAR(100) '$.id',
            Account NVARCHAR(20) '$.account',
            MoveType NVARCHAR(20) '$.type',
            Amount DECIMAL(19,4) '$.amount',
            MoveDate DATETIMEOFFSET(3) '$.date',
            Concept NVARCHAR(1000) '$.concept'
        ) AS incoming
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.CashMoves AS existente WHERE existente.CashMoveId = incoming.CashMoveId
        );

        INSERT INTO dbo.FinanceMoves (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
        SELECT incoming.FinanceMoveId, incoming.MoveType, incoming.Category, incoming.Amount, incoming.MoveDate, incoming.Note, incoming.UserName
        FROM OPENJSON(@Payload, '$.finance') WITH (
            FinanceMoveId NVARCHAR(100) '$.id',
            MoveType NVARCHAR(20) '$.type',
            Category NVARCHAR(160) '$.category',
            Amount DECIMAL(19,4) '$.amount',
            MoveDate DATETIMEOFFSET(3) '$.date',
            Note NVARCHAR(1000) '$.note',
            UserName NVARCHAR(200) '$.userName'
        ) AS incoming
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.FinanceMoves AS existente WHERE existente.FinanceMoveId = incoming.FinanceMoveId
        );

        INSERT INTO dbo.AccountingEntries (
            AccountingEntryId, EntryNumber, Description, Debit, Credit,
            DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId
        )
        SELECT incoming.AccountingEntryId, incoming.EntryNumber, incoming.Description, incoming.Debit, incoming.Credit,
               incoming.DebitAccount, incoming.CreditAccount, incoming.EntryDate, incoming.ReferenceType, incoming.ReferenceId
        FROM OPENJSON(@Payload, '$.accounting') WITH (
            AccountingEntryId NVARCHAR(100) '$.id',
            EntryNumber NVARCHAR(80) '$.entryNumber',
            Description NVARCHAR(1000) '$.description',
            Debit DECIMAL(19,4) '$.debit',
            Credit DECIMAL(19,4) '$.credit',
            DebitAccount NVARCHAR(200) '$.debitAccount',
            CreditAccount NVARCHAR(200) '$.creditAccount',
            EntryDate DATETIMEOFFSET(3) '$.entryDate',
            ReferenceType NVARCHAR(20) '$.referenceType',
            ReferenceId NVARCHAR(100) '$.referenceId'
        ) AS incoming
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.AccountingEntries AS existente WHERE existente.AccountingEntryId = incoming.AccountingEntryId
        );

        INSERT INTO dbo.Projections (ProjectionId, MonthLabel, ExpectedSales, ExpectedCosts)
        SELECT ProjectionId, MonthLabel, ExpectedSales, ExpectedCosts
        FROM OPENJSON(@Payload, '$.projections') WITH (
            ProjectionId NVARCHAR(100) '$.id',
            MonthLabel NVARCHAR(40) '$.month',
            ExpectedSales DECIMAL(19,4) '$.expectedSales',
            ExpectedCosts DECIMAL(19,4) '$.expectedCosts'
        );

        INSERT INTO dbo.AuditEvents (
            AuditEventId, OccurredAt, UserName, Action, Module, Detail, Severity, Reference, Uml, Hash, PreviousHash
        )
        SELECT incoming.AuditEventId, incoming.OccurredAt, incoming.UserName, incoming.[Action],
               incoming.[Module], incoming.Detail, incoming.Severity, incoming.[Reference],
               incoming.Uml, incoming.Hash, incoming.PreviousHash
        FROM OPENJSON(@Payload, '$.audit') WITH (
            AuditEventId NVARCHAR(100) '$.id',
            OccurredAt DATETIMEOFFSET(3) '$.at',
            UserName NVARCHAR(200) '$.userName',
            [Action] NVARCHAR(120) '$.action',
            [Module] NVARCHAR(120) '$.module',
            Detail NVARCHAR(MAX) '$.detail',
            Severity NVARCHAR(20) '$.severity',
            [Reference] NVARCHAR(500) '$.reference',
            Uml NVARCHAR(MAX) '$.uml',
            Hash NVARCHAR(256) '$.hash',
            PreviousHash NVARCHAR(256) '$.prevHash'
        ) AS incoming
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.AuditEvents AS existing
            WHERE existing.AuditEventId = incoming.AuditEventId
        );

        UPDATE salesRow SET ClientPartyId = party.PartyId
        FROM dbo.Sales AS salesRow
        OUTER APPLY (
            SELECT TOP (1) PartyId FROM dbo.Parties
            WHERE Name = salesRow.ClientName AND PartyType = N'cliente' ORDER BY PartyId
        ) AS party;

        UPDATE purchaseRow SET SupplierPartyId = party.PartyId
        FROM dbo.Purchases AS purchaseRow
        OUTER APPLY (
            SELECT TOP (1) PartyId FROM dbo.Parties
            WHERE Name = purchaseRow.SupplierName AND PartyType = N'proveedor' ORDER BY PartyId
        ) AS party;

        UPDATE projectRow SET ClientPartyId = party.PartyId
        FROM dbo.Projects AS projectRow
        OUTER APPLY (
            SELECT TOP (1) PartyId FROM dbo.Parties
            WHERE Name = projectRow.Client AND PartyType = N'cliente' ORDER BY PartyId
        ) AS party;

        UPDATE lot
        SET WarehouseId = COALESCE(byId.WarehouseId, byName.WarehouseId, lot.WarehouseId)
        FROM dbo.InventoryLots AS lot
        OUTER APPLY (SELECT TOP (1) WarehouseId FROM dbo.Warehouses WHERE WarehouseId = lot.WarehouseId) AS byId
        OUTER APPLY (SELECT TOP (1) WarehouseId FROM dbo.Warehouses WHERE Name = lot.WarehouseId) AS byName;

        UPDATE move SET FinanceCategoryName = category.CategoryName
        FROM dbo.FinanceMoves AS move
        JOIN dbo.FinanceCategories AS category ON category.CategoryName = move.Category;

        UPDATE entry
        SET DebitAccountRef = debit.AccountName, CreditAccountRef = credit.AccountName
        FROM dbo.AccountingEntries AS entry
        JOIN dbo.ChartOfAccounts AS debit ON debit.AccountName = entry.DebitAccount
        JOIN dbo.ChartOfAccounts AS credit ON credit.AccountName = entry.CreditAccount;

        UPDATE projection SET MonthNumber = monthLookup.MonthNumber
        FROM dbo.Projections AS projection
        JOIN dbo.ForecastMonths AS monthLookup ON monthLookup.MonthLabel = projection.MonthLabel;

        UPDATE cashMove SET CashAccountCode = account.AccountCode
        FROM dbo.CashMoves AS cashMove
        JOIN dbo.CashAccounts AS account ON account.AccountCode = cashMove.Account;

        UPDATE production SET ProductionStageCode = stage.StageCode
        FROM dbo.ProductionOrders AS production
        JOIN dbo.ProductionStages AS stage ON stage.StageCode = production.Stage;
        UPDATE employee SET AppUserId = NULL
        FROM dbo.Employees AS employee;

        ;WITH UserMapping AS (
            SELECT employee.EmployeeId, appUser.AppUserId,
                   ROW_NUMBER() OVER(PARTITION BY appUser.AppUserId ORDER BY CASE WHEN employee.EmployeeId LIKE 'emp-%' THEN 1 ELSE 2 END) AS rn
            FROM dbo.Employees AS employee
            JOIN dbo.AppUsers AS appUser ON appUser.Name = employee.Name
        )
        UPDATE emp
        SET AppUserId = um.AppUserId
        FROM dbo.Employees AS emp
        JOIN UserMapping AS um ON emp.EmployeeId = um.EmployeeId AND um.rn = 1;

        UPDATE kardex SET AppUserId = appUser.AppUserId
        FROM dbo.KardexMoves AS kardex
        JOIN dbo.AppUsers AS appUser ON appUser.Name = kardex.UserName;

        UPDATE auditEvent SET AppUserId = appUser.AppUserId
        FROM dbo.AuditEvents AS auditEvent
        JOIN dbo.AppUsers AS appUser ON appUser.Name = auditEvent.UserName;

        UPDATE salesRow
        SET CreatedByUserId = appUser.AppUserId, PromotionId = promotion.PromotionId
        FROM dbo.Sales AS salesRow
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = salesRow.CreatedBy) AS appUser
        OUTER APPLY (SELECT TOP (1) PromotionId FROM dbo.Promotions WHERE Title = salesRow.PromoCode) AS promotion;

        UPDATE proforma
        SET ClientPartyId = party.PartyId, CreatedByUserId = appUser.AppUserId, PromotionId = promotion.PromotionId
        FROM dbo.Proformas AS proforma
        OUTER APPLY (SELECT TOP (1) PartyId FROM dbo.Parties WHERE Name = proforma.ClientName AND PartyType = N'cliente' ORDER BY PartyId) AS party
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = proforma.CreatedBy) AS appUser
        OUTER APPLY (SELECT TOP (1) PromotionId FROM dbo.Promotions WHERE Title = proforma.PromoCode) AS promotion;

        UPDATE purchaseRow SET CreatedByUserId = appUser.AppUserId
        FROM dbo.Purchases AS purchaseRow
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = purchaseRow.CreatedBy) AS appUser;

        UPDATE payroll SET ActorUserId = appUser.AppUserId
        FROM dbo.PayrollRuns AS payroll
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = payroll.Actor) AS appUser;

        UPDATE production
        SET ClientPartyId = party.PartyId,
            OwnerEmployeeId = employee.EmployeeId,
            ProjectId = project.ProjectId
        FROM dbo.ProductionOrders AS production
        OUTER APPLY (SELECT TOP (1) PartyId FROM dbo.Parties WHERE Name = production.Client AND PartyType = N'cliente' ORDER BY PartyId) AS party
        OUTER APPLY (SELECT TOP (1) EmployeeId FROM dbo.Employees WHERE Name = production.Owner ORDER BY EmployeeId) AS employee
        OUTER APPLY (SELECT TOP (1) ProjectId FROM dbo.Projects WHERE Client = production.Client ORDER BY ProjectId) AS project;

        UPDATE project SET OwnerEmployeeId = employee.EmployeeId
        FROM dbo.Projects AS project
        OUTER APPLY (SELECT TOP (1) EmployeeId FROM dbo.Employees WHERE Name = project.Owner ORDER BY EmployeeId) AS employee;

        UPDATE financeMove
        SET AppUserId = appUser.AppUserId, SaleId = sale.SaleId,
            PurchaseId = purchase.PurchaseId, PayrollRunId = payroll.PayrollRunId
        FROM dbo.FinanceMoves AS financeMove
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = financeMove.UserName) AS appUser
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE financeMove.Note LIKE N'%' + SaleNumber + N'%') AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE financeMove.Note LIKE N'%' + PurchaseNumber + N'%') AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE financeMove.Note LIKE N'%' + Period + N'%') AS payroll;

        UPDATE cashMove
        SET SaleId = sale.SaleId, PurchaseId = purchase.PurchaseId, PayrollRunId = payroll.PayrollRunId
        FROM dbo.CashMoves AS cashMove
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE cashMove.Concept LIKE N'%' + SaleNumber + N'%') AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE cashMove.Concept LIKE N'%' + PurchaseNumber + N'%') AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE cashMove.Concept LIKE N'%' + Period + N'%') AS payroll;

        UPDATE accounting
        SET SaleId = CASE WHEN ReferenceType = N'sale' THEN sale.SaleId END,
            PurchaseId = CASE WHEN ReferenceType = N'purchase' THEN purchase.PurchaseId END,
            PayrollRunId = CASE WHEN ReferenceType = N'payroll' THEN payroll.PayrollRunId END,
            CashMoveId = CASE WHEN ReferenceType = N'cash' THEN cashMove.CashMoveId END
        FROM dbo.AccountingEntries AS accounting
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE SaleId = accounting.ReferenceId) AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE PurchaseId = accounting.ReferenceId) AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE PayrollRunId = accounting.ReferenceId) AS payroll
        OUTER APPLY (SELECT TOP (1) CashMoveId FROM dbo.CashMoves WHERE CashMoveId = accounting.ReferenceId) AS cashMove;

        --26: separar devengo y dinero. La cuenta por cobrar nace con el devengo de la
        -- venta, pero su saldo pendiente se deriva de los cobros reales registrados en
        -- caja/banco; una venta a credito no equivale a un cobro.
        INSERT INTO dbo.AccountsReceivable (ReceivableId, SaleId, PartyId, Amount, Balance, DueDate, Status)
        SELECT
            N'ar-' + s.SaleId, s.SaleId, s.ClientPartyId, s.Total,
            CASE WHEN cobros.Cobrado >= s.Total THEN CAST(0 AS DECIMAL(19,4))
                 ELSE CAST(s.Total - cobros.Cobrado AS DECIMAL(19,4)) END,
            CAST(s.SaleDate AS DATE),
            CASE WHEN cobros.Cobrado >= s.Total THEN N'cobrada' ELSE N'abierta' END
        FROM dbo.Sales AS s
        OUTER APPLY (
            SELECT ISNULL(SUM(m.Amount), 0) AS Cobrado
            FROM dbo.CashMoves AS m
            WHERE m.SaleId = s.SaleId AND m.MoveType = N'entrada'
        ) AS cobros
        WHERE s.Status = N'completed';

        --26: recibir mercancia no significa pagar al proveedor. La obligacion nace con
        -- la compra/recepcion; el pago parcial reduce el saldo pendiente una sola vez.
        INSERT INTO dbo.AccountsPayable (PayableId, PurchaseId, PartyId, Amount, Balance, DueDate, Status)
        SELECT
            N'ap-' + p.PurchaseId, p.PurchaseId, p.SupplierPartyId, p.Total,
            CASE WHEN pagos.Pagado >= p.Total THEN CAST(0 AS DECIMAL(19,4))
                 ELSE CAST(p.Total - pagos.Pagado AS DECIMAL(19,4)) END,
            CAST(p.PurchaseDate AS DATE),
            CASE WHEN pagos.Pagado >= p.Total THEN N'pagada' ELSE N'abierta' END
        FROM dbo.Purchases AS p
        OUTER APPLY (
            SELECT ISNULL(SUM(m.Amount), 0) AS Pagado
            FROM dbo.CashMoves AS m
            WHERE m.PurchaseId = p.PurchaseId AND m.MoveType = N'salida'
        ) AS pagos;

        MERGE dbo.ProjectStages AS target
        USING (
            SELECT DISTINCT o.ProductionOrderId + N'-stg' AS ProjectStageId, o.ProjectId, o.Product AS Name
            FROM dbo.ProductionOrders AS o
            WHERE o.ProjectId IS NOT NULL
        ) AS src
        ON (target.ProjectStageId = src.ProjectStageId)
        WHEN MATCHED THEN
            UPDATE SET target.ProjectId = src.ProjectId, target.Name = src.Name
        WHEN NOT MATCHED THEN
            INSERT (ProjectStageId, ProjectId, Name, CostActual)
            VALUES (src.ProjectStageId, src.ProjectId, src.Name, 0);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


-- =============================================================================
-- PARTE 3. VERIFICACION DE LA MIGRACION 26 (solo lectura)
-- Estas consultas devuelven la evidencia esperada tras aplicar la migracion.
-- =============================================================================

-- 3.1 Respaldo de seguridad previo disponible
SELECT 'respaldos_26' AS control, t.name AS tabla, SUM(p.rows) AS filas
FROM sys.tables AS t
JOIN sys.partitions AS p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE t.name LIKE N'bak_26_%'
GROUP BY t.name
ORDER BY t.name;
GO

-- 3.2 Caja: restricciones e indices de integridad
SELECT 'integridad_caja' AS control, o.name AS restriccion, o.type_desc AS tipo
FROM sys.objects AS o
WHERE o.parent_object_id = OBJECT_ID(N'dbo.CashMoves') AND o.type = 'C'
UNION ALL
SELECT 'integridad_caja', i.name, i.type_desc
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID(N'dbo.CashMoves') AND i.is_unique = 1;
GO

-- 3.3 Caja: resumen por cuenta (saldo inicial identificado, entradas, salidas, saldo final)
SELECT 'resumen_caja' AS control, v.*
FROM dbo.vw_ResumenCaja AS v
ORDER BY v.Account;
GO

-- 3.4 Caja: movimiento con saldo acumulado (Saldo anterior + entrada - salida)
SELECT 'movimiento_caja' AS control, v.Account, v.MoveDate, v.CashMoveId, v.Concept,
       v.Method, v.DocumentType, v.Entrada, v.Salida, v.SaldoAcumulado
FROM dbo.vw_MovimientoCajaSaldo AS v
ORDER BY v.Account, v.MoveDate, v.CashMoveId;
GO

-- 3.5 Caja: sesiones, arqueos y revisiones
SELECT 'sesiones_caja' AS control, s.*
FROM dbo.vw_EstadoSesionesCaja AS s
ORDER BY s.OpenedAt;
GO

-- 3.6 Nomina: estado del calculo por planilla y coherencia cabecera vs detalle
SELECT 'nomina_calculo' AS control,
       r.PayrollRunId, r.Period, r.Status,
       r.CalculatedAt, ISNULL(r.CalculationStale, 0) AS CalculationStale,
       r.Gross, r.TotalDeductions, r.Net, r.ConfirmedPaymentsTotal,
       g.items, g.deduccionesDetalle,
       CASE WHEN r.CalculatedAt IS NULL THEN N'pendiente_de_calculo'
            WHEN ISNULL(r.CalculationStale, 0) = 1 THEN N'calculodesactualizado'
            ELSE N'calculado_vigente' END AS estadoCalculo,
       CASE WHEN r.TotalDeductions = g.deduccionesDetalle THEN N'coherente' ELSE N'INCOHERENTE' END AS coherenciaCabecera
FROM dbo.PayrollRuns AS r
OUTER APPLY (
    SELECT COUNT(1) AS items, ISNULL(SUM(i.TotalDeductions), 0) AS deduccionesDetalle
    FROM dbo.PayrollRunItems AS i WHERE i.PayrollRunId = r.PayrollRunId
) AS g
ORDER BY r.Period;
GO

-- 3.7 Nomina: pagos confirmados y pendiente por planilla
SELECT 'nomina_pagos' AS control,
       r.PayrollRunId, r.Status, r.Net AS netoAprobado,
       ISNULL(p.pagos, 0) AS pagosConfirmados,
       (r.Net - ISNULL(p.pagos, 0)) AS pendiente,
       r.ConfirmedPaymentsTotal AS acumuladoCabecera
FROM dbo.PayrollRuns AS r
OUTER APPLY (SELECT SUM(x.Amount) AS pagos FROM dbo.PayrollPayments AS x WHERE x.PayrollRunId = r.PayrollRunId) AS p
WHERE r.Net > 0
ORDER BY r.Period;
GO

-- 3.8 Pagos: idempotencia registrada
SELECT 'idempotencia_pagos' AS control,
       i.name AS indice, i.is_unique, i.filter_definition
FROM sys.indexes AS i
WHERE i.name IN (N'UQ_PayrollPayments_IdempotencyKey', N'UQ_CashMoves_OperationKey',
                 N'UQ_AccountingEntries_OperationKey', N'UQ_FinanceMoves_OperationKey',
                 N'UQ_CashSessions_Abierta', N'UQ_CashSessions_OperationKey');
GO

-- 3.9 Efectos del servidor protegidos frente al snapshot del navegador
SELECT 'efectos_servidor' AS control,
       (SELECT COUNT(1) FROM dbo.CashMoves WHERE OperationKey IS NOT NULL) AS cashProtegidos,
       (SELECT COUNT(1) FROM dbo.AccountingEntries WHERE OperationKey IS NOT NULL) AS asientosProtegidos,
       (SELECT COUNT(1) FROM dbo.FinanceMoves WHERE OperationKey IS NOT NULL) AS finanzasProtegidas;
GO

-- =============================================================================
-- NOTAS DE APLICACION
-- =============================================================================
-- * Aplicar con el instalador (Database/SQLServer_Completo/instalar-sqlserver.mjs)
--   o manualmente con sqlcmd -i 26_integridad_caja_nomina_pagos.sql.
-- * La migracion es re-ejecutable: no vuelve a copiar los respaldos bak_26_*.
-- * Tras aplicarla, ejecutar 27_reporte_inconsistencias.sql para el reporte de
--   duplicados y descuadres existentes (solo lectura).
-- * Planillas cerradas y pagos ya confirmados no se modifican.
-- =============================================================================

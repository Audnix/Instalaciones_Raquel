/* ============================================================================
   PRUEBAS FUNCIONALES - MIGRACIONES 26 Y 28 (CAJA, NOMINA, PAGOS IDEMPOTENTES)
   ----------------------------------------------------------------------------
   Demuestra con datos reales que:
     - la caja registra apertura, entradas, salidas, saldo y arqueo;
     - el efectivo y la transferencia no se mezclan ni se duplican;
     - un pago de nomina es parcial, acumulativo e idempotente por clave;
     - el servidor rechaza sobrepagos, planillas no aprobadas y montos invalidos;
     - la revision del arqueo exige una persona distinta de quien cerro.

   PARTE A: dentro de una transaccion y SIEMPRE termina en ROLLBACK. No deja datos.
   PARTE B: fixtures con prefijo TEST-VALID-26- / test26- que se eliminan al final.
            Solo toca filas creadas por esta prueba.

   Ejecutar:
     sqlcmd -S 127.0.0.1,51433 -d "Instalaciones Raquel" -E -C -b -f 65001 ^
            -i docs\pruebas_26_transaccion.sql -o docs\pruebas_26_salida.txt -W
   ============================================================================ */
USE [Instalaciones Raquel];
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT OFF;
GO

PRINT N'=====================================================================';
PRINT N'PARTE A - CAMINO FELIZ DENTRO DE UNA TRANSACCION (TERMINA EN ROLLBACK)';
PRINT N'=====================================================================';

BEGIN TRY
    BEGIN TRANSACTION;

    /* ------------------------------------------------------------------
       A.0 Fixture: planilla aprobada y calculada de prueba
       ------------------------------------------------------------------ */
    DECLARE @RunA NVARCHAR(100) = N'TEST-VALID-26-A';
    DECLARE @Now DATETIMEOFFSET(3) = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00');

    INSERT INTO dbo.PayrollRuns (
        PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, Status,
        Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
        TotalDeductions, OtherDeductionsTotal, CalculatedAt, CalculationVersion,
        CalculationStale, ConfirmedPaymentsTotal, PreparedByAppUserId, PreparedAt,
        PaidAt, Actor, CreatedAt, UpdatedAt
    )
    VALUES (
        @RunA, N'TEST-VALID-26', N'mensual', '2026-10-01', '2026-10-31', '2026-10-31', N'aprobada',
        1000.00, 50.00, 215.00, 20.00, 50.00, 900.00, 1235.00,
        100.00, 0.00, @Now, 1,
        0, 0, N'u-super', @Now,
        @Now, N'Prueba automatizada', @Now, @Now
    );

    INSERT INTO dbo.PayrollRunItems (
        PayrollRunId, EmployeeId, PayrollItemId, Gross, InssLaboral, IncomeTax,
        TotalDeductions, Net, InssPatronal, Inatec, Aguinaldo, EmployerCost,
        BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
        InssBase, IrBase, PaymentStatus, ReceiptStatus
    )
    VALUES (
        @RunA, N'e2', N'item-test-26', 1000.00, 50.00, 50.00,
        100.00, 900.00, 215.00, 20.00, 83.33, 1235.00,
        1000.00, 30.00, 240.00, 1000.00,
        1000.00, 950.00, N'pendiente', N'disponible'
    );

    /* ------------------------------------------------------------------
       A.1 Apertura de caja y saldo inicial como operacion identificada
       ------------------------------------------------------------------ */
    EXEC dbo.usp_AbrirCaja
        @Account = N'caja', @Currency = N'C$', @InitialBalance = 1000.00,
        @SessionDate = '2026-10-20', @Notes = N'Apertura de prueba automatizada',
        @ActorId = N'u-super', @ActorName = N'Raquel',
        @OperationKey = N'test26-open-caja';

    DECLARE @SessionId NVARCHAR(100) =
        (SELECT CashSessionId FROM dbo.CashSessions WHERE OperationKey = N'test26-open-caja');

    IF @SessionId IS NULL
        THROW 51001, 'A.1 FALLO: no se creo la sesion de caja.', 1;

    -- Doble clic / reintento: la misma clave devuelve la MISMA sesion.
    EXEC dbo.usp_AbrirCaja
        @Account = N'caja', @Currency = N'C$', @InitialBalance = 1000.00,
        @SessionDate = '2026-10-20', @Notes = N'Reintento de la misma apertura',
        @ActorId = N'u-super', @ActorName = N'Raquel',
        @OperationKey = N'test26-open-caja';

    IF (SELECT COUNT(*) FROM dbo.CashSessions WHERE OperationKey = N'test26-open-caja') <> 1
        THROW 51002, 'A.1 FALLO: la apertura repetida creo una segunda sesion.', 1;

    /* ------------------------------------------------------------------
       A.2 Entradas y salidas de efectivo (siempre importes positivos)
       ------------------------------------------------------------------ */
    EXEC dbo.usp_RegistrarMovimientoCaja
        @Account = N'caja', @MoveType = N'entrada', @Amount = 250.00,
        @Concept = N'Venta de contado de prueba', @Method = N'efectivo',
        @DocumentType = N'venta', @DocumentRef = N'FACT-TEST-26',
        @MoveDate = '2026-10-20', @SessionId = @SessionId,
        @ActorId = N'u-super', @ActorName = N'Raquel',
        @OperationKey = N'test26-caja-entrada';

    -- Reintento identico: no debe crear un segundo ingreso.
    EXEC dbo.usp_RegistrarMovimientoCaja
        @Account = N'caja', @MoveType = N'entrada', @Amount = 250.00,
        @Concept = N'Venta de contado de prueba', @Method = N'efectivo',
        @DocumentType = N'venta', @DocumentRef = N'FACT-TEST-26',
        @MoveDate = '2026-10-20', @SessionId = @SessionId,
        @ActorId = N'u-super', @ActorName = N'Raquel',
        @OperationKey = N'test26-caja-entrada';

    EXEC dbo.usp_RegistrarMovimientoCaja
        @Account = N'caja', @MoveType = N'salida', @Amount = 100.00,
        @Concept = N'Pago de servicio de prueba', @Method = N'efectivo',
        @DocumentType = N'pago_proveedor', @DocumentRef = N'REC-TEST-26',
        @MoveDate = '2026-10-20', @SessionId = @SessionId,
        @ActorId = N'u-super', @ActorName = N'Raquel',
        @OperationKey = N'test26-caja-salida';

    -- Una transferencia afecta el banco, nunca la caja de efectivo.
    EXEC dbo.usp_RegistrarMovimientoCaja
        @Account = N'banco', @MoveType = N'entrada', @Amount = 500.00,
        @Concept = N'Cobro por transferencia de prueba', @Method = N'transferencia',
        @DocumentType = N'cobro', @DocumentRef = N'TRF-TEST-26',
        @MoveDate = '2026-10-20',
        @ActorId = N'u-super', @ActorName = N'Raquel',
        @OperationKey = N'test26-banco-entrada';

    DECLARE @EntradasCaja DECIMAL(19,4) = (
        SELECT ISNULL(SUM(Amount), 0) FROM dbo.CashMoves
        WHERE SessionId = @SessionId AND MoveType = N'entrada' AND DocumentType <> N'apertura'
    );
    DECLARE @SalidasCaja DECIMAL(19,4) = (
        SELECT ISNULL(SUM(Amount), 0) FROM dbo.CashMoves
        WHERE SessionId = @SessionId AND MoveType = N'salida'
    );
    DECLARE @MovsCaja INT = (
        SELECT COUNT(*) FROM dbo.CashMoves WHERE SessionId = @SessionId
    );

    IF @EntradasCaja <> 250.00
        THROW 51003, 'A.2 FALLO: las entradas de caja no suman 250 (reintento duplicado?).', 1;
    IF @SalidasCaja <> 100.00
        THROW 51004, 'A.2 FALLO: las salidas de caja no suman 100.', 1;
    IF @MovsCaja <> 3
        THROW 51005, 'A.2 FALLO: la sesion debe tener 3 movimientos (apertura + entrada + salida).', 1;

    -- La transferencia quedo en banco y NO en la sesion de caja.
    IF EXISTS (SELECT 1 FROM dbo.CashMoves WHERE OperationKey = N'test26-banco-entrada' AND Account <> N'banco')
        THROW 51006, 'A.2 FALLO: la transferencia no quedo en la cuenta banco.', 1;

    -- Saldo demostrable dentro de la sesion: 1000 inicial + 250 - 100 = 1150.
    DECLARE @SaldoCaja DECIMAL(19,4) = (
        SELECT TOP 1 v.SaldoAcumulado
        FROM dbo.vw_MovimientoCajaSaldo AS v
        WHERE v.SessionId = @SessionId AND v.Account = N'caja'
        ORDER BY v.MoveDate DESC, v.MoveTime DESC, v.CashMoveId DESC
    );
    IF @SaldoCaja <> 1150.00
        THROW 51007, 'A.2 FALLO: el saldo acumulado de la sesion no es 1150.', 1;

    -- El resumen de la cuenta refleja el ultimo periodo: inicial 1000, entradas 250, salidas 100, final 1150.
    DECLARE @ResumenIni DECIMAL(19,4) = (SELECT SaldoInicial FROM dbo.vw_ResumenCaja WHERE Account = N'caja');
    DECLARE @ResumenEnt DECIMAL(19,4) = (SELECT TotalEntradas FROM dbo.vw_ResumenCaja WHERE Account = N'caja');
    DECLARE @ResumenSal DECIMAL(19,4) = (SELECT TotalSalidas FROM dbo.vw_ResumenCaja WHERE Account = N'caja');
    DECLARE @ResumenFin DECIMAL(19,4) = (SELECT SaldoFinal FROM dbo.vw_ResumenCaja WHERE Account = N'caja');

    IF @ResumenIni <> 1000.00 OR @ResumenEnt <> 250.00 OR @ResumenSal <> 100.00 OR @ResumenFin <> 1150.00
        THROW 51008, 'A.2 FALLO: vw_ResumenCaja no refleja el periodo vigente (1000/250/100/1150).', 1;

    /* ------------------------------------------------------------------
       A.3 Pago parcial de nomina + reintento idempotente
       ------------------------------------------------------------------ */
    DECLARE @K1 UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
    DECLARE @K2 UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';

    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunA, @Amount = 300.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-TEST-A1', @PaymentDate = '2026-10-20',
        @Notes = N'Pago parcial 1 de prueba', @IdempotencyKey = @K1,
        @ActorId = N'u-super', @ActorName = N'Raquel';

    -- Reintento exacto (doble clic): misma clave, mismo pago.
    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunA, @Amount = 300.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-TEST-A1', @PaymentDate = '2026-10-20',
        @Notes = N'Pago parcial 1 de prueba', @IdempotencyKey = @K1,
        @ActorId = N'u-super', @ActorName = N'Raquel';

    IF (SELECT COUNT(*) FROM dbo.PayrollPayments WHERE PayrollRunId = @RunA) <> 1
        THROW 51010, 'A.3 FALLO: el reintento creo un segundo pago.', 1;
    IF (SELECT Amount FROM dbo.CashMoves WHERE CashMoveId = N'cash-nom-' + @RunA) <> 300.00
        THROW 51011, 'A.3 FALLO: el movimiento de caja no refleja el pago parcial de 300.', 1;

    -- Segundo pago parcial: completa el neto de 900.
    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunA, @Amount = 600.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-TEST-A2', @PaymentDate = '2026-10-20',
        @Notes = N'Pago parcial 2 de prueba (completa el neto)', @IdempotencyKey = @K2,
        @ActorId = N'u-super', @ActorName = N'Raquel';

    IF (SELECT ConfirmedPaymentsTotal FROM dbo.PayrollRuns WHERE PayrollRunId = @RunA) <> 900.00
        THROW 51012, 'A.3 FALLO: el total confirmado no es 900.', 1;
    IF (SELECT COUNT(*) FROM dbo.CashMoves WHERE PayrollRunId = @RunA) <> 1
        THROW 51013, 'A.3 FALLO: la planilla tiene mas de un movimiento de caja (doble egreso).', 1;
    IF (SELECT Amount FROM dbo.CashMoves WHERE PayrollRunId = @RunA) <> 900.00
        THROW 51014, 'A.3 FALLO: el movimiento de caja no se acumulo a 900.', 1;
    IF (SELECT SUM(Amount) FROM dbo.PayrollPayments WHERE PayrollRunId = @RunA) <> 900.00
        THROW 51015, 'A.3 FALLO: la suma de recibos no es 900.', 1;
    IF EXISTS (SELECT 1 FROM dbo.PayrollRunItems WHERE PayrollRunId = @RunA AND PaymentStatus <> N'pagado')
        THROW 51016, 'A.3 FALLO: los items no quedaron marcados como pagados al cubrir el neto.', 1;

    /* ------------------------------------------------------------------
       A.3b Pago INDIVIDUAL por empleado (employeeId informado)
       ------------------------------------------------------------------ */
    DECLARE @RunEmp NVARCHAR(100) = N'TEST-VALID-26-EMP';
    DECLARE @K3 UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';

    INSERT INTO dbo.PayrollRuns (
        PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, Status,
        Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
        TotalDeductions, OtherDeductionsTotal, CalculatedAt, CalculationVersion,
        CalculationStale, ConfirmedPaymentsTotal, PreparedByAppUserId, PreparedAt,
        PaidAt, Actor, CreatedAt, UpdatedAt
    )
    VALUES (
        @RunEmp, N'TEST-VALID-26-EMP', N'mensual', '2026-10-01', '2026-10-31', '2026-10-31', N'aprobada',
        1000.00, 50.00, 215.00, 20.00, 50.00, 900.00, 1235.00,
        100.00, 0.00, @Now, 1,
        0, 0, N'u-super', @Now,
        @Now, N'Prueba automatizada', @Now, @Now
    );

    INSERT INTO dbo.PayrollRunItems (
        PayrollRunId, EmployeeId, PayrollItemId, Gross, InssLaboral, IncomeTax,
        TotalDeductions, Net, InssPatronal, Inatec, Aguinaldo, EmployerCost,
        BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
        InssBase, IrBase, PaymentStatus, ReceiptStatus
    )
    VALUES (
        @RunEmp, N'e2', N'item-test-26-emp', 1000.00, 50.00, 50.00,
        100.00, 900.00, 215.00, 20.00, 83.33, 1235.00,
        1000.00, 30.00, 240.00, 1000.00,
        1000.00, 950.00, N'pendiente', N'disponible'
    );

    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunEmp, @Amount = 250.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-TEST-EMP-1', @PaymentDate = '2026-10-20',
        @Notes = N'Pago individual parcial de prueba', @IdempotencyKey = @K3,
        @EmployeeId = N'e2', @ActorId = N'u-super', @ActorName = N'Raquel';

    IF (SELECT EmployeeId FROM dbo.PayrollPayments WHERE PayrollRunId = @RunEmp AND IdempotencyKey = @K3) <> N'e2'
        THROW 51017, 'A.3b FALLO: el pago individual no quedo asociado al empleado e2.', 1;
    IF (SELECT ConfirmedPaymentsTotal FROM dbo.PayrollRuns WHERE PayrollRunId = @RunEmp) <> 250.00
        THROW 51018, 'A.3b FALLO: el acumulado del pago individual no es 250.', 1;
    IF (SELECT COUNT(*) FROM dbo.CashMoves WHERE PayrollRunId = @RunEmp) <> 1
        THROW 51019, 'A.3b FALLO: el pago individual no dejo exactamente un movimiento de caja.', 1;

    -- Completar el neto individual restante (650) marca los items como pagados.
    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunEmp, @Amount = 650.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-TEST-EMP-2', @PaymentDate = '2026-10-20',
        @Notes = N'Pago individual final de prueba', @IdempotencyKey = '44444444-4444-4444-4444-444444444444',
        @EmployeeId = N'e2', @ActorId = N'u-super', @ActorName = N'Raquel';

    IF (SELECT Amount FROM dbo.CashMoves WHERE CashMoveId = N'cash-nom-' + @RunEmp) <> 900.00
        THROW 51027, 'A.3b FALLO: el movimiento acumulado del pago individual no llego a 900.', 1;

    /* ------------------------------------------------------------------
       A.4 Arqueo y cierre con faltante explicado
       ------------------------------------------------------------------ */
    EXEC dbo.usp_ArquearYCerrarCaja
        @SessionId = @SessionId, @CountedCash = 1145.00,
        @Explanation = N'Faltante de C$ 5.00 detectado en la prueba automatizada',
        @ActorId = N'u-super', @ActorName = N'Raquel';

    DECLARE @Expected DECIMAL(19,4) = (SELECT ExpectedCash FROM dbo.CashSessions WHERE CashSessionId = @SessionId);
    DECLARE @Diff DECIMAL(19,4) = (SELECT Difference FROM dbo.CashSessions WHERE CashSessionId = @SessionId);
    DECLARE @Review NVARCHAR(30) = (SELECT ReviewStatus FROM dbo.CashSessions WHERE CashSessionId = @SessionId);

    IF @Expected <> 1150.00
        THROW 51020, 'A.4 FALLO: el efectivo esperado no es 1150.', 1;
    IF @Diff <> -5.00
        THROW 51021, 'A.4 FALLO: la diferencia del arqueo no es -5.', 1;
    IF @Review <> N'pendiente_revision'
        THROW 51022, 'A.4 FALLO: el arqueo con diferencia no quedo pendiente de revision.', 1;

    /* ------------------------------------------------------------------
       A.5 Revision del arqueo por una persona distinta
       ------------------------------------------------------------------ */
    EXEC dbo.usp_RevisionArqueo
        @SessionId = @SessionId, @Decision = N'revisado',
        @Notes = N'Revisado por segunda persona en la prueba',
        @ActorId = N'u-d526347b40b34400a16d30d83990e3c1', @ActorName = N'Jhonny Garcia';

    IF (SELECT ReviewStatus FROM dbo.CashSessions WHERE CashSessionId = @SessionId) <> N'revisado'
        THROW 51023, 'A.5 FALLO: la revision no quedo registrada.', 1;
    IF (SELECT ReviewedByAppUserId FROM dbo.CashSessions WHERE CashSessionId = @SessionId)
       <> N'u-d526347b40b34400a16d30d83990e3c1'
        THROW 51024, 'A.5 FALLO: el revisor registrado no es la segunda persona.', 1;

    /* ------------------------------------------------------------------
       A.6 Arrastre sugerido: el saldo contado de la sesion cerrada se propone
           como saldo inicial de la proxima apertura de la misma cuenta.
       ------------------------------------------------------------------ */
    DECLARE @SugeridoCaja DECIMAL(19,4) = (SELECT SaldoSugerido FROM dbo.vw_SaldoSugeridoApertura WHERE Account = N'caja');
    DECLARE @OrigenCaja NVARCHAR(30) = (SELECT Origen FROM dbo.vw_SaldoSugeridoApertura WHERE Account = N'caja');

    IF @OrigenCaja <> N'sesion_cerrada'
        THROW 51025, 'A.6 FALLO: la sugerencia no proviene de la ultima sesion cerrada.', 1;
    IF @SugeridoCaja <> 1145.00
        THROW 51026, 'A.6 FALLO: el saldo sugerido por arrastre no es el contado de la sesion cerrada (1145).', 1;

    PRINT N'PARTE A: TODAS LAS ASERCIONES PASARON (se revierte todo con ROLLBACK).';
    PRINT N'  Caja: apertura 1000 + entrada 250 - salida 100 = saldo 1150; arqueo 1145, diferencia -5, revisado por segunda persona.';
    PRINT N'  Nomina: pagos 300 + 600 = 900; el reintento con la misma clave no duplico; un solo CashMove acumulado.';

    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT N'PARTE A: FALLO -> ' + ERROR_MESSAGE();
    PRINT N'  (error ' + CAST(ERROR_NUMBER() AS NVARCHAR(20)) + N', linea ' + CAST(ERROR_LINE() AS NVARCHAR(20)) + N')';
END CATCH;
GO

PRINT N'';
PRINT N'=====================================================================';
PRINT N'PARTE B - RECHAZOS DEL SERVIDOR (FALLAN ANTES DE ESCRIBIR)';
PRINT N'=====================================================================';

/* ---------------------------------------------------------------------------
   B.0 Limpieza de fixtures de pruebas anteriores (solo prefijos de prueba)
   --------------------------------------------------------------------------- */
UPDATE dbo.PayrollRuns SET CashMoveId = NULL WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollHistoryEvents           WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollValidations             WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollNovelties               WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollProjectDistributions    WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollReceiptTickets          WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollPayments                WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.FinanceMoves                   WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.AccountingEntries              WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.CashMoves                      WHERE PayrollRunId LIKE N'TEST-VALID-26-%' OR OperationKey LIKE N'test26-%';
DELETE FROM dbo.PayrollRunItems                WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollRuns                    WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.CashSessions                   WHERE OperationKey LIKE N'test26-%';

/* ---------------------------------------------------------------------------
   B.1 Fixture B: sesion de caja abierta con 500 y planilla aprobada de 900
   --------------------------------------------------------------------------- */
DECLARE @RunB NVARCHAR(100) = N'TEST-VALID-26-B';
DECLARE @NowB DATETIMEOFFSET(3) = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00');

INSERT INTO dbo.PayrollRuns (
    PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, Status,
    Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
    TotalDeductions, OtherDeductionsTotal, CalculatedAt, CalculationVersion,
    CalculationStale, ConfirmedPaymentsTotal, PreparedByAppUserId, PreparedAt,
    PaidAt, Actor, CreatedAt, UpdatedAt
)
VALUES (
    @RunB, N'TEST-VALID-26-B', N'mensual', '2026-10-01', '2026-10-31', '2026-10-31', N'aprobada',
    1000.00, 50.00, 215.00, 20.00, 50.00, 900.00, 1235.00,
    100.00, 0.00, @NowB, 1,
    0, 0, N'u-super', @NowB,
    @NowB, N'Prueba automatizada B', @NowB, @NowB
);
INSERT INTO dbo.PayrollRunItems (
    PayrollRunId, EmployeeId, PayrollItemId, Gross, InssLaboral, IncomeTax,
    TotalDeductions, Net, InssPatronal, Inatec, Aguinaldo, EmployerCost,
    BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
    InssBase, IrBase, PaymentStatus, ReceiptStatus
)
VALUES (
    @RunB, N'e2', N'item-test-26-b', 1000.00, 50.00, 50.00,
    100.00, 900.00, 215.00, 20.00, 83.33, 1235.00,
    1000.00, 30.00, 240.00, 1000.00,
    1000.00, 950.00, N'pendiente', N'disponible'
);

EXEC dbo.usp_AbrirCaja
    @Account = N'caja', @Currency = N'C$', @InitialBalance = 500.00,
    @SessionDate = '2026-10-20', @Notes = N'Sesion de prueba B',
    @ActorId = N'u-super', @ActorName = N'Raquel',
    @OperationKey = N'test26-b-open';

DECLARE @SessionB NVARCHAR(100) =
    (SELECT CashSessionId FROM dbo.CashSessions WHERE OperationKey = N'test26-b-open');

DECLARE @MovB NVARCHAR(100);
SELECT TOP 1 @MovB = CashMoveId FROM dbo.CashMoves WHERE SessionId = @SessionB;

/* ---------------------------------------------------------------------------
   B.2 Abrir una segunda sesion para la misma cuenta -> rechazado
   --------------------------------------------------------------------------- */
BEGIN TRY
    EXEC dbo.usp_AbrirCaja
        @Account = N'caja', @Currency = N'C$', @InitialBalance = 100.00,
        @SessionDate = '2026-10-20', @ActorId = N'u-super', @ActorName = N'Raquel',
        @OperationKey = N'test26-b-open-2';
    PRINT N'B.2 FALLO: permitio abrir dos sesiones de caja simultaneas.';
END TRY
BEGIN CATCH
    PRINT N'B.2 OK - segunda apertura rechazada: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

/* ---------------------------------------------------------------------------
   B.3 Cerrar sin explicar un faltante -> rechazado
   --------------------------------------------------------------------------- */
BEGIN TRY
    EXEC dbo.usp_ArquearYCerrarCaja
        @SessionId = @SessionB, @CountedCash = 495.00, @Explanation = NULL,
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.3 FALLO: cerro un arqueo con faltante sin explicacion.';
END TRY
BEGIN CATCH
    PRINT N'B.3 OK - faltante sin explicacion rechazado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

/* ---------------------------------------------------------------------------
   B.4 Cierre correcto con explicacion y revision por la misma persona -> rechazado
   --------------------------------------------------------------------------- */
EXEC dbo.usp_ArquearYCerrarCaja
    @SessionId = @SessionB, @CountedCash = 495.00,
    @Explanation = N'Faltante de prueba B',
    @ActorId = N'u-super', @ActorName = N'Raquel';

BEGIN TRY
    EXEC dbo.usp_RevisionArqueo
        @SessionId = @SessionB, @Decision = N'revisado',
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.4 FALLO: permitio que quien cerro revisara su propio arqueo.';
END TRY
BEGIN CATCH
    PRINT N'B.4 OK - autorevision rechazada: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

EXEC dbo.usp_RevisionArqueo
    @SessionId = @SessionB, @Decision = N'observado',
    @Notes = N'Revision de segunda persona en prueba B',
    @ActorId = N'u-d526347b40b34400a16d30d83990e3c1', @ActorName = N'Jhonny Garcia';

IF (SELECT ReviewStatus FROM dbo.CashSessions WHERE CashSessionId = @SessionB) = N'observado'
    PRINT N'B.4b OK - segunda persona reviso y dejo constancia (observado).';
ELSE
    PRINT N'B.4b FALLO: no se registro la revision de la segunda persona.';

/* ---------------------------------------------------------------------------
   B.5 Anular un movimiento de una sesion cerrada sin ser administrador -> rechazado
   --------------------------------------------------------------------------- */
BEGIN TRY
    EXEC dbo.usp_AnularMovimientoCaja
        @CashMoveId = @MovB, @Reason = N'Intento de anulacion no autorizado',
        @ActorId = N'u-sales', @ActorName = N'Ana Ventas';
    PRINT N'B.5 FALLO: permitio anular un movimiento de una sesion cerrada sin ser administrador.';
END TRY
BEGIN CATCH
    PRINT N'B.5 OK - anulacion no autorizada rechazada: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

/* ---------------------------------------------------------------------------
   B.6 Montos y cuentas incoherentes en caja -> rechazado
   --------------------------------------------------------------------------- */
BEGIN TRY
    EXEC dbo.usp_RegistrarMovimientoCaja
        @Account = N'caja', @MoveType = N'entrada', @Amount = -5.00,
        @Concept = N'Importe negativo', @Method = N'efectivo',
        @ActorId = N'u-super', @ActorName = N'Raquel', @OperationKey = N'test26-b-neg';
    PRINT N'B.6a FALLO: acepto un importe negativo.';
END TRY
BEGIN CATCH
    PRINT N'B.6a OK - importe negativo rechazado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_RegistrarMovimientoCaja
        @Account = N'banco', @MoveType = N'entrada', @Amount = 10.00,
        @Concept = N'Efectivo en banco', @Method = N'efectivo',
        @ActorId = N'u-super', @ActorName = N'Raquel', @OperationKey = N'test26-b-ef-banco';
    PRINT N'B.6b FALLO: acepto efectivo contra la cuenta banco.';
END TRY
BEGIN CATCH
    PRINT N'B.6b OK - efectivo en banco rechazado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_RegistrarMovimientoCaja
        @Account = N'caja', @MoveType = N'entrada', @Amount = 10.00,
        @Concept = N'Transferencia en caja', @Method = N'transferencia',
        @ActorId = N'u-super', @ActorName = N'Raquel', @OperationKey = N'test26-b-tr-caja';
    PRINT N'B.6c FALLO: acepto una transferencia contra la caja de efectivo.';
END TRY
BEGIN CATCH
    PRINT N'B.6c OK - transferencia en caja rechazada: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

/* ---------------------------------------------------------------------------
   B.7 Pago: sobrepago y monto cero -> rechazado sin dejar rastro
   --------------------------------------------------------------------------- */
BEGIN TRY
    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunB, @Amount = 1000.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-OVER', @PaymentDate = '2026-10-20',
        @IdempotencyKey = '33333333-3333-3333-3333-333333333333',
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.7a FALLO: acepto un pago mayor que el neto pendiente.';
END TRY
BEGIN CATCH
    PRINT N'B.7a OK - sobrepago rechazado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunB, @Amount = 0.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-CERO', @PaymentDate = '2026-10-20',
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.7b FALLO: acepto un pago de importe cero.';
END TRY
BEGIN CATCH
    PRINT N'B.7b OK - pago de importe cero rechazado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

IF (SELECT COUNT(*) FROM dbo.PayrollPayments WHERE PayrollRunId = @RunB) = 0
    PRINT N'B.7c OK - los intentos invalidos no crearon ningun pago.';
ELSE
    PRINT N'B.7c FALLO: los intentos invalidos dejaron pagos registrados.';

/* ---------------------------------------------------------------------------
   B.8 Flujo: no se puede conciliar ni marcar pago sin cumplir los pasos
   --------------------------------------------------------------------------- */
DECLARE @RevB VARBINARY(8);
DECLARE @RevB2 VARBINARY(8);
DECLARE @RevB3 VARBINARY(8);
DECLARE @RevTrasPago VARBINARY(8);

SELECT @RevB  = CONVERT(VARBINARY(8), Revision) FROM dbo.PayrollRuns WHERE PayrollRunId = @RunB;
SELECT @RevB2 = CONVERT(VARBINARY(8), Revision) FROM dbo.PayrollRuns WHERE PayrollRunId = @RunB;
-- Reapertura de la caja B: el subproceso de pago mueve dinero en banco y exige
-- que exista un periodo de banco abierto (regla del servidor, no del cliente).
EXEC dbo.usp_AbrirCaja
    @Account = N'banco', @Currency = N'C$', @InitialBalance = 100.00,
    @SessionDate = '2026-10-20', @Notes = N'Sesion de banco para la prueba B',
    @ActorId = N'u-super', @ActorName = N'Raquel',
    @OperationKey = N'test26-b-banco';
SELECT @RevB3 = CONVERT(VARBINARY(8), Revision) FROM dbo.PayrollRuns WHERE PayrollRunId = @RunB;
PRINT N'B.8.0 OK - periodo de banco abierto para poder pagar; revision de la planilla '
    + CONVERT(VARCHAR(20), @RevB, 1) + N' (no bloquea el cobro).';

BEGIN TRY
    EXEC dbo.usp_TransitionPayrollStatus
        @PayrollRunId = @RunB, @ExpectedRevision = @RevB, @TargetStatus = N'conciliada',
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.8a FALLO: concilio una planilla aprobada sin pago registrado.';
END TRY
BEGIN CATCH
    PRINT N'B.8a OK - conciliacion fuera de orden rechazada: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_TransitionPayrollStatus
        @PayrollRunId = @RunB, @ExpectedRevision = @RevB2, @TargetStatus = N'pago_registrado',
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.8b FALLO: marco pago_registrado sin pagos confirmados.';
END TRY
BEGIN CATCH
    PRINT N'B.8b OK - pago_registrado sin pagos rechazado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

/* ---------------------------------------------------------------------------
   B.9 Pago valido completo, reintento idempotente y pago sobre saldo cero
   --------------------------------------------------------------------------- */
BEGIN TRY
    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunB, @Amount = 900.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-FULL-B', @PaymentDate = '2026-10-20',
        @IdempotencyKey = '44444444-4444-4444-4444-444444444444',
        @ActorId = N'u-super', @ActorName = N'Raquel';

    IF (SELECT ConfirmedPaymentsTotal FROM dbo.PayrollRuns WHERE PayrollRunId = @RunB) = 900.00
        PRINT N'B.9a OK - pago completo de 900 registrado.';
    ELSE
        PRINT N'B.9a FALLO: el total confirmado no es 900.';

    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunB, @Amount = 900.00, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-FULL-B', @PaymentDate = '2026-10-20',
        @IdempotencyKey = '44444444-4444-4444-4444-444444444444',
        @ActorId = N'u-super', @ActorName = N'Raquel';

    IF (SELECT COUNT(*) FROM dbo.PayrollPayments WHERE PayrollRunId = @RunB) = 1
        PRINT N'B.9b OK - el reintento devolvio la misma operacion (1 recibo).';
    ELSE
        PRINT N'B.9b FALLO: el reintento duplico el recibo.';

    IF (SELECT COUNT(*) FROM dbo.CashMoves WHERE PayrollRunId = @RunB) = 1
       AND (SELECT Amount FROM dbo.CashMoves WHERE PayrollRunId = @RunB) = 900.00
        PRINT N'B.9c OK - un solo movimiento de caja por el total acumulado (sin segundo egreso).';
    ELSE
        PRINT N'B.9c FALLO: el movimiento de caja de la planilla es incorrecto.';

    SELECT @RevTrasPago = CONVERT(VARBINARY(8), Revision) FROM dbo.PayrollRuns WHERE PayrollRunId = @RunB;
    PRINT N'B.9d-atencion: la revision de la planilla cambio de ' + CONVERT(VARCHAR(20), @RevB3, 1)
        + N' a ' + CONVERT(VARCHAR(20), @RevTrasPago, 1)
        + N' al registrar el pago (el servidor actualiza el estado economico de la planilla).';
END TRY
BEGIN CATCH
    PRINT N'B.9 FALLO inesperado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_RegisterPayrollPayment
        @PayrollRunId = @RunB, @Amount = 0.01, @PaymentMethod = N'transferencia',
        @PaymentReference = N'TRF-EXTRA', @PaymentDate = '2026-10-20',
        @IdempotencyKey = '55555555-5555-5555-5555-555555555555',
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.9d FALLO: acepto un pago cuando el pendiente ya era cero.';
END TRY
BEGIN CATCH
    PRINT N'B.9d OK - pago sobre saldo cero rechazado: ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
    EXEC dbo.usp_TransitionPayrollStatus
        @PayrollRunId = @RunB, @ExpectedRevision = @RevTrasPago, @TargetStatus = N'pago_registrado',
        @ActorId = N'u-super', @ActorName = N'Raquel';
    PRINT N'B.9e OK - con el neto pagado la planilla paso a pago_registrado.';
END TRY
BEGIN CATCH
    PRINT N'B.9e FALLO: no pudo marcar pago_registrado con el neto pagado: '
        + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
END CATCH;

/* ---------------------------------------------------------------------------
   B.10 Pago sobre planilla no aprobada (planilla calculada real del sistema)
   --------------------------------------------------------------------------- */
DECLARE @RunNoAprobada NVARCHAR(100) = (
    SELECT TOP 1 PayrollRunId FROM dbo.PayrollRuns
    WHERE Status NOT IN (N'aprobada', N'pago_registrado')
      AND PayrollRunId NOT LIKE N'TEST-VALID-26-%'
    ORDER BY CreatedAt DESC
);

IF @RunNoAprobada IS NOT NULL
BEGIN
    BEGIN TRY
        EXEC dbo.usp_RegisterPayrollPayment
            @PayrollRunId = @RunNoAprobada, @Amount = 1.00, @PaymentMethod = N'transferencia',
            @PaymentReference = N'TRF-SIN-APROBAR', @PaymentDate = '2026-10-20',
            @ActorId = N'u-super', @ActorName = N'Raquel';
        PRINT N'B.10 FALLO: acepto pago sobre la planilla no aprobada ' + @RunNoAprobada + N'.';
    END TRY
    BEGIN CATCH
        PRINT N'B.10 OK - pago sobre planilla no aprobada rechazado (' + @RunNoAprobada
            + N'): ' + CAST(ERROR_NUMBER() AS NVARCHAR(10)) + N' ' + ERROR_MESSAGE();
    END CATCH;
END
ELSE
    PRINT N'B.10 OMITIDO: no hay planillas fuera de aprobada/pago_registrado.';

/* ---------------------------------------------------------------------------
   B.11 Limpieza final de los fixtures de prueba
   --------------------------------------------------------------------------- */
UPDATE dbo.PayrollRuns SET CashMoveId = NULL WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollHistoryEvents           WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollValidations             WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollNovelties               WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollProjectDistributions    WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollReceiptTickets          WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollPayments                WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.FinanceMoves                   WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.AccountingEntries              WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.CashMoves                      WHERE PayrollRunId LIKE N'TEST-VALID-26-%' OR OperationKey LIKE N'test26-%';
DELETE FROM dbo.PayrollRunItems                WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.PayrollRuns                    WHERE PayrollRunId LIKE N'TEST-VALID-26-%';
DELETE FROM dbo.CashMoves                      WHERE SessionId IN (SELECT CashSessionId FROM dbo.CashSessions WHERE OperationKey LIKE N'test26-%');
DELETE FROM dbo.CashSessions                   WHERE OperationKey LIKE N'test26-%';
GO

PRINT N'';
IF (SELECT COUNT(*) FROM dbo.PayrollRuns WHERE PayrollRunId LIKE N'TEST-VALID-26-%') = 0
   AND (SELECT COUNT(*) FROM dbo.CashSessions WHERE OperationKey LIKE N'test26-%') = 0
   AND NOT EXISTS (
        SELECT 1 FROM dbo.CashMoves
        WHERE OperationKey LIKE N'test26-%'
           OR OperationKey LIKE N'apertura:%'
           OR CashMoveId LIKE N'cash-ap-%'
           OR CashMoveId LIKE N'cash-nom-%'
   )
    PRINT N'B.11 OK - fixtures de prueba eliminados; no queda rastro en los libros.';
ELSE
    PRINT N'B.11 FALLO: quedaron filas de prueba sin eliminar.';
GO

PRINT N'';
PRINT N'INVENTARIO FINAL: movimientos historicos y de produccion sin alterar';
SELECT Account, COUNT(*) AS Movimientos
FROM dbo.CashMoves AS m
WHERE m.OperationKey IS NULL
GROUP BY Account
ORDER BY Account;
GO

PRINT N'FIN DE LAS PRUEBAS.';
GO

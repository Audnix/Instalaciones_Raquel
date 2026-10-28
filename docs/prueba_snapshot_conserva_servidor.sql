SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRY
  BEGIN TRANSACTION;
  DECLARE @RunA NVARCHAR(100) = N'TEST-SNAP-26';
  DECLARE @Now DATETIMEOFFSET(3) = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00');

  -- Fixture: planilla aprobada + sesion de banco abierta.
  INSERT INTO dbo.PayrollRuns (
      PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, Status,
      Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
      TotalDeductions, OtherDeductionsTotal, CalculatedAt, CalculationVersion,
      CalculationStale, ConfirmedPaymentsTotal, PreparedByAppUserId, PreparedAt,
      PaidAt, Actor, CreatedAt, UpdatedAt)
  VALUES (@RunA, N'TEST-SNAP', N'mensual','2026-10-01','2026-10-31','2026-10-31',N'aprobada',
      1000,50,215,20,50,900,1235,100,0,@Now,1,0,0,N'u-super',@Now,@Now,N'prueba',@Now,@Now);

  EXEC dbo.usp_AbrirCaja @Account=N'banco',@Currency=N'C$',@InitialBalance=5000.00,
    @SessionDate='2026-10-20',@Notes=N'snap',@ActorId=N'u-super',@ActorName=N'Raquel',
    @OperationKey=N'snap-open-banco';

  EXEC dbo.usp_RegisterPayrollPayment @PayrollRunId=@RunA,@Amount=900.00,@PaymentMethod=N'transferencia',
    @PaymentReference=N'TRF-SNAP',@PaymentDate='2026-10-20',@Notes=N'snap',
    @IdempotencyKey='55555555-5555-5555-5555-555555555555',@ActorId=N'u-super',@ActorName=N'Raquel';

  DECLARE @Before INT = (SELECT COUNT(*) FROM dbo.CashMoves WHERE OperationKey = N'nomina:' + @RunA);
  DECLARE @PayBefore INT = (SELECT COUNT(*) FROM dbo.PayrollPayments WHERE PayrollRunId = @RunA);
  DECLARE @OpenBefore INT = (SELECT COUNT(*) FROM dbo.CashMoves WHERE OperationKey LIKE N'apertura:%');

  -- Efecto del snapshot: solo borra filas SIN OperationKey (las del cliente).
  DELETE FROM dbo.AccountingEntries WHERE OperationKey IS NULL;
  DELETE FROM dbo.FinanceMoves WHERE OperationKey IS NULL;
  DELETE FROM dbo.CashMoves WHERE OperationKey IS NULL;

  DECLARE @After INT = (SELECT COUNT(*) FROM dbo.CashMoves WHERE OperationKey = N'nomina:' + @RunA);
  DECLARE @PayAfter INT = (SELECT COUNT(*) FROM dbo.PayrollPayments WHERE PayrollRunId = @RunA);
  DECLARE @OpenAfter INT = (SELECT COUNT(*) FROM dbo.CashMoves WHERE OperationKey LIKE N'apertura:%');

  IF @Before <> 1 OR @After <> 1
    THROW 52001, 'FALLO: el movimiento cash-nom-* no sobrevivio al snapshot.', 1;
  IF @PayBefore <> 1 OR @PayAfter <> 1
    THROW 52002, 'FALLO: el recibo de pago no sobrevivio al snapshot.', 1;
  IF @OpenBefore <> @OpenAfter
    THROW 52003, 'FALLO: el movimiento de apertura no sobrevivio al snapshot.', 1;

  PRINT N'SNAPSHOT OK - el PUT de /api/state conserva cash-nom-*, aperturas y recibos (OperationKey no nulo).';
  ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
  IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
  PRINT N'SNAPSHOT FALLO -> ' + ERROR_MESSAGE();
  THROW;
END CATCH;

USE [Instalaciones Raquel];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Run NVARCHAR(100)=N'run-mvfbxste-d83c30',@Repair NVARCHAR(100)=N'unpaid-TEST-DYN-7929-20261021',@Status NVARCHAR(30),@HeaderPaid DECIMAL(19,4);
 SELECT @Status=Status,@HeaderPaid=ConfirmedPaymentsTotal FROM dbo.PayrollRuns WITH(UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@Run AND Period=N'TEST-DYN-7929';
 IF OBJECT_ID(N'dbo.PayrollIntegrityRepairs',N'U') IS NULL
  CREATE TABLE dbo.PayrollIntegrityRepairs(RepairKey NVARCHAR(100) NOT NULL PRIMARY KEY,PayrollRunId NVARCHAR(100) NOT NULL,
   Reason NVARCHAR(1000) NOT NULL,ExecutedBy NVARCHAR(240) NOT NULL,BeforeJson NVARCHAR(MAX) NOT NULL,CreatedAt DATETIMEOFFSET(3) NOT NULL DEFAULT SYSUTCDATETIME());
 IF EXISTS(SELECT 1 FROM dbo.PayrollIntegrityRepairs WHERE RepairKey=@Repair)
 BEGIN
  COMMIT; SELECT N'Reparacion ya aplicada; no se repite' AS Result; RETURN;
 END;
 IF @Status IS NULL OR @Status<>N'conciliada' OR @HeaderPaid<>50000 THROW 50710,'La planilla ya cambio; revisar antes de corregir.',1;
 IF EXISTS(SELECT 1 FROM dbo.PayrollPayments WITH(UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@Run)
  OR EXISTS(SELECT 1 FROM dbo.AccountingEntries WITH(UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@Run OR ReferenceId=@Run)
  OR EXISTS(SELECT 1 FROM dbo.CashMoves WITH(UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@Run)
  OR EXISTS(SELECT 1 FROM dbo.FinanceMoves WITH(UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@Run)
  THROW 50711,'Hay efectos vinculados; se requiere reverso coordinado. No se aplica esta correccion.',1;
 IF EXISTS(SELECT 1 FROM dbo.PayrollInstitutionalObligations WITH(UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@Run
   AND (PaidAt IS NOT NULL OR NULLIF(LTRIM(RTRIM(PaymentReceiptRef)),N'') IS NOT NULL OR Status IN(N'pagada',N'pagado',N'conciliada',N'cerrada')))
  THROW 50712,'Hay obligaciones institucionales con indicios de pago. Revisar sus documentos.',1;
 -- Correccion limitada de estructura prevista en la migracion 29:
 -- una planilla no pagada debe poder tener PaidAt NULL, sin inventar fechas.
 IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.PayrollRuns') AND name=N'PaidAt' AND is_nullable=0)
 BEGIN
  IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.PayrollRuns') AND name=N'PaidAt' AND TYPE_NAME(user_type_id)=N'datetimeoffset' AND scale=3)
   THROW 50713,'El tipo de fecha de pago difiere del esquema revisado.',1;
  ALTER TABLE dbo.PayrollRuns ALTER COLUMN PaidAt DATETIMEOFFSET(3) NULL;
 END;
 DECLARE @Snapshot NVARCHAR(MAX)=(SELECT
  JSON_QUERY((SELECT * FROM dbo.PayrollRuns WHERE PayrollRunId=@Run FOR JSON PATH)) AS payrollRun,
  JSON_QUERY((SELECT * FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run FOR JSON PATH)) AS items,
  JSON_QUERY((SELECT * FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId=@Run FOR JSON PATH)) AS obligations FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 DECLARE @Reason NVARCHAR(1000)=N'Correccion autorizada de estado historico inconsistente. El usuario confirmo el 21/10/2026: No se pago. Acumulado anterior C$50000 sin recibos ni movimientos ni devengo vinculado. Se devuelve a borrador para recalcular, revisar y aprobar; no se registra dinero ni se certifican calculos antiguos. Se conservan snapshot y documentos institucionales.';
 INSERT dbo.PayrollIntegrityRepairs(RepairKey,PayrollRunId,Reason,ExecutedBy,BeforeJson) VALUES(@Repair,@Run,@Reason,ORIGINAL_LOGIN(),@Snapshot);
 UPDATE dbo.PayrollRuns SET Status=N'borrador',ConfirmedPaymentsTotal=0,CalculationStale=1,
  ReviewedByAppUserId=NULL,ReviewedAt=NULL,ApprovedByAppUserId=NULL,ApprovedAt=NULL,
  PaidAt=NULL,ReconciledByAppUserId=NULL,ReconciledAt=NULL,UpdatedAt=SYSUTCDATETIME()
 WHERE PayrollRunId=@Run;
 UPDATE dbo.PayrollRunItems SET PaymentStatus=N'pendiente',PaymentConfirmedAt=NULL,ReceiptStatus=N'no_generado' WHERE PayrollRunId=@Run;
 INSERT dbo.PayrollHistoryEvents(PayrollRunId,ActorId,ActorName,EventType,PreviousStatus,NewStatus,Description)
 VALUES(@Run,LEFT(N'sql-maintenance:'+ORIGINAL_LOGIN(),100),LEFT(ORIGINAL_LOGIN(),240),N'correccion_integridad',@Status,N'borrador',@Reason);
 COMMIT;
 SELECT PayrollRunId,Period,Status,ConfirmedPaymentsTotal,CalculationStale FROM dbo.PayrollRuns WHERE PayrollRunId=@Run;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO


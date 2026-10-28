/* 32: preservar enlaces de operaciones confirmadas al sincronizar.
   Parche limitado a siete instrucciones conocidas. Si la definicion vigente
   difiere, aborta y exige revision; no sustituye toda la logica con una version antigua.
   Respalda el procedimiento. No modifica datos de negocio ni cuentas. */
USE [Instalaciones Raquel];
GO
SET XACT_ABORT ON;
GO
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Definition NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_SaveErpState'));
 SET @Definition=REPLACE(@Definition,CHAR(13)+CHAR(10),CHAR(10));
 IF @Definition IS NULL THROW 50630,'Se requiere acceso a la definicion de usp_SaveErpState para revisar el parche.',1;
 IF OBJECT_ID(N'dbo.IntegrityProcedureBackups',N'U') IS NULL
  CREATE TABLE dbo.IntegrityProcedureBackups(BackupId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT NEWID(),
   ProcedureName NVARCHAR(200) NOT NULL,Definition NVARCHAR(MAX) NOT NULL,SavedAt DATETIMEOFFSET(3) NOT NULL DEFAULT SYSUTCDATETIME());
 INSERT dbo.IntegrityProcedureBackups(ProcedureName,Definition) VALUES(N'dbo.usp_SaveErpState',@Definition);
 DECLARE @Before NVARCHAR(MAX),@After NVARCHAR(MAX);
 SET @Before=N'        UPDATE financeMove
        SET AppUserId = appUser.AppUserId, SaleId = sale.SaleId,
            PurchaseId = purchase.PurchaseId, PayrollRunId = payroll.PayrollRunId
        FROM dbo.FinanceMoves AS financeMove
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = financeMove.UserName) AS appUser
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE financeMove.Note LIKE N''%'' + SaleNumber + N''%'') AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE financeMove.Note LIKE N''%'' + PurchaseNumber + N''%'') AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE financeMove.Note LIKE N''%'' + Period + N''%'') AS payroll;';
 SET @After=N'        UPDATE financeMove
        SET AppUserId = appUser.AppUserId, SaleId = sale.SaleId,
            PurchaseId = purchase.PurchaseId, PayrollRunId = payroll.PayrollRunId
        FROM dbo.FinanceMoves AS financeMove
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = financeMove.UserName) AS appUser
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE financeMove.Note LIKE N''%'' + SaleNumber + N''%'') AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE financeMove.Note LIKE N''%'' + PurchaseNumber + N''%'') AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE financeMove.Note LIKE N''%'' + Period + N''%'') AS payroll
        WHERE financeMove.OperationKey IS NULL;';
 IF CHARINDEX(@After,@Definition)=0
 BEGIN
  IF CHARINDEX(@Before,@Definition)=0 THROW 50630,'La sincronizacion difiere del patron revisado (financeMove). No se aplica un reemplazo a ciegas.',1;
  SET @Definition=REPLACE(@Definition,@Before,@After);
 END;
 SET @Before=N'        UPDATE cashMove
        SET SaleId = sale.SaleId, PurchaseId = purchase.PurchaseId, PayrollRunId = payroll.PayrollRunId
        FROM dbo.CashMoves AS cashMove
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE cashMove.Concept LIKE N''%'' + SaleNumber + N''%'') AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE cashMove.Concept LIKE N''%'' + PurchaseNumber + N''%'') AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE cashMove.Concept LIKE N''%'' + Period + N''%'') AS payroll;';
 SET @After=N'        UPDATE cashMove
        SET SaleId = sale.SaleId, PurchaseId = purchase.PurchaseId, PayrollRunId = payroll.PayrollRunId
        FROM dbo.CashMoves AS cashMove
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE cashMove.Concept LIKE N''%'' + SaleNumber + N''%'') AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE cashMove.Concept LIKE N''%'' + PurchaseNumber + N''%'') AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE cashMove.Concept LIKE N''%'' + Period + N''%'') AS payroll
        WHERE cashMove.OperationKey IS NULL;';
 IF CHARINDEX(@After,@Definition)=0
 BEGIN
  IF CHARINDEX(@Before,@Definition)=0 THROW 50630,'La sincronizacion difiere del patron revisado (cashMove). No se aplica un reemplazo a ciegas.',1;
  SET @Definition=REPLACE(@Definition,@Before,@After);
 END;
 SET @Before=N'        UPDATE accounting
        SET SaleId = CASE WHEN ReferenceType = N''sale'' THEN sale.SaleId END,
            PurchaseId = CASE WHEN ReferenceType = N''purchase'' THEN purchase.PurchaseId END,
            PayrollRunId = CASE WHEN ReferenceType = N''payroll'' THEN payroll.PayrollRunId END,
            CashMoveId = CASE WHEN ReferenceType = N''cash'' THEN cashMove.CashMoveId END
        FROM dbo.AccountingEntries AS accounting
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE SaleId = accounting.ReferenceId) AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE PurchaseId = accounting.ReferenceId) AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE PayrollRunId = accounting.ReferenceId) AS payroll
        OUTER APPLY (SELECT TOP (1) CashMoveId FROM dbo.CashMoves WHERE CashMoveId = accounting.ReferenceId) AS cashMove;';
 SET @After=N'        UPDATE accounting
        SET SaleId = CASE WHEN ReferenceType = N''sale'' THEN sale.SaleId END,
            PurchaseId = CASE WHEN ReferenceType = N''purchase'' THEN purchase.PurchaseId END,
            PayrollRunId = CASE WHEN ReferenceType = N''payroll'' THEN payroll.PayrollRunId END,
            CashMoveId = CASE WHEN ReferenceType = N''cash'' THEN cashMove.CashMoveId END
        FROM dbo.AccountingEntries AS accounting
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE SaleId = accounting.ReferenceId) AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE PurchaseId = accounting.ReferenceId) AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE PayrollRunId = accounting.ReferenceId) AS payroll
        OUTER APPLY (SELECT TOP (1) CashMoveId FROM dbo.CashMoves WHERE CashMoveId = accounting.ReferenceId) AS cashMove
        WHERE accounting.OperationKey IS NULL;';
 IF CHARINDEX(@After,@Definition)=0
 BEGIN
  IF CHARINDEX(@Before,@Definition)=0 THROW 50630,'La sincronizacion difiere del patron revisado (accounting). No se aplica un reemplazo a ciegas.',1;
  SET @Definition=REPLACE(@Definition,@Before,@After);
 END;
 SET @Before=N'        INSERT INTO dbo.AccountsReceivable (ReceivableId, SaleId, PartyId, Amount, Balance, DueDate, Status)
        SELECT
            N''ar-'' + s.SaleId, s.SaleId, s.ClientPartyId, s.Total,
            CASE WHEN cobros.Cobrado >= s.Total THEN CAST(0 AS DECIMAL(19,4))
                 ELSE CAST(s.Total - cobros.Cobrado AS DECIMAL(19,4)) END,
            CAST(s.SaleDate AS DATE),
            CASE WHEN cobros.Cobrado >= s.Total THEN N''cobrada'' ELSE N''abierta'' END
        FROM dbo.Sales AS s
        OUTER APPLY (
            SELECT ISNULL(SUM(m.Amount), 0) AS Cobrado
            FROM dbo.CashMoves AS m
            WHERE m.SaleId = s.SaleId AND m.MoveType = N''entrada''
        ) AS cobros
        WHERE s.Status = N''completed'';';
 SET @After=N'        INSERT INTO dbo.AccountsReceivable (ReceivableId, SaleId, PartyId, Amount, Balance, DueDate, Status)
        SELECT
            N''ar-'' + s.SaleId, s.SaleId, s.ClientPartyId, s.Total,
            CASE WHEN cobros.Cobrado >= s.Total THEN CAST(0 AS DECIMAL(19,4))
                 ELSE CAST(s.Total - cobros.Cobrado AS DECIMAL(19,4)) END,
            (SELECT d.DueDate FROM @IntegrityReceivableDates d WHERE d.ReceivableId=N''ar-''+s.SaleId), -- conserva fechas existentes
            CASE WHEN cobros.Cobrado >= s.Total THEN N''cobrada'' WHEN cobros.Cobrado>0 THEN N''parcial'' ELSE N''abierta'' END
        FROM dbo.Sales AS s
        OUTER APPLY (
            SELECT ISNULL(SUM(m.Amount), 0) AS Cobrado
            FROM dbo.CashMoves AS m
            WHERE m.SaleId = s.SaleId AND m.MoveType = N''entrada'' AND m.MoveState=N''confirmado''
        ) AS cobros
        WHERE s.Status = N''completed'';';
 IF CHARINDEX(@After,@Definition)=0
 BEGIN
  IF CHARINDEX(@Before,@Definition)=0 THROW 50630,'La logica de AccountsReceivable difiere del patron revisado.',1;
  SET @Definition=REPLACE(@Definition,@Before,@After);
 END;
 SET @Before=N'        INSERT INTO dbo.AccountsPayable (PayableId, PurchaseId, PartyId, Amount, Balance, DueDate, Status)
        SELECT
            N''ap-'' + p.PurchaseId, p.PurchaseId, p.SupplierPartyId, p.Total,
            CASE WHEN pagos.Pagado >= p.Total THEN CAST(0 AS DECIMAL(19,4))
                 ELSE CAST(p.Total - pagos.Pagado AS DECIMAL(19,4)) END,
            CAST(p.PurchaseDate AS DATE),
            CASE WHEN pagos.Pagado >= p.Total THEN N''pagada'' ELSE N''abierta'' END
        FROM dbo.Purchases AS p
        OUTER APPLY (
            SELECT ISNULL(SUM(m.Amount), 0) AS Pagado
            FROM dbo.CashMoves AS m
            WHERE m.PurchaseId = p.PurchaseId AND m.MoveType = N''salida''
        ) AS pagos;';
 SET @After=N'        INSERT INTO dbo.AccountsPayable (PayableId, PurchaseId, PartyId, Amount, Balance, DueDate, Status)
        SELECT
            N''ap-'' + p.PurchaseId, p.PurchaseId, p.SupplierPartyId, p.Total,
            CASE WHEN pagos.Pagado >= p.Total THEN CAST(0 AS DECIMAL(19,4))
                 ELSE CAST(p.Total - pagos.Pagado AS DECIMAL(19,4)) END,
            (SELECT d.DueDate FROM @IntegrityPayableDates d WHERE d.PayableId=N''ap-''+p.PurchaseId), -- conserva fechas existentes
            CASE WHEN pagos.Pagado >= p.Total THEN N''pagada'' WHEN pagos.Pagado>0 THEN N''parcial'' ELSE N''abierta'' END
        FROM dbo.Purchases AS p
        OUTER APPLY (
            SELECT ISNULL(SUM(m.Amount), 0) AS Pagado
            FROM dbo.CashMoves AS m
            WHERE m.PurchaseId = p.PurchaseId AND m.MoveType = N''salida'' AND m.MoveState=N''confirmado''
        ) AS pagos
        WHERE p.Status=N''received'';';
 IF CHARINDEX(@After,@Definition)=0
 BEGIN
  IF CHARINDEX(@Before,@Definition)=0 THROW 50630,'La logica de AccountsPayable difiere del patron revisado.',1;
  SET @Definition=REPLACE(@Definition,@Before,@After);
 END;
 SET @Before=N'        DELETE FROM dbo.AccountsReceivable;';
 SET @After=N'        DECLARE @IntegrityReceivableDates TABLE(ReceivableId NVARCHAR(100) PRIMARY KEY,DueDate DATE NULL);
        INSERT @IntegrityReceivableDates SELECT ReceivableId,DueDate FROM dbo.AccountsReceivable;
        DELETE FROM dbo.AccountsReceivable;';
 IF CHARINDEX(@After,@Definition)=0
 BEGIN
  IF CHARINDEX(@Before,@Definition)=0 THROW 50630,'No se reconoce la preservacion de fechas de AccountsReceivable.',1;
  SET @Definition=REPLACE(@Definition,@Before,@After);
 END;
 SET @Before=N'        DELETE FROM dbo.AccountsPayable;';
 SET @After=N'        DECLARE @IntegrityPayableDates TABLE(PayableId NVARCHAR(100) PRIMARY KEY,DueDate DATE NULL);
        INSERT @IntegrityPayableDates SELECT PayableId,DueDate FROM dbo.AccountsPayable;
        DELETE FROM dbo.AccountsPayable;';
 IF CHARINDEX(@After,@Definition)=0
 BEGIN
  IF CHARINDEX(@Before,@Definition)=0 THROW 50630,'No se reconoce la preservacion de fechas de AccountsPayable.',1;
  SET @Definition=REPLACE(@Definition,@Before,@After);
 END;
 -- SQL Server puede almacenar CREATE   PROCEDURE al normalizar CREATE OR ALTER.
 -- Cambiar solo el encabezado conocido; nunca reemplazar texto del cuerpo.
 DECLARE @ProcedurePosition INT=CHARINDEX(N'PROCEDURE dbo.usp_SaveErpState',@Definition);
 IF @ProcedurePosition=0 THROW 50630,'No se reconoce el encabezado del procedimiento de sincronizacion.',1;
 DECLARE @Header NVARCHAR(MAX)=LTRIM(RTRIM(LEFT(@Definition,@ProcedurePosition-1)));
 SET @Header=REPLACE(REPLACE(REPLACE(@Header,CHAR(13),N' '),CHAR(10),N' '),CHAR(9),N' ');
 SET @Header=LTRIM(RTRIM(@Header));
 WHILE CHARINDEX(N'  ',@Header)>0 SET @Header=REPLACE(@Header,N'  ',N' ');
 IF @Header NOT IN(N'CREATE',N'CREATE OR ALTER',N'ALTER')
  THROW 50630,'El encabezado de sincronizacion difiere del formato revisado.',1;
 SET @Definition=N'ALTER '+SUBSTRING(@Definition,@ProcedurePosition,LEN(@Definition));
 EXEC sys.sp_executesql @Definition;
 EXEC(N'CREATE OR ALTER PROCEDURE dbo.usp_SnapshotLinkIntegrityVersion AS SELECT 32 AS version;');
 IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
 BEGIN
  GRANT EXECUTE ON dbo.usp_SaveErpState TO [raquel_erp_app];
  GRANT EXECUTE ON dbo.usp_SnapshotLinkIntegrityVersion TO [raquel_erp_app];
 END;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO

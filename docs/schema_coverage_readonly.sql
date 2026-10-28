USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET NOCOUNT ON;
DECLARE @Expected TABLE(Name SYSNAME); INSERT @Expected VALUES (N'AccountingEntries'),(N'AccountsPayable'),(N'AccountsReceivable'),(N'AppPasswordResetCodes'),(N'AppUserAreas'),(N'AppUserSessions'),(N'AppUsers'),(N'AuditEvents'),(N'CashAccounts'),(N'CashMoves'),(N'CashSessions'),(N'CatalogAlbumProducts'),(N'CatalogAlbums'),(N'ChartOfAccounts'),(N'EmployeeJobHistory'),(N'Employees'),(N'ErpState'),(N'FinanceCategories'),(N'FinanceMoves'),(N'ForecastMonths'),(N'HrAttendanceRecords'),(N'HrComplianceObligations'),(N'HrContracts'),(N'HrCorrectiveActions'),(N'HrEmployeeCreations'),(N'HrEquipmentDeliveries'),(N'HrRequestEvents'),(N'HrRequests'),(N'HrRightsArticles'),(N'HrSafetyEquipment'),(N'HrSafetyIncidents'),(N'HrSafetyTrainings'),(N'HrTrainingAttendees'),(N'IntegrityProcedureBackups'),(N'InventoryLots'),(N'KardexMoves'),(N'Parties'),(N'PayrollHistoryEvents'),(N'PayrollInstitutionalObligations'),(N'PayrollNovelties'),(N'PayrollNoveltyEvents'),(N'PayrollPaymentAllocations'),(N'PayrollPayments'),(N'PayrollProjectDistributions'),(N'PayrollReceiptTickets'),(N'PayrollRulesCatalog'),(N'PayrollRunItems'),(N'PayrollRuns'),(N'PayrollValidations'),(N'ProductCategories'),(N'ProductionOrders'),(N'ProductionStages'),(N'Products'),(N'ProformaItems'),(N'Proformas'),(N'ProjectEvents'),(N'ProjectStages'),(N'ProjectStates'),(N'Projections'),(N'Projects'),(N'Promotions'),(N'PurchaseItems'),(N'Purchases'),(N'SaleItems'),(N'Sales'),(N'SupplierDirectory'),(N'SupplierDirectoryEvents'),(N'SupplierDirectoryFiles'),(N'Warehouses');
SELECT DB_NAME() AS DatabaseName,69 AS ExpectedTables,(SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo')) AS ActualTables,
(SELECT COUNT(*) FROM @Expected e WHERE OBJECT_ID(N'dbo.'+e.Name,N'U') IS NULL) AS MissingExpectedTables,
(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo')) AS Procedures,
(SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=0) AS ActiveForeignKeys,
(SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=1) AS DisabledForeignKeys;
SELECT Name AS MissingTable FROM @Expected e WHERE OBJECT_ID(N'dbo.'+e.Name,N'U') IS NULL;
SELECT OBJECT_ID(N'dbo.usp_PayrollPaymentIntegrityVersion',N'P') AS Migration30,OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') AS Migration31,OBJECT_ID(N'dbo.usp_SnapshotLinkIntegrityVersion',N'P') AS Migration32;
SELECT (SELECT COUNT(*) FROM dbo.Employees) AS Employees,(SELECT COUNT(*) FROM dbo.PayrollRuns) AS PayrollRuns,(SELECT COUNT(*) FROM dbo.PayrollPayments) AS PayrollPayments,(SELECT COUNT(*) FROM dbo.CashMoves) AS CashMoves;
GO

USE [Instalaciones Raquel];
GO
SET NOCOUNT ON;
DECLARE @Expected TABLE(Name SYSNAME); INSERT @Expected VALUES (N'AccountingEntries'),(N'AccountsPayable'),(N'AccountsReceivable'),(N'AppPasswordResetCodes'),(N'AppUserAreas'),(N'AppUserSessions'),(N'AppUsers'),(N'AuditEvents'),(N'CashAccounts'),(N'CashMoves'),(N'CashSessions'),(N'CatalogAlbumProducts'),(N'CatalogAlbums'),(N'ChartOfAccounts'),(N'EmployeeJobHistory'),(N'Employees'),(N'ErpState'),(N'FinanceCategories'),(N'FinanceMoves'),(N'ForecastMonths'),(N'HrAttendanceRecords'),(N'HrComplianceObligations'),(N'HrContracts'),(N'HrCorrectiveActions'),(N'HrEmployeeCreations'),(N'HrEquipmentDeliveries'),(N'HrRequestEvents'),(N'HrRequests'),(N'HrRightsArticles'),(N'HrSafetyEquipment'),(N'HrSafetyIncidents'),(N'HrSafetyTrainings'),(N'HrTrainingAttendees'),(N'IntegrityProcedureBackups'),(N'InventoryLots'),(N'KardexMoves'),(N'Parties'),(N'PayrollHistoryEvents'),(N'PayrollInstitutionalObligations'),(N'PayrollNovelties'),(N'PayrollNoveltyEvents'),(N'PayrollPaymentAllocations'),(N'PayrollPayments'),(N'PayrollProjectDistributions'),(N'PayrollReceiptTickets'),(N'PayrollRulesCatalog'),(N'PayrollRunItems'),(N'PayrollRuns'),(N'PayrollValidations'),(N'ProductCategories'),(N'ProductionOrders'),(N'ProductionStages'),(N'Products'),(N'ProformaItems'),(N'Proformas'),(N'ProjectEvents'),(N'ProjectStages'),(N'ProjectStates'),(N'Projections'),(N'Projects'),(N'Promotions'),(N'PurchaseItems'),(N'Purchases'),(N'SaleItems'),(N'Sales'),(N'SupplierDirectory'),(N'SupplierDirectoryEvents'),(N'SupplierDirectoryFiles'),(N'Warehouses');
SELECT DB_NAME() AS DatabaseName,69 AS ExpectedTables,(SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo')) AS ActualTables,
(SELECT COUNT(*) FROM @Expected e WHERE OBJECT_ID(N'dbo.'+e.Name,N'U') IS NULL) AS MissingExpectedTables,
(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo')) AS Procedures,
(SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=0) AS ActiveForeignKeys,
(SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=1) AS DisabledForeignKeys;
SELECT Name AS MissingTable FROM @Expected e WHERE OBJECT_ID(N'dbo.'+e.Name,N'U') IS NULL;
SELECT OBJECT_ID(N'dbo.usp_PayrollPaymentIntegrityVersion',N'P') AS Migration30,OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') AS Migration31,OBJECT_ID(N'dbo.usp_SnapshotLinkIntegrityVersion',N'P') AS Migration32;
SELECT (SELECT COUNT(*) FROM dbo.Employees) AS Employees,(SELECT COUNT(*) FROM dbo.PayrollRuns) AS PayrollRuns,(SELECT COUNT(*) FROM dbo.PayrollPayments) AS PayrollPayments,(SELECT COUNT(*) FROM dbo.CashMoves) AS CashMoves;
GO

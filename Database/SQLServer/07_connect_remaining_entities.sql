USE [Instalaciones Raquel];
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.CashAccounts', N'U') IS NULL
CREATE TABLE dbo.CashAccounts
(
    AccountCode NVARCHAR(20) NOT NULL CONSTRAINT PK_CashAccounts PRIMARY KEY,
    AccountName NVARCHAR(80) NOT NULL
);
IF OBJECT_ID(N'dbo.ForecastMonths', N'U') IS NULL
CREATE TABLE dbo.ForecastMonths
(
    MonthNumber TINYINT NOT NULL CONSTRAINT PK_ForecastMonths PRIMARY KEY,
    MonthLabel NVARCHAR(20) NOT NULL CONSTRAINT UQ_ForecastMonths_Label UNIQUE
);
IF OBJECT_ID(N'dbo.ProductionStages', N'U') IS NULL
CREATE TABLE dbo.ProductionStages
(
    StageCode NVARCHAR(30) NOT NULL CONSTRAINT PK_ProductionStages PRIMARY KEY,
    StageName NVARCHAR(80) NOT NULL
);
IF OBJECT_ID(N'dbo.Warehouses', N'U') IS NULL
CREATE TABLE dbo.Warehouses
(
    WarehouseId NVARCHAR(160) NOT NULL CONSTRAINT PK_Warehouses PRIMARY KEY
);
IF OBJECT_ID(N'dbo.ChartOfAccounts', N'U') IS NULL
CREATE TABLE dbo.ChartOfAccounts
(
    AccountName NVARCHAR(200) NOT NULL CONSTRAINT PK_ChartOfAccounts PRIMARY KEY
);
IF OBJECT_ID(N'dbo.FinanceCategories', N'U') IS NULL
CREATE TABLE dbo.FinanceCategories
(
    CategoryName NVARCHAR(160) NOT NULL CONSTRAINT PK_FinanceCategories PRIMARY KEY
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.CashAccounts WHERE AccountCode = N'caja')
    INSERT INTO dbo.CashAccounts (AccountCode, AccountName) VALUES (N'caja', N'Caja');
IF NOT EXISTS (SELECT 1 FROM dbo.CashAccounts WHERE AccountCode = N'banco')
    INSERT INTO dbo.CashAccounts (AccountCode, AccountName) VALUES (N'banco', N'Banco');

MERGE dbo.ForecastMonths AS target
USING (VALUES
    (1, N'Ene'), (2, N'Feb'), (3, N'Mar'), (4, N'Abr'),
    (5, N'May'), (6, N'Jun'), (7, N'Jul'), (8, N'Ago'),
    (9, N'Sep'), (10, N'Oct'), (11, N'Nov'), (12, N'Dic')
) AS source(MonthNumber, MonthLabel)
ON target.MonthNumber = source.MonthNumber
WHEN MATCHED AND target.MonthLabel <> source.MonthLabel THEN UPDATE SET MonthLabel = source.MonthLabel
WHEN NOT MATCHED THEN INSERT (MonthNumber, MonthLabel) VALUES (source.MonthNumber, source.MonthLabel);

MERGE dbo.ProductionStages AS target
USING (VALUES
    (N'backlog', N'Pendiente'), (N'corte', N'Corte'), (N'ensamble', N'Ensamble'),
    (N'instalacion', N'Instalación'), (N'entregado', N'Entregado')
) AS source(StageCode, StageName)
ON target.StageCode = source.StageCode
WHEN MATCHED AND target.StageName <> source.StageName THEN UPDATE SET StageName = source.StageName
WHEN NOT MATCHED THEN INSERT (StageCode, StageName) VALUES (source.StageCode, source.StageName);
GO

IF COL_LENGTH(N'dbo.Sales', N'CreatedByUserId') IS NULL ALTER TABLE dbo.Sales ADD CreatedByUserId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Sales', N'PromotionId') IS NULL ALTER TABLE dbo.Sales ADD PromotionId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Proformas', N'ClientPartyId') IS NULL ALTER TABLE dbo.Proformas ADD ClientPartyId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Proformas', N'CreatedByUserId') IS NULL ALTER TABLE dbo.Proformas ADD CreatedByUserId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Proformas', N'PromotionId') IS NULL ALTER TABLE dbo.Proformas ADD PromotionId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Purchases', N'CreatedByUserId') IS NULL ALTER TABLE dbo.Purchases ADD CreatedByUserId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.KardexMoves', N'AppUserId') IS NULL ALTER TABLE dbo.KardexMoves ADD AppUserId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Employees', N'AppUserId') IS NULL ALTER TABLE dbo.Employees ADD AppUserId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.PayrollRuns', N'ActorUserId') IS NULL ALTER TABLE dbo.PayrollRuns ADD ActorUserId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Projects', N'OwnerEmployeeId') IS NULL ALTER TABLE dbo.Projects ADD OwnerEmployeeId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.ProductionOrders', N'ClientPartyId') IS NULL ALTER TABLE dbo.ProductionOrders ADD ClientPartyId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.ProductionOrders', N'OwnerEmployeeId') IS NULL ALTER TABLE dbo.ProductionOrders ADD OwnerEmployeeId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.ProductionOrders', N'ProductionStageCode') IS NULL ALTER TABLE dbo.ProductionOrders ADD ProductionStageCode NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.FinanceMoves', N'FinanceCategoryName') IS NULL ALTER TABLE dbo.FinanceMoves ADD FinanceCategoryName NVARCHAR(160) NULL;
IF COL_LENGTH(N'dbo.FinanceMoves', N'AppUserId') IS NULL ALTER TABLE dbo.FinanceMoves ADD AppUserId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.FinanceMoves', N'SaleId') IS NULL ALTER TABLE dbo.FinanceMoves ADD SaleId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.FinanceMoves', N'PurchaseId') IS NULL ALTER TABLE dbo.FinanceMoves ADD PurchaseId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.FinanceMoves', N'PayrollRunId') IS NULL ALTER TABLE dbo.FinanceMoves ADD PayrollRunId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.CashMoves', N'CashAccountCode') IS NULL ALTER TABLE dbo.CashMoves ADD CashAccountCode NVARCHAR(20) NULL;
IF COL_LENGTH(N'dbo.CashMoves', N'SaleId') IS NULL ALTER TABLE dbo.CashMoves ADD SaleId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.CashMoves', N'PurchaseId') IS NULL ALTER TABLE dbo.CashMoves ADD PurchaseId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.CashMoves', N'PayrollRunId') IS NULL ALTER TABLE dbo.CashMoves ADD PayrollRunId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.AccountingEntries', N'DebitAccountRef') IS NULL ALTER TABLE dbo.AccountingEntries ADD DebitAccountRef NVARCHAR(200) NULL;
IF COL_LENGTH(N'dbo.AccountingEntries', N'CreditAccountRef') IS NULL ALTER TABLE dbo.AccountingEntries ADD CreditAccountRef NVARCHAR(200) NULL;
IF COL_LENGTH(N'dbo.AccountingEntries', N'SaleId') IS NULL ALTER TABLE dbo.AccountingEntries ADD SaleId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.AccountingEntries', N'PurchaseId') IS NULL ALTER TABLE dbo.AccountingEntries ADD PurchaseId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.AccountingEntries', N'PayrollRunId') IS NULL ALTER TABLE dbo.AccountingEntries ADD PayrollRunId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.AccountingEntries', N'CashMoveId') IS NULL ALTER TABLE dbo.AccountingEntries ADD CashMoveId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Projections', N'MonthNumber') IS NULL ALTER TABLE dbo.Projections ADD MonthNumber TINYINT NULL;
IF COL_LENGTH(N'dbo.AuditEvents', N'AppUserId') IS NULL ALTER TABLE dbo.AuditEvents ADD AppUserId NVARCHAR(100) NULL;
GO

IF OBJECT_ID(N'dbo.PayrollRunItems', N'U') IS NULL
CREATE TABLE dbo.PayrollRunItems
(
    PayrollRunId NVARCHAR(100) NOT NULL,
    EmployeeId NVARCHAR(100) NOT NULL,
    Gross DECIMAL(19,4) NOT NULL,
    InssLaboral DECIMAL(19,4) NOT NULL,
    IncomeTax DECIMAL(19,4) NOT NULL,
    Net DECIMAL(19,4) NOT NULL,
    InssPatronal DECIMAL(19,4) NOT NULL,
    Inatec DECIMAL(19,4) NOT NULL,
    Aguinaldo DECIMAL(19,4) NOT NULL,
    EmployerCost DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_PayrollRunItems PRIMARY KEY (PayrollRunId, EmployeeId)
);
GO

INSERT INTO dbo.Warehouses (WarehouseId)
SELECT DISTINCT WarehouseId FROM dbo.InventoryLots AS lot
WHERE NOT EXISTS (SELECT 1 FROM dbo.Warehouses AS warehouse WHERE warehouse.WarehouseId = lot.WarehouseId);
INSERT INTO dbo.ChartOfAccounts (AccountName)
SELECT account.AccountName
FROM
(
    SELECT DebitAccount AS AccountName FROM dbo.AccountingEntries
    UNION
    SELECT CreditAccount FROM dbo.AccountingEntries
) AS account
WHERE NOT EXISTS (SELECT 1 FROM dbo.ChartOfAccounts AS chart WHERE chart.AccountName = account.AccountName);
INSERT INTO dbo.FinanceCategories (CategoryName)
SELECT DISTINCT Category FROM dbo.FinanceMoves AS move
WHERE NOT EXISTS (SELECT 1 FROM dbo.FinanceCategories AS category WHERE category.CategoryName = move.Category);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Employees') AND name = N'UX_Employees_AppUserId')
    CREATE UNIQUE INDEX UX_Employees_AppUserId ON dbo.Employees(AppUserId) WHERE AppUserId IS NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_InventoryLots_Warehouses') ALTER TABLE dbo.InventoryLots WITH CHECK ADD CONSTRAINT FK_InventoryLots_Warehouses FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses(WarehouseId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Sales_CreatedByUsers') ALTER TABLE dbo.Sales WITH CHECK ADD CONSTRAINT FK_Sales_CreatedByUsers FOREIGN KEY (CreatedByUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Sales_Promotions') ALTER TABLE dbo.Sales WITH CHECK ADD CONSTRAINT FK_Sales_Promotions FOREIGN KEY (PromotionId) REFERENCES dbo.Promotions(PromotionId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Proformas_ClientParties') ALTER TABLE dbo.Proformas WITH CHECK ADD CONSTRAINT FK_Proformas_ClientParties FOREIGN KEY (ClientPartyId) REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Proformas_CreatedByUsers') ALTER TABLE dbo.Proformas WITH CHECK ADD CONSTRAINT FK_Proformas_CreatedByUsers FOREIGN KEY (CreatedByUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Proformas_Promotions') ALTER TABLE dbo.Proformas WITH CHECK ADD CONSTRAINT FK_Proformas_Promotions FOREIGN KEY (PromotionId) REFERENCES dbo.Promotions(PromotionId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Purchases_CreatedByUsers') ALTER TABLE dbo.Purchases WITH CHECK ADD CONSTRAINT FK_Purchases_CreatedByUsers FOREIGN KEY (CreatedByUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_KardexMoves_AppUsers') ALTER TABLE dbo.KardexMoves WITH CHECK ADD CONSTRAINT FK_KardexMoves_AppUsers FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Employees_AppUsers') ALTER TABLE dbo.Employees WITH CHECK ADD CONSTRAINT FK_Employees_AppUsers FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_PayrollRuns_ActorUsers') ALTER TABLE dbo.PayrollRuns WITH CHECK ADD CONSTRAINT FK_PayrollRuns_ActorUsers FOREIGN KEY (ActorUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_PayrollRunItems_PayrollRuns') ALTER TABLE dbo.PayrollRunItems WITH CHECK ADD CONSTRAINT FK_PayrollRunItems_PayrollRuns FOREIGN KEY (PayrollRunId) REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_PayrollRunItems_Employees') ALTER TABLE dbo.PayrollRunItems WITH CHECK ADD CONSTRAINT FK_PayrollRunItems_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Projects_OwnerEmployees') ALTER TABLE dbo.Projects WITH CHECK ADD CONSTRAINT FK_Projects_OwnerEmployees FOREIGN KEY (OwnerEmployeeId) REFERENCES dbo.Employees(EmployeeId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_ProductionOrders_ClientParties') ALTER TABLE dbo.ProductionOrders WITH CHECK ADD CONSTRAINT FK_ProductionOrders_ClientParties FOREIGN KEY (ClientPartyId) REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_ProductionOrders_OwnerEmployees') ALTER TABLE dbo.ProductionOrders WITH CHECK ADD CONSTRAINT FK_ProductionOrders_OwnerEmployees FOREIGN KEY (OwnerEmployeeId) REFERENCES dbo.Employees(EmployeeId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_ProductionOrders_Stages') ALTER TABLE dbo.ProductionOrders WITH CHECK ADD CONSTRAINT FK_ProductionOrders_Stages FOREIGN KEY (ProductionStageCode) REFERENCES dbo.ProductionStages(StageCode);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_FinanceMoves_Categories') ALTER TABLE dbo.FinanceMoves WITH CHECK ADD CONSTRAINT FK_FinanceMoves_Categories FOREIGN KEY (FinanceCategoryName) REFERENCES dbo.FinanceCategories(CategoryName);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_FinanceMoves_AppUsers') ALTER TABLE dbo.FinanceMoves WITH CHECK ADD CONSTRAINT FK_FinanceMoves_AppUsers FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_FinanceMoves_Sales') ALTER TABLE dbo.FinanceMoves WITH CHECK ADD CONSTRAINT FK_FinanceMoves_Sales FOREIGN KEY (SaleId) REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_FinanceMoves_Purchases') ALTER TABLE dbo.FinanceMoves WITH CHECK ADD CONSTRAINT FK_FinanceMoves_Purchases FOREIGN KEY (PurchaseId) REFERENCES dbo.Purchases(PurchaseId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_FinanceMoves_PayrollRuns') ALTER TABLE dbo.FinanceMoves WITH CHECK ADD CONSTRAINT FK_FinanceMoves_PayrollRuns FOREIGN KEY (PayrollRunId) REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_CashMoves_CashAccounts') ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT FK_CashMoves_CashAccounts FOREIGN KEY (CashAccountCode) REFERENCES dbo.CashAccounts(AccountCode);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_CashMoves_Sales') ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT FK_CashMoves_Sales FOREIGN KEY (SaleId) REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_CashMoves_Purchases') ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT FK_CashMoves_Purchases FOREIGN KEY (PurchaseId) REFERENCES dbo.Purchases(PurchaseId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_CashMoves_PayrollRuns') ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT FK_CashMoves_PayrollRuns FOREIGN KEY (PayrollRunId) REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_AccountingEntries_DebitAccounts') ALTER TABLE dbo.AccountingEntries WITH CHECK ADD CONSTRAINT FK_AccountingEntries_DebitAccounts FOREIGN KEY (DebitAccountRef) REFERENCES dbo.ChartOfAccounts(AccountName);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_AccountingEntries_CreditAccounts') ALTER TABLE dbo.AccountingEntries WITH CHECK ADD CONSTRAINT FK_AccountingEntries_CreditAccounts FOREIGN KEY (CreditAccountRef) REFERENCES dbo.ChartOfAccounts(AccountName);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_AccountingEntries_Sales') ALTER TABLE dbo.AccountingEntries WITH CHECK ADD CONSTRAINT FK_AccountingEntries_Sales FOREIGN KEY (SaleId) REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_AccountingEntries_Purchases') ALTER TABLE dbo.AccountingEntries WITH CHECK ADD CONSTRAINT FK_AccountingEntries_Purchases FOREIGN KEY (PurchaseId) REFERENCES dbo.Purchases(PurchaseId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_AccountingEntries_PayrollRuns') ALTER TABLE dbo.AccountingEntries WITH CHECK ADD CONSTRAINT FK_AccountingEntries_PayrollRuns FOREIGN KEY (PayrollRunId) REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_AccountingEntries_CashMoves') ALTER TABLE dbo.AccountingEntries WITH CHECK ADD CONSTRAINT FK_AccountingEntries_CashMoves FOREIGN KEY (CashMoveId) REFERENCES dbo.CashMoves(CashMoveId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_Projections_ForecastMonths') ALTER TABLE dbo.Projections WITH CHECK ADD CONSTRAINT FK_Projections_ForecastMonths FOREIGN KEY (MonthNumber) REFERENCES dbo.ForecastMonths(MonthNumber);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_AuditEvents_AppUsers') ALTER TABLE dbo.AuditEvents WITH CHECK ADD CONSTRAINT FK_AuditEvents_AppUsers FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL;
GO

CREATE OR ALTER VIEW dbo.vw_EntidadesAisladas AS
SELECT N'ErpState' AS EntidadTecnica, N'Snapshot JSON para compatibilidad del API; excluir del diagrama funcional.' AS Motivo;
GO

CREATE OR ALTER VIEW dbo.vw_AsientosContables AS
SELECT entry.AccountingEntryId AS IdAsiento, entry.EntryNumber AS NumeroAsiento,
       entry.Description AS Descripcion, entry.Debit AS Debito, entry.Credit AS Credito,
       debit.AccountName AS CuentaDebito, credit.AccountName AS CuentaCredito,
       entry.EntryDate AS Fecha, sale.SaleNumber AS VentaRelacionada,
       purchase.PurchaseNumber AS CompraRelacionada, payroll.Period AS PlanillaRelacionada,
       cashMove.Concept AS MovimientoCajaRelacionado
FROM dbo.AccountingEntries AS entry
LEFT JOIN dbo.ChartOfAccounts AS debit ON debit.AccountName = entry.DebitAccountRef
LEFT JOIN dbo.ChartOfAccounts AS credit ON credit.AccountName = entry.CreditAccountRef
LEFT JOIN dbo.Sales AS sale ON sale.SaleId = entry.SaleId
LEFT JOIN dbo.Purchases AS purchase ON purchase.PurchaseId = entry.PurchaseId
LEFT JOIN dbo.PayrollRuns AS payroll ON payroll.PayrollRunId = entry.PayrollRunId
LEFT JOIN dbo.CashMoves AS cashMove ON cashMove.CashMoveId = entry.CashMoveId;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosFinancieros AS
SELECT movement.FinanceMoveId AS IdMovimiento, movement.MoveType AS Tipo,
       category.CategoryName AS Categoria, movement.Amount AS Monto, movement.MoveDate AS Fecha,
       movement.Note AS Nota, appUser.Name AS Usuario,
       sale.SaleNumber AS VentaRelacionada, purchase.PurchaseNumber AS CompraRelacionada,
       payroll.Period AS PlanillaRelacionada
FROM dbo.FinanceMoves AS movement
LEFT JOIN dbo.FinanceCategories AS category ON category.CategoryName = movement.FinanceCategoryName
LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = movement.AppUserId
LEFT JOIN dbo.Sales AS sale ON sale.SaleId = movement.SaleId
LEFT JOIN dbo.Purchases AS purchase ON purchase.PurchaseId = movement.PurchaseId
LEFT JOIN dbo.PayrollRuns AS payroll ON payroll.PayrollRunId = movement.PayrollRunId;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosCaja AS
SELECT movement.CashMoveId AS IdMovimiento, account.AccountName AS Cuenta,
       movement.MoveType AS Tipo, movement.Amount AS Monto, movement.MoveDate AS Fecha,
       movement.Concept AS Concepto, sale.SaleNumber AS VentaRelacionada,
       purchase.PurchaseNumber AS CompraRelacionada, payroll.Period AS PlanillaRelacionada
FROM dbo.CashMoves AS movement
LEFT JOIN dbo.CashAccounts AS account ON account.AccountCode = movement.CashAccountCode
LEFT JOIN dbo.Sales AS sale ON sale.SaleId = movement.SaleId
LEFT JOIN dbo.Purchases AS purchase ON purchase.PurchaseId = movement.PurchaseId
LEFT JOIN dbo.PayrollRuns AS payroll ON payroll.PayrollRunId = movement.PayrollRunId;
GO

CREATE OR ALTER VIEW dbo.vw_Proyecciones AS
SELECT projection.ProjectionId AS IdProyeccion, monthLookup.MonthLabel AS Mes,
       projection.ExpectedSales AS VentasEsperadas, projection.ExpectedCosts AS CostosEsperados
FROM dbo.Projections AS projection
LEFT JOIN dbo.ForecastMonths AS monthLookup ON monthLookup.MonthNumber = projection.MonthNumber;
GO

CREATE OR ALTER VIEW dbo.vw_OrdenesProduccion AS
SELECT production.ProductionOrderId AS IdOrden, production.Code AS Codigo,
       production.Product AS Producto, party.Name AS Cliente,
       employee.Name AS Responsable, stage.StageName AS Etapa,
       production.Sprint AS Sprint, production.Quantity AS Cantidad
FROM dbo.ProductionOrders AS production
LEFT JOIN dbo.Parties AS party ON party.PartyId = production.ClientPartyId
LEFT JOIN dbo.Employees AS employee ON employee.EmployeeId = production.OwnerEmployeeId
LEFT JOIN dbo.ProductionStages AS stage ON stage.StageCode = production.ProductionStageCode;
GO

CREATE OR ALTER VIEW dbo.vw_Planillas AS
SELECT payroll.PayrollRunId AS IdPlanilla, payroll.Period AS Periodo,
       payroll.PaidAt AS FechaPago, appUser.Name AS Responsable,
       payroll.Gross AS SalarioBruto, payroll.InssLaboral AS INSSLaboral,
       payroll.InssPatronal AS INSSPatronal, payroll.Inatec AS INATEC,
       payroll.IncomeTax AS ImpuestoRenta, payroll.Net AS SalarioNeto,
       payroll.EmployerCost AS CostoPatronal
FROM dbo.PayrollRuns AS payroll
LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = payroll.ActorUserId;
GO

CREATE OR ALTER VIEW dbo.vw_DetallePlanilla AS
SELECT item.PayrollRunId AS IdPlanilla, payroll.Period AS Periodo,
       employee.EmployeeId AS IdEmpleado, employee.Name AS Empleado,
       item.Gross AS SalarioBruto, item.InssLaboral AS INSSLaboral,
       item.IncomeTax AS ImpuestoRenta, item.Net AS SalarioNeto,
       item.InssPatronal AS INSSPatronal, item.Inatec AS INATEC,
       item.Aguinaldo AS Aguinaldo, item.EmployerCost AS CostoPatronal
FROM dbo.PayrollRunItems AS item
JOIN dbo.PayrollRuns AS payroll ON payroll.PayrollRunId = item.PayrollRunId
JOIN dbo.Employees AS employee ON employee.EmployeeId = item.EmployeeId;
GO

CREATE OR ALTER VIEW dbo.vw_CuentasContables AS
SELECT AccountName AS NombreCuenta FROM dbo.ChartOfAccounts;
GO

CREATE OR ALTER VIEW dbo.vw_CategoriasFinancieras AS
SELECT CategoryName AS Categoria FROM dbo.FinanceCategories;
GO

CREATE OR ALTER VIEW dbo.vw_CuentasCaja AS
SELECT AccountCode AS CodigoCuenta, AccountName AS NombreCuenta FROM dbo.CashAccounts;
GO

CREATE OR ALTER VIEW dbo.vw_MesesProyeccion AS
SELECT MonthNumber AS NumeroMes, MonthLabel AS Mes FROM dbo.ForecastMonths;
GO

CREATE OR ALTER VIEW dbo.vw_EtapasProduccion AS
SELECT StageCode AS CodigoEtapa, StageName AS Etapa FROM dbo.ProductionStages;
GO

CREATE OR ALTER VIEW dbo.vw_Bodegas AS
SELECT WarehouseId AS Bodega FROM dbo.Warehouses;
GO

CREATE OR ALTER VIEW dbo.vw_Empleados AS
SELECT employee.EmployeeId AS IdEmpleado, employee.Name AS Nombre,
       employee.Position AS Cargo, employee.Salary AS Salario,
       employee.Area AS Area, appUser.Email AS CorreoUsuario
FROM dbo.Employees AS employee
LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = employee.AppUserId;
GO

CREATE OR ALTER VIEW dbo.vw_EventosAuditoria AS
SELECT event.AuditEventId AS IdEvento, event.OccurredAt AS Fecha,
       appUser.Name AS Usuario, event.[Action] AS Accion,
       event.[Module] AS Modulo, event.Detail AS Detalle,
       event.Severity AS Severidad, event.[Reference] AS Referencia,
       event.Uml AS Modelo, event.Hash AS Huella, event.PreviousHash AS HuellaAnterior
FROM dbo.AuditEvents AS event
LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = event.AppUserId;
GO

CREATE OR ALTER VIEW dbo.vw_Ventas AS
SELECT sale.SaleId AS IdVenta, sale.SaleNumber AS NumeroVenta,
       COALESCE(party.Name, sale.ClientName) AS Cliente,
       promotion.Title AS Promocion, appUser.Name AS CreadoPor,
       sale.Subtotal AS Subtotal, sale.DiscountAmount AS Descuento,
       sale.TaxAmount AS Impuesto, sale.Total AS Total, sale.Status AS Estado,
       sale.SaleDate AS FechaVenta, sale.QrPayload AS CodigoQR
FROM dbo.Sales AS sale
LEFT JOIN dbo.Parties AS party ON party.PartyId = sale.ClientPartyId
LEFT JOIN dbo.Promotions AS promotion ON promotion.PromotionId = sale.PromotionId
LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = sale.CreatedByUserId;
GO

CREATE OR ALTER VIEW dbo.vw_Proformas AS
SELECT proforma.ProformaId AS IdProforma, proforma.ProformaNumber AS NumeroProforma,
       COALESCE(party.Name, proforma.ClientName) AS Cliente,
       promotion.Title AS Promocion, appUser.Name AS CreadoPor,
       proforma.Subtotal AS Subtotal, proforma.DiscountAmount AS Descuento,
       proforma.TaxAmount AS Impuesto, proforma.Total AS Total,
       proforma.Status AS Estado, proforma.ValidUntil AS VigenteHasta,
       proforma.CreatedAt AS FechaCreacion, proforma.QrPayload AS CodigoQR
FROM dbo.Proformas AS proforma
LEFT JOIN dbo.Parties AS party ON party.PartyId = proforma.ClientPartyId
LEFT JOIN dbo.Promotions AS promotion ON promotion.PromotionId = proforma.PromotionId
LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = proforma.CreatedByUserId;
GO

CREATE OR ALTER VIEW dbo.vw_Compras AS
SELECT purchase.PurchaseId AS IdCompra, purchase.PurchaseNumber AS NumeroCompra,
       COALESCE(party.Name, purchase.SupplierName) AS Proveedor,
       appUser.Name AS CreadoPor, purchase.Total AS Total,
       purchase.Status AS Estado, purchase.PurchaseDate AS FechaCompra
FROM dbo.Purchases AS purchase
LEFT JOIN dbo.Parties AS party ON party.PartyId = purchase.SupplierPartyId
LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = purchase.CreatedByUserId;
GO

SELECT fk.name AS Relacion, OBJECT_NAME(fk.parent_object_id) AS TablaHija,
       OBJECT_NAME(fk.referenced_object_id) AS TablaPrincipal
FROM sys.foreign_keys AS fk
WHERE fk.is_disabled = 0
ORDER BY TablaPrincipal, TablaHija;
GO
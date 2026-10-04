USE [Instalaciones Raquel];
GO

IF OBJECT_ID(N'dbo.Products', N'U') IS NULL
CREATE TABLE dbo.Products
(
    ProductId NVARCHAR(100) NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
    Code NVARCHAR(80) NOT NULL,
    Name NVARCHAR(200) NOT NULL,
    Category NVARCHAR(120) NOT NULL,
    UnitPrice DECIMAL(19,4) NOT NULL,
    MinQuantity DECIMAL(19,4) NOT NULL,
    CreatedAt DATETIMEOFFSET(3) NOT NULL,
    ImageUrl NVARCHAR(1000) NULL,
    Model NVARCHAR(160) NULL,
    Brand NVARCHAR(160) NULL,
    Material NVARCHAR(160) NULL,
    Measures NVARCHAR(160) NULL,
    Capacity NVARCHAR(160) NULL,
    Finish NVARCHAR(160) NULL,
    ProductUse NVARCHAR(500) NULL,
    Warranty NVARCHAR(160) NULL
);
GO

IF OBJECT_ID(N'dbo.InventoryLots', N'U') IS NULL
CREATE TABLE dbo.InventoryLots
(
    LotId NVARCHAR(100) NOT NULL CONSTRAINT PK_InventoryLots PRIMARY KEY,
    ProductId NVARCHAR(100) NOT NULL,
    Quantity DECIMAL(19,4) NOT NULL,
    UnitCost DECIMAL(19,4) NOT NULL,
    EntryDate DATETIMEOFFSET(3) NOT NULL,
    WarehouseId NVARCHAR(160) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.KardexMoves', N'U') IS NULL
CREATE TABLE dbo.KardexMoves
(
    KardexMoveId NVARCHAR(100) NOT NULL CONSTRAINT PK_KardexMoves PRIMARY KEY,
    ProductId NVARCHAR(100) NOT NULL,
    MoveType NVARCHAR(20) NOT NULL,
    Quantity DECIMAL(19,4) NOT NULL,
    UnitCost DECIMAL(19,4) NOT NULL,
    MoveDate DATETIMEOFFSET(3) NOT NULL,
    Reason NVARCHAR(500) NOT NULL,
    UserName NVARCHAR(200) NOT NULL,
    CONSTRAINT CK_KardexMoves_MoveType CHECK (MoveType IN (N'entrada', N'salida'))
);
GO

IF OBJECT_ID(N'dbo.Sales', N'U') IS NULL
CREATE TABLE dbo.Sales
(
    SaleId NVARCHAR(100) NOT NULL CONSTRAINT PK_Sales PRIMARY KEY,
    SaleNumber NVARCHAR(80) NOT NULL,
    ClientName NVARCHAR(240) NOT NULL,
    Subtotal DECIMAL(19,4) NOT NULL,
    DiscountAmount DECIMAL(19,4) NOT NULL,
    PromoCode NVARCHAR(160) NULL,
    TaxAmount DECIMAL(19,4) NOT NULL,
    Total DECIMAL(19,4) NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    SaleDate DATETIMEOFFSET(3) NOT NULL,
    CreatedBy NVARCHAR(200) NOT NULL,
    QrPayload NVARCHAR(MAX) NOT NULL,
    CONSTRAINT CK_Sales_Status CHECK (Status IN (N'draft', N'completed'))
);
GO

IF OBJECT_ID(N'dbo.SaleItems', N'U') IS NULL
CREATE TABLE dbo.SaleItems
(
    SaleId NVARCHAR(100) NOT NULL,
    LineNumber INT NOT NULL,
    ProductId NVARCHAR(100) NOT NULL,
    Quantity DECIMAL(19,4) NOT NULL,
    UnitPrice DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_SaleItems PRIMARY KEY (SaleId, LineNumber),
    CONSTRAINT FK_SaleItems_Sales FOREIGN KEY (SaleId) REFERENCES dbo.Sales(SaleId) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.Proformas', N'U') IS NULL
CREATE TABLE dbo.Proformas
(
    ProformaId NVARCHAR(100) NOT NULL CONSTRAINT PK_Proformas PRIMARY KEY,
    ProformaNumber NVARCHAR(80) NOT NULL,
    ClientName NVARCHAR(240) NOT NULL,
    Subtotal DECIMAL(19,4) NOT NULL,
    DiscountAmount DECIMAL(19,4) NOT NULL,
    PromoCode NVARCHAR(160) NULL,
    TaxAmount DECIMAL(19,4) NOT NULL,
    Total DECIMAL(19,4) NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    ValidUntil DATETIMEOFFSET(3) NOT NULL,
    Notes NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIMEOFFSET(3) NOT NULL,
    CreatedBy NVARCHAR(200) NOT NULL,
    QrPayload NVARCHAR(MAX) NOT NULL,
    ConvertedSaleId NVARCHAR(100) NULL,
    CONSTRAINT CK_Proformas_Status CHECK (Status IN (N'borrador', N'enviada', N'aceptada', N'vencida', N'convertida'))
);
GO

IF OBJECT_ID(N'dbo.ProformaItems', N'U') IS NULL
CREATE TABLE dbo.ProformaItems
(
    ProformaId NVARCHAR(100) NOT NULL,
    LineNumber INT NOT NULL,
    ProductId NVARCHAR(100) NOT NULL,
    Quantity DECIMAL(19,4) NOT NULL,
    UnitPrice DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_ProformaItems PRIMARY KEY (ProformaId, LineNumber),
    CONSTRAINT FK_ProformaItems_Proformas FOREIGN KEY (ProformaId) REFERENCES dbo.Proformas(ProformaId) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.Promotions', N'U') IS NULL
CREATE TABLE dbo.Promotions
(
    PromotionId NVARCHAR(100) NOT NULL CONSTRAINT PK_Promotions PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    Blurb NVARCHAR(1000) NOT NULL,
    MinSubtotal DECIMAL(19,4) NOT NULL,
    PercentOff DECIMAL(9,4) NOT NULL,
    IsActive BIT NOT NULL,
    Badge NVARCHAR(120) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.Purchases', N'U') IS NULL
CREATE TABLE dbo.Purchases
(
    PurchaseId NVARCHAR(100) NOT NULL CONSTRAINT PK_Purchases PRIMARY KEY,
    PurchaseNumber NVARCHAR(80) NOT NULL,
    SupplierName NVARCHAR(240) NOT NULL,
    Total DECIMAL(19,4) NOT NULL,
    Status NVARCHAR(20) NOT NULL,
    PurchaseDate DATETIMEOFFSET(3) NOT NULL,
    CreatedBy NVARCHAR(200) NOT NULL,
    CONSTRAINT CK_Purchases_Status CHECK (Status IN (N'ordered', N'received'))
);
GO

IF OBJECT_ID(N'dbo.PurchaseItems', N'U') IS NULL
CREATE TABLE dbo.PurchaseItems
(
    PurchaseId NVARCHAR(100) NOT NULL,
    LineNumber INT NOT NULL,
    ProductId NVARCHAR(100) NOT NULL,
    Quantity DECIMAL(19,4) NOT NULL,
    UnitPrice DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_PurchaseItems PRIMARY KEY (PurchaseId, LineNumber),
    CONSTRAINT FK_PurchaseItems_Purchases FOREIGN KEY (PurchaseId) REFERENCES dbo.Purchases(PurchaseId) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.AccountingEntries', N'U') IS NULL
CREATE TABLE dbo.AccountingEntries
(
    AccountingEntryId NVARCHAR(100) NOT NULL CONSTRAINT PK_AccountingEntries PRIMARY KEY,
    EntryNumber NVARCHAR(80) NOT NULL,
    Description NVARCHAR(1000) NOT NULL,
    Debit DECIMAL(19,4) NOT NULL,
    Credit DECIMAL(19,4) NOT NULL,
    DebitAccount NVARCHAR(200) NOT NULL,
    CreditAccount NVARCHAR(200) NOT NULL,
    EntryDate DATETIMEOFFSET(3) NOT NULL,
    ReferenceType NVARCHAR(20) NOT NULL,
    ReferenceId NVARCHAR(100) NULL,
    CONSTRAINT CK_AccountingEntries_ReferenceType CHECK (ReferenceType IN (N'sale', N'purchase', N'manual', N'payroll', N'cash'))
);
GO

IF OBJECT_ID(N'dbo.FinanceMoves', N'U') IS NULL
CREATE TABLE dbo.FinanceMoves
(
    FinanceMoveId NVARCHAR(100) NOT NULL CONSTRAINT PK_FinanceMoves PRIMARY KEY,
    MoveType NVARCHAR(20) NOT NULL,
    Category NVARCHAR(160) NOT NULL,
    Amount DECIMAL(19,4) NOT NULL,
    MoveDate DATETIMEOFFSET(3) NOT NULL,
    Note NVARCHAR(1000) NOT NULL,
    UserName NVARCHAR(200) NOT NULL,
    CONSTRAINT CK_FinanceMoves_MoveType CHECK (MoveType IN (N'ingreso', N'egreso'))
);
GO

IF OBJECT_ID(N'dbo.Projections', N'U') IS NULL
CREATE TABLE dbo.Projections
(
    ProjectionId NVARCHAR(100) NOT NULL CONSTRAINT PK_Projections PRIMARY KEY,
    MonthLabel NVARCHAR(40) NOT NULL,
    ExpectedSales DECIMAL(19,4) NOT NULL,
    ExpectedCosts DECIMAL(19,4) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.ProductionOrders', N'U') IS NULL
CREATE TABLE dbo.ProductionOrders
(
    ProductionOrderId NVARCHAR(100) NOT NULL CONSTRAINT PK_ProductionOrders PRIMARY KEY,
    Code NVARCHAR(80) NOT NULL,
    Product NVARCHAR(240) NOT NULL,
    Client NVARCHAR(240) NOT NULL,
    Quantity DECIMAL(19,4) NOT NULL,
    Stage NVARCHAR(30) NOT NULL,
    Sprint NVARCHAR(100) NOT NULL,
    Owner NVARCHAR(200) NOT NULL,
    CONSTRAINT CK_ProductionOrders_Stage CHECK (Stage IN (N'backlog', N'corte', N'ensamble', N'instalacion', N'entregado'))
);
GO

IF OBJECT_ID(N'dbo.Parties', N'U') IS NULL
CREATE TABLE dbo.Parties
(
    PartyId NVARCHAR(100) NOT NULL CONSTRAINT PK_Parties PRIMARY KEY,
    Name NVARCHAR(240) NOT NULL,
    Contact NVARCHAR(200) NOT NULL,
    Phone NVARCHAR(80) NOT NULL,
    PartyType NVARCHAR(20) NOT NULL,
    CONSTRAINT CK_Parties_Type CHECK (PartyType IN (N'cliente', N'proveedor'))
);
GO

IF OBJECT_ID(N'dbo.Employees', N'U') IS NULL
CREATE TABLE dbo.Employees
(
    EmployeeId NVARCHAR(100) NOT NULL CONSTRAINT PK_Employees PRIMARY KEY,
    Name NVARCHAR(240) NOT NULL,
    Position NVARCHAR(200) NOT NULL,
    Salary DECIMAL(19,4) NOT NULL,
    Area NVARCHAR(120) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.PayrollRuns', N'U') IS NULL
CREATE TABLE dbo.PayrollRuns
(
    PayrollRunId NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollRuns PRIMARY KEY,
    Period NVARCHAR(40) NOT NULL,
    PaidAt DATETIMEOFFSET(3) NOT NULL,
    Actor NVARCHAR(200) NOT NULL,
    Gross DECIMAL(19,4) NOT NULL,
    InssLaboral DECIMAL(19,4) NOT NULL,
    InssPatronal DECIMAL(19,4) NOT NULL,
    Inatec DECIMAL(19,4) NOT NULL,
    IncomeTax DECIMAL(19,4) NOT NULL,
    Net DECIMAL(19,4) NOT NULL,
    EmployerCost DECIMAL(19,4) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.CatalogAlbums', N'U') IS NULL
CREATE TABLE dbo.CatalogAlbums
(
    AlbumId NVARCHAR(100) NOT NULL CONSTRAINT PK_CatalogAlbums PRIMARY KEY,
    MonthLabel NVARCHAR(40) NOT NULL,
    Title NVARCHAR(240) NOT NULL,
    Blurb NVARCHAR(2000) NOT NULL,
    IsPublished BIT NOT NULL,
    CreatedAt DATETIMEOFFSET(3) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.CatalogAlbumProducts', N'U') IS NULL
CREATE TABLE dbo.CatalogAlbumProducts
(
    AlbumId NVARCHAR(100) NOT NULL,
    LineNumber INT NOT NULL,
    ProductId NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_CatalogAlbumProducts PRIMARY KEY (AlbumId, LineNumber),
    CONSTRAINT FK_CatalogAlbumProducts_Albums FOREIGN KEY (AlbumId) REFERENCES dbo.CatalogAlbums(AlbumId) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.Projects', N'U') IS NULL
CREATE TABLE dbo.Projects
(
    ProjectId NVARCHAR(100) NOT NULL CONSTRAINT PK_Projects PRIMARY KEY,
    Code NVARCHAR(80) NOT NULL,
    Name NVARCHAR(240) NOT NULL,
    Client NVARCHAR(240) NOT NULL,
    Amount DECIMAL(19,4) NOT NULL,
    Progress DECIMAL(7,4) NOT NULL,
    ProjectState NVARCHAR(120) NOT NULL,
    Owner NVARCHAR(200) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.CashMoves', N'U') IS NULL
CREATE TABLE dbo.CashMoves
(
    CashMoveId NVARCHAR(100) NOT NULL CONSTRAINT PK_CashMoves PRIMARY KEY,
    Account NVARCHAR(20) NOT NULL,
    MoveType NVARCHAR(20) NOT NULL,
    Amount DECIMAL(19,4) NOT NULL,
    MoveDate DATETIMEOFFSET(3) NOT NULL,
    Concept NVARCHAR(1000) NOT NULL,
    CONSTRAINT CK_CashMoves_Account CHECK (Account IN (N'caja', N'banco')),
    CONSTRAINT CK_CashMoves_MoveType CHECK (MoveType IN (N'entrada', N'salida'))
);
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
CREATE TABLE dbo.AppUsers
(
    AppUserId NVARCHAR(100) NOT NULL CONSTRAINT PK_AppUsers PRIMARY KEY,
    Name NVARCHAR(240) NOT NULL,
    Email NVARCHAR(320) NOT NULL,
    Hierarchy NVARCHAR(30) NOT NULL,
    IsActive BIT NOT NULL,
    CONSTRAINT CK_AppUsers_Hierarchy CHECK (Hierarchy IN (N'superadmin', N'administrador', N'estandar', N'invitado'))
);
GO

IF OBJECT_ID(N'dbo.AppUserAreas', N'U') IS NULL
CREATE TABLE dbo.AppUserAreas
(
    AppUserId NVARCHAR(100) NOT NULL,
    Area NVARCHAR(30) NOT NULL,
    CONSTRAINT PK_AppUserAreas PRIMARY KEY (AppUserId, Area),
    CONSTRAINT FK_AppUserAreas_AppUsers FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE CASCADE,
    CONSTRAINT CK_AppUserAreas_Area CHECK (Area IN (N'produccion', N'inventario', N'finanzas', N'contabilidad', N'mercadotecnia', N'compras', N'ventas', N'rrhh', N'proyectos', N'gobierno'))
);
GO

IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
CREATE TABLE dbo.AuditEvents
(
    AuditEventId NVARCHAR(100) NOT NULL CONSTRAINT PK_AuditEvents PRIMARY KEY,
    OccurredAt DATETIMEOFFSET(3) NOT NULL,
    UserName NVARCHAR(200) NOT NULL,
    Action NVARCHAR(120) NOT NULL,
    Module NVARCHAR(120) NOT NULL,
    Detail NVARCHAR(MAX) NOT NULL,
    Severity NVARCHAR(20) NULL,
    Reference NVARCHAR(500) NULL,
    Uml NVARCHAR(MAX) NULL,
    Hash NVARCHAR(256) NULL,
    PreviousHash NVARCHAR(256) NULL,
    CONSTRAINT CK_AuditEvents_Severity CHECK (Severity IS NULL OR Severity IN (N'info', N'warn', N'critical'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.InventoryLots') AND name = N'IX_InventoryLots_ProductDate')
    CREATE INDEX IX_InventoryLots_ProductDate ON dbo.InventoryLots(ProductId, EntryDate);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.KardexMoves') AND name = N'IX_KardexMoves_ProductDate')
    CREATE INDEX IX_KardexMoves_ProductDate ON dbo.KardexMoves(ProductId, MoveDate DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Sales') AND name = N'IX_Sales_Date')
    CREATE INDEX IX_Sales_Date ON dbo.Sales(SaleDate DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Purchases') AND name = N'IX_Purchases_Date')
    CREATE INDEX IX_Purchases_Date ON dbo.Purchases(PurchaseDate DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.FinanceMoves') AND name = N'IX_FinanceMoves_Date')
    CREATE INDEX IX_FinanceMoves_Date ON dbo.FinanceMoves(MoveDate DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.AuditEvents') AND name = N'IX_AuditEvents_OccurredAt')
    CREATE INDEX IX_AuditEvents_OccurredAt ON dbo.AuditEvents(OccurredAt DESC);
GO

SELECT name AS table_name
FROM sys.tables
WHERE schema_id = SCHEMA_ID(N'dbo')
ORDER BY name;
GO
/* INSTALACIONES RAQUEL: ESTRUCTURA PARA INSTALACION NUEVA
Generado a partir de 25 archivos en orden explicito.
No ejecutar sobre una base existente: la comprobacion siguiente lo bloquea.
No incluye reconstruccion, cargas de ejemplo, importaciones operativas ni cambio de credenciales.
Los catalogos y reglas tecnicas definidos dentro de las migraciones se mantienen.
El paquete no certifica vigencia normativa ni sustituye pruebas funcionales.
En SSMS ejecutar completo; en sqlcmd utilizar -b. Configurar el usuario de aplicacion por separado. */
USE master;
GO
IF DB_ID(N'Raquel_Schema_Check_20261025_99ef80cc') IS NOT NULL
BEGIN
 RAISERROR('La base ya existe. Este paquete es solo para instalacion nueva; revisar migraciones individuales con respaldo.',16,1);
 SET NOEXEC ON;
END;
GO

/* ARCHIVO 1/25: 00_crear_base.sql */
/* 00 — Crear base de datos Raquel_Schema_Check_20261025_99ef80cc */
IF DB_ID(N'Raquel_Schema_Check_20261025_99ef80cc') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE [Raquel_Schema_Check_20261025_99ef80cc]');
END;
GO

SELECT name AS database_name, create_date, state_desc
FROM sys.databases
WHERE name = N'Raquel_Schema_Check_20261025_99ef80cc';
GO

GO

/* ARCHIVO 2/25: 01_catalogos.sql */
/* 01 — Catálogos de dominio (tablas padre de casi todo el ERP) */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.CashAccounts', N'U') IS NULL
CREATE TABLE dbo.CashAccounts
(
    AccountCode NVARCHAR(20)  NOT NULL CONSTRAINT PK_CashAccounts PRIMARY KEY,
    AccountName NVARCHAR(80)  NOT NULL
);
GO

IF OBJECT_ID(N'dbo.ForecastMonths', N'U') IS NULL
CREATE TABLE dbo.ForecastMonths
(
    MonthNumber TINYINT      NOT NULL CONSTRAINT PK_ForecastMonths PRIMARY KEY,
    MonthLabel  NVARCHAR(20) NOT NULL CONSTRAINT UQ_ForecastMonths_Label UNIQUE
);
GO

IF OBJECT_ID(N'dbo.ProductionStages', N'U') IS NULL
CREATE TABLE dbo.ProductionStages
(
    StageCode NVARCHAR(30) NOT NULL CONSTRAINT PK_ProductionStages PRIMARY KEY,
    StageName NVARCHAR(80) NOT NULL,
    SortOrder TINYINT      NOT NULL CONSTRAINT DF_ProductionStages_Sort DEFAULT (0)
);
GO

IF OBJECT_ID(N'dbo.ProjectStates', N'U') IS NULL
CREATE TABLE dbo.ProjectStates
(
    StateName NVARCHAR(120) NOT NULL CONSTRAINT PK_ProjectStates PRIMARY KEY,
    SortOrder TINYINT       NOT NULL CONSTRAINT DF_ProjectStates_Sort DEFAULT (0)
);
GO

IF OBJECT_ID(N'dbo.Warehouses', N'U') IS NULL
CREATE TABLE dbo.Warehouses
(
    WarehouseId NVARCHAR(160) NOT NULL CONSTRAINT PK_Warehouses PRIMARY KEY,
    Name        NVARCHAR(200) NOT NULL CONSTRAINT DF_Warehouses_Name DEFAULT (N''),
    Location    NVARCHAR(240) NULL,
    IsActive    BIT           NOT NULL CONSTRAINT DF_Warehouses_Active DEFAULT (1)
);
GO

IF OBJECT_ID(N'dbo.ProductCategories', N'U') IS NULL
CREATE TABLE dbo.ProductCategories
(
    CategoryId   NVARCHAR(80)  NOT NULL CONSTRAINT PK_ProductCategories PRIMARY KEY,
    CategoryName NVARCHAR(120) NOT NULL CONSTRAINT UQ_ProductCategories_Name UNIQUE
);
GO

IF OBJECT_ID(N'dbo.ChartOfAccounts', N'U') IS NULL
CREATE TABLE dbo.ChartOfAccounts
(
    AccountName NVARCHAR(200) NOT NULL CONSTRAINT PK_ChartOfAccounts PRIMARY KEY,
    AccountType NVARCHAR(20)  NOT NULL
        CONSTRAINT DF_ChartOfAccounts_Type DEFAULT (N'activo')
        CONSTRAINT CK_ChartOfAccounts_Type CHECK (AccountType IN (N'activo', N'pasivo', N'patrimonio', N'ingreso', N'gasto'))
);
GO

IF OBJECT_ID(N'dbo.FinanceCategories', N'U') IS NULL
CREATE TABLE dbo.FinanceCategories
(
    CategoryName NVARCHAR(160) NOT NULL CONSTRAINT PK_FinanceCategories PRIMARY KEY
);
GO

MERGE dbo.CashAccounts AS t
USING (VALUES (N'caja', N'Caja'), (N'banco', N'Banco')) AS s(AccountCode, AccountName)
ON t.AccountCode = s.AccountCode
WHEN NOT MATCHED THEN INSERT (AccountCode, AccountName) VALUES (s.AccountCode, s.AccountName);

MERGE dbo.ForecastMonths AS t
USING (VALUES
    (1, N'Ene'), (2, N'Feb'), (3, N'Mar'), (4, N'Abr'),
    (5, N'May'), (6, N'Jun'), (7, N'Jul'), (8, N'Ago'),
    (9, N'Sep'), (10, N'Oct'), (11, N'Nov'), (12, N'Dic')
) AS s(MonthNumber, MonthLabel)
ON t.MonthNumber = s.MonthNumber
WHEN MATCHED THEN UPDATE SET MonthLabel = s.MonthLabel
WHEN NOT MATCHED THEN INSERT (MonthNumber, MonthLabel) VALUES (s.MonthNumber, s.MonthLabel);

MERGE dbo.ProductionStages AS t
USING (VALUES
    (N'backlog',     N'Pendiente',   1),
    (N'corte',       N'Corte',       2),
    (N'ensamble',    N'Ensamble',    3),
    (N'instalacion', N'Instalación', 4),
    (N'entregado',   N'Entregado',   5)
) AS s(StageCode, StageName, SortOrder)
ON t.StageCode = s.StageCode
WHEN MATCHED THEN UPDATE SET StageName = s.StageName, SortOrder = s.SortOrder
WHEN NOT MATCHED THEN INSERT (StageCode, StageName, SortOrder) VALUES (s.StageCode, s.StageName, s.SortOrder);

MERGE dbo.ProjectStates AS t
USING (VALUES
    (N'Pendiente',    1),
    (N'Autorizada',   2),
    (N'En proceso',   3),
    (N'Fabricación',  4),
    (N'Instalación',  5),
    (N'Cierre',       6),
    (N'Liquidada',    7),
    (N'Anulada',      8)
) AS s(StateName, SortOrder)
ON t.StateName = s.StateName
WHEN MATCHED THEN UPDATE SET SortOrder = s.SortOrder
WHEN NOT MATCHED THEN INSERT (StateName, SortOrder) VALUES (s.StateName, s.SortOrder);

MERGE dbo.Warehouses AS t
USING (VALUES
    (N'Bodega central',  N'Bodega central',  N'Taller principal', 1),
    (N'Obra Torre Azul', N'Obra Torre Azul', N'Proyecto', 1),
    (N'Showroom',        N'Showroom',        N'Sala de ventas', 1),
    (N'wh-central',      N'Bodega central',  N'Taller principal', 1),
    (N'wh-torre',        N'Obra Torre Azul', N'Proyecto', 1),
    (N'wh-show',         N'Showroom',        N'Sala de ventas', 1)
) AS s(WarehouseId, Name, Location, IsActive)
ON t.WarehouseId = s.WarehouseId
WHEN MATCHED THEN UPDATE SET Name = s.Name, Location = s.Location, IsActive = s.IsActive
WHEN NOT MATCHED THEN INSERT (WarehouseId, Name, Location, IsActive)
     VALUES (s.WarehouseId, s.Name, s.Location, s.IsActive);

MERGE dbo.ProductCategories AS t
USING (VALUES
    (N'cat-perf', N'Perfiles'),
    (N'cat-vid',  N'Vidrios'),
    (N'cat-acc',  N'Accesorios'),
    (N'cat-elec', N'Electrodomésticos')
) AS s(CategoryId, CategoryName)
ON t.CategoryId = s.CategoryId
WHEN MATCHED THEN UPDATE SET CategoryName = s.CategoryName
WHEN NOT MATCHED THEN INSERT (CategoryId, CategoryName) VALUES (s.CategoryId, s.CategoryName);

MERGE dbo.ChartOfAccounts AS t
USING (VALUES
    (N'Caja',                  N'activo'),
    (N'Banco',                 N'activo'),
    (N'Inventario',            N'activo'),
    (N'Cuentas por cobrar',    N'activo'),
    (N'Cuentas por pagar',     N'pasivo'),
    (N'Ventas',                N'ingreso'),
    (N'Costo de ventas',       N'gasto'),
    (N'Gastos operativos',     N'gasto'),
    (N'INSS por pagar',        N'pasivo'),
    (N'IR por pagar',          N'pasivo'),
    (N'Nómina',                N'gasto'),
    (N'Descuadre detectado',   N'activo'),
    (N'Pendiente auditoría',   N'pasivo')
) AS s(AccountName, AccountType)
ON t.AccountName = s.AccountName
WHEN MATCHED THEN UPDATE SET AccountType = s.AccountType
WHEN NOT MATCHED THEN INSERT (AccountName, AccountType) VALUES (s.AccountName, s.AccountType);

MERGE dbo.FinanceCategories AS t
USING (VALUES
    (N'Ventas'), (N'Materia prima'), (N'Instalación'), (N'Servicios'), (N'Nómina')
) AS s(CategoryName)
ON t.CategoryName = s.CategoryName
WHEN NOT MATCHED THEN INSERT (CategoryName) VALUES (s.CategoryName);
GO

SELECT N'Catálogos listos' AS Resultado;
GO

GO

/* ARCHIVO 3/25: 02_gobierno_y_maestros.sql */
/* 02 — Gobierno (usuarios, auditoría, snapshot) y maestros (terceros, productos, empleados) */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.ErpState', N'U') IS NULL
CREATE TABLE dbo.ErpState
(
    StateId TINYINT NOT NULL
        CONSTRAINT PK_ErpState PRIMARY KEY
        CONSTRAINT DF_ErpState_StateId DEFAULT (1),
    Payload NVARCHAR(MAX) NOT NULL,
    UpdatedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_ErpState_UpdatedAt DEFAULT (SYSUTCDATETIME()),
    Revision ROWVERSION NOT NULL,
    CONSTRAINT CK_ErpState_Singleton CHECK (StateId = 1),
    CONSTRAINT CK_ErpState_Json CHECK (ISJSON(Payload) = 1)
);
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ErpState WHERE StateId = 1)
    INSERT INTO dbo.ErpState (StateId, Payload) VALUES (1, N'{}');
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
CREATE TABLE dbo.AppUsers
(
    AppUserId NVARCHAR(100) NOT NULL CONSTRAINT PK_AppUsers PRIMARY KEY,
    Name      NVARCHAR(240) NOT NULL,
    Email     NVARCHAR(320) NOT NULL CONSTRAINT UQ_AppUsers_Email UNIQUE,
    Hierarchy NVARCHAR(30)  NOT NULL
        CONSTRAINT CK_AppUsers_Hierarchy CHECK (Hierarchy IN (N'superadmin', N'administrador', N'estandar', N'invitado')),
    IsActive  BIT           NOT NULL CONSTRAINT DF_AppUsers_Active DEFAULT (1)
);
GO

IF OBJECT_ID(N'dbo.AppUserAreas', N'U') IS NULL
CREATE TABLE dbo.AppUserAreas
(
    AppUserId NVARCHAR(100) NOT NULL,
    Area      NVARCHAR(30)  NOT NULL
        CONSTRAINT CK_AppUserAreas_Area CHECK (Area IN (
            N'produccion', N'inventario', N'finanzas', N'contabilidad', N'mercadotecnia',
            N'compras', N'ventas', N'rrhh', N'proyectos', N'gobierno'
        )),
    CONSTRAINT PK_AppUserAreas PRIMARY KEY (AppUserId, Area),
    CONSTRAINT FK_AppUserAreas_AppUsers FOREIGN KEY (AppUserId)
        REFERENCES dbo.AppUsers(AppUserId) ON DELETE CASCADE
);
GO

IF OBJECT_ID(N'dbo.Parties', N'U') IS NULL
CREATE TABLE dbo.Parties
(
    PartyId      NVARCHAR(100) NOT NULL CONSTRAINT PK_Parties PRIMARY KEY,
    Name         NVARCHAR(240) NOT NULL,
    Contact      NVARCHAR(200) NOT NULL,
    Phone        NVARCHAR(80)  NOT NULL,
    PartyType    NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_Parties_Type CHECK (PartyType IN (N'cliente', N'proveedor')),
    Ruc          NVARCHAR(40)  NULL,
    PaymentTerms NVARCHAR(80)  NULL,
    CreditLimit  DECIMAL(19,4) NOT NULL CONSTRAINT DF_Parties_Credit DEFAULT (0),
    Email        NVARCHAR(320) NULL,
    Address      NVARCHAR(500) NULL,
    SupplierCategory NVARCHAR(30) NULL
        CONSTRAINT CK_Parties_SupplierCategory CHECK (SupplierCategory IS NULL OR SupplierCategory IN (N'materiales', N'servicios', N'transporte', N'herramientas', N'otro')),
    ProductsServices NVARCHAR(1000) NULL,
    Observations NVARCHAR(2000) NULL,
    SupplierStatus NVARCHAR(20) NULL
        CONSTRAINT CK_Parties_SupplierStatus CHECK (SupplierStatus IS NULL OR SupplierStatus IN (N'activo', N'pendiente', N'inactivo')),
    CreatedAt    DATETIMEOFFSET(3) NULL,
    UpdatedAt    DATETIMEOFFSET(3) NULL,
    NextReviewDate DATE NULL
);
GO

IF OBJECT_ID(N'dbo.Promotions', N'U') IS NULL
CREATE TABLE dbo.Promotions
(
    PromotionId NVARCHAR(100)  NOT NULL CONSTRAINT PK_Promotions PRIMARY KEY,
    Title       NVARCHAR(200)  NOT NULL,
    Blurb       NVARCHAR(1000) NOT NULL,
    MinSubtotal DECIMAL(19,4)  NOT NULL,
    PercentOff  DECIMAL(9,4)   NOT NULL,
    IsActive    BIT            NOT NULL,
    Badge       NVARCHAR(120)  NOT NULL
);
GO

IF OBJECT_ID(N'dbo.Products', N'U') IS NULL
CREATE TABLE dbo.Products
(
    ProductId    NVARCHAR(100)  NOT NULL CONSTRAINT PK_Products PRIMARY KEY,
    Code         NVARCHAR(80)   NOT NULL CONSTRAINT UQ_Products_Code UNIQUE,
    Name         NVARCHAR(200)  NOT NULL,
    Category     NVARCHAR(120)  NOT NULL,
    CategoryId   NVARCHAR(80)   NULL
        CONSTRAINT FK_Products_Categories FOREIGN KEY REFERENCES dbo.ProductCategories(CategoryId),
    UnitPrice    DECIMAL(19,4)  NOT NULL,
    MinQuantity  DECIMAL(19,4)  NOT NULL,
    CreatedAt    DATETIMEOFFSET(3) NOT NULL,
    ImageUrl     NVARCHAR(1000) NULL,
    Model        NVARCHAR(160)  NULL,
    Brand        NVARCHAR(160)  NULL,
    Material     NVARCHAR(160)  NULL,
    Measures     NVARCHAR(160)  NULL,
    Capacity     NVARCHAR(160)  NULL,
    Finish       NVARCHAR(160)  NULL,
    ProductUse   NVARCHAR(500)  NULL,
    Warranty     NVARCHAR(160)  NULL
);
GO

IF OBJECT_ID(N'dbo.Employees', N'U') IS NULL
CREATE TABLE dbo.Employees
(
    EmployeeId NVARCHAR(100) NOT NULL CONSTRAINT PK_Employees PRIMARY KEY,
    Name       NVARCHAR(240) NOT NULL,
    Position   NVARCHAR(200) NOT NULL,
    Salary     DECIMAL(19,4) NOT NULL,
    Area       NVARCHAR(120) NOT NULL,
    AppUserId  NVARCHAR(100) NULL
        CONSTRAINT FK_Employees_AppUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    HireDate   DATE          NULL,
    IsActive   BIT           NOT NULL CONSTRAINT DF_Employees_Active DEFAULT (1)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Employees') AND name = N'UX_Employees_AppUserId')
    CREATE UNIQUE INDEX UX_Employees_AppUserId ON dbo.Employees(AppUserId) WHERE AppUserId IS NOT NULL;
GO

IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
CREATE TABLE dbo.AuditEvents
(
    AuditEventId NVARCHAR(100) NOT NULL CONSTRAINT PK_AuditEvents PRIMARY KEY,
    OccurredAt   DATETIMEOFFSET(3) NOT NULL,
    UserName     NVARCHAR(200) NOT NULL,
    AppUserId    NVARCHAR(100) NULL
        CONSTRAINT FK_AuditEvents_AppUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    Action       NVARCHAR(120) NOT NULL,
    Module       NVARCHAR(120) NOT NULL,
    Detail       NVARCHAR(MAX) NOT NULL,
    Severity     NVARCHAR(20)  NULL
        CONSTRAINT CK_AuditEvents_Severity CHECK (Severity IS NULL OR Severity IN (N'info', N'warn', N'critical')),
    Reference    NVARCHAR(500) NULL,
    Uml          NVARCHAR(MAX) NULL,
    Hash         NVARCHAR(256) NULL,
    PreviousHash NVARCHAR(256) NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.AuditEvents') AND name = N'IX_AuditEvents_OccurredAt')
    CREATE INDEX IX_AuditEvents_OccurredAt ON dbo.AuditEvents(OccurredAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Parties') AND name = N'IX_Parties_TypeName')
    CREATE INDEX IX_Parties_TypeName ON dbo.Parties(PartyType, Name);
GO

GO

/* ARCHIVO 4/25: 11_actualizar_proveedores.sql */
/* Actualiza dbo.Parties para administrar el directorio de proveedores. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO

IF OBJECT_ID(N'dbo.Parties', N'U') IS NULL
    THROW 50200, 'Primero ejecuta 02_gobierno_y_maestros.sql para crear dbo.Parties.', 1;
GO

IF COL_LENGTH(N'dbo.Parties', N'Email') IS NULL
    ALTER TABLE dbo.Parties ADD Email NVARCHAR(320) NULL;
IF COL_LENGTH(N'dbo.Parties', N'Address') IS NULL
    ALTER TABLE dbo.Parties ADD Address NVARCHAR(500) NULL;
IF COL_LENGTH(N'dbo.Parties', N'SupplierCategory') IS NULL
    ALTER TABLE dbo.Parties ADD SupplierCategory NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.Parties', N'ProductsServices') IS NULL
    ALTER TABLE dbo.Parties ADD ProductsServices NVARCHAR(1000) NULL;
IF COL_LENGTH(N'dbo.Parties', N'Observations') IS NULL
    ALTER TABLE dbo.Parties ADD Observations NVARCHAR(2000) NULL;
IF COL_LENGTH(N'dbo.Parties', N'SupplierStatus') IS NULL
    ALTER TABLE dbo.Parties ADD SupplierStatus NVARCHAR(20) NULL;
IF COL_LENGTH(N'dbo.Parties', N'CreatedAt') IS NULL
    ALTER TABLE dbo.Parties ADD CreatedAt DATETIMEOFFSET(3) NULL;
IF COL_LENGTH(N'dbo.Parties', N'UpdatedAt') IS NULL
    ALTER TABLE dbo.Parties ADD UpdatedAt DATETIMEOFFSET(3) NULL;
IF COL_LENGTH(N'dbo.Parties', N'NextReviewDate') IS NULL
    ALTER TABLE dbo.Parties ADD NextReviewDate DATE NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Parties') AND name = N'CK_Parties_SupplierCategory')
    ALTER TABLE dbo.Parties WITH CHECK ADD CONSTRAINT CK_Parties_SupplierCategory
        CHECK (SupplierCategory IS NULL OR SupplierCategory IN (N'materiales', N'servicios', N'transporte', N'herramientas', N'otro'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Parties') AND name = N'CK_Parties_SupplierStatus')
    ALTER TABLE dbo.Parties WITH CHECK ADD CONSTRAINT CK_Parties_SupplierStatus
        CHECK (SupplierStatus IS NULL OR SupplierStatus IN (N'activo', N'pendiente', N'inactivo'));
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Parties') AND name = N'IX_Parties_SupplierDirectory')
    CREATE INDEX IX_Parties_SupplierDirectory
        ON dbo.Parties(PartyType, SupplierStatus, SupplierCategory, Name);
GO

UPDATE dbo.Parties
SET CreatedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
WHERE PartyType = N'proveedor' AND CreatedAt IS NULL;
GO

UPDATE dbo.Parties
SET SupplierCategory = COALESCE(SupplierCategory, N'otro'),
    SupplierStatus = COALESCE(SupplierStatus, N'activo'),
    UpdatedAt = COALESCE(UpdatedAt, CreatedAt, TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'))
WHERE PartyType = N'proveedor';
GO

GO

/* ARCHIVO 5/25: 03_inventario_y_comercial.sql */
/* 03 — Inventario PEPS y ciclo comercial (ventas, proformas, compras, álbum) */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.InventoryLots', N'U') IS NULL
CREATE TABLE dbo.InventoryLots
(
    LotId       NVARCHAR(100) NOT NULL CONSTRAINT PK_InventoryLots PRIMARY KEY,
    ProductId   NVARCHAR(100) NOT NULL
        CONSTRAINT FK_InventoryLots_Products FOREIGN KEY REFERENCES dbo.Products(ProductId),
    Quantity    DECIMAL(19,4) NOT NULL,
    UnitCost    DECIMAL(19,4) NOT NULL,
    EntryDate   DATETIMEOFFSET(3) NOT NULL,
    WarehouseId NVARCHAR(160) NOT NULL
        CONSTRAINT FK_InventoryLots_Warehouses FOREIGN KEY REFERENCES dbo.Warehouses(WarehouseId)
);
GO

IF OBJECT_ID(N'dbo.KardexMoves', N'U') IS NULL
CREATE TABLE dbo.KardexMoves
(
    KardexMoveId NVARCHAR(100) NOT NULL CONSTRAINT PK_KardexMoves PRIMARY KEY,
    ProductId    NVARCHAR(100) NOT NULL
        CONSTRAINT FK_KardexMoves_Products FOREIGN KEY REFERENCES dbo.Products(ProductId),
    MoveType     NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_KardexMoves_MoveType CHECK (MoveType IN (N'entrada', N'salida')),
    Quantity     DECIMAL(19,4) NOT NULL,
    UnitCost     DECIMAL(19,4) NOT NULL,
    MoveDate     DATETIMEOFFSET(3) NOT NULL,
    Reason       NVARCHAR(500) NOT NULL,
    UserName     NVARCHAR(200) NOT NULL,
    AppUserId    NVARCHAR(100) NULL
        CONSTRAINT FK_KardexMoves_AppUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.Sales', N'U') IS NULL
CREATE TABLE dbo.Sales
(
    SaleId          NVARCHAR(100) NOT NULL CONSTRAINT PK_Sales PRIMARY KEY,
    SaleNumber      NVARCHAR(80)  NOT NULL CONSTRAINT UQ_Sales_Number UNIQUE,
    ClientName      NVARCHAR(240) NOT NULL,
    ClientPartyId   NVARCHAR(100) NULL
        CONSTRAINT FK_Sales_ClientParties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Subtotal        DECIMAL(19,4) NOT NULL,
    DiscountAmount  DECIMAL(19,4) NOT NULL,
    PromoCode       NVARCHAR(160) NULL,
    PromotionId     NVARCHAR(100) NULL
        CONSTRAINT FK_Sales_Promotions FOREIGN KEY REFERENCES dbo.Promotions(PromotionId) ON DELETE SET NULL,
    TaxAmount       DECIMAL(19,4) NOT NULL,
    Total           DECIMAL(19,4) NOT NULL,
    Status          NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_Sales_Status CHECK (Status IN (N'draft', N'completed')),
    SaleDate        DATETIMEOFFSET(3) NOT NULL,
    CreatedBy       NVARCHAR(200) NOT NULL,
    CreatedByUserId NVARCHAR(100) NULL
        CONSTRAINT FK_Sales_CreatedByUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    QrPayload       NVARCHAR(MAX) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.SaleItems', N'U') IS NULL
CREATE TABLE dbo.SaleItems
(
    SaleId     NVARCHAR(100) NOT NULL
        CONSTRAINT FK_SaleItems_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE CASCADE,
    LineNumber INT           NOT NULL,
    ProductId  NVARCHAR(100) NOT NULL
        CONSTRAINT FK_SaleItems_Products FOREIGN KEY REFERENCES dbo.Products(ProductId),
    Quantity   DECIMAL(19,4) NOT NULL,
    UnitPrice  DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_SaleItems PRIMARY KEY (SaleId, LineNumber)
);
GO

IF OBJECT_ID(N'dbo.Proformas', N'U') IS NULL
CREATE TABLE dbo.Proformas
(
    ProformaId       NVARCHAR(100) NOT NULL CONSTRAINT PK_Proformas PRIMARY KEY,
    ProformaNumber   NVARCHAR(80)  NOT NULL CONSTRAINT UQ_Proformas_Number UNIQUE,
    ClientName       NVARCHAR(240) NOT NULL,
    ClientPartyId    NVARCHAR(100) NULL
        CONSTRAINT FK_Proformas_ClientParties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Subtotal         DECIMAL(19,4) NOT NULL,
    DiscountAmount   DECIMAL(19,4) NOT NULL,
    PromoCode        NVARCHAR(160) NULL,
    PromotionId      NVARCHAR(100) NULL
        CONSTRAINT FK_Proformas_Promotions FOREIGN KEY REFERENCES dbo.Promotions(PromotionId) ON DELETE SET NULL,
    TaxAmount        DECIMAL(19,4) NOT NULL,
    Total            DECIMAL(19,4) NOT NULL,
    Status           NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_Proformas_Status CHECK (Status IN (N'borrador', N'enviada', N'aceptada', N'vencida', N'convertida')),
    ValidUntil       DATETIMEOFFSET(3) NOT NULL,
    Notes            NVARCHAR(MAX) NOT NULL,
    CreatedAt        DATETIMEOFFSET(3) NOT NULL,
    CreatedBy        NVARCHAR(200) NOT NULL,
    CreatedByUserId  NVARCHAR(100) NULL
        CONSTRAINT FK_Proformas_CreatedByUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    QrPayload        NVARCHAR(MAX) NOT NULL,
    ConvertedSaleId  NVARCHAR(100) NULL
        CONSTRAINT FK_Proformas_ConvertedSales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.ProformaItems', N'U') IS NULL
CREATE TABLE dbo.ProformaItems
(
    ProformaId NVARCHAR(100) NOT NULL
        CONSTRAINT FK_ProformaItems_Proformas FOREIGN KEY REFERENCES dbo.Proformas(ProformaId) ON DELETE CASCADE,
    LineNumber INT           NOT NULL,
    ProductId  NVARCHAR(100) NOT NULL
        CONSTRAINT FK_ProformaItems_Products FOREIGN KEY REFERENCES dbo.Products(ProductId),
    Quantity   DECIMAL(19,4) NOT NULL,
    UnitPrice  DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_ProformaItems PRIMARY KEY (ProformaId, LineNumber)
);
GO

IF OBJECT_ID(N'dbo.Purchases', N'U') IS NULL
CREATE TABLE dbo.Purchases
(
    PurchaseId       NVARCHAR(100) NOT NULL CONSTRAINT PK_Purchases PRIMARY KEY,
    PurchaseNumber   NVARCHAR(80)  NOT NULL CONSTRAINT UQ_Purchases_Number UNIQUE,
    SupplierName     NVARCHAR(240) NOT NULL,
    SupplierPartyId  NVARCHAR(100) NULL
        CONSTRAINT FK_Purchases_SupplierParties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Total            DECIMAL(19,4) NOT NULL,
    Status           NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_Purchases_Status CHECK (Status IN (N'ordered', N'received')),
    PurchaseDate     DATETIMEOFFSET(3) NOT NULL,
    CreatedBy        NVARCHAR(200) NOT NULL,
    CreatedByUserId  NVARCHAR(100) NULL
        CONSTRAINT FK_Purchases_CreatedByUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.PurchaseItems', N'U') IS NULL
CREATE TABLE dbo.PurchaseItems
(
    PurchaseId NVARCHAR(100) NOT NULL
        CONSTRAINT FK_PurchaseItems_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId) ON DELETE CASCADE,
    LineNumber INT           NOT NULL,
    ProductId  NVARCHAR(100) NOT NULL
        CONSTRAINT FK_PurchaseItems_Products FOREIGN KEY REFERENCES dbo.Products(ProductId),
    Quantity   DECIMAL(19,4) NOT NULL,
    UnitPrice  DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_PurchaseItems PRIMARY KEY (PurchaseId, LineNumber)
);
GO

IF OBJECT_ID(N'dbo.CatalogAlbums', N'U') IS NULL
CREATE TABLE dbo.CatalogAlbums
(
    AlbumId     NVARCHAR(100)  NOT NULL CONSTRAINT PK_CatalogAlbums PRIMARY KEY,
    MonthLabel  NVARCHAR(40)   NOT NULL,
    Title       NVARCHAR(240)  NOT NULL,
    Blurb       NVARCHAR(2000) NOT NULL,
    IsPublished BIT            NOT NULL,
    CreatedAt   DATETIMEOFFSET(3) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.CatalogAlbumProducts', N'U') IS NULL
CREATE TABLE dbo.CatalogAlbumProducts
(
    AlbumId    NVARCHAR(100) NOT NULL
        CONSTRAINT FK_CatalogAlbumProducts_Albums FOREIGN KEY REFERENCES dbo.CatalogAlbums(AlbumId) ON DELETE CASCADE,
    LineNumber INT           NOT NULL,
    ProductId  NVARCHAR(100) NOT NULL
        CONSTRAINT FK_CatalogAlbumProducts_Products FOREIGN KEY REFERENCES dbo.Products(ProductId),
    CONSTRAINT PK_CatalogAlbumProducts PRIMARY KEY (AlbumId, LineNumber)
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
GO

GO

/* ARCHIVO 6/25: 04_produccion_proyectos.sql */
/* 04 — Proyectos de instalación y órdenes de taller (Kanban) */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Projects', N'U') IS NULL
CREATE TABLE dbo.Projects
(
    ProjectId        NVARCHAR(100) NOT NULL CONSTRAINT PK_Projects PRIMARY KEY,
    Code             NVARCHAR(80)  NOT NULL CONSTRAINT UQ_Projects_Code UNIQUE,
    Name             NVARCHAR(240) NOT NULL,
    Client           NVARCHAR(240) NOT NULL,
    ClientPartyId    NVARCHAR(100) NULL
        CONSTRAINT FK_Projects_ClientParties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Amount           DECIMAL(19,4) NOT NULL,
    Budget           DECIMAL(19,4) NULL,
    Progress         DECIMAL(7,4)  NOT NULL,
    ProjectState     NVARCHAR(120) NOT NULL
        CONSTRAINT FK_Projects_States FOREIGN KEY REFERENCES dbo.ProjectStates(StateName),
    Owner            NVARCHAR(200) NOT NULL,
    OwnerEmployeeId  NVARCHAR(100) NULL
        CONSTRAINT FK_Projects_OwnerEmployees FOREIGN KEY REFERENCES dbo.Employees(EmployeeId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.ProjectStages', N'U') IS NULL
CREATE TABLE dbo.ProjectStages
(
    ProjectStageId NVARCHAR(100) NOT NULL CONSTRAINT PK_ProjectStages PRIMARY KEY,
    ProjectId      NVARCHAR(100) NOT NULL
        CONSTRAINT FK_ProjectStages_Projects FOREIGN KEY REFERENCES dbo.Projects(ProjectId) ON DELETE CASCADE,
    Name           NVARCHAR(200) NOT NULL,
    StartDate      DATE          NULL,
    EndDate        DATE          NULL,
    CostActual     DECIMAL(19,4) NOT NULL CONSTRAINT DF_ProjectStages_Cost DEFAULT (0)
);
GO

IF OBJECT_ID(N'dbo.ProductionOrders', N'U') IS NULL
CREATE TABLE dbo.ProductionOrders
(
    ProductionOrderId    NVARCHAR(100) NOT NULL CONSTRAINT PK_ProductionOrders PRIMARY KEY,
    Code                 NVARCHAR(80)  NOT NULL CONSTRAINT UQ_ProductionOrders_Code UNIQUE,
    Product              NVARCHAR(240) NOT NULL,
    Client               NVARCHAR(240) NOT NULL,
    ClientPartyId        NVARCHAR(100) NULL
        CONSTRAINT FK_ProductionOrders_ClientParties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    ProjectId            NVARCHAR(100) NULL
        CONSTRAINT FK_ProductionOrders_Projects FOREIGN KEY REFERENCES dbo.Projects(ProjectId) ON DELETE SET NULL,
    Quantity             DECIMAL(19,4) NOT NULL,
    Stage                NVARCHAR(30)  NOT NULL
        CONSTRAINT CK_ProductionOrders_Stage CHECK (Stage IN (N'backlog', N'corte', N'ensamble', N'instalacion', N'entregado')),
    ProductionStageCode  NVARCHAR(30)  NULL
        CONSTRAINT FK_ProductionOrders_Stages FOREIGN KEY REFERENCES dbo.ProductionStages(StageCode),
    Sprint               NVARCHAR(100) NOT NULL,
    Owner                NVARCHAR(200) NOT NULL,
    OwnerEmployeeId      NVARCHAR(100) NULL
        CONSTRAINT FK_ProductionOrders_OwnerEmployees FOREIGN KEY REFERENCES dbo.Employees(EmployeeId) ON DELETE SET NULL
);
GO

GO

/* ARCHIVO 7/25: 05_finanzas_nomina.sql */
/* 05 — Tesorería, contabilidad, cartera, planilla */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.PayrollRuns', N'U') IS NULL
CREATE TABLE dbo.PayrollRuns
(
    PayrollRunId NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollRuns PRIMARY KEY,
    Period       NVARCHAR(40)  NOT NULL,
    PaidAt       DATETIMEOFFSET(3) NOT NULL,
    Actor        NVARCHAR(200) NOT NULL,
    ActorUserId  NVARCHAR(100) NULL
        CONSTRAINT FK_PayrollRuns_ActorUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    Gross        DECIMAL(19,4) NOT NULL,
    InssLaboral  DECIMAL(19,4) NOT NULL,
    InssPatronal DECIMAL(19,4) NOT NULL,
    Inatec       DECIMAL(19,4) NOT NULL,
    IncomeTax    DECIMAL(19,4) NOT NULL,
    Net          DECIMAL(19,4) NOT NULL,
    EmployerCost DECIMAL(19,4) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.PayrollRunItems', N'U') IS NULL
CREATE TABLE dbo.PayrollRunItems
(
    PayrollRunId NVARCHAR(100) NOT NULL
        CONSTRAINT FK_PayrollRunItems_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId   NVARCHAR(100) NOT NULL
        CONSTRAINT FK_PayrollRunItems_Employees FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    Gross        DECIMAL(19,4) NOT NULL,
    InssLaboral  DECIMAL(19,4) NOT NULL,
    IncomeTax    DECIMAL(19,4) NOT NULL,
    Net          DECIMAL(19,4) NOT NULL,
    InssPatronal DECIMAL(19,4) NOT NULL,
    Inatec       DECIMAL(19,4) NOT NULL,
    Aguinaldo    DECIMAL(19,4) NOT NULL,
    EmployerCost DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_PayrollRunItems PRIMARY KEY (PayrollRunId, EmployeeId)
);
GO

IF OBJECT_ID(N'dbo.CashMoves', N'U') IS NULL
CREATE TABLE dbo.CashMoves
(
    CashMoveId      NVARCHAR(100) NOT NULL CONSTRAINT PK_CashMoves PRIMARY KEY,
    Account         NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_CashMoves_Account CHECK (Account IN (N'caja', N'banco')),
    CashAccountCode NVARCHAR(20)  NULL
        CONSTRAINT FK_CashMoves_CashAccounts FOREIGN KEY REFERENCES dbo.CashAccounts(AccountCode),
    MoveType        NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_CashMoves_MoveType CHECK (MoveType IN (N'entrada', N'salida')),
    Amount          DECIMAL(19,4) NOT NULL,
    MoveDate        DATETIMEOFFSET(3) NOT NULL,
    Concept         NVARCHAR(1000) NOT NULL,
    SaleId          NVARCHAR(100) NULL
        CONSTRAINT FK_CashMoves_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL,
    PurchaseId      NVARCHAR(100) NULL
        CONSTRAINT FK_CashMoves_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId) ON DELETE SET NULL,
    PayrollRunId    NVARCHAR(100) NULL
        CONSTRAINT FK_CashMoves_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.FinanceMoves', N'U') IS NULL
CREATE TABLE dbo.FinanceMoves
(
    FinanceMoveId        NVARCHAR(100)  NOT NULL CONSTRAINT PK_FinanceMoves PRIMARY KEY,
    MoveType             NVARCHAR(20)   NOT NULL
        CONSTRAINT CK_FinanceMoves_MoveType CHECK (MoveType IN (N'ingreso', N'egreso')),
    Category             NVARCHAR(160)  NOT NULL,
    FinanceCategoryName  NVARCHAR(160)  NULL
        CONSTRAINT FK_FinanceMoves_Categories FOREIGN KEY REFERENCES dbo.FinanceCategories(CategoryName),
    Amount               DECIMAL(19,4)  NOT NULL,
    MoveDate             DATETIMEOFFSET(3) NOT NULL,
    Note                 NVARCHAR(1000) NOT NULL,
    UserName             NVARCHAR(200)  NOT NULL,
    AppUserId            NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_AppUsers FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
    SaleId               NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE SET NULL,
    PurchaseId           NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId) ON DELETE SET NULL,
    PayrollRunId         NVARCHAR(100)  NULL
        CONSTRAINT FK_FinanceMoves_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL
);
GO

IF OBJECT_ID(N'dbo.AccountingEntries', N'U') IS NULL
CREATE TABLE dbo.AccountingEntries
(
    AccountingEntryId NVARCHAR(100)  NOT NULL CONSTRAINT PK_AccountingEntries PRIMARY KEY,
    EntryNumber       NVARCHAR(80)   NOT NULL CONSTRAINT UQ_AccountingEntries_Number UNIQUE,
    Description       NVARCHAR(1000) NOT NULL,
    Debit             DECIMAL(19,4)  NOT NULL,
    Credit            DECIMAL(19,4)  NOT NULL,
    DebitAccount      NVARCHAR(200)  NOT NULL,
    CreditAccount     NVARCHAR(200)  NOT NULL,
    DebitAccountRef   NVARCHAR(200)  NULL
        CONSTRAINT FK_AccountingEntries_DebitAccounts FOREIGN KEY REFERENCES dbo.ChartOfAccounts(AccountName),
    CreditAccountRef  NVARCHAR(200)  NULL
        CONSTRAINT FK_AccountingEntries_CreditAccounts FOREIGN KEY REFERENCES dbo.ChartOfAccounts(AccountName),
    EntryDate         DATETIMEOFFSET(3) NOT NULL,
    ReferenceType     NVARCHAR(20)   NOT NULL
        CONSTRAINT CK_AccountingEntries_ReferenceType CHECK (ReferenceType IN (N'sale', N'purchase', N'manual', N'payroll', N'cash')),
    ReferenceId       NVARCHAR(100)  NULL,
    SaleId            NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId),
    PurchaseId        NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId),
    PayrollRunId      NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_PayrollRuns FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId),
    CashMoveId        NVARCHAR(100)  NULL
        CONSTRAINT FK_AccountingEntries_CashMoves FOREIGN KEY REFERENCES dbo.CashMoves(CashMoveId),
    CONSTRAINT CK_AccountingEntries_PartidaDoble CHECK (Debit = Credit)
);
GO

IF OBJECT_ID(N'dbo.Projections', N'U') IS NULL
CREATE TABLE dbo.Projections
(
    ProjectionId  NVARCHAR(100) NOT NULL CONSTRAINT PK_Projections PRIMARY KEY,
    MonthLabel    NVARCHAR(40)  NOT NULL,
    MonthNumber   TINYINT       NULL
        CONSTRAINT FK_Projections_ForecastMonths FOREIGN KEY REFERENCES dbo.ForecastMonths(MonthNumber),
    ExpectedSales DECIMAL(19,4) NOT NULL,
    ExpectedCosts DECIMAL(19,4) NOT NULL
);
GO

IF OBJECT_ID(N'dbo.AccountsReceivable', N'U') IS NULL
CREATE TABLE dbo.AccountsReceivable
(
    ReceivableId NVARCHAR(100) NOT NULL CONSTRAINT PK_AccountsReceivable PRIMARY KEY,
    SaleId       NVARCHAR(100) NOT NULL
        CONSTRAINT FK_AccountsReceivable_Sales FOREIGN KEY REFERENCES dbo.Sales(SaleId) ON DELETE CASCADE,
    PartyId      NVARCHAR(100) NULL
        CONSTRAINT FK_AccountsReceivable_Parties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Amount       DECIMAL(19,4) NOT NULL,
    Balance      DECIMAL(19,4) NOT NULL,
    DueDate      DATE          NULL,
    Status       NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_AccountsReceivable_Status CHECK (Status IN (N'abierta', N'parcial', N'cobrada', N'vencida'))
);
GO

IF OBJECT_ID(N'dbo.AccountsPayable', N'U') IS NULL
CREATE TABLE dbo.AccountsPayable
(
    PayableId  NVARCHAR(100) NOT NULL CONSTRAINT PK_AccountsPayable PRIMARY KEY,
    PurchaseId NVARCHAR(100) NOT NULL
        CONSTRAINT FK_AccountsPayable_Purchases FOREIGN KEY REFERENCES dbo.Purchases(PurchaseId) ON DELETE CASCADE,
    PartyId    NVARCHAR(100) NULL
        CONSTRAINT FK_AccountsPayable_Parties FOREIGN KEY REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL,
    Amount     DECIMAL(19,4) NOT NULL,
    Balance    DECIMAL(19,4) NOT NULL,
    DueDate    DATE          NULL,
    Status     NVARCHAR(20)  NOT NULL
        CONSTRAINT CK_AccountsPayable_Status CHECK (Status IN (N'abierta', N'parcial', N'pagada'))
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.FinanceMoves') AND name = N'IX_FinanceMoves_Date')
    CREATE INDEX IX_FinanceMoves_Date ON dbo.FinanceMoves(MoveDate DESC);
GO

GO

/* ARCHIVO 8/25: 06_vistas.sql */
/* 06 — Vistas en español (consultas con JOINs para reportes y diagrama) */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW dbo.vw_EstadoERP AS
SELECT StateId AS IdEstado, Payload AS DatosJSON, UpdatedAt AS ActualizadoUTC, Revision AS Version
FROM dbo.ErpState;
GO

CREATE OR ALTER VIEW dbo.vw_Productos AS
SELECT p.ProductId AS IdProducto, p.Code AS Codigo, p.Name AS Nombre,
       p.Category AS Categoria, p.CategoryId AS IdCategoria, c.CategoryName AS NombreCategoria,
       p.UnitPrice AS PrecioUnitario, p.MinQuantity AS CantidadMinima, p.CreatedAt AS FechaCreacion,
       p.ImageUrl AS Imagen, p.Model AS Modelo, p.Brand AS Marca, p.Material AS Material,
       p.Measures AS Medidas, p.Capacity AS Capacidad, p.Finish AS Acabado,
       p.ProductUse AS Uso, p.Warranty AS Garantia
FROM dbo.Products AS p
LEFT JOIN dbo.ProductCategories AS c ON c.CategoryId = p.CategoryId;
GO

CREATE OR ALTER VIEW dbo.vw_LotesInventario AS
SELECT l.LotId AS IdLote, l.ProductId AS IdProducto, p.Name AS Producto,
       l.Quantity AS Cantidad, l.UnitCost AS CostoUnitario,
       l.EntryDate AS FechaEntrada, l.WarehouseId AS IdBodega, w.Name AS Bodega
FROM dbo.InventoryLots AS l
JOIN dbo.Products AS p ON p.ProductId = l.ProductId
JOIN dbo.Warehouses AS w ON w.WarehouseId = l.WarehouseId;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosKardex AS
SELECT k.KardexMoveId AS IdMovimiento, k.ProductId AS IdProducto, p.Name AS Producto,
       k.MoveType AS Tipo, k.Quantity AS Cantidad, k.UnitCost AS CostoUnitario,
       k.MoveDate AS Fecha, k.Reason AS Motivo, k.UserName AS Usuario, k.AppUserId AS IdUsuario
FROM dbo.KardexMoves AS k
JOIN dbo.Products AS p ON p.ProductId = k.ProductId;
GO

CREATE OR ALTER VIEW dbo.vw_Ventas AS
SELECT s.SaleId AS IdVenta, s.SaleNumber AS NumeroVenta,
       COALESCE(c.Name, s.ClientName) AS Cliente, s.ClientPartyId AS IdCliente,
       s.Subtotal AS Subtotal, s.DiscountAmount AS Descuento, s.PromoCode AS Promocion,
       s.PromotionId AS IdPromocion, s.TaxAmount AS Impuesto, s.Total AS Total,
       s.Status AS Estado, s.SaleDate AS FechaVenta, s.CreatedBy AS CreadoPor,
       s.CreatedByUserId AS IdUsuario, s.QrPayload AS CodigoQR
FROM dbo.Sales AS s
LEFT JOIN dbo.Parties AS c ON c.PartyId = s.ClientPartyId;
GO

CREATE OR ALTER VIEW dbo.vw_DetallesVenta AS
SELECT i.SaleId AS IdVenta, s.SaleNumber AS NumeroVenta, i.LineNumber AS NumeroLinea,
       i.ProductId AS IdProducto, p.Name AS Producto, i.Quantity AS Cantidad,
       i.UnitPrice AS PrecioUnitario, i.Quantity * i.UnitPrice AS TotalLinea
FROM dbo.SaleItems AS i
JOIN dbo.Sales AS s ON s.SaleId = i.SaleId
JOIN dbo.Products AS p ON p.ProductId = i.ProductId;
GO

CREATE OR ALTER VIEW dbo.vw_Proformas AS
SELECT f.ProformaId AS IdProforma, f.ProformaNumber AS NumeroProforma,
       COALESCE(c.Name, f.ClientName) AS Cliente, f.ClientPartyId AS IdCliente,
       f.Subtotal AS Subtotal, f.DiscountAmount AS Descuento, f.PromoCode AS Promocion,
       f.TaxAmount AS Impuesto, f.Total AS Total, f.Status AS Estado,
       f.ValidUntil AS VigenteHasta, f.Notes AS Notas, f.CreatedAt AS FechaCreacion,
       f.CreatedBy AS CreadoPor, f.QrPayload AS CodigoQR, f.ConvertedSaleId AS IdVentaConvertida
FROM dbo.Proformas AS f
LEFT JOIN dbo.Parties AS c ON c.PartyId = f.ClientPartyId;
GO

CREATE OR ALTER VIEW dbo.vw_DetallesProforma AS
SELECT i.ProformaId AS IdProforma, i.LineNumber AS NumeroLinea,
       i.ProductId AS IdProducto, p.Name AS Producto, i.Quantity AS Cantidad, i.UnitPrice AS PrecioUnitario
FROM dbo.ProformaItems AS i
JOIN dbo.Products AS p ON p.ProductId = i.ProductId;
GO

CREATE OR ALTER VIEW dbo.vw_Promociones AS
SELECT PromotionId AS IdPromocion, Title AS Titulo, Blurb AS Descripcion,
       MinSubtotal AS SubtotalMinimo, PercentOff AS PorcentajeDescuento,
       IsActive AS Activa, Badge AS Distintivo
FROM dbo.Promotions;
GO

CREATE OR ALTER VIEW dbo.vw_Compras AS
SELECT pu.PurchaseId AS IdCompra, pu.PurchaseNumber AS NumeroCompra,
       COALESCE(pv.Name, pu.SupplierName) AS Proveedor, pu.SupplierPartyId AS IdProveedor,
       pu.Total AS Total, pu.Status AS Estado, pu.PurchaseDate AS FechaCompra, pu.CreatedBy AS CreadoPor
FROM dbo.Purchases AS pu
LEFT JOIN dbo.Parties AS pv ON pv.PartyId = pu.SupplierPartyId;
GO

CREATE OR ALTER VIEW dbo.vw_DetallesCompra AS
SELECT i.PurchaseId AS IdCompra, i.LineNumber AS NumeroLinea,
       i.ProductId AS IdProducto, p.Name AS Producto, i.Quantity AS Cantidad, i.UnitPrice AS PrecioUnitario
FROM dbo.PurchaseItems AS i
JOIN dbo.Products AS p ON p.ProductId = i.ProductId;
GO

CREATE OR ALTER VIEW dbo.vw_AsientosContables AS
SELECT e.AccountingEntryId AS IdAsiento, e.EntryNumber AS NumeroAsiento, e.Description AS Descripcion,
       e.Debit AS Debito, e.Credit AS Credito, e.DebitAccount AS CuentaDebito, e.CreditAccount AS CuentaCredito,
       e.EntryDate AS FechaAsiento, e.ReferenceType AS TipoReferencia, e.ReferenceId AS IdReferencia,
       e.SaleId AS IdVenta, e.PurchaseId AS IdCompra, e.PayrollRunId AS IdPlanilla, e.CashMoveId AS IdCaja
FROM dbo.AccountingEntries AS e;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosFinancieros AS
SELECT FinanceMoveId AS IdMovimiento, MoveType AS Tipo, Category AS Categoria,
       Amount AS Monto, MoveDate AS Fecha, Note AS Nota, UserName AS Usuario,
       SaleId AS IdVenta, PurchaseId AS IdCompra, PayrollRunId AS IdPlanilla
FROM dbo.FinanceMoves;
GO

CREATE OR ALTER VIEW dbo.vw_Proyecciones AS
SELECT ProjectionId AS IdProyeccion, MonthLabel AS Mes, MonthNumber AS NumeroMes,
       ExpectedSales AS VentasEsperadas, ExpectedCosts AS CostosEsperados
FROM dbo.Projections;
GO

CREATE OR ALTER VIEW dbo.vw_OrdenesProduccion AS
SELECT o.ProductionOrderId AS IdOrden, o.Code AS Codigo, o.Product AS Producto,
       COALESCE(c.Name, o.Client) AS Cliente, o.ClientPartyId AS IdCliente,
       o.ProjectId AS IdProyecto, pr.Code AS CodigoProyecto,
       o.Quantity AS Cantidad, o.Stage AS Etapa, o.Sprint AS Sprint, o.Owner AS Responsable
FROM dbo.ProductionOrders AS o
LEFT JOIN dbo.Parties AS c ON c.PartyId = o.ClientPartyId
LEFT JOIN dbo.Projects AS pr ON pr.ProjectId = o.ProjectId;
GO

CREATE OR ALTER VIEW dbo.vw_Terceros AS
SELECT PartyId AS IdTercero, Name AS Nombre, Contact AS Contacto,
       Phone AS Telefono, PartyType AS Tipo, Ruc AS RUC, PaymentTerms AS Plazo, CreditLimit AS LimiteCredito
FROM dbo.Parties;
GO

CREATE OR ALTER VIEW dbo.vw_Empleados AS
SELECT e.EmployeeId AS IdEmpleado, e.Name AS Nombre, e.Position AS Cargo,
       e.Salary AS Salario, e.Area AS Area, e.AppUserId AS IdUsuario, u.Email AS Correo
FROM dbo.Employees AS e
LEFT JOIN dbo.AppUsers AS u ON u.AppUserId = e.AppUserId;
GO

CREATE OR ALTER VIEW dbo.vw_Planillas AS
SELECT PayrollRunId AS IdPlanilla, Period AS Periodo, PaidAt AS FechaPago,
       Actor AS Responsable, Gross AS SalarioBruto, InssLaboral AS INSSLaboral,
       InssPatronal AS INSSPatronal, Inatec AS INATEC, IncomeTax AS ImpuestoRenta,
       Net AS SalarioNeto, EmployerCost AS CostoPatronal
FROM dbo.PayrollRuns;
GO

CREATE OR ALTER VIEW dbo.vw_AlbumesCatalogo AS
SELECT AlbumId AS IdAlbum, MonthLabel AS Mes, Title AS Titulo,
       Blurb AS Descripcion, IsPublished AS Publicado, CreatedAt AS FechaCreacion
FROM dbo.CatalogAlbums;
GO

CREATE OR ALTER VIEW dbo.vw_ProductosAlbum AS
SELECT a.AlbumId AS IdAlbum, al.Title AS Album, a.LineNumber AS NumeroLinea,
       a.ProductId AS IdProducto, p.Name AS Producto
FROM dbo.CatalogAlbumProducts AS a
JOIN dbo.CatalogAlbums AS al ON al.AlbumId = a.AlbumId
JOIN dbo.Products AS p ON p.ProductId = a.ProductId;
GO

CREATE OR ALTER VIEW dbo.vw_Proyectos AS
SELECT p.ProjectId AS IdProyecto, p.Code AS Codigo, p.Name AS Nombre,
       COALESCE(c.Name, p.Client) AS Cliente, p.ClientPartyId AS IdCliente,
       p.Amount AS Monto, p.Progress AS Avance, p.ProjectState AS Estado, p.Owner AS Responsable
FROM dbo.Projects AS p
LEFT JOIN dbo.Parties AS c ON c.PartyId = p.ClientPartyId;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosCaja AS
SELECT CashMoveId AS IdMovimiento, Account AS Cuenta, MoveType AS Tipo,
       Amount AS Monto, MoveDate AS Fecha, Concept AS Concepto,
       SaleId AS IdVenta, PurchaseId AS IdCompra, PayrollRunId AS IdPlanilla
FROM dbo.CashMoves;
GO

CREATE OR ALTER VIEW dbo.vw_UsuariosERP AS
SELECT AppUserId AS IdUsuario, Name AS Nombre, Email AS Correo,
       Hierarchy AS Rol, IsActive AS Activo
FROM dbo.AppUsers;
GO

CREATE OR ALTER VIEW dbo.vw_AreasUsuario AS
SELECT AppUserId AS IdUsuario, Area AS Area
FROM dbo.AppUserAreas;
GO

CREATE OR ALTER VIEW dbo.vw_EventosAuditoria AS
SELECT AuditEventId AS IdEvento, OccurredAt AS Fecha, UserName AS Usuario,
       [Action] AS Accion, [Module] AS Modulo, Detail AS Detalle,
       Severity AS Severidad, [Reference] AS Referencia, Uml AS Modelo,
       Hash AS Huella, PreviousHash AS HuellaAnterior
FROM dbo.AuditEvents;
GO

CREATE OR ALTER VIEW dbo.vw_CuentasPorCobrar AS
SELECT r.ReceivableId AS IdCxC, r.SaleId AS IdVenta, s.SaleNumber AS Factura,
       r.PartyId AS IdCliente, COALESCE(p.Name, s.ClientName) AS Cliente,
       r.Amount AS Monto, r.Balance AS Saldo, r.DueDate AS Vence, r.Status AS Estado
FROM dbo.AccountsReceivable AS r
JOIN dbo.Sales AS s ON s.SaleId = r.SaleId
LEFT JOIN dbo.Parties AS p ON p.PartyId = r.PartyId;
GO

CREATE OR ALTER VIEW dbo.vw_CuentasPorPagar AS
SELECT ap.PayableId AS IdCxP, ap.PurchaseId AS IdCompra, pu.PurchaseNumber AS Orden,
       ap.PartyId AS IdProveedor, COALESCE(p.Name, pu.SupplierName) AS Proveedor,
       ap.Amount AS Monto, ap.Balance AS Saldo, ap.DueDate AS Vence, ap.Status AS Estado
FROM dbo.AccountsPayable AS ap
JOIN dbo.Purchases AS pu ON pu.PurchaseId = ap.PurchaseId
LEFT JOIN dbo.Parties AS p ON p.PartyId = ap.PartyId;
GO

CREATE OR ALTER VIEW dbo.vw_MapaRelaciones AS
SELECT fk.name AS Relacion,
       OBJECT_NAME(fk.parent_object_id) AS TablaHija,
       COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ColumnaHija,
       OBJECT_NAME(fk.referenced_object_id) AS TablaPadre,
       COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ColumnaPadre
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fc ON fc.constraint_object_id = fk.object_id
WHERE fk.is_disabled = 0;
GO

SELECT N'Vistas listas' AS Resultado, COUNT(*) AS Cantidad
FROM sys.views
WHERE schema_id = SCHEMA_ID(N'dbo') AND name LIKE N'vw[_]%';
GO

GO

/* ARCHIVO 9/25: 12_sincronizacion_proveedores.sql */
/* Persistencia idempotente de proveedores y permisos minimos para la API. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO

IF OBJECT_ID(N'dbo.Parties', N'U') IS NULL
    THROW 50300, 'Falta dbo.Parties; ejecuta primero los scripts base.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50311, 'Falta dbo.AuditEvents; ejecuta primero los scripts base.', 1;
IF COL_LENGTH(N'dbo.Parties', N'Email') IS NULL
   OR COL_LENGTH(N'dbo.Parties', N'NextReviewDate') IS NULL
    THROW 50301, 'Faltan columnas del directorio; ejecuta primero 11_actualizar_proveedores.sql.', 1;
GO

IF EXISTS (
    SELECT LOWER(LTRIM(RTRIM(Name)))
    FROM dbo.Parties
    WHERE PartyType = N'proveedor'
    GROUP BY LOWER(LTRIM(RTRIM(Name)))
    HAVING COUNT(*) > 1
)
    THROW 50302, 'Hay proveedores duplicados por nombre; resuelvelos antes de crear el indice.', 1;
IF EXISTS (
    SELECT LOWER(LTRIM(RTRIM(Ruc)))
    FROM dbo.Parties
    WHERE PartyType = N'proveedor' AND NULLIF(LTRIM(RTRIM(Ruc)), N'') IS NOT NULL
    GROUP BY LOWER(LTRIM(RTRIM(Ruc)))
    HAVING COUNT(*) > 1
)
    THROW 50303, 'Hay proveedores duplicados por identificacion fiscal; resuelvelos antes de crear el indice.', 1;
GO

IF COL_LENGTH(N'dbo.Parties', N'SupplierNameKey') IS NULL
    ALTER TABLE dbo.Parties ADD SupplierNameKey AS (
        LOWER(LTRIM(RTRIM(Name)))
    ) PERSISTED;
IF COL_LENGTH(N'dbo.Parties', N'SupplierRucKey') IS NULL
    ALTER TABLE dbo.Parties ADD SupplierRucKey AS (
        COALESCE(NULLIF(LOWER(LTRIM(RTRIM(Ruc))), N''), NCHAR(1) + PartyId)
    ) PERSISTED;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Parties') AND name = N'UX_Parties_SupplierName')
    CREATE UNIQUE INDEX UX_Parties_SupplierName ON dbo.Parties(SupplierNameKey)
        WHERE PartyType = N'proveedor';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.Parties') AND name = N'UX_Parties_SupplierRuc')
    CREATE UNIQUE INDEX UX_Parties_SupplierRuc ON dbo.Parties(SupplierRucKey)
        WHERE PartyType = N'proveedor';
GO

CREATE OR ALTER PROCEDURE dbo.usp_UpsertSupplier
    @PartyId NVARCHAR(100),
    @Name NVARCHAR(240),
    @Category NVARCHAR(30),
    @Contact NVARCHAR(200),
    @Phone NVARCHAR(80),
    @Email NVARCHAR(320),
    @Address NVARCHAR(500),
    @ProductsServices NVARCHAR(1000),
    @Ruc NVARCHAR(40),
    @PaymentTerms NVARCHAR(80),
    @Observations NVARCHAR(2000),
    @Status NVARCHAR(20),
    @NextReviewDate DATE,
    @Actor NVARCHAR(200),
    @AuditEventId NVARCHAR(100),
    @AuditAction NVARCHAR(120),
    @AuditDetail NVARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OwnTransaction BIT = 0;
    SET @Name = LTRIM(RTRIM(@Name));
    SET @Phone = NULLIF(LTRIM(RTRIM(@Phone)), N'');
    SET @Email = NULLIF(LTRIM(RTRIM(@Email)), N'');
    SET @Ruc = NULLIF(LTRIM(RTRIM(@Ruc)), N'');

    IF NULLIF(@Name, N'') IS NULL
        THROW 50304, 'El nombre del proveedor es obligatorio.', 1;
    IF @Phone IS NULL AND @Email IS NULL
        THROW 50305, 'Indica un telefono o un correo electronico.', 1;
    IF @Category IS NULL OR @Category NOT IN (N'materiales', N'servicios', N'transporte', N'herramientas', N'otro')
        THROW 50306, 'La categoria del proveedor no es valida.', 1;
    IF @Status IS NULL OR @Status NOT IN (N'activo', N'pendiente', N'inactivo')
        THROW 50307, 'El estado del proveedor no es valido.', 1;
    IF NULLIF(LTRIM(RTRIM(@AuditEventId)), N'') IS NULL
       OR @AuditAction IS NULL
       OR @AuditAction NOT IN (N'alta proveedor', N'actualizar proveedor')
       OR NULLIF(LTRIM(RTRIM(@AuditDetail)), N'') IS NULL
        THROW 50312, 'Faltan los datos de auditoria del proveedor.', 1;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnTransaction = 1;
        END;

        IF EXISTS (SELECT 1 FROM dbo.Parties WITH (UPDLOCK, HOLDLOCK) WHERE PartyId = @PartyId AND PartyType <> N'proveedor')
            THROW 50308, 'El identificador ya pertenece a un tercero que no es proveedor.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Parties WITH (UPDLOCK, HOLDLOCK)
                   WHERE PartyType = N'proveedor' AND SupplierNameKey = LOWER(@Name) AND PartyId <> @PartyId)
            THROW 50309, 'Ya existe un proveedor con ese nombre.', 1;
        IF @Ruc IS NOT NULL AND EXISTS (
            SELECT 1 FROM dbo.Parties WITH (UPDLOCK, HOLDLOCK)
            WHERE PartyType = N'proveedor' AND SupplierRucKey = LOWER(@Ruc) AND PartyId <> @PartyId
        )
            THROW 50310, 'Ya existe un proveedor con esa identificacion fiscal.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Parties WITH (UPDLOCK, HOLDLOCK) WHERE PartyId = @PartyId)
        BEGIN
            UPDATE dbo.Parties
            SET Name = @Name,
                SupplierCategory = @Category,
                Contact = COALESCE(@Contact, N''),
                Phone = COALESCE(@Phone, N''),
                Email = @Email,
                Address = @Address,
                ProductsServices = @ProductsServices,
                Ruc = @Ruc,
                PaymentTerms = @PaymentTerms,
                Observations = @Observations,
                SupplierStatus = @Status,
                UpdatedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                NextReviewDate = @NextReviewDate
            WHERE PartyId = @PartyId AND PartyType = N'proveedor';
        END
        ELSE
        BEGIN
            INSERT INTO dbo.Parties (
                PartyId, Name, Contact, Phone, PartyType, Ruc, PaymentTerms, Email, Address,
                SupplierCategory, ProductsServices, Observations, SupplierStatus, CreatedAt, UpdatedAt, NextReviewDate
            )
            VALUES (
                @PartyId, @Name, COALESCE(@Contact, N''), COALESCE(@Phone, N''), N'proveedor',
                @Ruc, @PaymentTerms, @Email, @Address, @Category, @ProductsServices, @Observations, @Status,
                TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'), @NextReviewDate
            );
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.AuditEvents WITH (UPDLOCK, HOLDLOCK) WHERE AuditEventId = @AuditEventId)
        BEGIN
            INSERT INTO dbo.AuditEvents (AuditEventId, OccurredAt, UserName, Action, Module, Detail, Severity, Reference)
            VALUES (
                @AuditEventId, TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                COALESCE(NULLIF(@Actor, N''), N'sistema'), @AuditAction, N'proveedores',
                @AuditDetail, N'info', @PartyId
            );
        END;

        IF @OwnTransaction = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT PartyId AS id, Name AS name, Contact AS contact, Phone AS phone,
           Email AS email, Address AS address, SupplierCategory AS category,
           ProductsServices AS productsServices, Ruc AS ruc, PaymentTerms AS paymentTerms,
           Observations AS observations, SupplierStatus AS status,
           CreatedAt AS createdAt, UpdatedAt AS updatedAt, NextReviewDate AS nextReviewDate,
           PartyType AS type
    FROM dbo.Parties
    WHERE PartyId = @PartyId AND PartyType = N'proveedor';
END;
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    IF IS_ROLEMEMBER(N'db_datareader', N'raquel_erp_app') = 1
        ALTER ROLE db_datareader DROP MEMBER [raquel_erp_app];
    IF IS_ROLEMEMBER(N'db_datawriter', N'raquel_erp_app') = 1
        ALTER ROLE db_datawriter DROP MEMBER [raquel_erp_app];
    REVOKE SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo FROM [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.ErpState TO [raquel_erp_app];
    GRANT UPDATE ON OBJECT::dbo.ErpState TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.Parties TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_SaveErpState TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpsertSupplier TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 10/25: 13_autenticacion_y_sesiones.sql */
/* 13 - Credenciales, bloqueo de intentos y sesiones revocables para la API. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50400, 'Falta dbo.AppUsers; ejecuta primero los scripts base y 08_semilla.sql.', 1;
IF OBJECT_ID(N'dbo.AppUserAreas', N'U') IS NULL
    THROW 50405, 'Falta dbo.AppUserAreas; ejecuta primero los scripts base.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50406, 'Falta dbo.AuditEvents; ejecuta primero los scripts base.', 1;
GO

IF COL_LENGTH(N'dbo.AppUsers', N'PasswordHash') IS NULL
    ALTER TABLE dbo.AppUsers ADD PasswordHash NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.AppUsers', N'FailedLoginCount') IS NULL
    ALTER TABLE dbo.AppUsers ADD FailedLoginCount INT NOT NULL
        CONSTRAINT DF_AppUsers_FailedLoginCount DEFAULT (0) WITH VALUES;
IF COL_LENGTH(N'dbo.AppUsers', N'LockedUntil') IS NULL
    ALTER TABLE dbo.AppUsers ADD LockedUntil DATETIME2(3) NULL;
IF COL_LENGTH(N'dbo.AppUsers', N'MustChangePassword') IS NULL
    ALTER TABLE dbo.AppUsers ADD MustChangePassword BIT NOT NULL
        CONSTRAINT DF_AppUsers_MustChangePassword DEFAULT (1) WITH VALUES;
GO

IF OBJECT_ID(N'dbo.AppUserSessions', N'U') IS NULL
CREATE TABLE dbo.AppUserSessions
(
    SessionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AppUserSessions PRIMARY KEY,
    AppUserId NVARCHAR(100) NOT NULL,
    CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AppUserSessions_CreatedAt DEFAULT (SYSUTCDATETIME()),
    ExpiresAt DATETIME2(3) NOT NULL,
    RevokedAt DATETIME2(3) NULL,
    CONSTRAINT FK_AppUserSessions_AppUsers FOREIGN KEY (AppUserId)
        REFERENCES dbo.AppUsers(AppUserId)
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetAppUserForLogin
    @Email NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.AppUserId, u.Name, u.Email, u.Hierarchy, u.IsActive,
           u.PasswordHash, u.FailedLoginCount, u.LockedUntil, u.MustChangePassword,
           (SELECT a.Area AS area
            FROM dbo.AppUserAreas AS a
            WHERE a.AppUserId = u.AppUserId
            FOR JSON PATH) AS AreasJson
    FROM dbo.AppUsers AS u
    WHERE u.Email = @Email;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RecordFailedAppLogin
    @Email NVARCHAR(320)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @UserId NVARCHAR(100);
    DECLARE @UserName NVARCHAR(200);
    BEGIN TRANSACTION;
    SELECT @UserId = AppUserId, @UserName = Name
    FROM dbo.AppUsers WITH (UPDLOCK, ROWLOCK)
    WHERE Email = @Email AND IsActive = 1;

    IF @UserId IS NOT NULL
    BEGIN
        UPDATE dbo.AppUsers
        SET FailedLoginCount = CASE WHEN FailedLoginCount >= 4 THEN 0 ELSE FailedLoginCount + 1 END,
            LockedUntil = CASE WHEN FailedLoginCount >= 4
                THEN DATEADD(MINUTE, 15, SYSUTCDATETIME()) ELSE LockedUntil END
        WHERE AppUserId = @UserId;

        INSERT INTO dbo.AuditEvents (
            AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
        )
        VALUES (
            CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            @UserName, @UserId, N'acceso denegado', N'usuarios', N'Intento de autenticación fallido.', N'warn'
        );
    END;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ResetFailedAppLogin
    @AppUserId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.AppUsers
    SET FailedLoginCount = 0, LockedUntil = NULL
    WHERE AppUserId = @AppUserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateAppUserSession
    @SessionId UNIQUEIDENTIFIER,
    @AppUserId NVARCHAR(100),
    @ExpiresAt DATETIME2(3)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @AppUserId AND IsActive = 1 AND PasswordHash IS NOT NULL
            AND (LockedUntil IS NULL OR LockedUntil <= SYSUTCDATETIME())
    )
        THROW 50401, 'No se puede crear una sesión para este usuario.', 1;

    INSERT INTO dbo.AppUserSessions (SessionId, AppUserId, ExpiresAt)
    VALUES (@SessionId, @AppUserId, @ExpiresAt);

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    SELECT CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
           Name, AppUserId, N'inicio de sesión', N'usuarios', N'Sesión autenticada.', N'info'
    FROM dbo.AppUsers
    WHERE AppUserId = @AppUserId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetAppUserSession
    @SessionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT u.AppUserId, u.Name, u.Email, u.Hierarchy, u.IsActive, u.MustChangePassword,
           s.ExpiresAt,
           (SELECT a.Area AS area
            FROM dbo.AppUserAreas AS a
            WHERE a.AppUserId = u.AppUserId
            FOR JSON PATH) AS AreasJson
    FROM dbo.AppUserSessions AS s
    JOIN dbo.AppUsers AS u ON u.AppUserId = s.AppUserId
    WHERE s.SessionId = @SessionId
      AND s.RevokedAt IS NULL
      AND s.ExpiresAt > SYSUTCDATETIME()
      AND u.IsActive = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RevokeAppUserSession
    @SessionId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @AppUserId NVARCHAR(100);
    DECLARE @UserName NVARCHAR(200);
    SELECT @AppUserId = u.AppUserId, @UserName = u.Name
    FROM dbo.AppUserSessions AS s
    JOIN dbo.AppUsers AS u ON u.AppUserId = s.AppUserId
    WHERE s.SessionId = @SessionId AND s.RevokedAt IS NULL;

    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE SessionId = @SessionId AND RevokedAt IS NULL;

    IF @AppUserId IS NOT NULL
        INSERT INTO dbo.AuditEvents (
            AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
        )
        VALUES (
            CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            @UserName, @AppUserId, N'cierre de sesión', N'usuarios', N'Sesión revocada.', N'info'
        );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_ChangeAppUserPassword
    @AppUserId NVARCHAR(100),
    @SessionId UNIQUEIDENTIFIER,
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    UPDATE dbo.AppUsers
    SET PasswordHash = @PasswordHash,
        MustChangePassword = 0,
        FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE AppUserId = @AppUserId AND IsActive = 1;
    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50402, 'No se pudo actualizar la contraseña del usuario.', 1;
    END;
    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND SessionId <> @SessionId AND RevokedAt IS NULL;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    SELECT CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
           Name, AppUserId, N'cambio de contraseña', N'usuarios', N'Contraseña actualizada.', N'info'
    FROM dbo.AppUsers
    WHERE AppUserId = @AppUserId;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_BootstrapSuperAdmin
    @Email NVARCHAR(320),
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.AppUsers WITH (UPDLOCK, HOLDLOCK) WHERE PasswordHash IS NOT NULL)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50403, 'La activación inicial ya se completó.', 1;
    END;

    UPDATE dbo.AppUsers
    SET PasswordHash = @PasswordHash,
        MustChangePassword = 1,
        FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE Email = @Email AND Hierarchy = N'superadmin' AND IsActive = 1;
    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50404, 'El correo no corresponde a un superadministrador activo existente.', 1;
    END;
    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    SELECT CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
           Name, AppUserId, N'activación inicial', N'usuarios', N'Credencial temporal activada.', N'critical'
    FROM dbo.AppUsers
    WHERE Email = @Email;
    COMMIT TRANSACTION;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_GetAppUserForLogin TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RecordFailedAppLogin TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ResetFailedAppLogin TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateAppUserSession TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetAppUserSession TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RevokeAppUserSession TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ChangeAppUserPassword TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_BootstrapSuperAdmin TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 11/25: 14_recuperacion_contrasena.sql */
/* 14 - Códigos de recuperación de contraseña de un solo uso. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO

IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50410, 'Falta dbo.AppUsers; ejecuta primero 13_autenticacion_y_sesiones.sql.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50411, 'Falta dbo.AuditEvents; ejecuta primero los scripts base.', 1;
IF OBJECT_ID(N'dbo.AppUserSessions', N'U') IS NULL
    THROW 50413, 'Falta dbo.AppUserSessions; ejecuta primero 13_autenticacion_y_sesiones.sql.', 1;
GO

IF OBJECT_ID(N'dbo.AppPasswordResetCodes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AppPasswordResetCodes
    (
        CodeId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AppPasswordResetCodes PRIMARY KEY,
        AppUserId NVARCHAR(100) NOT NULL,
        CodeHash CHAR(64) NOT NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_AppPasswordResetCodes_CreatedAt DEFAULT (SYSUTCDATETIME()),
        ExpiresAt DATETIME2(3) NOT NULL,
        FailedAttempts TINYINT NOT NULL CONSTRAINT DF_AppPasswordResetCodes_FailedAttempts DEFAULT (0),
        UsedAt DATETIME2(3) NULL,
        CONSTRAINT FK_AppPasswordResetCodes_AppUsers FOREIGN KEY (AppUserId)
            REFERENCES dbo.AppUsers(AppUserId)
    );
    CREATE INDEX IX_AppPasswordResetCodes_AppUserId_CreatedAt
        ON dbo.AppPasswordResetCodes (AppUserId, CreatedAt DESC)
        INCLUDE (ExpiresAt, FailedAttempts, UsedAt);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateAppPasswordReset
    @Email NVARCHAR(320),
    @CodeHash CHAR(64),
    @ExpiresAt DATETIME2(3)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @AppUserId NVARCHAR(100);
    DECLARE @UserEmail NVARCHAR(320);

    BEGIN TRANSACTION;
    SELECT @AppUserId = AppUserId, @UserEmail = Email
    FROM dbo.AppUsers WITH (UPDLOCK, ROWLOCK)
    WHERE Email = @Email AND IsActive = 1 AND PasswordHash IS NOT NULL;

    IF @AppUserId IS NOT NULL
    BEGIN
        UPDATE dbo.AppPasswordResetCodes
        SET UsedAt = SYSUTCDATETIME()
        WHERE AppUserId = @AppUserId AND UsedAt IS NULL;

        INSERT INTO dbo.AppPasswordResetCodes (CodeId, AppUserId, CodeHash, ExpiresAt)
        VALUES (NEWID(), @AppUserId, @CodeHash, @ExpiresAt);
    END;
    COMMIT TRANSACTION;

    IF @AppUserId IS NOT NULL
        SELECT @UserEmail AS Email;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CompleteAppPasswordReset
    @Email NVARCHAR(320),
    @CodeHash CHAR(64),
    @PasswordHash NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @CodeId UNIQUEIDENTIFIER;
    DECLARE @AppUserId NVARCHAR(100);
    DECLARE @StoredHash CHAR(64);
    DECLARE @UserName NVARCHAR(200);

    BEGIN TRANSACTION;
    SELECT TOP (1)
        @CodeId = c.CodeId,
        @AppUserId = c.AppUserId,
        @StoredHash = c.CodeHash,
        @UserName = u.Name
    FROM dbo.AppPasswordResetCodes AS c WITH (UPDLOCK, ROWLOCK)
    JOIN dbo.AppUsers AS u ON u.AppUserId = c.AppUserId
    WHERE u.Email = @Email
      AND u.IsActive = 1
      AND c.UsedAt IS NULL
      AND c.ExpiresAt > SYSUTCDATETIME()
      AND c.FailedAttempts < 5
    ORDER BY c.CreatedAt DESC;

    IF @CodeId IS NULL
    BEGIN
        COMMIT TRANSACTION;
        SELECT CAST(0 AS BIT) AS Changed;
        RETURN;
    END;

    IF @StoredHash <> @CodeHash
    BEGIN
        UPDATE dbo.AppPasswordResetCodes
        SET FailedAttempts = FailedAttempts + 1
        WHERE CodeId = @CodeId;
        COMMIT TRANSACTION;
        SELECT CAST(0 AS BIT) AS Changed;
        RETURN;
    END;

    UPDATE dbo.AppUsers
    SET PasswordHash = @PasswordHash,
        MustChangePassword = 0,
        FailedLoginCount = 0,
        LockedUntil = NULL
    WHERE AppUserId = @AppUserId AND IsActive = 1;

    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50412, 'No se pudo actualizar la contraseña del usuario.', 1;
    END;

    UPDATE dbo.AppPasswordResetCodes
    SET UsedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND UsedAt IS NULL;

    UPDATE dbo.AppUserSessions
    SET RevokedAt = SYSUTCDATETIME()
    WHERE AppUserId = @AppUserId AND RevokedAt IS NULL;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity
    )
    VALUES (
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        @UserName, @AppUserId, N'recuperación de contraseña', N'usuarios',
        N'Contraseña restablecida mediante código de correo.', N'warn'
    );

    COMMIT TRANSACTION;
    SELECT CAST(1 AS BIT) AS Changed;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateAppPasswordReset TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CompleteAppPasswordReset TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 12/25: 15_expedientes_proyectos.sql */
/* 15 - Estados independientes y escrituras transaccionales para proyectos. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO

IF OBJECT_ID(N'dbo.Projects', N'U') IS NULL
    THROW 50420, 'Falta dbo.Projects; ejecuta primero 04_produccion_proyectos.sql.', 1;
IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50421, 'Falta dbo.AppUsers; ejecuta primero los scripts de gobierno.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50422, 'Falta dbo.AuditEvents; ejecuta primero los scripts de gobierno.', 1;
GO

IF COL_LENGTH(N'dbo.Projects', N'AuthorizationStatus') IS NULL
    ALTER TABLE dbo.Projects ADD AuthorizationStatus NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.Projects', N'OperationalStage') IS NULL
    ALTER TABLE dbo.Projects ADD OperationalStage NVARCHAR(30) NULL;
IF COL_LENGTH(N'dbo.Projects', N'CollectionStatus') IS NULL
    ALTER TABLE dbo.Projects ADD CollectionStatus NVARCHAR(30) NULL;
GO

UPDATE dbo.Projects
SET AuthorizationStatus = COALESCE(AuthorizationStatus, N'no_verificado'),
    OperationalStage = COALESCE(OperationalStage, N'no_verificado'),
    CollectionStatus = COALESCE(CollectionStatus, N'no_verificado')
WHERE AuthorizationStatus IS NULL OR OperationalStage IS NULL OR CollectionStatus IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Projects_AuthorizationStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT CK_Projects_AuthorizationStatus
        CHECK (AuthorizationStatus IN (N'pendiente', N'autorizada', N'rechazada', N'no_verificado'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Projects_OperationalStage')
    ALTER TABLE dbo.Projects ADD CONSTRAINT CK_Projects_OperationalStage
        CHECK (OperationalStage IN (N'medicion', N'fabricacion', N'instalacion', N'entregado', N'no_verificado'));
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_Projects_CollectionStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT CK_Projects_CollectionStatus
        CHECK (CollectionStatus IN (N'pendiente', N'anticipo_pendiente', N'parcial', N'pagado', N'vencido', N'no_verificado'));
GO

ALTER TABLE dbo.Projects ALTER COLUMN AuthorizationStatus NVARCHAR(30) NOT NULL;
ALTER TABLE dbo.Projects ALTER COLUMN OperationalStage NVARCHAR(30) NOT NULL;
ALTER TABLE dbo.Projects ALTER COLUMN CollectionStatus NVARCHAR(30) NOT NULL;
ALTER TABLE dbo.Projects ALTER COLUMN Owner NVARCHAR(240) NOT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Projects') AND name = N'DF_Projects_AuthorizationStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT DF_Projects_AuthorizationStatus DEFAULT (N'no_verificado') FOR AuthorizationStatus;
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Projects') AND name = N'DF_Projects_OperationalStage')
    ALTER TABLE dbo.Projects ADD CONSTRAINT DF_Projects_OperationalStage DEFAULT (N'no_verificado') FOR OperationalStage;
IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Projects') AND name = N'DF_Projects_CollectionStatus')
    ALTER TABLE dbo.Projects ADD CONSTRAINT DF_Projects_CollectionStatus DEFAULT (N'no_verificado') FOR CollectionStatus;
GO

IF OBJECT_ID(N'dbo.ProjectEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ProjectEvents
    (
        ProjectEventId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_ProjectEvents PRIMARY KEY,
        ProjectId NVARCHAR(100) NOT NULL,
        MutationId UNIQUEIDENTIFIER NOT NULL,
        AppUserId NVARCHAR(100) NULL,
        ActorName NVARCHAR(240) NOT NULL,
        EventType NVARCHAR(40) NOT NULL,
        Detail NVARCHAR(1000) NOT NULL,
        OccurredAt DATETIME2(3) NOT NULL CONSTRAINT DF_ProjectEvents_OccurredAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_ProjectEvents_Projects FOREIGN KEY (ProjectId) REFERENCES dbo.Projects(ProjectId),
        CONSTRAINT FK_ProjectEvents_AppUsers FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT UQ_ProjectEvents_MutationId UNIQUE (MutationId)
    );
END;
GO

IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.ProjectEvents')
          AND name = N'IX_ProjectEvents_ProjectId_OccurredAt'
)
        CREATE INDEX IX_ProjectEvents_ProjectId_OccurredAt
            ON dbo.ProjectEvents(ProjectId, OccurredAt DESC);
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateProject
    @ProjectId NVARCHAR(100),
    @Code NVARCHAR(80),
    @Name NVARCHAR(240),
    @Client NVARCHAR(240),
    @Amount DECIMAL(19,4),
    @Budget DECIMAL(19,4),
    @Owner NVARCHAR(240),
    @AppUserId NVARCHAR(100),
    @ActorName NVARCHAR(240),
    @MutationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @ExistingProjectId NVARCHAR(100);

    BEGIN TRANSACTION;
    SELECT @ExistingProjectId = ProjectId
    FROM dbo.ProjectEvents WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingProjectId IS NULL
    BEGIN
        INSERT INTO dbo.Projects (
            ProjectId, Code, Name, Client, Amount, Budget, Progress, ProjectState, Owner,
            AuthorizationStatus, OperationalStage, CollectionStatus
        )
        VALUES (
            @ProjectId, @Code, @Name, @Client, @Amount, @Budget, 0, N'Pendiente', @Owner,
            N'pendiente', N'medicion', N'pendiente'
        );

        INSERT INTO dbo.ProjectEvents (
            ProjectEventId, ProjectId, MutationId, AppUserId, ActorName, EventType, Detail
        )
        VALUES (
            NEWID(), @ProjectId, @MutationId, @AppUserId, @ActorName, N'creado', N'Expediente creado.'
        );

        INSERT INTO dbo.AuditEvents (
            AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
        )
        SELECT
            CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
            LEFT(u.Name, 200), u.AppUserId, N'crear proyecto', N'proyectos',
            CONCAT(N'Proyecto ', @Code, N' creado.'), N'info', @ProjectId
        FROM dbo.AppUsers AS u
        WHERE u.AppUserId = @AppUserId AND u.IsActive = 1;

        SET @ExistingProjectId = @ProjectId;
    END;

    SELECT ProjectId AS id, Code AS code, Name AS name, Client AS client, Amount AS amount,
           Budget AS budget, Progress AS progress, ProjectState AS state, Owner AS owner,
           AuthorizationStatus AS authorizationStatus, OperationalStage AS operationalStage,
           CollectionStatus AS collectionStatus
    FROM dbo.Projects
    WHERE ProjectId = @ExistingProjectId;
    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_UpdateProjectWorkflow
    @ProjectId NVARCHAR(100),
    @AuthorizationStatus NVARCHAR(30),
    @OperationalStage NVARCHAR(30),
    @CollectionStatus NVARCHAR(30),
    @Detail NVARCHAR(1000),
    @AppUserId NVARCHAR(100),
    @ActorName NVARCHAR(240),
    @MutationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.ProjectEvents WITH (UPDLOCK, HOLDLOCK) WHERE MutationId = @MutationId)
    BEGIN
        SELECT p.ProjectId AS id, p.Code AS code, p.Name AS name, p.Client AS client,
               p.Amount AS amount, p.Budget AS budget, p.Progress AS progress, p.ProjectState AS state,
               p.Owner AS owner, p.AuthorizationStatus AS authorizationStatus,
               p.OperationalStage AS operationalStage, p.CollectionStatus AS collectionStatus
        FROM dbo.Projects AS p
        JOIN dbo.ProjectEvents AS e ON e.ProjectId = p.ProjectId
        WHERE e.MutationId = @MutationId;
        COMMIT TRANSACTION;
        RETURN;
    END;

    UPDATE dbo.Projects
    SET AuthorizationStatus = @AuthorizationStatus,
        OperationalStage = @OperationalStage,
        CollectionStatus = @CollectionStatus
    WHERE ProjectId = @ProjectId;

    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50423, 'No se encontró el proyecto solicitado.', 1;
    END;

    INSERT INTO dbo.ProjectEvents (
        ProjectEventId, ProjectId, MutationId, AppUserId, ActorName, EventType, Detail
    )
    VALUES (
        NEWID(), @ProjectId, @MutationId, @AppUserId, @ActorName, N'estado actualizado', @Detail
    );

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(u.Name, 200), u.AppUserId, N'actualizar estados de proyecto', N'proyectos',
        @Detail, N'info', @ProjectId
    FROM dbo.AppUsers AS u
    WHERE u.AppUserId = @AppUserId AND u.IsActive = 1;

    SELECT ProjectId AS id, Code AS code, Name AS name, Client AS client, Amount AS amount,
           Budget AS budget, Progress AS progress, ProjectState AS state, Owner AS owner,
           AuthorizationStatus AS authorizationStatus, OperationalStage AS operationalStage,
           CollectionStatus AS collectionStatus
    FROM dbo.Projects
    WHERE ProjectId = @ProjectId;
    COMMIT TRANSACTION;
END;
GO

IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateProject TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpdateProjectWorkflow TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.Projects TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.ProjectEvents TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 13/25: 16_talento_humano_base.sql */
/* 16 - Módulo integral de Talento Humano y Bienestar Laboral para Raquel_Schema_Check_20261025_99ef80cc */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Employees', N'U') IS NULL
    THROW 50430, 'Falta dbo.Employees; ejecuta primero 02_gobierno_y_maestros.sql.', 1;
IF OBJECT_ID(N'dbo.AppUsers', N'U') IS NULL
    THROW 50431, 'Falta dbo.AppUsers; ejecuta primero los scripts de gobierno.', 1;
IF OBJECT_ID(N'dbo.AuditEvents', N'U') IS NULL
    THROW 50432, 'Falta dbo.AuditEvents; ejecuta primero los scripts de gobierno.', 1;
IF OBJECT_ID(N'dbo.AppUserAreas', N'U') IS NULL
    THROW 50431, 'Falta dbo.AppUserAreas; ejecuta primero los scripts de gobierno.', 1;
GO

/* =========================================================
   1. AMPLIACIÓN DE EMPLEADOS Y CONTROL DE BAJAS LABORALES
   ========================================================= */
IF COL_LENGTH(N'dbo.Employees', N'EmploymentStatus') IS NULL
BEGIN
    ALTER TABLE dbo.Employees
        ADD EmploymentStatus NVARCHAR(20) NOT NULL CONSTRAINT DF_Employees_EmploymentStatus DEFAULT (N'activo');
END;
GO

IF COL_LENGTH(N'dbo.Employees', N'DismissalDate') IS NULL
    ALTER TABLE dbo.Employees ADD DismissalDate DATE NULL;
IF COL_LENGTH(N'dbo.Employees', N'DismissalReason') IS NULL
    ALTER TABLE dbo.Employees ADD DismissalReason NVARCHAR(500) NULL;
IF COL_LENGTH(N'dbo.Employees', N'DismissalDocRef') IS NULL
    ALTER TABLE dbo.Employees ADD DismissalDocRef NVARCHAR(300) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE parent_object_id = OBJECT_ID(N'dbo.Employees') AND name = N'CK_Employees_EmploymentStatus')
    ALTER TABLE dbo.Employees ADD CONSTRAINT CK_Employees_EmploymentStatus
        CHECK (EmploymentStatus IN (N'activo', N'licencia', N'baja'));
GO

/* =========================================================
   2. HISTORIAL LABORAL Y SALARIAL
   ========================================================= */
IF OBJECT_ID(N'dbo.EmployeeJobHistory', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.EmployeeJobHistory
    (
        EmployeeJobHistoryId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_EmployeeJobHistory PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        Position NVARCHAR(200) NOT NULL,
        Area NVARCHAR(120) NOT NULL,
        Salary DECIMAL(19,4) NOT NULL,
        ValidFrom DATE NULL,
        ValidTo DATE NULL,
        ChangedByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIME2(3) NOT NULL CONSTRAINT DF_EmployeeJobHistory_CreatedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT FK_EmployeeJobHistory_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_EmployeeJobHistory_AppUsers FOREIGN KEY (ChangedByAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT CK_EmployeeJobHistory_Dates CHECK (ValidFrom IS NULL OR ValidTo IS NULL OR ValidTo >= ValidFrom)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.EmployeeJobHistory') AND name = N'IX_EmployeeJobHistory_Employee_ValidFrom')
    CREATE INDEX IX_EmployeeJobHistory_Employee_ValidFrom
        ON dbo.EmployeeJobHistory(EmployeeId, ValidFrom DESC);
GO

-- Carga de demostracion opcional; no inventar historial ni contratos al instalar estructura.
IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1
INSERT INTO dbo.EmployeeJobHistory (
    EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
)
SELECT NEWID(), employee.EmployeeId, employee.Position, employee.Area, employee.Salary,
       ISNULL(employee.HireDate, '2025-01-01'), NULL
FROM dbo.Employees AS employee
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.EmployeeJobHistory AS history
    WHERE history.EmployeeId = employee.EmployeeId
);
GO

/* =========================================================
   3. DIRECTORIO SEGURO Y MUTACIONES IDEMPOTENTES
   ========================================================= */
CREATE OR ALTER VIEW dbo.vw_HrEmployeeDirectory
AS
    SELECT employee.EmployeeId, employee.Name, employee.Position, employee.Area,
           employee.HireDate, employee.EmploymentStatus, employee.AppUserId,
           employee.DismissalDate, employee.DismissalReason,
           CASE WHEN employee.AppUserId IS NULL THEN NULL ELSE appUser.IsActive END AS AccountActive
    FROM dbo.Employees AS employee
    LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = employee.AppUserId;
GO

IF OBJECT_ID(N'dbo.HrEmployeeCreations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrEmployeeCreations
    (
        MutationId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrEmployeeCreations PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        CreatedByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrEmployeeCreations_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrEmployeeCreations_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrEmployeeCreations_Users FOREIGN KEY (CreatedByAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL
    );
END;
GO

/* =========================================================
   4. CONTRATOS Y CONDICIONES PACTADAS
   ========================================================= */
IF OBJECT_ID(N'dbo.HrContracts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrContracts
    (
        ContractId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrContracts PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        ContractNumber NVARCHAR(60) NOT NULL,
        ContractType NVARCHAR(40) NOT NULL CONSTRAINT DF_HrContracts_Type DEFAULT (N'indefinido'),
        Position NVARCHAR(200) NOT NULL,
        WorkSchedule NVARCHAR(100) NOT NULL CONSTRAINT DF_HrContracts_Schedule DEFAULT (N'Diurna 48h (Lun-Sáb)'),
        StartDate DATE NOT NULL,
        EndDate DATE NULL,
        AgreedTerms NVARCHAR(2000) NOT NULL,
        DocumentName NVARCHAR(200) NULL,
        DocumentRef NVARCHAR(500) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrContracts_Status DEFAULT (N'registrado'),
        ReviewedByAppUserId NVARCHAR(100) NULL,
        ReviewedAt DATETIMEOFFSET(3) NULL,
        Revision ROWVERSION NOT NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrContracts_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        UpdatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrContracts_UpdatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrContracts_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrContracts_ReviewedBy FOREIGN KEY (ReviewedByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT CK_HrContracts_Status CHECK (Status IN (N'borrador', N'en_revision', N'registrado', N'finalizado')),
        CONSTRAINT CK_HrContracts_Type CHECK (ContractType IN (N'indefinido', N'determinado', N'obra_servicio', N'periodo_prueba')),
        CONSTRAINT CK_HrContracts_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrContracts') AND name = N'IX_HrContracts_Employee_StartDate')
    CREATE INDEX IX_HrContracts_Employee_StartDate ON dbo.HrContracts(EmployeeId, StartDate DESC);
GO

/* Semilla de contratos iniciales para el personal existente si no los tienen */
-- Carga de demostracion opcional; no inventar historial ni contratos al instalar estructura.
IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1
INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, EndDate, AgreedTerms, Status)
SELECT 
    NEWID(), e.EmployeeId, 
    CONCAT(N'CT-RAQ-', YEAR(ISNULL(e.HireDate, '2025-01-01')), N'-', RIGHT(CONCAT('00', ROW_NUMBER() OVER (ORDER BY e.EmployeeId)), 3)),
    N'indefinido', e.Position, N'Diurna 48h (Lun-Sáb: 8am-5pm)', ISNULL(e.HireDate, '2025-01-01'), NULL,
    CONCAT(N'Contrato laboral por tiempo indeterminado según Código del Trabajo (Ley 185). Jornada diurna de 48 horas semanales. Área: ', e.Area, N'. Con derecho a descanso semanal remunerado y EPP especializado.'),
    N'registrado'
FROM dbo.Employees AS e
WHERE NOT EXISTS (SELECT 1 FROM dbo.HrContracts c WHERE c.EmployeeId = e.EmployeeId);
GO

/* =========================================================
   5. SOLICITUDES PRIVADAS E INCIDENCIAS DE PERSONAL
   ========================================================= */
IF OBJECT_ID(N'dbo.HrRequests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrRequests
    (
        HrRequestId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrRequests PRIMARY KEY,
        MutationId UNIQUEIDENTIFIER NOT NULL,
        EmployeeId NVARCHAR(100) NOT NULL,
        Category NVARCHAR(30) NOT NULL,
        StartDate DATE NULL,
        EndDate DATE NULL,
        Details NVARCHAR(1000) NOT NULL,
        Status NVARCHAR(20) NOT NULL CONSTRAINT DF_HrRequests_Status DEFAULT (N'enviada'),
        Resolution NVARCHAR(1000) NULL,
        AssignedToAppUserId NVARCHAR(100) NULL,
        DecidedByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrRequests_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        UpdatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrRequests_UpdatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        DecidedAt DATETIMEOFFSET(3) NULL,
        Revision ROWVERSION NOT NULL,
        CONSTRAINT FK_HrRequests_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrRequests_AssignedUser FOREIGN KEY (AssignedToAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT FK_HrRequests_DecidedUser FOREIGN KEY (DecidedByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT UQ_HrRequests_MutationId UNIQUE (MutationId),
        CONSTRAINT CK_HrRequests_Category CHECK (Category IN (
            N'vacaciones', N'permiso', N'correccion_datos', N'consulta_laboral', N'seguridad', N'trato_recibido'
        )),
        CONSTRAINT CK_HrRequests_Status CHECK (Status IN (
            N'enviada', N'en_revision', N'aprobada', N'rechazada', N'cancelada'
        )),
        CONSTRAINT CK_HrRequests_Dates CHECK (StartDate IS NULL OR EndDate IS NULL OR EndDate >= StartDate),
        CONSTRAINT CK_HrRequests_Decision CHECK (
            (Status IN (N'aprobada', N'rechazada') AND DecidedByAppUserId IS NOT NULL AND DecidedAt IS NOT NULL)
            OR Status NOT IN (N'aprobada', N'rechazada')
        )
    );
END;
GO

IF OBJECT_ID(N'dbo.HrRequestEvents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrRequestEvents
    (
        HrRequestEventId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrRequestEvents PRIMARY KEY,
        HrRequestId UNIQUEIDENTIFIER NOT NULL,
        AppUserId NVARCHAR(100) NULL,
        ActorName NVARCHAR(240) NOT NULL,
        EventType NVARCHAR(30) NOT NULL,
        Detail NVARCHAR(1000) NULL,
        OccurredAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrRequestEvents_OccurredAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrRequestEvents_Requests FOREIGN KEY (HrRequestId) REFERENCES dbo.HrRequests(HrRequestId),
        CONSTRAINT FK_HrRequestEvents_Users FOREIGN KEY (AppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrRequests') AND name = N'IX_HrRequests_Employee_CreatedAt')
    CREATE INDEX IX_HrRequests_Employee_CreatedAt ON dbo.HrRequests(EmployeeId, CreatedAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrRequests') AND name = N'IX_HrRequests_Status_CreatedAt')
    CREATE INDEX IX_HrRequests_Status_CreatedAt ON dbo.HrRequests(Status, CreatedAt DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.HrRequestEvents') AND name = N'IX_HrRequestEvents_Request_OccurredAt')
    CREATE INDEX IX_HrRequestEvents_Request_OccurredAt ON dbo.HrRequestEvents(HrRequestId, OccurredAt DESC);
GO

/* =========================================================
   6. ASISTENCIA Y JORNADA LABORAL
   ========================================================= */
IF OBJECT_ID(N'dbo.HrAttendanceRecords', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrAttendanceRecords
    (
        AttendanceId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrAttendanceRecords PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        RecordDate DATE NOT NULL,
        ShiftName NVARCHAR(60) NOT NULL CONSTRAINT DF_HrAttendance_Shift DEFAULT (N'Taller Diurno (8h)'),
        ScheduledIn TIME(0) NOT NULL CONSTRAINT DF_HrAttendance_SchedIn DEFAULT ('08:00:00'),
        ScheduledOut TIME(0) NOT NULL CONSTRAINT DF_HrAttendance_SchedOut DEFAULT ('17:00:00'),
        ActualIn TIME(0) NULL,
        ActualOut TIME(0) NULL,
        OriginalIn TIME(0) NULL,
        OriginalOut TIME(0) NULL,
        HoursLogged DECIMAL(5,2) NOT NULL CONSTRAINT DF_HrAttendance_Logged DEFAULT (0),
        HoursReviewed DECIMAL(5,2) NOT NULL CONSTRAINT DF_HrAttendance_Reviewed DEFAULT (0),
        HoursAuthorized DECIMAL(5,2) NOT NULL CONSTRAINT DF_HrAttendance_Authorized DEFAULT (0),
        IncidentType NVARCHAR(40) NOT NULL CONSTRAINT DF_HrAttendance_Incident DEFAULT (N'ninguna'),
        IncidentNotes NVARCHAR(500) NULL,
        CorrectionReason NVARCHAR(500) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrAttendance_Status DEFAULT (N'registrado'),
        AuthorizedByAppUserId NVARCHAR(100) NULL,
        Revision ROWVERSION NOT NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrAttendance_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrAttendance_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrAttendance_Authorizer FOREIGN KEY (AuthorizedByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT UQ_HrAttendance_Employee_Date UNIQUE (EmployeeId, RecordDate),
        CONSTRAINT CK_HrAttendance_Incident CHECK (IncidentType IN (
            N'ninguna', N'tardanza', N'falta_justificada', N'falta_injustificada', N'salida_anticipada', N'permiso_oficial'
        )),
        CONSTRAINT CK_HrAttendance_Status CHECK (Status IN (N'registrado', N'en_revision', N'autorizado_nomina'))
    );
END;
GO

/* Semilla de asistencia reciente para comprobación */
IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1 AND NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE RecordDate = CONVERT(DATE, SYSUTCDATETIME()))
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, IncidentType, Status)
    SELECT 
        NEWID(), e.EmployeeId, CONVERT(DATE, SYSUTCDATETIME()), N'Taller Diurno (8h)',
        '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.0, 8.0, 8.0, N'ninguna', N'autorizado_nomina'
    FROM dbo.Employees e
    WHERE e.EmploymentStatus = N'activo';
END;
GO

/* =========================================================
   7. SEGURIDAD Y BIENESTAR: EQUIPOS DE PROTECCIÓN (EPP)
   ========================================================= */
IF OBJECT_ID(N'dbo.HrSafetyEquipment', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrSafetyEquipment
    (
        EquipmentId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrSafetyEquipment PRIMARY KEY,
        Name NVARCHAR(200) NOT NULL,
        Category NVARCHAR(50) NOT NULL,
        StandardNorm NVARCHAR(120) NOT NULL,
        StockQty INT NOT NULL CONSTRAINT DF_HrEquipment_Stock DEFAULT (10),
        ReplacementPeriodDays INT NOT NULL CONSTRAINT DF_HrEquipment_Period DEFAULT (90),
        IsActive BIT NOT NULL CONSTRAINT DF_HrEquipment_Active DEFAULT (1),
        CONSTRAINT CK_HrSafetyEquipment_Category CHECK (Category IN (N'vidrio', N'aluminio', N'altura', N'electricidad', N'general'))
    );
END;
GO

/* Semilla de EPP especializado para corte de vidrio, aluminio e instalaciones */
IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1 AND NOT EXISTS (SELECT 1 FROM dbo.HrSafetyEquipment)
BEGIN
    INSERT INTO dbo.HrSafetyEquipment (EquipmentId, Name, Category, StandardNorm, StockQty, ReplacementPeriodDays)
    VALUES
        (NEWID(), N'Guantes anticorte nivel 5 con recubrimiento de nitrilo espumado (Manipulación de vidrio y perfiles)', N'vidrio', N'EN 388:2016 (4X43F) / Ley 618 Art. 110', 25, 60),
        (NEWID(), N'Mangas protectoras anticorte nivel 5 para antebrazos (Corte de cristales)', N'vidrio', N'EN 388 / Ley 618 Art. 110', 18, 90),
        (NEWID(), N'Gafas panorámicas de seguridad con ventilación indirecta anti-impacto', N'aluminio', N'ANSI Z87.1+ / Ley 618 Art. 108', 30, 120),
        (NEWID(), N'Calzado de seguridad con puntera dieléctrica y plantilla anti-perforación', N'general', N'ASTM F2413 / Ley 618 Art. 112', 15, 180),
        (NEWID(), N'Ventosas dobles de succión con indicador de vacío para cristal templado (100 kg)', N'vidrio', N'Certificación CE / Inspección mensual', 8, 365),
        (NEWID(), N'Arnés de cuerpo entero de 4 puntos con línea de vida y absorbedor de impacto', N'altura', N'ANSI Z359.11 / Ley 618 Art. 165', 10, 180),
        (NEWID(), N'Protector auditivo tipo copa de alta atenuación (Tronzadora de aluminio)', N'aluminio', N'ANSI S3.19 / Ley 618 Art. 109', 20, 180);
END;
GO

IF OBJECT_ID(N'dbo.HrEquipmentDeliveries', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrEquipmentDeliveries
    (
        DeliveryId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrEquipmentDeliveries PRIMARY KEY,
        EmployeeId NVARCHAR(100) NOT NULL,
        EquipmentId UNIQUEIDENTIFIER NOT NULL,
        DeliveryDate DATE NOT NULL,
        DeliveryType NVARCHAR(40) NOT NULL CONSTRAINT DF_HrDeliveries_Type DEFAULT (N'dotacion_inicial'),
        NextReplacementDate DATE NULL,
        Notes NVARCHAR(500) NULL,
        DeliveredByAppUserId NVARCHAR(100) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrDeliveries_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrDeliveries_Employees FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId),
        CONSTRAINT FK_HrDeliveries_Equipment FOREIGN KEY (EquipmentId) REFERENCES dbo.HrSafetyEquipment(EquipmentId),
        CONSTRAINT FK_HrDeliveries_DeliveredBy FOREIGN KEY (DeliveredByAppUserId) REFERENCES dbo.AppUsers(AppUserId),
        CONSTRAINT CK_HrDeliveries_Type CHECK (DeliveryType IN (N'dotacion_inicial', N'reposicion_desgaste', N'reposicion_dano'))
    );
END;
GO

/* Dotaciones iniciales para supervisores e instaladores */
IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1 AND NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries)
BEGIN
    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes)
    SELECT NEWID(), e.EmployeeId, eq.EquipmentId, '2026-09-01', N'dotacion_inicial', DATEADD(DAY, eq.ReplacementPeriodDays, '2026-09-01'), N'Dotación reglamentaria de seguridad para operaciones en taller y obra.'
    FROM dbo.Employees e
    CROSS JOIN (SELECT TOP 2 EquipmentId, ReplacementPeriodDays FROM dbo.HrSafetyEquipment ORDER BY Category) eq
    WHERE e.Area IN (N'Producción', N'Ventas');
END;
GO

/* =========================================================
   8. SEGURIDAD Y BIENESTAR: CAPACITACIONES
   ========================================================= */
IF OBJECT_ID(N'dbo.HrSafetyTrainings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrSafetyTrainings
    (
        TrainingId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrSafetyTrainings PRIMARY KEY,
        Topic NVARCHAR(250) NOT NULL,
        Instructor NVARCHAR(200) NOT NULL,
        TrainingDate DATE NOT NULL,
        Hours INT NOT NULL,
        LegalRef NVARCHAR(120) NOT NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrTrainings_Status DEFAULT (N'completada'),
        TargetArea NVARCHAR(60) NOT NULL CONSTRAINT DF_HrTrainings_Area DEFAULT (N'Taller y Obras'),
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrTrainings_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT CK_HrSafetyTrainings_Status CHECK (Status IN (N'programada', N'completada', N'cancelada'))
    );
END;
GO

IF OBJECT_ID(N'dbo.HrTrainingAttendees', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrTrainingAttendees
    (
        TrainingId UNIQUEIDENTIFIER NOT NULL,
        EmployeeId NVARCHAR(100) NOT NULL,
        Attended BIT NOT NULL CONSTRAINT DF_HrAttendees_Attended DEFAULT (1),
        CertificateIssued BIT NOT NULL CONSTRAINT DF_HrAttendees_Cert DEFAULT (1),
        CONSTRAINT PK_HrTrainingAttendees PRIMARY KEY (TrainingId, EmployeeId),
        CONSTRAINT FK_HrAttendees_Training FOREIGN KEY (TrainingId) REFERENCES dbo.HrSafetyTrainings(TrainingId) ON DELETE CASCADE,
        CONSTRAINT FK_HrAttendees_Employee FOREIGN KEY (EmployeeId) REFERENCES dbo.Employees(EmployeeId)
    );
END;
GO

IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1 AND NOT EXISTS (SELECT 1 FROM dbo.HrSafetyTrainings)
BEGIN
    DECLARE @T1 UNIQUEIDENTIFIER = NEWID();
    DECLARE @T2 UNIQUEIDENTIFIER = NEWID();
    DECLARE @T3 UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.HrSafetyTrainings (TrainingId, Topic, Instructor, TrainingDate, Hours, LegalRef, Status, TargetArea)
    VALUES
        (@T1, N'Técnicas seguras en manipulación, trasiego y corte de vidrio crudo y templado', N'Ing. Manuel Espinoza (Especialista en Seguridad Industrial)', '2026-08-15', 6, N'Ley 618 Art. 18 / NTON', N'completada', N'Taller de Vidrio'),
        (@T2, N'Seguridad en trabajos en alturas y anclajes en instalación de ventanería y fachadas', N'Téc. Roberto Calero (Certificado OSHA / MITRAB)', '2026-09-20', 8, N'Ley 618 Art. 165', N'completada', N'Instalaciones en Obra'),
        (@T3, N'Operación segura de tronzadoras, ingletadoras y taladros para perfiles de aluminio', N'Ing. Carlos Producción', '2026-10-10', 4, N'Ley 618 Art. 78', N'completada', N'Taller de Aluminio');

    INSERT INTO dbo.HrTrainingAttendees (TrainingId, EmployeeId, Attended, CertificateIssued)
    SELECT @T1, EmployeeId, 1, 1 FROM dbo.Employees WHERE Area IN (N'Producción', N'Ventas');
    INSERT INTO dbo.HrTrainingAttendees (TrainingId, EmployeeId, Attended, CertificateIssued)
    SELECT @T2, EmployeeId, 1, 1 FROM dbo.Employees WHERE Area = N'Producción';
    INSERT INTO dbo.HrTrainingAttendees (TrainingId, EmployeeId, Attended, CertificateIssued)
    SELECT @T3, EmployeeId, 1, 1 FROM dbo.Employees WHERE Area = N'Producción';
END;
GO

/* =========================================================
   9. SEGURIDAD Y BIENESTAR: INCIDENTES Y ACCIONES CORRECTIVAS
   ========================================================= */
IF OBJECT_ID(N'dbo.HrSafetyIncidents', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrSafetyIncidents
    (
        IncidentId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrSafetyIncidents PRIMARY KEY,
        IncidentDate DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrIncidents_Date DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        ReportedByAppUserId NVARCHAR(100) NULL,
        Area NVARCHAR(100) NOT NULL,
        IncidentType NVARCHAR(40) NOT NULL,
        Severity NVARCHAR(20) NOT NULL CONSTRAINT DF_HrIncidents_Sev DEFAULT (N'baja'),
        Description NVARCHAR(1000) NOT NULL,
        ImmediateAction NVARCHAR(1000) NULL,
        PhotoUrl NVARCHAR(500) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrIncidents_Status DEFAULT (N'reportado'),
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrIncidents_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrIncidents_Reporter FOREIGN KEY (ReportedByAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT CK_HrIncidents_Type CHECK (IncidentType IN (N'condicion_insegura', N'acto_inseguro', N'casi_accidente', N'incidente_menor')),
        CONSTRAINT CK_HrIncidents_Severity CHECK (Severity IN (N'baja', N'media', N'alta', N'critica')),
        CONSTRAINT CK_HrIncidents_Status CHECK (Status IN (N'reportado', N'en_investigacion', N'con_accion_correctiva', N'cerrado'))
    );
END;
GO

IF OBJECT_ID(N'dbo.HrCorrectiveActions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrCorrectiveActions
    (
        ActionId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrCorrectiveActions PRIMARY KEY,
        IncidentId UNIQUEIDENTIFIER NULL,
        Description NVARCHAR(1000) NOT NULL,
        ResponsibleAppUserId NVARCHAR(100) NULL,
        ResponsibleName NVARCHAR(200) NOT NULL,
        DueDate DATE NOT NULL,
        Evidence NVARCHAR(1000) NULL,
        Status NVARCHAR(30) NOT NULL CONSTRAINT DF_HrActions_Status DEFAULT (N'abierta'),
        ClosedAt DATETIMEOFFSET(3) NULL,
        CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_HrActions_CreatedAt DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')),
        CONSTRAINT FK_HrActions_Incidents FOREIGN KEY (IncidentId) REFERENCES dbo.HrSafetyIncidents(IncidentId) ON DELETE SET NULL,
        CONSTRAINT FK_HrActions_Responsible FOREIGN KEY (ResponsibleAppUserId) REFERENCES dbo.AppUsers(AppUserId) ON DELETE SET NULL,
        CONSTRAINT CK_HrActions_Status CHECK (Status IN (N'abierta', N'en_proceso', N'implementada', N'verificada_cerrada'))
    );
END;
GO

IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1 AND NOT EXISTS (SELECT 1 FROM dbo.HrSafetyIncidents)
BEGIN
    DECLARE @Inc1 UNIQUEIDENTIFIER = NEWID();
    INSERT INTO dbo.HrSafetyIncidents (IncidentId, Area, IncidentType, Severity, Description, ImmediateAction, Status)
    VALUES (
        @Inc1, N'Taller de Vidrio - Mesa de corte #2', N'condicion_insegura', N'media',
        N'Fieltro protector de mesa de corte desgastado con residuos de esquirlas adheridas que pueden rayar o astillar el cristal durante el desprendimiento.',
        N'Se delimitó la mesa y se programó cambio de cubierta acolchada.',
        N'con_accion_correctiva'
    );

    INSERT INTO dbo.HrCorrectiveActions (ActionId, IncidentId, Description, ResponsibleName, DueDate, Status)
    VALUES (
        NEWID(), @Inc1,
        N'Instalar fieltro sintético nuevo de 5mm en mesa de corte y aspirado de viruta de vidrio al final de cada jornada.',
        N'Carlos Producción', DATEADD(DAY, 7, CONVERT(DATE, SYSUTCDATETIME())), N'en_proceso'
    );
END;
GO

/* =========================================================
   10. MARCO LEGAL Y OBLIGACIONES DE CUMPLIMIENTO (NICARAGUA)
   ========================================================= */
IF OBJECT_ID(N'dbo.HrComplianceObligations', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrComplianceObligations
    (
        ObligationId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrCompliance PRIMARY KEY,
        Topic NVARCHAR(120) NOT NULL,
        LawName NVARCHAR(200) NOT NULL,
        ArticleRef NVARCHAR(100) NOT NULL,
        Summary NVARCHAR(1000) NOT NULL,
        ResponsibilityArea NVARCHAR(80) NOT NULL,
        ComplianceStatus NVARCHAR(40) NOT NULL CONSTRAINT DF_HrCompliance_Status DEFAULT (N'revisado_internamente'),
        LastReviewDate DATE NOT NULL,
        ResponsibleName NVARCHAR(150) NOT NULL,
        Notes NVARCHAR(1000) NULL,
        CONSTRAINT CK_HrCompliance_Status CHECK (ComplianceStatus IN (
            N'pendiente_revision', N'documentacion_incompleta', N'revisado_internamente', N'constancia_registrada'
        ))
    );
END;
GO

IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1 AND NOT EXISTS (SELECT 1 FROM dbo.HrComplianceObligations)
BEGIN
    INSERT INTO dbo.HrComplianceObligations (ObligationId, Topic, LawName, ArticleRef, Summary, ResponsibilityArea, ComplianceStatus, LastReviewDate, ResponsibleName, Notes)
    VALUES
        (NEWID(), N'Jornada Ordinaria y Descanso Semanal', N'Código del Trabajo (Ley 185)', N'Artículos 51, 52, 64',
         N'La jornada ordinaria diurna no excederá de 8 horas diarias ni de 48 semanales. Derecho a un día de descanso continuo remunerado por cada 6 días trabajados.',
         N'Talento humano', N'revisado_internamente', '2026-10-01', N'Raquel López', N'Turnos de taller organizados de 8:00 AM a 5:00 PM con una hora de almuerzo.'),

        (NEWID(), N'Derecho y Cálculo de Vacaciones', N'Código del Trabajo (Ley 185)', N'Artículo 76',
         N'Todo trabajador tiene derecho a 15 días continuos de descanso remunerado por cada 6 meses ininterrumpidos de trabajo (equivalente a 2.5 días acumulados por mes). Las vacaciones se disfrutan, no se compensan en dinero salvo rescisión.',
         N'Talento humano', N'constancia_registrada', '2026-10-01', N'Raquel López', N'Módulo de vacaciones con liquidación y registro de descansos efectivos.'),

        (NEWID(), N'Décimo Tercer Mes (Aguinaldo)', N'Código del Trabajo (Ley 185)', N'Artículos 93 - 99',
         N'Un mes de salario ordinario después de un año de trabajo continuo o la parte proporcional. Se paga en los primeros 10 días de diciembre. Es inembargable y exento de tributos y cargas sociales.',
         N'Contabilidad y nómina', N'revisado_internamente', '2026-10-01', N'María Contadora', N'Provisiones mensuales del 8.33% registradas en la contabilidad.'),

        (NEWID(), N'Comisión Mixta y EPP para Vidrio y Metal', N'Ley General de Higiene y Seguridad del Trabajo (Ley 618)', N'Artículos 32, 108 - 114',
         N'Obligación de constituir Comisión Mixta de Higiene y Seguridad y suministrar EPP certificado gratuito a todo trabajador expuesto a cortes, esquirlas, polvo y alturas.',
         N'Seguridad industrial', N'constancia_registrada', '2026-09-15', N'Carlos Producción', N'EPP entregado con actas firmadas y reposición periódica.'),

        (NEWID(), N'Retención Salarial del IR de Empleados', N'Ley de Concertación Tributaria (Ley 822)', N'Artículo 23',
         N'Retención en la fuente sobre rentas del trabajo conforme a la tarifa progresiva sobre el ingreso neto gravable una vez deducido el aporte laboral del INSS.',
         N'Contabilidad y nómina', N'revisado_internamente', '2026-10-01', N'María Contadora', N'Tablas de retención salarial aplicadas en la nómina.'),

        (NEWID(), N'Aportes a la Seguridad Social (INSS e INATEC)', N'Ley de Seguridad Social y Normativa INATEC', N'Reglamento INSS / Ley INATEC',
         N'Deducción laboral INSS 7.0%, aporte patronal INSS 21.5% o 22.5% según número de colaboradores, y aporte patronal INATEC 2.0% para capacitación.',
         N'Contabilidad y nómina', N'constancia_registrada', '2026-10-01', N'María Contadora', N'Pagos y declaraciones mensuales con comprobante oficial.'),

        (NEWID(), N'Protección y Confidencialidad de Datos', N'Ley de Protección de Datos Personales (Ley 787)', N'Artículos 4, 9, 13',
         N'Los datos laborales y salariales deben tratarse con principio de finalidad, seguridad técnica y reserva estricta. Queda prohibida la divulgación de diagnósticos médicos en tableros comunes.',
         N'Talento humano', N'constancia_registrada', '2026-10-01', N'Raquel López', N'Separación física y digital en base de datos con roles restringidos.');
END;
GO

/* =========================================================
   11. BIBLIOTECA DE DERECHOS Y ORIENTACIÓN ("CONOCE TUS DERECHOS")
   ========================================================= */
IF OBJECT_ID(N'dbo.HrRightsArticles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.HrRightsArticles
    (
        ArticleId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_HrRightsArticles PRIMARY KEY,
        Slug NVARCHAR(100) NOT NULL CONSTRAINT UQ_HrRights_Slug UNIQUE,
        Category NVARCHAR(50) NOT NULL,
        Question NVARCHAR(300) NOT NULL,
        ShortAnswer NVARCHAR(1000) NOT NULL,
        PracticalExample NVARCHAR(1500) NOT NULL,
        LegalSource NVARCHAR(300) NOT NULL,
        ReviewedAt DATE NOT NULL,
        EditorialOwner NVARCHAR(150) NOT NULL,
        OrderIndex INT NOT NULL CONSTRAINT DF_HrRights_Order DEFAULT (0),
        IsPublic BIT NOT NULL CONSTRAINT DF_HrRights_Public DEFAULT (1)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.HrRightsArticles)
BEGIN
    INSERT INTO dbo.HrRightsArticles (ArticleId, Slug, Category, Question, ShortAnswer, PracticalExample, LegalSource, ReviewedAt, EditorialOwner, OrderIndex)
    VALUES
        (NEWID(), N'que-debo-revisar-en-un-contrato', N'contratos',
         N'¿Qué debo revisar en mi contrato de trabajo?',
         N'Tu contrato formaliza la relación laboral y debe detallar con precisión tu puesto específico, horario pactado, lugar donde desempeñarás tus labores, fecha de inicio y salario acordado.',
         N'En Raquel_Schema_Check_20261025_99ef80cc, si fuiste contratado como armador de perfiles de aluminio o instalador en obra, tu contrato debe estipular la jornada diurna máxima de 48 horas semanales y las condiciones de seguridad en taller.',
         N'Código del Trabajo de Nicaragua (Ley 185), Artículos 19 al 24.', '2026-10-01', N'Talento Humano Raquel', 1),

        (NEWID(), N'como-entiendo-mi-comprobante-de-pago', N'pagos',
         N'¿Cómo entiendo mi comprobante de nómina?',
         N'Tu colilla desglosa tus ingresos devengados (salario base, horas extras autorizadas, comisiones) y tus deducciones legales obligatorias (7% de INSS laboral y retención del IR si aplica según escala tributaria).',
         N'Por ejemplo, con un devengado de C$ 12,000, el 7% de INSS laboral equivale a C$ 840 deducidos para tu cobertura de salud y pensión. El salario neto a cobrar se calcula restando estas deducciones legales al devengado total.',
         N'Código del Trabajo (Ley 185) Art. 84; Ley de Concertación Tributaria (Ley 822) Art. 23.', '2026-10-01', N'Contabilidad y Nómina', 2),

        (NEWID(), N'como-solicito-vacaciones', N'vacaciones',
         N'¿Cómo solicito y disfruto mis vacaciones?',
         N'Acumulas 2.5 días hábiles de descanso por cada mes continuo de trabajo (15 días por semestre). Puedes solicitar tu período desde "Mi espacio" con un mínimo de 15 días de anticipación para planificar la cobertura en taller.',
         N'Si cumples un año continuo, habrás acumulado 30 días de vacaciones. Al solicitar 15 días, conservas 15 días disponibles. Las vacaciones deben gozarse efectivamente; la ley prohíbe compensarlas con dinero salvo al finalizar la relación laboral.',
         N'Código del Trabajo de Nicaragua (Ley 185), Artículos 76 al 81.', '2026-10-01', N'Talento Humano Raquel', 3),

        (NEWID(), N'que-hago-si-mis-datos-estan-incorrectos', N'datos',
         N'¿Qué hago si mis datos personales están incorrectos en el expediente?',
         N'Tienes derecho a la rectificación inmediata de tu número de cédula, afiliación INSS, número de cuenta bancaria o dirección domiciliaria mediante una solicitud de corrección en "Mi espacio".',
         N'Si te mudaste de domicilio o renovaste tu cédula, envía la solicitud adjuntando el nuevo número. Talento humano valida la información oficial y actualiza el expediente sin sobrescribir el historial previo.',
         N'Ley de Protección de Datos Personales (Ley 787), Artículo 13.', '2026-10-01', N'Seguridad y Cumplimiento', 4),

        (NEWID(), N'que-proteccion-necesito-para-trabajar-con-vidrio', N'seguridad_vidrio',
         N'¿Qué protección obligatoria necesito para trabajar con vidrio y perfiles?',
         N'Para corte y trasiego de vidrio requieres guantes anticorte nivel 5 certificados, mangas protectoras para antebrazos, gafas de seguridad de impacto y calzado con puntera. Para trabajo en altura es obligatorio arnés de cuerpo entero con línea de vida.',
         N'En Raquel_Schema_Check_20261025_99ef80cc todos los EPP son suministrados por la empresa sin costo alguno para el colaborador. Ante cualquier corte o rasgadura del guante, solicita reposición inmediata sin sanción.',
         N'Ley General de Higiene y Seguridad del Trabajo (Ley 618), Artículos 108 al 114 y 165.', '2026-10-01', N'Seguridad Industrial', 5),

        (NEWID(), N'como-comunico-una-condicion-insegura', N'reportes',
         N'¿Cómo comunico una condición o acto inseguro en el taller u obra?',
         N'Puedes registrar un reporte preventivo desde tu teléfono en "Seguridad y bienestar" o avisar directamente a tu supervisor. Si detectas cables pelados, andamios inestables o ventosas defectuosas, repórtalo de inmediato.',
         N'Aviso Importante: Un reporte dentro del sistema tiene carácter de mejora preventiva y no sustituye la llamada de emergencia inmediata ante un accidente grave (Cruz Blanca 128 o Bomberos 115).',
         N'Ley General de Higiene y Seguridad del Trabajo (Ley 618), Artículos 18 y 22.', '2026-10-01', N'Seguridad Industrial', 6);
END;
GO

/* =========================================================
   12. PROCEDIMIENTOS ALMACENADOS DE TALENTO HUMANO
   ========================================================= */

/* --- Consultar Directorio General (con roles y permisos) --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeDirectory
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        THROW 50447, 'Se requiere autorización de administración de Talento humano.', 1;

    SELECT employee.EmployeeId AS id, employee.Name AS name, employee.Position AS position,
           employee.Area AS area, employee.HireDate AS hireDate,
           employee.EmploymentStatus AS employmentStatus, employee.AccountActive AS accountActive,
           employee.DismissalDate AS dismissalDate, employee.DismissalReason AS dismissalReason
    FROM dbo.vw_HrEmployeeDirectory AS employee
    ORDER BY employee.Name;
END;
GO

/* --- Consultar Mi Expediente Autenticado --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrMyEmployee
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar Talento humano.', 1;

    SELECT employee.EmployeeId AS id, employee.Name AS name, employee.Position AS position,
           employee.Area AS area, employee.HireDate AS hireDate,
           employee.EmploymentStatus AS employmentStatus, employee.AccountActive AS accountActive
    FROM dbo.vw_HrEmployeeDirectory AS employee
    WHERE employee.AppUserId = @ActorId;
END;
GO

/* --- Resolver EmployeeId a partir de AppUserId --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeIdForUser
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar Talento humano.', 1;

    SELECT EmployeeId AS employeeId
    FROM dbo.vw_HrEmployeeDirectory
    WHERE AppUserId = @ActorId AND EmploymentStatus <> N'baja';
END;
GO

/* --- Detalle Completo de Expediente (7 pestañas) --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeDetail
    @EmployeeId NVARCHAR(100),
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsManagement BIT = 0;
    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @IsManagement = 1;

    -- Verificar que sea administración o el propio empleado
    IF @IsManagement = 0 AND NOT EXISTS (
        SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId AND AppUserId = @ActorId
    )
        THROW 50434, 'No tienes permiso para consultar el expediente solicitado.', 1;

    -- Resumen y Relación laboral
    SELECT employee.EmployeeId AS id, employee.Name AS name, employee.Position AS position,
           employee.Area AS area, employee.HireDate AS hireDate,
           employee.EmploymentStatus AS employmentStatus,
           employee.DismissalDate AS dismissalDate, employee.DismissalReason AS dismissalReason,
           employee.AppUserId AS appUserId,
           CASE WHEN @IsManagement = 1 THEN employee.Salary ELSE NULL END AS salary
    FROM dbo.Employees AS employee
    WHERE employee.EmployeeId = @EmployeeId;

    -- Contratos
    SELECT c.ContractId AS id, c.ContractNumber AS contractNumber, c.ContractType AS contractType,
           c.Position AS position, c.WorkSchedule AS workSchedule, c.StartDate AS startDate,
           c.EndDate AS endDate, c.AgreedTerms AS agreedTerms, c.Status AS status,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), c.Revision), 1) AS revision
    FROM dbo.HrContracts AS c
    WHERE c.EmployeeId = @EmployeeId
    ORDER BY c.StartDate DESC;

    -- Solicitudes
    SELECT r.HrRequestId AS id, r.Category AS category, r.StartDate AS startDate,
           r.EndDate AS endDate, r.Details AS details, r.Status AS status,
           r.Resolution AS resolution, r.CreatedAt AS createdAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision
    FROM dbo.HrRequests AS r
    WHERE r.EmployeeId = @EmployeeId
    ORDER BY r.CreatedAt DESC;

    -- Seguridad (EPP asignado)
    SELECT d.DeliveryId AS id, eq.Name AS equipmentName, eq.Category AS category,
           d.DeliveryDate AS deliveryDate, d.DeliveryType AS deliveryType,
           d.NextReplacementDate AS nextReplacementDate, d.Notes AS notes
    FROM dbo.HrEquipmentDeliveries d
    JOIN dbo.HrSafetyEquipment eq ON eq.EquipmentId = d.EquipmentId
    WHERE d.EmployeeId = @EmployeeId
    ORDER BY d.DeliveryDate DESC;
END;
GO

/* --- Crear Expediente de Personal con Idempotencia --- */
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrEmployee
    @MutationId UNIQUEIDENTIFIER,
    @EmployeeId NVARCHAR(100),
    @Name NVARCHAR(240),
    @Position NVARCHAR(200),
    @Salary DECIMAL(19,4),
    @Area NVARCHAR(120),
    @AppUserId NVARCHAR(100) = NULL,
    @HireDate DATE,
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF @MutationId IS NULL
       OR (@AppUserId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.AppUsers WHERE AppUserId = @AppUserId AND IsActive = 1
       ))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50435, 'La cuenta vinculada no existe o está inactiva.', 1;
    END;

    IF NULLIF(LTRIM(RTRIM(@Name)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Position)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Area)), N'') IS NULL
       OR @Salary IS NULL OR @Salary <= 0
       OR @HireDate IS NULL OR @HireDate > CONVERT(DATE, SYSUTCDATETIME())
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Los datos del expediente no son válidos.', 1;
    END;

    DECLARE @ExistingEmployeeId NVARCHAR(100);
    SELECT @ExistingEmployeeId = EmployeeId
    FROM dbo.HrEmployeeCreations WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingEmployeeId IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.HrEmployeeCreations
            WHERE MutationId = @MutationId AND CreatedByAppUserId = @ActorId
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50446, 'La clave de repetición ya está asociada a otra operación.', 1;
        END;
        COMMIT TRANSACTION;
        SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
               HireDate AS hireDate, EmploymentStatus AS employmentStatus,
               CAST(NULL AS BIT) AS accountActive, CAST(0 AS BIT) AS wasCreated
        FROM dbo.Employees
        WHERE EmployeeId = @ExistingEmployeeId;
        RETURN;
    END;

    INSERT INTO dbo.Employees (
        EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, IsActive, EmploymentStatus
    )
    VALUES (
        @EmployeeId, @Name, @Position, @Salary, @Area, @AppUserId, @HireDate, 1, N'activo'
    );

    INSERT INTO dbo.EmployeeJobHistory (
        EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
    )
    VALUES (
        NEWID(), @EmployeeId, @Position, @Area, @Salary, @HireDate, @ActorId
    );

    INSERT INTO dbo.HrContracts (
        ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, EndDate, AgreedTerms, Status
    )
    VALUES (
        NEWID(), @EmployeeId,
        CONCAT(N'CT-RAQ-', YEAR(@HireDate), N'-', RIGHT(CONCAT('00', ABS(CHECKSUM(NEWID())) % 900 + 100), 3)),
        N'indefinido', @Position, N'Diurna 48h (Lun-Sáb)', @HireDate, NULL,
        CONCAT(N'Contrato laboral según Código del Trabajo de Nicaragua (Ley 185). Puesto: ', @Position, N'. Área: ', @Area, N'. Con derecho a descanso semanal y EPP reglamentario.'),
        N'registrado'
    );

    INSERT INTO dbo.HrEmployeeCreations (MutationId, EmployeeId, CreatedByAppUserId)
    VALUES (@MutationId, @EmployeeId, @ActorId);

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'crear expediente de personal', N'rrhh',
        CONCAT(N'Expediente ', @EmployeeId, N' creado; sin incluir información salarial en auditoría abierta.'), N'info', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
           HireDate AS hireDate, EmploymentStatus AS employmentStatus,
           CAST(NULL AS BIT) AS accountActive, CAST(1 AS BIT) AS wasCreated
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

/* --- Actualizar Expediente y Registro Histórico --- */
CREATE OR ALTER PROCEDURE dbo.usp_UpdateHrEmployee
    @EmployeeId NVARCHAR(100),
    @Position NVARCHAR(200),
    @Area NVARCHAR(120),
    @Salary DECIMAL(19,4) = NULL,
    @EmploymentStatus NVARCHAR(20),
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WITH (UPDLOCK, HOLDLOCK) WHERE EmployeeId = @EmployeeId)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50448, 'No se encontró el expediente de personal.', 1;
    END;
    IF NULLIF(LTRIM(RTRIM(@Position)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Area)), N'') IS NULL
       OR (@Salary IS NOT NULL AND @Salary <= 0)
       OR @EmploymentStatus IS NULL OR @EmploymentStatus NOT IN (N'activo', N'licencia', N'baja')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Los datos laborales no son válidos.', 1;
    END;

    DECLARE @OldPosition NVARCHAR(200), @OldArea NVARCHAR(120),
            @OldSalary DECIMAL(19,4), @EffectiveDate DATE = CONVERT(DATE, SYSUTCDATETIME());
    SELECT @OldPosition = Position, @OldArea = Area, @OldSalary = Salary
    FROM dbo.Employees WHERE EmployeeId = @EmployeeId;

    IF @OldPosition <> @Position OR @OldArea <> @Area OR (@Salary IS NOT NULL AND @OldSalary <> @Salary)
    BEGIN
        UPDATE dbo.EmployeeJobHistory
        SET ValidTo = DATEADD(DAY, -1, @EffectiveDate)
        WHERE EmployeeId = @EmployeeId AND ValidTo IS NULL;

        INSERT INTO dbo.EmployeeJobHistory (
            EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
        )
        VALUES (
            NEWID(), @EmployeeId, @Position, @Area, COALESCE(@Salary, @OldSalary), @EffectiveDate, @ActorId
        );
    END;

    UPDATE dbo.Employees
    SET Position = @Position,
        Area = @Area,
        Salary = COALESCE(@Salary, Salary),
        EmploymentStatus = @EmploymentStatus,
        IsActive = CASE WHEN @EmploymentStatus = N'baja' THEN 0 ELSE 1 END
    WHERE EmployeeId = @EmployeeId;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'actualizar expediente de personal', N'rrhh',
        CONCAT(N'Expediente ', @EmployeeId, N' actualizado con nuevo cargo/área/estado.'), N'info', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
           HireDate AS hireDate, EmploymentStatus AS employmentStatus,
           CAST(NULL AS BIT) AS accountActive
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

/* --- Registro de Baja Laboral (sin borrar el expediente) --- */
CREATE OR ALTER PROCEDURE dbo.usp_TerminateHrEmployee
    @EmployeeId NVARCHAR(100),
    @DismissalDate DATE,
    @DismissalReason NVARCHAR(500),
    @DismissalDocRef NVARCHAR(300) = NULL,
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50448, 'No se encontró el expediente de personal.', 1;
    END;

    IF @DismissalDate IS NULL OR NULLIF(LTRIM(RTRIM(@DismissalReason)), N'') IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Indica la fecha y el motivo formal de la baja laboral.', 1;
    END;

    UPDATE dbo.Employees
    SET EmploymentStatus = N'baja',
        IsActive = 0,
        DismissalDate = @DismissalDate,
        DismissalReason = @DismissalReason,
        DismissalDocRef = @DismissalDocRef
    WHERE EmployeeId = @EmployeeId;

    -- Finalizar contratos vigentes
    UPDATE dbo.HrContracts
    SET Status = N'finalizado', EndDate = @DismissalDate, UpdatedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
    WHERE EmployeeId = @EmployeeId AND Status IN (N'registrado', N'en_revision');

    -- Deshabilitar cuenta si existía vinculada
    UPDATE u
    SET u.IsActive = 0
    FROM dbo.AppUsers u
    JOIN dbo.Employees e ON e.AppUserId = u.AppUserId
    WHERE e.EmployeeId = @EmployeeId;

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'baja laboral de personal', N'rrhh',
        CONCAT(N'Baja formal registrada para expediente ', @EmployeeId, N' con motivo autorizado; expediente preservado en archivo histórico.'), N'warn', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, EmploymentStatus AS employmentStatus,
           DismissalDate AS dismissalDate, DismissalReason AS dismissalReason
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

/* --- Consultar Historial Laboral --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrEmployeeJobHistory
    @EmployeeId NVARCHAR(100),
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsManagement BIT = 0;
    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @IsManagement = 1;

    IF @IsManagement = 0 AND NOT EXISTS (
        SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId AND AppUserId = @ActorId
    )
        THROW 50434, 'No tienes permiso para consultar este historial.', 1;

    SELECT history.EmployeeJobHistoryId AS id, history.Position AS position,
           history.Area AS area, history.ValidFrom AS validFrom,
           history.ValidTo AS validTo, history.CreatedAt AS createdAt,
           actor.Name AS changedBy
    FROM dbo.EmployeeJobHistory AS history
    LEFT JOIN dbo.AppUsers AS actor ON actor.AppUserId = history.ChangedByAppUserId
    WHERE history.EmployeeId = @EmployeeId
    ORDER BY history.ValidFrom DESC, history.CreatedAt DESC;
END;
GO

/* --- Crear Solicitud de Personal (Vacaciones, Permisos, etc.) --- */
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrRequest
    @HrRequestId UNIQUEIDENTIFIER,
    @MutationId UNIQUEIDENTIFIER,
    @EmployeeId NVARCHAR(100),
    @Category NVARCHAR(30),
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @Details NVARCHAR(1000),
    @AppUserId NVARCHAR(100),
    @ActorName NVARCHAR(240)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @AppUserId AND IsActive = 1 AND MustChangePassword = 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50447, 'La sesión no está autorizada para crear solicitudes.', 1;
    END;

    DECLARE @ExistingId UNIQUEIDENTIFIER;
    SELECT @ExistingId = HrRequestId
    FROM dbo.HrRequests WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingId IS NULL
    BEGIN
        IF @Category IS NULL OR @Category NOT IN (N'vacaciones', N'permiso', N'correccion_datos', N'consulta_laboral', N'seguridad', N'trato_recibido')
           OR NULLIF(LTRIM(RTRIM(@Details)), N'') IS NULL
           OR (@Category IN (N'vacaciones', N'permiso') AND (@StartDate IS NULL OR @EndDate IS NULL))
           OR (@StartDate IS NOT NULL AND @EndDate IS NOT NULL AND @EndDate < @StartDate)
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50444, 'Los datos de la solicitud no son válidos.', 1;
        END;

        -- Validar solapamiento con solicitudes ya aprobadas o enviadas de la misma categoría
        IF @Category IN (N'vacaciones', N'permiso') AND EXISTS (
            SELECT 1 FROM dbo.HrRequests
            WHERE EmployeeId = @EmployeeId AND Status IN (N'enviada', N'en_revision', N'aprobada')
              AND StartDate <= @EndDate AND EndDate >= @StartDate
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50451, 'Ya existe una solicitud de descanso o permiso para ese rango de fechas.', 1;
        END;

        INSERT INTO dbo.HrRequests (
            HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details
        )
        SELECT @HrRequestId, @MutationId, employee.EmployeeId, @Category, @StartDate, @EndDate, @Details
        FROM dbo.Employees AS employee
        WHERE employee.EmployeeId = @EmployeeId
          AND employee.AppUserId = @AppUserId
          AND employee.EmploymentStatus = N'activo';

        IF @@ROWCOUNT <> 1
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50433, 'No existe un expediente activo vinculado con la sesión.', 1;
        END;

        INSERT INTO dbo.HrRequestEvents (
            HrRequestEventId, HrRequestId, AppUserId, ActorName, EventType, Detail
        )
        VALUES (NEWID(), @HrRequestId, @AppUserId, @ActorName, N'enviada', N'Solicitud recibida en la bandeja.');

        SET @ExistingId = @HrRequestId;
    END;

    COMMIT TRANSACTION;
    SELECT HrRequestId AS id, Category AS category, StartDate AS startDate, EndDate AS endDate,
           Details AS details, Status AS status, Resolution AS resolution,
           CreatedAt AS createdAt, UpdatedAt AS updatedAt, DecidedAt AS decidedAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), Revision), 1) AS revision
    FROM dbo.HrRequests
    WHERE HrRequestId = @ExistingId;
END;
GO

/* --- Consultar Solicitudes (Cola de gestión o Mis casos) --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrRequests
    @ActorId NVARCHAR(100),
    @Scope NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmployeeId NVARCHAR(100), @Management BIT = 0;
    SELECT @EmployeeId = employee.EmployeeId
    FROM dbo.Employees AS employee
    JOIN dbo.AppUsers AS actor ON actor.AppUserId = employee.AppUserId
    WHERE actor.AppUserId = @ActorId AND actor.IsActive = 1
      AND actor.MustChangePassword = 0 AND employee.EmploymentStatus <> N'baja';

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar solicitudes.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND
          (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @Management = 1;

    IF @Scope IS NULL OR @Scope NOT IN (N'mine', N'queue')
        THROW 50444, 'El alcance de solicitudes no es válido.', 1;
    IF @Scope = N'queue' AND @Management = 0
        THROW 50440, 'Se requiere autorización de administración de Talento humano.', 1;
    IF @Scope = N'mine' AND @EmployeeId IS NULL
        RETURN;

    SELECT TOP (200) request.HrRequestId AS id, request.EmployeeId AS employeeId,
           employee.Name AS employeeName, request.Category AS category,
           request.StartDate AS startDate, request.EndDate AS endDate,
           request.Details AS details, request.Status AS status,
           request.Resolution AS resolution, request.CreatedAt AS createdAt,
           request.UpdatedAt AS updatedAt, request.DecidedAt AS decidedAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), request.Revision), 1) AS revision
    FROM dbo.HrRequests AS request
    JOIN dbo.Employees AS employee ON employee.EmployeeId = request.EmployeeId
    WHERE (@Scope = N'queue' AND @Management = 1)
       OR (@Scope = N'mine' AND request.EmployeeId = @EmployeeId)
    ORDER BY request.CreatedAt DESC;
END;
GO

/* --- Actualizar Estado de Solicitud (Separación de Funciones y Concurrencia) --- */
CREATE OR ALTER PROCEDURE dbo.usp_UpdateHrRequestStatus
    @HrRequestId UNIQUEIDENTIFIER,
    @ExpectedRevision BINARY(8),
    @Status NVARCHAR(20),
    @Resolution NVARCHAR(1000),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    DECLARE @EmployeeId NVARCHAR(100), @ApplicantId NVARCHAR(100),
            @CurrentStatus NVARCHAR(20), @CurrentRevision BINARY(8);
    SELECT @EmployeeId = request.EmployeeId, @ApplicantId = employee.AppUserId,
           @CurrentStatus = request.Status, @CurrentRevision = request.Revision
    FROM dbo.HrRequests AS request WITH (UPDLOCK, HOLDLOCK)
    JOIN dbo.Employees AS employee ON employee.EmployeeId = request.EmployeeId
    WHERE request.HrRequestId = @HrRequestId;

    IF @EmployeeId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50436, 'No se encontró la solicitud.', 1;
    END;
    IF @CurrentRevision <> @ExpectedRevision
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50437, 'La solicitud cambió desde la última lectura. Actualiza la lista antes de resolver.', 1;
    END;
    IF @CurrentStatus NOT IN (N'enviada', N'en_revision')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50438, 'La solicitud ya tiene una decisión final.', 1;
    END;
    IF @Status IS NULL OR @Status NOT IN (N'en_revision', N'aprobada', N'rechazada', N'cancelada')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50445, 'El estado de la solicitud no es válido.', 1;
    END;

    IF @Status = N'cancelada'
    BEGIN
        IF @ApplicantId <> @ActorId
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50439, 'Solo quien envió la solicitud puede cancelarla.', 1;
        END;
    END
    ELSE
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.AppUsers
            WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
              AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
                  SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
              )))
        )
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50440, 'Se requiere autorización de administración de Talento humano.', 1;
        END;

        -- Regla estricta: Separación de funciones, no se permite auto-aprobar solicitudes propias
        IF @Status IN (N'aprobada', N'rechazada') AND @ApplicantId = @ActorId
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50441, 'No puedes decidir una solicitud propia. Debe revisarla otro administrador.', 1;
        END;

        IF @Status IN (N'aprobada', N'rechazada') AND NULLIF(LTRIM(RTRIM(@Resolution)), N'') IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50442, 'La decisión requiere una explicación clara para el trabajador.', 1;
        END;
    END;

    UPDATE dbo.HrRequests
    SET Status = @Status,
        Resolution = NULLIF(@Resolution, N''),
        AssignedToAppUserId = CASE WHEN @Status = N'en_revision' THEN @ActorId ELSE AssignedToAppUserId END,
        DecidedByAppUserId = CASE WHEN @Status IN (N'aprobada', N'rechazada') THEN @ActorId ELSE NULL END,
        DecidedAt = CASE WHEN @Status IN (N'aprobada', N'rechazada') THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE NULL END,
        UpdatedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
    WHERE HrRequestId = @HrRequestId AND Revision = @ExpectedRevision;

    IF @@ROWCOUNT <> 1
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50437, 'La solicitud cambió concurrentemente.', 1;
    END;

    INSERT INTO dbo.HrRequestEvents (
        HrRequestEventId, HrRequestId, AppUserId, ActorName, EventType, Detail
    )
    VALUES (NEWID(), @HrRequestId, @ActorId, @ActorName, @Status, @Resolution);

    COMMIT TRANSACTION;
    SELECT HrRequestId AS id, EmployeeId AS employeeId, Category AS category,
           StartDate AS startDate, EndDate AS endDate, Details AS details,
           Status AS status, Resolution AS resolution, CreatedAt AS createdAt,
           UpdatedAt AS updatedAt, DecidedAt AS decidedAt,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), Revision), 1) AS revision
    FROM dbo.HrRequests
    WHERE HrRequestId = @HrRequestId;
END;
GO

/* --- Eventos y Trazabilidad de una Solicitud --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrRequestEvents
    @HrRequestId UNIQUEIDENTIFIER,
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmployeeId NVARCHAR(100), @Management BIT = 0;
    SELECT @EmployeeId = EmployeeId
    FROM dbo.Employees
    WHERE AppUserId = @ActorId AND EmploymentStatus <> N'baja';

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
    )
        THROW 50447, 'La sesión no está autorizada para consultar solicitudes.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND
          (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @Management = 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.HrRequests
        WHERE HrRequestId = @HrRequestId AND (@Management = 1 OR EmployeeId = @EmployeeId)
    )
        THROW 50450, 'No se encontró la solicitud o no tienes permiso para verla.', 1;

    SELECT event.HrRequestEventId AS id, event.ActorName AS actorName,
           event.EventType AS eventType, event.Detail AS detail, event.OccurredAt AS occurredAt
    FROM dbo.HrRequestEvents AS event
    WHERE event.HrRequestId = @HrRequestId
    ORDER BY event.OccurredAt;
END;
GO

/* --- Métricas Dinámicas del Dashboard de Talento Humano --- */
CREATE OR ALTER PROCEDURE dbo.usp_GetHrDashboardMetrics
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IsManagement BIT = 0, @EmployeeId NVARCHAR(100) = NULL;

    SELECT @EmployeeId = EmployeeId FROM dbo.Employees WHERE AppUserId = @ActorId;

    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          )))
    )
        SET @IsManagement = 1;

    IF @IsManagement = 1
    BEGIN
        SELECT
            (SELECT COUNT(*) FROM dbo.Employees WHERE EmploymentStatus = N'activo') AS activeEmployees,
            (SELECT COUNT(*) FROM dbo.HrRequests WHERE Status IN (N'enviada', N'en_revision')) AS pendingRequests,
            (SELECT COUNT(*) FROM dbo.HrContracts WHERE Status = N'en_revision' OR (EndDate IS NOT NULL AND EndDate <= DATEADD(DAY, 45, CONVERT(DATE, SYSUTCDATETIME())))) AS contractsToReview,
            (SELECT COUNT(*) FROM dbo.HrEquipmentDeliveries WHERE NextReplacementDate IS NOT NULL AND NextReplacementDate <= DATEADD(DAY, 15, CONVERT(DATE, SYSUTCDATETIME()))) AS pendingPpeDeliveries,
            (SELECT COUNT(*) FROM dbo.HrCorrectiveActions WHERE Status IN (N'abierta', N'en_proceso')) AS openCorrectiveActions,
            CAST(1 AS BIT) AS isManagementView;
    END
    ELSE
    BEGIN
        SELECT
            (SELECT COUNT(*) FROM dbo.HrRequests WHERE EmployeeId = @EmployeeId) AS myTotalRequests,
            (SELECT COUNT(*) FROM dbo.HrRequests WHERE EmployeeId = @EmployeeId AND Status IN (N'enviada', N'en_revision')) AS myPendingRequests,
            (SELECT COUNT(*) FROM dbo.HrContracts WHERE EmployeeId = @EmployeeId AND Status = N'registrado') AS myActiveContracts,
            (SELECT COUNT(*) FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = @EmployeeId) AS mySafetyItems,
            (SELECT COUNT(*) FROM dbo.HrTrainingAttendees WHERE EmployeeId = @EmployeeId AND Attended = 1) AS myTrainingsCompleted,
            CAST(0 AS BIT) AS isManagementView;
    END;
END;
GO

/* =========================================================
   13. PERMISOS DE EJECUCIÓN PARA EL USUARIO DE LA APLICACIÓN
   ========================================================= */
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    REVOKE SELECT ON OBJECT::dbo.Employees FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.EmployeeJobHistory FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.HrRequests FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.HrRequestEvents FROM [raquel_erp_app];
    REVOKE SELECT ON OBJECT::dbo.vw_HrEmployeeDirectory FROM [raquel_erp_app];

    GRANT SELECT ON OBJECT::dbo.Employees TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.vw_HrEmployeeDirectory TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.HrRequests TO [raquel_erp_app];
    GRANT SELECT, INSERT ON OBJECT::dbo.HrRequestEvents TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.EmployeeJobHistory TO [raquel_erp_app];

    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrMyEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeDirectory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeDetail TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeIdForUser TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpdateHrEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_TerminateHrEmployee TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrEmployeeJobHistory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrRequests TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrRequestEvents TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrRequest TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpdateHrRequestStatus TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetHrDashboardMetrics TO [raquel_erp_app];

    -- Tablas complementarias de solo lectura o acceso controlado
    GRANT SELECT ON OBJECT::dbo.HrContracts TO [raquel_erp_app];
    GRANT INSERT, UPDATE ON OBJECT::dbo.HrContracts TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrAttendanceRecords TO [raquel_erp_app];
    GRANT INSERT, UPDATE ON OBJECT::dbo.HrAttendanceRecords TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrSafetyEquipment TO [raquel_erp_app];
    GRANT SELECT, INSERT ON OBJECT::dbo.HrEquipmentDeliveries TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrSafetyTrainings TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrTrainingAttendees TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.HrSafetyIncidents TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE ON OBJECT::dbo.HrCorrectiveActions TO [raquel_erp_app];
    GRANT SELECT, UPDATE ON OBJECT::dbo.HrComplianceObligations TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.HrRightsArticles TO [raquel_erp_app];
END;
GO

IF TRY_CONVERT(BIT,SESSION_CONTEXT(N'raquel_include_demo'))=1
AND EXISTS (SELECT 1 FROM dbo.AppUsers WHERE AppUserId=N'u-super')
AND NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE AppUserId = N'u-super')
BEGIN
    INSERT INTO dbo.Employees (EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, IsActive, EmploymentStatus)
    VALUES (N'e0', N'Raquel López', N'Gerente General', 45000, N'Dirección', N'u-super', '2024-01-15', 1, N'activo');
END;
GO

GO

/* ARCHIVO 14/25: 17_modulo_nomina_completo.sql */
/* ==============================================================================
   17 — MÓDULO INTEGRAL DE NÓMINA, PRESTACIONES Y CUMPLIMIENTO LABORAL (NICARAGUA)
   Raquel_Schema_Check_20261025_99ef80cc — Aluminio, Vidrio y Fachadas Arquitectónicas
   Fundamento Legal: Ley 185 (Código del Trabajo), Ley 822 (LCT) y Reglamento,
                     Ley de Seguridad Social (INSS), Ley INATEC y Ley 787.
   ============================================================================== */

USE [Raquel_Schema_Check_20261025_99ef80cc];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1. PLAN DE CUENTAS: Asegurar cuentas de nómina y pasivos laborales
-- -----------------------------------------------------------------------------
MERGE dbo.ChartOfAccounts AS target
USING (VALUES
    (N'Nómina', N'gasto'),
    (N'Aporte patronal INSS e INATEC', N'gasto'),
    (N'Gasto prestaciones y provisiones', N'gasto'),
    (N'Sueldos por pagar', N'pasivo'),
    (N'INSS por pagar', N'pasivo'),
    (N'IR por pagar', N'pasivo'),
    (N'INATEC por pagar', N'pasivo'),
    (N'Provisiones laborales por pagar', N'pasivo'),
    (N'Banco', N'activo'),
    (N'Caja', N'activo')
) AS src (AccountName, AccountType)
ON (target.AccountName = src.AccountName)
WHEN MATCHED AND target.AccountType <> src.AccountType THEN
    UPDATE SET target.AccountType = src.AccountType
WHEN NOT MATCHED THEN
    INSERT (AccountName, AccountType) VALUES (src.AccountName, src.AccountType);
GO

-- -----------------------------------------------------------------------------
-- 2. CATÁLOGO DE REGLAS NORMATIVAS Y PARÁMETROS (NICARAGUA)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollRulesCatalog', N'U') IS NULL
CREATE TABLE dbo.PayrollRulesCatalog
(
    RuleId           NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollRulesCatalog PRIMARY KEY,
    RuleCode         NVARCHAR(40)  NOT NULL CONSTRAINT UQ_PayrollRulesCatalog_Code UNIQUE,
    RuleName         NVARCHAR(200) NOT NULL,
    LawReference     NVARCHAR(300) NOT NULL,
    OfficialSource   NVARCHAR(300) NOT NULL,
    EffectiveFrom    DATE          NOT NULL,
    EffectiveTo      DATE          NULL,
    ParameterJson    NVARCHAR(MAX) NOT NULL,
    IsVerified       BIT           NOT NULL CONSTRAINT DF_PayrollRules_IsVerified DEFAULT (1),
    ReviewedBy       NVARCHAR(200) NOT NULL,
    ReviewedAt       DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollRules_ReviewedAt DEFAULT (SYSUTCDATETIME()),
    Status           NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollRules_Status DEFAULT (N'vigente')
);
GO

MERGE dbo.PayrollRulesCatalog AS target
USING (VALUES
    (N'rule-inss-lab', N'INSS_LABORAL', N'Aporte Laboral INSS (7.0%)',
     N'Ley de Seguridad Social, Art. 16 y Decreto Ejecutivo No. 06-2019',
     N'La Gaceta, Diario Oficial No. 22', '2019-02-01', NULL,
     N'{"rate": 0.07, "cap": null, "description": "Deducción del 7% sobre el total devengado sin techo salarial."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-inss-pat', N'INSS_PATRONAL', N'Aporte Patronal INSS (21.5% / 22.5%)',
     N'Ley de Seguridad Social, Decreto Ejecutivo No. 06-2019',
     N'La Gaceta, Diario Oficial No. 22', '2019-02-01', NULL,
     N'{"rate_standard": 0.225, "rate_large": 0.215, "threshold_workers": 50, "rate_used": 0.215, "description": "21.5% para empresas con más de 50 trabajadores, 22.5% hasta 50 trabajadores."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-inatec', N'INATEC_PATRONAL', N'Aporte Patronal INATEC (2.0%)',
     N'Decreto Ley No. 3-91 y Ley Orgánica de INATEC',
     N'La Gaceta, Diario Oficial No. 71', '1991-04-18', NULL,
     N'{"rate": 0.02, "description": "Aporte patronal del 2% sobre nómina para capacitación técnica."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-ir-prog', N'IR_PROGRESIVO', N'Retención IR Salarial Progresiva',
     N'Ley 822 (LCT), Art. 23 y Art. 96 (Tarifa Progresiva)',
     N'La Gaceta No. 241 con reformas vigentes DGI', '2013-01-01', NULL,
     N'{"brackets": [{"from": 0.01, "to": 100000.0, "rate": 0.0, "base": 0.0, "excess": 0.0}, {"from": 100000.01, "to": 200000.0, "rate": 0.15, "base": 0.0, "excess": 100000.0}, {"from": 200000.01, "to": 350000.0, "rate": 0.20, "base": 15000.0, "excess": 200000.0}, {"from": 350000.01, "to": 500000.0, "rate": 0.25, "base": 45000.0, "excess": 350000.0}, {"from": 500000.01, "to": null, "rate": 0.30, "base": 82500.0, "excess": 500000.0}], "exemption_base": "Ingreso gravable anualizado menos INSS laboral anualizado."}',
     1, N'María Contadora', N'vigente'),

    (N'rule-aguinaldo', N'AGUINALDO_PROV', N'Décimo Tercer Mes / Aguinaldo (8.3333%)',
     N'Código del Trabajo (Ley 185), Artículos 93 a 99',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"rate": 0.083333, "fraction": "1/12", "description": "Un mes de salario ordinario por año de trabajo continuo o proporcional."}',
     1, N'Raquel López', N'vigente'),

    (N'rule-vacaciones', N'VACACIONES_PROV', N'Vacaciones Remuneradas (8.3333%)',
     N'Código del Trabajo (Ley 185), Artículos 76 a 81',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"rate": 0.083333, "days_per_semester": 15, "description": "15 días continuos de descanso remunerado por cada seis meses de labor continua (2.5 días/mes)."}',
     1, N'Raquel López', N'vigente'),

    (N'rule-antiguedad', N'INDEMNIZACION_PROV', N'Indemnización por Años de Servicio (8.3333%)',
     N'Código del Trabajo (Ley 185), Artículo 45',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"rate": 0.083333, "rules": "1 mes por cada uno de los primeros 3 años; 20 días por año a partir del 4to año; tope 5 meses.", "description": "Provisión técnica mensual para pasivo laboral por antigüedad."}',
     1, N'Raquel López', N'vigente'),

    (N'rule-horas-extra', N'HORA_EXTRA_RECARGO', N'Horas Extraordinarias (Recargo 100%)',
     N'Código del Trabajo (Ley 185), Artículos 57 y 58',
     N'La Gaceta No. 205', '1996-10-30', NULL,
     N'{"multiplier": 2.0, "max_weekly_hours": 9, "divisor_monthly": 240, "description": "La hora extraordinaria se remunera con el doble del valor de la hora ordinaria."}',
     1, N'Carlos Producción', N'vigente')
) AS src (RuleId, RuleCode, RuleName, LawReference, OfficialSource, EffectiveFrom, EffectiveTo, ParameterJson, IsVerified, ReviewedBy, Status)
ON (target.RuleId = src.RuleId)
WHEN MATCHED THEN
    UPDATE SET target.RuleCode = src.RuleCode, target.RuleName = src.RuleName,
               target.LawReference = src.LawReference, target.OfficialSource = src.OfficialSource,
               target.EffectiveFrom = src.EffectiveFrom, target.ParameterJson = src.ParameterJson,
               target.IsVerified = src.IsVerified, target.ReviewedBy = src.ReviewedBy, target.Status = src.Status
WHEN NOT MATCHED THEN
    INSERT (RuleId, RuleCode, RuleName, LawReference, OfficialSource, EffectiveFrom, EffectiveTo, ParameterJson, IsVerified, ReviewedBy, Status)
    VALUES (src.RuleId, src.RuleCode, src.RuleName, src.LawReference, src.OfficialSource, src.EffectiveFrom, src.EffectiveTo, src.ParameterJson, src.IsVerified, src.ReviewedBy, src.Status);
GO

-- -----------------------------------------------------------------------------
-- 3. CABECERA DE PLANILLA DE NÓMINA (dbo.PayrollRuns)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollRuns', N'U') IS NOT NULL
BEGIN
    -- Asegurar columnas avanzadas si la tabla fue creada en la versión básica
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PeriodType') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PeriodType NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRuns_PeriodType DEFAULT (N'quincenal');
    IF COL_LENGTH(N'dbo.PayrollRuns', N'StartDate') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD StartDate DATE NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'EndDate') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD EndDate DATE NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PaymentDate') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PaymentDate DATE NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'Status') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD Status NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRuns_Status DEFAULT (N'borrador');
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculationVersion') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CalculationVersion INT NOT NULL CONSTRAINT DF_PayrollRuns_CalcVer DEFAULT (1);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'OtherDeductionsTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD OtherDeductionsTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_OtherDed DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'AguinaldoProvTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD AguinaldoProvTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_AguiProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'VacacionesProvTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD VacacionesProvTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_VacProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'IndemnizacionProvTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD IndemnizacionProvTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_IndemProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ConfirmedPaymentsTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ConfirmedPaymentsTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_ConfPay DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PendingDiscrepancyTotal') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PendingDiscrepancyTotal DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRuns_PendDisc DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PreparedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PreparedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_PrepUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PreparedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PreparedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculatedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CalculatedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_CalcUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculatedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CalculatedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReviewedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReviewedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_RevUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReviewedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReviewedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReviewNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReviewNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ApprovedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ApprovedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_ApprUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ApprovedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ApprovedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ApprovalNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ApprovalNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PaidByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PaidByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_PaidUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'PaymentNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD PaymentNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReconciledByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReconciledByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_ReconUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReconciledAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReconciledAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ReconciliationNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ReconciliationNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ClosedByAppUserId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ClosedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_CloseUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'ClosedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD ClosedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CloseNotes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CloseNotes NVARCHAR(1000) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'AccountingEntryId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD AccountingEntryId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_AcctEntry FOREIGN KEY REFERENCES dbo.AccountingEntries(AccountingEntryId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CashMoveId') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CashMoveId NVARCHAR(100) NULL CONSTRAINT FK_PayrollRuns_CashMove FOREIGN KEY REFERENCES dbo.CashMoves(CashMoveId);
    IF COL_LENGTH(N'dbo.PayrollRuns', N'Notes') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD Notes NVARCHAR(MAX) NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'Revision') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD Revision ROWVERSION NOT NULL;
    IF COL_LENGTH(N'dbo.PayrollRuns', N'CreatedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD CreatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollRuns_CreatedAt DEFAULT (SYSUTCDATETIME());
    IF COL_LENGTH(N'dbo.PayrollRuns', N'UpdatedAt') IS NULL
        ALTER TABLE dbo.PayrollRuns ADD UpdatedAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollRuns_UpdatedAt DEFAULT (SYSUTCDATETIME());
END;
GO

-- -----------------------------------------------------------------------------
-- 4. DETALLE DE TRABAJADORES EN PLANILLA (dbo.PayrollRunItems)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollRunItems', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PayrollItemId') IS NULL
    BEGIN
        ALTER TABLE dbo.PayrollRunItems ADD PayrollItemId NVARCHAR(100) NULL;
        EXEC(N'UPDATE dbo.PayrollRunItems SET PayrollItemId = PayrollRunId + N''-'' + EmployeeId WHERE PayrollItemId IS NULL;');
        ALTER TABLE dbo.PayrollRunItems ALTER COLUMN PayrollItemId NVARCHAR(100) NOT NULL;
    END;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PositionSnapshot') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PositionSnapshot NVARCHAR(200) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'AreaSnapshot') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD AreaSnapshot NVARCHAR(120) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'BaseSalaryMonthly') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD BaseSalaryMonthly DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_BaseSal DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PeriodDaysWorked') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PeriodDaysWorked DECIMAL(9,2) NOT NULL CONSTRAINT DF_PayrollRunItems_DaysWorked DEFAULT (15);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PeriodHoursWorked') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PeriodHoursWorked DECIMAL(9,2) NOT NULL CONSTRAINT DF_PayrollRunItems_HoursWorked DEFAULT (120);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OrdinarySalary') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OrdinarySalary DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OrdSal DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OvertimeHours') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OvertimeHours DECIMAL(9,2) NOT NULL CONSTRAINT DF_PayrollRunItems_OtHours DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OvertimeAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OvertimeAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OtAmt DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'BonusesAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD BonusesAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_Bonuses DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'CommissionsAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD CommissionsAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_Commissions DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'VacationDisfruteAmount') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD VacationDisfruteAmount DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_VacDisfrute DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OtherTaxableIncome') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OtherTaxableIncome DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OtherInc DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'InssBase') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD InssBase DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_InssBase DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'IrBase') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD IrBase DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_IrBase DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'OtherDeductions') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD OtherDeductions DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_OtherDed DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'TotalDeductions') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD TotalDeductions DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_TotDed DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'VacacionesProv') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD VacacionesProv DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_VacProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'IndemnizacionProv') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD IndemnizacionProv DECIMAL(19,4) NOT NULL CONSTRAINT DF_PayrollRunItems_IndemProv DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentStatus') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRunItems_PayStat DEFAULT (N'pendiente');
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentMethod') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentMethod NVARCHAR(40) NOT NULL CONSTRAINT DF_PayrollRunItems_PayMethod DEFAULT (N'transferencia_bancaria');
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentReference') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentReference NVARCHAR(120) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'PaymentConfirmedAt') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD PaymentConfirmedAt DATETIMEOFFSET(3) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'CalculationExplanationJson') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD CalculationExplanationJson NVARCHAR(MAX) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'HasDiscrepancy') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD HasDiscrepancy BIT NOT NULL CONSTRAINT DF_PayrollRunItems_HasDisc DEFAULT (0);
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'DiscrepancyReason') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD DiscrepancyReason NVARCHAR(500) NULL;
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'ReceiptStatus') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD ReceiptStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_PayrollRunItems_RcptStat DEFAULT (N'no_generado');
    IF COL_LENGTH(N'dbo.PayrollRunItems', N'Revision') IS NULL
        ALTER TABLE dbo.PayrollRunItems ADD Revision ROWVERSION NOT NULL;
END;
GO

-- -----------------------------------------------------------------------------
-- 5. NOVEDADES DEL PERÍODO (dbo.PayrollNovelties)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollNovelties', N'U') IS NULL
CREATE TABLE dbo.PayrollNovelties
(
    NoveltyId           NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollNovelties PRIMARY KEY,
    PayrollRunId        NVARCHAR(100) NULL CONSTRAINT FK_PayrollNovelties_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE SET NULL,
    EmployeeId          NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollNovelties_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    NoveltyType         NVARCHAR(40)  NOT NULL,
    Concept             NVARCHAR(240) NOT NULL,
    Amount              DECIMAL(19,4) NOT NULL,
    Hours               DECIMAL(9,2)  NULL,
    LegalJustification  NVARCHAR(500) NULL,
    DocReference        NVARCHAR(300) NULL,
    PeriodDate          DATE          NOT NULL,
    Status              NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollNovelties_Status DEFAULT (N'autorizada'),
    CreatedByAppUserId  NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollNovelties_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    AuthorizedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollNovelties_AuthUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    AuthorizedAt        DATETIMEOFFSET(3) NULL,
    CreatedAt           DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollNovelties_CreatedAt DEFAULT (SYSUTCDATETIME()),
    Revision            ROWVERSION NOT NULL
);
GO

-- -----------------------------------------------------------------------------
-- 6. VALIDACIONES DE REGLAS DE NÓMINA (dbo.PayrollValidations)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollValidations', N'U') IS NULL
CREATE TABLE dbo.PayrollValidations
(
    ValidationId        NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollValidations PRIMARY KEY,
    PayrollRunId        NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollValidations_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId          NVARCHAR(100) NULL CONSTRAINT FK_PayrollValidations_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    Severity            NVARCHAR(20)  NOT NULL CONSTRAINT CK_PayrollValidations_Severity CHECK (Severity IN (N'bloqueante', N'advertencia', N'informativa')),
    RuleCode            NVARCHAR(50)  NOT NULL,
    Message             NVARCHAR(500) NOT NULL,
    TargetTab           NVARCHAR(40)  NOT NULL CONSTRAINT DF_PayrollValidations_Tab DEFAULT (N'trabajadores'),
    IsResolved          BIT           NOT NULL CONSTRAINT DF_PayrollValidations_IsResolved DEFAULT (0),
    ResolvedAt          DATETIMEOFFSET(3) NULL,
    ResolvedByAppUserId NVARCHAR(100) NULL CONSTRAINT FK_PayrollValidations_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    CreatedAt           DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollValidations_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 7. DISTRIBUCIÓN DE COSTOS DE NÓMINA A PROYECTOS (dbo.PayrollProjectDistributions)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollProjectDistributions', N'U') IS NULL
CREATE TABLE dbo.PayrollProjectDistributions
(
    DistributionId      NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollProjectDistributions PRIMARY KEY,
    PayrollRunId        NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId          NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    ProjectId           NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_Proj FOREIGN KEY REFERENCES dbo.Projects(ProjectId),
    ProductionOrderId   NVARCHAR(100) NULL CONSTRAINT FK_PayrollProjDist_ProdOrder FOREIGN KEY REFERENCES dbo.ProductionOrders(ProductionOrderId),
    HoursAllocated      DECIMAL(9,2)  NOT NULL DEFAULT (0),
    PercentageAllocated DECIMAL(5,2)  NOT NULL DEFAULT (100.00),
    CostAllocated       DECIMAL(19,4) NOT NULL,
    Notes               NVARCHAR(500) NULL,
    ApprovedByAppUserId NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollProjDist_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    CreatedAt           DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollProjDist_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 8. REGISTRO DETALLADO DE PAGOS (dbo.PayrollPayments)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollPayments', N'U') IS NULL
CREATE TABLE dbo.PayrollPayments
(
    PaymentId               NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollPayments PRIMARY KEY,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollPayments_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EmployeeId              NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollPayments_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    Amount                  DECIMAL(19,4) NOT NULL,
    PaymentMethod           NVARCHAR(40)  NOT NULL CONSTRAINT DF_PayrollPayments_Method DEFAULT (N'transferencia_bancaria'),
    BankName                NVARCHAR(100) NULL,
    AccountLast4            NVARCHAR(10)  NULL,
    TransactionReference    NVARCHAR(120) NULL,
    BatchNumber             NVARCHAR(60)  NULL,
    Status                  NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollPayments_Status DEFAULT (N'preparado'),
    ConfirmedAt             DATETIMEOFFSET(3) NULL,
    ConfirmedByAppUserId    NVARCHAR(100) NULL CONSTRAINT FK_PayrollPayments_ConfUser FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    ManualConfirmationProof NVARCHAR(300) NULL,
    CashMoveId              NVARCHAR(100) NULL CONSTRAINT FK_PayrollPayments_CashMove FOREIGN KEY REFERENCES dbo.CashMoves(CashMoveId),
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollPayments_CreatedAt DEFAULT (SYSUTCDATETIME()),
    Revision                ROWVERSION NOT NULL
);
GO

-- -----------------------------------------------------------------------------
-- 9. SEGUIMIENTO DE OBLIGACIONES INSTITUCIONALES (dbo.PayrollInstitutionalObligations)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollInstitutionalObligations', N'U') IS NULL
CREATE TABLE dbo.PayrollInstitutionalObligations
(
    ObligationId            NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollInstOblig PRIMARY KEY,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollInstOblig_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    EntityName              NVARCHAR(50)  NOT NULL, -- DGI_IR, INSS_LABORAL, INSS_PATRONAL, INATEC, PROVISIONES_PASIVO
    PeriodLabel             NVARCHAR(50)  NOT NULL,
    BaseAmount              DECIMAL(19,4) NOT NULL,
    PayableAmount           DECIMAL(19,4) NOT NULL,
    DueDate                 DATE          NOT NULL,
    Status                  NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollInstOblig_Status DEFAULT (N'calculada'),
    DeclarationReference    NVARCHAR(120) NULL,
    PaymentReceiptRef       NVARCHAR(200) NULL,
    PaidAt                  DATETIMEOFFSET(3) NULL,
    PaidByAppUserId         NVARCHAR(100) NULL CONSTRAINT FK_PayrollInstOblig_User FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    Notes                   NVARCHAR(500) NULL,
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollInstOblig_CreatedAt DEFAULT (SYSUTCDATETIME()),
    Revision                ROWVERSION NOT NULL
);
GO

-- -----------------------------------------------------------------------------
-- 10. ATENCIÓN AL TRABAJADOR: RECLAMOS SOBRE COMPROBANTE (dbo.PayrollReceiptTickets)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollReceiptTickets', N'U') IS NULL
CREATE TABLE dbo.PayrollReceiptTickets
(
    TicketId                NVARCHAR(100) NOT NULL CONSTRAINT PK_PayrollReceiptTickets PRIMARY KEY,
    PayrollItemId           NVARCHAR(100) NULL,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollTickets_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId),
    EmployeeId              NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollTickets_Emp FOREIGN KEY REFERENCES dbo.Employees(EmployeeId),
    TicketNumber            NVARCHAR(60)  NOT NULL CONSTRAINT UQ_PayrollTickets_Num UNIQUE,
    Subject                 NVARCHAR(200) NOT NULL,
    Description             NVARCHAR(1000) NOT NULL,
    Status                  NVARCHAR(30)  NOT NULL CONSTRAINT DF_PayrollTickets_Status DEFAULT (N'abierto'),
    ResolutionNotes         NVARCHAR(1000) NULL,
    AssignedToAppUserId     NVARCHAR(100) NULL CONSTRAINT FK_PayrollTickets_Assigned FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    ResolvedByAppUserId     NVARCHAR(100) NULL CONSTRAINT FK_PayrollTickets_Resolved FOREIGN KEY REFERENCES dbo.AppUsers(AppUserId),
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollTickets_CreatedAt DEFAULT (SYSUTCDATETIME()),
    ResolvedAt              DATETIMEOFFSET(3) NULL
);
GO

-- -----------------------------------------------------------------------------
-- 11. HISTORIAL Y TRAZABILIDAD DE EVENTOS DE NÓMINA (dbo.PayrollHistoryEvents)
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.PayrollHistoryEvents', N'U') IS NULL
CREATE TABLE dbo.PayrollHistoryEvents
(
    EventId                 BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PayrollHistoryEvents PRIMARY KEY,
    PayrollRunId            NVARCHAR(100) NOT NULL CONSTRAINT FK_PayrollHistory_Run FOREIGN KEY REFERENCES dbo.PayrollRuns(PayrollRunId) ON DELETE CASCADE,
    ActorId                 NVARCHAR(100) NOT NULL,
    ActorName               NVARCHAR(240) NOT NULL,
    EventType               NVARCHAR(40)  NOT NULL,
    PreviousStatus          NVARCHAR(30)  NULL,
    NewStatus               NVARCHAR(30)  NOT NULL,
    Description             NVARCHAR(1000) NOT NULL,
    CreatedAt               DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollHistory_CreatedAt DEFAULT (SYSUTCDATETIME())
);
GO

-- -----------------------------------------------------------------------------
-- 12. PROCEDIMIENTO ALMACENADO: LISTADO DE PLANILLAS (usp_GetPayrollRuns)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRuns
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.PayrollRunId AS id,
           r.Period AS period,
           r.PeriodType AS periodType,
           r.StartDate AS startDate,
           r.EndDate AS endDate,
           r.PaymentDate AS paymentDate,
           r.Status AS status,
           r.CalculationVersion AS calculationVersion,
           r.Gross AS grossTotal,
           r.InssLaboral AS inssLaboralTotal,
           r.IncomeTax AS incomeTaxTotal,
           r.OtherDeductionsTotal AS otherDeductionsTotal,
           (r.InssLaboral + r.IncomeTax + r.OtherDeductionsTotal) AS totalDeductions,
           r.Net AS netTotal,
           r.InssPatronal AS inssPatronalTotal,
           r.Inatec AS inatecTotal,
           r.AguinaldoProvTotal AS aguinaldoProvTotal,
           r.VacacionesProvTotal AS vacacionesProvTotal,
           r.IndemnizacionProvTotal AS indemnizacionProvTotal,
           r.EmployerCost AS employerCostTotal,
           r.ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
           r.PendingDiscrepancyTotal AS pendingDiscrepancyTotal,
           r.Actor AS preparedByName,
           r.PreparedAt AS preparedAt,
           r.CalculatedAt AS calculatedAt,
           r.ReviewedAt AS reviewedAt,
           r.ApprovedAt AS approvedAt,
           r.PaidAt AS paidAt,
           r.ReconciledAt AS reconciledAt,
           r.ClosedAt AS closedAt,
           (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
           (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'bloqueante' AND IsResolved = 0) AS blockingIssuesCount,
           (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'advertencia' AND IsResolved = 0) AS warningIssuesCount,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
           r.UpdatedAt AS updatedAt
    FROM dbo.PayrollRuns r
    ORDER BY r.StartDate DESC, r.CreatedAt DESC;
END;
GO

-- -----------------------------------------------------------------------------
-- 13. PROCEDIMIENTO ALMACENADO: CREAR BORRADOR DE PLANILLA (usp_CreatePayrollDraft)
-- -----------------------------------------------------------------------------
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
        THROW 50501, 'Ya existe una planilla activa para el mismo período.', 1;

    IF @StartDate > @EndDate
        THROW 50502, 'La fecha de inicio no puede ser posterior a la fecha de finalización.', 1;

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

        -- Poblar automáticamente trabajadores activos de la empresa
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
            CASE WHEN @PeriodType = N'quincenal' THEN 15.0 ELSE 30.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN 120.0 ELSE 240.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            0, 0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(e.Salary / 2.0, 2) ELSE e.Salary END,
            N'pendiente', N'transferencia_bancaria', N'no_generado'
        FROM dbo.Employees e
        WHERE e.EmploymentStatus = N'activo'
           OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate);

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'creacion', NULL, N'borrador',
            N'Planilla creada en estado borrador con selección inicial de colaboradores.'
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

-- -----------------------------------------------------------------------------
-- 14. PROCEDIMIENTO ALMACENADO: MOTOR DE CÁLCULO DE NÓMINA (usp_CalculatePayroll)
--     Aplica: Ley 185 (H.Extra recargo 100%, Provisiones 8.3333%),
--             Ley de Seguridad Social (INSS Lab 7%, Patronal 21.5%),
--             Ley 822 (IR progresivo anualizado LCT Art. 96), INATEC (2%)
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
                   SUM(CASE WHEN NoveltyType IN (N'deduccion_prestamo', N'otro_descuento') THEN Amount ELSE 0 END) AS TotalDed
            FROM dbo.PayrollNovelties
            WHERE EmployeeId = i.EmployeeId AND (PayrollRunId = @PayrollRunId OR PayrollRunId IS NULL)
              AND Status = N'autorizada'
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
            r.Net = ISNULL(t.NetTotal, 0),
            r.InssPatronal = ISNULL(t.InssPatTotal, 0),
            r.Inatec = ISNULL(t.InatecTotal, 0),
            r.AguinaldoProvTotal = ISNULL(t.AguiTotal, 0),
            r.VacacionesProvTotal = ISNULL(t.VacTotal, 0),
            r.IndemnizacionProvTotal = ISNULL(t.IndemTotal, 0),
            r.EmployerCost = ISNULL(t.CostTotal, 0),
            r.CalculationVersion = r.CalculationVersion + 1,
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

-- -----------------------------------------------------------------------------
-- 15. PROCEDIMIENTO ALMACENADO: TRANSICIÓN DE ESTADOS DE NÓMINA (usp_TransitionPayrollStatus)
--     Valida flujo: borrador -> calculada -> revisada -> aprobada -> pago_registrado -> conciliada -> cerrada
-- -----------------------------------------------------------------------------
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
            -- Registrar movimiento de salida en tesorería (Banco)
            DECLARE @CashId NVARCHAR(100) = N'cash-nom-' + @PayrollRunId;
            IF NOT EXISTS (SELECT 1 FROM dbo.CashMoves WHERE CashMoveId = @CashId)
            BEGIN
                INSERT INTO dbo.CashMoves (
                    CashMoveId, Account, CashAccountCode, MoveType, Amount, MoveDate, Concept, PayrollRunId
                )
                VALUES (
                    @CashId, N'banco', N'banco', N'salida', @NetTotal,
                    TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                    N'Dispersión y pago bancario de nómina de colaboradores período ' + @Period,
                    @PayrollRunId
                );
            END;

            UPDATE dbo.PayrollRuns
            SET Status = N'pago_registrado',
                PaidByAppUserId = @ActorId,
                PaidAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
                PaymentNotes = @Notes,
                CashMoveId = @CashId,
                ConfirmedPaymentsTotal = @NetTotal,
                PendingDiscrepancyTotal = 0,
                UpdatedAt = SYSUTCDATETIME()
            WHERE PayrollRunId = @PayrollRunId;

            UPDATE dbo.PayrollRunItems
            SET PaymentStatus = N'pagado',
                PaymentConfirmedAt = TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00')
            WHERE PayrollRunId = @PayrollRunId;
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

-- -----------------------------------------------------------------------------
-- 16. PROCEDIMIENTO ALMACENADO: OBTENER DETALLE DE TRABAJADORES (usp_GetPayrollRunItems)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRunItems
    @PayrollRunId NVARCHAR(100),
    @ActorId      NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT i.PayrollItemId AS id,
           i.EmployeeId AS employeeId,
           e.Name AS employeeName,
           i.PositionSnapshot AS position,
           i.AreaSnapshot AS area,
           i.BaseSalaryMonthly AS baseSalaryMonthly,
           i.PeriodDaysWorked AS daysWorked,
           i.PeriodHoursWorked AS hoursWorked,
           i.OrdinarySalary AS ordinarySalary,
           i.OvertimeHours AS overtimeHours,
           i.OvertimeAmount AS overtimeAmount,
           i.BonusesAmount AS bonusesAmount,
           i.CommissionsAmount AS commissionsAmount,
           i.VacationDisfruteAmount AS vacationDisfruteAmount,
           i.OtherTaxableIncome AS otherTaxableIncome,
           i.Gross AS grossIncome,
           i.InssBase AS inssBase,
           i.InssLaboral AS inssLaboral,
           i.IrBase AS irBase,
           i.IncomeTax AS incomeTax,
           i.OtherDeductions AS otherDeductions,
           i.TotalDeductions AS totalDeductions,
           i.Net AS netPay,
           i.InssPatronal AS inssPatronal,
           i.Inatec AS inatec,
           i.Aguinaldo AS aguinaldoProv,
           i.VacacionesProv AS vacacionesProv,
           i.IndemnizacionProv AS indemnizacionProv,
           i.EmployerCost AS employerCost,
           i.PaymentStatus AS paymentStatus,
           i.PaymentMethod AS paymentMethod,
           i.PaymentReference AS paymentReference,
           i.CalculationExplanationJson AS explanationJson,
           i.ReceiptStatus AS receiptStatus,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), i.Revision), 1) AS revision
    FROM dbo.PayrollRunItems i
    JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
    WHERE i.PayrollRunId = @PayrollRunId
    ORDER BY e.Name ASC;
END;
GO

-- -----------------------------------------------------------------------------
-- 17. PROCEDIMIENTO ALMACENADO: COMPROBANTE DE PAGO INDIVIDUAL (usp_GetPayrollEmployeeReceipt)
--     Seguridad estricta: un colaborador solo puede ver su propia colilla
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollEmployeeReceipt
    @PayrollRunId NVARCHAR(100),
    @EmployeeId   NVARCHAR(100),
    @ActorId      NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsManagement BIT = 0;
    IF EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1
          AND (Hierarchy = N'superadmin' OR (Hierarchy = N'administrador' AND EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area IN (N'rrhh', N'finanzas', N'contabilidad')
          )))
    )
        SET @IsManagement = 1;

    -- Si no es administrativo, verificar que el empleado esté vinculado a la cuenta del actor
    IF @IsManagement = 0
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM dbo.Employees
            WHERE EmployeeId = @EmployeeId AND AppUserId = @ActorId
        )
            THROW 50517, 'No tienes autorización para consultar el comprobante de pago de otro colaborador.', 1;
    END;

    SELECT i.PayrollItemId AS receiptNumber,
           r.Period AS period,
           r.PeriodType AS periodType,
           r.StartDate AS startDate,
           r.EndDate AS endDate,
           r.PaymentDate AS paymentDate,
           r.Status AS runStatus,
           e.EmployeeId AS employeeId,
           e.Name AS employeeName,
           i.PositionSnapshot AS position,
           i.AreaSnapshot AS area,
           e.HireDate AS hireDate,
           i.BaseSalaryMonthly AS baseSalaryMonthly,
           i.PeriodDaysWorked AS daysWorked,
           i.PeriodHoursWorked AS hoursWorked,
           i.OrdinarySalary AS ordinarySalary,
           i.OvertimeHours AS overtimeHours,
           i.OvertimeAmount AS overtimeAmount,
           i.BonusesAmount AS bonusesAmount,
           i.CommissionsAmount AS commissionsAmount,
           i.VacationDisfruteAmount AS vacationDisfruteAmount,
           i.OtherTaxableIncome AS otherTaxableIncome,
           i.Gross AS grossTotal,
           i.InssLaboral AS inssLaboral,
           i.IncomeTax AS incomeTax,
           i.OtherDeductions AS otherDeductions,
           i.TotalDeductions AS totalDeductions,
           i.Net AS netPay,
           i.PaymentStatus AS paymentStatus,
           i.PaymentMethod AS paymentMethod,
           i.PaymentReference AS paymentReference,
           i.PaymentConfirmedAt AS paymentConfirmedAt,
           i.CalculationExplanationJson AS explanationJson,
           N'Raquel_Schema_Check_20261025_99ef80cc S.A. - RUC J0310000123456' AS employerInfo
    FROM dbo.PayrollRunItems i
    JOIN dbo.PayrollRuns r ON r.PayrollRunId = i.PayrollRunId
    JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
    WHERE i.PayrollRunId = @PayrollRunId AND i.EmployeeId = @EmployeeId;
END;
GO

-- -----------------------------------------------------------------------------
-- 18. PROCEDIMIENTO ALMACENADO: GESTIÓN DE NOVEDADES (usp_UpsertPayrollNovelty)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_UpsertPayrollNovelty
    @NoveltyId          NVARCHAR(100),
    @PayrollRunId       NVARCHAR(100) = NULL,
    @EmployeeId         NVARCHAR(100),
    @NoveltyType        NVARCHAR(40),
    @Concept            NVARCHAR(240),
    @Amount             DECIMAL(19,4),
    @Hours              DECIMAL(9,2) = NULL,
    @LegalJustification NVARCHAR(500) = NULL,
    @DocReference       NVARCHAR(300) = NULL,
    @PeriodDate         DATE,
    @ActorId            NVARCHAR(100)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    IF @Amount <= 0
        THROW 50518, 'El importe de la novedad debe ser mayor que cero.', 1;

    MERGE dbo.PayrollNovelties AS target
    USING (VALUES (@NoveltyId, @PayrollRunId, @EmployeeId, @NoveltyType, @Concept, @Amount, @Hours, @LegalJustification, @DocReference, @PeriodDate, @ActorId))
       AS src (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, ActorId)
    ON (target.NoveltyId = src.NoveltyId)
    WHEN MATCHED THEN
        UPDATE SET target.PayrollRunId = src.PayrollRunId, target.EmployeeId = src.EmployeeId,
                   target.NoveltyType = src.NoveltyType, target.Concept = src.Concept,
                   target.Amount = src.Amount, target.Hours = src.Hours,
                   target.LegalJustification = src.LegalJustification, target.DocReference = src.DocReference,
                   target.PeriodDate = src.PeriodDate
    WHEN NOT MATCHED THEN
        INSERT (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, Status, CreatedByAppUserId, AuthorizedByAppUserId, AuthorizedAt)
        VALUES (src.NoveltyId, src.PayrollRunId, src.EmployeeId, src.NoveltyType, src.Concept, src.Amount, src.Hours, src.LegalJustification, src.DocReference, src.PeriodDate, N'autorizada', src.ActorId, src.ActorId, SYSUTCDATETIME());

    SELECT NoveltyId AS id, Concept AS concept, Amount AS amount, Status AS status
    FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;
END;
GO

-- -----------------------------------------------------------------------------
-- 19. PROCEDIMIENTO ALMACENADO: REPORTES Y AGREGACIONES (usp_GetPayrollReports)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollReports
    @ReportType   NVARCHAR(50), -- 'resumen_periodo', 'costos_proyecto', 'obligaciones', 'comparativa'
    @PayrollRunId NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @ReportType = N'resumen_periodo'
    BEGIN
        SELECT r.Period AS period, r.StartDate AS startDate, r.EndDate AS endDate,
               COUNT(i.EmployeeId) AS workersCount,
               SUM(i.Gross) AS totalGross,
               SUM(i.InssLaboral) AS totalInssLaboral,
               SUM(i.IncomeTax) AS totalIncomeTax,
               SUM(i.OtherDeductions) AS totalOtherDeductions,
               SUM(i.Net) AS totalNetPay,
               SUM(i.InssPatronal) AS totalInssPatronal,
               SUM(i.Inatec) AS totalInatec,
               SUM(i.Aguinaldo + i.VacacionesProv + i.IndemnizacionProv) AS totalProvisiones,
               SUM(i.EmployerCost) AS totalEmployerCost
        FROM dbo.PayrollRuns r
        LEFT JOIN dbo.PayrollRunItems i ON i.PayrollRunId = r.PayrollRunId
        WHERE (@PayrollRunId IS NULL OR r.PayrollRunId = @PayrollRunId)
        GROUP BY r.PayrollRunId, r.Period, r.StartDate, r.EndDate
        ORDER BY r.StartDate DESC;
    END
    ELSE IF @ReportType = N'por_area'
    BEGIN
        SELECT i.AreaSnapshot AS area,
               COUNT(i.EmployeeId) AS countEmployees,
               SUM(i.Gross) AS totalGross,
               SUM(i.InssLaboral) AS totalInssLaboral,
               SUM(i.IncomeTax) AS totalIncomeTax,
               SUM(i.Net) AS totalNet,
               SUM(i.EmployerCost) AS totalCost
        FROM dbo.PayrollRunItems i
        WHERE (@PayrollRunId IS NULL OR i.PayrollRunId = @PayrollRunId)
        GROUP BY i.AreaSnapshot
        ORDER BY totalCost DESC;
    END
    ELSE IF @ReportType = N'obligaciones'
    BEGIN
        SELECT EntityName AS entity, PeriodLabel AS period, BaseAmount AS base,
               PayableAmount AS payable, DueDate AS dueDate, Status AS status,
               PaymentReceiptRef AS receiptRef
        FROM dbo.PayrollInstitutionalObligations
        WHERE (@PayrollRunId IS NULL OR PayrollRunId = @PayrollRunId)
        ORDER BY DueDate ASC;
    END
    ELSE IF @ReportType = N'costos_proyecto'
    BEGIN
        SELECT p.Code AS projectCode, p.Name AS projectName,
               COUNT(DISTINCT d.EmployeeId) AS employeesAssigned,
               SUM(d.HoursAllocated) AS totalHours,
               SUM(d.CostAllocated) AS totalCostAllocated
        FROM dbo.PayrollProjectDistributions d
        JOIN dbo.Projects p ON p.ProjectId = d.ProjectId
        WHERE (@PayrollRunId IS NULL OR d.PayrollRunId = @PayrollRunId)
        GROUP BY p.Code, p.Name
        ORDER BY totalCostAllocated DESC;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 20. PROCEDIMIENTO ALMACENADO: GESTIÓN DE TICKETS DE COLILLAS (usp_CreatePayrollReceiptTicket)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CreatePayrollReceiptTicket
    @TicketId       NVARCHAR(100),
    @PayrollRunId   NVARCHAR(100),
    @EmployeeId     NVARCHAR(100),
    @Subject        NVARCHAR(200),
    @Description    NVARCHAR(1000),
    @ActorId        NVARCHAR(100)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TicketNumber NVARCHAR(60) = N'TCK-NOM-' + RIGHT(CONVERT(VARCHAR(36), NEWID()), 8);

    INSERT INTO dbo.PayrollReceiptTickets (
        TicketId, PayrollRunId, EmployeeId, TicketNumber, Subject, Description, Status
    )
    VALUES (
        @TicketId, @PayrollRunId, @EmployeeId, @TicketNumber, @Subject, @Description, N'abierto'
    );

    SELECT TicketId AS id, TicketNumber AS ticketNumber, Subject AS subject, Status AS status, CreatedAt AS createdAt
    FROM dbo.PayrollReceiptTickets
    WHERE TicketId = @TicketId;
END;
GO

-- -----------------------------------------------------------------------------
-- 21. PERMISOS DE ACCESO PARA raquel_erp_app
-- -----------------------------------------------------------------------------
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollRulesCatalog TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollRuns TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollRunItems TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollNovelties TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollValidations TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollProjectDistributions TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollPayments TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollInstitutionalObligations TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollReceiptTickets TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.PayrollHistoryEvents TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.AccountingEntries TO [raquel_erp_app];
    GRANT SELECT, INSERT, UPDATE, DELETE ON OBJECT::dbo.CashMoves TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.ChartOfAccounts TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.Employees TO [raquel_erp_app];
    GRANT SELECT ON OBJECT::dbo.AppUsers TO [raquel_erp_app];

    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollRuns TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreatePayrollDraft TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CalculatePayroll TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_TransitionPayrollStatus TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollRunItems TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollEmployeeReceipt TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_UpsertPayrollNovelty TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollReports TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreatePayrollReceiptTicket TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 15/25: 07_procedimiento_sincronizacion.sql */
/* 07 — Guarda el JSON del ERP y normaliza las 19 colecciones en tablas + FKs */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
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

        IF OBJECT_ID(N'dbo.PayrollRuns', N'U') IS NOT NULL
            UPDATE dbo.PayrollRuns SET AccountingEntryId = NULL, CashMoveId = NULL;

        IF OBJECT_ID(N'dbo.PayrollPayments', N'U') IS NOT NULL
            UPDATE dbo.PayrollPayments SET CashMoveId = NULL;

        IF OBJECT_ID(N'dbo.Projects', N'U') IS NOT NULL
            UPDATE dbo.Projects SET ClientPartyId = NULL, OwnerEmployeeId = NULL;

        DELETE FROM dbo.AccountsReceivable;
        DELETE FROM dbo.AccountsPayable;
        DELETE FROM dbo.AccountingEntries;
        DELETE FROM dbo.FinanceMoves;
        DELETE FROM dbo.CashMoves;
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

SELECT OBJECT_ID(N'dbo.usp_SaveErpState', N'P') AS save_procedure_id;
GO

GO

/* ARCHIVO 16/25: 25_mejoras_gestion_talento_humano_y_nomina.sql */
-- =============================================================================
-- EMPRESA: INSTALACIONES RAQUEL S.A.
-- SISTEMA: ERP INTEGRAL DE ALUMNIO Y VIDRIO
-- MÓDULO:  TALENTO HUMANO Y NÓMINA (MEJORAS OPERATIVAS E INTERACTIVIDAD)
-- SCRIPT:  25_mejoras_gestion_talento_humano_y_nomina.sql
-- OBJETIVO: Procedimientos específicos para incluir/retirar trabajadores en planillas,
--           gestionar novedades, registrar pagos con evidencia y registrar
--           capacitaciones y acciones correctivas de seguridad (Ley 618).
-- =============================================================================

USE [Raquel_Schema_Check_20261025_99ef80cc];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- -----------------------------------------------------------------------------
-- 1. PROCEDIMIENTO: INCLUIR TRABAJADOR EN PLANILLA (EN ESTADO BORRADOR)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_AddWorkerToPayrollRun
    @PayrollRunId   NVARCHAR(100),
    @EmployeeId     NVARCHAR(100),
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240),
    @Reason         NVARCHAR(500) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunStatus NVARCHAR(30);
    DECLARE @PeriodType NVARCHAR(30);
    DECLARE @StartDate DATE;

    SELECT @RunStatus = Status, @PeriodType = PeriodType, @StartDate = StartDate
    FROM dbo.PayrollRuns
    WHERE PayrollRunId = @PayrollRunId;

    IF @RunStatus IS NULL
        THROW 50520, 'La planilla especificada no existe.', 1;

    IF @RunStatus <> N'borrador'
        THROW 50521, 'Solo se pueden agregar colaboradores a una planilla en estado Borrador.', 1;

    IF EXISTS (
        SELECT 1 FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId
    )
        THROW 50522, 'El colaborador ya se encuentra incluido en esta planilla.', 1;

    DECLARE @EmpName NVARCHAR(240), @Position NVARCHAR(200), @Area NVARCHAR(120), @Salary DECIMAL(19,4);
    SELECT @EmpName = Name, @Position = Position, @Area = Area, @Salary = Salary
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;

    IF @EmpName IS NULL
        THROW 50523, 'El expediente de colaborador no existe en Talento Humano.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.PayrollRunItems (
            PayrollRunId, EmployeeId, PayrollItemId, PositionSnapshot, AreaSnapshot,
            BaseSalaryMonthly, PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary,
            OvertimeHours, OvertimeAmount, BonusesAmount, CommissionsAmount,
            VacationDisfruteAmount, OtherTaxableIncome, Gross,
            InssBase, InssLaboral, IrBase, IncomeTax, OtherDeductions, TotalDeductions, Net,
            InssPatronal, Inatec, Aguinaldo, VacacionesProv, IndemnizacionProv, EmployerCost,
            PaymentStatus, PaymentMethod, ReceiptStatus
        )
        VALUES (
            @PayrollRunId,
            @EmployeeId,
            @PayrollRunId + N'-' + @EmployeeId,
            @Position,
            @Area,
            @Salary,
            CASE WHEN @PeriodType = N'quincenal' THEN 15.0 ELSE 30.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN 120.0 ELSE 240.0 END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            0, 0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            0, 0, 0, 0, 0,
            CASE WHEN @PeriodType = N'quincenal' THEN ROUND(@Salary / 2.0, 2) ELSE @Salary END,
            N'pendiente', N'transferencia_bancaria', N'no_generado'
        );

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType,
            PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'trabajador_incluido',
            @RunStatus, @RunStatus,
            N'Colaborador ' + @EmpName + N' (' + @EmployeeId + N') incluido en planilla. ' + COALESCE(@Reason, N'')
        );

        COMMIT TRANSACTION;

        SELECT PayrollItemId AS id, EmployeeId AS employeeId, @EmpName AS employeeName,
               PositionSnapshot AS position, AreaSnapshot AS area, Gross AS grossIncome, Net AS netPay
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. PROCEDIMIENTO: RETIRAR TRABAJADOR DE PLANILLA (EN ESTADO BORRADOR)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_RemoveWorkerFromPayrollRun
    @PayrollRunId   NVARCHAR(100),
    @EmployeeId     NVARCHAR(100),
    @ActorId        NVARCHAR(100),
    @ActorName      NVARCHAR(240),
    @Reason         NVARCHAR(500) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunStatus NVARCHAR(30);
    SELECT @RunStatus = Status
    FROM dbo.PayrollRuns
    WHERE PayrollRunId = @PayrollRunId;

    IF @RunStatus IS NULL
        THROW 50524, 'La planilla especificada no existe.', 1;

    IF @RunStatus <> N'borrador'
        THROW 50525, 'Solo se pueden retirar colaboradores de una planilla en estado Borrador.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId
    )
        THROW 50526, 'El colaborador no forma parte de esta planilla.', 1;

    DECLARE @EmpName NVARCHAR(240);
    SELECT @EmpName = Name FROM dbo.Employees WHERE EmployeeId = @EmployeeId;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType,
            PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'trabajador_retirado',
            @RunStatus, @RunStatus,
            N'Colaborador ' + COALESCE(@EmpName, @EmployeeId) + N' retirado de la nómina. Motivo: ' + COALESCE(@Reason, N'Ajuste administrativo')
        );

        COMMIT TRANSACTION;

        SELECT @EmployeeId AS removedEmployeeId, @PayrollRunId AS payrollRunId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. PROCEDIMIENTO: ELIMINAR / CANCELAR NOVEDAD Y MARCAR CÁLCULO COMO DESACTUALIZADO
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_DeletePayrollNovelty
    @NoveltyId  NVARCHAR(100),
    @ActorId    NVARCHAR(100),
    @ActorName  NVARCHAR(240),
    @Reason     NVARCHAR(500) = NULL
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunId NVARCHAR(100);
    DECLARE @RunStatus NVARCHAR(30);
    DECLARE @Concept NVARCHAR(240);

    SELECT @RunId = n.PayrollRunId, @Concept = n.Concept, @RunStatus = r.Status
    FROM dbo.PayrollNovelties n
    LEFT JOIN dbo.PayrollRuns r ON r.PayrollRunId = n.PayrollRunId
    WHERE n.NoveltyId = @NoveltyId;

    IF @Concept IS NULL
        THROW 50527, 'La novedad indicada no existe.', 1;

    IF @RunStatus IS NOT NULL AND @RunStatus NOT IN (N'borrador', N'calculada')
        THROW 50528, 'No se pueden cancelar novedades de una planilla revisada o aprobada.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;

        -- Si la planilla estaba calculada, volver a borrador para obligar recálculo transparente
        IF @RunStatus = N'calculada'
        BEGIN
            UPDATE dbo.PayrollRuns
            SET Status = N'borrador'
            WHERE PayrollRunId = @RunId;

            INSERT INTO dbo.PayrollHistoryEvents (
                PayrollRunId, ActorId, ActorName, EventType,
                PreviousStatus, NewStatus, Description
            )
            VALUES (
                @RunId, @ActorId, @ActorName, N'recalculo_requerido',
                N'calculada', N'borrador',
                N'Cálculo marcado como desactualizado tras eliminar la novedad: ' + @Concept
            );
        END;

        COMMIT TRANSACTION;

        SELECT @NoveltyId AS deletedNoveltyId, @RunId AS payrollRunId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. PROCEDIMIENTO: REGISTRAR PAGO Y DISPERSIÓN DE PLANILLA (CON EVIDENCIA)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PayrollRunId       NVARCHAR(100),
    @Amount             DECIMAL(19,4),
    @PaymentMethod      NVARCHAR(60),
    @PaymentReference   NVARCHAR(120),
    @PaymentDate        DATE,
    @Notes              NVARCHAR(1000) = NULL,
    @ActorId            NVARCHAR(100),
    @ActorName          NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @NetTotal DECIMAL(19,4);

    SELECT @CurrentStatus = Status, @NetTotal = Net
    FROM dbo.PayrollRuns
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50529, 'La planilla indicada no existe.', 1;

    IF @CurrentStatus <> N'aprobada' AND @CurrentStatus <> N'pago_registrado'
        THROW 50530, 'Solo se puede registrar pago en planillas que han sido formalmente aprobadas.', 1;

    IF @Amount <= 0
        THROW 50531, 'El monto del pago debe ser mayor a cero.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Actualizar todos los ítems de los trabajadores a 'pagado'
        UPDATE dbo.PayrollRunItems
        SET PaymentStatus = N'pagado',
            PaymentMethod = @PaymentMethod,
            PaymentConfirmedAt = TODATETIMEOFFSET(CONVERT(DATETIME2, @PaymentDate), N'+00:00')
        WHERE PayrollRunId = @PayrollRunId;

        -- Actualizar cabecera de la planilla
        UPDATE dbo.PayrollRuns
        SET Status = N'pago_registrado',
            PaidAt = TODATETIMEOFFSET(CONVERT(DATETIME2, @PaymentDate), N'+00:00'),
            ConfirmedPaymentsTotal = @Amount,
            Notes = COALESCE(Notes, N'') + NCHAR(13) + NCHAR(10) +
                    N'[Dispersión confirmada: Ref. ' + @PaymentReference + N' por C$ ' + CONVERT(NVARCHAR(30), @Amount) +
                    N' vía ' + @PaymentMethod + N' el ' + CONVERT(NVARCHAR(10), @PaymentDate) + N']'
        WHERE PayrollRunId = @PayrollRunId;

        -- Trazabilidad de auditoría
        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType,
            PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'pago_registrado',
            @CurrentStatus, N'pago_registrado',
            N'Dispersión de nómina registrada por C$ ' + CONVERT(NVARCHAR(30), @Amount) +
            N'. Método: ' + @PaymentMethod + N' · Ref: ' + @PaymentReference + N'. ' + COALESCE(@Notes, N'')
        );

        COMMIT TRANSACTION;

        SELECT PayrollRunId AS id, Status AS status, ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
               PaidAt AS paidAt
        FROM dbo.PayrollRuns
        WHERE PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- -----------------------------------------------------------------------------
-- 5. PROCEDIMIENTO: REGISTRAR CAPACITACIÓN DE SEGURIDAD (LEY 618)
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrTraining
    @Topic          NVARCHAR(200),
    @Instructor     NVARCHAR(200),
    @TrainingDate   DATE,
    @Hours          INT,
    @LegalRef       NVARCHAR(100) = N'Ley 618 Arto. 18',
    @TargetArea     NVARCHAR(100) = N'Taller y Montaje',
    @Status         NVARCHAR(30) = N'completada',
    @ActorId        NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TrainingId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.HrSafetyTrainings (
        TrainingId, Topic, Instructor, TrainingDate, Hours,
        LegalRef, TargetArea, Status
    )
    OUTPUT inserted.TrainingId AS id, inserted.Topic AS topic, inserted.TrainingDate AS trainingDate, inserted.Status AS status
    VALUES (
        @TrainingId, @Topic, @Instructor, @TrainingDate, @Hours,
        @LegalRef, @TargetArea, @Status
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 6. PROCEDIMIENTO: REGISTRAR ACCIÓN CORRECTIVA DE SEGURIDAD
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.usp_CreateHrCorrectiveAction
    @Description        NVARCHAR(1000),
    @ResponsibleName    NVARCHAR(200),
    @DueDate            DATE,
    @Status             NVARCHAR(30) = N'abierta',
    @ActorId            NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ActionId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO dbo.HrCorrectiveActions (
        ActionId, Description, ResponsibleName, DueDate, Status
    )
    OUTPUT inserted.ActionId AS id, inserted.Description AS description, inserted.DueDate AS dueDate, inserted.Status AS status
    VALUES (
        @ActionId, @Description, @ResponsibleName, @DueDate, @Status
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 7. OTORGAR PERMISOS AL ROL DE APLICACIÓN
-- -----------------------------------------------------------------------------
IF USER_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_AddWorkerToPayrollRun TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RemoveWorkerFromPayrollRun TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_DeletePayrollNovelty TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RegisterPayrollPayment TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrTraining TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CreateHrCorrectiveAction TO [raquel_erp_app];
END;
GO

PRINT 'Migración 25 (Mejoras operativas de Talento Humano y Nómina) ejecutada con éxito.';
GO

GO

/* ARCHIVO 17/25: 25_operaciones_hr_nomina.sql */
/* 25 - Operaciones reales de Talento Humano y Nómina (conserva datos existentes) */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH(N'dbo.Employees', N'LaborCondition') IS NULL
    ALTER TABLE dbo.Employees ADD LaborCondition NVARCHAR(40) NOT NULL CONSTRAINT DF_Employees_LaborCondition DEFAULT (N'permanente');
GO

IF COL_LENGTH(N'dbo.PayrollRuns', N'CalculationStale') IS NULL
    ALTER TABLE dbo.PayrollRuns ADD CalculationStale BIT NOT NULL CONSTRAINT DF_PayrollRuns_CalcStale DEFAULT (0);
GO

IF COL_LENGTH(N'dbo.HrContracts', N'ParentContractId') IS NULL
    ALTER TABLE dbo.HrContracts ADD ParentContractId UNIQUEIDENTIFIER NULL;
GO
IF COL_LENGTH(N'dbo.HrContracts', N'VersionNumber') IS NULL
    ALTER TABLE dbo.HrContracts ADD VersionNumber INT NOT NULL CONSTRAINT DF_HrContracts_Version DEFAULT (1);
GO

IF COL_LENGTH(N'dbo.HrAttendanceRecords', N'CorrectionRequestedIn') IS NULL
    ALTER TABLE dbo.HrAttendanceRecords ADD CorrectionRequestedIn TIME(0) NULL;
IF COL_LENGTH(N'dbo.HrAttendanceRecords', N'CorrectionRequestedOut') IS NULL
    ALTER TABLE dbo.HrAttendanceRecords ADD CorrectionRequestedOut TIME(0) NULL;
GO

IF OBJECT_ID(N'dbo.PayrollNoveltyEvents', N'U') IS NULL
CREATE TABLE dbo.PayrollNoveltyEvents
(
    EventId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PayrollNoveltyEvents PRIMARY KEY,
    NoveltyId NVARCHAR(100) NOT NULL,
    ActorId NVARCHAR(100) NOT NULL,
    ActorName NVARCHAR(240) NOT NULL,
    EventType NVARCHAR(40) NOT NULL,
    Detail NVARCHAR(1000) NULL,
    OccurredAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollNoveltyEvents_At DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'))
);
GO

CREATE OR ALTER VIEW dbo.vw_HrEmployeeDirectory
AS
    SELECT employee.EmployeeId, employee.Name, employee.Position, employee.Area,
           employee.HireDate, employee.EmploymentStatus, employee.AppUserId,
           employee.DismissalDate, employee.DismissalReason, employee.LaborCondition,
           CASE WHEN employee.AppUserId IS NULL THEN NULL ELSE appUser.IsActive END AS AccountActive
    FROM dbo.Employees AS employee
    LEFT JOIN dbo.AppUsers AS appUser ON appUser.AppUserId = employee.AppUserId;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CreateHrEmployee
    @MutationId UNIQUEIDENTIFIER,
    @EmployeeId NVARCHAR(100),
    @Name NVARCHAR(240),
    @Position NVARCHAR(200),
    @Salary DECIMAL(19,4),
    @Area NVARCHAR(120),
    @AppUserId NVARCHAR(100) = NULL,
    @HireDate DATE,
    @LaborCondition NVARCHAR(40) = N'permanente',
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers
        WHERE AppUserId = @ActorId AND IsActive = 1 AND MustChangePassword = 0
          AND (Hierarchy = N'superadmin' OR EXISTS (
              SELECT 1 FROM dbo.AppUserAreas WHERE AppUserId = @ActorId AND Area = N'rrhh'
          ))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50434, 'Se requiere autorización de administración de Talento humano.', 1;
    END;

    IF @AppUserId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.AppUsers WHERE AppUserId = @AppUserId AND IsActive = 1
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50435, 'La cuenta vinculada no existe o está inactiva.', 1;
    END;

    IF NULLIF(LTRIM(RTRIM(@Name)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Position)), N'') IS NULL
       OR NULLIF(LTRIM(RTRIM(@Area)), N'') IS NULL
       OR @Salary IS NULL OR @Salary <= 0
       OR @HireDate IS NULL OR @HireDate > CONVERT(DATE, SYSUTCDATETIME())
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50443, 'Los datos del expediente no son válidos.', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM dbo.Employees
        WHERE LOWER(LTRIM(RTRIM(Name))) = LOWER(LTRIM(RTRIM(@Name)))
          AND HireDate = @HireDate
          AND EmploymentStatus <> N'baja'
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50452, 'Ya existe un expediente activo con el mismo nombre y fecha de ingreso.', 1;
    END;

    DECLARE @ExistingEmployeeId NVARCHAR(100);
    SELECT @ExistingEmployeeId = EmployeeId
    FROM dbo.HrEmployeeCreations WITH (UPDLOCK, HOLDLOCK)
    WHERE MutationId = @MutationId;

    IF @ExistingEmployeeId IS NOT NULL
    BEGIN
        COMMIT TRANSACTION;
        SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
               HireDate AS hireDate, EmploymentStatus AS employmentStatus, LaborCondition AS laborCondition,
               CAST(NULL AS BIT) AS accountActive, CAST(0 AS BIT) AS wasCreated
        FROM dbo.Employees
        WHERE EmployeeId = @ExistingEmployeeId;
        RETURN;
    END;

    INSERT INTO dbo.Employees (
        EmployeeId, Name, Position, Salary, Area, AppUserId, HireDate, IsActive, EmploymentStatus, LaborCondition
    )
    VALUES (
        @EmployeeId, @Name, @Position, @Salary, @Area, @AppUserId, @HireDate, 1, N'activo', ISNULL(@LaborCondition, N'permanente')
    );

    INSERT INTO dbo.EmployeeJobHistory (
        EmployeeJobHistoryId, EmployeeId, Position, Area, Salary, ValidFrom, ChangedByAppUserId
    )
    VALUES (
        NEWID(), @EmployeeId, @Position, @Area, @Salary, @HireDate, @ActorId
    );

    INSERT INTO dbo.HrEmployeeCreations (MutationId, EmployeeId, CreatedByAppUserId)
    VALUES (@MutationId, @EmployeeId, @ActorId);

    INSERT INTO dbo.AuditEvents (
        AuditEventId, OccurredAt, UserName, AppUserId, Action, Module, Detail, Severity, Reference
    )
    SELECT
        CONVERT(NVARCHAR(36), NEWID()), TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00'),
        LEFT(actor.Name, 200), actor.AppUserId, N'crear expediente de personal', N'rrhh',
        CONCAT(N'Expediente ', @EmployeeId, N' creado; el contrato se registra en un paso separado.'), N'info', @EmployeeId
    FROM dbo.AppUsers AS actor
    WHERE actor.AppUserId = @ActorId;

    COMMIT TRANSACTION;
    SELECT EmployeeId AS id, Name AS name, Position AS position, Area AS area,
           HireDate AS hireDate, EmploymentStatus AS employmentStatus, LaborCondition AS laborCondition,
           CAST(NULL AS BIT) AS accountActive, CAST(1 AS BIT) AS wasCreated
    FROM dbo.Employees
    WHERE EmployeeId = @EmployeeId;
END;
GO

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
        THROW 50501, 'Ya existe una planilla activa para el mismo período.', 1;

    IF @StartDate > @EndDate
        THROW 50502, 'La fecha de inicio no puede ser posterior a la fecha de finalización.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.PayrollRuns (
            PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate,
            Actor, ActorUserId, Status, CalculationVersion, CalculationStale,
            Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost,
            OtherDeductionsTotal, AguinaldoProvTotal, VacacionesProvTotal, IndemnizacionProvTotal,
            ConfirmedPaymentsTotal, PendingDiscrepancyTotal,
            PreparedByAppUserId, PreparedAt, Notes
        )
        VALUES (
            @PayrollRunId, @Period, @PeriodType, @StartDate, @EndDate, @PaymentDate,
            @ActorName, @ActorId, N'borrador', 1, 1,
            0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0,
            @ActorId, SYSUTCDATETIME(), @Notes
        );

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'creacion', NULL, N'borrador',
            N'Planilla creada en borrador. No registra pago. Agregue trabajadores elegibles desde Talento humano.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.Gross AS grossTotal, r.Net AS netTotal,
               CAST(0 AS INT) AS workersCount,
               CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
               CAST(1 AS BIT) AS calculationStale
        FROM dbo.PayrollRuns r
        WHERE r.PayrollRunId = @PayrollRunId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollEligibleEmployees
    @PayrollRunId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartDate DATE, @EndDate DATE;
    SELECT @StartDate = StartDate, @EndDate = EndDate
    FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId;

    SELECT e.EmployeeId AS id, e.Name AS name, e.Position AS position, e.Area AS area,
           e.EmploymentStatus AS employmentStatus, e.Salary AS salary,
           e.HireDate AS hireDate, e.DismissalDate AS dismissalDate
    FROM dbo.Employees e
    WHERE NOT EXISTS (
            SELECT 1 FROM dbo.PayrollRunItems i
            WHERE i.PayrollRunId = @PayrollRunId AND i.EmployeeId = e.EmployeeId
        )
      AND e.HireDate <= @EndDate
      AND (
            e.EmploymentStatus IN (N'activo', N'licencia')
            OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate)
          )
    ORDER BY e.Name;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AddPayrollRunWorker
    @PayrollRunId NVARCHAR(100),
    @EmployeeId NVARCHAR(100),
    @Reason NVARCHAR(500),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Status NVARCHAR(30), @PeriodType NVARCHAR(30), @StartDate DATE, @EndDate DATE;
    SELECT @Status = Status, @PeriodType = PeriodType, @StartDate = StartDate, @EndDate = EndDate
    FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId;

    IF @Status IS NULL THROW 50503, 'La planilla no existe.', 1;
    IF @Status <> N'borrador' THROW 50521, 'Solo se pueden agregar trabajadores en estado borrador.', 1;
    IF EXISTS (SELECT 1 FROM dbo.PayrollRunItems WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId)
        THROW 50522, 'El trabajador ya está incluido en esta planilla.', 1;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.Employees e
        WHERE e.EmployeeId = @EmployeeId
          AND e.HireDate <= @EndDate
          AND (
                e.EmploymentStatus IN (N'activo', N'licencia')
                OR (e.DismissalDate IS NOT NULL AND e.DismissalDate >= @StartDate)
              )
    )
        THROW 50523, 'El trabajador no es elegible para este período.', 1;

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
        @PayrollRunId, e.EmployeeId, @PayrollRunId + N'-' + e.EmployeeId,
        e.Position, e.Area, e.Salary,
        CASE WHEN @PeriodType = N'quincenal' THEN 15.0 ELSE 30.0 END,
        CASE WHEN @PeriodType = N'quincenal' THEN 120.0 ELSE 240.0 END,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        N'pendiente', N'transferencia_bancaria', N'no_generado'
    FROM dbo.Employees e
    WHERE e.EmployeeId = @EmployeeId;

    UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @PayrollRunId;

    INSERT INTO dbo.PayrollHistoryEvents (
        PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
    )
    VALUES (
        @PayrollRunId, @ActorId, @ActorName, N'inclusion_trabajador', N'borrador', N'borrador',
        CONCAT(N'Se incluyó a ', @EmployeeId, N'. Motivo: ', ISNULL(@Reason, N'sin motivo'))
    );

    SELECT i.PayrollItemId AS id, i.EmployeeId AS employeeId, e.Name AS employeeName
    FROM dbo.PayrollRunItems i
    JOIN dbo.Employees e ON e.EmployeeId = i.EmployeeId
    WHERE i.PayrollRunId = @PayrollRunId AND i.EmployeeId = @EmployeeId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RemovePayrollRunWorker
    @PayrollRunId NVARCHAR(100),
    @EmployeeId NVARCHAR(100),
    @Reason NVARCHAR(500),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId AND Status = N'borrador')
        THROW 50521, 'Solo se pueden retirar trabajadores en estado borrador.', 1;

    DELETE FROM dbo.PayrollRunItems
    WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;

    UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @PayrollRunId;

    INSERT INTO dbo.PayrollHistoryEvents (
        PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
    )
    VALUES (
        @PayrollRunId, @ActorId, @ActorName, N'retiro_trabajador', N'borrador', N'borrador',
        CONCAT(N'Se retiró a ', @EmployeeId, N'. Motivo: ', ISNULL(@Reason, N'sin motivo'))
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PaymentId NVARCHAR(100),
    @PayrollRunId NVARCHAR(100),
    @EmployeeId NVARCHAR(100),
    @Amount DECIMAL(19,4),
    @PaymentMethod NVARCHAR(40),
    @TransactionReference NVARCHAR(120),
    @ManualConfirmationProof NVARCHAR(300) = NULL,
    @Status NVARCHAR(30),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RunStatus NVARCHAR(30), @Net DECIMAL(19,4);
    SELECT @RunStatus = Status FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId;
    IF @RunStatus IS NULL THROW 50503, 'La planilla no existe.', 1;
    IF @RunStatus NOT IN (N'aprobada', N'pago_registrado')
        THROW 50524, 'Solo se registran pagos cuando la planilla está aprobada o con pago en curso.', 1;
    IF @Amount <= 0 THROW 50525, 'El importe del pago debe ser mayor que cero.', 1;
    IF NULLIF(LTRIM(RTRIM(@TransactionReference)), N'') IS NULL
        THROW 50526, 'Indica una referencia documental o bancaria del pago.', 1;

    SELECT @Net = Net FROM dbo.PayrollRunItems WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;
    IF @Net IS NULL THROW 50527, 'El trabajador no pertenece a esta planilla.', 1;

    INSERT INTO dbo.PayrollPayments (
        PaymentId, PayrollRunId, EmployeeId, Amount, PaymentMethod, TransactionReference,
        Status, ConfirmedAt, ConfirmedByAppUserId, ManualConfirmationProof
    )
    VALUES (
        @PaymentId, @PayrollRunId, @EmployeeId, @Amount, @PaymentMethod, @TransactionReference,
        @Status,
        CASE WHEN @Status = N'confirmado' THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE NULL END,
        @ActorId, @ManualConfirmationProof
    );

    DECLARE @Paid DECIMAL(19,4) = (
        SELECT ISNULL(SUM(Amount), 0) FROM dbo.PayrollPayments
        WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId AND Status = N'confirmado'
    );

    UPDATE dbo.PayrollRunItems
    SET PaymentStatus = CASE
            WHEN @Status = N'fallido' AND @Paid = 0 THEN N'pendiente'
            WHEN @Paid >= Net THEN N'pagado'
            WHEN @Paid > 0 THEN N'parcial'
            ELSE N'pendiente'
        END,
        PaymentMethod = @PaymentMethod,
        PaymentReference = @TransactionReference,
        PaymentConfirmedAt = CASE WHEN @Paid >= Net THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE PaymentConfirmedAt END
    WHERE PayrollRunId = @PayrollRunId AND EmployeeId = @EmployeeId;

    UPDATE r
    SET r.ConfirmedPaymentsTotal = x.TotalPaid,
        r.PendingDiscrepancyTotal = CASE WHEN r.Net > x.TotalPaid THEN r.Net - x.TotalPaid ELSE 0 END,
        r.UpdatedAt = SYSUTCDATETIME()
    FROM dbo.PayrollRuns r
    CROSS APPLY (
        SELECT ISNULL(SUM(Amount), 0) AS TotalPaid
        FROM dbo.PayrollPayments p
        WHERE p.PayrollRunId = r.PayrollRunId AND p.Status = N'confirmado'
    ) x
    WHERE r.PayrollRunId = @PayrollRunId;

    INSERT INTO dbo.PayrollHistoryEvents (
        PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
    )
    VALUES (
        @PayrollRunId, @ActorId, @ActorName, N'registro_pago', @RunStatus, @RunStatus,
        CONCAT(N'Pago ', @Status, N' de C$ ', CONVERT(NVARCHAR(40), @Amount), N' para ', @EmployeeId, N'. Ref: ', @TransactionReference)
    );

    SELECT PaymentId AS id, Status AS status, Amount AS amount FROM dbo.PayrollPayments WHERE PaymentId = @PaymentId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRuns
    @ActorId NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT r.PayrollRunId AS id,
           r.Period AS period,
           r.PeriodType AS periodType,
           r.StartDate AS startDate,
           r.EndDate AS endDate,
           r.PaymentDate AS paymentDate,
           r.Status AS status,
           r.CalculationVersion AS calculationVersion,
           ISNULL(r.CalculationStale, 0) AS calculationStale,
           r.Gross AS grossTotal,
           r.InssLaboral AS inssLaboralTotal,
           r.IncomeTax AS incomeTaxTotal,
           r.OtherDeductionsTotal AS otherDeductionsTotal,
           (r.InssLaboral + r.IncomeTax + r.OtherDeductionsTotal) AS totalDeductions,
           r.Net AS netTotal,
           r.InssPatronal AS inssPatronalTotal,
           r.Inatec AS inatecTotal,
           r.AguinaldoProvTotal AS aguinaldoProvTotal,
           r.VacacionesProvTotal AS vacacionesProvTotal,
           r.IndemnizacionProvTotal AS indemnizacionProvTotal,
           r.EmployerCost AS employerCostTotal,
           r.ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
           r.PendingDiscrepancyTotal AS pendingDiscrepancyTotal,
           r.Actor AS preparedByName,
           r.PreparedAt AS preparedAt,
           r.CalculatedAt AS calculatedAt,
           r.ReviewedAt AS reviewedAt,
           r.ApprovedAt AS approvedAt,
           r.PaidAt AS paidAt,
           r.ReconciledAt AS reconciledAt,
           r.ClosedAt AS closedAt,
           (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
           (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'bloqueante' AND IsResolved = 0) AS blockingIssuesCount,
           (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'advertencia' AND IsResolved = 0) AS warningIssuesCount,
           CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
           r.UpdatedAt AS updatedAt
    FROM dbo.PayrollRuns r
    ORDER BY r.StartDate DESC, r.CreatedAt DESC;
END;
GO

IF OBJECT_ID(N'dbo.usp_UpsertPayrollNovelty', N'P') IS NOT NULL
BEGIN
    EXEC(N'
    CREATE OR ALTER PROCEDURE dbo.usp_UpsertPayrollNovelty
        @NoveltyId          NVARCHAR(100),
        @PayrollRunId       NVARCHAR(100) = NULL,
        @EmployeeId         NVARCHAR(100),
        @NoveltyType        NVARCHAR(40),
        @Concept            NVARCHAR(240),
        @Amount             DECIMAL(19,4),
        @Hours              DECIMAL(9,2) = NULL,
        @LegalJustification NVARCHAR(500) = NULL,
        @DocReference       NVARCHAR(300) = NULL,
        @PeriodDate         DATE,
        @ActorId            NVARCHAR(100)
    WITH EXECUTE AS OWNER
    AS
    BEGIN
        SET NOCOUNT ON;
        IF @Amount <= 0
            THROW 50518, ''El importe de la novedad debe ser mayor que cero.'', 1;

        IF @PayrollRunId IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId = @PayrollRunId AND Status IN (N''borrador'', N''calculada'')
        )
            THROW 50528, ''La novedad solo se registra o corrige mientras la planilla está en borrador o calculada.'', 1;

        MERGE dbo.PayrollNovelties AS target
        USING (VALUES (@NoveltyId, @PayrollRunId, @EmployeeId, @NoveltyType, @Concept, @Amount, @Hours, @LegalJustification, @DocReference, @PeriodDate, @ActorId))
           AS src (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, ActorId)
        ON (target.NoveltyId = src.NoveltyId)
        WHEN MATCHED AND target.Status <> N''cancelada'' THEN
            UPDATE SET target.PayrollRunId = src.PayrollRunId, target.EmployeeId = src.EmployeeId,
                       target.NoveltyType = src.NoveltyType, target.Concept = src.Concept,
                       target.Amount = src.Amount, target.Hours = src.Hours,
                       target.LegalJustification = src.LegalJustification, target.DocReference = src.DocReference,
                       target.PeriodDate = src.PeriodDate
        WHEN NOT MATCHED THEN
            INSERT (NoveltyId, PayrollRunId, EmployeeId, NoveltyType, Concept, Amount, Hours, LegalJustification, DocReference, PeriodDate, Status, CreatedByAppUserId, AuthorizedByAppUserId, AuthorizedAt)
            VALUES (src.NoveltyId, src.PayrollRunId, src.EmployeeId, src.NoveltyType, src.Concept, src.Amount, src.Hours, src.LegalJustification, src.DocReference, src.PeriodDate, N''autorizada'', src.ActorId, src.ActorId, SYSUTCDATETIME());

        IF @PayrollRunId IS NOT NULL
            UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @PayrollRunId;

        INSERT INTO dbo.PayrollNoveltyEvents (NoveltyId, ActorId, ActorName, EventType, Detail)
        SELECT @NoveltyId, @ActorId, ISNULL(u.Name, @ActorId), N''registro'', @Concept
        FROM dbo.AppUsers u WHERE u.AppUserId = @ActorId;

        SELECT NoveltyId AS id, Concept AS concept, Amount AS amount, Status AS status
        FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;
    END;
    ');
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CancelPayrollNovelty
    @NoveltyId NVARCHAR(100),
    @Reason NVARCHAR(500),
    @ActorId NVARCHAR(100),
    @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RunId NVARCHAR(100), @Status NVARCHAR(30);
    SELECT @RunId = PayrollRunId, @Status = Status FROM dbo.PayrollNovelties WHERE NoveltyId = @NoveltyId;
    IF @Status IS NULL THROW 50529, 'La novedad no existe.', 1;
    IF @Status = N'cancelada' THROW 50530, 'La novedad ya está cancelada.', 1;
    IF @RunId IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId = @RunId AND Status IN (N'borrador', N'calculada')
    )
        THROW 50528, 'La novedad no se puede cancelar en el estado actual de la planilla.', 1;

    UPDATE dbo.PayrollNovelties SET Status = N'cancelada' WHERE NoveltyId = @NoveltyId;
    IF @RunId IS NOT NULL
        UPDATE dbo.PayrollRuns SET CalculationStale = 1, UpdatedAt = SYSUTCDATETIME() WHERE PayrollRunId = @RunId;

    INSERT INTO dbo.PayrollNoveltyEvents (NoveltyId, ActorId, ActorName, EventType, Detail)
    VALUES (@NoveltyId, @ActorId, @ActorName, N'cancelacion', @Reason);

    INSERT INTO dbo.PayrollHistoryEvents (PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description)
    SELECT @RunId, @ActorId, @ActorName, N'cancelacion_novedad', Status, Status, CONCAT(N'Se canceló la novedad ', @NoveltyId, N'. ', @Reason)
    FROM dbo.PayrollRuns WHERE PayrollRunId = @RunId;
END;
GO

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'raquel_erp_app')
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_GetPayrollEligibleEmployees TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_AddPayrollRunWorker TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RemovePayrollRunWorker TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_RegisterPayrollPayment TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_CancelPayrollNovelty TO [raquel_erp_app];
    GRANT SELECT, INSERT ON OBJECT::dbo.PayrollNoveltyEvents TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 18/25: 26_integridad_caja_nomina_pagos.sql */
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

GO

/* ARCHIVO 19/25: 19_directorio_proveedores.sql */
/* Directorio de proveedores. Aplicar con cuenta de migraciones, sin semilla ni reconstruccion.
   Requiere 11 y 12. No modifica personal, nomina, compras ni otros terceros. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
IF OBJECT_ID(N'dbo.usp_UpsertSupplier', N'P') IS NULL
    THROW 50500, 'Aplica primero 11_actualizar_proveedores.sql y 12_sincronizacion_proveedores.sql.', 1;
GO
/* El snapshot antiguo elimina Parties. Preservar SOLO proveedores y su expediente.
   Fallar antes de crear tablas si la version instalada no tiene el bloque conocido. */
DECLARE @Definition NVARCHAR(MAX)=OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_SaveErpState'));
SET @Definition=REPLACE(@Definition,CHAR(13),N'');
IF @Definition IS NULL THROW 50505,'No se puede inspeccionar usp_SaveErpState con esta cuenta.',1;
IF CHARINDEX(N'DELETE FROM dbo.Parties;',@Definition)>0
BEGIN
    DECLARE @EndBlock NVARCHAR(MAX)=N'NextReviewDate DATE ''$.nextReviewDate'''+CHAR(10)+N'        );';
    IF CHARINDEX(@EndBlock,@Definition)=0 THROW 50506,'Version de snapshot no reconocida; revisar el bloque Parties antes de migrar.',1;
    SET @Definition=REPLACE(@Definition,N'DELETE FROM dbo.Parties;',N'DELETE FROM dbo.Parties WHERE PartyType <> N''proveedor'';');
    SET @Definition=REPLACE(@Definition,@EndBlock,N'NextReviewDate DATE ''$.nextReviewDate'''+CHAR(10)+N'        ) WHERE PartyType <> N''proveedor'';');
    DECLARE @Merge NVARCHAR(MAX)=N'
        /* Proveedores confirmados no se sobrescriben desde un navegador antiguo. */
        DECLARE @DirectoryParties NVARCHAR(MAX);
        SELECT @DirectoryParties=N''[''+COALESCE(STRING_AGG(CONVERT(NVARCHAR(MAX),value),N'',''),N'''')+N'']''
        FROM (
            SELECT value FROM OPENJSON(@Payload,''$.parties'') WHERE JSON_VALUE(value,''$.type'')<>N''proveedor''
            UNION ALL
            SELECT (SELECT p.PartyId AS id,p.Name AS name,p.Contact AS contact,p.Phone AS phone,
                p.Email AS email,p.Address AS address,p.SupplierCategory AS category,p.ProductsServices AS productsServices,
                p.Ruc AS ruc,p.PaymentTerms AS paymentTerms,p.Observations AS observations,p.SupplierStatus AS status,
                p.CreatedAt AS createdAt,p.UpdatedAt AS updatedAt,p.NextReviewDate AS nextReviewDate,N''proveedor'' AS type
                FOR JSON PATH,WITHOUT_ARRAY_WRAPPER)
            FROM dbo.Parties p WHERE PartyType=N''proveedor''
        ) AS confirmed;
        SET @Payload=JSON_MODIFY(@Payload,''$.parties'',JSON_QUERY(@DirectoryParties));
        ';
    SET @Definition=REPLACE(@Definition,N'        UPDATE dbo.ErpState',@Merge+N'        UPDATE dbo.ErpState');
    DECLARE @procPos INT = CHARINDEX(N'PROCEDURE', @Definition);
    IF @procPos > 0 SET @Definition = N'CREATE OR ALTER ' + SUBSTRING(@Definition, @procPos, LEN(@Definition));
    EXEC sys.sp_executesql @Definition;
END;
GO
IF OBJECT_ID(N'dbo.SupplierDirectory', N'U') IS NULL
CREATE TABLE dbo.SupplierDirectory (
    PartyId NVARCHAR(100) NOT NULL PRIMARY KEY REFERENCES dbo.Parties(PartyId),
    Data NVARCHAR(MAX) NOT NULL CHECK (ISJSON(Data) = 1),
    UpdatedAt DATETIMEOFFSET(3) NOT NULL,
    UpdatedBy NVARCHAR(200) NOT NULL,
    Version ROWVERSION NOT NULL
);
IF OBJECT_ID(N'dbo.SupplierDirectoryEvents', N'U') IS NULL
CREATE TABLE dbo.SupplierDirectoryEvents (
    MutationId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    PartyId NVARCHAR(100) NOT NULL REFERENCES dbo.Parties(PartyId),
    ActorId NVARCHAR(100) NOT NULL,
    ActorName NVARCHAR(200) NOT NULL,
    RequestHash VARCHAR(64) NOT NULL,
    OccurredAt DATETIMEOFFSET(3) NOT NULL,
    Reason NVARCHAR(500) NOT NULL,
    BeforeData NVARCHAR(MAX) NULL,
    AfterData NVARCHAR(MAX) NOT NULL,
    Response NVARCHAR(MAX) NOT NULL
);
IF OBJECT_ID(N'dbo.SupplierDirectoryFiles', N'U') IS NULL
CREATE TABLE dbo.SupplierDirectoryFiles (
    DocumentId UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    PartyId NVARCHAR(100) NOT NULL REFERENCES dbo.Parties(PartyId),
    FileName NVARCHAR(200) NOT NULL,
    ContentType NVARCHAR(80) NOT NULL,
    Content VARBINARY(MAX) NOT NULL,
    CHECK (DATALENGTH(Content) BETWEEN 1 AND 3145728)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.SupplierDirectoryEvents') AND name = N'IX_SupplierDirectoryEvents_Party')
    CREATE INDEX IX_SupplierDirectoryEvents_Party ON dbo.SupplierDirectoryEvents(PartyId, OccurredAt DESC);
GO
INSERT dbo.SupplierDirectory(PartyId,Data,UpdatedAt,UpdatedBy)
SELECT PartyId,N'{}',TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),N'Migracion de directorio'
FROM dbo.Parties p WHERE PartyType=N'proveedor' AND NOT EXISTS(SELECT 1 FROM dbo.SupplierDirectory d WHERE d.PartyId=p.PartyId);
GO
CREATE OR ALTER VIEW dbo.vw_SupplierDirectory AS
SELECT p.PartyId AS id, p.Name AS name, p.Contact AS contact, p.Phone AS phone,
       COALESCE(p.Email,N'') AS email, COALESCE(p.Address,N'') AS address,
       COALESCE(p.SupplierCategory,N'otro') AS category, COALESCE(p.SupplierStatus,N'pendiente') AS status,
       COALESCE(p.ProductsServices,N'') AS productsServices, COALESCE(p.Ruc,N'') AS ruc,
       COALESCE(p.PaymentTerms,N'') AS paymentTerms, COALESCE(p.Observations,N'') AS observations,
       CONVERT(VARCHAR(10),p.NextReviewDate,23) AS nextReviewDate,
       p.CreatedAt AS createdAt, p.UpdatedAt AS updatedAt,
       d.Data AS profile, d.UpdatedBy AS updatedBy,
       CONVERT(VARCHAR(18), d.Version, 1) AS version
FROM dbo.Parties p LEFT JOIN dbo.SupplierDirectory d ON d.PartyId=p.PartyId
WHERE p.PartyType=N'proveedor';
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReadSupplierDirectory
    @PartyId NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_SupplierDirectory WHERE @PartyId IS NULL OR id=@PartyId ORDER BY name,id;
    IF @PartyId IS NOT NULL
    BEGIN
        SELECT TOP (100) MutationId AS id, ActorName AS actor, OccurredAt AS at,
               Reason AS reason, BeforeData AS beforeData, AfterData AS afterData
        FROM dbo.SupplierDirectoryEvents WHERE PartyId=@PartyId ORDER BY OccurredAt DESC,MutationId;
        SELECT p.PurchaseId AS id,p.PurchaseNumber AS number,p.Status AS status,
               p.Total AS total,p.PurchaseDate AS date,p.SupplierPartyId AS supplierId
        FROM dbo.Purchases p WHERE p.SupplierPartyId=@PartyId ORDER BY p.PurchaseDate DESC;
        SELECT DocumentId AS id,FileName AS name,ContentType AS type
        FROM dbo.SupplierDirectoryFiles WHERE PartyId=@PartyId;
    END;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_SaveSupplierDirectory
    @PartyId NVARCHAR(100), @Data NVARCHAR(MAX), @ExpectedVersion VARCHAR(18),
    @MutationId UNIQUEIDENTIFIER, @ActorId NVARCHAR(100), @ActorName NVARCHAR(200),
    @Reason NVARCHAR(500), @RequestHash VARCHAR(64), @FileId UNIQUEIDENTIFIER = NULL, @FileContent VARBINARY(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF ISJSON(@Data)<>1 THROW 50501,'Datos del proveedor invalidos.',1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @StoredResponse NVARCHAR(MAX), @StoredParty NVARCHAR(100), @StoredActor NVARCHAR(100), @StoredHash VARCHAR(64);
        SELECT @StoredResponse=Response,@StoredParty=PartyId,@StoredActor=ActorId,@StoredHash=RequestHash
        FROM dbo.SupplierDirectoryEvents WITH (UPDLOCK,HOLDLOCK) WHERE MutationId=@MutationId;
        IF @StoredResponse IS NOT NULL
        BEGIN
            IF @StoredParty<>@PartyId OR @StoredActor<>@ActorId OR @StoredHash<>@RequestHash
                THROW 50502,'Identificador de operacion ya utilizado.',1;
            COMMIT TRANSACTION;
            SELECT @StoredResponse AS response;
            RETURN;
        END;
        DECLARE @SnapshotLock NVARCHAR(MAX);
        SELECT @SnapshotLock=Payload FROM dbo.ErpState WITH(UPDLOCK,HOLDLOCK) WHERE StateId=1;
        DECLARE @Before NVARCHAR(MAX), @CurrentVersion VARCHAR(18), @Exists BIT=0;
        SELECT @Exists=1 FROM dbo.Parties WITH (UPDLOCK,HOLDLOCK) WHERE PartyId=@PartyId AND PartyType=N'proveedor';
        SELECT @CurrentVersion=CONVERT(VARCHAR(18),Version,1)
        FROM dbo.SupplierDirectory WITH (UPDLOCK,HOLDLOCK) WHERE PartyId=@PartyId;
        IF COALESCE(@CurrentVersion,'')<>COALESCE(@ExpectedVersion,'')
            THROW 50503,'Otro usuario modifico el proveedor. Recarga el expediente y compara los cambios.',1;
        IF @Exists=1 SELECT @Before=(SELECT * FROM dbo.vw_SupplierDirectory WHERE id=@PartyId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);

        DECLARE @Name NVARCHAR(240)=JSON_VALUE(@Data,'$.name'), @Category NVARCHAR(30)=JSON_VALUE(@Data,'$.category'),
        @Contact NVARCHAR(200)=JSON_VALUE(@Data,'$.contact'), @Phone NVARCHAR(80)=JSON_VALUE(@Data,'$.phone'),
        @Email NVARCHAR(320)=JSON_VALUE(@Data,'$.email'), @Address NVARCHAR(500)=JSON_VALUE(@Data,'$.address'),
        @Products NVARCHAR(1000)=JSON_VALUE(@Data,'$.productsServices'), @Ruc NVARCHAR(40)=JSON_VALUE(@Data,'$.ruc'),
        @Terms NVARCHAR(80)=JSON_VALUE(@Data,'$.paymentTerms'), @Notes NVARCHAR(2000)=JSON_VALUE(@Data,'$.observations'),
        @Status NVARCHAR(20)=JSON_VALUE(@Data,'$.status'), @Review DATE=TRY_CONVERT(DATE,NULLIF(JSON_VALUE(@Data,'$.nextReviewDate'),'')),
        @AuditId NVARCHAR(100)=CONVERT(NVARCHAR(100),@MutationId), @Action NVARCHAR(120)=CASE WHEN @Exists=1 THEN N'actualizar proveedor' ELSE N'alta proveedor' END;
        DECLARE @Saved TABLE (
            id NVARCHAR(100),name NVARCHAR(240),contact NVARCHAR(200),phone NVARCHAR(80),email NVARCHAR(320),address NVARCHAR(500),category NVARCHAR(30),
            productsServices NVARCHAR(1000),ruc NVARCHAR(40),paymentTerms NVARCHAR(80),observations NVARCHAR(2000),status NVARCHAR(20),
            createdAt DATETIMEOFFSET(3),updatedAt DATETIMEOFFSET(3),nextReviewDate DATE,type NVARCHAR(30));
        INSERT INTO @Saved EXEC dbo.usp_UpsertSupplier @PartyId,@Name,@Category,@Contact,@Phone,@Email,@Address,@Products,@Ruc,@Terms,@Notes,@Status,@Review,@ActorName,@AuditId,@Action,@Reason;
        IF EXISTS(SELECT 1 FROM dbo.SupplierDirectory WHERE PartyId=@PartyId)
            UPDATE dbo.SupplierDirectory SET Data=@Data,UpdatedAt=TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),UpdatedBy=@ActorName WHERE PartyId=@PartyId;
        ELSE INSERT dbo.SupplierDirectory(PartyId,Data,UpdatedAt,UpdatedBy)
            VALUES(@PartyId,@Data,TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),@ActorName);

        IF @FileId IS NOT NULL
        BEGIN
            DECLARE @FileName NVARCHAR(200),@FileType NVARCHAR(80);
            SELECT @FileName=fileName,@FileType=fileType FROM OPENJSON(@Data,'$.documents')
            WITH(id UNIQUEIDENTIFIER '$.id',fileName NVARCHAR(200) '$.fileName',fileType NVARCHAR(80) '$.fileType') WHERE id=@FileId;
            IF @FileName IS NULL OR @FileContent IS NULL THROW 50504,'Faltan datos del documento.',1;
            INSERT dbo.SupplierDirectoryFiles(DocumentId,PartyId,FileName,ContentType,Content) VALUES(@FileId,@PartyId,@FileName,@FileType,@FileContent);
        END;
        DECLARE @Response NVARCHAR(MAX)=(SELECT * FROM dbo.vw_SupplierDirectory WHERE id=@PartyId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
        INSERT dbo.SupplierDirectoryEvents(MutationId,PartyId,ActorId,ActorName,RequestHash,OccurredAt,Reason,BeforeData,AfterData,Response)
        VALUES(@MutationId,@PartyId,@ActorId,@ActorName,@RequestHash,TODATETIMEOFFSET(SYSUTCDATETIME(),'+00:00'),@Reason,@Before,@Data,@Response);

        /* Mantener compatible el snapshot existente sin reemplazar otros modulos. */
        DECLARE @Payload NVARCHAR(MAX),@Index INT,@PartyJson NVARCHAR(MAX);
        SELECT @Payload=Payload FROM dbo.ErpState WITH (UPDLOCK,HOLDLOCK) WHERE StateId=1;
        IF ISJSON(@Payload)=1
        BEGIN
            SET @PartyJson=(SELECT id,name,contact,phone,email,address,category,productsServices,ruc,paymentTerms,observations,status,createdAt,updatedAt,nextReviewDate,N'proveedor' AS type FROM dbo.vw_SupplierDirectory WHERE id=@PartyId FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
            SELECT @Index=TRY_CONVERT(INT,[key]) FROM OPENJSON(@Payload,'$.parties') WHERE JSON_VALUE(value,'$.id')=@PartyId;
            IF JSON_QUERY(@Payload,'$.parties') IS NULL SET @Payload=JSON_MODIFY(@Payload,'$.parties',JSON_QUERY('[]'));
            IF @Index IS NULL SET @Payload=JSON_MODIFY(@Payload,'append $.parties',JSON_QUERY(@PartyJson));
            ELSE SET @Payload=JSON_MODIFY(@Payload,'$.parties['+CONVERT(VARCHAR(12),@Index)+']',JSON_QUERY(@PartyJson));
            UPDATE dbo.ErpState SET Payload=@Payload,UpdatedAt=SYSUTCDATETIME() WHERE StateId=1;
        END;
        COMMIT TRANSACTION;
        SELECT @Response AS response;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReadSupplierDirectoryReceipt
    @MutationId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PartyId,ActorId,RequestHash,Response FROM dbo.SupplierDirectoryEvents WHERE MutationId=@MutationId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_ReadSupplierDirectoryFile
    @PartyId NVARCHAR(100), @DocumentId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FileName,ContentType,Content FROM dbo.SupplierDirectoryFiles WHERE PartyId=@PartyId AND DocumentId=@DocumentId;
END;
GO
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT EXECUTE ON OBJECT::dbo.usp_ReadSupplierDirectory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_SaveSupplierDirectory TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ReadSupplierDirectoryFile TO [raquel_erp_app];
    GRANT EXECUTE ON OBJECT::dbo.usp_ReadSupplierDirectoryReceipt TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 20/25: 28_ajuste_pagos_caja.sql */
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
USE [Raquel_Schema_Check_20261025_99ef80cc];
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

GO

/* ARCHIVO 21/25: 29_coherencia_caja_nomina_snapshot.sql */
/* ============================================================================
   MIGRACION 29 - COHERENCIA CAJA / NOMINA / SNAPSHOT
   ----------------------------------------------------------------------------
   Causas encontradas (con evidencia en codigo, no reconstruye la base):

   1) usp_GetPayrollRuns (migracion 26) dejo de devolver workersCount, startDate,
      endDate, paymentDate y employerCostTotal. La pantalla mostraba 0 personas
      y podia tratar un borrador como si ya estuviera calculado.
   2) usp_CreatePayrollDraft escribia CalculationVersion = 1, PaidAt = ahora y
      Net = Gross con TotalDeductions = 0. Eso aparentaba un calculo valido.
   3) usp_SaveErpState BORRABA caja sin OperationKey y la VOLVIA A INSERTAR
      desde el JSON del navegador (addSale/addCash). Esa es una fuente real de
      duplicados de dinero.
   4) usp_RegisterPayrollPayment reutilizaba un solo CashMove por planilla y
      NO validaba el pendiente del trabajador: dos pagos al mismo empleado con
      distinta clave de idempotencia se aceptaban hasta agotar el neto de la
      planilla.
   5) CK_CashMoves_AmountPositivo impedia apertura en C$ 0.

   No borra datos operativos. No reinstala semilla. No cambia cuentas.
   ============================================================================ */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

PRINT N'29: inicio';

/* ---------------------------------------------------------------------------
   1) Apertura con saldo 0 permitida (el tipo apertura identifica el saldo
      inicial; no es un ingreso).
   --------------------------------------------------------------------------- */
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = N'CK_CashMoves_AmountPositivo'
      AND parent_object_id = OBJECT_ID(N'dbo.CashMoves')
)
    ALTER TABLE dbo.CashMoves DROP CONSTRAINT CK_CashMoves_AmountPositivo;
GO

ALTER TABLE dbo.CashMoves WITH CHECK ADD CONSTRAINT CK_CashMoves_AmountPositivo
    CHECK (Amount > 0 OR (DocumentType = N'apertura' AND Amount >= 0));
GO

IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.PayrollRuns')
      AND name = N'PaidAt' AND is_nullable = 0
)
BEGIN
    ALTER TABLE dbo.PayrollRuns ALTER COLUMN PaidAt DATETIMEOFFSET(3) NULL;
    PRINT N'29: PayrollRuns.PaidAt ahora admite NULL (el borrador no esta pagado).';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UQ_PayrollPayments_RequestHash'
      AND object_id = OBJECT_ID(N'dbo.PayrollPayments')
)
    CREATE UNIQUE INDEX UQ_PayrollPayments_RequestHash
        ON dbo.PayrollPayments (RequestHash)
        WHERE RequestHash IS NOT NULL;
GO

/* ---------------------------------------------------------------------------
   2) Tasa vigente del catalogo de reglas (no se inventan porcentajes).
   --------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.fn_PayrollRuleRate', N'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_PayrollRuleRate;
GO
CREATE FUNCTION dbo.fn_PayrollRuleRate (
    @RuleCode NVARCHAR(40),
    @JsonPath NVARCHAR(80)
)
RETURNS DECIMAL(9,6)
AS
BEGIN
    DECLARE @Rate DECIMAL(9,6);
    SELECT TOP (1) @Rate = TRY_CONVERT(DECIMAL(9,6), JSON_VALUE(ParameterJson, @JsonPath))
    FROM dbo.PayrollRulesCatalog
    WHERE RuleCode = @RuleCode
      AND Status = N'vigente'
      AND IsVerified = 1
      AND EffectiveFrom <= CAST(SYSUTCDATETIME() AS DATE)
      AND (EffectiveTo IS NULL OR EffectiveTo >= CAST(SYSUTCDATETIME() AS DATE))
    ORDER BY EffectiveFrom DESC;
    RETURN @Rate;
END;
GO

/* ---------------------------------------------------------------------------
   3) Listado de planillas: devolver las columnas que usa la interfaz.
   --------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_GetPayrollRuns
    @IncludeClosed BIT = 0
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        r.PayrollRunId AS id,
        r.Period AS period,
        r.PeriodType AS periodType,
        r.StartDate AS startDate,
        r.EndDate AS endDate,
        r.PaymentDate AS paymentDate,
        r.Status AS status,
        r.CalculationVersion AS calculationVersion,
        ISNULL(r.CalculationStale, 0) AS calculationStale,
        r.Gross AS grossTotal,
        r.InssLaboral AS inssLaboralTotal,
        r.IncomeTax AS incomeTaxTotal,
        r.OtherDeductionsTotal AS otherDeductionsTotal,
        r.TotalDeductions AS totalDeductions,
        ISNULL((SELECT SUM(i.TotalDeductions) FROM dbo.PayrollRunItems AS i WHERE i.PayrollRunId = r.PayrollRunId), 0) AS deductionsFromItems,
        CASE WHEN r.TotalDeductions = ISNULL((SELECT SUM(i.TotalDeductions) FROM dbo.PayrollRunItems AS i WHERE i.PayrollRunId = r.PayrollRunId), 0)
             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS headerConsistent,
        r.Net AS netTotal,
        r.InssPatronal AS inssPatronalTotal,
        r.Inatec AS inatecTotal,
        r.AguinaldoProvTotal AS aguinaldoProvTotal,
        r.VacacionesProvTotal AS vacacionesProvTotal,
        r.IndemnizacionProvTotal AS indemnizacionProvTotal,
        r.EmployerCost AS employerCostTotal,
        r.EmployerCost AS companyCostTotal,
        r.ConfirmedPaymentsTotal AS confirmedPaymentsTotal,
        (ISNULL(r.Net, 0) - ISNULL(r.ConfirmedPaymentsTotal, 0)) AS pendingPayment,
        r.PendingDiscrepancyTotal AS pendingDiscrepancyTotal,
        r.Actor AS preparedByName,
        r.PreparedAt AS preparedAt,
        r.CalculatedAt AS calculatedAt,
        r.ReviewedAt AS reviewedAt,
        r.ApprovedAt AS approvedAt,
        r.PaidAt AS paidAt,
        r.ReconciledAt AS reconciledAt,
        r.ClosedAt AS closedAt,
        r.Notes AS notes,
        (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS workersCount,
        (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId = r.PayrollRunId) AS employeesCount,
        (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'bloqueante' AND IsResolved = 0) AS blockingIssuesCount,
        (SELECT COUNT(*) FROM dbo.PayrollValidations WHERE PayrollRunId = r.PayrollRunId AND Severity = N'advertencia' AND IsResolved = 0) AS warningIssuesCount,
        CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS revision,
        CONVERT(VARCHAR(20), CONVERT(VARBINARY(8), r.Revision), 1) AS rowVersion,
        r.UpdatedAt AS updatedAt
    FROM dbo.PayrollRuns AS r
    WHERE (@IncludeClosed = 1 OR r.Status NOT IN (N'cancelada'))
    ORDER BY r.StartDate DESC, r.CreatedAt DESC;
END;
GO

/* ---------------------------------------------------------------------------
   4) Borrador: version 0, sin PaidAt, neto y deducciones en 0 hasta calcular.
      Conserva dias/horas reconocidos (no asigna 30/240 fijos).
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
            OtherDeductionsTotal, TotalDeductions, AguinaldoProvTotal, VacacionesProvTotal, IndemnizacionProvTotal,
            ConfirmedPaymentsTotal, PendingDiscrepancyTotal,
            PreparedByAppUserId, PreparedAt, Notes
        )
        VALUES (
            @PayrollRunId, @Period, @PeriodType, @StartDate, @EndDate, @PaymentDate,
            NULL, @ActorName, @ActorId, N'borrador', 0,
            0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0,
            0, 0,
            @ActorId, SYSUTCDATETIME(), @Notes
        );

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
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0,
            N'pendiente', N'transferencia_bancaria', N'no_generado'
        FROM dbo.Employees AS e
        CROSS APPLY (
            SELECT DATEDIFF(
                DAY,
                CASE WHEN e.HireDate IS NULL OR e.HireDate < @StartDate THEN @StartDate ELSE e.HireDate END,
                CASE WHEN e.DismissalDate IS NULL OR e.DismissalDate > @EndDate THEN @EndDate ELSE e.DismissalDate END
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
            N'Borrador creado. Dias y horas reconocidos; deducciones y neto pendientes de calculo.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.CalculationVersion AS calculationVersion,
               r.Gross AS grossTotal, r.Net AS netTotal, r.TotalDeductions AS totalDeductions,
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
   5) Calculo: tasas del catalogo vigente. Sin regla verificada no se calcula.
   --------------------------------------------------------------------------- */
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
    DECLARE @PeriodsInYear DECIMAL(9,4);
    DECLARE @InssLab DECIMAL(9,6) = dbo.fn_PayrollRuleRate(N'INSS_LABORAL', N'$.rate');
    DECLARE @InssPat DECIMAL(9,6) = COALESCE(
        dbo.fn_PayrollRuleRate(N'INSS_PATRONAL', N'$.rate_used'),
        dbo.fn_PayrollRuleRate(N'INSS_PATRONAL', N'$.rate_large')
    );
    DECLARE @Inatec DECIMAL(9,6) = dbo.fn_PayrollRuleRate(N'INATEC_PATRONAL', N'$.rate');
    DECLARE @Prov DECIMAL(9,6) = COALESCE(dbo.fn_PayrollRuleRate(N'AGUINALDO_PROV', N'$.rate'), CONVERT(DECIMAL(9,6), 1.0/12.0));

    IF @InssLab IS NULL OR @InssPat IS NULL OR @Inatec IS NULL
        THROW 50596, 'Faltan reglas vigentes y verificadas (INSS laboral, INSS patronal o INATEC). No se inventan porcentajes.', 1;

    SELECT @CurrentStatus = Status,
           @PeriodType = PeriodType,
           @CalcVer = CalculationVersion,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50503, 'La planilla solicitada no existe.', 1;

    IF @CurrentRev <> @ExpectedRevision
        THROW 50504, 'La planilla fue modificada por otro usuario (revision desfasada). Recarga la pantalla.', 1;

    IF @CurrentStatus IN (N'aprobada', N'pago_registrado', N'conciliada', N'cerrada')
        THROW 50505, 'No se puede recalcular una planilla que ya ha sido aprobada, pagada o cerrada.', 1;

    SET @PeriodsInYear = CASE
        WHEN @PeriodType = N'quincenal' THEN 24.0
        WHEN @PeriodType = N'catorcenal' THEN 26.0
        ELSE 12.0
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

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

        UPDATE dbo.PayrollRunItems
        SET Gross = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2),
            InssBase = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET InssLaboral = ROUND(InssBase * @InssLab, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE i
        SET i.IrBase = p.NetBasePeriod,
            i.IncomeTax = calc.IrPeriod
        FROM dbo.PayrollRunItems i
        CROSS APPLY (
            SELECT
                (i.Gross - i.InssLaboral) AS NetBasePeriod,
                (i.Gross - i.InssLaboral) * @PeriodsInYear AS ProjectedAnnual
        ) AS p
        CROSS APPLY (
            SELECT
                CASE
                    WHEN p.ProjectedAnnual <= 100000.00 THEN 0.00
                    WHEN p.ProjectedAnnual <= 200000.00 THEN
                        ROUND(((p.ProjectedAnnual - 100000.00) * 0.15) / @PeriodsInYear, 2)
                    WHEN p.ProjectedAnnual <= 350000.00 THEN
                        ROUND((15000.00 + (p.ProjectedAnnual - 200000.00) * 0.20) / @PeriodsInYear, 2)
                    WHEN p.ProjectedAnnual <= 500000.00 THEN
                        ROUND((45000.00 + (p.ProjectedAnnual - 350000.00) * 0.25) / @PeriodsInYear, 2)
                    ELSE
                        ROUND((82500.00 + (p.ProjectedAnnual - 500000.00) * 0.30) / @PeriodsInYear, 2)
                END AS IrPeriod
        ) AS calc
        WHERE i.PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET TotalDeductions = ROUND(InssLaboral + IncomeTax + OtherDeductions, 2),
            Net = ROUND(Gross - (InssLaboral + IncomeTax + OtherDeductions), 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET InssPatronal = ROUND(Gross * @InssPat, 2),
            Inatec = ROUND(Gross * @Inatec, 2),
            Aguinaldo = ROUND(Gross * @Prov, 2),
            VacacionesProv = ROUND(Gross * @Prov, 2),
            IndemnizacionProv = ROUND(Gross * @Prov, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET EmployerCost = ROUND(Gross + InssPatronal + Inatec + Aguinaldo + VacacionesProv + IndemnizacionProv, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE i
        SET CalculationExplanationJson = (
            SELECT
                i.OrdinarySalary AS [salario_ordinario],
                i.OvertimeAmount AS [horas_extra_monto],
                i.OvertimeHours AS [horas_extra_cantidad],
                i.BonusesAmount AS [bonos],
                i.CommissionsAmount AS [comisiones],
                i.Gross AS [total_devengado],
                CONVERT(NVARCHAR(20), @InssLab * 100) + N'% sobre devengado (catalogo INSS_LABORAL vigente)' AS [inss_laboral_regla],
                i.InssLaboral AS [inss_laboral_monto],
                N'Tarifa progresiva anual Ley 822 Art. 96 (catalogo IR_PROGRESIVO)' AS [ir_laboral_regla],
                i.IrBase AS [ir_base_periodo],
                i.IncomeTax AS [ir_laboral_monto],
                i.OtherDeductions AS [otras_deducciones],
                i.TotalDeductions AS [total_deducciones],
                i.Net AS [salario_neto_a_pagar],
                CONVERT(NVARCHAR(20), @InssPat * 100) + N'% INSS patronal + ' + CONVERT(NVARCHAR(20), @Inatec * 100) + N'% INATEC (no se descuentan al trabajador)' AS [aportes_patronales_regla],
                i.InssPatronal AS [inss_patronal],
                i.Inatec AS [inatec],
                N'Ley 185: provision 1/12 aguinaldo, vacaciones y antiguedad' AS [provisiones_regla],
                i.Aguinaldo AS [provision_aguinaldo],
                i.VacacionesProv AS [provision_vacaciones],
                i.IndemnizacionProv AS [provision_indemnizacion],
                i.EmployerCost AS [costo_total_empresa],
                @InssLab AS [tasa_inss_laboral],
                @InssPat AS [tasa_inss_patronal],
                @Inatec AS [tasa_inatec]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
        FROM dbo.PayrollRunItems i
        WHERE i.PayrollRunId = @PayrollRunId;

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

        DELETE FROM dbo.PayrollValidations WHERE PayrollRunId = @PayrollRunId;

        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_NETO_INVALIDO',
               N'El trabajador tiene un salario neto menor o igual a cero (C$ ' + CAST(Net AS NVARCHAR(30)) + N'). Revisa las deducciones aplicadas.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Net <= 0;

        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_DEVENGADO_CERO',
               N'El colaborador no registra salario ordinario ni devengado en el periodo.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Gross <= 0;

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'calculo', @CurrentStatus, N'calculada',
            N'Calculo con reglas vigentes INSS ' + CONVERT(NVARCHAR(20), @InssLab) + N' / patronal ' + CONVERT(NVARCHAR(20), @InssPat) + N'.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.CalculationVersion AS calculationVersion,
               r.Gross AS grossTotal, r.InssLaboral AS inssLaboralTotal,
               r.IncomeTax AS incomeTaxTotal, r.TotalDeductions AS totalDeductions,
               r.Net AS netTotal,
               r.InssPatronal AS inssPatronalTotal, r.Inatec AS inatecTotal,
               r.EmployerCost AS employerCostTotal,
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


GO

/* ARCHIVO 22/25: 30_pagos_individuales_atomicos.sql */
/* Incremental: ejecutar DESPUES de 29 con una cuenta administradora.
   Conserva historicos. Los pagos antiguos sin distribucion requieren revision;
   no se inventa a que empleados correspondieron. No reinstala ni siembra datos. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
GO
IF OBJECT_ID(N'dbo.PayrollPaymentAllocations', N'U') IS NULL
CREATE TABLE dbo.PayrollPaymentAllocations (
    PaymentId NVARCHAR(100) NOT NULL REFERENCES dbo.PayrollPayments(PaymentId),
    EmployeeId NVARCHAR(100) NOT NULL REFERENCES dbo.Employees(EmployeeId),
    Amount DECIMAL(19,4) NOT NULL CHECK (Amount > 0),
    CONSTRAINT PK_PayrollPaymentAllocations PRIMARY KEY (PaymentId, EmployeeId)
);
GO
CREATE OR ALTER PROCEDURE dbo.usp_RegisterPayrollPayment
    @PayrollRunId NVARCHAR(100), @Amount DECIMAL(19,4),
    @PaymentMethod NVARCHAR(60), @PaymentReference NVARCHAR(120) = NULL,
    @PaymentDate DATE = NULL, @Notes NVARCHAR(1000) = NULL,
    @IdempotencyKey UNIQUEIDENTIFIER = NULL, @EmployeeId NVARCHAR(100) = NULL,
    @ActorId NVARCHAR(100), @ActorName NVARCHAR(240)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @IdempotencyKey IS NULL OR @PaymentDate IS NULL OR NULLIF(LTRIM(RTRIM(@PaymentReference)),N'') IS NULL
        THROW 50600, 'El pago requiere identificador, fecha y referencia.', 1;
    IF @Amount IS NULL OR @Amount <= 0 OR @Amount <> ROUND(@Amount,2)
        THROW 50600, 'Indica un importe positivo con hasta dos decimales.', 1;
    DECLARE @Method NVARCHAR(30) = CASE LOWER(@PaymentMethod)
        WHEN N'transferencia_bancaria' THEN N'transferencia'
        WHEN N'caja' THEN N'efectivo' ELSE LOWER(@PaymentMethod) END;
    IF @Method NOT IN (N'efectivo',N'transferencia',N'cheque',N'tarjeta',N'otro') OR @Method IS NULL
        THROW 50600, 'Medio de pago no reconocido.', 1;
    DECLARE @Payload NVARCHAR(MAX) = (SELECT @PayrollRunId AS runId, @EmployeeId AS employeeId,
        @Amount AS amount, @Method AS method, @PaymentReference AS reference,
        @PaymentDate AS paymentDate, @Notes AS notes FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES);
    DECLARE @Hash VARBINARY(32) = HASHBYTES('SHA2_256', @Payload);
    DECLARE @Status NVARCHAR(30), @Net DECIMAL(19,4), @Paid DECIMAL(19,4), @Version INT,
        @Stale BIT, @Calculated DATETIMEOFFSET(3), @Session NVARCHAR(100), @SessionDate DATE,
        @Currency NVARCHAR(10), @Lock INT, @Existing NVARCHAR(100);
    DECLARE @Account NVARCHAR(30) = CASE WHEN @Method=N'efectivo' THEN N'caja' ELSE N'banco' END;
    DECLARE @Allocation TABLE (EmployeeId NVARCHAR(100) PRIMARY KEY, Amount DECIMAL(19,4));
    BEGIN TRY
        BEGIN TRANSACTION;
        -- Serializa la misma clave incluso si se intenta usar en otra planilla.
        DECLARE @Resource NVARCHAR(255)=N'payroll-payment:'+CONVERT(NVARCHAR(36),@IdempotencyKey);
        EXEC @Lock=sys.sp_getapplock @Resource=@Resource, @LockMode='Exclusive', @LockOwner='Transaction', @LockTimeout=10000;
        IF @Lock < 0 THROW 50601, 'Otra solicitud procesa este pago. Reintenta con la misma clave.', 1;
        SELECT @Existing=PaymentId FROM dbo.PayrollPayments WHERE IdempotencyKey=@IdempotencyKey;
        IF @Existing IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.PayrollPayments WHERE PaymentId=@Existing AND (RequestHash IS NULL OR RequestHash<>@Hash))
                THROW 50602, 'El identificador ya fue usado con otros datos. Revisa el pago existente.', 1;
            COMMIT;
            SELECT N'repetida' AS Resultado, PaymentId, PayrollRunId, Amount, CashMoveId
            FROM dbo.PayrollPayments WHERE PaymentId=@Existing;
            RETURN;
        END;
        -- El bloqueo vive hasta confirmar TODOS los efectos, no solo el SELECT.
        SELECT @Status=Status,@Net=Net,@Version=CalculationVersion,@Stale=CalculationStale,@Calculated=CalculatedAt
        FROM dbo.PayrollRuns WITH (UPDLOCK,HOLDLOCK) WHERE PayrollRunId=@PayrollRunId;
        IF @Status IS NULL THROW 50529, 'La planilla no existe.', 1;
        IF @Status NOT IN (N'aprobada',N'pago_registrado') THROW 50530, 'La planilla debe estar aprobada.', 1;
        IF @Calculated IS NULL OR ISNULL(@Version,0)<1 OR @Stale=1
            THROW 50590, 'Se requiere calculo confirmado y vigente antes de pagar.', 1;
        IF EXISTS(SELECT 1 FROM dbo.PayrollValidations WHERE PayrollRunId=@PayrollRunId AND Severity=N'bloqueante' AND IsResolved=0)
            THROW 50603, 'Existen validaciones bloqueantes pendientes.', 1;
        IF NOT EXISTS(SELECT 1 FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId)
            THROW 50603, 'La planilla no tiene trabajadores.', 1;
        IF EXISTS(SELECT 1 FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId AND (Net<0 OR ABS(Gross-TotalDeductions-Net)>0.01))
           OR EXISTS(SELECT 1 FROM dbo.PayrollRuns r WHERE r.PayrollRunId=@PayrollRunId AND
              (ABS(r.Net-(SELECT SUM(Net) FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId))>0.01
               OR ABS(r.TotalDeductions-(SELECT SUM(TotalDeductions) FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId))>0.01))
            THROW 50603, 'Cabecera, deducciones y netos no coinciden. Revisa la planilla antes de pagar.', 1;
        -- Sin inferencias sobre historicos: se exige distribucion explicita.
        IF EXISTS(SELECT 1 FROM dbo.PayrollPayments p WHERE p.PayrollRunId=@PayrollRunId AND p.Status=N'confirmado'
            AND p.Amount<>(SELECT ISNULL(SUM(a.Amount),0) FROM dbo.PayrollPaymentAllocations a WHERE a.PaymentId=p.PaymentId))
            THROW 50604, 'Hay pagos historicos sin distribucion verificada por trabajador. Requieren conciliacion.', 1;
        SELECT @Paid=ISNULL(SUM(Amount),0) FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado';
        IF EXISTS(SELECT 1 FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado'
            AND ISNULL(EmployeeId,N'')=ISNULL(@EmployeeId,N'') AND TransactionReference=@PaymentReference AND PaymentDate=@PaymentDate
            AND CASE LOWER(PaymentMethod) WHEN N'transferencia_bancaria' THEN N'transferencia' WHEN N'caja' THEN N'efectivo' ELSE LOWER(PaymentMethod) END=@Method)
            THROW 50607, 'La referencia ya tiene un pago confirmado para este beneficiario y fecha.', 1;
        IF @Amount>@Net-@Paid THROW 50592, 'El importe supera el pendiente aprobado de la planilla.', 1;
        ;WITH Pending AS (
            SELECT i.EmployeeId, i.Net-ISNULL(p.Amount,0) AS Amount
            FROM dbo.PayrollRunItems i OUTER APPLY (
                SELECT SUM(a.Amount) AS Amount FROM dbo.PayrollPaymentAllocations a JOIN dbo.PayrollPayments p ON p.PaymentId=a.PaymentId
                WHERE p.PayrollRunId=@PayrollRunId AND p.Status=N'confirmado' AND a.EmployeeId=i.EmployeeId
            ) p WHERE i.PayrollRunId=@PayrollRunId AND (@EmployeeId IS NULL OR i.EmployeeId=@EmployeeId)
        ), Ordered AS (
            SELECT *, ISNULL(SUM(Amount) OVER(ORDER BY EmployeeId ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) AS BeforeAmount
            FROM Pending WHERE Amount>0
        )
        INSERT @Allocation SELECT EmployeeId, CASE WHEN @Amount-BeforeAmount<Amount THEN @Amount-BeforeAmount ELSE Amount END
        FROM Ordered WHERE BeforeAmount<@Amount;
        IF (SELECT ISNULL(SUM(Amount),0) FROM @Allocation)<>@Amount
            THROW 50605, 'El trabajador no pertenece a la planilla o el pago supera su pendiente.', 1;
        DECLARE @CashResource NVARCHAR(255)=N'cash-account:'+@Account;
        EXEC @Lock=sys.sp_getapplock @Resource=@CashResource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
        IF @Lock<0 THROW 50601, 'La cuenta esta ocupada. Reintenta el mismo pago.', 1;
        SELECT @Session=CashSessionId,@SessionDate=SessionDate,@Currency=Currency
        FROM dbo.CashSessions WITH (UPDLOCK,HOLDLOCK) WHERE Account=@Account AND Status=N'abierta';
        IF @Session IS NULL OR @SessionDate<>@PaymentDate THROW 50606, 'Abre una sesion de la cuenta para la fecha del pago.', 1;
        IF @Currency NOT IN (N'C$',N'NIO') THROW 50606, 'La moneda de la sesion no coincide con la nomina en cordobas.', 1;
        DECLARE @Available DECIMAL(19,4);
        SELECT @Available=s.OpeningBalance+ISNULL((SELECT SUM(CASE WHEN m.MoveType=N'entrada' THEN m.Amount ELSE -m.Amount END)
            FROM dbo.CashMoves m WHERE m.SessionId=s.CashSessionId AND m.MoveState=N'confirmado'
              AND ISNULL(m.DocumentType,N'')<>N'apertura'),0)
        FROM dbo.CashSessions s WHERE s.CashSessionId=@Session;
        IF @Available<@Amount THROW 50609, 'El saldo confirmado de la sesion no cubre el pago.', 1;
        DECLARE @PaymentId NVARCHAR(100)=N'pay-'+CONVERT(NVARCHAR(36),@IdempotencyKey);
        DECLARE @CashId NVARCHAR(100)=N'cash-'+@PaymentId;
        DECLARE @Operation NVARCHAR(160)=N'pago-nomina:'+CONVERT(NVARCHAR(36),@IdempotencyKey);
        DECLARE @Date DATETIMEOFFSET(3)=TODATETIMEOFFSET(CONVERT(DATETIME2(3),@PaymentDate),N'-06:00');
        INSERT dbo.CashMoves(CashMoveId,Account,MoveType,Amount,MoveDate,MoveTime,Concept,Method,DocumentType,DocumentRef,PayrollRunId,SessionId,
            ResponsibleAppUserId,ResponsibleName,MoveState,OperationKey,CreatedBy)
        VALUES(@CashId,@Account,N'salida',@Amount,@Date,CONVERT(TIME(0),SYSDATETIMEOFFSET()),N'Pago neto de nomina '+@PayrollRunId,
            @Method,N'nomina',@PaymentReference,@PayrollRunId,@Session,@ActorId,@ActorName,N'confirmado',@Operation,@ActorName);
        INSERT dbo.PayrollPayments(PaymentId,PayrollRunId,EmployeeId,Amount,PaymentMethod,TransactionReference,PaymentDate,CashMoveId,Notes,
            ConfirmedAt,ConfirmedByAppUserId,ConfirmedByName,CalculationVersion,Status,IdempotencyKey,OperationKey,RequestHash)
        VALUES(@PaymentId,@PayrollRunId,@EmployeeId,@Amount,@PaymentMethod,@PaymentReference,@PaymentDate,@CashId,@Notes,
            SYSUTCDATETIME(),@ActorId,@ActorName,@Version,N'confirmado',@IdempotencyKey,@Operation,@Hash);
        INSERT dbo.PayrollPaymentAllocations SELECT @PaymentId,EmployeeId,Amount FROM @Allocation;
        -- Cancela deuda salarial; no vuelve a reconocer el gasto devengado.
        INSERT dbo.AccountingEntries(AccountingEntryId,EntryNumber,Description,Debit,Credit,DebitAccount,CreditAccount,
            EntryDate,ReferenceType,ReferenceId,PayrollRunId,CashMoveId,OperationKey)
        VALUES(N'entry-'+@PaymentId,N'PAG-'+CONVERT(NVARCHAR(36),@IdempotencyKey),N'Cancelacion de neto salarial',@Amount,@Amount,
            N'Sueldos por pagar',CASE WHEN @Account=N'caja' THEN N'Caja' ELSE N'Banco' END,@Date,N'payroll',@PaymentId,@PayrollRunId,@CashId,@Operation);
        UPDATE dbo.PayrollRuns SET ConfirmedPaymentsTotal=@Paid+@Amount,UpdatedAt=SYSUTCDATETIME() WHERE PayrollRunId=@PayrollRunId;
        UPDATE i SET PaymentStatus=CASE WHEN p.Paid>=i.Net THEN N'pagado' ELSE N'pago_parcial' END,
            PaymentMethod=@PaymentMethod,PaymentReference=@PaymentReference,
            PaymentConfirmedAt=CASE WHEN p.Paid>=i.Net THEN SYSUTCDATETIME() ELSE NULL END
        FROM dbo.PayrollRunItems i JOIN @Allocation x ON x.EmployeeId=i.EmployeeId
        CROSS APPLY(SELECT SUM(a.Amount) AS Paid FROM dbo.PayrollPaymentAllocations a JOIN dbo.PayrollPayments p ON p.PaymentId=a.PaymentId
            WHERE p.PayrollRunId=@PayrollRunId AND p.Status=N'confirmado' AND a.EmployeeId=i.EmployeeId) p
        WHERE i.PayrollRunId=@PayrollRunId;
        INSERT dbo.PayrollHistoryEvents(PayrollRunId,ActorId,ActorName,EventType,PreviousStatus,NewStatus,Description)
        VALUES(@PayrollRunId,@ActorId,@ActorName,N'pago',@Status,@Status,N'Pago '+@PaymentId+N'; importe '+CONVERT(NVARCHAR(30),@Amount));
        COMMIT;
        SELECT N'confirmada' AS Resultado,@PaymentId AS PaymentId,@PayrollRunId AS PayrollRunId,@Amount AS Amount,
            @CashId AS CashMoveId,@Paid+@Amount AS ConfirmedPaymentsTotal,@Net-@Paid-@Amount AS pendingPayment;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
-- Un egreso de nomina no puede anularse aisladamente y dejar el recibo pagado.
CREATE OR ALTER TRIGGER dbo.tr_PayrollCashMoveIntegrity ON dbo.CashMoves AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM deleted d JOIN dbo.PayrollPayments p ON p.CashMoveId=d.CashMoveId AND p.Status=N'confirmado'
        LEFT JOIN inserted i ON i.CashMoveId=d.CashMoveId
        WHERE i.CashMoveId IS NULL OR i.Amount<>d.Amount OR i.Account<>d.Account OR i.MoveDate<>d.MoveDate OR i.MoveState<>d.MoveState)
        THROW 50608, 'El movimiento tiene un pago confirmado. Se requiere un reverso coordinado de nomina.', 1;
END;
GO
CREATE OR ALTER PROCEDURE dbo.usp_PayrollPaymentIntegrityVersion
AS SELECT 30 AS version;
GO
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
    GRANT SELECT ON dbo.PayrollPaymentAllocations TO [raquel_erp_app];
    GRANT EXECUTE ON dbo.usp_RegisterPayrollPayment TO [raquel_erp_app];
    GRANT EXECUTE ON dbo.usp_PayrollPaymentIntegrityVersion TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 23/25: 31_reglas_periodo_y_devengo_nomina.sql */
/* 31: reglas por periodo y devengo separado. DESPUES de 30.
   No cambia tasas del catalogo, no certifica su validez legal ni repara historicos.
   La revision de las reglas sigue siendo responsabilidad del personal autorizado.
   Aplica solamente procedimientos para futuras operaciones. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET QUOTED_IDENTIFIER ON;
GO
IF EXISTS(SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID(N'dbo.PayrollRulesCatalog') AND name=N'UQ_PayrollRulesCatalog_Code')
 ALTER TABLE dbo.PayrollRulesCatalog DROP CONSTRAINT UQ_PayrollRulesCatalog_Code;
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.PayrollRulesCatalog') AND name=N'UQ_PayrollRulesCatalog_CodeDate')
 CREATE UNIQUE INDEX UQ_PayrollRulesCatalog_CodeDate ON dbo.PayrollRulesCatalog(RuleCode,EffectiveFrom);
GO
IF NOT EXISTS(SELECT 1 FROM dbo.ChartOfAccounts WHERE AccountName=N'Otras deducciones por pagar')
 INSERT dbo.ChartOfAccounts(AccountName,AccountType) VALUES(N'Otras deducciones por pagar',N'pasivo');
GO
IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.PayrollInstitutionalObligations') AND name=N'DueDate' AND is_nullable=0)
 ALTER TABLE dbo.PayrollInstitutionalObligations ALTER COLUMN DueDate DATE NULL;
GO
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
    DECLARE @PeriodsInYear DECIMAL(9,4);
    DECLARE @StartDate DATE,@EndDate DATE;
    DECLARE @InssLab DECIMAL(9,6),@InssPat DECIMAL(9,6),@Inatec DECIMAL(9,6),
        @Prov DECIMAL(9,6),@VacProv DECIMAL(9,6),@IndemProv DECIMAL(9,6),@RulesSnapshot NVARCHAR(MAX);
    DECLARE @Rules TABLE(RuleCode NVARCHAR(40),RuleId NVARCHAR(100),ParameterJson NVARCHAR(MAX),EffectiveFrom DATE,EffectiveTo DATE);
    DECLARE @Brackets TABLE(LowerBound DECIMAL(19,2),UpperBound DECIMAL(19,2),Rate DECIMAL(9,6),BaseAmount DECIMAL(19,4),Excess DECIMAL(19,2));
    BEGIN TRY
        BEGIN TRANSACTION;
    SELECT @StartDate=StartDate,@EndDate=EndDate, @CurrentStatus = Status,
           @PeriodType = PeriodType,
           @CalcVer = CalculationVersion,
           @CurrentRev = CONVERT(VARBINARY(8), Revision)
    FROM dbo.PayrollRuns WITH (UPDLOCK, HOLDLOCK)
    WHERE PayrollRunId = @PayrollRunId;

    IF @CurrentStatus IS NULL
        THROW 50503, 'La planilla solicitada no existe.', 1;

    IF @ExpectedRevision IS NULL OR @CurrentRev <> @ExpectedRevision
        THROW 50504, 'La planilla fue modificada por otro usuario (revision desfasada). Recarga la pantalla.', 1;

    IF @CurrentStatus IN (N'aprobada', N'pago_registrado', N'conciliada', N'cerrada')
        THROW 50505, 'No se puede recalcular una planilla que ya ha sido aprobada, pagada o cerrada.', 1;

    INSERT @Rules SELECT RuleCode,RuleId,ParameterJson,EffectiveFrom,EffectiveTo
    FROM dbo.PayrollRulesCatalog WITH(HOLDLOCK)
    WHERE RuleCode IN(N'INSS_LABORAL',N'INSS_PATRONAL',N'INATEC_PATRONAL',N'IR_PROGRESIVO',N'AGUINALDO_PROV',N'VACACIONES_PROV',N'INDEMNIZACION_PROV')
      AND Status IN(N'vigente',N'historica') AND IsVerified=1 AND EffectiveFrom<=@StartDate AND (EffectiveTo IS NULL OR EffectiveTo>=@EndDate);
    IF (SELECT COUNT(DISTINCT RuleCode) FROM @Rules)<>7 OR EXISTS(SELECT RuleCode FROM @Rules GROUP BY RuleCode HAVING COUNT(*)<>1)
        THROW 50620,'Faltan reglas unicas verificadas que cubran todo el periodo. Revisa vigencias o divide el periodo.',1;
    SELECT @InssLab=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'INSS_LABORAL';
    SELECT @InssPat=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate_used')) FROM @Rules WHERE RuleCode=N'INSS_PATRONAL';
    SELECT @Inatec=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'INATEC_PATRONAL';
    SELECT @Prov=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'AGUINALDO_PROV';
    SELECT @VacProv=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'VACACIONES_PROV';
    SELECT @IndemProv=TRY_CONVERT(DECIMAL(9,6),JSON_VALUE(ParameterJson,'$.rate')) FROM @Rules WHERE RuleCode=N'INDEMNIZACION_PROV';
    IF EXISTS(SELECT 1 FROM (VALUES(@InssLab),(@InssPat),(@Inatec),(@Prov),(@VacProv),(@IndemProv)) r(rate) WHERE rate IS NULL OR rate<0 OR rate>1)
        THROW 50620,'Las tasas verificadas estan incompletas o fuera de rango. No se aplican valores por defecto.',1;
    INSERT @Brackets SELECT b.LowerBound,b.UpperBound,b.Rate,b.BaseAmount,b.Excess
    FROM @Rules r CROSS APPLY OPENJSON(r.ParameterJson,'$.brackets') WITH(
        LowerBound DECIMAL(19,2) '$.from',UpperBound DECIMAL(19,2) '$.to',Rate DECIMAL(9,6) '$.rate',
        BaseAmount DECIMAL(19,4) '$.base',Excess DECIMAL(19,2) '$.excess') b WHERE r.RuleCode=N'IR_PROGRESIVO';
    IF NOT EXISTS(SELECT 1 FROM @Brackets) OR EXISTS(SELECT 1 FROM @Brackets WHERE LowerBound IS NULL OR LowerBound<0 OR Rate IS NULL OR Rate<0 OR Rate>1
        OR BaseAmount IS NULL OR BaseAmount<0 OR Excess IS NULL OR Excess<0 OR (UpperBound IS NOT NULL AND UpperBound<LowerBound))
        THROW 50620,'Los tramos del catalogo IR estan incompletos o son invalidos.',1;
    IF (SELECT COUNT(*) FROM @Brackets WHERE UpperBound IS NULL)<>1
        OR (SELECT MIN(LowerBound) FROM @Brackets)>0.01
        OR EXISTS(SELECT 1 FROM (SELECT LowerBound,UpperBound,LAG(UpperBound) OVER(ORDER BY LowerBound) AS PreviousUpper,
            ROW_NUMBER() OVER(ORDER BY LowerBound) AS rn FROM @Brackets) b
            WHERE rn>1 AND (PreviousUpper IS NULL OR LowerBound<>PreviousUpper+0.01))
        THROW 50620,'El catalogo IR tiene tramos superpuestos o sin cobertura.',1;
    SET @RulesSnapshot=(SELECT * FROM @Rules ORDER BY RuleCode FOR JSON PATH);
    SET @PeriodsInYear = CASE
        WHEN @PeriodType = N'quincenal' THEN 24.0
        WHEN @PeriodType = N'catorcenal' THEN 26.0
        ELSE 12.0
    END;

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
            WHERE EmployeeId = i.EmployeeId AND (PayrollRunId = @PayrollRunId OR (PayrollRunId IS NULL AND PeriodDate BETWEEN @StartDate AND @EndDate))
              AND Status IN (N'autorizada', N'procesada')
        ) AS nov
        WHERE i.PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET Gross = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2),
            InssBase = ROUND(OrdinarySalary + OvertimeAmount + BonusesAmount + CommissionsAmount + VacationDisfruteAmount + OtherTaxableIncome, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET InssLaboral = ROUND(InssBase * @InssLab, 2)
        WHERE PayrollRunId = @PayrollRunId;

        IF EXISTS(SELECT 1 FROM dbo.PayrollRunItems i WHERE i.PayrollRunId=@PayrollRunId AND ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2)>0
            AND (SELECT COUNT(*) FROM @Brackets b WHERE ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2)>=b.LowerBound
             AND (b.UpperBound IS NULL OR ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2)<=b.UpperBound))<>1)
            THROW 50620,'La base anual no tiene exactamente un tramo IR aplicable.',1;
        UPDATE i SET IrBase=i.Gross-i.InssLaboral,
            IncomeTax=CASE WHEN p.AnnualBase<=0 THEN 0 ELSE ROUND((b.BaseAmount+(p.AnnualBase-b.Excess)*b.Rate)/@PeriodsInYear,2) END
        FROM dbo.PayrollRunItems i CROSS APPLY(SELECT ROUND((i.Gross-i.InssLaboral)*@PeriodsInYear,2) AS AnnualBase) p
        OUTER APPLY(SELECT * FROM @Brackets WHERE p.AnnualBase>=LowerBound AND (UpperBound IS NULL OR p.AnnualBase<=UpperBound)) b
        WHERE i.PayrollRunId=@PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET TotalDeductions = ROUND(InssLaboral + IncomeTax + OtherDeductions, 2),
            Net = ROUND(Gross - (InssLaboral + IncomeTax + OtherDeductions), 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET InssPatronal = ROUND(Gross * @InssPat, 2),
            Inatec = ROUND(Gross * @Inatec, 2),
            Aguinaldo = ROUND(Gross * @Prov, 2),
            VacacionesProv = ROUND(Gross * @VacProv, 2),
            IndemnizacionProv = ROUND(Gross * @IndemProv, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE dbo.PayrollRunItems
        SET EmployerCost = ROUND(Gross + InssPatronal + Inatec + Aguinaldo + VacacionesProv + IndemnizacionProv, 2)
        WHERE PayrollRunId = @PayrollRunId;

        UPDATE i
        SET CalculationExplanationJson = (
            SELECT
                i.OrdinarySalary AS [salario_ordinario],
                i.OvertimeAmount AS [horas_extra_monto],
                i.OvertimeHours AS [horas_extra_cantidad],
                i.BonusesAmount AS [bonos],
                i.CommissionsAmount AS [comisiones],
                i.Gross AS [total_devengado],
                CONVERT(NVARCHAR(20), @InssLab * 100) + N'% sobre devengado (catalogo INSS_LABORAL vigente)' AS [inss_laboral_regla],
                i.InssLaboral AS [inss_laboral_monto],
                N'Tarifa progresiva anual Ley 822 Art. 96 (catalogo IR_PROGRESIVO)' AS [ir_laboral_regla],
                i.IrBase AS [ir_base_periodo],
                i.IncomeTax AS [ir_laboral_monto],
                i.OtherDeductions AS [otras_deducciones],
                i.TotalDeductions AS [total_deducciones],
                i.Net AS [salario_neto_a_pagar],
                CONVERT(NVARCHAR(20), @InssPat * 100) + N'% INSS patronal + ' + CONVERT(NVARCHAR(20), @Inatec * 100) + N'% INATEC (no se descuentan al trabajador)' AS [aportes_patronales_regla],
                i.InssPatronal AS [inss_patronal],
                i.Inatec AS [inatec],
                N'Tasas del catalogo verificado para el periodo' AS [provisiones_regla],
                i.Aguinaldo AS [provision_aguinaldo],
                i.VacacionesProv AS [provision_vacaciones],
                i.IndemnizacionProv AS [provision_indemnizacion],
                i.EmployerCost AS [costo_total_empresa],
                @InssLab AS [tasa_inss_laboral],
                @InssPat AS [tasa_inss_patronal],
                @Inatec AS [tasa_inatec],
                @StartDate AS [vigencia_inicio],@EndDate AS [vigencia_fin],JSON_QUERY(@RulesSnapshot) AS [reglas_aplicadas]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
        FROM dbo.PayrollRunItems i
        WHERE i.PayrollRunId = @PayrollRunId;

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

        UPDATE dbo.PayrollRuns SET ReviewedAt=NULL,ReviewedByAppUserId=NULL,ApprovedAt=NULL,ApprovedByAppUserId=NULL
        WHERE PayrollRunId=@PayrollRunId;
        DELETE FROM dbo.PayrollValidations WHERE PayrollRunId = @PayrollRunId;

        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_NETO_INVALIDO',
               N'El trabajador tiene un salario neto menor o igual a cero (C$ ' + CAST(Net AS NVARCHAR(30)) + N'). Revisa las deducciones aplicadas.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Net <= 0;

        INSERT INTO dbo.PayrollValidations (ValidationId, PayrollRunId, EmployeeId, Severity, RuleCode, Message, TargetTab)
        SELECT CONVERT(NVARCHAR(36), NEWID()), @PayrollRunId, EmployeeId, N'bloqueante', N'VAL_DEVENGADO_CERO',
               N'El colaborador no registra salario ordinario ni devengado en el periodo.',
               N'trabajadores'
        FROM dbo.PayrollRunItems
        WHERE PayrollRunId = @PayrollRunId AND Gross <= 0;

        INSERT INTO dbo.PayrollHistoryEvents (
            PayrollRunId, ActorId, ActorName, EventType, PreviousStatus, NewStatus, Description
        )
        VALUES (
            @PayrollRunId, @ActorId, @ActorName, N'calculo', @CurrentStatus, N'calculada',
            N'Calculo con reglas vigentes INSS ' + CONVERT(NVARCHAR(20), @InssLab) + N' / patronal ' + CONVERT(NVARCHAR(20), @InssPat) + N'.'
        );

        COMMIT TRANSACTION;

        SELECT r.PayrollRunId AS id, r.Period AS period, r.Status AS status,
               r.CalculationVersion AS calculationVersion,
               r.Gross AS grossTotal, r.InssLaboral AS inssLaboralTotal,
               r.IncomeTax AS incomeTaxTotal, r.TotalDeductions AS totalDeductions,
               r.Net AS netTotal,
               r.InssPatronal AS inssPatronalTotal, r.Inatec AS inatecTotal,
               r.EmployerCost AS employerCostTotal,
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

    BEGIN TRY
        BEGIN TRANSACTION;
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

    IF @ExpectedRevision IS NULL OR @CurrentRev <> @ExpectedRevision
        THROW 50507, 'La planilla fue actualizada por otro usuario. Recarga la información.', 1;

    IF @TargetStatus NOT IN(N'borrador',N'calculada',N'revisada',N'aprobada',N'pago_registrado',N'conciliada',N'cerrada')
        THROW 50621,'Estado de destino invalido.',1;
    IF @TargetStatus IN(N'borrador',N'calculada') AND (@CurrentStatus IN(N'aprobada',N'pago_registrado',N'conciliada',N'cerrada')
        OR EXISTS(SELECT 1 FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado'))
        THROW 50621,'Una planilla con devengo aprobado o pagos requiere un reverso o ajuste, no retroceso directo.',1;
    IF @TargetStatus IN(N'revisada',N'aprobada') AND EXISTS(SELECT 1 FROM dbo.PayrollRuns r WHERE PayrollRunId=@PayrollRunId AND
        (ABS(r.Gross-r.TotalDeductions-r.Net)>0.01 OR r.TotalDeductions<>(SELECT ISNULL(SUM(TotalDeductions),0) FROM dbo.PayrollRunItems WHERE PayrollRunId=@PayrollRunId)))
        THROW 50621,'Los importes de cabecera y detalle no son coherentes.',1;
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
        IF @ActorId = @PreparedBy OR EXISTS(SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId=@PayrollRunId AND CalculatedByAppUserId=@ActorId)
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
               @ConfirmedTotal = (SELECT ISNULL(SUM(Amount),0) FROM dbo.PayrollPayments WHERE PayrollRunId=@PayrollRunId AND Status=N'confirmado')
        FROM dbo.PayrollRuns
        WHERE PayrollRunId = @PayrollRunId;

        IF @TargetStatus IN (N'calculada', N'revisada', N'aprobada') AND @CalculatedAt IS NULL
            THROW 50593, 'La planilla no tiene un calculo confirmado. Ejecute el calculo antes de avanzar de estado.', 1;

        IF @TargetStatus IN (N'revisada', N'aprobada') AND @CalcStale = 1
            THROW 50594, 'El calculo quedo desactualizado por cambios en trabajadores o novedades. Recalcula antes de revisar o aprobar.', 1;

        IF @TargetStatus = N'pago_registrado' AND @ConfirmedTotal <= 0
            THROW 50596, 'No hay pagos confirmados para esta planilla. Registre el pago del neto pendiente antes de marcar el estado.', 1;

        IF @TargetStatus IN (N'conciliada', N'cerrada') AND @ConfirmedTotal <> @NetTotal
            THROW 50597, 'La planilla aun tiene saldo pendiente por pagar; no puede conciliarse ni cerrarse.', 1;

        IF @TargetStatus IN(N'pago_registrado',N'conciliada',N'cerrada') AND EXISTS(SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId=@PayrollRunId AND ISNULL(ConfirmedPaymentsTotal,0)<>@ConfirmedTotal)
            THROW 50621,'El acumulado de pagos no coincide con los recibos confirmados. Requiere conciliacion.',1;
        IF @TargetStatus IN(N'conciliada',N'cerrada') AND (NULLIF(LTRIM(RTRIM(@Notes)),N'') IS NULL
            OR EXISTS(SELECT 1 FROM dbo.PayrollRuns WHERE PayrollRunId=@PayrollRunId AND ISNULL(PendingDiscrepancyTotal,0)<>0))
            THROW 50621,'Documenta la conciliacion y resuelve las diferencias antes de conciliar o cerrar.',1;
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
            IF EXISTS(SELECT 1 FROM dbo.AccountingEntries WHERE PayrollRunId=@PayrollRunId)
                OR EXISTS(SELECT 1 FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId=@PayrollRunId)
                THROW 50621,'La planilla ya tiene devengo u obligaciones. Requiere revision de origen, no recontabilizacion automatica.',1;
            -- Generar Asiento Contable Equilibrado de Nómina (Partida Doble)
            DECLARE @EntryId NVARCHAR(100) = N'entry-nom-' + @PayrollRunId;
            DECLARE @EntryNumber NVARCHAR(80) = N'AST-NOM-' + REPLACE(@Period, N' ', N'-');

            -- Verificar si ya existe asiento para actualizar o crear
            IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryId)
            BEGIN
                -- 1. Asiento de Gasto de Nómina vs Pasivos Laborales
                -- Débito: Gasto de Nómina (Devengado)
                -- Crédito: Sueldos por pagar (Neto), INSS por pagar (Laboral), IR por pagar (Laboral)
                DECLARE @OtherDeductions DECIMAL(19,4)=@GrossTotal-@NetTotal-@InssLaboral-@IncomeTax;
                IF @OtherDeductions<0 THROW 50621,'Las deducciones no cuadran con el devengado.',1;
                INSERT dbo.AccountingEntries(AccountingEntryId,EntryNumber,Description,Debit,Credit,DebitAccount,CreditAccount,EntryDate,ReferenceType,ReferenceId,PayrollRunId,OperationKey)
                SELECT @EntryId+suffix,LEFT(@EntryNumber,60)+suffix,N'Devengo separado: '+accountName,amount,amount,N'Nómina',accountName,
                    SYSUTCDATETIME(),N'payroll',@PayrollRunId,@PayrollRunId,N'nomina-devengo:'+@PayrollRunId+suffix
                FROM (VALUES(N'',N'Sueldos por pagar',@NetTotal),(N'-inss',N'INSS por pagar',@InssLaboral),
                    (N'-ir',N'IR por pagar',@IncomeTax),(N'-otros',N'Otras deducciones por pagar',@OtherDeductions)) v(suffix,accountName,amount)
                WHERE amount>0;

                -- 2. Asiento de Cargas Sociales Patronales (INSS Patronal + INATEC)
                DECLARE @EntryPatronalId NVARCHAR(100) = N'entry-pat-' + @PayrollRunId;
                DECLARE @EntryPatronalNum NVARCHAR(80) = N'AST-PAT-' + REPLACE(@Period, N' ', N'-');
                DECLARE @TotalCargasPatronales DECIMAL(19,4) = @InssPatronal + @Inatec;

                IF NOT EXISTS (SELECT 1 FROM dbo.AccountingEntries WHERE AccountingEntryId = @EntryPatronalId)
                BEGIN
                    INSERT dbo.AccountingEntries(AccountingEntryId,EntryNumber,Description,Debit,Credit,DebitAccount,CreditAccount,EntryDate,ReferenceType,ReferenceId,PayrollRunId,OperationKey)
                    SELECT @EntryPatronalId+suffix,LEFT(@EntryPatronalNum,60)+suffix,N'Aporte patronal separado: '+accountName,amount,amount,
                        N'Aporte patronal INSS e INATEC',accountName,SYSUTCDATETIME(),N'payroll',@PayrollRunId,@PayrollRunId,N'nomina-devengo:'+@PayrollRunId+N'-pat'+suffix
                    FROM (VALUES(N'',N'INSS por pagar',@InssPatronal),(N'-inatec',N'INATEC por pagar',@Inatec)) v(suffix,accountName,amount)
                    WHERE amount>0;
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
                (N'ob-ir-' + @PayrollRunId, @PayrollRunId, N'DGI', @Period, @GrossTotal - @InssLaboral, @IncomeTax, NULL, N'pendiente_vencimiento'),
                (N'ob-inss-' + @PayrollRunId, @PayrollRunId, N'INSS', @Period, @GrossTotal, (@InssLaboral + @InssPatronal), DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente_vencimiento'),
                (N'ob-inatec-' + @PayrollRunId, @PayrollRunId, N'INATEC', @Period, @GrossTotal, @Inatec, DATEADD(DAY, 15, CAST(GETDATE() AS DATE)), N'pendiente_vencimiento'),
                (N'ob-prov-' + @PayrollRunId, @PayrollRunId, N'PROVISIONES_PASIVO', @Period, @GrossTotal, (@AguinaldoProv + @VacacionesProv + @IndemnizacionProv), NULL, N'provisionada');
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
                PaidAt = CASE WHEN @ConfirmedTotal=@NetTotal THEN TODATETIMEOFFSET(SYSUTCDATETIME(), N'+00:00') ELSE NULL END,
                PaymentNotes = @Notes,
                CashMoveId = NULL, -- los movimientos se consultan en los recibos individuales
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

            -- Las obligaciones existentes conservan sus referencias, estados y vencimientos.

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
CREATE OR ALTER PROCEDURE dbo.usp_PayrollAccrualIntegrityVersion AS SELECT 31 AS version;
GO
IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
BEGIN
 GRANT EXECUTE ON dbo.usp_CalculatePayroll TO [raquel_erp_app];
 GRANT EXECUTE ON dbo.usp_TransitionPayrollStatus TO [raquel_erp_app];
 GRANT EXECUTE ON dbo.usp_PayrollAccrualIntegrityVersion TO [raquel_erp_app];
END;
GO

GO

/* ARCHIVO 24/25: 32_conservar_enlaces_snapshot.sql */
/* 32: preservar enlaces de operaciones confirmadas al sincronizar.
   Parche limitado a siete instrucciones conocidas. Si la definicion vigente
   difiere, aborta y exige revision; no sustituye toda la logica con una version antigua.
   Respalda el procedimiento. No modifica datos de negocio ni cuentas. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
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

GO

/* ARCHIVO 25/25: 33_eventos_novedades_nomina.sql */
/* 33: completar auditoria de novedades en instalaciones que no aplicaron 25_operaciones_hr_nomina.
   Solo estructura y permisos ya previstos en 25. No carga ni modifica datos operativos. */
USE [Raquel_Schema_Check_20261025_99ef80cc];
GO
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
GO
BEGIN TRY
 BEGIN TRANSACTION;
 IF OBJECT_ID(N'dbo.PayrollNoveltyEvents',N'U') IS NULL
 CREATE TABLE dbo.PayrollNoveltyEvents(
  EventId BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PayrollNoveltyEvents PRIMARY KEY,
  NoveltyId NVARCHAR(100) NOT NULL,ActorId NVARCHAR(100) NOT NULL,ActorName NVARCHAR(240) NOT NULL,
  EventType NVARCHAR(40) NOT NULL,Detail NVARCHAR(1000) NULL,
  OccurredAt DATETIMEOFFSET(3) NOT NULL CONSTRAINT DF_PayrollNoveltyEvents_At DEFAULT (TODATETIMEOFFSET(SYSUTCDATETIME(),N'+00:00'))
 );
 IF DATABASE_PRINCIPAL_ID(N'raquel_erp_app') IS NOT NULL
  GRANT SELECT,INSERT ON dbo.PayrollNoveltyEvents TO [raquel_erp_app];
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO

GO

SET NOEXEC OFF;
GO

/* 02 — Gobierno (usuarios, auditoría, snapshot) y maestros (terceros, productos, empleados) */
USE [Instalaciones Raquel];
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

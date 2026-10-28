/* 03 — Inventario PEPS y ciclo comercial (ventas, proformas, compras, álbum) */
USE [Instalaciones Raquel];
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

/* 07 — Guarda el JSON del ERP y normaliza las 19 colecciones en tablas + FKs */
USE [Instalaciones Raquel];
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

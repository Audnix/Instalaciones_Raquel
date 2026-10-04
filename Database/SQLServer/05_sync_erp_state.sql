USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_SaveErpState
    @Payload NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISJSON(@Payload) <> 1
        THROW 50100, 'El estado recibido no contiene JSON valido.', 1;

    DECLARE @RequiredCollections TABLE
    (
        CollectionName SYSNAME NOT NULL,
        JsonArray NVARCHAR(MAX) NULL
    );

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

    IF EXISTS
    (
        SELECT 1
        FROM @RequiredCollections
        WHERE JsonArray IS NULL
           OR ISJSON(JsonArray) <> 1
           OR LEFT(LTRIM(JsonArray), 1) <> N'['
    )
        THROW 50101, 'El estado debe incluir las 19 colecciones del ERP como arreglos JSON.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

                INSERT INTO dbo.Warehouses (WarehouseId)
                SELECT DISTINCT lot.WarehouseId
                FROM OPENJSON(@Payload, '$.lots')
                WITH (WarehouseId NVARCHAR(160) '$.warehouseId') AS lot
                WHERE lot.WarehouseId IS NOT NULL
                    AND NOT EXISTS (SELECT 1 FROM dbo.Warehouses AS warehouse WHERE warehouse.WarehouseId = lot.WarehouseId);

                INSERT INTO dbo.ChartOfAccounts (AccountName)
                SELECT DISTINCT account.AccountName
                FROM OPENJSON(@Payload, '$.accounting')
                WITH
                (
                        DebitAccount NVARCHAR(200) '$.debitAccount',
                        CreditAccount NVARCHAR(200) '$.creditAccount'
                ) AS entry
                CROSS APPLY (VALUES (entry.DebitAccount), (entry.CreditAccount)) AS account(AccountName)
                WHERE account.AccountName IS NOT NULL
                    AND NOT EXISTS (SELECT 1 FROM dbo.ChartOfAccounts AS chart WHERE chart.AccountName = account.AccountName);

                INSERT INTO dbo.FinanceCategories (CategoryName)
                SELECT DISTINCT move.Category
                FROM OPENJSON(@Payload, '$.finance')
                WITH (Category NVARCHAR(160) '$.category') AS move
                WHERE move.Category IS NOT NULL
                    AND NOT EXISTS (SELECT 1 FROM dbo.FinanceCategories AS category WHERE category.CategoryName = move.Category);

        UPDATE dbo.ErpState
        SET Payload = @Payload,
            UpdatedAt = SYSUTCDATETIME()
        WHERE StateId = 1;

        IF @@ROWCOUNT = 0
            INSERT INTO dbo.ErpState (StateId, Payload) VALUES (1, @Payload);

        DELETE FROM dbo.SaleItems;
        DELETE FROM dbo.ProformaItems;
        DELETE FROM dbo.PurchaseItems;
        DELETE FROM dbo.CatalogAlbumProducts;
        DELETE FROM dbo.AppUserAreas;
        DELETE FROM dbo.PayrollRunItems;
        DELETE FROM dbo.AccountingEntries;
        DELETE FROM dbo.FinanceMoves;
        DELETE FROM dbo.CashMoves;
        DELETE FROM dbo.ProductionOrders;
        DELETE FROM dbo.Projects;
        DELETE FROM dbo.Sales;
        DELETE FROM dbo.Proformas;
        DELETE FROM dbo.Purchases;
        DELETE FROM dbo.KardexMoves;
        DELETE FROM dbo.InventoryLots;
        DELETE FROM dbo.Employees;
        DELETE FROM dbo.PayrollRuns;
        DELETE FROM dbo.CatalogAlbums;
        DELETE FROM dbo.Products;
        DELETE FROM dbo.Parties;
        DELETE FROM dbo.Promotions;
        DELETE FROM dbo.Projections;
        DELETE FROM dbo.AppUsers;
        DELETE FROM dbo.AuditEvents;

        INSERT INTO dbo.Products
        (
            ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
            ImageUrl, Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
        )
        SELECT ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
               ImageUrl, Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
        FROM OPENJSON(@Payload, '$.products')
        WITH
        (
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
        );

        INSERT INTO dbo.InventoryLots (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
        SELECT LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId
        FROM OPENJSON(@Payload, '$.lots')
        WITH
        (
            LotId NVARCHAR(100) '$.id',
            ProductId NVARCHAR(100) '$.productId',
            Quantity DECIMAL(19,4) '$.quantity',
            UnitCost DECIMAL(19,4) '$.unitCost',
            EntryDate DATETIMEOFFSET(3) '$.entryDate',
            WarehouseId NVARCHAR(160) '$.warehouseId'
        );

        INSERT INTO dbo.KardexMoves
        (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
        SELECT KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName
        FROM OPENJSON(@Payload, '$.kardex')
        WITH
        (
            KardexMoveId NVARCHAR(100) '$.id',
            ProductId NVARCHAR(100) '$.productId',
            MoveType NVARCHAR(20) '$.type',
            Quantity DECIMAL(19,4) '$.quantity',
            UnitCost DECIMAL(19,4) '$.unitCost',
            MoveDate DATETIMEOFFSET(3) '$.date',
            Reason NVARCHAR(500) '$.reason',
            UserName NVARCHAR(200) '$.userName'
        );

        INSERT INTO dbo.Sales
        (SaleId, SaleNumber, ClientName, Subtotal, DiscountAmount, PromoCode, TaxAmount, Total, Status, SaleDate, CreatedBy, QrPayload)
        SELECT SaleId, SaleNumber, ClientName, Subtotal, DiscountAmount, PromoCode, TaxAmount, Total, Status, SaleDate, CreatedBy, QrPayload
        FROM OPENJSON(@Payload, '$.sales')
        WITH
        (
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
            QrPayload NVARCHAR(MAX) '$.qrPayload',
            Items NVARCHAR(MAX) '$.items' AS JSON
        );

        INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
        SELECT sale.SaleId, CONVERT(INT, item.[key]) + 1,
               JSON_VALUE(item.value, '$.productId'),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.quantity')),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.unitPrice'))
        FROM OPENJSON(@Payload, '$.sales')
        WITH (SaleId NVARCHAR(100) '$.id', Items NVARCHAR(MAX) '$.items' AS JSON) AS sale
        CROSS APPLY OPENJSON(sale.Items) AS item;

        INSERT INTO dbo.Proformas
        (ProformaId, ProformaNumber, ClientName, Subtotal, DiscountAmount, PromoCode, TaxAmount, Total, Status, ValidUntil, Notes, CreatedAt, CreatedBy, QrPayload, ConvertedSaleId)
        SELECT ProformaId, ProformaNumber, ClientName, Subtotal, DiscountAmount, PromoCode, TaxAmount, Total, Status, ValidUntil, Notes, CreatedAt, CreatedBy, QrPayload, ConvertedSaleId
        FROM OPENJSON(@Payload, '$.proformas')
        WITH
        (
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
        CROSS APPLY OPENJSON(proforma.Items) AS item;

        INSERT INTO dbo.Promotions (PromotionId, Title, Blurb, MinSubtotal, PercentOff, IsActive, Badge)
        SELECT PromotionId, Title, Blurb, MinSubtotal, PercentOff, IsActive, Badge
        FROM OPENJSON(@Payload, '$.promotions')
        WITH
        (
            PromotionId NVARCHAR(100) '$.id',
            Title NVARCHAR(200) '$.title',
            Blurb NVARCHAR(1000) '$.blurb',
            MinSubtotal DECIMAL(19,4) '$.minSubtotal',
            PercentOff DECIMAL(9,4) '$.percentOff',
            IsActive BIT '$.active',
            Badge NVARCHAR(120) '$.badge'
        );

        INSERT INTO dbo.Purchases (PurchaseId, PurchaseNumber, SupplierName, Total, Status, PurchaseDate, CreatedBy)
        SELECT PurchaseId, PurchaseNumber, SupplierName, Total, Status, PurchaseDate, CreatedBy
        FROM OPENJSON(@Payload, '$.purchases')
        WITH
        (
            PurchaseId NVARCHAR(100) '$.id',
            PurchaseNumber NVARCHAR(80) '$.purchaseNumber',
            SupplierName NVARCHAR(240) '$.supplierName',
            Total DECIMAL(19,4) '$.total',
            Status NVARCHAR(20) '$.status',
            PurchaseDate DATETIMEOFFSET(3) '$.purchaseDate',
            CreatedBy NVARCHAR(200) '$.createdBy',
            Items NVARCHAR(MAX) '$.items' AS JSON
        );

        INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)
        SELECT purchase.PurchaseId, CONVERT(INT, item.[key]) + 1,
               JSON_VALUE(item.value, '$.productId'),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.quantity')),
               TRY_CONVERT(DECIMAL(19,4), JSON_VALUE(item.value, '$.unitPrice'))
        FROM OPENJSON(@Payload, '$.purchases')
        WITH (PurchaseId NVARCHAR(100) '$.id', Items NVARCHAR(MAX) '$.items' AS JSON) AS purchase
        CROSS APPLY OPENJSON(purchase.Items) AS item;

        INSERT INTO dbo.AccountingEntries
        (AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId)
        SELECT AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId
        FROM OPENJSON(@Payload, '$.accounting')
        WITH
        (
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
        );

        INSERT INTO dbo.FinanceMoves (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
        SELECT FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName
        FROM OPENJSON(@Payload, '$.finance')
        WITH
        (
            FinanceMoveId NVARCHAR(100) '$.id',
            MoveType NVARCHAR(20) '$.type',
            Category NVARCHAR(160) '$.category',
            Amount DECIMAL(19,4) '$.amount',
            MoveDate DATETIMEOFFSET(3) '$.date',
            Note NVARCHAR(1000) '$.note',
            UserName NVARCHAR(200) '$.userName'
        );

        INSERT INTO dbo.Projections (ProjectionId, MonthLabel, ExpectedSales, ExpectedCosts)
        SELECT ProjectionId, MonthLabel, ExpectedSales, ExpectedCosts
        FROM OPENJSON(@Payload, '$.projections')
        WITH
        (
            ProjectionId NVARCHAR(100) '$.id',
            MonthLabel NVARCHAR(40) '$.month',
            ExpectedSales DECIMAL(19,4) '$.expectedSales',
            ExpectedCosts DECIMAL(19,4) '$.expectedCosts'
        );

        INSERT INTO dbo.ProductionOrders (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)
        SELECT ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner
        FROM OPENJSON(@Payload, '$.production')
        WITH
        (
            ProductionOrderId NVARCHAR(100) '$.id',
            Code NVARCHAR(80) '$.code',
            Product NVARCHAR(240) '$.product',
            Client NVARCHAR(240) '$.client',
            Quantity DECIMAL(19,4) '$.qty',
            Stage NVARCHAR(30) '$.stage',
            Sprint NVARCHAR(100) '$.sprint',
            Owner NVARCHAR(200) '$.owner'
        );

        INSERT INTO dbo.Parties (PartyId, Name, Contact, Phone, PartyType)
        SELECT PartyId, Name, Contact, Phone, PartyType
        FROM OPENJSON(@Payload, '$.parties')
        WITH
        (
            PartyId NVARCHAR(100) '$.id',
            Name NVARCHAR(240) '$.name',
            Contact NVARCHAR(200) '$.contact',
            Phone NVARCHAR(80) '$.phone',
            PartyType NVARCHAR(20) '$.type'
        );

                UPDATE salesRow
                SET ClientPartyId = party.PartyId
                FROM dbo.Sales AS salesRow
                OUTER APPLY
                (
                        SELECT TOP (1) PartyId
                        FROM dbo.Parties AS partyRow
                        WHERE partyRow.Name = salesRow.ClientName
                            AND partyRow.PartyType = N'cliente'
                        ORDER BY partyRow.PartyId
                ) AS party;

                UPDATE purchaseRow
                SET SupplierPartyId = party.PartyId
                FROM dbo.Purchases AS purchaseRow
                OUTER APPLY
                (
                        SELECT TOP (1) PartyId
                        FROM dbo.Parties AS partyRow
                        WHERE partyRow.Name = purchaseRow.SupplierName
                            AND partyRow.PartyType = N'proveedor'
                        ORDER BY partyRow.PartyId
                ) AS party;

        INSERT INTO dbo.Employees (EmployeeId, Name, Position, Salary, Area)
        SELECT EmployeeId, Name, Position, Salary, Area
        FROM OPENJSON(@Payload, '$.employees')
        WITH
        (
            EmployeeId NVARCHAR(100) '$.id',
            Name NVARCHAR(240) '$.name',
            Position NVARCHAR(200) '$.position',
            Salary DECIMAL(19,4) '$.salary',
            Area NVARCHAR(120) '$.area'
        );

        INSERT INTO dbo.PayrollRuns
        (PayrollRunId, Period, PaidAt, Actor, Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost)
        SELECT PayrollRunId, Period, PaidAt, Actor, Gross, InssLaboral, InssPatronal, Inatec, IncomeTax, Net, EmployerCost
        FROM OPENJSON(@Payload, '$.payrollRuns')
        WITH
        (
            PayrollRunId NVARCHAR(100) '$.id',
            Period NVARCHAR(40) '$.period',
            PaidAt DATETIMEOFFSET(3) '$.paidAt',
            Actor NVARCHAR(200) '$.actor',
            Gross DECIMAL(19,4) '$.gross',
            InssLaboral DECIMAL(19,4) '$.inssLaboral',
            InssPatronal DECIMAL(19,4) '$.inssPatronal',
            Inatec DECIMAL(19,4) '$.inatec',
            IncomeTax DECIMAL(19,4) '$.ir',
            Net DECIMAL(19,4) '$.net',
            EmployerCost DECIMAL(19,4) '$.employerCost',
            Employees NVARCHAR(MAX) '$.employees' AS JSON
        );

        INSERT INTO dbo.PayrollRunItems
        (PayrollRunId, EmployeeId, Gross, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo, EmployerCost)
        SELECT payroll.PayrollRunId, slip.EmployeeId, slip.Gross, slip.InssLaboral,
               slip.IncomeTax, slip.Net, slip.InssPatronal, slip.Inatec,
               slip.Aguinaldo, slip.EmployerCost
        FROM OPENJSON(@Payload, '$.payrollRuns')
        WITH (PayrollRunId NVARCHAR(100) '$.id', Employees NVARCHAR(MAX) '$.employees' AS JSON) AS payroll
        CROSS APPLY OPENJSON(payroll.Employees)
        WITH
        (
            EmployeeId NVARCHAR(100) '$.employeeId',
            Gross DECIMAL(19,4) '$.gross',
            InssLaboral DECIMAL(19,4) '$.inssLaboral',
            IncomeTax DECIMAL(19,4) '$.ir',
            Net DECIMAL(19,4) '$.net',
            InssPatronal DECIMAL(19,4) '$.inssPatronal',
            Inatec DECIMAL(19,4) '$.inatec',
            Aguinaldo DECIMAL(19,4) '$.aguinaldo',
            EmployerCost DECIMAL(19,4) '$.employerCost'
        ) AS slip;

        INSERT INTO dbo.CatalogAlbums (AlbumId, MonthLabel, Title, Blurb, IsPublished, CreatedAt)
        SELECT AlbumId, MonthLabel, Title, Blurb, IsPublished, CreatedAt
        FROM OPENJSON(@Payload, '$.albums')
        WITH
        (
            AlbumId NVARCHAR(100) '$.id',
            MonthLabel NVARCHAR(40) '$.month',
            Title NVARCHAR(240) '$.title',
            Blurb NVARCHAR(2000) '$.blurb',
            IsPublished BIT '$.published',
            CreatedAt DATETIMEOFFSET(3) '$.createdAt',
            ProductIds NVARCHAR(MAX) '$.productIds' AS JSON
        );

        INSERT INTO dbo.CatalogAlbumProducts (AlbumId, LineNumber, ProductId)
        SELECT album.AlbumId, CONVERT(INT, product.[key]) + 1, product.value
        FROM OPENJSON(@Payload, '$.albums')
        WITH (AlbumId NVARCHAR(100) '$.id', ProductIds NVARCHAR(MAX) '$.productIds' AS JSON) AS album
        CROSS APPLY OPENJSON(album.ProductIds) AS product;

        INSERT INTO dbo.Projects (ProjectId, Code, Name, Client, Amount, Progress, ProjectState, Owner)
        SELECT ProjectId, Code, Name, Client, Amount, Progress, ProjectState, Owner
        FROM OPENJSON(@Payload, '$.projects')
        WITH
        (
            ProjectId NVARCHAR(100) '$.id',
            Code NVARCHAR(80) '$.code',
            Name NVARCHAR(240) '$.name',
            Client NVARCHAR(240) '$.client',
            Amount DECIMAL(19,4) '$.amount',
            Progress DECIMAL(7,4) '$.progress',
            ProjectState NVARCHAR(120) '$.state',
            Owner NVARCHAR(200) '$.owner'
        );

                UPDATE projectRow
                SET ClientPartyId = party.PartyId
                FROM dbo.Projects AS projectRow
                OUTER APPLY
                (
                        SELECT TOP (1) PartyId
                        FROM dbo.Parties AS partyRow
                        WHERE partyRow.Name = projectRow.Client
                            AND partyRow.PartyType = N'cliente'
                        ORDER BY partyRow.PartyId
                ) AS party;

        INSERT INTO dbo.CashMoves (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
        SELECT CashMoveId, Account, MoveType, Amount, MoveDate, Concept
        FROM OPENJSON(@Payload, '$.cash')
        WITH
        (
            CashMoveId NVARCHAR(100) '$.id',
            Account NVARCHAR(20) '$.account',
            MoveType NVARCHAR(20) '$.type',
            Amount DECIMAL(19,4) '$.amount',
            MoveDate DATETIMEOFFSET(3) '$.date',
            Concept NVARCHAR(1000) '$.concept'
        );

        INSERT INTO dbo.AppUsers (AppUserId, Name, Email, Hierarchy, IsActive)
        SELECT AppUserId, Name, Email, Hierarchy, IsActive
        FROM OPENJSON(@Payload, '$.users')
        WITH
        (
            AppUserId NVARCHAR(100) '$.id',
            Name NVARCHAR(240) '$.name',
            Email NVARCHAR(320) '$.email',
            Hierarchy NVARCHAR(30) '$.hierarchy',
            IsActive BIT '$.active',
            Areas NVARCHAR(MAX) '$.areas' AS JSON
        );

        INSERT INTO dbo.AppUserAreas (AppUserId, Area)
        SELECT appUser.AppUserId, area.value
        FROM OPENJSON(@Payload, '$.users')
        WITH (AppUserId NVARCHAR(100) '$.id', Areas NVARCHAR(MAX) '$.areas' AS JSON) AS appUser
        CROSS APPLY OPENJSON(appUser.Areas) AS area;

        INSERT INTO dbo.AuditEvents
        (AuditEventId, OccurredAt, UserName, Action, Module, Detail, Severity, Reference, Uml, Hash, PreviousHash)
        SELECT AuditEventId, OccurredAt, UserName, [Action], [Module], Detail, Severity, [Reference], Uml, Hash, PreviousHash
        FROM OPENJSON(@Payload, '$.audit')
        WITH
        (
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
        );

        UPDATE lot
        SET WarehouseId = warehouse.WarehouseId
        FROM dbo.InventoryLots AS lot
        JOIN dbo.Warehouses AS warehouse ON warehouse.WarehouseId = lot.WarehouseId;

        UPDATE move
        SET FinanceCategoryName = category.CategoryName
        FROM dbo.FinanceMoves AS move
        JOIN dbo.FinanceCategories AS category ON category.CategoryName = move.Category;

        UPDATE entry
        SET DebitAccountRef = debit.AccountName,
            CreditAccountRef = credit.AccountName
        FROM dbo.AccountingEntries AS entry
        JOIN dbo.ChartOfAccounts AS debit ON debit.AccountName = entry.DebitAccount
        JOIN dbo.ChartOfAccounts AS credit ON credit.AccountName = entry.CreditAccount;

        UPDATE projection
        SET MonthNumber = monthLookup.MonthNumber
        FROM dbo.Projections AS projection
        JOIN dbo.ForecastMonths AS monthLookup ON monthLookup.MonthLabel = projection.MonthLabel;

        UPDATE cashMove
        SET CashAccountCode = account.AccountCode
        FROM dbo.CashMoves AS cashMove
        JOIN dbo.CashAccounts AS account ON account.AccountCode = cashMove.Account;

        UPDATE production
        SET ProductionStageCode = stage.StageCode
        FROM dbo.ProductionOrders AS production
        JOIN dbo.ProductionStages AS stage ON stage.StageCode = production.Stage;

        UPDATE employee
        SET AppUserId = appUser.AppUserId
        FROM dbo.Employees AS employee
        JOIN dbo.AppUsers AS appUser ON appUser.Name = employee.Name;

        UPDATE kardex
        SET AppUserId = appUser.AppUserId
        FROM dbo.KardexMoves AS kardex
        JOIN dbo.AppUsers AS appUser ON appUser.Name = kardex.UserName;

        UPDATE auditEvent
        SET AppUserId = appUser.AppUserId
        FROM dbo.AuditEvents AS auditEvent
        JOIN dbo.AppUsers AS appUser ON appUser.Name = auditEvent.UserName;

        UPDATE salesRow
        SET CreatedByUserId = appUser.AppUserId,
            PromotionId = promotion.PromotionId
        FROM dbo.Sales AS salesRow
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = salesRow.CreatedBy) AS appUser
        OUTER APPLY (SELECT TOP (1) PromotionId FROM dbo.Promotions WHERE Title = salesRow.PromoCode) AS promotion;

        UPDATE proforma
        SET ClientPartyId = party.PartyId,
            CreatedByUserId = appUser.AppUserId,
            PromotionId = promotion.PromotionId
        FROM dbo.Proformas AS proforma
        OUTER APPLY (SELECT TOP (1) PartyId FROM dbo.Parties WHERE Name = proforma.ClientName AND PartyType = N'cliente' ORDER BY PartyId) AS party
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = proforma.CreatedBy) AS appUser
        OUTER APPLY (SELECT TOP (1) PromotionId FROM dbo.Promotions WHERE Title = proforma.PromoCode) AS promotion;

        UPDATE purchaseRow
        SET CreatedByUserId = appUser.AppUserId
        FROM dbo.Purchases AS purchaseRow
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = purchaseRow.CreatedBy) AS appUser;

        UPDATE payroll
        SET ActorUserId = appUser.AppUserId
        FROM dbo.PayrollRuns AS payroll
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = payroll.Actor) AS appUser;

        UPDATE production
        SET ClientPartyId = party.PartyId,
            OwnerEmployeeId = employee.EmployeeId
        FROM dbo.ProductionOrders AS production
        OUTER APPLY (SELECT TOP (1) PartyId FROM dbo.Parties WHERE Name = production.Client AND PartyType = N'cliente' ORDER BY PartyId) AS party
        OUTER APPLY (SELECT TOP (1) EmployeeId FROM dbo.Employees WHERE Name = production.Owner ORDER BY EmployeeId) AS employee;

        UPDATE project
        SET OwnerEmployeeId = employee.EmployeeId
        FROM dbo.Projects AS project
        OUTER APPLY (SELECT TOP (1) EmployeeId FROM dbo.Employees WHERE Name = project.Owner ORDER BY EmployeeId) AS employee;

        UPDATE financeMove
        SET AppUserId = appUser.AppUserId,
            SaleId = sale.SaleId,
            PurchaseId = purchase.PurchaseId,
            PayrollRunId = payroll.PayrollRunId
        FROM dbo.FinanceMoves AS financeMove
        OUTER APPLY (SELECT TOP (1) AppUserId FROM dbo.AppUsers WHERE Name = financeMove.UserName) AS appUser
        OUTER APPLY (SELECT TOP (1) SaleId FROM dbo.Sales WHERE financeMove.Note LIKE N'%' + SaleNumber + N'%') AS sale
        OUTER APPLY (SELECT TOP (1) PurchaseId FROM dbo.Purchases WHERE financeMove.Note LIKE N'%' + PurchaseNumber + N'%') AS purchase
        OUTER APPLY (SELECT TOP (1) PayrollRunId FROM dbo.PayrollRuns WHERE financeMove.Note LIKE N'%' + Period + N'%') AS payroll;

        UPDATE cashMove
        SET SaleId = sale.SaleId,
            PurchaseId = purchase.PurchaseId,
            PayrollRunId = payroll.PayrollRunId
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
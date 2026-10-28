/* Persistencia idempotente de proveedores y permisos minimos para la API. */
USE [Instalaciones Raquel];
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

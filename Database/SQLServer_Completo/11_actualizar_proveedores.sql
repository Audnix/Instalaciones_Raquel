/* Actualiza dbo.Parties para administrar el directorio de proveedores. */
USE [Instalaciones Raquel];
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

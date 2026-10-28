/* 01 — Catálogos de dominio (tablas padre de casi todo el ERP) */
USE [Instalaciones Raquel];
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

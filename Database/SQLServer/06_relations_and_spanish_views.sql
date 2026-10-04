USE [Instalaciones Raquel];
GO

IF COL_LENGTH(N'dbo.Sales', N'ClientPartyId') IS NULL
    ALTER TABLE dbo.Sales ADD ClientPartyId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Purchases', N'SupplierPartyId') IS NULL
    ALTER TABLE dbo.Purchases ADD SupplierPartyId NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.Projects', N'ClientPartyId') IS NULL
    ALTER TABLE dbo.Projects ADD ClientPartyId NVARCHAR(100) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.InventoryLots') AND name = N'FK_InventoryLots_Products')
    ALTER TABLE dbo.InventoryLots WITH CHECK ADD CONSTRAINT FK_InventoryLots_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.KardexMoves') AND name = N'FK_KardexMoves_Products')
    ALTER TABLE dbo.KardexMoves WITH CHECK ADD CONSTRAINT FK_KardexMoves_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.SaleItems') AND name = N'FK_SaleItems_Products')
    ALTER TABLE dbo.SaleItems WITH CHECK ADD CONSTRAINT FK_SaleItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.ProformaItems') AND name = N'FK_ProformaItems_Products')
    ALTER TABLE dbo.ProformaItems WITH CHECK ADD CONSTRAINT FK_ProformaItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.PurchaseItems') AND name = N'FK_PurchaseItems_Products')
    ALTER TABLE dbo.PurchaseItems WITH CHECK ADD CONSTRAINT FK_PurchaseItems_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.CatalogAlbumProducts') AND name = N'FK_CatalogAlbumProducts_Products')
    ALTER TABLE dbo.CatalogAlbumProducts WITH CHECK ADD CONSTRAINT FK_CatalogAlbumProducts_Products FOREIGN KEY (ProductId) REFERENCES dbo.Products(ProductId);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.Sales') AND name = N'FK_Sales_ClientParties')
    ALTER TABLE dbo.Sales WITH CHECK ADD CONSTRAINT FK_Sales_ClientParties FOREIGN KEY (ClientPartyId) REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.Purchases') AND name = N'FK_Purchases_SupplierParties')
    ALTER TABLE dbo.Purchases WITH CHECK ADD CONSTRAINT FK_Purchases_SupplierParties FOREIGN KEY (SupplierPartyId) REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE parent_object_id = OBJECT_ID(N'dbo.Projects') AND name = N'FK_Projects_ClientParties')
    ALTER TABLE dbo.Projects WITH CHECK ADD CONSTRAINT FK_Projects_ClientParties FOREIGN KEY (ClientPartyId) REFERENCES dbo.Parties(PartyId) ON DELETE SET NULL;
GO

CREATE OR ALTER VIEW dbo.vw_EstadoERP AS
SELECT StateId AS IdEstado, Payload AS DatosJSON, UpdatedAt AS ActualizadoUTC, Revision AS Version
FROM dbo.ErpState;
GO

CREATE OR ALTER VIEW dbo.vw_Productos AS
SELECT ProductId AS IdProducto, Code AS Codigo, Name AS Nombre, Category AS Categoria,
       UnitPrice AS PrecioUnitario, MinQuantity AS CantidadMinima, CreatedAt AS FechaCreacion,
       ImageUrl AS Imagen, Model AS Modelo, Brand AS Marca, Material AS Material,
       Measures AS Medidas, Capacity AS Capacidad, Finish AS Acabado, ProductUse AS Uso, Warranty AS Garantia
FROM dbo.Products;
GO

CREATE OR ALTER VIEW dbo.vw_LotesInventario AS
SELECT LotId AS IdLote, ProductId AS IdProducto, Quantity AS Cantidad, UnitCost AS CostoUnitario,
       EntryDate AS FechaEntrada, WarehouseId AS Bodega
FROM dbo.InventoryLots;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosKardex AS
SELECT KardexMoveId AS IdMovimiento, ProductId AS IdProducto, MoveType AS Tipo,
       Quantity AS Cantidad, UnitCost AS CostoUnitario, MoveDate AS Fecha,
       Reason AS Motivo, UserName AS Usuario
FROM dbo.KardexMoves;
GO

CREATE OR ALTER VIEW dbo.vw_Ventas AS
SELECT sale.SaleId AS IdVenta, sale.SaleNumber AS NumeroVenta,
       COALESCE(party.Name, sale.ClientName) AS Cliente, sale.ClientPartyId AS IdCliente,
       sale.Subtotal AS Subtotal, sale.DiscountAmount AS Descuento, sale.PromoCode AS Promocion,
       sale.TaxAmount AS Impuesto, sale.Total AS Total, sale.Status AS Estado,
       sale.SaleDate AS FechaVenta, sale.CreatedBy AS CreadoPor, sale.QrPayload AS CodigoQR
FROM dbo.Sales AS sale
LEFT JOIN dbo.Parties AS party ON party.PartyId = sale.ClientPartyId;
GO

CREATE OR ALTER VIEW dbo.vw_DetallesVenta AS
SELECT SaleId AS IdVenta, LineNumber AS NumeroLinea, ProductId AS IdProducto,
       Quantity AS Cantidad, UnitPrice AS PrecioUnitario
FROM dbo.SaleItems;
GO

CREATE OR ALTER VIEW dbo.vw_Proformas AS
SELECT ProformaId AS IdProforma, ProformaNumber AS NumeroProforma, ClientName AS Cliente,
       Subtotal AS Subtotal, DiscountAmount AS Descuento, PromoCode AS Promocion,
       TaxAmount AS Impuesto, Total AS Total, Status AS Estado, ValidUntil AS VigenteHasta,
       Notes AS Notas, CreatedAt AS FechaCreacion, CreatedBy AS CreadoPor,
       QrPayload AS CodigoQR, ConvertedSaleId AS IdVentaConvertida
FROM dbo.Proformas;
GO

CREATE OR ALTER VIEW dbo.vw_DetallesProforma AS
SELECT ProformaId AS IdProforma, LineNumber AS NumeroLinea, ProductId AS IdProducto,
       Quantity AS Cantidad, UnitPrice AS PrecioUnitario
FROM dbo.ProformaItems;
GO

CREATE OR ALTER VIEW dbo.vw_Promociones AS
SELECT PromotionId AS IdPromocion, Title AS Titulo, Blurb AS Descripcion,
       MinSubtotal AS SubtotalMinimo, PercentOff AS PorcentajeDescuento,
       IsActive AS Activa, Badge AS Distintivo
FROM dbo.Promotions;
GO

CREATE OR ALTER VIEW dbo.vw_Compras AS
SELECT purchase.PurchaseId AS IdCompra, purchase.PurchaseNumber AS NumeroCompra,
       COALESCE(party.Name, purchase.SupplierName) AS Proveedor,
       purchase.SupplierPartyId AS IdProveedor, purchase.Total AS Total,
       purchase.Status AS Estado, purchase.PurchaseDate AS FechaCompra,
       purchase.CreatedBy AS CreadoPor
FROM dbo.Purchases AS purchase
LEFT JOIN dbo.Parties AS party ON party.PartyId = purchase.SupplierPartyId;
GO

CREATE OR ALTER VIEW dbo.vw_DetallesCompra AS
SELECT PurchaseId AS IdCompra, LineNumber AS NumeroLinea, ProductId AS IdProducto,
       Quantity AS Cantidad, UnitPrice AS PrecioUnitario
FROM dbo.PurchaseItems;
GO

CREATE OR ALTER VIEW dbo.vw_AsientosContables AS
SELECT AccountingEntryId AS IdAsiento, EntryNumber AS NumeroAsiento,
       Description AS Descripcion, Debit AS Debito, Credit AS Credito,
       DebitAccount AS CuentaDebito, CreditAccount AS CuentaCredito,
       EntryDate AS FechaAsiento, ReferenceType AS TipoReferencia, ReferenceId AS IdReferencia
FROM dbo.AccountingEntries;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosFinancieros AS
SELECT FinanceMoveId AS IdMovimiento, MoveType AS Tipo, Category AS Categoria,
       Amount AS Monto, MoveDate AS Fecha, Note AS Nota, UserName AS Usuario
FROM dbo.FinanceMoves;
GO

CREATE OR ALTER VIEW dbo.vw_Proyecciones AS
SELECT ProjectionId AS IdProyeccion, MonthLabel AS Mes,
       ExpectedSales AS VentasEsperadas, ExpectedCosts AS CostosEsperados
FROM dbo.Projections;
GO

CREATE OR ALTER VIEW dbo.vw_OrdenesProduccion AS
SELECT ProductionOrderId AS IdOrden, Code AS Codigo, Product AS Producto,
       Client AS Cliente, Quantity AS Cantidad, Stage AS Etapa, Sprint AS Sprint,
       Owner AS Responsable
FROM dbo.ProductionOrders;
GO

CREATE OR ALTER VIEW dbo.vw_Terceros AS
SELECT PartyId AS IdTercero, Name AS Nombre, Contact AS Contacto,
       Phone AS Telefono, PartyType AS Tipo
FROM dbo.Parties;
GO

CREATE OR ALTER VIEW dbo.vw_Empleados AS
SELECT EmployeeId AS IdEmpleado, Name AS Nombre, Position AS Cargo,
       Salary AS Salario, Area AS Area
FROM dbo.Employees;
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
SELECT AlbumId AS IdAlbum, LineNumber AS NumeroLinea, ProductId AS IdProducto
FROM dbo.CatalogAlbumProducts;
GO

CREATE OR ALTER VIEW dbo.vw_Proyectos AS
SELECT project.ProjectId AS IdProyecto, project.Code AS Codigo,
       project.Name AS Nombre, COALESCE(party.Name, project.Client) AS Cliente,
       project.ClientPartyId AS IdCliente, project.Amount AS Monto,
       project.Progress AS Avance, project.ProjectState AS Estado, project.Owner AS Responsable
FROM dbo.Projects AS project
LEFT JOIN dbo.Parties AS party ON party.PartyId = project.ClientPartyId;
GO

CREATE OR ALTER VIEW dbo.vw_MovimientosCaja AS
SELECT CashMoveId AS IdMovimiento, Account AS Cuenta, MoveType AS Tipo,
       Amount AS Monto, MoveDate AS Fecha, Concept AS Concepto
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

SELECT fk.name AS Relacion, OBJECT_NAME(fk.parent_object_id) AS TablaHija,
       OBJECT_NAME(fk.referenced_object_id) AS TablaPrincipal
FROM sys.foreign_keys AS fk
WHERE fk.is_disabled = 0
ORDER BY TablaPrincipal, TablaHija;

SELECT name AS VistaEnEspanol
FROM sys.views
WHERE schema_id = SCHEMA_ID(N'dbo') AND name LIKE N'vw[_]%'
ORDER BY name;
GO
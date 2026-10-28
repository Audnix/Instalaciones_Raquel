/* 06 — Vistas en español (consultas con JOINs para reportes y diagrama) */
USE [Instalaciones Raquel];
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

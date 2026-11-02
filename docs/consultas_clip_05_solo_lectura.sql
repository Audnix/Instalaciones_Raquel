-- Clip 05: ejecutar cada bloque por separado en SSMS.
-- Seleccionar en el desplegable la misma base utilizada por la aplicacion.
-- Consultas de lectura; no crean ni modifican registros.

-- 1. Comprobar la base seleccionada.
-- Revision del 01/11/2026: la conexion configurada consulto [Instalaciones Raquel].
SELECT DB_NAME() AS BaseConsultada;

-- 2. Despues de mostrar o guardar el proveedor en la aplicacion.
SELECT Name AS Proveedor,
       PartyType AS Tipo,
       SupplierCategory AS Categoria,
       SupplierStatus AS Estado,
       ProductsServices AS ProductosServicios
FROM dbo.Parties
WHERE PartyType = N'proveedor'
  AND Name = N'GRAB-01 Proveedor de aluminio';

-- 3. Despues de mostrar o guardar el producto en la aplicacion.
SELECT Code AS Codigo,
       Name AS Producto,
       Category AS Categoria,
       UnitPrice AS PrecioVenta,
       MinQuantity AS Minimo
FROM dbo.Products
WHERE Code = N'GRAB-01-MARCO';

-- 4. Despues de mostrar o guardar el cliente en la aplicacion.
-- El nuevo cliente tiene una tabulacion inicial: se normaliza solo para buscar.
-- GRAB.O1 es otro cliente anterior y no se incluye en esta comprobacion.
SELECT Name AS Cliente,
       Contact AS Contacto,
       Phone AS TelefonoOCorreo,
       PartyType AS Tipo
FROM dbo.Parties
WHERE PartyType = N'cliente'
  AND LTRIM(RTRIM(REPLACE(Name, CHAR(9), N''))) = N'GRAB-01 Cliente de practica';

-- 5. Diagnostico si el filtro exacto no encuentra el producto.
-- Esto muestra el catalogo reciente; no crea el producto que falta.
SELECT TOP (20) Code AS Codigo, Name AS Producto,
       UnitPrice AS PrecioVenta, CreatedAt AS FechaRegistro
FROM dbo.Products
ORDER BY CreatedAt DESC, Code;

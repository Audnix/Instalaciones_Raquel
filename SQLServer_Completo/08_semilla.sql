/* 08 — Semilla de maestros del prototipo (usuarios, terceros, promociones, productos) */
USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

MERGE dbo.AppUsers AS t
USING (VALUES
    (N'u-super', N'Raquel López',      N'admin@raquel.com',      N'superadmin',     1),
    (N'u-fin',   N'María Contadora',   N'contador@raquel.com',   N'administrador',  1),
    (N'u-prod',  N'Carlos Producción', N'produccion@raquel.com', N'administrador',  1),
    (N'u-sales', N'Ana Ventas',        N'vendedor@raquel.com',   N'estandar',       1),
    (N'u-buy',   N'Luis Compras',      N'compras@raquel.com',    N'estandar',       1),
    (N'u-guest', N'Invitado Gerencia', N'invitado@raquel.com',   N'invitado',       1)
) AS s(AppUserId, Name, Email, Hierarchy, IsActive)
ON t.AppUserId = s.AppUserId
WHEN MATCHED THEN UPDATE SET Name = s.Name, Email = s.Email, Hierarchy = s.Hierarchy, IsActive = s.IsActive
WHEN NOT MATCHED THEN INSERT (AppUserId, Name, Email, Hierarchy, IsActive)
     VALUES (s.AppUserId, s.Name, s.Email, s.Hierarchy, s.IsActive);

DELETE FROM dbo.AppUserAreas WHERE AppUserId IN (N'u-super', N'u-fin', N'u-prod', N'u-sales', N'u-buy', N'u-guest');

INSERT INTO dbo.AppUserAreas (AppUserId, Area)
VALUES
    (N'u-super', N'gobierno'), (N'u-super', N'produccion'), (N'u-super', N'finanzas'),
    (N'u-super', N'contabilidad'), (N'u-super', N'mercadotecnia'), (N'u-super', N'compras'),
    (N'u-super', N'ventas'), (N'u-super', N'rrhh'), (N'u-super', N'proyectos'),
    (N'u-fin', N'finanzas'), (N'u-fin', N'contabilidad'),
    (N'u-prod', N'produccion'), (N'u-prod', N'inventario'), (N'u-prod', N'proyectos'),
    (N'u-sales', N'ventas'), (N'u-sales', N'mercadotecnia'),
    (N'u-buy', N'compras'), (N'u-buy', N'inventario'),
    (N'u-guest', N'finanzas'), (N'u-guest', N'mercadotecnia'), (N'u-guest', N'proyectos');

MERGE dbo.Parties AS t
USING (VALUES
    (N'cl1', N'Grupo Hábitat',          N'Rosa Méndez',      N'8888-1100', N'cliente'),
    (N'cl2', N'Torre Azul',             N'Iván Solís',       N'8777-2211', N'cliente'),
    (N'cl3', N'Casa Norte',             N'Elena Cruz',       N'8555-3344', N'cliente'),
    (N'cl4', N'Plaza Sur',              N'Mario Peña',       N'8666-7788', N'cliente'),
    (N'cl5', N'Residencial Sol',        N'Patricia Gómez',   N'8444-9900', N'cliente'),
    (N'cl6', N'Clínica del Lago',       N'Dr. Rivas',        N'8222-1010', N'cliente'),
    (N'pv1', N'Alumex',                 N'Compras Alumex',   N'2222-4400', N'proveedor'),
    (N'pv2', N'Vidrios del Pacífico',   N'Karla Ruiz',       N'2255-9090', N'proveedor'),
    (N'pv3', N'Ferretería Central',     N'José Duarte',      N'2277-3311', N'proveedor')
) AS s(PartyId, Name, Contact, Phone, PartyType)
ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET Name = s.Name, Contact = s.Contact, Phone = s.Phone, PartyType = s.PartyType
WHEN NOT MATCHED THEN INSERT (PartyId, Name, Contact, Phone, PartyType)
     VALUES (s.PartyId, s.Name, s.Contact, s.Phone, s.PartyType);

MERGE dbo.Promotions AS t
USING (VALUES
    (N'promo1', N'Combo Hogar 8%',  N'Llevá electrodomésticos o kit de ventana y ahorrá desde C$ 3,000.', 3000, 8,  1, N'-8%'),
    (N'promo2', N'Renovación 12%',  N'Compras fuertes de taller o showroom.', 10000, 12, 1, N'-12%'),
    (N'promo3', N'Mega pack 15%',   N'Pedidos grandes: refrigeradora, lavadora o fachadas.', 20000, 15, 1, N'-15%'),
    (N'promo4', N'Arranque 5%',     N'Descuento de bienvenida desde C$ 1,500.', 1500, 5, 1, N'-5%')
) AS s(PromotionId, Title, Blurb, MinSubtotal, PercentOff, IsActive, Badge)
ON t.PromotionId = s.PromotionId
WHEN MATCHED THEN UPDATE SET Title = s.Title, Blurb = s.Blurb, MinSubtotal = s.MinSubtotal,
     PercentOff = s.PercentOff, IsActive = s.IsActive, Badge = s.Badge
WHEN NOT MATCHED THEN INSERT (PromotionId, Title, Blurb, MinSubtotal, PercentOff, IsActive, Badge)
     VALUES (s.PromotionId, s.Title, s.Blurb, s.MinSubtotal, s.PercentOff, s.IsActive, s.Badge);

MERGE dbo.Products AS t
USING (VALUES
    (N'p1',  N'ALU-5020', N'Perfil serie 5020',        N'Perfiles',          N'cat-perf', 186,   40, N'Alumex / Raquel'),
    (N'p2',  N'VID-10T',  N'Vidrio templado 10mm',     N'Vidrios',           N'cat-vid',  420,   20, N'Vidrios del Pacífico'),
    (N'p3',  N'SIL-NB',   N'Silicon neutro blanco',    N'Accesorios',        N'cat-acc',  95,    12, N'Raquel Sellos'),
    (N'p4',  N'ACC-HER',  N'Herraje de ventana',       N'Accesorios',        N'cat-acc',  64,    30, N'Raquel Herrajes'),
    (N'p5',  N'ALU-7000', N'Perfil serie 7000',        N'Perfiles',          N'cat-perf', 245,   25, N'Alumex / Raquel'),
    (N'p6',  N'VID-6CL',  N'Vidrio claro 6mm',         N'Vidrios',           N'cat-vid',  185,   35, N'Vidrios del Pacífico'),
    (N'p7',  N'MOS-INS',  N'Mosquitero enrollable',    N'Accesorios',        N'cat-acc',  320,   10, N'Raquel Malla'),
    (N'p8',  N'BAR-12',   N'Barandal templado 12mm',   N'Vidrios',           N'cat-vid',  890,   8,  N'Raquel Cristal'),
    (N'e1',  N'REF-18P',  N'Refrigeradora 18 pies',    N'Electrodomésticos', N'cat-elec', 18500, 3,  N'Raquel Hogar'),
    (N'e2',  N'LAV-16K',  N'Lavadora 16 kg',           N'Electrodomésticos', N'cat-elec', 12400, 4,  N'Raquel Hogar'),
    (N'e3',  N'SEC-8K',   N'Secadora 8 kg',            N'Electrodomésticos', N'cat-elec', 9800,  3,  N'Raquel Hogar'),
    (N'e4',  N'MIC-30L',  N'Microondas 30L',           N'Electrodomésticos', N'cat-elec', 3200,  6,  N'Raquel Hogar'),
    (N'e5',  N'EST-4Q',   N'Estufa 4 quemadores',      N'Electrodomésticos', N'cat-elec', 7600,  4,  N'Raquel Hogar'),
    (N'e6',  N'AIR-12K',  N'Aire acondicionado 12k BTU', N'Electrodomésticos', N'cat-elec', 14900, 3, N'Raquel Clima'),
    (N'e7',  N'TV-55S',   N'Smart TV 55 pulgadas',     N'Electrodomésticos', N'cat-elec', 16800, 5,  N'Raquel Vision'),
    (N'e8',  N'LIC-PRO',  N'Licuadora profesional',    N'Electrodomésticos', N'cat-elec', 2100,  8,  N'Raquel Hogar'),
    (N'e9',  N'CAF-ESP',  N'Cafetera espresso',        N'Electrodomésticos', N'cat-elec', 4500,  5,  N'Raquel Hogar'),
    (N'e10', N'ASP-ROB',  N'Aspiradora robot',         N'Electrodomésticos', N'cat-elec', 8900,  4,  N'Raquel Hogar'),
    (N'e11', N'HOR-ELE',  N'Horno eléctrico',          N'Electrodomésticos', N'cat-elec', 5400,  4,  N'Raquel Hogar'),
    (N'e12', N'VEN-TOR',  N'Ventilador de torre',      N'Electrodomésticos', N'cat-elec', 1800,  10, N'Raquel Clima')
) AS s(ProductId, Code, Name, Category, CategoryId, UnitPrice, MinQuantity, Brand)
ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET Code = s.Code, Name = s.Name, Category = s.Category, CategoryId = s.CategoryId,
     UnitPrice = s.UnitPrice, MinQuantity = s.MinQuantity, Brand = s.Brand
WHEN NOT MATCHED THEN INSERT (ProductId, Code, Name, Category, CategoryId, UnitPrice, MinQuantity, CreatedAt, Brand)
     VALUES (s.ProductId, s.Code, s.Name, s.Category, s.CategoryId, s.UnitPrice, s.MinQuantity, SYSUTCDATETIME(), s.Brand);

MERGE dbo.Employees AS t
USING (VALUES
    (N'e1', N'Carlos Producción', N'Supervisor de taller', 18500, N'Producción', N'u-prod'),
    (N'e2', N'Ana Ventas',        N'Asesora comercial',    14200, N'Ventas',     N'u-sales'),
    (N'e3', N'Luis Compras',      N'Comprador',            13800, N'Compras',    N'u-buy'),
    (N'e4', N'María Contadora',   N'Contadora general',    16800, N'Contabilidad', N'u-fin'),
    (N'e5', N'Diego Instalador',  N'Técnico de instalación', 12500, N'Producción', NULL),
    (N'e6', N'Sofía Bodega',      N'Encargada de inventario', 11800, N'Inventario', NULL)
) AS s(EmployeeId, Name, Position, Salary, Area, AppUserId)
ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET Name = s.Name, Position = s.Position, Salary = s.Salary, Area = s.Area, AppUserId = s.AppUserId
WHEN NOT MATCHED THEN INSERT (EmployeeId, Name, Position, Salary, Area, AppUserId)
     VALUES (s.EmployeeId, s.Name, s.Position, s.Salary, s.Area, s.AppUserId);

SELECT N'Semilla de maestros lista' AS Resultado;
GO

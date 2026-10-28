-- =========================================================================================
-- INSTALACIONES RAQUEL - SISTEMA INTEGRAL ERP & RRHH (NICARAGUA)
-- SCRIPT 19: CARGA INTEGRAL DE REGISTROS REALES Y COHERENTES EN TODOS LOS MÓDULOS
--
-- Normativa Aplicada:
-- 1. DGI - Ley 822 (Ley de Concertación Tributaria de Nicaragua):
--    - IVA 15% en facturación de bienes y obras de cancelería y vidrio.
--    - Retención en la fuente del IR sobre salarios según escala progresiva Art. 23.
--    - Retención del 2% por servicios profesionales y 1% por compra de bienes.
--    - Retención municipal de la Alcaldía de Managua (ALMA) 1%.
-- 2. MITRAB - Ley 185 (Código del Trabajo de Nicaragua):
--    - Contratos de trabajo por tiempo indefinido formalizados.
--    - Jornada laboral diurna legal de 8 horas diarias / 48 horas semanales.
--    - Recargo del 100% por horas extraordinarias (Art. 62).
--    - Provisión de Décimo Tercer Mes (Aguinaldo, Art. 93-99).
--    - Provisión de Vacaciones (15 días por cada 6 meses continuos, Art. 76).
--    - Provisión de Indemnización por Antigüedad (Art. 45).
-- 3. INSS e INATEC:
--    - Aporte Laboral INSS: 7.00%
--    - Aporte Patronal INSS: 21.50%
--    - Aporte INATEC: 2.00%
-- =========================================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
USE [Instalaciones Raquel];
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

PRINT '=========================================================================================';
PRINT 'INICIANDO CARGA INTEGRAL DE REGISTROS REALES · INSTALACIONES RAQUEL';
PRINT '=========================================================================================';
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 1. TERCEROS: CLIENTES Y PROVEEDORES (RUC DGI Y DIRECCIONES EN MANAGUA, NICARAGUA)
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Terceros (Clientes corporativos y Proveedores)...';
MERGE dbo.Parties AS t
USING (SELECT N'cl1' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Grupo HÃ¡bitat S.A.', Contact = N'Ing. Rosa MÃ©ndez',
    Phone = N'8888-1100', PartyType = N'cliente',
    SupplierCategory = NULL,
    Email = N'proyectos@grupohabitat.com.ni', Address = N'Pista Jean Paul Genie, Edificio Prisma Piso 3, Managua',
    Ruc = N'J0310000607080', PaymentTerms = N'CrÃ©dito 30 dÃ­as',
    Observations = N'Cliente corporativo de fachadas flotantes y ventanerÃ­a comercial.',
    SupplierStatus = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'cl1', N'Grupo HÃ¡bitat S.A.', N'Ing. Rosa MÃ©ndez', N'8888-1100',
    N'cliente', NULL, N'proyectos@grupohabitat.com.ni', N'Pista Jean Paul Genie, Edificio Prisma Piso 3, Managua',
    N'J0310000607080', N'CrÃ©dito 30 dÃ­as', N'Cliente corporativo de fachadas flotantes y ventanerÃ­a comercial.',
    NULL, SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'cl2' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Torre Azul Condominios S.A.', Contact = N'Lic. IvÃ¡n SolÃ­s',
    Phone = N'8777-2211', PartyType = N'cliente',
    SupplierCategory = NULL,
    Email = N'administracion@torreazul.com.ni', Address = N'Villa Fontana, de los semÃ¡foros del Club Terraza 300m al Sur, Managua',
    Ruc = N'J0310000708090', PaymentTerms = N'Anticipo 50% y saldo contra entrega',
    Observations = N'Desarrollo vertical de apartamentos, barandales y muros cortina.',
    SupplierStatus = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'cl2', N'Torre Azul Condominios S.A.', N'Lic. IvÃ¡n SolÃ­s', N'8777-2211',
    N'cliente', NULL, N'administracion@torreazul.com.ni', N'Villa Fontana, de los semÃ¡foros del Club Terraza 300m al Sur, Managua',
    N'J0310000708090', N'Anticipo 50% y saldo contra entrega', N'Desarrollo vertical de apartamentos, barandales y muros cortina.',
    NULL, SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'cl3' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Constructora MÃ¡ntica S.A.', Contact = N'Ing. Elena Cruz',
    Phone = N'8555-3344', PartyType = N'cliente',
    SupplierCategory = NULL,
    Email = N'compras@constructoramantica.com.ni', Address = N'Carretera a Masaya Km 8.5, Managua',
    Ruc = N'J0310000809100', PaymentTerms = N'CrÃ©dito 45 dÃ­as contra avalÃºo',
    Observations = N'Constructora general de centros comerciales y clÃ­nicas mÃ©dicas.',
    SupplierStatus = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'cl3', N'Constructora MÃ¡ntica S.A.', N'Ing. Elena Cruz', N'8555-3344',
    N'cliente', NULL, N'compras@constructoramantica.com.ni', N'Carretera a Masaya Km 8.5, Managua',
    N'J0310000809100', N'CrÃ©dito 45 dÃ­as contra avalÃºo', N'Constructora general de centros comerciales y clÃ­nicas mÃ©dicas.',
    NULL, SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'cl4' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Plaza Comercial Sur S.A.', Contact = N'Lic. Mario PeÃ±a',
    Phone = N'8666-7788', PartyType = N'cliente',
    SupplierCategory = NULL,
    Email = N'gerencia@plazasur.com.ni', Address = N'Carretera Sur Km 10.2, Managua',
    Ruc = N'J0310001112130', PaymentTerms = N'Contado contra entrega',
    Observations = N'MÃ³dulos comerciales, puertas de vidrio templado y canceles automÃ¡ticos.',
    SupplierStatus = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'cl4', N'Plaza Comercial Sur S.A.', N'Lic. Mario PeÃ±a', N'8666-7788',
    N'cliente', NULL, N'gerencia@plazasur.com.ni', N'Carretera Sur Km 10.2, Managua',
    N'J0310001112130', N'Contado contra entrega', N'MÃ³dulos comerciales, puertas de vidrio templado y canceles automÃ¡ticos.',
    NULL, SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'cl5' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Desarrollos Inmobiliarios Las Colinas S.A.', Contact = N'Arq. Patricia GÃ³mez',
    Phone = N'8444-9900', PartyType = N'cliente',
    SupplierCategory = NULL,
    Email = N'arquitectura@lascolinas.com.ni', Address = N'Reparto Las Colinas, Avenida Principal, Managua',
    Ruc = N'J0310001011120', PaymentTerms = N'CrÃ©dito 30 dÃ­as',
    Observations = N'Residencias de lujo, ventanas europeas acÃºsticas y mamparas de baÃ±o.',
    SupplierStatus = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'cl5', N'Desarrollos Inmobiliarios Las Colinas S.A.', N'Arq. Patricia GÃ³mez', N'8444-9900',
    N'cliente', NULL, N'arquitectura@lascolinas.com.ni', N'Reparto Las Colinas, Avenida Principal, Managua',
    N'J0310001011120', N'CrÃ©dito 30 dÃ­as', N'Residencias de lujo, ventanas europeas acÃºsticas y mamparas de baÃ±o.',
    NULL, SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'cl6' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'ClÃ­nica del Lago S.A.', Contact = N'Dr. Roberto Rivas',
    Phone = N'8222-1010', PartyType = N'cliente',
    SupplierCategory = NULL,
    Email = N'direccion@clinicalago.com.ni', Address = N'Bolonia, de la Ã“ptica NicaragÃ¼ense 2c al Norte, Managua',
    Ruc = N'J0310000910110', PaymentTerms = N'Contado 100%',
    Observations = N'Divisiones de quirÃ³fano con perfiles sellados y vidrio laminado antibacterial.',
    SupplierStatus = NULL,
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'cl6', N'ClÃ­nica del Lago S.A.', N'Dr. Roberto Rivas', N'8222-1010',
    N'cliente', NULL, N'direccion@clinicalago.com.ni', N'Bolonia, de la Ã“ptica NicaragÃ¼ense 2c al Norte, Managua',
    N'J0310000910110', N'Contado 100%', N'Divisiones de quirÃ³fano con perfiles sellados y vidrio laminado antibacterial.',
    NULL, SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'pv1' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Alumex de Nicaragua S.A.', Contact = N'Lic. Karla Ruiz',
    Phone = N'2222-4400', PartyType = N'proveedor',
    SupplierCategory = N'materiales',
    Email = N'ventas@alumex.com.ni', Address = N'Carretera Norte Km 6.5, Complejo Industrial, Managua',
    Ruc = N'J0310000102030', PaymentTerms = N'CrÃ©dito 30 dÃ­as',
    Observations = N'Proveedor principal de extrusiones de aluminio anodizado y lacado blanco.',
    SupplierStatus = N'activo',
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'pv1', N'Alumex de Nicaragua S.A.', N'Lic. Karla Ruiz', N'2222-4400',
    N'proveedor', N'materiales', N'ventas@alumex.com.ni', N'Carretera Norte Km 6.5, Complejo Industrial, Managua',
    N'J0310000102030', N'CrÃ©dito 30 dÃ­as', N'Proveedor principal de extrusiones de aluminio anodizado y lacado blanco.',
    N'activo', SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'pv2' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Vidrios del PacÃ­fico S.A.', Contact = N'Ing. Fernando Morales',
    Phone = N'2255-9090', PartyType = N'proveedor',
    SupplierCategory = N'materiales',
    Email = N'pedidos@vidriospacifico.com.ni', Address = N'Carretera a Masaya Km 12.5, Ticuantepe',
    Ruc = N'J0310000203040', PaymentTerms = N'CrÃ©dito 15 dÃ­as',
    Observations = N'Planta de procesamiento de vidrio con templado horizontal homologado ASTM.',
    SupplierStatus = N'activo',
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'pv2', N'Vidrios del PacÃ­fico S.A.', N'Ing. Fernando Morales', N'2255-9090',
    N'proveedor', N'materiales', N'pedidos@vidriospacifico.com.ni', N'Carretera a Masaya Km 12.5, Ticuantepe',
    N'J0310000203040', N'CrÃ©dito 15 dÃ­as', N'Planta de procesamiento de vidrio con templado horizontal homologado ASTM.',
    N'activo', SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'pv3' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'FerreterÃ­a y Herrajes Industriales S.A.', Contact = N'Don JosÃ© Duarte',
    Phone = N'2277-3311', PartyType = N'proveedor',
    SupplierCategory = N'materiales',
    Email = N'ventas@ferreteriaindustrial.com.ni', Address = N'Ciudad JardÃ­n, de la gasolinera Puma 1c al Sur, Managua',
    Ruc = N'J0310000304050', PaymentTerms = N'Contado contra entrega',
    Observations = N'Herrajes de alta durabilidad para puertas de vidrio templado y ventanas corredizas.',
    SupplierStatus = N'activo',
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'pv3', N'FerreterÃ­a y Herrajes Industriales S.A.', N'Don JosÃ© Duarte', N'2277-3311',
    N'proveedor', N'materiales', N'ventas@ferreteriaindustrial.com.ni', N'Ciudad JardÃ­n, de la gasolinera Puma 1c al Sur, Managua',
    N'J0310000304050', N'Contado contra entrega', N'Herrajes de alta durabilidad para puertas de vidrio templado y ventanas corredizas.',
    N'activo', SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.Parties AS t
USING (SELECT N'pv4' AS PartyId) AS s ON t.PartyId = s.PartyId
WHEN MATCHED THEN UPDATE SET
    Name = N'Selladores y QuÃ­micos Estructurales S.A.', Contact = N'Ing. Claudia Espinoza',
    Phone = N'2288-5522', PartyType = N'proveedor',
    SupplierCategory = N'materiales',
    Email = N'pedidos@selladores.com.ni', Address = N'Pista Suburbana, Edificio Discover MÃ³dulo 2, Managua',
    Ruc = N'J0310000405060', PaymentTerms = N'CrÃ©dito 30 dÃ­as',
    Observations = N'Distribuidor exclusivo de silicones de curado neutro para muros cortina.',
    SupplierStatus = N'activo',
    UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,
    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt
) VALUES (
    N'pv4', N'Selladores y QuÃ­micos Estructurales S.A.', N'Ing. Claudia Espinoza', N'2288-5522',
    N'proveedor', N'materiales', N'pedidos@selladores.com.ni', N'Pista Suburbana, Edificio Discover MÃ³dulo 2, Managua',
    N'J0310000405060', N'CrÃ©dito 30 dÃ­as', N'Distribuidor exclusivo de silicones de curado neutro para muros cortina.',
    N'activo', SYSUTCDATETIME(), SYSUTCDATETIME()
);
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 2. CATÁLOGO DE PRODUCTOS (ALUMINIO, VIDRIO DE SEGURIDAD Y ACCESORIOS)
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Catálogo de Productos...';
MERGE dbo.Products AS t
USING (SELECT N'p1' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'ALU-5020', Name = N'Perfil de aluminio corredizo serie 5020 (6m)', Category = N'Perfiles',
    UnitPrice = 480, MinQuantity = 40,
    Model = N'', Brand = N'Alumex / Raquel',
    Material = N'Aluminio 6063-T5', Measures = N'6.00 metros',
    Capacity = N'', Finish = N'Anodizado Natural',
    ProductUse = N'VentanerÃ­a corrediza residencial', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p1', N'ALU-5020', N'Perfil de aluminio corredizo serie 5020 (6m)', N'Perfiles', 480, 40,
    '2026-09-01T08:00:00Z', N'', N'Alumex / Raquel',
    N'Aluminio 6063-T5', N'6.00 metros', N'',
    N'Anodizado Natural', N'VentanerÃ­a corrediza residencial', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p2' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'VID-10T', Name = N'Vidrio templado de seguridad 10mm (mÂ²)', Category = N'Vidrios',
    UnitPrice = 950, MinQuantity = 20,
    Model = N'', Brand = N'Vidrios del PacÃ­fico',
    Material = N'Vidrio templado tÃ©rmico', Measures = N'Metro cuadrado a medida',
    Capacity = N'', Finish = N'Bordes pulidos brillantes',
    ProductUse = N'Puertas, canceles y divisiones comerciales', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p2', N'VID-10T', N'Vidrio templado de seguridad 10mm (mÂ²)', N'Vidrios', 950, 20,
    '2026-09-01T08:00:00Z', N'', N'Vidrios del PacÃ­fico',
    N'Vidrio templado tÃ©rmico', N'Metro cuadrado a medida', N'',
    N'Bordes pulidos brillantes', N'Puertas, canceles y divisiones comerciales', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p3' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'SIL-DC795', Name = N'SilicÃ³n estructural Dow Corning 795 (Cartucho 310ml)', Category = N'Accesorios',
    UnitPrice = 280, MinQuantity = 24,
    Model = N'', Brand = N'Dow Corning',
    Material = N'PolÃ­mero de silicona neutra', Measures = N'310 ml',
    Capacity = N'', Finish = N'Negro estructural',
    ProductUse = N'FijaciÃ³n y sellado estanco de muro cortina', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p3', N'SIL-DC795', N'SilicÃ³n estructural Dow Corning 795 (Cartucho 310ml)', N'Accesorios', 280, 24,
    '2026-09-01T08:00:00Z', N'', N'Dow Corning',
    N'PolÃ­mero de silicona neutra', N'310 ml', N'',
    N'Negro estructural', N'FijaciÃ³n y sellado estanco de muro cortina', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p4' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'HER-PIVOT', Name = N'Pivote hidrÃ¡ulico de piso para puerta templada', Category = N'Accesorios',
    UnitPrice = 1850, MinQuantity = 10,
    Model = N'', Brand = N'Dorma / Raquel',
    Material = N'Acero inoxidable y latÃ³n', Measures = N'Caja de piso 30x12 cm',
    Capacity = N'', Finish = N'Tapa satinada inox 304',
    ProductUse = N'Puertas abatibles de alto trÃ¡nsito', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p4', N'HER-PIVOT', N'Pivote hidrÃ¡ulico de piso para puerta templada', N'Accesorios', 1850, 10,
    '2026-09-01T08:00:00Z', N'', N'Dorma / Raquel',
    N'Acero inoxidable y latÃ³n', N'Caja de piso 30x12 cm', N'',
    N'Tapa satinada inox 304', N'Puertas abatibles de alto trÃ¡nsito', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p5' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'ALU-7000', Name = N'Perfil perimetral batiente serie 7000 (6m)', Category = N'Perfiles',
    UnitPrice = 620, MinQuantity = 30,
    Model = N'', Brand = N'Alumex / Raquel',
    Material = N'Aluminio 6063-T5', Measures = N'6.00 metros',
    Capacity = N'', Finish = N'Lacado Blanco ElectrostÃ¡tico',
    ProductUse = N'Puertas y ventanas abatibles hermÃ©ticas', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p5', N'ALU-7000', N'Perfil perimetral batiente serie 7000 (6m)', N'Perfiles', 620, 30,
    '2026-09-01T08:00:00Z', N'', N'Alumex / Raquel',
    N'Aluminio 6063-T5', N'6.00 metros', N'',
    N'Lacado Blanco ElectrostÃ¡tico', N'Puertas y ventanas abatibles hermÃ©ticas', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p6' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'VID-6CL', Name = N'Vidrio flotado claro 6mm (mÂ²)', Category = N'Vidrios',
    UnitPrice = 420, MinQuantity = 35,
    Model = N'', Brand = N'Vidrios del PacÃ­fico',
    Material = N'Flotado estÃ¡ndar', Measures = N'Metro cuadrado',
    Capacity = N'', Finish = N'Canto pulido',
    ProductUse = N'VentanerÃ­a tradicional y marcos de aluminio', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p6', N'VID-6CL', N'Vidrio flotado claro 6mm (mÂ²)', N'Vidrios', 420, 35,
    '2026-09-01T08:00:00Z', N'', N'Vidrios del PacÃ­fico',
    N'Flotado estÃ¡ndar', N'Metro cuadrado', N'',
    N'Canto pulido', N'VentanerÃ­a tradicional y marcos de aluminio', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p7' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'BAR-12T', Name = N'Vidrio templado 12mm para barandales con perforaciones', Category = N'Vidrios',
    UnitPrice = 1450, MinQuantity = 15,
    Model = N'', Brand = N'Vidrios del PacÃ­fico',
    Material = N'Templado alta resistencia', Measures = N'Metro cuadrado',
    Capacity = N'', Finish = N'Cantos rectificados y barrenos',
    ProductUse = N'Barandales de balcones y pasamanos', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p7', N'BAR-12T', N'Vidrio templado 12mm para barandales con perforaciones', N'Vidrios', 1450, 15,
    '2026-09-01T08:00:00Z', N'', N'Vidrios del PacÃ­fico',
    N'Templado alta resistencia', N'Metro cuadrado', N'',
    N'Cantos rectificados y barrenos', N'Barandales de balcones y pasamanos', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p8' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'ACC-CARR', Name = N'Carretilla doble tÃ¡ndem con rodamientos sellados', Category = N'Accesorios',
    UnitPrice = 120, MinQuantity = 50,
    Model = N'', Brand = N'Herrajes Industriales',
    Material = N'Nylon autolubricado y acero inox', Measures = N'Par de rodos regulables',
    Capacity = N'', Finish = N'Tropicalizado',
    ProductUse = N'Hojas corredizas pesadas hasta 120kg', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p8', N'ACC-CARR', N'Carretilla doble tÃ¡ndem con rodamientos sellados', N'Accesorios', 120, 50,
    '2026-09-01T08:00:00Z', N'', N'Herrajes Industriales',
    N'Nylon autolubricado y acero inox', N'Par de rodos regulables', N'',
    N'Tropicalizado', N'Hojas corredizas pesadas hasta 120kg', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p9' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'ALU-MC80', Name = N'Perfil de columna para muro cortina MC-80 (6m)', Category = N'Perfiles',
    UnitPrice = 1650, MinQuantity = 16,
    Model = N'', Brand = N'Alumex / Raquel',
    Material = N'Aluminio estructural 6063-T6', Measures = N'6.00 metros x 80mm',
    Capacity = N'', Finish = N'Anodizado Bronce Oscuro',
    ProductUse = N'Estructuras verticales de fachadas de edificios', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p9', N'ALU-MC80', N'Perfil de columna para muro cortina MC-80 (6m)', N'Perfiles', 1650, 16,
    '2026-09-01T08:00:00Z', N'', N'Alumex / Raquel',
    N'Aluminio estructural 6063-T6', N'6.00 metros x 80mm', N'',
    N'Anodizado Bronce Oscuro', N'Estructuras verticales de fachadas de edificios', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p10' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'VID-8REF', Name = N'Vidrio reflectivo solar 8mm azul solar (mÂ²)', Category = N'Vidrios',
    UnitPrice = 880, MinQuantity = 25,
    Model = N'', Brand = N'Vidrios del PacÃ­fico',
    Material = N'Capa pirolÃ­tica reflectiva', Measures = N'Metro cuadrado',
    Capacity = N'', Finish = N'Azul reflectivo / neutro',
    ProductUse = N'Control tÃ©rmico y ahorro energÃ©tico en fachadas', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p10', N'VID-8REF', N'Vidrio reflectivo solar 8mm azul solar (mÂ²)', N'Vidrios', 880, 25,
    '2026-09-01T08:00:00Z', N'', N'Vidrios del PacÃ­fico',
    N'Capa pirolÃ­tica reflectiva', N'Metro cuadrado', N'',
    N'Azul reflectivo / neutro', N'Control tÃ©rmico y ahorro energÃ©tico en fachadas', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p11' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'HER-MANI', Name = N'Manija de aluminio embutida con cerradura', Category = N'Accesorios',
    UnitPrice = 240, MinQuantity = 30,
    Model = N'', Brand = N'Herrajes Industriales',
    Material = N'Zamak y aluminio inyectado', Measures = N'Pieza estÃ¡ndar 18cm',
    Capacity = N'', Finish = N'Pintura epÃ³xica negra',
    ProductUse = N'Cierre seguro de ventanas corredizas', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p11', N'HER-MANI', N'Manija de aluminio embutida con cerradura', N'Accesorios', 240, 30,
    '2026-09-01T08:00:00Z', N'', N'Herrajes Industriales',
    N'Zamak y aluminio inyectado', N'Pieza estÃ¡ndar 18cm', N'',
    N'Pintura epÃ³xica negra', N'Cierre seguro de ventanas corredizas', N''
);
MERGE dbo.Products AS t
USING (SELECT N'p12' AS ProductId) AS s ON t.ProductId = s.ProductId
WHEN MATCHED THEN UPDATE SET
    Code = N'ACC-EPDM', Name = N'Empaque perimetral de hule EPDM tipo cuÃ±a (Rollo 50m)', Category = N'Accesorios',
    UnitPrice = 450, MinQuantity = 10,
    Model = N'', Brand = N'Selladores Industriales',
    Material = N'Caucho sintÃ©tico EPDM', Measures = N'Rollo de 50 metros',
    Capacity = N'', Finish = N'Negro mate',
    ProductUse = N'Hermeticidad al agua y viento en canceles', Warranty = N''
WHEN NOT MATCHED THEN INSERT (
    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,
    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty
) VALUES (
    N'p12', N'ACC-EPDM', N'Empaque perimetral de hule EPDM tipo cuÃ±a (Rollo 50m)', N'Accesorios', 450, 10,
    '2026-09-01T08:00:00Z', N'', N'Selladores Industriales',
    N'Caucho sintÃ©tico EPDM', N'Rollo de 50 metros', N'',
    N'Negro mate', N'Hermeticidad al agua y viento en canceles', N''
);
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 3. LOTES DE INVENTARIO (BODEGA CENTRAL Y TALLER DE ENSAMBLAJE)
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Lotes de Inventario...';
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-1' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p1', Quantity = 65, UnitCost = 380,
    EntryDate = '2026-09-01T08:00:00Z', WarehouseId = N'Bodega Central Carretera Norte'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-1', N'p1', 65, 380, '2026-09-01T08:00:00Z', N'Bodega Central Carretera Norte');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-2' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p2', Quantity = 45, UnitCost = 750,
    EntryDate = '2026-09-05T09:30:00Z', WarehouseId = N'Taller de Ensamblaje'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-2', N'p2', 45, 750, '2026-09-05T09:30:00Z', N'Taller de Ensamblaje');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-3' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p3', Quantity = 80, UnitCost = 210,
    EntryDate = '2026-09-10T11:00:00Z', WarehouseId = N'Bodega Central Carretera Norte'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-3', N'p3', 80, 210, '2026-09-10T11:00:00Z', N'Bodega Central Carretera Norte');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-4' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p4', Quantity = 18, UnitCost = 1450,
    EntryDate = '2026-09-12T14:00:00Z', WarehouseId = N'Taller de Ensamblaje'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-4', N'p4', 18, 1450, '2026-09-12T14:00:00Z', N'Taller de Ensamblaje');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-5' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p5', Quantity = 50, UnitCost = 490,
    EntryDate = '2026-09-15T10:00:00Z', WarehouseId = N'Bodega Central Carretera Norte'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-5', N'p5', 50, 490, '2026-09-15T10:00:00Z', N'Bodega Central Carretera Norte');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-6' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p6', Quantity = 60, UnitCost = 310,
    EntryDate = '2026-09-18T16:00:00Z', WarehouseId = N'Bodega Central Carretera Norte'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-6', N'p6', 60, 310, '2026-09-18T16:00:00Z', N'Bodega Central Carretera Norte');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-7' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p7', Quantity = 28, UnitCost = 1100,
    EntryDate = '2026-09-20T08:30:00Z', WarehouseId = N'Taller de Ensamblaje'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-7', N'p7', 28, 1100, '2026-09-20T08:30:00Z', N'Taller de Ensamblaje');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-8' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p8', Quantity = 120, UnitCost = 85,
    EntryDate = '2026-09-22T09:00:00Z', WarehouseId = N'Bodega Central Carretera Norte'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-8', N'p8', 120, 85, '2026-09-22T09:00:00Z', N'Bodega Central Carretera Norte');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-9' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p9', Quantity = 24, UnitCost = 1300,
    EntryDate = '2026-09-25T11:30:00Z', WarehouseId = N'Taller de Ensamblaje'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-9', N'p9', 24, 1300, '2026-09-25T11:30:00Z', N'Taller de Ensamblaje');
MERGE dbo.InventoryLots AS t
USING (SELECT N'lot-10' AS LotId) AS s ON t.LotId = s.LotId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p10', Quantity = 40, UnitCost = 680,
    EntryDate = '2026-09-28T13:00:00Z', WarehouseId = N'Taller de Ensamblaje'
WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)
VALUES (N'lot-10', N'p10', 40, 680, '2026-09-28T13:00:00Z', N'Taller de Ensamblaje');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 4. MOVIMIENTOS DE KARDEX PEPS
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Movimientos de Kardex...';
MERGE dbo.KardexMoves AS t
USING (SELECT N'kdx-1' AS KardexMoveId) AS s ON t.KardexMoveId = s.KardexMoveId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p1', MoveType = N'entrada', Quantity = 80,
    UnitCost = 380, MoveDate = '2026-09-01T08:00:00Z', Reason = N'Compra inicial segÃºn Factura F001-4521 de Alumex', UserName = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
VALUES (N'kdx-1', N'p1', N'entrada', 80, 380, '2026-09-01T08:00:00Z', N'Compra inicial segÃºn Factura F001-4521 de Alumex', N'Luis Morales');
MERGE dbo.KardexMoves AS t
USING (SELECT N'kdx-2' AS KardexMoveId) AS s ON t.KardexMoveId = s.KardexMoveId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p1', MoveType = N'salida', Quantity = 15,
    UnitCost = 380, MoveDate = '2026-09-15T14:00:00Z', Reason = N'Entrega a taller para Proyecto PRJ-001 Ofiplaza', UserName = N'Carlos Mendoza'
WHEN NOT MATCHED THEN INSERT (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
VALUES (N'kdx-2', N'p1', N'salida', 15, 380, '2026-09-15T14:00:00Z', N'Entrega a taller para Proyecto PRJ-001 Ofiplaza', N'Carlos Mendoza');
MERGE dbo.KardexMoves AS t
USING (SELECT N'kdx-3' AS KardexMoveId) AS s ON t.KardexMoveId = s.KardexMoveId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p2', MoveType = N'entrada', Quantity = 50,
    UnitCost = 750, MoveDate = '2026-09-05T09:30:00Z', Reason = N'RecepciÃ³n de cristales templados segÃºn Factura F002-8812 de Vidrios del PacÃ­fico', UserName = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
VALUES (N'kdx-3', N'p2', N'entrada', 50, 750, '2026-09-05T09:30:00Z', N'RecepciÃ³n de cristales templados segÃºn Factura F002-8812 de Vidrios del PacÃ­fico', N'Luis Morales');
MERGE dbo.KardexMoves AS t
USING (SELECT N'kdx-4' AS KardexMoveId) AS s ON t.KardexMoveId = s.KardexMoveId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p2', MoveType = N'salida', Quantity = 5,
    UnitCost = 750, MoveDate = '2026-09-22T10:30:00Z', Reason = N'Salida para ensamble de puerta mÃ³dulo comercial GalerÃ­as', UserName = N'Carlos Mendoza'
WHEN NOT MATCHED THEN INSERT (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
VALUES (N'kdx-4', N'p2', N'salida', 5, 750, '2026-09-22T10:30:00Z', N'Salida para ensamble de puerta mÃ³dulo comercial GalerÃ­as', N'Carlos Mendoza');
MERGE dbo.KardexMoves AS t
USING (SELECT N'kdx-5' AS KardexMoveId) AS s ON t.KardexMoveId = s.KardexMoveId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p3', MoveType = N'entrada', Quantity = 100,
    UnitCost = 210, MoveDate = '2026-09-10T11:00:00Z', Reason = N'Ingreso de silicÃ³n estructural Dow Corning Factura F004-1102', UserName = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
VALUES (N'kdx-5', N'p3', N'entrada', 100, 210, '2026-09-10T11:00:00Z', N'Ingreso de silicÃ³n estructural Dow Corning Factura F004-1102', N'Luis Morales');
MERGE dbo.KardexMoves AS t
USING (SELECT N'kdx-6' AS KardexMoveId) AS s ON t.KardexMoveId = s.KardexMoveId
WHEN MATCHED THEN UPDATE SET
    ProductId = N'p3', MoveType = N'salida', Quantity = 20,
    UnitCost = 210, MoveDate = '2026-09-26T15:00:00Z', Reason = N'InstalaciÃ³n de fachada flotante en obra Ofiplaza', UserName = N'Denis Somarriba'
WHEN NOT MATCHED THEN INSERT (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)
VALUES (N'kdx-6', N'p3', N'salida', 20, 210, '2026-09-26T15:00:00Z', N'InstalaciÃ³n de fachada flotante en obra Ofiplaza', N'Denis Somarriba');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 5. FACTURACIÓN COMERCIAL Y CUMPLIMIENTO DGI (IVA 15%, QR FISCAL)
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Facturación Comercial con QR DGI...';
MERGE dbo.Sales AS t
USING (SELECT N'fac-1001' AS SaleId) AS s ON t.SaleId = s.SaleId
WHEN MATCHED THEN UPDATE SET
    SaleNumber = N'FACT-2026-00101', ClientName = N'Grupo HÃ¡bitat S.A.',
    Subtotal = 44120, DiscountAmount = 2206,
    TaxAmount = 6287.1, Total = 48201.1, Status = N'completed',
    SaleDate = '2026-09-18T10:00:00Z', CreatedBy = N'Ana Silva', QrPayload = N'DGI-NIC|FACT-2026-00101|J0310000000019|J0310000607080|44120.00|6287.10|48201.10|2026-09-18'
WHEN NOT MATCHED THEN INSERT (
    SaleId, SaleNumber, ClientName, Subtotal, DiscountAmount, TaxAmount, Total, Status, SaleDate, CreatedBy, QrPayload
) VALUES (
    N'fac-1001', N'FACT-2026-00101', N'Grupo HÃ¡bitat S.A.', 44120,
    2206, 6287.1, 48201.1, N'completed', '2026-09-18T10:00:00Z',
    N'Ana Silva', N'DGI-NIC|FACT-2026-00101|J0310000000019|J0310000607080|44120.00|6287.10|48201.10|2026-09-18'
);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1001' AND LineNumber = 1)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1001', 1, N'p9', 12, 1650);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1001' AND LineNumber = 2)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1001', 2, N'p10', 20, 880);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1001' AND LineNumber = 3)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1001', 3, N'p3', 24, 280);
MERGE dbo.Sales AS t
USING (SELECT N'fac-1002' AS SaleId) AS s ON t.SaleId = s.SaleId
WHEN MATCHED THEN UPDATE SET
    SaleNumber = N'FACT-2026-00102', ClientName = N'Plaza Comercial Sur S.A.',
    Subtotal = 17960, DiscountAmount = 0,
    TaxAmount = 2694, Total = 20654, Status = N'completed',
    SaleDate = '2026-09-24T14:30:00Z', CreatedBy = N'Ana Silva', QrPayload = N'DGI-NIC|FACT-2026-00102|J0310000000019|J0310001112130|17960.00|2694.00|20654.00|2026-09-24'
WHEN NOT MATCHED THEN INSERT (
    SaleId, SaleNumber, ClientName, Subtotal, DiscountAmount, TaxAmount, Total, Status, SaleDate, CreatedBy, QrPayload
) VALUES (
    N'fac-1002', N'FACT-2026-00102', N'Plaza Comercial Sur S.A.', 17960,
    0, 2694, 20654, N'completed', '2026-09-24T14:30:00Z',
    N'Ana Silva', N'DGI-NIC|FACT-2026-00102|J0310000000019|J0310001112130|17960.00|2694.00|20654.00|2026-09-24'
);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1002' AND LineNumber = 1)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1002', 1, N'p2', 14, 950);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1002' AND LineNumber = 2)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1002', 2, N'p4', 2, 1850);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1002' AND LineNumber = 3)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1002', 3, N'p11', 4, 240);
MERGE dbo.Sales AS t
USING (SELECT N'fac-1003' AS SaleId) AS s ON t.SaleId = s.SaleId
WHEN MATCHED THEN UPDATE SET
    SaleNumber = N'FACT-2026-00103', ClientName = N'Desarrollos Inmobiliarios Las Colinas S.A.',
    Subtotal = 29400, DiscountAmount = 2352,
    TaxAmount = 4057.2, Total = 31105.2, Status = N'completed',
    SaleDate = '2026-10-02T11:15:00Z', CreatedBy = N'Ana Silva', QrPayload = N'DGI-NIC|FACT-2026-00103|J0310000000019|J0310001011120|27048.00|4057.20|31105.20|2026-10-02'
WHEN NOT MATCHED THEN INSERT (
    SaleId, SaleNumber, ClientName, Subtotal, DiscountAmount, TaxAmount, Total, Status, SaleDate, CreatedBy, QrPayload
) VALUES (
    N'fac-1003', N'FACT-2026-00103', N'Desarrollos Inmobiliarios Las Colinas S.A.', 29400,
    2352, 4057.2, 31105.2, N'completed', '2026-10-02T11:15:00Z',
    N'Ana Silva', N'DGI-NIC|FACT-2026-00103|J0310000000019|J0310001011120|27048.00|4057.20|31105.20|2026-10-02'
);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1003' AND LineNumber = 1)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1003', 1, N'p1', 25, 480);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1003' AND LineNumber = 2)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1003', 2, N'p6', 30, 420);
IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'fac-1003' AND LineNumber = 3)
    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'fac-1003', 3, N'p8', 40, 120);
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 6. PROFORMAS Y COTIZACIONES COMERCIALES
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Proformas Comerciales...';
MERGE dbo.Proformas AS t
USING (SELECT N'prof-1' AS ProformaId) AS s ON t.ProformaId = s.ProformaId
WHEN MATCHED THEN UPDATE SET
    ProformaNumber = N'PROF-2026-00045', ClientName = N'Torre Azul Condominios S.A.',
    Subtotal = 51440, DiscountAmount = 5144,
    TaxAmount = 6944.4, Total = 53240.4, Status = N'enviada',
    ValidUntil = '2026-11-15T23:59:59Z', Notes = N'CotizaciÃ³n incluye instalaciÃ³n con arneses de seguridad en altura y garantÃ­a de 3 aÃ±os.',
    CreatedAt = '2026-10-10T09:00:00Z', CreatedBy = N'Ana Silva', QrPayload = N'DGI-NIC|PROF-2026-00045|J0310000000019|J0310000708090|46296.00|6944.40|53240.40|2026-10-10'
WHEN NOT MATCHED THEN INSERT (
    ProformaId, ProformaNumber, ClientName, Subtotal, DiscountAmount, TaxAmount, Total, Status, ValidUntil, Notes, CreatedAt, CreatedBy, QrPayload
) VALUES (
    N'prof-1', N'PROF-2026-00045', N'Torre Azul Condominios S.A.', 51440,
    5144, 6944.4, 53240.4, N'enviada', '2026-11-15T23:59:59Z',
    N'CotizaciÃ³n incluye instalaciÃ³n con arneses de seguridad en altura y garantÃ­a de 3 aÃ±os.', '2026-10-10T09:00:00Z', N'Ana Silva', N'DGI-NIC|PROF-2026-00045|J0310000000019|J0310000708090|46296.00|6944.40|53240.40|2026-10-10'
);
IF NOT EXISTS (SELECT 1 FROM dbo.ProformaItems WHERE ProformaId = N'prof-1' AND LineNumber = 1)
    INSERT INTO dbo.ProformaItems (ProformaId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'prof-1', 1, N'p7', 32, 1450);
IF NOT EXISTS (SELECT 1 FROM dbo.ProformaItems WHERE ProformaId = N'prof-1' AND LineNumber = 2)
    INSERT INTO dbo.ProformaItems (ProformaId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'prof-1', 2, N'p3', 18, 280);
MERGE dbo.Proformas AS t
USING (SELECT N'prof-2' AS ProformaId) AS s ON t.ProformaId = s.ProformaId
WHEN MATCHED THEN UPDATE SET
    ProformaNumber = N'PROF-2026-00046', ClientName = N'Constructora MÃ¡ntica S.A.',
    Subtotal = 19560, DiscountAmount = 978,
    TaxAmount = 2787.3, Total = 21369.3, Status = N'borrador',
    ValidUntil = '2026-11-20T23:59:59Z', Notes = N'CancelerÃ­a interior para oficinas administrativas.',
    CreatedAt = '2026-10-14T15:00:00Z', CreatedBy = N'Ana Silva', QrPayload = N'DGI-NIC|PROF-2026-00046|J0310000000019|J0310000809100|18582.00|2787.30|21369.30|2026-10-14'
WHEN NOT MATCHED THEN INSERT (
    ProformaId, ProformaNumber, ClientName, Subtotal, DiscountAmount, TaxAmount, Total, Status, ValidUntil, Notes, CreatedAt, CreatedBy, QrPayload
) VALUES (
    N'prof-2', N'PROF-2026-00046', N'Constructora MÃ¡ntica S.A.', 19560,
    978, 2787.3, 21369.3, N'borrador', '2026-11-20T23:59:59Z',
    N'CancelerÃ­a interior para oficinas administrativas.', '2026-10-14T15:00:00Z', N'Ana Silva', N'DGI-NIC|PROF-2026-00046|J0310000000019|J0310000809100|18582.00|2787.30|21369.30|2026-10-14'
);
IF NOT EXISTS (SELECT 1 FROM dbo.ProformaItems WHERE ProformaId = N'prof-2' AND LineNumber = 1)
    INSERT INTO dbo.ProformaItems (ProformaId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'prof-2', 1, N'p5', 18, 620);
IF NOT EXISTS (SELECT 1 FROM dbo.ProformaItems WHERE ProformaId = N'prof-2' AND LineNumber = 2)
    INSERT INTO dbo.ProformaItems (ProformaId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'prof-2', 2, N'p6', 20, 420);
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 7. COMPRAS Y ÓRDENES DE COMPRA (OC)
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Órdenes de Compra a Proveedores...';
MERGE dbo.Purchases AS t
USING (SELECT N'cmp-2026-01' AS PurchaseId) AS s ON t.PurchaseId = s.PurchaseId
WHEN MATCHED THEN UPDATE SET
    PurchaseNumber = N'OC-2026-00081', SupplierName = N'Alumex de Nicaragua S.A.',
    SupplierPartyId = N'pv1', Total = 33700, Status = N'received',
    PurchaseDate = '2026-09-08T09:00:00Z', CreatedBy = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (PurchaseId, PurchaseNumber, SupplierName, SupplierPartyId, Total, Status, PurchaseDate, CreatedBy)
VALUES (N'cmp-2026-01', N'OC-2026-00081', N'Alumex de Nicaragua S.A.', N'pv1', 33700, N'received', '2026-09-08T09:00:00Z', N'Luis Morales');
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseItems WHERE PurchaseId = N'cmp-2026-01' AND LineNumber = 1)
    INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'cmp-2026-01', 1, N'p1', 50, 380);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseItems WHERE PurchaseId = N'cmp-2026-01' AND LineNumber = 2)
    INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'cmp-2026-01', 2, N'p5', 30, 490);
MERGE dbo.Purchases AS t
USING (SELECT N'cmp-2026-02' AS PurchaseId) AS s ON t.PurchaseId = s.PurchaseId
WHEN MATCHED THEN UPDATE SET
    PurchaseNumber = N'OC-2026-00082', SupplierName = N'Vidrios del PacÃ­fico S.A.',
    SupplierPartyId = N'pv2', Total = 47000, Status = N'received',
    PurchaseDate = '2026-09-15T11:00:00Z', CreatedBy = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (PurchaseId, PurchaseNumber, SupplierName, SupplierPartyId, Total, Status, PurchaseDate, CreatedBy)
VALUES (N'cmp-2026-02', N'OC-2026-00082', N'Vidrios del PacÃ­fico S.A.', N'pv2', 47000, N'received', '2026-09-15T11:00:00Z', N'Luis Morales');
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseItems WHERE PurchaseId = N'cmp-2026-02' AND LineNumber = 1)
    INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'cmp-2026-02', 1, N'p2', 40, 750);
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseItems WHERE PurchaseId = N'cmp-2026-02' AND LineNumber = 2)
    INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'cmp-2026-02', 2, N'p10', 25, 680);
MERGE dbo.Purchases AS t
USING (SELECT N'cmp-2026-03' AS PurchaseId) AS s ON t.PurchaseId = s.PurchaseId
WHEN MATCHED THEN UPDATE SET
    PurchaseNumber = N'OC-2026-00083', SupplierName = N'Selladores y QuÃ­micos Estructurales S.A.',
    SupplierPartyId = N'pv4', Total = 12600, Status = N'received',
    PurchaseDate = '2026-09-22T14:00:00Z', CreatedBy = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (PurchaseId, PurchaseNumber, SupplierName, SupplierPartyId, Total, Status, PurchaseDate, CreatedBy)
VALUES (N'cmp-2026-03', N'OC-2026-00083', N'Selladores y QuÃ­micos Estructurales S.A.', N'pv4', 12600, N'received', '2026-09-22T14:00:00Z', N'Luis Morales');
IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseItems WHERE PurchaseId = N'cmp-2026-03' AND LineNumber = 1)
    INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)
    VALUES (N'cmp-2026-03', 1, N'p3', 60, 210);
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 8. PROYECTOS DE CANCELERÍA Y ÓRDENES DE PRODUCCIÓN EN TALLER
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Proyectos y Producción...';
MERGE dbo.Projects AS t
USING (SELECT N'prj-1' AS ProjectId) AS s ON t.ProjectId = s.ProjectId
WHEN MATCHED THEN UPDATE SET
    Code = N'PRJ-001', Name = N'Fachada Flotante Edificio Ofiplaza Piso 4', Client = N'Grupo HÃ¡bitat S.A.',
    ClientPartyId = N'cl1', Amount = 185000, Budget = 125000,
    Progress = 85, ProjectState = N'En proceso', Owner = N'Carlos Mendoza',
    OwnerEmployeeId = N'emp-01', OperationalStage = N'instalacion',
    AuthorizationStatus = N'autorizada', CollectionStatus = N'parcial'
WHEN NOT MATCHED THEN INSERT (
    ProjectId, Code, Name, Client, ClientPartyId, Amount, Budget, Progress,
    ProjectState, Owner, OwnerEmployeeId, OperationalStage, AuthorizationStatus, CollectionStatus
) VALUES (
    N'prj-1', N'PRJ-001', N'Fachada Flotante Edificio Ofiplaza Piso 4', N'Grupo HÃ¡bitat S.A.', N'cl1',
    185000, 125000, 85, N'En proceso', N'Carlos Mendoza', N'emp-01',
    N'instalacion', N'autorizada', N'parcial'
);
MERGE dbo.Projects AS t
USING (SELECT N'prj-2' AS ProjectId) AS s ON t.ProjectId = s.ProjectId
WHEN MATCHED THEN UPDATE SET
    Code = N'PRJ-002', Name = N'VentanerÃ­a LÃ­nea Europea Residencial Las Colinas', Client = N'Desarrollos Inmobiliarios Las Colinas S.A.',
    ClientPartyId = N'cl5', Amount = 98000, Budget = 64000,
    Progress = 60, ProjectState = N'En proceso', Owner = N'Francisco Valle',
    OwnerEmployeeId = N'emp-03', OperationalStage = N'fabricacion',
    AuthorizationStatus = N'autorizada', CollectionStatus = N'parcial'
WHEN NOT MATCHED THEN INSERT (
    ProjectId, Code, Name, Client, ClientPartyId, Amount, Budget, Progress,
    ProjectState, Owner, OwnerEmployeeId, OperationalStage, AuthorizationStatus, CollectionStatus
) VALUES (
    N'prj-2', N'PRJ-002', N'VentanerÃ­a LÃ­nea Europea Residencial Las Colinas', N'Desarrollos Inmobiliarios Las Colinas S.A.', N'cl5',
    98000, 64000, 60, N'En proceso', N'Francisco Valle', N'emp-03',
    N'fabricacion', N'autorizada', N'parcial'
);
MERGE dbo.Projects AS t
USING (SELECT N'prj-3' AS ProjectId) AS s ON t.ProjectId = s.ProjectId
WHEN MATCHED THEN UPDATE SET
    Code = N'PRJ-003', Name = N'Frente de Tienda Vidrio Templado 12mm Plaza Sur', Client = N'Plaza Comercial Sur S.A.',
    ClientPartyId = N'cl4', Amount = 45000, Budget = 28000,
    Progress = 100, ProjectState = N'Liquidada', Owner = N'Carlos Mendoza',
    OwnerEmployeeId = N'emp-01', OperationalStage = N'entregado',
    AuthorizationStatus = N'autorizada', CollectionStatus = N'pagado'
WHEN NOT MATCHED THEN INSERT (
    ProjectId, Code, Name, Client, ClientPartyId, Amount, Budget, Progress,
    ProjectState, Owner, OwnerEmployeeId, OperationalStage, AuthorizationStatus, CollectionStatus
) VALUES (
    N'prj-3', N'PRJ-003', N'Frente de Tienda Vidrio Templado 12mm Plaza Sur', N'Plaza Comercial Sur S.A.', N'cl4',
    45000, 28000, 100, N'Liquidada', N'Carlos Mendoza', N'emp-01',
    N'entregado', N'autorizada', N'pagado'
);
MERGE dbo.Projects AS t
USING (SELECT N'prj-4' AS ProjectId) AS s ON t.ProjectId = s.ProjectId
WHEN MATCHED THEN UPDATE SET
    Code = N'PRJ-004', Name = N'Divisiones Hospitalarias ClÃ­nicas del Lago', Client = N'ClÃ­nica del Lago S.A.',
    ClientPartyId = N'cl6', Amount = 72000, Budget = 48000,
    Progress = 35, ProjectState = N'En proceso', Owner = N'Carlos Mendoza',
    OwnerEmployeeId = N'emp-01', OperationalStage = N'fabricacion',
    AuthorizationStatus = N'autorizada', CollectionStatus = N'parcial'
WHEN NOT MATCHED THEN INSERT (
    ProjectId, Code, Name, Client, ClientPartyId, Amount, Budget, Progress,
    ProjectState, Owner, OwnerEmployeeId, OperationalStage, AuthorizationStatus, CollectionStatus
) VALUES (
    N'prj-4', N'PRJ-004', N'Divisiones Hospitalarias ClÃ­nicas del Lago', N'ClÃ­nica del Lago S.A.', N'cl6',
    72000, 48000, 35, N'En proceso', N'Carlos Mendoza', N'emp-01',
    N'fabricacion', N'autorizada', N'parcial'
);
MERGE dbo.Projects AS t
USING (SELECT N'prj-5' AS ProjectId) AS s ON t.ProjectId = s.ProjectId
WHEN MATCHED THEN UPDATE SET
    Code = N'PRJ-005', Name = N'Barandales Inoxidables Torre Azul Piso 8 al 12', Client = N'Torre Azul Condominios S.A.',
    ClientPartyId = N'cl2', Amount = 140000, Budget = 92000,
    Progress = 15, ProjectState = N'Pendiente', Owner = N'Francisco Valle',
    OwnerEmployeeId = N'emp-03', OperationalStage = N'medicion',
    AuthorizationStatus = N'pendiente', CollectionStatus = N'pendiente'
WHEN NOT MATCHED THEN INSERT (
    ProjectId, Code, Name, Client, ClientPartyId, Amount, Budget, Progress,
    ProjectState, Owner, OwnerEmployeeId, OperationalStage, AuthorizationStatus, CollectionStatus
) VALUES (
    N'prj-5', N'PRJ-005', N'Barandales Inoxidables Torre Azul Piso 8 al 12', N'Torre Azul Condominios S.A.', N'cl2',
    140000, 92000, 15, N'Pendiente', N'Francisco Valle', N'emp-03',
    N'medicion', N'pendiente', N'pendiente'
);
MERGE dbo.ProductionOrders AS t
USING (SELECT N'ord-1' AS ProductionOrderId) AS s ON t.ProductionOrderId = s.ProductionOrderId
WHEN MATCHED THEN UPDATE SET
    Code = N'OP-2026-001', Product = N'Muro Cortina MC-80 con Vidrio Reflectivo 8mm', Client = N'Grupo HÃ¡bitat S.A.',
    Quantity = 14, Stage = N'instalacion', Sprint = N'Sprint 18', Owner = N'Denis Somarriba'
WHEN NOT MATCHED THEN INSERT (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)
VALUES (N'ord-1', N'OP-2026-001', N'Muro Cortina MC-80 con Vidrio Reflectivo 8mm', N'Grupo HÃ¡bitat S.A.', 14, N'instalacion', N'Sprint 18', N'Denis Somarriba');
MERGE dbo.ProductionOrders AS t
USING (SELECT N'ord-2' AS ProductionOrderId) AS s ON t.ProductionOrderId = s.ProductionOrderId
WHEN MATCHED THEN UPDATE SET
    Code = N'OP-2026-002', Product = N'Ventanas Serie 5020 con Mosquiteros', Client = N'Desarrollos Inmobiliarios Las Colinas',
    Quantity = 22, Stage = N'ensamble', Sprint = N'Sprint 18', Owner = N'Wilmer JarquÃ­n'
WHEN NOT MATCHED THEN INSERT (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)
VALUES (N'ord-2', N'OP-2026-002', N'Ventanas Serie 5020 con Mosquiteros', N'Desarrollos Inmobiliarios Las Colinas', 22, N'ensamble', N'Sprint 18', N'Wilmer JarquÃ­n');
MERGE dbo.ProductionOrders AS t
USING (SELECT N'ord-3' AS ProductionOrderId) AS s ON t.ProductionOrderId = s.ProductionOrderId
WHEN MATCHED THEN UPDATE SET
    Code = N'OP-2026-003', Product = N'Puerta Batiente Templada 10mm con Pivote Dorma', Client = N'Plaza Comercial Sur',
    Quantity = 2, Stage = N'entregado', Sprint = N'Sprint 17', Owner = N'Roberto ToruÃ±o'
WHEN NOT MATCHED THEN INSERT (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)
VALUES (N'ord-3', N'OP-2026-003', N'Puerta Batiente Templada 10mm con Pivote Dorma', N'Plaza Comercial Sur', 2, N'entregado', N'Sprint 17', N'Roberto ToruÃ±o');
MERGE dbo.ProductionOrders AS t
USING (SELECT N'ord-4' AS ProductionOrderId) AS s ON t.ProductionOrderId = s.ProductionOrderId
WHEN MATCHED THEN UPDATE SET
    Code = N'OP-2026-004', Product = N'Canceles Hospitalarios Sellados 6mm', Client = N'ClÃ­nica del Lago S.A.',
    Quantity = 8, Stage = N'corte', Sprint = N'Sprint 19', Owner = N'Marlon Calero'
WHEN NOT MATCHED THEN INSERT (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)
VALUES (N'ord-4', N'OP-2026-004', N'Canceles Hospitalarios Sellados 6mm', N'ClÃ­nica del Lago S.A.', 8, N'corte', N'Sprint 19', N'Marlon Calero');
MERGE dbo.ProductionOrders AS t
USING (SELECT N'ord-5' AS ProductionOrderId) AS s ON t.ProductionOrderId = s.ProductionOrderId
WHEN MATCHED THEN UPDATE SET
    Code = N'OP-2026-005', Product = N'Barandales de Acero Inox con Vidrio 12mm', Client = N'Torre Azul Condominios',
    Quantity = 16, Stage = N'backlog', Sprint = N'Sprint 19', Owner = N'Francisco Valle'
WHEN NOT MATCHED THEN INSERT (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)
VALUES (N'ord-5', N'OP-2026-005', N'Barandales de Acero Inox con Vidrio 12mm', N'Torre Azul Condominios', 16, N'backlog', N'Sprint 19', N'Francisco Valle');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 9. TALENTO HUMANO: 14 EXPEDIENTES LABORALES Y CONTRATOS INDEFINIDOS DE LEY
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Colaboradores y Contratos de Trabajo (Ley 185)...';
MERGE dbo.Employees AS t
USING (SELECT N'emp-01' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Carlos Mendoza', Position = N'Ingeniero de Proyectos y Producción', Salary = 28500,
    Area = N'produccion', HireDate = '2024-01-15', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-01', N'Carlos Mendoza', N'Ingeniero de Proyectos y Producción', 28500, N'produccion', '2024-01-15', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-01')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-01', N'CT-RAQUEL-2024-01', N'indefinido', N'Ingeniero de Proyectos y Producción', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-01-15', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-02' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Jhonny Garcia', Position = N'Administrador de Operaciones y Ventas', Salary = 25000,
    Area = N'administracion', HireDate = '2024-02-01', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-02', N'Jhonny Garcia', N'Administrador de Operaciones y Ventas', 25000, N'administracion', '2024-02-01', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-02')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-02', N'CT-RAQUEL-2024-02', N'indefinido', N'Administrador de Operaciones y Ventas', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-02-01', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-03' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Francisco Valle', Position = N'Maestro Aluminero y Supervisor', Salary = 19500,
    Area = N'produccion', HireDate = '2024-03-01', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-03', N'Francisco Valle', N'Maestro Aluminero y Supervisor', 19500, N'produccion', '2024-03-01', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-03')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-03', N'CT-RAQUEL-2024-03', N'indefinido', N'Maestro Aluminero y Supervisor', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-03-01', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-04' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Roberto Toruño', Position = N'Operario de Corte y Troquelado', Salary = 14500,
    Area = N'produccion', HireDate = '2024-04-10', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-04', N'Roberto Toruño', N'Operario de Corte y Troquelado', 14500, N'produccion', '2024-04-10', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-04')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-04', N'CT-RAQUEL-2024-04', N'indefinido', N'Operario de Corte y Troquelado', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-04-10', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-05' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Marlon Calero', Position = N'Operario Especialista en Vidrio', Salary = 15200,
    Area = N'produccion', HireDate = '2024-04-15', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-05', N'Marlon Calero', N'Operario Especialista en Vidrio', 15200, N'produccion', '2024-04-15', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-05')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-05', N'CT-RAQUEL-2024-05', N'indefinido', N'Operario Especialista en Vidrio', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-04-15', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-06' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Wilmer Jarquín', Position = N'Armador de Ventanería y Fachadas', Salary = 13800,
    Area = N'produccion', HireDate = '2024-05-02', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-06', N'Wilmer Jarquín', N'Armador de Ventanería y Fachadas', 13800, N'produccion', '2024-05-02', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-06')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-06', N'CT-RAQUEL-2024-06', N'indefinido', N'Armador de Ventanería y Fachadas', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-05-02', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-07' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Denis Somarriba', Position = N'Instalador Líder de Altura', Salary = 16500,
    Area = N'produccion', HireDate = '2024-05-15', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-07', N'Denis Somarriba', N'Instalador Líder de Altura', 16500, N'produccion', '2024-05-15', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-07')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-07', N'CT-RAQUEL-2024-07', N'indefinido', N'Instalador Líder de Altura', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-05-15', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-08' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'José Blandón', Position = N'Auxiliar de Instalación en Obra', Salary = 11500,
    Area = N'produccion', HireDate = '2024-06-01', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-08', N'José Blandón', N'Auxiliar de Instalación en Obra', 11500, N'produccion', '2024-06-01', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-08')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-08', N'CT-RAQUEL-2024-08', N'indefinido', N'Auxiliar de Instalación en Obra', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-06-01', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-09' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Kevin Rivas', Position = N'Auxiliar de Taller y Mantenimiento', Salary = 10800,
    Area = N'produccion', HireDate = '2024-06-15', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-09', N'Kevin Rivas', N'Auxiliar de Taller y Mantenimiento', 10800, N'produccion', '2024-06-15', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-09')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-09', N'CT-RAQUEL-2024-09', N'indefinido', N'Auxiliar de Taller y Mantenimiento', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-06-15', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-10' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Ana Silva', Position = N'Ejecutiva de Ventas Técnicas', Salary = 18000,
    Area = N'ventas', HireDate = '2024-02-15', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-10', N'Ana Silva', N'Ejecutiva de Ventas Técnicas', 18000, N'ventas', '2024-02-15', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-10')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-10', N'CT-RAQUEL-2024-10', N'indefinido', N'Ejecutiva de Ventas Técnicas', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-02-15', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-11' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'María Elena Cruz', Position = N'Contadora General', Salary = 26000,
    Area = N'contabilidad', HireDate = '2024-01-20', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-11', N'María Elena Cruz', N'Contadora General', 26000, N'contabilidad', '2024-01-20', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-11')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-11', N'CT-RAQUEL-2024-11', N'indefinido', N'Contadora General', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-01-20', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-12' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Luis Morales', Position = N'Encargado de Compras y Bodega', Salary = 17000,
    Area = N'compras', HireDate = '2024-03-10', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-12', N'Luis Morales', N'Encargado de Compras y Bodega', 17000, N'compras', '2024-03-10', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-12')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-12', N'CT-RAQUEL-2024-12', N'indefinido', N'Encargado de Compras y Bodega', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-03-10', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-13' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Patricia Mayorga', Position = N'Asistente Administrativa y RRHH', Salary = 14000,
    Area = N'rrhh', HireDate = '2024-04-01', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-13', N'Patricia Mayorga', N'Asistente Administrativa y RRHH', 14000, N'rrhh', '2024-04-01', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-13')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-13', N'CT-RAQUEL-2024-13', N'indefinido', N'Asistente Administrativa y RRHH', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2024-04-01', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
MERGE dbo.Employees AS t
USING (SELECT N'emp-14' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
WHEN MATCHED THEN UPDATE SET
    Name = N'Raquel López', Position = N'Gerente General y Propietaria', Salary = 38000,
    Area = N'direccion', HireDate = '2023-11-01', IsActive = 1, EmploymentStatus = N'activo'
WHEN NOT MATCHED THEN INSERT (
    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus
) VALUES (
    N'emp-14', N'Raquel López', N'Gerente General y Propietaria', 38000, N'direccion', '2023-11-01', 1, N'activo'
);
IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'emp-14')
BEGIN
    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
    VALUES (NEWID(), N'emp-14', N'CT-RAQUEL-2024-14', N'indefinido', N'Gerente General y Propietaria', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '2023-11-01', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
END;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 10. GESTIÓN DE BIENESTAR: ASISTENCIA, EPP, SOLICITUDES Y CAPACITACIONES
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Asistencias, Solicitudes y Entregas de EPP...';
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-01' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-01', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-02' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-02', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-03' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-03', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-04' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-04', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-05' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-05', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-06' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-06', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-07' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-07', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-08' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-08', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-09' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-09', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-10' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-10', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-11' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-11', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-12' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-12', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-13' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-13', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'emp-14' AND RecordDate = '2026-10-16')
BEGIN
    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)
    VALUES (NEWID(), N'emp-14', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE EmployeeId = N'emp-03' AND Category = N'vacaciones')
BEGIN
    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, Resolution, AssignedToAppUserId, DecidedByAppUserId, DecidedAt, CreatedAt, UpdatedAt)
    VALUES (NEWID(), NEWID(), N'emp-03', N'vacaciones', '2026-11-03', '2026-11-07', N'Solicitud de 5 días de vacaciones anuales según Art. 76 Código del Trabajo.', N'aprobada', N'Aprobadas 5 días de vacaciones ordinarias acumuladas.', N'u-super', N'u-super', SYSUTCDATETIME(), SYSUTCDATETIME(), SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE EmployeeId = N'emp-06' AND Category = N'vacaciones')
BEGIN
    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, Resolution, AssignedToAppUserId, DecidedByAppUserId, DecidedAt, CreatedAt, UpdatedAt)
    VALUES (NEWID(), NEWID(), N'emp-06', N'vacaciones', '2026-11-16', '2026-11-21', N'Solicitud de 6 días de vacaciones por asuntos familiares.', N'en_revision', N'En revisión de disponibilidad de relevo en taller de corte.', N'u-super', NULL, NULL, SYSUTCDATETIME(), SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE EmployeeId = N'emp-07' AND Category = N'permiso')
BEGIN
    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, Resolution, AssignedToAppUserId, DecidedByAppUserId, DecidedAt, CreatedAt, UpdatedAt)
    VALUES (NEWID(), NEWID(), N'emp-07', N'permiso', '2026-10-20', '2026-10-21', N'Cita médica programada en clínica médica previsional del INSS.', N'aprobada', N'Permiso con goce de salario por constancia de atención médica INSS.', N'u-super', N'u-super', SYSUTCDATETIME(), SYSUTCDATETIME(), SYSUTCDATETIME());
END;
IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE EmployeeId = N'emp-05' AND Category = N'seguridad')
BEGIN
    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, Resolution, AssignedToAppUserId, DecidedByAppUserId, DecidedAt, CreatedAt, UpdatedAt)
    VALUES (NEWID(), NEWID(), N'emp-05', N'seguridad', NULL, NULL, N'Reporte de desgaste preventivo en guantes anticorte y solicitud de reposición para corte de vidrio templado.', N'enviada', N'Pendiente entrega en bodega de seguridad.', N'u-super', NULL, NULL, SYSUTCDATETIME(), SYSUTCDATETIME());
END;
DECLARE @EquipVidrio UNIQUEIDENTIFIER;
SELECT TOP 1 @EquipVidrio = EquipmentId FROM dbo.HrSafetyEquipment WHERE Category = 'vidrio' AND Name LIKE '%Guantes anticorte%';
IF @EquipVidrio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = 'emp-05')
BEGIN
    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes, CreatedAt)
    VALUES (NEWID(), N'emp-05', @EquipVidrio, '2026-10-01', N'dotacion_inicial', '2026-12-30', N'Dotación de guantes anticorte nivel 5 para manipulación de cristales templados.', SYSUTCDATETIME());
END;
DECLARE @EquipAltura UNIQUEIDENTIFIER;
SELECT TOP 1 @EquipAltura = EquipmentId FROM dbo.HrSafetyEquipment WHERE Category = 'altura' AND Name LIKE '%Arnés%';
IF @EquipAltura IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = 'emp-07')
BEGIN
    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes, CreatedAt)
    VALUES (NEWID(), N'emp-07', @EquipAltura, '2026-09-15', N'dotacion_inicial', '2027-03-15', N'Arnés de cuerpo entero 4 argollas para instalación de muro cortina en altura.', SYSUTCDATETIME());
END;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 11. PLANILLA DE NÓMINA NICARAGÜENSE 2026-10-1Q (LEY 185 Y LEY 822)
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Planilla de Nómina Quincenal y Desglose de 14 Colaboradores...';
MERGE dbo.PayrollRuns AS t
USING (SELECT N'pr-2026-10-1' AS PayrollRunId) AS s ON t.PayrollRunId = s.PayrollRunId
WHEN MATCHED THEN UPDATE SET
    Period = N'2026-10-1Q', StartDate = '2026-10-01', EndDate = '2026-10-15', PaymentDate = '2026-10-15',
    PaidAt = '2026-10-15 16:00:00', Status = N'cerrada', CalculationVersion = 1,
    Gross = 137150.00, InssLaboral = 9600.50, IncomeTax = 11746.96, Net = 115802.54,
    InssPatronal = 29487.25, Inatec = 2743.00, EmployerCost = 203667.74,
    ConfirmedPaymentsTotal = 115802.54, PendingDiscrepancyTotal = 0, UpdatedAt = SYSUTCDATETIME()
WHEN NOT MATCHED THEN INSERT (
    PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, PaidAt, Status, CalculationVersion,
    Actor, Gross, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, EmployerCost,
    ConfirmedPaymentsTotal, PendingDiscrepancyTotal, CreatedAt, UpdatedAt
) VALUES (
    N'pr-2026-10-1', N'2026-10-1Q', N'quincenal', '2026-10-01', '2026-10-15', '2026-10-15', '2026-10-15 16:00:00', N'cerrada', 1,
    N'María Elena Cruz', 137150.00, 9600.50, 11746.96, 115802.54, 29487.25, 2743.00, 203667.74,
    115802.54, 0, SYSUTCDATETIME(), SYSUTCDATETIME()
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-01' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 14250, InssLaboral = 997.5, IncomeTax = 1608.83, Net = 11643.67,
    InssPatronal = 3063.75, Inatec = 285, Aguinaldo = 1187.5,
    EmployerCost = 21161.25, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-01', N'pr-2026-10-1', N'emp-01', N'Ingeniero de Proyectos y Producción', N'produccion', 28500,
    15.0, 120.0, 14250, 0, 0,
    14250, 14250, 13252.5, 997.5, 1608.83, 11643.67, 3063.75, 285, 1187.5,
    1187.5, 1187.5, 21161.25, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-02' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 12500, InssLaboral = 875, IncomeTax = 1283.33, Net = 10341.67,
    InssPatronal = 2687.5, Inatec = 250, Aguinaldo = 1041.67,
    EmployerCost = 18562.51, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-02', N'pr-2026-10-1', N'emp-02', N'Administrador de Operaciones y Ventas', N'administracion', 25000,
    15.0, 120.0, 12500, 0, 0,
    12500, 12500, 11625, 875, 1283.33, 10341.67, 2687.5, 250, 1041.67,
    1041.67, 1041.67, 18562.51, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-03' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 11375, InssLaboral = 796.25, IncomeTax = 1074.08, Net = 9504.67,
    InssPatronal = 2445.63, Inatec = 227.5, Aguinaldo = 947.92,
    EmployerCost = 16891.89, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-03', N'pr-2026-10-1', N'emp-03', N'Maestro Aluminero y Supervisor', N'produccion', 19500,
    15.0, 120.0, 9750, 10, 1625,
    11375, 11375, 10578.75, 796.25, 1074.08, 9504.67, 2445.63, 227.5, 947.92,
    947.92, 947.92, 16891.89, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-04' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 7250, InssLaboral = 507.5, IncomeTax = 386.38, Net = 6356.12,
    InssPatronal = 1558.75, Inatec = 145, Aguinaldo = 604.17,
    EmployerCost = 10766.26, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-04', N'pr-2026-10-1', N'emp-04', N'Operario de Corte y Troquelado', N'produccion', 14500,
    15.0, 120.0, 7250, 0, 0,
    7250, 7250, 6742.5, 507.5, 386.38, 6356.12, 1558.75, 145, 604.17,
    604.17, 604.17, 10766.26, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-05' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 7600, InssLaboral = 532, IncomeTax = 435.2, Net = 6632.8,
    InssPatronal = 1634, Inatec = 152, Aguinaldo = 633.33,
    EmployerCost = 11285.99, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-05', N'pr-2026-10-1', N'emp-05', N'Operario Especialista en Vidrio', N'produccion', 15200,
    15.0, 120.0, 7600, 0, 0,
    7600, 7600, 7068, 532, 435.2, 6632.8, 1634, 152, 633.33,
    633.33, 633.33, 11285.99, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-06' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 6900, InssLaboral = 483, IncomeTax = 337.55, Net = 6079.45,
    InssPatronal = 1483.5, Inatec = 138, Aguinaldo = 575,
    EmployerCost = 10246.5, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-06', N'pr-2026-10-1', N'emp-06', N'Armador de Ventanería y Fachadas', N'produccion', 13800,
    15.0, 120.0, 6900, 0, 0,
    6900, 6900, 6417, 483, 337.55, 6079.45, 1483.5, 138, 575,
    575, 575, 10246.5, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-07' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 9625, InssLaboral = 673.75, IncomeTax = 748.58, Net = 8202.67,
    InssPatronal = 2069.38, Inatec = 192.5, Aguinaldo = 802.08,
    EmployerCost = 14293.12, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-07', N'pr-2026-10-1', N'emp-07', N'Instalador Líder de Altura', N'produccion', 16500,
    15.0, 120.0, 8250, 10, 1375,
    9625, 9625, 8951.25, 673.75, 748.58, 8202.67, 2069.38, 192.5, 802.08,
    802.08, 802.08, 14293.12, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-08' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 5750, InssLaboral = 402.5, IncomeTax = 177.13, Net = 5170.37,
    InssPatronal = 1236.25, Inatec = 115, Aguinaldo = 479.17,
    EmployerCost = 8538.76, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-08', N'pr-2026-10-1', N'emp-08', N'Auxiliar de Instalación en Obra', N'produccion', 11500,
    15.0, 120.0, 5750, 0, 0,
    5750, 5750, 5347.5, 402.5, 177.13, 5170.37, 1236.25, 115, 479.17,
    479.17, 479.17, 8538.76, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-09' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 5400, InssLaboral = 378, IncomeTax = 128.3, Net = 4893.7,
    InssPatronal = 1161, Inatec = 108, Aguinaldo = 450,
    EmployerCost = 8019, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-09', N'pr-2026-10-1', N'emp-09', N'Auxiliar de Taller y Mantenimiento', N'produccion', 10800,
    15.0, 120.0, 5400, 0, 0,
    5400, 5400, 5022, 378, 128.3, 4893.7, 1161, 108, 450,
    450, 450, 8019, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-10' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 9000, InssLaboral = 630, IncomeTax = 632.33, Net = 7737.67,
    InssPatronal = 1935, Inatec = 180, Aguinaldo = 750,
    EmployerCost = 13365, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-10', N'pr-2026-10-1', N'emp-10', N'Ejecutiva de Ventas Técnicas', N'ventas', 18000,
    15.0, 120.0, 9000, 0, 0,
    9000, 9000, 8370, 630, 632.33, 7737.67, 1935, 180, 750,
    750, 750, 13365, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-11' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 13000, InssLaboral = 910, IncomeTax = 1376.33, Net = 10713.67,
    InssPatronal = 2795, Inatec = 260, Aguinaldo = 1083.33,
    EmployerCost = 19304.99, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-11', N'pr-2026-10-1', N'emp-11', N'Contadora General', N'contabilidad', 26000,
    15.0, 120.0, 13000, 0, 0,
    13000, 13000, 12090, 910, 1376.33, 10713.67, 2795, 260, 1083.33,
    1083.33, 1083.33, 19304.99, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-12' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 8500, InssLaboral = 595, IncomeTax = 560.75, Net = 7344.25,
    InssPatronal = 1827.5, Inatec = 170, Aguinaldo = 708.33,
    EmployerCost = 12622.49, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-12', N'pr-2026-10-1', N'emp-12', N'Encargado de Compras y Bodega', N'compras', 17000,
    15.0, 120.0, 8500, 0, 0,
    8500, 8500, 7905, 595, 560.75, 7344.25, 1827.5, 170, 708.33,
    708.33, 708.33, 12622.49, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-13' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 7000, InssLaboral = 490, IncomeTax = 351.5, Net = 6158.5,
    InssPatronal = 1505, Inatec = 140, Aguinaldo = 583.33,
    EmployerCost = 10394.99, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-13', N'pr-2026-10-1', N'emp-13', N'Asistente Administrativa y RRHH', N'rrhh', 14000,
    15.0, 120.0, 7000, 0, 0,
    7000, 7000, 6510, 490, 351.5, 6158.5, 1505, 140, 583.33,
    583.33, 583.33, 10394.99, N'pagado', N'emitida'
);
MERGE dbo.PayrollRunItems AS t
USING (SELECT N'item-pr-2026-10-1-emp-14' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
WHEN MATCHED THEN UPDATE SET
    Gross = 19000, InssLaboral = 1330, IncomeTax = 2646.67, Net = 15023.33,
    InssPatronal = 4085, Inatec = 380, Aguinaldo = 1583.33,
    EmployerCost = 28214.99, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
WHEN NOT MATCHED THEN INSERT (
    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus
) VALUES (
    N'item-pr-2026-10-1-emp-14', N'pr-2026-10-1', N'emp-14', N'Gerente General y Propietaria', N'direccion', 38000,
    15.0, 120.0, 19000, 0, 0,
    19000, 19000, 17670, 1330, 2646.67, 15023.33, 4085, 380, 1583.33,
    1583.33, 1583.33, 28214.99, N'pagado', N'emitida'
);
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 12. ASIENTOS CONTABLES DE PARTIDA DOBLE Y MOVIMIENTOS BANCARIOS
-- -----------------------------------------------------------------------------------------
PRINT 'Cargando Asientos Contables Cuadrados y Movimientos de Caja y Bancos...';
MERGE dbo.AccountingEntries AS t
USING (SELECT N'ast-001' AS AccountingEntryId) AS s ON t.AccountingEntryId = s.AccountingEntryId
WHEN MATCHED THEN UPDATE SET
    EntryNumber = N'AST-2026-0001', Description = N'FacturaciÃ³n Proyecto PRJ-001 Ofiplaza Fachada Flotante (Factura FACT-2026-00101)',
    Debit = 48201.1, Credit = 48201.1, DebitAccount = N'1103 Cuentas por Cobrar Clientes',
    CreditAccount = N'4101 Ingresos por Obras de CancelerÃ­a y Vidrio', EntryDate = '2026-09-18T10:00:00Z',
    ReferenceType = N'sale', ReferenceId = N'fac-1001'
WHEN NOT MATCHED THEN INSERT (
    AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId
) VALUES (
    N'ast-001', N'AST-2026-0001', N'FacturaciÃ³n Proyecto PRJ-001 Ofiplaza Fachada Flotante (Factura FACT-2026-00101)', 48201.1, 48201.1,
    N'1103 Cuentas por Cobrar Clientes', N'4101 Ingresos por Obras de CancelerÃ­a y Vidrio', '2026-09-18T10:00:00Z', N'sale', N'fac-1001'
);
MERGE dbo.AccountingEntries AS t
USING (SELECT N'ast-002' AS AccountingEntryId) AS s ON t.AccountingEntryId = s.AccountingEntryId
WHEN MATCHED THEN UPDATE SET
    EntryNumber = N'AST-2026-0002', Description = N'Compra de perfiles de aluminio a Alumex de Nicaragua (Orden OC-2026-00081)',
    Debit = 38755, Credit = 38755, DebitAccount = N'1105 Inventario Materia Prima e IVA Acreditable',
    CreditAccount = N'2101 Cuentas por Pagar Proveedores y RetenciÃ³n DGI', EntryDate = '2026-09-08T09:00:00Z',
    ReferenceType = N'purchase', ReferenceId = N'cmp-2026-01'
WHEN NOT MATCHED THEN INSERT (
    AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId
) VALUES (
    N'ast-002', N'AST-2026-0002', N'Compra de perfiles de aluminio a Alumex de Nicaragua (Orden OC-2026-00081)', 38755, 38755,
    N'1105 Inventario Materia Prima e IVA Acreditable', N'2101 Cuentas por Pagar Proveedores y RetenciÃ³n DGI', '2026-09-08T09:00:00Z', N'purchase', N'cmp-2026-01'
);
MERGE dbo.AccountingEntries AS t
USING (SELECT N'ast-003' AS AccountingEntryId) AS s ON t.AccountingEntryId = s.AccountingEntryId
WHEN MATCHED THEN UPDATE SET
    EntryNumber = N'AST-2026-0003', Description = N'Registro contable devengado NÃ³mina Quincenal 2026-10-1Q (14 trabajadores)',
    Debit = 203667.73999999993, Credit = 203667.73999999993, DebitAccount = N'5101 Gastos de Sueldos y Cargas Sociales',
    CreditAccount = N'2105 Sueldos, Retenciones y Aportes Patronales por Pagar', EntryDate = '2026-10-15T15:00:00Z',
    ReferenceType = N'payroll', ReferenceId = N'pr-2026-10-1'
WHEN NOT MATCHED THEN INSERT (
    AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId
) VALUES (
    N'ast-003', N'AST-2026-0003', N'Registro contable devengado NÃ³mina Quincenal 2026-10-1Q (14 trabajadores)', 203667.73999999993, 203667.73999999993,
    N'5101 Gastos de Sueldos y Cargas Sociales', N'2105 Sueldos, Retenciones y Aportes Patronales por Pagar', '2026-10-15T15:00:00Z', N'payroll', N'pr-2026-10-1'
);
MERGE dbo.AccountingEntries AS t
USING (SELECT N'ast-004' AS AccountingEntryId) AS s ON t.AccountingEntryId = s.AccountingEntryId
WHEN MATCHED THEN UPDATE SET
    EntryNumber = N'AST-2026-0004', Description = N'Pago de NÃ³mina Quincenal 2026-10-1Q mediante transferencia bancaria BANPRO',
    Debit = 115802.54000000001, Credit = 115802.54000000001, DebitAccount = N'2105 Sueldos por Pagar',
    CreditAccount = N'1102 Banco de la ProducciÃ³n (BANPRO) Cuenta Corriente C$', EntryDate = '2026-10-15T16:00:00Z',
    ReferenceType = N'payroll', ReferenceId = N'pr-2026-10-1'
WHEN NOT MATCHED THEN INSERT (
    AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId
) VALUES (
    N'ast-004', N'AST-2026-0004', N'Pago de NÃ³mina Quincenal 2026-10-1Q mediante transferencia bancaria BANPRO', 115802.54000000001, 115802.54000000001,
    N'2105 Sueldos por Pagar', N'1102 Banco de la ProducciÃ³n (BANPRO) Cuenta Corriente C$', '2026-10-15T16:00:00Z', N'payroll', N'pr-2026-10-1'
);
MERGE dbo.AccountingEntries AS t
USING (SELECT N'ast-005' AS AccountingEntryId) AS s ON t.AccountingEntryId = s.AccountingEntryId
WHEN MATCHED THEN UPDATE SET
    EntryNumber = N'AST-2026-0005', Description = N'Cobro transferencia bancaria BAC Credomatic de Factura Plaza Sur',
    Debit = 20654, Credit = 20654, DebitAccount = N'1101 Banco BAC Credomatic Cuenta C$',
    CreditAccount = N'1103 Cuentas por Cobrar Clientes', EntryDate = '2026-09-25T11:00:00Z',
    ReferenceType = N'cash', ReferenceId = N'csh-002'
WHEN NOT MATCHED THEN INSERT (
    AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId
) VALUES (
    N'ast-005', N'AST-2026-0005', N'Cobro transferencia bancaria BAC Credomatic de Factura Plaza Sur', 20654, 20654,
    N'1101 Banco BAC Credomatic Cuenta C$', N'1103 Cuentas por Cobrar Clientes', '2026-09-25T11:00:00Z', N'cash', N'csh-002'
);
MERGE dbo.CashMoves AS t
USING (SELECT N'csh-001' AS CashMoveId) AS s ON t.CashMoveId = s.CashMoveId
WHEN MATCHED THEN UPDATE SET
    Account = N'banco', MoveType = N'entrada', Amount = 25000,
    MoveDate = '2026-09-18T14:00:00Z', Concept = N'Anticipo 50% segÃºn contrato Proyecto Ofiplaza Grupo HÃ¡bitat'
WHEN NOT MATCHED THEN INSERT (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
VALUES (N'csh-001', N'banco', N'entrada', 25000, '2026-09-18T14:00:00Z', N'Anticipo 50% segÃºn contrato Proyecto Ofiplaza Grupo HÃ¡bitat');
MERGE dbo.CashMoves AS t
USING (SELECT N'csh-002' AS CashMoveId) AS s ON t.CashMoveId = s.CashMoveId
WHEN MATCHED THEN UPDATE SET
    Account = N'banco', MoveType = N'entrada', Amount = 20654,
    MoveDate = '2026-09-25T11:00:00Z', Concept = N'Cobro total de factura FACT-2026-00102 Plaza Sur'
WHEN NOT MATCHED THEN INSERT (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
VALUES (N'csh-002', N'banco', N'entrada', 20654, '2026-09-25T11:00:00Z', N'Cobro total de factura FACT-2026-00102 Plaza Sur');
MERGE dbo.CashMoves AS t
USING (SELECT N'csh-003' AS CashMoveId) AS s ON t.CashMoveId = s.CashMoveId
WHEN MATCHED THEN UPDATE SET
    Account = N'banco', MoveType = N'salida', Amount = 15000,
    MoveDate = '2026-09-20T10:00:00Z', Concept = N'Abono a proveedor Alumex de Nicaragua transferencia BANPRO'
WHEN NOT MATCHED THEN INSERT (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
VALUES (N'csh-003', N'banco', N'salida', 15000, '2026-09-20T10:00:00Z', N'Abono a proveedor Alumex de Nicaragua transferencia BANPRO');
MERGE dbo.CashMoves AS t
USING (SELECT N'csh-004' AS CashMoveId) AS s ON t.CashMoveId = s.CashMoveId
WHEN MATCHED THEN UPDATE SET
    Account = N'banco', MoveType = N'salida', Amount = 115802.54,
    MoveDate = '2026-10-15T16:00:00Z', Concept = N'DispersiÃ³n electrÃ³nica de salarios NÃ³mina 2026-10-1Q'
WHEN NOT MATCHED THEN INSERT (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
VALUES (N'csh-004', N'banco', N'salida', 115802.54, '2026-10-15T16:00:00Z', N'DispersiÃ³n electrÃ³nica de salarios NÃ³mina 2026-10-1Q');
MERGE dbo.CashMoves AS t
USING (SELECT N'csh-005' AS CashMoveId) AS s ON t.CashMoveId = s.CashMoveId
WHEN MATCHED THEN UPDATE SET
    Account = N'caja', MoveType = N'entrada', Amount = 8500,
    MoveDate = '2026-10-05T09:00:00Z', Concept = N'Venta de mostrador y retal de perfiles aluminio taller'
WHEN NOT MATCHED THEN INSERT (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
VALUES (N'csh-005', N'caja', N'entrada', 8500, '2026-10-05T09:00:00Z', N'Venta de mostrador y retal de perfiles aluminio taller');
MERGE dbo.CashMoves AS t
USING (SELECT N'csh-006' AS CashMoveId) AS s ON t.CashMoveId = s.CashMoveId
WHEN MATCHED THEN UPDATE SET
    Account = N'caja', MoveType = N'salida', Amount = 1250,
    MoveDate = '2026-10-08T15:30:00Z', Concept = N'Gastos menores de taller: brocas para aluminio y lija de agua'
WHEN NOT MATCHED THEN INSERT (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)
VALUES (N'csh-006', N'caja', N'salida', 1250, '2026-10-08T15:30:00Z', N'Gastos menores de taller: brocas para aluminio y lija de agua');
MERGE dbo.FinanceMoves AS t
USING (SELECT N'fin-1' AS FinanceMoveId) AS s ON t.FinanceMoveId = s.FinanceMoveId
WHEN MATCHED THEN UPDATE SET
    MoveType = N'ingreso', Category = N'Obras y Proyectos', Amount = 48201.1,
    MoveDate = '2026-09-18T10:00:00Z', Note = N'Factura Ofiplaza Piso 4', UserName = N'MarÃ­a Elena Cruz'
WHEN NOT MATCHED THEN INSERT (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
VALUES (N'fin-1', N'ingreso', N'Obras y Proyectos', 48201.1, '2026-09-18T10:00:00Z', N'Factura Ofiplaza Piso 4', N'MarÃ­a Elena Cruz');
MERGE dbo.FinanceMoves AS t
USING (SELECT N'fin-2' AS FinanceMoveId) AS s ON t.FinanceMoveId = s.FinanceMoveId
WHEN MATCHED THEN UPDATE SET
    MoveType = N'ingreso', Category = N'Venta Comercial', Amount = 20654,
    MoveDate = '2026-09-24T14:30:00Z', Note = N'Frente de tienda Plaza Sur', UserName = N'MarÃ­a Elena Cruz'
WHEN NOT MATCHED THEN INSERT (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
VALUES (N'fin-2', N'ingreso', N'Venta Comercial', 20654, '2026-09-24T14:30:00Z', N'Frente de tienda Plaza Sur', N'MarÃ­a Elena Cruz');
MERGE dbo.FinanceMoves AS t
USING (SELECT N'fin-3' AS FinanceMoveId) AS s ON t.FinanceMoveId = s.FinanceMoveId
WHEN MATCHED THEN UPDATE SET
    MoveType = N'egreso', Category = N'Materia Prima', Amount = 33700,
    MoveDate = '2026-09-08T09:00:00Z', Note = N'Perfiles de aluminio Alumex', UserName = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
VALUES (N'fin-3', N'egreso', N'Materia Prima', 33700, '2026-09-08T09:00:00Z', N'Perfiles de aluminio Alumex', N'Luis Morales');
MERGE dbo.FinanceMoves AS t
USING (SELECT N'fin-4' AS FinanceMoveId) AS s ON t.FinanceMoveId = s.FinanceMoveId
WHEN MATCHED THEN UPDATE SET
    MoveType = N'egreso', Category = N'Materia Prima', Amount = 47000,
    MoveDate = '2026-09-15T11:00:00Z', Note = N'Cristales templados Vidrios del PacÃ­fico', UserName = N'Luis Morales'
WHEN NOT MATCHED THEN INSERT (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
VALUES (N'fin-4', N'egreso', N'Materia Prima', 47000, '2026-09-15T11:00:00Z', N'Cristales templados Vidrios del PacÃ­fico', N'Luis Morales');
MERGE dbo.FinanceMoves AS t
USING (SELECT N'fin-5' AS FinanceMoveId) AS s ON t.FinanceMoveId = s.FinanceMoveId
WHEN MATCHED THEN UPDATE SET
    MoveType = N'egreso', Category = N'NÃ³mina y Salarios', Amount = 203667.73999999993,
    MoveDate = '2026-10-15T16:00:00Z', Note = N'Costo integral NÃ³mina Quincenal 1Q Octubre', UserName = N'MarÃ­a Elena Cruz'
WHEN NOT MATCHED THEN INSERT (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
VALUES (N'fin-5', N'egreso', N'NÃ³mina y Salarios', 203667.73999999993, '2026-10-15T16:00:00Z', N'Costo integral NÃ³mina Quincenal 1Q Octubre', N'MarÃ­a Elena Cruz');
MERGE dbo.FinanceMoves AS t
USING (SELECT N'fin-6' AS FinanceMoveId) AS s ON t.FinanceMoveId = s.FinanceMoveId
WHEN MATCHED THEN UPDATE SET
    MoveType = N'egreso', Category = N'Servicios BÃ¡sicos', Amount = 4500,
    MoveDate = '2026-10-05T10:00:00Z', Note = N'EnergÃ­a trifÃ¡sica taller DISNORTE-DISSUR', UserName = N'MarÃ­a Elena Cruz'
WHEN NOT MATCHED THEN INSERT (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)
VALUES (N'fin-6', N'egreso', N'Servicios BÃ¡sicos', 4500, '2026-10-05T10:00:00Z', N'EnergÃ­a trifÃ¡sica taller DISNORTE-DISSUR', N'MarÃ­a Elena Cruz');
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 13. RESOLUCIÓN DE LLAVES FORÁNEAS Y COHERENCIA RELACIONAL
-- -----------------------------------------------------------------------------------------
PRINT 'Sincronizando relaciones de llaves foráneas...';
UPDATE s SET ClientPartyId = p.PartyId FROM dbo.Sales s JOIN dbo.Parties p ON s.ClientName = p.Name WHERE p.PartyType = 'cliente';
UPDATE pr SET ClientPartyId = p.PartyId FROM dbo.Proformas pr JOIN dbo.Parties p ON pr.ClientName = p.Name WHERE p.PartyType = 'cliente';
UPDATE pc SET SupplierPartyId = p.PartyId FROM dbo.Purchases pc JOIN dbo.Parties p ON pc.SupplierName = p.Name WHERE p.PartyType = 'proveedor';
UPDATE pj SET ClientPartyId = p.PartyId FROM dbo.Projects pj JOIN dbo.Parties p ON pj.Client = p.Name WHERE p.PartyType = 'cliente';
UPDATE pj SET OwnerEmployeeId = e.EmployeeId FROM dbo.Projects pj JOIN dbo.Employees e ON pj.Owner = e.Name;
UPDATE prun SET AccountingEntryId = 'ast-003', CashMoveId = 'csh-004' FROM dbo.PayrollRuns prun WHERE prun.PayrollRunId = 'pr-2026-10-1';
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

-- -----------------------------------------------------------------------------------------
-- 14. SINCRONIZACIÓN FINAL CON dbo.ErpState MEDIANTE dbo.usp_SaveErpState
-- -----------------------------------------------------------------------------------------
PRINT 'Sincronizando estado integral en dbo.ErpState...';
DECLARE @PayloadJson NVARCHAR(MAX) = N'{"products":[{"id":"p1","code":"ALU-5020","name":"Perfil de aluminio corredizo serie 5020 (6m)","category":"Perfiles","unitPrice":480,"minQuantity":40,"createdAt":"2026-09-01T08:00:00Z","brand":"Alumex / Raquel","measures":"6.00 metros","material":"Aluminio 6063-T5","finish":"Anodizado Natural","use":"VentanerÃ­a corrediza residencial"},{"id":"p2","code":"VID-10T","name":"Vidrio templado de seguridad 10mm (mÂ²)","category":"Vidrios","unitPrice":950,"minQuantity":20,"createdAt":"2026-09-01T08:00:00Z","brand":"Vidrios del PacÃ­fico","measures":"Metro cuadrado a medida","material":"Vidrio templado tÃ©rmico","finish":"Bordes pulidos brillantes","use":"Puertas, canceles y divisiones comerciales"},{"id":"p3","code":"SIL-DC795","name":"SilicÃ³n estructural Dow Corning 795 (Cartucho 310ml)","category":"Accesorios","unitPrice":280,"minQuantity":24,"createdAt":"2026-09-01T08:00:00Z","brand":"Dow Corning","measures":"310 ml","material":"PolÃ­mero de silicona neutra","finish":"Negro estructural","use":"FijaciÃ³n y sellado estanco de muro cortina"},{"id":"p4","code":"HER-PIVOT","name":"Pivote hidrÃ¡ulico de piso para puerta templada","category":"Accesorios","unitPrice":1850,"minQuantity":10,"createdAt":"2026-09-01T08:00:00Z","brand":"Dorma / Raquel","measures":"Caja de piso 30x12 cm","material":"Acero inoxidable y latÃ³n","finish":"Tapa satinada inox 304","use":"Puertas abatibles de alto trÃ¡nsito"},{"id":"p5","code":"ALU-7000","name":"Perfil perimetral batiente serie 7000 (6m)","category":"Perfiles","unitPrice":620,"minQuantity":30,"createdAt":"2026-09-01T08:00:00Z","brand":"Alumex / Raquel","measures":"6.00 metros","material":"Aluminio 6063-T5","finish":"Lacado Blanco ElectrostÃ¡tico","use":"Puertas y ventanas abatibles hermÃ©ticas"},{"id":"p6","code":"VID-6CL","name":"Vidrio flotado claro 6mm (mÂ²)","category":"Vidrios","unitPrice":420,"minQuantity":35,"createdAt":"2026-09-01T08:00:00Z","brand":"Vidrios del PacÃ­fico","measures":"Metro cuadrado","material":"Flotado estÃ¡ndar","finish":"Canto pulido","use":"VentanerÃ­a tradicional y marcos de aluminio"},{"id":"p7","code":"BAR-12T","name":"Vidrio templado 12mm para barandales con perforaciones","category":"Vidrios","unitPrice":1450,"minQuantity":15,"createdAt":"2026-09-01T08:00:00Z","brand":"Vidrios del PacÃ­fico","measures":"Metro cuadrado","material":"Templado alta resistencia","finish":"Cantos rectificados y barrenos","use":"Barandales de balcones y pasamanos"},{"id":"p8","code":"ACC-CARR","name":"Carretilla doble tÃ¡ndem con rodamientos sellados","category":"Accesorios","unitPrice":120,"minQuantity":50,"createdAt":"2026-09-01T08:00:00Z","brand":"Herrajes Industriales","measures":"Par de rodos regulables","material":"Nylon autolubricado y acero inox","finish":"Tropicalizado","use":"Hojas corredizas pesadas hasta 120kg"},{"id":"p9","code":"ALU-MC80","name":"Perfil de columna para muro cortina MC-80 (6m)","category":"Perfiles","unitPrice":1650,"minQuantity":16,"createdAt":"2026-09-01T08:00:00Z","brand":"Alumex / Raquel","measures":"6.00 metros x 80mm","material":"Aluminio estructural 6063-T6","finish":"Anodizado Bronce Oscuro","use":"Estructuras verticales de fachadas de edificios"},{"id":"p10","code":"VID-8REF","name":"Vidrio reflectivo solar 8mm azul solar (mÂ²)","category":"Vidrios","unitPrice":880,"minQuantity":25,"createdAt":"2026-09-01T08:00:00Z","brand":"Vidrios del PacÃ­fico","measures":"Metro cuadrado","material":"Capa pirolÃ­tica reflectiva","finish":"Azul reflectivo / neutro","use":"Control tÃ©rmico y ahorro energÃ©tico en fachadas"},{"id":"p11","code":"HER-MANI","name":"Manija de aluminio embutida con cerradura","category":"Accesorios","unitPrice":240,"minQuantity":30,"createdAt":"2026-09-01T08:00:00Z","brand":"Herrajes Industriales","measures":"Pieza estÃ¡ndar 18cm","material":"Zamak y aluminio inyectado","finish":"Pintura epÃ³xica negra","use":"Cierre seguro de ventanas corredizas"},{"id":"p12","code":"ACC-EPDM","name":"Empaque perimetral de hule EPDM tipo cuÃ±a (Rollo 50m)","category":"Accesorios","unitPrice":450,"minQuantity":10,"createdAt":"2026-09-01T08:00:00Z","brand":"Selladores Industriales","measures":"Rollo de 50 metros","material":"Caucho sintÃ©tico EPDM","finish":"Negro mate","use":"Hermeticidad al agua y viento en canceles"}],"lots":[{"id":"lot-1","productId":"p1","quantity":65,"unitCost":380,"entryDate":"2026-09-01T08:00:00Z","warehouseId":"Bodega Central Carretera Norte"},{"id":"lot-2","productId":"p2","quantity":45,"unitCost":750,"entryDate":"2026-09-05T09:30:00Z","warehouseId":"Taller de Ensamblaje"},{"id":"lot-3","productId":"p3","quantity":80,"unitCost":210,"entryDate":"2026-09-10T11:00:00Z","warehouseId":"Bodega Central Carretera Norte"},{"id":"lot-4","productId":"p4","quantity":18,"unitCost":1450,"entryDate":"2026-09-12T14:00:00Z","warehouseId":"Taller de Ensamblaje"},{"id":"lot-5","productId":"p5","quantity":50,"unitCost":490,"entryDate":"2026-09-15T10:00:00Z","warehouseId":"Bodega Central Carretera Norte"},{"id":"lot-6","productId":"p6","quantity":60,"unitCost":310,"entryDate":"2026-09-18T16:00:00Z","warehouseId":"Bodega Central Carretera Norte"},{"id":"lot-7","productId":"p7","quantity":28,"unitCost":1100,"entryDate":"2026-09-20T08:30:00Z","warehouseId":"Taller de Ensamblaje"},{"id":"lot-8","productId":"p8","quantity":120,"unitCost":85,"entryDate":"2026-09-22T09:00:00Z","warehouseId":"Bodega Central Carretera Norte"},{"id":"lot-9","productId":"p9","quantity":24,"unitCost":1300,"entryDate":"2026-09-25T11:30:00Z","warehouseId":"Taller de Ensamblaje"},{"id":"lot-10","productId":"p10","quantity":40,"unitCost":680,"entryDate":"2026-09-28T13:00:00Z","warehouseId":"Taller de Ensamblaje"}],"kardex":[{"id":"kdx-1","productId":"p1","type":"entrada","quantity":80,"unitCost":380,"date":"2026-09-01T08:00:00Z","reason":"Compra inicial segÃºn Factura F001-4521 de Alumex","userName":"Luis Morales"},{"id":"kdx-2","productId":"p1","type":"salida","quantity":15,"unitCost":380,"date":"2026-09-15T14:00:00Z","reason":"Entrega a taller para Proyecto PRJ-001 Ofiplaza","userName":"Carlos Mendoza"},{"id":"kdx-3","productId":"p2","type":"entrada","quantity":50,"unitCost":750,"date":"2026-09-05T09:30:00Z","reason":"RecepciÃ³n de cristales templados segÃºn Factura F002-8812 de Vidrios del PacÃ­fico","userName":"Luis Morales"},{"id":"kdx-4","productId":"p2","type":"salida","quantity":5,"unitCost":750,"date":"2026-09-22T10:30:00Z","reason":"Salida para ensamble de puerta mÃ³dulo comercial GalerÃ­as","userName":"Carlos Mendoza"},{"id":"kdx-5","productId":"p3","type":"entrada","quantity":100,"unitCost":210,"date":"2026-09-10T11:00:00Z","reason":"Ingreso de silicÃ³n estructural Dow Corning Factura F004-1102","userName":"Luis Morales"},{"id":"kdx-6","productId":"p3","type":"salida","quantity":20,"unitCost":210,"date":"2026-09-26T15:00:00Z","reason":"InstalaciÃ³n de fachada flotante en obra Ofiplaza","userName":"Denis Somarriba"}],"sales":[{"id":"fac-1001","saleNumber":"FACT-2026-00101","clientName":"Grupo HÃ¡bitat S.A.","items":[{"productId":"p9","productName":"Perfil de columna para muro cortina MC-80","quantity":12,"unitPrice":1650},{"productId":"p10","productName":"Vidrio reflectivo solar 8mm azul solar","quantity":20,"unitPrice":880},{"productId":"p3","productName":"SilicÃ³n estructural Dow Corning 795","quantity":24,"unitPrice":280}],"subtotal":44120,"discountAmount":2206,"taxAmount":6287.1,"total":48201.1,"status":"completed","saleDate":"2026-09-18T10:00:00Z","createdBy":"Ana Silva","qrPayload":"DGI-NIC|FACT-2026-00101|J0310000000019|J0310000607080|44120.00|6287.10|48201.10|2026-09-18"},{"id":"fac-1002","saleNumber":"FACT-2026-00102","clientName":"Plaza Comercial Sur S.A.","items":[{"productId":"p2","productName":"Vidrio templado de seguridad 10mm","quantity":14,"unitPrice":950},{"productId":"p4","productName":"Pivote hidrÃ¡ulico de piso para puerta templada","quantity":2,"unitPrice":1850},{"productId":"p11","productName":"Manija de aluminio embutida","quantity":4,"unitPrice":240}],"subtotal":17960,"discountAmount":0,"taxAmount":2694,"total":20654,"status":"completed","saleDate":"2026-09-24T14:30:00Z","createdBy":"Ana Silva","qrPayload":"DGI-NIC|FACT-2026-00102|J0310000000019|J0310001112130|17960.00|2694.00|20654.00|2026-09-24"},{"id":"fac-1003","saleNumber":"FACT-2026-00103","clientName":"Desarrollos Inmobiliarios Las Colinas S.A.","items":[{"productId":"p1","productName":"Perfil de aluminio corredizo serie 5020","quantity":25,"unitPrice":480},{"productId":"p6","productName":"Vidrio flotado claro 6mm","quantity":30,"unitPrice":420},{"productId":"p8","productName":"Carretilla doble tÃ¡ndem con rodamientos sellados","quantity":40,"unitPrice":120}],"subtotal":29400,"discountAmount":2352,"taxAmount":4057.2,"total":31105.2,"status":"completed","saleDate":"2026-10-02T11:15:00Z","createdBy":"Ana Silva","qrPayload":"DGI-NIC|FACT-2026-00103|J0310000000019|J0310001011120|27048.00|4057.20|31105.20|2026-10-02"}],"proformas":[{"id":"prof-1","proformaNumber":"PROF-2026-00045","clientName":"Torre Azul Condominios S.A.","items":[{"productId":"p7","productName":"Vidrio templado 12mm para barandales","quantity":32,"unitPrice":1450},{"productId":"p3","productName":"SilicÃ³n estructural Dow Corning 795","quantity":18,"unitPrice":280}],"subtotal":51440,"discountAmount":5144,"taxAmount":6944.4,"total":53240.4,"status":"enviada","validUntil":"2026-11-15T23:59:59Z","notes":"CotizaciÃ³n incluye instalaciÃ³n con arneses de seguridad en altura y garantÃ­a de 3 aÃ±os.","createdAt":"2026-10-10T09:00:00Z","createdBy":"Ana Silva","qrPayload":"DGI-NIC|PROF-2026-00045|J0310000000019|J0310000708090|46296.00|6944.40|53240.40|2026-10-10"},{"id":"prof-2","proformaNumber":"PROF-2026-00046","clientName":"Constructora MÃ¡ntica S.A.","items":[{"productId":"p5","productName":"Perfil perimetral batiente serie 7000","quantity":18,"unitPrice":620},{"productId":"p6","productName":"Vidrio flotado claro 6mm","quantity":20,"unitPrice":420}],"subtotal":19560,"discountAmount":978,"taxAmount":2787.3,"total":21369.3,"status":"borrador","validUntil":"2026-11-20T23:59:59Z","notes":"CancelerÃ­a interior para oficinas administrativas.","createdAt":"2026-10-14T15:00:00Z","createdBy":"Ana Silva","qrPayload":"DGI-NIC|PROF-2026-00046|J0310000000019|J0310000809100|18582.00|2787.30|21369.30|2026-10-14"}],"promotions":[{"id":"promo1","title":"Combo Hogar 8%","blurb":"LlevÃ¡ perfiles y canceles de baÃ±o con descuento desde C$ 3,000.","minSubtotal":3000,"percentOff":8,"active":true,"badge":"-8%"},{"id":"promo2","title":"RenovaciÃ³n Comercial 12%","blurb":"Obras comerciales, vitrinas y cancelerÃ­a integral desde C$ 10,000.","minSubtotal":10000,"percentOff":12,"active":true,"badge":"-12%"},{"id":"promo3","title":"Mega Pack Fachadas 15%","blurb":"Proyectos verticales con vidrio reflectivo o muro cortina desde C$ 20,000.","minSubtotal":20000,"percentOff":15,"active":true,"badge":"-15%"},{"id":"promo4","title":"Descuento de Apertura 5%","blurb":"Descuento de bienvenida a nuevos clientes corporativos desde C$ 1,500.","minSubtotal":1500,"percentOff":5,"active":true,"badge":"-5%"}],"purchases":[{"id":"cmp-2026-01","purchaseNumber":"OC-2026-00081","supplierName":"Alumex de Nicaragua S.A.","supplierId":"pv1","items":[{"productId":"p1","productName":"Perfil de aluminio serie 5020","quantity":50,"unitPrice":380},{"productId":"p5","productName":"Perfil batiente serie 7000","quantity":30,"unitPrice":490}],"total":33700,"status":"received","purchaseDate":"2026-09-08T09:00:00Z","createdBy":"Luis Morales"},{"id":"cmp-2026-02","purchaseNumber":"OC-2026-00082","supplierName":"Vidrios del PacÃ­fico S.A.","supplierId":"pv2","items":[{"productId":"p2","productName":"Vidrio templado 10mm","quantity":40,"unitPrice":750},{"productId":"p10","productName":"Vidrio reflectivo 8mm","quantity":25,"unitPrice":680}],"total":47000,"status":"received","purchaseDate":"2026-09-15T11:00:00Z","createdBy":"Luis Morales"},{"id":"cmp-2026-03","purchaseNumber":"OC-2026-00083","supplierName":"Selladores y QuÃ­micos Estructurales S.A.","supplierId":"pv4","items":[{"productId":"p3","productName":"SilicÃ³n estructural Dow Corning 795","quantity":60,"unitPrice":210}],"total":12600,"status":"received","purchaseDate":"2026-09-22T14:00:00Z","createdBy":"Luis Morales"}],"accounting":[{"id":"ast-001","entryNumber":"AST-2026-0001","description":"FacturaciÃ³n Proyecto PRJ-001 Ofiplaza Fachada Flotante (Factura FACT-2026-00101)","debit":48201.1,"credit":48201.1,"debitAccount":"1103 Cuentas por Cobrar Clientes","creditAccount":"4101 Ingresos por Obras de CancelerÃ­a y Vidrio","entryDate":"2026-09-18T10:00:00Z","referenceType":"sale","referenceId":"fac-1001"},{"id":"ast-002","entryNumber":"AST-2026-0002","description":"Compra de perfiles de aluminio a Alumex de Nicaragua (Orden OC-2026-00081)","debit":38755,"credit":38755,"debitAccount":"1105 Inventario Materia Prima e IVA Acreditable","creditAccount":"2101 Cuentas por Pagar Proveedores y RetenciÃ³n DGI","entryDate":"2026-09-08T09:00:00Z","referenceType":"purchase","referenceId":"cmp-2026-01"},{"id":"ast-003","entryNumber":"AST-2026-0003","description":"Registro contable devengado NÃ³mina Quincenal 2026-10-1Q (14 trabajadores)","debit":203667.73999999993,"credit":203667.73999999993,"debitAccount":"5101 Gastos de Sueldos y Cargas Sociales","creditAccount":"2105 Sueldos, Retenciones y Aportes Patronales por Pagar","entryDate":"2026-10-15T15:00:00Z","referenceType":"payroll","referenceId":"pr-2026-10-1"},{"id":"ast-004","entryNumber":"AST-2026-0004","description":"Pago de NÃ³mina Quincenal 2026-10-1Q mediante transferencia bancaria BANPRO","debit":115802.54000000001,"credit":115802.54000000001,"debitAccount":"2105 Sueldos por Pagar","creditAccount":"1102 Banco de la ProducciÃ³n (BANPRO) Cuenta Corriente C$","entryDate":"2026-10-15T16:00:00Z","referenceType":"payroll","referenceId":"pr-2026-10-1"},{"id":"ast-005","entryNumber":"AST-2026-0005","description":"Cobro transferencia bancaria BAC Credomatic de Factura Plaza Sur","debit":20654,"credit":20654,"debitAccount":"1101 Banco BAC Credomatic Cuenta C$","creditAccount":"1103 Cuentas por Cobrar Clientes","entryDate":"2026-09-25T11:00:00Z","referenceType":"cash","referenceId":"csh-002"}],"finance":[{"id":"fin-1","type":"ingreso","category":"Obras y Proyectos","amount":48201.1,"date":"2026-09-18T10:00:00Z","note":"Factura Ofiplaza Piso 4","userName":"MarÃ­a Elena Cruz"},{"id":"fin-2","type":"ingreso","category":"Venta Comercial","amount":20654,"date":"2026-09-24T14:30:00Z","note":"Frente de tienda Plaza Sur","userName":"MarÃ­a Elena Cruz"},{"id":"fin-3","type":"egreso","category":"Materia Prima","amount":33700,"date":"2026-09-08T09:00:00Z","note":"Perfiles de aluminio Alumex","userName":"Luis Morales"},{"id":"fin-4","type":"egreso","category":"Materia Prima","amount":47000,"date":"2026-09-15T11:00:00Z","note":"Cristales templados Vidrios del PacÃ­fico","userName":"Luis Morales"},{"id":"fin-5","type":"egreso","category":"NÃ³mina y Salarios","amount":203667.73999999993,"date":"2026-10-15T16:00:00Z","note":"Costo integral NÃ³mina Quincenal 1Q Octubre","userName":"MarÃ­a Elena Cruz"},{"id":"fin-6","type":"egreso","category":"Servicios BÃ¡sicos","amount":4500,"date":"2026-10-05T10:00:00Z","note":"EnergÃ­a trifÃ¡sica taller DISNORTE-DISSUR","userName":"MarÃ­a Elena Cruz"}],"projections":[{"id":"prj-m1","month":"2026-08","expectedSales":160000,"expectedCosts":95000},{"id":"prj-m2","month":"2026-09","expectedSales":195000,"expectedCosts":110000},{"id":"prj-m3","month":"2026-10","expectedSales":240000,"expectedCosts":135000},{"id":"prj-m4","month":"2026-11","expectedSales":280000,"expectedCosts":155000},{"id":"prj-m5","month":"2026-12","expectedSales":320000,"expectedCosts":180000}],"production":[{"id":"ord-1","code":"OP-2026-001","product":"Muro Cortina MC-80 con Vidrio Reflectivo 8mm","client":"Grupo HÃ¡bitat S.A.","qty":14,"stage":"instalacion","sprint":"Sprint 18","owner":"Denis Somarriba"},{"id":"ord-2","code":"OP-2026-002","product":"Ventanas Serie 5020 con Mosquiteros","client":"Desarrollos Inmobiliarios Las Colinas","qty":22,"stage":"ensamble","sprint":"Sprint 18","owner":"Wilmer JarquÃ­n"},{"id":"ord-3","code":"OP-2026-003","product":"Puerta Batiente Templada 10mm con Pivote Dorma","client":"Plaza Comercial Sur","qty":2,"stage":"entregado","sprint":"Sprint 17","owner":"Roberto ToruÃ±o"},{"id":"ord-4","code":"OP-2026-004","product":"Canceles Hospitalarios Sellados 6mm","client":"ClÃ­nica del Lago S.A.","qty":8,"stage":"corte","sprint":"Sprint 19","owner":"Marlon Calero"},{"id":"ord-5","code":"OP-2026-005","product":"Barandales de Acero Inox con Vidrio 12mm","client":"Torre Azul Condominios","qty":16,"stage":"backlog","sprint":"Sprint 19","owner":"Francisco Valle"}],"parties":[{"id":"cl1","name":"Grupo HÃ¡bitat S.A.","contact":"Ing. Rosa MÃ©ndez","phone":"8888-1100","email":"proyectos@grupohabitat.com.ni","type":"cliente","status":"activo","ruc":"J0310000607080","address":"Pista Jean Paul Genie, Edificio Prisma Piso 3, Managua","paymentTerms":"CrÃ©dito 30 dÃ­as","observations":"Cliente corporativo de fachadas flotantes y ventanerÃ­a comercial."},{"id":"cl2","name":"Torre Azul Condominios S.A.","contact":"Lic. IvÃ¡n SolÃ­s","phone":"8777-2211","email":"administracion@torreazul.com.ni","type":"cliente","status":"activo","ruc":"J0310000708090","address":"Villa Fontana, de los semÃ¡foros del Club Terraza 300m al Sur, Managua","paymentTerms":"Anticipo 50% y saldo contra entrega","observations":"Desarrollo vertical de apartamentos, barandales y muros cortina."},{"id":"cl3","name":"Constructora MÃ¡ntica S.A.","contact":"Ing. Elena Cruz","phone":"8555-3344","email":"compras@constructoramantica.com.ni","type":"cliente","status":"activo","ruc":"J0310000809100","address":"Carretera a Masaya Km 8.5, Managua","paymentTerms":"CrÃ©dito 45 dÃ­as contra avalÃºo","observations":"Constructora general de centros comerciales y clÃ­nicas mÃ©dicas."},{"id":"cl4","name":"Plaza Comercial Sur S.A.","contact":"Lic. Mario PeÃ±a","phone":"8666-7788","email":"gerencia@plazasur.com.ni","type":"cliente","status":"activo","ruc":"J0310001112130","address":"Carretera Sur Km 10.2, Managua","paymentTerms":"Contado contra entrega","observations":"MÃ³dulos comerciales, puertas de vidrio templado y canceles automÃ¡ticos."},{"id":"cl5","name":"Desarrollos Inmobiliarios Las Colinas S.A.","contact":"Arq. Patricia GÃ³mez","phone":"8444-9900","email":"arquitectura@lascolinas.com.ni","type":"cliente","status":"activo","ruc":"J0310001011120","address":"Reparto Las Colinas, Avenida Principal, Managua","paymentTerms":"CrÃ©dito 30 dÃ­as","observations":"Residencias de lujo, ventanas europeas acÃºsticas y mamparas de baÃ±o."},{"id":"cl6","name":"ClÃ­nica del Lago S.A.","contact":"Dr. Roberto Rivas","phone":"8222-1010","email":"direccion@clinicalago.com.ni","type":"cliente","status":"activo","ruc":"J0310000910110","address":"Bolonia, de la Ã“ptica NicaragÃ¼ense 2c al Norte, Managua","paymentTerms":"Contado 100%","observations":"Divisiones de quirÃ³fano con perfiles sellados y vidrio laminado antibacterial."},{"id":"pv1","name":"Alumex de Nicaragua S.A.","contact":"Lic. Karla Ruiz","phone":"2222-4400","email":"ventas@alumex.com.ni","type":"proveedor","status":"activo","category":"materiales","ruc":"J0310000102030","address":"Carretera Norte Km 6.5, Complejo Industrial, Managua","productsServices":"Perfiles de aluminio arquitectÃ³nico serie 5020, 7000, 8025 y lÃ­nea europea","paymentTerms":"CrÃ©dito 30 dÃ­as","observations":"Proveedor principal de extrusiones de aluminio anodizado y lacado blanco."},{"id":"pv2","name":"Vidrios del PacÃ­fico S.A.","contact":"Ing. Fernando Morales","phone":"2255-9090","email":"pedidos@vidriospacifico.com.ni","type":"proveedor","status":"activo","category":"materiales","ruc":"J0310000203040","address":"Carretera a Masaya Km 12.5, Ticuantepe","productsServices":"Vidrio flotado, templado 6mm a 12mm, laminado de seguridad y reflectivo","paymentTerms":"CrÃ©dito 15 dÃ­as","observations":"Planta de procesamiento de vidrio con templado horizontal homologado ASTM."},{"id":"pv3","name":"FerreterÃ­a y Herrajes Industriales S.A.","contact":"Don JosÃ© Duarte","phone":"2277-3311","email":"ventas@ferreteriaindustrial.com.ni","type":"proveedor","status":"activo","category":"materiales","ruc":"J0310000304050","address":"Ciudad JardÃ­n, de la gasolinera Puma 1c al Sur, Managua","productsServices":"Cerraduras multipunto, carretillas dobles de acero, pivotes hidrÃ¡ulicos Dorma","paymentTerms":"Contado contra entrega","observations":"Herrajes de alta durabilidad para puertas de vidrio templado y ventanas corredizas."},{"id":"pv4","name":"Selladores y QuÃ­micos Estructurales S.A.","contact":"Ing. Claudia Espinoza","phone":"2288-5522","email":"pedidos@selladores.com.ni","type":"proveedor","status":"activo","category":"materiales","ruc":"J0310000405060","address":"Pista Suburbana, Edificio Discover MÃ³dulo 2, Managua","productsServices":"SilicÃ³n estructural Dow Corning 795, selladores neutros y cintas VHB 3M","paymentTerms":"CrÃ©dito 30 dÃ­as","observations":"Distribuidor exclusivo de silicones de curado neutro para muros cortina."}],"employees":[{"id":"emp-01","name":"Carlos Mendoza","position":"Ingeniero de Proyectos y ProducciÃ³n","salary":28500,"area":"produccion"},{"id":"emp-02","name":"Jhonny Garcia","position":"Administrador de Operaciones y Ventas","salary":25000,"area":"administracion"},{"id":"emp-03","name":"Francisco Valle","position":"Maestro Aluminero y Supervisor","salary":19500,"area":"produccion"},{"id":"emp-04","name":"Roberto ToruÃ±o","position":"Operario de Corte y Troquelado","salary":14500,"area":"produccion"},{"id":"emp-05","name":"Marlon Calero","position":"Operario Especialista en Vidrio","salary":15200,"area":"produccion"},{"id":"emp-06","name":"Wilmer JarquÃ­n","position":"Armador de VentanerÃ­a y Fachadas","salary":13800,"area":"produccion"},{"id":"emp-07","name":"Denis Somarriba","position":"Instalador LÃ­der de Altura","salary":16500,"area":"produccion"},{"id":"emp-08","name":"JosÃ© BlandÃ³n","position":"Auxiliar de InstalaciÃ³n en Obra","salary":11500,"area":"produccion"},{"id":"emp-09","name":"Kevin Rivas","position":"Auxiliar de Taller y Mantenimiento","salary":10800,"area":"produccion"},{"id":"emp-10","name":"Ana Silva","position":"Ejecutiva de Ventas TÃ©cnicas","salary":18000,"area":"ventas"},{"id":"emp-11","name":"MarÃ­a Elena Cruz","position":"Contadora General","salary":26000,"area":"contabilidad"},{"id":"emp-12","name":"Luis Morales","position":"Encargado de Compras y Bodega","salary":17000,"area":"compras"},{"id":"emp-13","name":"Patricia Mayorga","position":"Asistente Administrativa y RRHH","salary":14000,"area":"rrhh"},{"id":"emp-14","name":"Raquel LÃ³pez","position":"Gerente General y Propietaria","salary":38000,"area":"direccion"}],"payrollRuns":[{"id":"pr-2026-10-1","period":"2026-10-1Q","paidAt":"2026-10-15T16:00:00Z","actor":"MarÃ­a Elena Cruz","gross":137150,"inssLaboral":9600.5,"inssPatronal":29487.260000000002,"inatec":2743,"ir":11746.960000000001,"net":115802.54000000001,"employerCost":203667.73999999993,"employees":[{"employeeId":"emp-01","position":"Ingeniero de Proyectos y ProducciÃ³n","area":"produccion","baseSalary":28500,"ordinary":14250,"otHours":0,"otAmount":0,"gross":14250,"inssLaboral":997.5,"ir":1608.83,"net":11643.67,"inssPatronal":3063.75,"inatec":285,"aguinaldo":1187.5,"vacacionesProv":1187.5,"indemnizacionProv":1187.5,"employerCost":21161.25},{"employeeId":"emp-02","position":"Administrador de Operaciones y Ventas","area":"administracion","baseSalary":25000,"ordinary":12500,"otHours":0,"otAmount":0,"gross":12500,"inssLaboral":875,"ir":1283.33,"net":10341.67,"inssPatronal":2687.5,"inatec":250,"aguinaldo":1041.67,"vacacionesProv":1041.67,"indemnizacionProv":1041.67,"employerCost":18562.51},{"employeeId":"emp-03","position":"Maestro Aluminero y Supervisor","area":"produccion","baseSalary":19500,"ordinary":9750,"otHours":10,"otAmount":1625,"gross":11375,"inssLaboral":796.25,"ir":1074.08,"net":9504.67,"inssPatronal":2445.63,"inatec":227.5,"aguinaldo":947.92,"vacacionesProv":947.92,"indemnizacionProv":947.92,"employerCost":16891.89},{"employeeId":"emp-04","position":"Operario de Corte y Troquelado","area":"produccion","baseSalary":14500,"ordinary":7250,"otHours":0,"otAmount":0,"gross":7250,"inssLaboral":507.5,"ir":386.38,"net":6356.12,"inssPatronal":1558.75,"inatec":145,"aguinaldo":604.17,"vacacionesProv":604.17,"indemnizacionProv":604.17,"employerCost":10766.26},{"employeeId":"emp-05","position":"Operario Especialista en Vidrio","area":"produccion","baseSalary":15200,"ordinary":7600,"otHours":0,"otAmount":0,"gross":7600,"inssLaboral":532,"ir":435.2,"net":6632.8,"inssPatronal":1634,"inatec":152,"aguinaldo":633.33,"vacacionesProv":633.33,"indemnizacionProv":633.33,"employerCost":11285.99},{"employeeId":"emp-06","position":"Armador de VentanerÃ­a y Fachadas","area":"produccion","baseSalary":13800,"ordinary":6900,"otHours":0,"otAmount":0,"gross":6900,"inssLaboral":483,"ir":337.55,"net":6079.45,"inssPatronal":1483.5,"inatec":138,"aguinaldo":575,"vacacionesProv":575,"indemnizacionProv":575,"employerCost":10246.5},{"employeeId":"emp-07","position":"Instalador LÃ­der de Altura","area":"produccion","baseSalary":16500,"ordinary":8250,"otHours":10,"otAmount":1375,"gross":9625,"inssLaboral":673.75,"ir":748.58,"net":8202.67,"inssPatronal":2069.38,"inatec":192.5,"aguinaldo":802.08,"vacacionesProv":802.08,"indemnizacionProv":802.08,"employerCost":14293.12},{"employeeId":"emp-08","position":"Auxiliar de InstalaciÃ³n en Obra","area":"produccion","baseSalary":11500,"ordinary":5750,"otHours":0,"otAmount":0,"gross":5750,"inssLaboral":402.5,"ir":177.13,"net":5170.37,"inssPatronal":1236.25,"inatec":115,"aguinaldo":479.17,"vacacionesProv":479.17,"indemnizacionProv":479.17,"employerCost":8538.76},{"employeeId":"emp-09","position":"Auxiliar de Taller y Mantenimiento","area":"produccion","baseSalary":10800,"ordinary":5400,"otHours":0,"otAmount":0,"gross":5400,"inssLaboral":378,"ir":128.3,"net":4893.7,"inssPatronal":1161,"inatec":108,"aguinaldo":450,"vacacionesProv":450,"indemnizacionProv":450,"employerCost":8019},{"employeeId":"emp-10","position":"Ejecutiva de Ventas TÃ©cnicas","area":"ventas","baseSalary":18000,"ordinary":9000,"otHours":0,"otAmount":0,"gross":9000,"inssLaboral":630,"ir":632.33,"net":7737.67,"inssPatronal":1935,"inatec":180,"aguinaldo":750,"vacacionesProv":750,"indemnizacionProv":750,"employerCost":13365},{"employeeId":"emp-11","position":"Contadora General","area":"contabilidad","baseSalary":26000,"ordinary":13000,"otHours":0,"otAmount":0,"gross":13000,"inssLaboral":910,"ir":1376.33,"net":10713.67,"inssPatronal":2795,"inatec":260,"aguinaldo":1083.33,"vacacionesProv":1083.33,"indemnizacionProv":1083.33,"employerCost":19304.99},{"employeeId":"emp-12","position":"Encargado de Compras y Bodega","area":"compras","baseSalary":17000,"ordinary":8500,"otHours":0,"otAmount":0,"gross":8500,"inssLaboral":595,"ir":560.75,"net":7344.25,"inssPatronal":1827.5,"inatec":170,"aguinaldo":708.33,"vacacionesProv":708.33,"indemnizacionProv":708.33,"employerCost":12622.49},{"employeeId":"emp-13","position":"Asistente Administrativa y RRHH","area":"rrhh","baseSalary":14000,"ordinary":7000,"otHours":0,"otAmount":0,"gross":7000,"inssLaboral":490,"ir":351.5,"net":6158.5,"inssPatronal":1505,"inatec":140,"aguinaldo":583.33,"vacacionesProv":583.33,"indemnizacionProv":583.33,"employerCost":10394.99},{"employeeId":"emp-14","position":"Gerente General y Propietaria","area":"direccion","baseSalary":38000,"ordinary":19000,"otHours":0,"otAmount":0,"gross":19000,"inssLaboral":1330,"ir":2646.67,"net":15023.33,"inssPatronal":4085,"inatec":380,"aguinaldo":1583.33,"vacacionesProv":1583.33,"indemnizacionProv":1583.33,"employerCost":28214.99}]}],"albums":[{"id":"alb-1","month":"2026-10","title":"CatÃ¡logo Fachadas y VentanerÃ­a ArquitectÃ³nica 2026","blurb":"Sistemas europeos hermÃ©ticos, muro cortina y barandales de vidrio templado para proyectos residenciales y corporativos.","productIds":["p1","p2","p5","p7","p9","p10"],"published":true,"createdAt":"2026-10-01T08:00:00Z"},{"id":"alb-2","month":"2026-09","title":"LÃ­nea BaÃ±os y Canceles Templados","blurb":"Puertas corredizas y abatibles con herrajes de acero inoxidable satinado y empaques magnÃ©ticos estancos.","productIds":["p2","p4","p8","p11"],"published":true,"createdAt":"2026-09-01T08:00:00Z"}],"projects":[{"id":"prj-1","code":"PRJ-001","name":"Fachada Flotante Edificio Ofiplaza Piso 4","client":"Grupo HÃ¡bitat S.A.","amount":185000,"progress":85,"state":"InstalaciÃ³n","owner":"Carlos Mendoza"},{"id":"prj-2","code":"PRJ-002","name":"VentanerÃ­a LÃ­nea Europea Residencial Las Colinas","client":"Desarrollos Inmobiliarios Las Colinas S.A.","amount":98000,"progress":60,"state":"FabricaciÃ³n","owner":"Francisco Valle"},{"id":"prj-3","code":"PRJ-003","name":"Frente de Tienda Vidrio Templado 12mm Plaza Sur","client":"Plaza Comercial Sur S.A.","amount":45000,"progress":100,"state":"Liquidada","owner":"Carlos Mendoza"},{"id":"prj-4","code":"PRJ-004","name":"Divisiones Hospitalarias ClÃ­nicas del Lago","client":"ClÃ­nica del Lago S.A.","amount":72000,"progress":35,"state":"FabricaciÃ³n","owner":"Carlos Mendoza"},{"id":"prj-5","code":"PRJ-005","name":"Barandales Inoxidables Torre Azul Piso 8 al 12","client":"Torre Azul Condominios S.A.","amount":140000,"progress":15,"state":"Pendiente","owner":"Francisco Valle"}],"cash":[{"id":"csh-001","account":"banco","type":"entrada","amount":25000,"date":"2026-09-18T14:00:00Z","concept":"Anticipo 50% segÃºn contrato Proyecto Ofiplaza Grupo HÃ¡bitat"},{"id":"csh-002","account":"banco","type":"entrada","amount":20654,"date":"2026-09-25T11:00:00Z","concept":"Cobro total de factura FACT-2026-00102 Plaza Sur"},{"id":"csh-003","account":"banco","type":"salida","amount":15000,"date":"2026-09-20T10:00:00Z","concept":"Abono a proveedor Alumex de Nicaragua transferencia BANPRO"},{"id":"csh-004","account":"banco","type":"salida","amount":115802.54,"date":"2026-10-15T16:00:00Z","concept":"DispersiÃ³n electrÃ³nica de salarios NÃ³mina 2026-10-1Q"},{"id":"csh-005","account":"caja","type":"entrada","amount":8500,"date":"2026-10-05T09:00:00Z","concept":"Venta de mostrador y retal de perfiles aluminio taller"},{"id":"csh-006","account":"caja","type":"salida","amount":1250,"date":"2026-10-08T15:30:00Z","concept":"Gastos menores de taller: brocas para aluminio y lija de agua"}],"users":[{"id":"u-super","name":"Raquel LÃ³pez","email":"admin@raquel.com","hierarchy":"superadmin","areas":["gobierno","produccion","finanzas","contabilidad","mercadotecnia","compras","ventas","rrhh","proyectos"],"active":true},{"id":"u-d526347b40b34400a16d30d83990e3c1","name":"Jhonny Garcia","email":"admin@jhonnyarea.com","hierarchy":"administrador","areas":["compras","contabilidad","finanzas","inventario","mercadotecnia","produccion","proyectos","rrhh","ventas"],"active":true},{"id":"u-prod","name":"Carlos Mendoza","email":"produccion@raquel.com","hierarchy":"administrador","areas":["produccion","inventario","proyectos"],"active":true},{"id":"u-fin","name":"MarÃ­a Elena Cruz","email":"contador@raquel.com","hierarchy":"administrador","areas":["finanzas","contabilidad","rrhh"],"active":true},{"id":"u-sales","name":"Ana Silva","email":"vendedor@raquel.com","hierarchy":"estandar","areas":["ventas","mercadotecnia"],"active":true},{"id":"u-buy","name":"Luis Morales","email":"compras@raquel.com","hierarchy":"estandar","areas":["compras","inventario"],"active":true},{"id":"u-guest","name":"Invitado Gerencia","email":"invitado@raquel.com","hierarchy":"invitado","areas":["finanzas","proyectos","mercadotecnia"],"active":true}],"audit":[{"id":"aud-01","at":"2026-09-01T08:00:00Z","userName":"Raquel LÃ³pez","action":"creacion","module":"gobierno","detail":"Inicio de ciclo fiscal y validaciÃ³n de reglas normativas DGI e INSS.","severity":"info"},{"id":"aud-02","at":"2026-09-18T10:05:00Z","userName":"Ana Silva","action":"facturacion","module":"ventas","detail":"EmisiÃ³n de Factura FACT-2026-00101 con retenciones DGI 2% y ALMA 1% a Grupo HÃ¡bitat.","severity":"info"},{"id":"aud-03","at":"2026-09-22T14:10:00Z","userName":"Luis Morales","action":"recepcion","module":"compras","detail":"RecepciÃ³n conforme de 60 cartuchos de silicÃ³n estructural Dow Corning 795.","severity":"info"},{"id":"aud-04","at":"2026-10-15T15:05:00Z","userName":"MarÃ­a Elena Cruz","action":"calculo_nomina","module":"nomina","detail":"CÃ¡lculo de NÃ³mina 2026-10-1Q para 14 colaboradores con INSS Laboral C$ 9600.50 e IR C$ 11746.96.","severity":"info"},{"id":"aud-05","at":"2026-10-15T15:30:00Z","userName":"Jhonny Garcia","action":"aprobacion_nomina","module":"nomina","detail":"AprobaciÃ³n y autorizaciÃ³n de pago de salarios por transferencia bancaria.","severity":"info"},{"id":"aud-06","at":"2026-10-15T16:00:00Z","userName":"MarÃ­a Elena Cruz","action":"dispersion_bancaria","module":"bancos","detail":"Transferencia masiva BANPRO ejecutada por C$ 115802.54. Asiento AST-2026-0004 generado.","severity":"info"}]}';
EXEC dbo.usp_SaveErpState @Payload = @PayloadJson;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

PRINT '=========================================================================================';
PRINT 'CARGA INTEGRAL COMPLETADA CON ÉXITO AL 100%';
PRINT 'Todos los módulos están relacionados coherentemente con las leyes de Nicaragua.';
PRINT '=========================================================================================';
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

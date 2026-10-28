import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import crypto from "node:crypto";
import dotenv from "dotenv";
import sql from "mssql";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");

console.log("============================================================================");
console.log("CARGA INTEGRAL Y COHERENTE DE DATOS DEL SISTEMA · INSTALACIONES RAQUEL");
console.log("Normativa: DGI Ley 822 (LCT), MITRAB Código del Trabajo, INSS e INATEC");
console.log("============================================================================");

async function main() {
  const pool = await getDatabase();
  if (!pool) {
    console.error("Error crítico: No se pudo conectar a SQL Server [Instalaciones Raquel].");
    process.exit(1);
  }

  console.log("✓ Conectado exitosamente a SQL Server: [Instalaciones Raquel]");

  // 1. TERCEROS (CLIENTES Y PROVEEDORES CON RUC DGI Y DIRECCIONES EN NICARAGUA)
  const parties = [
    {
      id: "cl1",
      name: "Grupo Hábitat S.A.",
      contact: "Ing. Rosa Méndez",
      phone: "8888-1100",
      email: "proyectos@grupohabitat.com.ni",
      type: "cliente",
      status: "activo",
      ruc: "J0310000607080",
      address: "Pista Jean Paul Genie, Edificio Prisma Piso 3, Managua",
      paymentTerms: "Crédito 30 días",
      observations: "Cliente corporativo de fachadas flotantes y ventanería comercial."
    },
    {
      id: "cl2",
      name: "Torre Azul Condominios S.A.",
      contact: "Lic. Iván Solís",
      phone: "8777-2211",
      email: "administracion@torreazul.com.ni",
      type: "cliente",
      status: "activo",
      ruc: "J0310000708090",
      address: "Villa Fontana, de los semáforos del Club Terraza 300m al Sur, Managua",
      paymentTerms: "Anticipo 50% y saldo contra entrega",
      observations: "Desarrollo vertical de apartamentos, barandales y muros cortina."
    },
    {
      id: "cl3",
      name: "Constructora Mántica S.A.",
      contact: "Ing. Elena Cruz",
      phone: "8555-3344",
      email: "compras@constructoramantica.com.ni",
      type: "cliente",
      status: "activo",
      ruc: "J0310000809100",
      address: "Carretera a Masaya Km 8.5, Managua",
      paymentTerms: "Crédito 45 días contra avalúo",
      observations: "Constructora general de centros comerciales y clínicas médicas."
    },
    {
      id: "cl4",
      name: "Plaza Comercial Sur S.A.",
      contact: "Lic. Mario Peña",
      phone: "8666-7788",
      email: "gerencia@plazasur.com.ni",
      type: "cliente",
      status: "activo",
      ruc: "J0310001112130",
      address: "Carretera Sur Km 10.2, Managua",
      paymentTerms: "Contado contra entrega",
      observations: "Módulos comerciales, puertas de vidrio templado y canceles automáticos."
    },
    {
      id: "cl5",
      name: "Desarrollos Inmobiliarios Las Colinas S.A.",
      contact: "Arq. Patricia Gómez",
      phone: "8444-9900",
      email: "arquitectura@lascolinas.com.ni",
      type: "cliente",
      status: "activo",
      ruc: "J0310001011120",
      address: "Reparto Las Colinas, Avenida Principal, Managua",
      paymentTerms: "Crédito 30 días",
      observations: "Residencias de lujo, ventanas europeas acústicas y mamparas de baño."
    },
    {
      id: "cl6",
      name: "Clínica del Lago S.A.",
      contact: "Dr. Roberto Rivas",
      phone: "8222-1010",
      email: "direccion@clinicalago.com.ni",
      type: "cliente",
      status: "activo",
      ruc: "J0310000910110",
      address: "Bolonia, de la Óptica Nicaragüense 2c al Norte, Managua",
      paymentTerms: "Contado 100%",
      observations: "Divisiones de quirófano con perfiles sellados y vidrio laminado antibacterial."
    },
    {
      id: "pv1",
      name: "Alumex de Nicaragua S.A.",
      contact: "Lic. Karla Ruiz",
      phone: "2222-4400",
      email: "ventas@alumex.com.ni",
      type: "proveedor",
      status: "activo",
      category: "materiales",
      ruc: "J0310000102030",
      address: "Carretera Norte Km 6.5, Complejo Industrial, Managua",
      productsServices: "Perfiles de aluminio arquitectónico serie 5020, 7000, 8025 y línea europea",
      paymentTerms: "Crédito 30 días",
      observations: "Proveedor principal de extrusiones de aluminio anodizado y lacado blanco."
    },
    {
      id: "pv2",
      name: "Vidrios del Pacífico S.A.",
      contact: "Ing. Fernando Morales",
      phone: "2255-9090",
      email: "pedidos@vidriospacifico.com.ni",
      type: "proveedor",
      status: "activo",
      category: "materiales",
      ruc: "J0310000203040",
      address: "Carretera a Masaya Km 12.5, Ticuantepe",
      productsServices: "Vidrio flotado, templado 6mm a 12mm, laminado de seguridad y reflectivo",
      paymentTerms: "Crédito 15 días",
      observations: "Planta de procesamiento de vidrio con templado horizontal homologado ASTM."
    },
    {
      id: "pv3",
      name: "Ferretería y Herrajes Industriales S.A.",
      contact: "Don José Duarte",
      phone: "2277-3311",
      email: "ventas@ferreteriaindustrial.com.ni",
      type: "proveedor",
      status: "activo",
      category: "materiales",
      ruc: "J0310000304050",
      address: "Ciudad Jardín, de la gasolinera Puma 1c al Sur, Managua",
      productsServices: "Cerraduras multipunto, carretillas dobles de acero, pivotes hidráulicos Dorma",
      paymentTerms: "Contado contra entrega",
      observations: "Herrajes de alta durabilidad para puertas de vidrio templado y ventanas corredizas."
    },
    {
      id: "pv4",
      name: "Selladores y Químicos Estructurales S.A.",
      contact: "Ing. Claudia Espinoza",
      phone: "2288-5522",
      email: "pedidos@selladores.com.ni",
      type: "proveedor",
      status: "activo",
      category: "materiales",
      ruc: "J0310000405060",
      address: "Pista Suburbana, Edificio Discover Módulo 2, Managua",
      productsServices: "Silicón estructural Dow Corning 795, selladores neutros y cintas VHB 3M",
      paymentTerms: "Crédito 30 días",
      observations: "Distribuidor exclusivo de silicones de curado neutro para muros cortina."
    }
  ];

  // 2. PRODUCTOS E INVENTARIO (ALUMINIO, VIDRIO, ACCESORIOS Y HERRAJES)
  const products = [
    { id: "p1", code: "ALU-5020", name: "Perfil de aluminio corredizo serie 5020 (6m)", category: "Perfiles", unitPrice: 480, minQuantity: 40, createdAt: "2026-09-01T08:00:00Z", brand: "Alumex / Raquel", measures: "6.00 metros", material: "Aluminio 6063-T5", finish: "Anodizado Natural", use: "Ventanería corrediza residencial" },
    { id: "p2", code: "VID-10T", name: "Vidrio templado de seguridad 10mm (m²)", category: "Vidrios", unitPrice: 950, minQuantity: 20, createdAt: "2026-09-01T08:00:00Z", brand: "Vidrios del Pacífico", measures: "Metro cuadrado a medida", material: "Vidrio templado térmico", finish: "Bordes pulidos brillantes", use: "Puertas, canceles y divisiones comerciales" },
    { id: "p3", code: "SIL-DC795", name: "Silicón estructural Dow Corning 795 (Cartucho 310ml)", category: "Accesorios", unitPrice: 280, minQuantity: 24, createdAt: "2026-09-01T08:00:00Z", brand: "Dow Corning", measures: "310 ml", material: "Polímero de silicona neutra", finish: "Negro estructural", use: "Fijación y sellado estanco de muro cortina" },
    { id: "p4", code: "HER-PIVOT", name: "Pivote hidráulico de piso para puerta templada", category: "Accesorios", unitPrice: 1850, minQuantity: 10, createdAt: "2026-09-01T08:00:00Z", brand: "Dorma / Raquel", measures: "Caja de piso 30x12 cm", material: "Acero inoxidable y latón", finish: "Tapa satinada inox 304", use: "Puertas abatibles de alto tránsito" },
    { id: "p5", code: "ALU-7000", name: "Perfil perimetral batiente serie 7000 (6m)", category: "Perfiles", unitPrice: 620, minQuantity: 30, createdAt: "2026-09-01T08:00:00Z", brand: "Alumex / Raquel", measures: "6.00 metros", material: "Aluminio 6063-T5", finish: "Lacado Blanco Electrostático", use: "Puertas y ventanas abatibles herméticas" },
    { id: "p6", code: "VID-6CL", name: "Vidrio flotado claro 6mm (m²)", category: "Vidrios", unitPrice: 420, minQuantity: 35, createdAt: "2026-09-01T08:00:00Z", brand: "Vidrios del Pacífico", measures: "Metro cuadrado", material: "Flotado estándar", finish: "Canto pulido", use: "Ventanería tradicional y marcos de aluminio" },
    { id: "p7", code: "BAR-12T", name: "Vidrio templado 12mm para barandales con perforaciones", category: "Vidrios", unitPrice: 1450, minQuantity: 15, createdAt: "2026-09-01T08:00:00Z", brand: "Vidrios del Pacífico", measures: "Metro cuadrado", material: "Templado alta resistencia", finish: "Cantos rectificados y barrenos", use: "Barandales de balcones y pasamanos" },
    { id: "p8", code: "ACC-CARR", name: "Carretilla doble tándem con rodamientos sellados", category: "Accesorios", unitPrice: 120, minQuantity: 50, createdAt: "2026-09-01T08:00:00Z", brand: "Herrajes Industriales", measures: "Par de rodos regulables", material: "Nylon autolubricado y acero inox", finish: "Tropicalizado", use: "Hojas corredizas pesadas hasta 120kg" },
    { id: "p9", code: "ALU-MC80", name: "Perfil de columna para muro cortina MC-80 (6m)", category: "Perfiles", unitPrice: 1650, minQuantity: 16, createdAt: "2026-09-01T08:00:00Z", brand: "Alumex / Raquel", measures: "6.00 metros x 80mm", material: "Aluminio estructural 6063-T6", finish: "Anodizado Bronce Oscuro", use: "Estructuras verticales de fachadas de edificios" },
    { id: "p10", code: "VID-8REF", name: "Vidrio reflectivo solar 8mm azul solar (m²)", category: "Vidrios", unitPrice: 880, minQuantity: 25, createdAt: "2026-09-01T08:00:00Z", brand: "Vidrios del Pacífico", measures: "Metro cuadrado", material: "Capa pirolítica reflectiva", finish: "Azul reflectivo / neutro", use: "Control térmico y ahorro energético en fachadas" },
    { id: "p11", code: "HER-MANI", name: "Manija de aluminio embutida con cerradura", category: "Accesorios", unitPrice: 240, minQuantity: 30, createdAt: "2026-09-01T08:00:00Z", brand: "Herrajes Industriales", measures: "Pieza estándar 18cm", material: "Zamak y aluminio inyectado", finish: "Pintura epóxica negra", use: "Cierre seguro de ventanas corredizas" },
    { id: "p12", code: "ACC-EPDM", name: "Empaque perimetral de hule EPDM tipo cuña (Rollo 50m)", category: "Accesorios", unitPrice: 450, minQuantity: 10, createdAt: "2026-09-01T08:00:00Z", brand: "Selladores Industriales", measures: "Rollo de 50 metros", material: "Caucho sintético EPDM", finish: "Negro mate", use: "Hermeticidad al agua y viento en canceles" }
  ];

  // 3. LOTES DE INVENTARIO
  const lots = [
    { id: "lot-1", productId: "p1", quantity: 65, unitCost: 380, entryDate: "2026-09-01T08:00:00Z", warehouseId: "Bodega Central Carretera Norte" },
    { id: "lot-2", productId: "p2", quantity: 45, unitCost: 750, entryDate: "2026-09-05T09:30:00Z", warehouseId: "Taller de Ensamblaje" },
    { id: "lot-3", productId: "p3", quantity: 80, unitCost: 210, entryDate: "2026-09-10T11:00:00Z", warehouseId: "Bodega Central Carretera Norte" },
    { id: "lot-4", productId: "p4", quantity: 18, unitCost: 1450, entryDate: "2026-09-12T14:00:00Z", warehouseId: "Taller de Ensamblaje" },
    { id: "lot-5", productId: "p5", quantity: 50, unitCost: 490, entryDate: "2026-09-15T10:00:00Z", warehouseId: "Bodega Central Carretera Norte" },
    { id: "lot-6", productId: "p6", quantity: 60, unitCost: 310, entryDate: "2026-09-18T16:00:00Z", warehouseId: "Bodega Central Carretera Norte" },
    { id: "lot-7", productId: "p7", quantity: 28, unitCost: 1100, entryDate: "2026-09-20T08:30:00Z", warehouseId: "Taller de Ensamblaje" },
    { id: "lot-8", productId: "p8", quantity: 120, unitCost: 85, entryDate: "2026-09-22T09:00:00Z", warehouseId: "Bodega Central Carretera Norte" },
    { id: "lot-9", productId: "p9", quantity: 24, unitCost: 1300, entryDate: "2026-09-25T11:30:00Z", warehouseId: "Taller de Ensamblaje" },
    { id: "lot-10", productId: "p10", quantity: 40, unitCost: 680, entryDate: "2026-09-28T13:00:00Z", warehouseId: "Taller de Ensamblaje" }
  ];

  // 4. KARDEX PEPS
  const kardex = [
    { id: "kdx-1", productId: "p1", type: "entrada", quantity: 80, unitCost: 380, date: "2026-09-01T08:00:00Z", reason: "Compra inicial según Factura F001-4521 de Alumex", userName: "Luis Morales" },
    { id: "kdx-2", productId: "p1", type: "salida", quantity: 15, unitCost: 380, date: "2026-09-15T14:00:00Z", reason: "Entrega a taller para Proyecto PRJ-001 Ofiplaza", userName: "Carlos Mendoza" },
    { id: "kdx-3", productId: "p2", type: "entrada", quantity: 50, unitCost: 750, date: "2026-09-05T09:30:00Z", reason: "Recepción de cristales templados según Factura F002-8812 de Vidrios del Pacífico", userName: "Luis Morales" },
    { id: "kdx-4", productId: "p2", type: "salida", quantity: 5, unitCost: 750, date: "2026-09-22T10:30:00Z", reason: "Salida para ensamble de puerta módulo comercial Galerías", userName: "Carlos Mendoza" },
    { id: "kdx-5", productId: "p3", type: "entrada", quantity: 100, unitCost: 210, date: "2026-09-10T11:00:00Z", reason: "Ingreso de silicón estructural Dow Corning Factura F004-1102", userName: "Luis Morales" },
    { id: "kdx-6", productId: "p3", type: "salida", quantity: 20, unitCost: 210, date: "2026-09-26T15:00:00Z", reason: "Instalación de fachada flotante en obra Ofiplaza", userName: "Denis Somarriba" }
  ];

  // 5. PROMOCIONES
  const promotions = [
    { id: "promo1", title: "Combo Hogar 8%", blurb: "Llevá perfiles y canceles de baño con descuento desde C$ 3,000.", minSubtotal: 3000, percentOff: 8, active: true, badge: "-8%" },
    { id: "promo2", title: "Renovación Comercial 12%", blurb: "Obras comerciales, vitrinas y cancelería integral desde C$ 10,000.", minSubtotal: 10000, percentOff: 12, active: true, badge: "-12%" },
    { id: "promo3", title: "Mega Pack Fachadas 15%", blurb: "Proyectos verticales con vidrio reflectivo o muro cortina desde C$ 20,000.", minSubtotal: 20000, percentOff: 15, active: true, badge: "-15%" },
    { id: "promo4", title: "Descuento de Apertura 5%", blurb: "Descuento de bienvenida a nuevos clientes corporativos desde C$ 1,500.", minSubtotal: 1500, percentOff: 5, active: true, badge: "-5%" }
  ];

  // 6. PROYECTOS DE CANCELERÍA Y VIDRIO
  const projects = [
    {
      id: "prj-1",
      code: "PRJ-001",
      name: "Fachada Flotante Edificio Ofiplaza Piso 4",
      client: "Grupo Hábitat S.A.",
      clientPartyId: "cl1",
      amount: 185000,
      budget: 125000,
      progress: 85,
      state: "Instalación",
      operationalStage: "instalacion",
      authorizationStatus: "autorizada",
      collectionStatus: "parcial",
      owner: "Carlos Mendoza",
      ownerEmployeeId: "emp-01"
    },
    {
      id: "prj-2",
      code: "PRJ-002",
      name: "Ventanería Línea Europea Residencial Las Colinas",
      client: "Desarrollos Inmobiliarios Las Colinas S.A.",
      clientPartyId: "cl5",
      amount: 98000,
      budget: 64000,
      progress: 60,
      state: "Fabricación",
      operationalStage: "fabricacion",
      authorizationStatus: "autorizada",
      collectionStatus: "parcial",
      owner: "Francisco Valle",
      ownerEmployeeId: "emp-03"
    },
    {
      id: "prj-3",
      code: "PRJ-003",
      name: "Frente de Tienda Vidrio Templado 12mm Plaza Sur",
      client: "Plaza Comercial Sur S.A.",
      clientPartyId: "cl4",
      amount: 45000,
      budget: 28000,
      progress: 100,
      state: "Liquidada",
      operationalStage: "entregado",
      authorizationStatus: "autorizada",
      collectionStatus: "pagado",
      owner: "Carlos Mendoza",
      ownerEmployeeId: "emp-01"
    },
    {
      id: "prj-4",
      code: "PRJ-004",
      name: "Divisiones Hospitalarias Clínicas del Lago",
      client: "Clínica del Lago S.A.",
      clientPartyId: "cl6",
      amount: 72000,
      budget: 48000,
      progress: 35,
      state: "Fabricación",
      operationalStage: "fabricacion",
      authorizationStatus: "autorizada",
      collectionStatus: "parcial",
      owner: "Carlos Mendoza",
      ownerEmployeeId: "emp-01"
    },
    {
      id: "prj-5",
      code: "PRJ-005",
      name: "Barandales Inoxidables Torre Azul Piso 8 al 12",
      client: "Torre Azul Condominios S.A.",
      clientPartyId: "cl2",
      amount: 140000,
      budget: 92000,
      progress: 15,
      state: "Pendiente",
      operationalStage: "medicion",
      authorizationStatus: "pendiente",
      collectionStatus: "pendiente",
      owner: "Francisco Valle",
      ownerEmployeeId: "emp-03"
    }
  ];

  // 7. ÓRDENES DE PRODUCCIÓN
  const production = [
    { id: "ord-1", code: "OP-2026-001", product: "Muro Cortina MC-80 con Vidrio Reflectivo 8mm", client: "Grupo Hábitat S.A.", qty: 14, stage: "instalacion", sprint: "Sprint 18", owner: "Denis Somarriba" },
    { id: "ord-2", code: "OP-2026-002", product: "Ventanas Serie 5020 con Mosquiteros", client: "Desarrollos Inmobiliarios Las Colinas", qty: 22, stage: "ensamble", sprint: "Sprint 18", owner: "Wilmer Jarquín" },
    { id: "ord-3", code: "OP-2026-003", product: "Puerta Batiente Templada 10mm con Pivote Dorma", client: "Plaza Comercial Sur", qty: 2, stage: "entregado", sprint: "Sprint 17", owner: "Roberto Toruño" },
    { id: "ord-4", code: "OP-2026-004", product: "Canceles Hospitalarios Sellados 6mm", client: "Clínica del Lago S.A.", qty: 8, stage: "corte", sprint: "Sprint 19", owner: "Marlon Calero" },
    { id: "ord-5", code: "OP-2026-005", product: "Barandales de Acero Inox con Vidrio 12mm", client: "Torre Azul Condominios", qty: 16, stage: "backlog", sprint: "Sprint 19", owner: "Francisco Valle" }
  ];

  // 8. VENTAS Y FACTURACIÓN COMERCIAL (CUMPLIMIENTO DGI NICARAGUA: IVA 15%, RETENCIÓN IR 2%, RET. ALMA 1%)
  const sales = [
    {
      id: "fac-1001",
      saleNumber: "FACT-2026-00101",
      clientName: "Grupo Hábitat S.A.",
      items: [
        { productId: "p9", productName: "Perfil de columna para muro cortina MC-80", quantity: 12, unitPrice: 1650 },
        { productId: "p10", productName: "Vidrio reflectivo solar 8mm azul solar", quantity: 20, unitPrice: 880 },
        { productId: "p3", productName: "Silicón estructural Dow Corning 795", quantity: 24, unitPrice: 280 }
      ],
      subtotal: 44120,
      discountAmount: 2206, // Descuento 5% cliente recurrente
      taxAmount: 6287.10, // IVA 15% DGI
      total: 48201.10,
      status: "completed",
      saleDate: "2026-09-18T10:00:00Z",
      createdBy: "Ana Silva",
      qrPayload: "DGI-NIC|FACT-2026-00101|J0310000000019|J0310000607080|44120.00|6287.10|48201.10|2026-09-18"
    },
    {
      id: "fac-1002",
      saleNumber: "FACT-2026-00102",
      clientName: "Plaza Comercial Sur S.A.",
      items: [
        { productId: "p2", productName: "Vidrio templado de seguridad 10mm", quantity: 14, unitPrice: 950 },
        { productId: "p4", productName: "Pivote hidráulico de piso para puerta templada", quantity: 2, unitPrice: 1850 },
        { productId: "p11", productName: "Manija de aluminio embutida", quantity: 4, unitPrice: 240 }
      ],
      subtotal: 17960,
      discountAmount: 0,
      taxAmount: 2694.00, // IVA 15%
      total: 20654.00,
      status: "completed",
      saleDate: "2026-09-24T14:30:00Z",
      createdBy: "Ana Silva",
      qrPayload: "DGI-NIC|FACT-2026-00102|J0310000000019|J0310001112130|17960.00|2694.00|20654.00|2026-09-24"
    },
    {
      id: "fac-1003",
      saleNumber: "FACT-2026-00103",
      clientName: "Desarrollos Inmobiliarios Las Colinas S.A.",
      items: [
        { productId: "p1", productName: "Perfil de aluminio corredizo serie 5020", quantity: 25, unitPrice: 480 },
        { productId: "p6", productName: "Vidrio flotado claro 6mm", quantity: 30, unitPrice: 420 },
        { productId: "p8", productName: "Carretilla doble tándem con rodamientos sellados", quantity: 40, unitPrice: 120 }
      ],
      subtotal: 29400,
      discountAmount: 2352, // Promo Combo 8%
      taxAmount: 4057.20,
      total: 31105.20,
      status: "completed",
      saleDate: "2026-10-02T11:15:00Z",
      createdBy: "Ana Silva",
      qrPayload: "DGI-NIC|FACT-2026-00103|J0310000000019|J0310001011120|27048.00|4057.20|31105.20|2026-10-02"
    }
  ];

  // 9. PROFORMAS Y COTIZACIONES
  const proformas = [
    {
      id: "prof-1",
      proformaNumber: "PROF-2026-00045",
      clientName: "Torre Azul Condominios S.A.",
      items: [
        { productId: "p7", productName: "Vidrio templado 12mm para barandales", quantity: 32, unitPrice: 1450 },
        { productId: "p3", productName: "Silicón estructural Dow Corning 795", quantity: 18, unitPrice: 280 }
      ],
      subtotal: 51440,
      discountAmount: 5144, // 10% descuento comercial por volumen
      taxAmount: 6944.40,
      total: 53240.40,
      status: "enviada",
      validUntil: "2026-11-15T23:59:59Z",
      notes: "Cotización incluye instalación con arneses de seguridad en altura y garantía de 3 años.",
      createdAt: "2026-10-10T09:00:00Z",
      createdBy: "Ana Silva",
      qrPayload: "DGI-NIC|PROF-2026-00045|J0310000000019|J0310000708090|46296.00|6944.40|53240.40|2026-10-10"
    },
    {
      id: "prof-2",
      proformaNumber: "PROF-2026-00046",
      clientName: "Constructora Mántica S.A.",
      items: [
        { productId: "p5", productName: "Perfil perimetral batiente serie 7000", quantity: 18, unitPrice: 620 },
        { productId: "p6", productName: "Vidrio flotado claro 6mm", quantity: 20, unitPrice: 420 }
      ],
      subtotal: 19560,
      discountAmount: 978,
      taxAmount: 2787.30,
      total: 21369.30,
      status: "borrador",
      validUntil: "2026-11-20T23:59:59Z",
      notes: "Cancelería interior para oficinas administrativas.",
      createdAt: "2026-10-14T15:00:00Z",
      createdBy: "Ana Silva",
      qrPayload: "DGI-NIC|PROF-2026-00046|J0310000000019|J0310000809100|18582.00|2787.30|21369.30|2026-10-14"
    }
  ];

  // 10. COMPRAS A PROVEEDORES
  const purchases = [
    {
      id: "cmp-2026-01",
      purchaseNumber: "OC-2026-00081",
      supplierName: "Alumex de Nicaragua S.A.",
      supplierId: "pv1",
      items: [
        { productId: "p1", productName: "Perfil de aluminio serie 5020", quantity: 50, unitPrice: 380 },
        { productId: "p5", productName: "Perfil batiente serie 7000", quantity: 30, unitPrice: 490 }
      ],
      total: 33700,
      status: "received",
      purchaseDate: "2026-09-08T09:00:00Z",
      createdBy: "Luis Morales"
    },
    {
      id: "cmp-2026-02",
      purchaseNumber: "OC-2026-00082",
      supplierName: "Vidrios del Pacífico S.A.",
      supplierId: "pv2",
      items: [
        { productId: "p2", productName: "Vidrio templado 10mm", quantity: 40, unitPrice: 750 },
        { productId: "p10", productName: "Vidrio reflectivo 8mm", quantity: 25, unitPrice: 680 }
      ],
      total: 47000,
      status: "received",
      purchaseDate: "2026-09-15T11:00:00Z",
      createdBy: "Luis Morales"
    },
    {
      id: "cmp-2026-03",
      purchaseNumber: "OC-2026-00083",
      supplierName: "Selladores y Químicos Estructurales S.A.",
      supplierId: "pv4",
      items: [
        { productId: "p3", productName: "Silicón estructural Dow Corning 795", quantity: 60, unitPrice: 210 }
      ],
      total: 12600,
      status: "received",
      purchaseDate: "2026-09-22T14:00:00Z",
      createdBy: "Luis Morales"
    }
  ];

  // 11. COLABORADORES Y EXPEDIENTES LABORALES (14 COLABORADORES CON SALARIOS REALES EN CÓRDOBAS)
  const employees = [
    { id: "emp-01", name: "Carlos Mendoza", position: "Ingeniero de Proyectos y Producción", salary: 28500, area: "produccion", hireDate: "2024-01-15", inss: "6548123-4", cedula: "001-150190-0012A" },
    { id: "emp-02", name: "Jhonny Garcia", position: "Administrador de Operaciones y Ventas", salary: 25000, area: "administracion", hireDate: "2024-02-01", inss: "7891234-5", cedula: "001-050492-0023B" },
    { id: "emp-03", name: "Francisco Valle", position: "Maestro Aluminero y Supervisor", salary: 19500, area: "produccion", hireDate: "2024-03-01", inss: "5123987-1", cedula: "001-200888-0034C" },
    { id: "emp-04", name: "Roberto Toruño", position: "Operario de Corte y Troquelado", salary: 14500, area: "produccion", hireDate: "2024-04-10", inss: "4198234-9", cedula: "001-120594-0045D" },
    { id: "emp-05", name: "Marlon Calero", position: "Operario Especialista en Vidrio", salary: 15200, area: "produccion", hireDate: "2024-04-15", inss: "3987123-8", cedula: "001-180993-0056E" },
    { id: "emp-06", name: "Wilmer Jarquín", position: "Armador de Ventanería y Fachadas", salary: 13800, area: "produccion", hireDate: "2024-05-02", inss: "4823901-2", cedula: "001-220795-0067F" },
    { id: "emp-07", name: "Denis Somarriba", position: "Instalador Líder de Altura", salary: 16500, area: "produccion", hireDate: "2024-05-15", inss: "5912384-6", cedula: "001-140291-0078G" },
    { id: "emp-08", name: "José Blandón", position: "Auxiliar de Instalación en Obra", salary: 11500, area: "produccion", hireDate: "2024-06-01", inss: "6129834-0", cedula: "001-031198-0089H" },
    { id: "emp-09", name: "Kevin Rivas", position: "Auxiliar de Taller y Mantenimiento", salary: 10800, area: "produccion", hireDate: "2024-06-15", inss: "7239012-3", cedula: "001-190600-0090J" },
    { id: "emp-10", name: "Ana Silva", position: "Ejecutiva de Ventas Técnicas", salary: 18000, area: "ventas", hireDate: "2024-02-15", inss: "8123904-7", cedula: "001-280393-0011K" },
    { id: "emp-11", name: "María Elena Cruz", position: "Contadora General", salary: 26000, area: "contabilidad", hireDate: "2024-01-20", inss: "9012834-1", cedula: "001-090989-0022L" },
    { id: "emp-12", name: "Luis Morales", position: "Encargado de Compras y Bodega", salary: 17000, area: "compras", hireDate: "2024-03-10", inss: "3129084-5", cedula: "001-171292-0033M" },
    { id: "emp-13", name: "Patricia Mayorga", position: "Asistente Administrativa y RRHH", salary: 14000, area: "rrhh", hireDate: "2024-04-01", inss: "4239801-9", cedula: "001-240496-0044N" },
    { id: "emp-14", name: "Raquel López", position: "Gerente General y Propietaria", salary: 38000, area: "direccion", hireDate: "2023-11-01", inss: "2109834-2", cedula: "001-110885-0055P" }
  ];

  // 12. PLANILLA DE NÓMINA DE NICARAGUA (LEY 185 CÓDIGO DEL TRABAJO Y LEY 822 LCT)
  // Cálculo quincenal con INSS laboral 7%, escala IR 822 progresiva, INSS patronal 21.5%, INATEC 2%
  function calculatePayrollItem(emp) {
    const ordinary = emp.salary / 2; // Quincena base
    const otHours = (emp.area === "produccion" && (emp.id === "emp-03" || emp.id === "emp-07")) ? 10 : 0;
    const hourlyRate = emp.salary / 240; // 30 días * 8 horas
    const otAmount = otHours * hourlyRate * 2.0; // Recargo 100% Art. 62 Código del Trabajo
    const gross = ordinary + otAmount;

    // INSS Laboral: 7% exacto
    const inssLaboral = Number((gross * 0.07).toFixed(2));

    // Base imponible IR: Devengado menos INSS laboral
    const inssBase = gross;
    const irBase = gross - inssLaboral;

    // Proyección anual para cálculo de retención IR según escala progresiva Ley 822 Art. 23
    const projectedAnnual = irBase * 24; // 24 quincenas
    let annualTax = 0;
    if (projectedAnnual > 500000) {
      annualTax = 82500 + (projectedAnnual - 500000) * 0.30;
    } else if (projectedAnnual > 350000) {
      annualTax = 45000 + (projectedAnnual - 350000) * 0.25;
    } else if (projectedAnnual > 200000) {
      annualTax = 15000 + (projectedAnnual - 200000) * 0.20;
    } else if (projectedAnnual > 100000) {
      annualTax = (projectedAnnual - 100000) * 0.15;
    } else {
      annualTax = 0;
    }
    const irQuincenal = Number((annualTax / 24).toFixed(2));

    // Neto a pagar
    const net = Number((gross - inssLaboral - irQuincenal).toFixed(2));

    // Aportes patronales de ley (costo de la empresa)
    const inssPatronal = Number((gross * 0.215).toFixed(2)); // 21.5% régimen integral
    const inatec = Number((gross * 0.02).toFixed(2)); // 2% capacitación técnica
    const aguinaldoProv = Number((gross * (1 / 12)).toFixed(2)); // Provisión 13vo mes
    const vacacionesProv = Number((gross * (1 / 12)).toFixed(2)); // Provisión vacaciones
    const indemnizacionProv = Number((gross * (1 / 12)).toFixed(2)); // Provisión Art. 45 antigüedad

    const employerCost = Number((gross + inssPatronal + inatec + aguinaldoProv + vacacionesProv + indemnizacionProv).toFixed(2));

    return {
      employeeId: emp.id,
      position: emp.position,
      area: emp.area,
      baseSalary: emp.salary,
      ordinary,
      otHours,
      otAmount,
      gross,
      inssLaboral,
      ir: irQuincenal,
      net,
      inssPatronal,
      inatec,
      aguinaldo: aguinaldoProv,
      vacacionesProv,
      indemnizacionProv,
      employerCost
    };
  }

  const payrollItems = employees.map(calculatePayrollItem);
  const totalGross = payrollItems.reduce((acc, i) => acc + i.gross, 0);
  const totalInssLab = payrollItems.reduce((acc, i) => acc + i.inssLaboral, 0);
  const totalIr = payrollItems.reduce((acc, i) => acc + i.ir, 0);
  const totalNet = payrollItems.reduce((acc, i) => acc + i.net, 0);
  const totalInssPat = payrollItems.reduce((acc, i) => acc + i.inssPatronal, 0);
  const totalInatec = payrollItems.reduce((acc, i) => acc + i.inatec, 0);
  const totalEmployerCost = payrollItems.reduce((acc, i) => acc + i.employerCost, 0);

  const payrollRuns = [
    {
      id: "pr-2026-10-1",
      period: "2026-10-1Q",
      paidAt: "2026-10-15T16:00:00Z",
      actor: "María Elena Cruz",
      gross: totalGross,
      inssLaboral: totalInssLab,
      inssPatronal: totalInssPat,
      inatec: totalInatec,
      ir: totalIr,
      net: totalNet,
      employerCost: totalEmployerCost,
      employees: payrollItems
    }
  ];

  // 13. ASIENTOS CONTABLES DE PARTIDA DOBLE CUADRADOS (DÉBITO = CRÉDITO)
  const accounting = [
    {
      id: "ast-001",
      entryNumber: "AST-2026-0001",
      description: "Facturación Proyecto PRJ-001 Ofiplaza Fachada Flotante (Factura FACT-2026-00101)",
      debit: 48201.10,
      credit: 48201.10,
      debitAccount: "1103 Cuentas por Cobrar Clientes",
      creditAccount: "4101 Ingresos por Obras de Cancelería y Vidrio",
      entryDate: "2026-09-18T10:00:00Z",
      referenceType: "sale",
      referenceId: "fac-1001"
    },
    {
      id: "ast-002",
      entryNumber: "AST-2026-0002",
      description: "Compra de perfiles de aluminio a Alumex de Nicaragua (Orden OC-2026-00081)",
      debit: 38755.00,
      credit: 38755.00,
      debitAccount: "1105 Inventario Materia Prima e IVA Acreditable",
      creditAccount: "2101 Cuentas por Pagar Proveedores y Retención DGI",
      entryDate: "2026-09-08T09:00:00Z",
      referenceType: "purchase",
      referenceId: "cmp-2026-01"
    },
    {
      id: "ast-003",
      entryNumber: "AST-2026-0003",
      description: `Registro contable devengado Nómina Quincenal 2026-10-1Q (${employees.length} trabajadores)`,
      debit: totalEmployerCost,
      credit: totalEmployerCost,
      debitAccount: "5101 Gastos de Sueldos y Cargas Sociales",
      creditAccount: "2105 Sueldos, Retenciones y Aportes Patronales por Pagar",
      entryDate: "2026-10-15T15:00:00Z",
      referenceType: "payroll",
      referenceId: "pr-2026-10-1"
    },
    {
      id: "ast-004",
      entryNumber: "AST-2026-0004",
      description: `Pago de Nómina Quincenal 2026-10-1Q mediante transferencia bancaria BANPRO`,
      debit: totalNet,
      credit: totalNet,
      debitAccount: "2105 Sueldos por Pagar",
      creditAccount: "1102 Banco de la Producción (BANPRO) Cuenta Corriente C$",
      entryDate: "2026-10-15T16:00:00Z",
      referenceType: "payroll",
      referenceId: "pr-2026-10-1"
    },
    {
      id: "ast-005",
      entryNumber: "AST-2026-0005",
      description: "Cobro transferencia bancaria BAC Credomatic de Factura Plaza Sur",
      debit: 20654.00,
      credit: 20654.00,
      debitAccount: "1101 Banco BAC Credomatic Cuenta C$",
      creditAccount: "1103 Cuentas por Cobrar Clientes",
      entryDate: "2026-09-25T11:00:00Z",
      referenceType: "cash",
      referenceId: "csh-002"
    }
  ];

  // 14. TESORERÍA, CAJA Y BANCOS
  const cash = [
    { id: "csh-001", account: "banco", type: "entrada", amount: 25000, date: "2026-09-18T14:00:00Z", concept: "Anticipo 50% según contrato Proyecto Ofiplaza Grupo Hábitat" },
    { id: "csh-002", account: "banco", type: "entrada", amount: 20654, date: "2026-09-25T11:00:00Z", concept: "Cobro total de factura FACT-2026-00102 Plaza Sur" },
    { id: "csh-003", account: "banco", type: "salida", amount: 15000, date: "2026-09-20T10:00:00Z", concept: "Abono a proveedor Alumex de Nicaragua transferencia BANPRO" },
    { id: "csh-004", account: "banco", type: "salida", amount: Number(totalNet.toFixed(2)), date: "2026-10-15T16:00:00Z", concept: "Dispersión electrónica de salarios Nómina 2026-10-1Q" },
    { id: "csh-005", account: "caja", type: "entrada", amount: 8500, date: "2026-10-05T09:00:00Z", concept: "Venta de mostrador y retal de perfiles aluminio taller" },
    { id: "csh-006", account: "caja", type: "salida", amount: 1250, date: "2026-10-08T15:30:00Z", concept: "Gastos menores de taller: brocas para aluminio y lija de agua" }
  ];

  // 15. MOVIMIENTOS FINANCIEROS Y RESULTADO OPERATIVO
  const finance = [
    { id: "fin-1", type: "ingreso", category: "Obras y Proyectos", amount: 48201.10, date: "2026-09-18T10:00:00Z", note: "Factura Ofiplaza Piso 4", userName: "María Elena Cruz" },
    { id: "fin-2", type: "ingreso", category: "Venta Comercial", amount: 20654.00, date: "2026-09-24T14:30:00Z", note: "Frente de tienda Plaza Sur", userName: "María Elena Cruz" },
    { id: "fin-3", type: "egreso", category: "Materia Prima", amount: 33700.00, date: "2026-09-08T09:00:00Z", note: "Perfiles de aluminio Alumex", userName: "Luis Morales" },
    { id: "fin-4", type: "egreso", category: "Materia Prima", amount: 47000.00, date: "2026-09-15T11:00:00Z", note: "Cristales templados Vidrios del Pacífico", userName: "Luis Morales" },
    { id: "fin-5", type: "egreso", category: "Nómina y Salarios", amount: totalEmployerCost, date: "2026-10-15T16:00:00Z", note: "Costo integral Nómina Quincenal 1Q Octubre", userName: "María Elena Cruz" },
    { id: "fin-6", type: "egreso", category: "Servicios Básicos", amount: 4500.00, date: "2026-10-05T10:00:00Z", note: "Energía trifásica taller DISNORTE-DISSUR", userName: "María Elena Cruz" }
  ];

  // 16. PROYECCIONES OPERATIVAS
  const projections = [
    { id: "prj-m1", month: "2026-08", expectedSales: 160000, expectedCosts: 95000 },
    { id: "prj-m2", month: "2026-09", expectedSales: 195000, expectedCosts: 110000 },
    { id: "prj-m3", month: "2026-10", expectedSales: 240000, expectedCosts: 135000 },
    { id: "prj-m4", month: "2026-11", expectedSales: 280000, expectedCosts: 155000 },
    { id: "prj-m5", month: "2026-12", expectedSales: 320000, expectedCosts: 180000 }
  ];

  // 17. ÁLBUMES DE CATÁLOGO COMERCIAL
  const albums = [
    {
      id: "alb-1",
      month: "2026-10",
      title: "Catálogo Fachadas y Ventanería Arquitectónica 2026",
      blurb: "Sistemas europeos herméticos, muro cortina y barandales de vidrio templado para proyectos residenciales y corporativos.",
      productIds: ["p1", "p2", "p5", "p7", "p9", "p10"],
      published: true,
      createdAt: "2026-10-01T08:00:00Z"
    },
    {
      id: "alb-2",
      month: "2026-09",
      title: "Línea Baños y Canceles Templados",
      blurb: "Puertas corredizas y abatibles con herrajes de acero inoxidable satinado y empaques magnéticos estancos.",
      productIds: ["p2", "p4", "p8", "p11"],
      published: true,
      createdAt: "2026-09-01T08:00:00Z"
    }
  ];

  // 18. USUARIOS DEL SISTEMA Y GOBIERNO
  const users = [
    { id: "u-super", name: "Raquel López", email: "admin@raquel.com", hierarchy: "superadmin", areas: ["gobierno", "produccion", "finanzas", "contabilidad", "mercadotecnia", "compras", "ventas", "rrhh", "proyectos"], active: true },
    { id: "u-d526347b40b34400a16d30d83990e3c1", name: "Jhonny Garcia", email: "admin@jhonnyarea.com", hierarchy: "administrador", areas: ["compras", "contabilidad", "finanzas", "inventario", "mercadotecnia", "produccion", "proyectos", "rrhh", "ventas"], active: true },
    { id: "u-prod", name: "Carlos Mendoza", email: "produccion@raquel.com", hierarchy: "administrador", areas: ["produccion", "inventario", "proyectos"], active: true },
    { id: "u-fin", name: "María Elena Cruz", email: "contador@raquel.com", hierarchy: "administrador", areas: ["finanzas", "contabilidad", "rrhh"], active: true },
    { id: "u-sales", name: "Ana Silva", email: "vendedor@raquel.com", hierarchy: "estandar", areas: ["ventas", "mercadotecnia"], active: true },
    { id: "u-buy", name: "Luis Morales", email: "compras@raquel.com", hierarchy: "estandar", areas: ["compras", "inventario"], active: true },
    { id: "u-guest", name: "Invitado Gerencia", email: "invitado@raquel.com", hierarchy: "invitado", areas: ["finanzas", "proyectos", "mercadotecnia"], active: true }
  ];

  // 19. AUDITORÍA SELLADA ACID
  const audit = [
    { id: "aud-01", at: "2026-09-01T08:00:00Z", userName: "Raquel López", action: "creacion", module: "gobierno", detail: "Inicio de ciclo fiscal y validación de reglas normativas DGI e INSS.", severity: "info" },
    { id: "aud-02", at: "2026-09-18T10:05:00Z", userName: "Ana Silva", action: "facturacion", module: "ventas", detail: "Emisión de Factura FACT-2026-00101 con retenciones DGI 2% y ALMA 1% a Grupo Hábitat.", severity: "info" },
    { id: "aud-03", at: "2026-09-22T14:10:00Z", userName: "Luis Morales", action: "recepcion", module: "compras", detail: "Recepción conforme de 60 cartuchos de silicón estructural Dow Corning 795.", severity: "info" },
    { id: "aud-04", at: "2026-10-15T15:05:00Z", userName: "María Elena Cruz", action: "calculo_nomina", module: "nomina", detail: `Cálculo de Nómina 2026-10-1Q para ${employees.length} colaboradores con INSS Laboral C$ ${totalInssLab.toFixed(2)} e IR C$ ${totalIr.toFixed(2)}.`, severity: "info" },
    { id: "aud-05", at: "2026-10-15T15:30:00Z", userName: "Jhonny Garcia", action: "aprobacion_nomina", module: "nomina", detail: "Aprobación y autorización de pago de salarios por transferencia bancaria.", severity: "info" },
    { id: "aud-06", at: "2026-10-15T16:00:00Z", userName: "María Elena Cruz", action: "dispersion_bancaria", module: "bancos", detail: `Transferencia masiva BANPRO ejecutada por C$ ${totalNet.toFixed(2)}. Asiento AST-2026-0004 generado.`, severity: "info" }
  ];

  // OBJETO COMPLETO DE ESTADO ERP (LAS 19 COLECCIONES SIN EXCEPCIÓN)
  const completeState = {
    products,
    lots,
    kardex,
    sales,
    proformas,
    promotions,
    purchases,
    accounting,
    finance,
    projections,
    production,
    parties,
    employees: employees.map(e => ({ id: e.id, name: e.name, position: e.position, salary: e.salary, area: e.area })),
    payrollRuns,
    albums,
    projects: projects.map(p => ({ id: p.id, code: p.code, name: p.name, client: p.client, amount: p.amount, progress: p.progress, state: p.state, owner: p.owner })),
    cash,
    users,
    audit
  };

  console.log("\nGuardando las 19 colecciones normalizadas en dbo.ErpState mediante dbo.usp_SaveErpState...");
  const revResult = await pool.request().query("SELECT Revision FROM dbo.ErpState WHERE StateId = 1");
  const revision = revResult.recordset?.[0]?.Revision;

  const payloadJson = JSON.stringify(completeState);
  const saveReq = pool.request()
    .input("payload", sql.NVarChar(sql.MAX), payloadJson);

  if (revision) {
    saveReq.input("ExpectedRevision", sql.VarBinary(8), revision);
  }

  await saveReq.execute("dbo.usp_SaveErpState");
  console.log("✓ dbo.ErpState actualizado exitosamente con las 19 colecciones.");

  // =========================================================================
  // CARGA EN TABLAS RELACIONALES DE SQL SERVER
  // =========================================================================

  console.log("\nActualizando tablas relacionales de Terceros (Parties)...");
  for (const p of parties) {
    await pool.request()
      .input("PartyId", sql.NVarChar(100), p.id)
      .input("Name", sql.NVarChar(240), p.name)
      .input("Contact", sql.NVarChar(200), p.contact)
      .input("Phone", sql.NVarChar(80), p.phone)
      .input("PartyType", sql.NVarChar(20), p.type)
      .input("Category", sql.NVarChar(50), p.type === "proveedor" ? (p.category || "materiales") : null)
      .input("Email", sql.NVarChar(320), p.email || "")
      .input("Address", sql.NVarChar(300), p.address || "")
      .input("Ruc", sql.NVarChar(40), p.ruc || "")
      .input("PaymentTerms", sql.NVarChar(100), p.paymentTerms || "")
      .input("Observations", sql.NVarChar(500), p.observations || "")
      .query(`
        MERGE dbo.Parties AS t
        USING (SELECT @PartyId AS PartyId) AS s ON t.PartyId = s.PartyId
        WHEN MATCHED THEN UPDATE SET 
            Name = @Name, Contact = @Contact, Phone = @Phone, PartyType = @PartyType,
            SupplierCategory = @Category, Email = @Email, Address = @Address,
            Ruc = @Ruc, PaymentTerms = @PaymentTerms, Observations = @Observations,
            UpdatedAt = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT 
            (PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address, Ruc, PaymentTerms, Observations, CreatedAt, UpdatedAt)
            VALUES (@PartyId, @Name, @Contact, @Phone, @PartyType, @Category, @Email, @Address, @Ruc, @PaymentTerms, @Observations, SYSUTCDATETIME(), SYSUTCDATETIME());
      `);
  }
  console.log(`✓ ${parties.length} Terceros (Clientes y Proveedores) actualizados con RUC y normativas DGI.`);

  console.log("\nActualizando tablas relacionales de Empleados (Employees)...");
  for (const emp of employees) {
    await pool.request()
      .input("EmployeeId", sql.NVarChar(100), emp.id)
      .input("Name", sql.NVarChar(240), emp.name)
      .input("Position", sql.NVarChar(160), emp.position)
      .input("Salary", sql.Decimal(18, 2), emp.salary)
      .input("Area", sql.NVarChar(60), emp.area)
      .input("HireDate", sql.Date, emp.hireDate)
      .query(`
        MERGE dbo.Employees AS t
        USING (SELECT @EmployeeId AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId
        WHEN MATCHED THEN UPDATE SET
            Name = @Name, Position = @Position, Salary = @Salary, Area = @Area,
            HireDate = @HireDate, IsActive = 1, EmploymentStatus = N'activo'
        WHEN NOT MATCHED THEN INSERT
            (EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus)
            VALUES (@EmployeeId, @Name, @Position, @Salary, @Area, @HireDate, 1, N'activo');
      `);
  }
  console.log(`✓ ${employees.length} Expedientes de colaboradores actualizados en dbo.Employees.`);

  console.log("\nActualizando Contratos formales de trabajo (dbo.HrContracts)...");
  for (const emp of employees) {
    const contractNumber = `CT-RAQUEL-2024-${emp.id.replace("emp-", "")}`;
    await pool.request()
      .input("EmployeeId", sql.NVarChar(100), emp.id)
      .input("ContractNumber", sql.NVarChar(100), contractNumber)
      .input("Position", sql.NVarChar(160), emp.position)
      .input("StartDate", sql.Date, emp.hireDate)
      .input("AgreedTerms", sql.NVarChar(sql.MAX), `Contrato por tiempo indeterminado según Código del Trabajo de Nicaragua. Jornada laboral diurna legal de 8 horas diarias y 48 horas semanales. Salario mensual ordinario de C$ ${emp.salary.toLocaleString()} córdobas. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.`)
      .query(`
        IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = @EmployeeId)
        BEGIN
            INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)
            VALUES (NEWID(), @EmployeeId, @ContractNumber, N'indefinido', @Position, N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', @StartDate, @AgreedTerms, N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());
        END
      `);
  }
  console.log(`✓ Contratos laborales formales verificados en dbo.HrContracts.`);

  console.log("\nActualizando Proyectos en dbo.Projects...");
  for (const prj of projects) {
    await pool.request()
      .input("ProjectId", sql.NVarChar(100), prj.id)
      .input("Code", sql.NVarChar(60), prj.code)
      .input("Name", sql.NVarChar(240), prj.name)
      .input("Client", sql.NVarChar(240), prj.client)
      .input("ClientPartyId", sql.NVarChar(100), prj.clientPartyId)
      .input("Amount", sql.Decimal(18, 2), prj.amount)
      .input("Budget", sql.Decimal(18, 2), prj.budget)
      .input("Progress", sql.Decimal(5, 2), prj.progress)
      .input("ProjectState", sql.NVarChar(60), prj.state)
      .input("Owner", sql.NVarChar(200), prj.owner)
      .input("OwnerEmployeeId", sql.NVarChar(100), prj.ownerEmployeeId)
      .input("OperationalStage", sql.NVarChar(60), prj.operationalStage)
      .input("AuthorizationStatus", sql.NVarChar(60), prj.authorizationStatus)
      .input("CollectionStatus", sql.NVarChar(60), prj.collectionStatus)
      .query(`
        MERGE dbo.Projects AS t
        USING (SELECT @ProjectId AS ProjectId) AS s ON t.ProjectId = s.ProjectId
        WHEN MATCHED THEN UPDATE SET
            Code = @Code, Name = @Name, Client = @Client, ClientPartyId = @ClientPartyId,
            Amount = @Amount, Budget = @Budget, Progress = @Progress, ProjectState = @ProjectState,
            Owner = @Owner, OwnerEmployeeId = @OwnerEmployeeId, OperationalStage = @OperationalStage,
            AuthorizationStatus = @AuthorizationStatus, CollectionStatus = @CollectionStatus
        WHEN NOT MATCHED THEN INSERT
            (ProjectId, Code, Name, Client, ClientPartyId, Amount, Budget, Progress, ProjectState, Owner, OwnerEmployeeId, OperationalStage, AuthorizationStatus, CollectionStatus)
            VALUES (@ProjectId, @Code, @Name, @Client, @ClientPartyId, @Amount, @Budget, @Progress, @ProjectState, @Owner, @OwnerEmployeeId, @OperationalStage, @AuthorizationStatus, @CollectionStatus);
      `);
  }
  console.log(`✓ ${projects.length} Proyectos actualizados en dbo.Projects con etapas operativas.`);

  console.log("\nActualizando Nómina formal en dbo.PayrollRuns y dbo.PayrollRunItems...");
  const runId = "pr-2026-10-1";
  await pool.request()
    .input("PayrollRunId", sql.NVarChar(100), runId)
    .input("Period", sql.NVarChar(60), "2026-10-1Q")
    .input("StartDate", sql.Date, "2026-10-01")
    .input("EndDate", sql.Date, "2026-10-15")
    .input("PaymentDate", sql.Date, "2026-10-15")
    .input("Actor", sql.NVarChar(200), "María Elena Cruz")
    .input("Gross", sql.Decimal(18, 2), totalGross)
    .input("InssLaboral", sql.Decimal(18, 2), totalInssLab)
    .input("IncomeTax", sql.Decimal(18, 2), totalIr)
    .input("Net", sql.Decimal(18, 2), totalNet)
    .input("InssPatronal", sql.Decimal(18, 2), totalInssPat)
    .input("Inatec", sql.Decimal(18, 2), totalInatec)
    .input("EmployerCost", sql.Decimal(18, 2), totalEmployerCost)
    .query(`
      MERGE dbo.PayrollRuns AS t
      USING (SELECT @PayrollRunId AS PayrollRunId) AS s ON t.PayrollRunId = s.PayrollRunId
      WHEN MATCHED THEN UPDATE SET
          Period = @Period, StartDate = @StartDate, EndDate = @EndDate, PaymentDate = @PaymentDate,
          PaidAt = '2026-10-15 16:00:00', Status = N'pagada', CalculationVersion = 1,
          Gross = @Gross, InssLaboral = @InssLaboral, IncomeTax = @IncomeTax, Net = @Net,
          InssPatronal = @InssPatronal, Inatec = @Inatec, EmployerCost = @EmployerCost,
          ConfirmedPaymentsTotal = @Net, PendingDiscrepancyTotal = 0,
          UpdatedAt = SYSUTCDATETIME()
      WHEN NOT MATCHED THEN INSERT
          (PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, PaidAt, Status, CalculationVersion,
           Actor, Gross, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, EmployerCost,
           ConfirmedPaymentsTotal, PendingDiscrepancyTotal, CreatedAt, UpdatedAt)
          VALUES (@PayrollRunId, @Period, N'quincenal', @StartDate, @EndDate, @PaymentDate, '2026-10-15 16:00:00', N'pagada', 1,
                  @Actor, @Gross, @InssLaboral, @IncomeTax, @Net, @InssPatronal, @Inatec, @EmployerCost,
                  @Net, 0, SYSUTCDATETIME(), SYSUTCDATETIME());
    `);

  for (const item of payrollItems) {
    const itemId = `item-${runId}-${item.employeeId}`;
    await pool.request()
      .input("PayrollItemId", sql.NVarChar(100), itemId)
      .input("PayrollRunId", sql.NVarChar(100), runId)
      .input("EmployeeId", sql.NVarChar(100), item.employeeId)
      .input("PositionSnapshot", sql.NVarChar(160), item.position)
      .input("AreaSnapshot", sql.NVarChar(60), item.area)
      .input("BaseSalaryMonthly", sql.Decimal(18, 2), item.baseSalary)
      .input("PeriodDaysWorked", sql.Decimal(5, 2), 15.0)
      .input("PeriodHoursWorked", sql.Decimal(7, 2), 120.0)
      .input("OrdinarySalary", sql.Decimal(18, 2), item.ordinary)
      .input("OvertimeHours", sql.Decimal(5, 2), item.otHours)
      .input("OvertimeAmount", sql.Decimal(18, 2), item.otAmount)
      .input("Gross", sql.Decimal(18, 2), item.gross)
      .input("InssBase", sql.Decimal(18, 2), item.gross)
      .input("IrBase", sql.Decimal(18, 2), item.gross - item.inssLaboral)
      .input("InssLaboral", sql.Decimal(18, 2), item.inssLaboral)
      .input("IncomeTax", sql.Decimal(18, 2), item.ir)
      .input("Net", sql.Decimal(18, 2), item.net)
      .input("InssPatronal", sql.Decimal(18, 2), item.inssPatronal)
      .input("Inatec", sql.Decimal(18, 2), item.inatec)
      .input("Aguinaldo", sql.Decimal(18, 2), item.aguinaldo)
      .input("VacacionesProv", sql.Decimal(18, 2), item.vacacionesProv)
      .input("IndemnizacionProv", sql.Decimal(18, 2), item.indemnizacionProv)
      .input("EmployerCost", sql.Decimal(18, 2), item.employerCost)
      .query(`
        MERGE dbo.PayrollRunItems AS t
        USING (SELECT @PayrollItemId AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId
        WHEN MATCHED THEN UPDATE SET
            Gross = @Gross, InssLaboral = @InssLaboral, IncomeTax = @IncomeTax, Net = @Net,
            InssPatronal = @InssPatronal, Inatec = @Inatec, Aguinaldo = @Aguinaldo,
            EmployerCost = @EmployerCost, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'
        WHEN NOT MATCHED THEN INSERT
            (PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,
             PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,
             Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,
             VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus)
            VALUES
            (@PayrollItemId, @PayrollRunId, @EmployeeId, @PositionSnapshot, @AreaSnapshot, @BaseSalaryMonthly,
             @PeriodDaysWorked, @PeriodHoursWorked, @OrdinarySalary, @OvertimeHours, @OvertimeAmount,
             @Gross, @InssBase, @IrBase, @InssLaboral, @IncomeTax, @Net, @InssPatronal, @Inatec, @Aguinaldo,
             @VacacionesProv, @IndemnizacionProv, @EmployerCost, N'pagado', N'emitida');
      `);
  }
  console.log(`✓ Planilla 2026-10-1Q registrada con ${payrollItems.length} desgloses individuales en dbo.PayrollRunItems.`);

  console.log("\nActualizando Asientos Contables en dbo.AccountingEntries...");
  for (const ast of accounting) {
    await pool.request()
      .input("EntryId", sql.NVarChar(100), ast.id)
      .input("EntryNumber", sql.NVarChar(60), ast.entryNumber)
      .input("Description", sql.NVarChar(500), ast.description)
      .input("Debit", sql.Decimal(18, 2), ast.debit)
      .input("Credit", sql.Decimal(18, 2), ast.credit)
      .input("DebitAccount", sql.NVarChar(200), ast.debitAccount)
      .input("CreditAccount", sql.NVarChar(200), ast.creditAccount)
      .input("EntryDate", sql.Date, ast.entryDate.split("T")[0])
      .input("ReferenceType", sql.NVarChar(50), ast.referenceType)
      .input("ReferenceId", sql.NVarChar(100), ast.referenceId || "")
      .query(`
        MERGE dbo.AccountingEntries AS t
        USING (SELECT @EntryId AS EntryId) AS s ON t.AccountingEntryId = s.EntryId
        WHEN MATCHED THEN UPDATE SET
            Description = @Description, Debit = @Debit, Credit = @Credit,
            DebitAccount = @DebitAccount, CreditAccount = @CreditAccount,
            EntryDate = @EntryDate, ReferenceType = @ReferenceType, ReferenceId = @ReferenceId
        WHEN NOT MATCHED THEN INSERT
            (AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId)
            VALUES (@EntryId, @EntryNumber, @Description, @Debit, @Credit, @DebitAccount, @CreditAccount, @EntryDate, @ReferenceType, @ReferenceId);
      `);
  }
  console.log(`✓ ${accounting.length} Asientos contables de partida doble cuadrados registrados en dbo.AccountingEntries.`);

  console.log("\n============================================================================");
  console.log("CARGA INTEGRAL COMPLETADA CON ÉXITO");
  console.log("Todos los módulos están relacionados y coherentes con la legislación nicaragüense.");
  console.log("============================================================================");
}

main().then(() => process.exit(0)).catch((err) => {
  console.error("Error durante la carga:", err);
  process.exit(1);
});

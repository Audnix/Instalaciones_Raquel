import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, "../../.env") });

const { getDatabase } = await import("../src/config/sqlserver.js");

async function generate() {
  const pool = await getDatabase();
  if (!pool) {
    console.error("No se pudo conectar a SQL Server.");
    process.exit(1);
  }

  // Get current JSON payload from dbo.ErpState
  const erpRes = await pool.request().query("SELECT Payload FROM dbo.ErpState WHERE StateId = 1");
  const payloadStr = erpRes.recordset?.[0]?.Payload;
  if (!payloadStr) {
    console.error("No se encontró el estado de ErpState en StateId = 1");
    process.exit(1);
  }

  const state = JSON.parse(payloadStr);

  const targetFile = path.resolve(__dirname, "../../Database/SQLServer_Completo/19_carga_integral_datos_reales.sql");
  const lines = [];

  function p(str) {
    lines.push(str);
  }

  function go() {
    lines.push(`GO`);
    lines.push(`SET ANSI_NULLS ON;`);
    lines.push(`SET QUOTED_IDENTIFIER ON;`);
    lines.push(``);
  }

  p(`-- =========================================================================================`);
  p(`-- INSTALACIONES RAQUEL - SISTEMA INTEGRAL ERP & RRHH (NICARAGUA)`);
  p(`-- SCRIPT 19: CARGA INTEGRAL DE REGISTROS REALES Y COHERENTES EN TODOS LOS MÓDULOS`);
  p(`--`);
  p(`-- Normativa Aplicada:`);
  p(`-- 1. DGI - Ley 822 (Ley de Concertación Tributaria de Nicaragua):`);
  p(`--    - IVA 15% en facturación de bienes y obras de cancelería y vidrio.`);
  p(`--    - Retención en la fuente del IR sobre salarios según escala progresiva Art. 23.`);
  p(`--    - Retención del 2% por servicios profesionales y 1% por compra de bienes.`);
  p(`--    - Retención municipal de la Alcaldía de Managua (ALMA) 1%.`);
  p(`-- 2. MITRAB - Ley 185 (Código del Trabajo de Nicaragua):`);
  p(`--    - Contratos de trabajo por tiempo indefinido formalizados.`);
  p(`--    - Jornada laboral diurna legal de 8 horas diarias / 48 horas semanales.`);
  p(`--    - Recargo del 100% por horas extraordinarias (Art. 62).`);
  p(`--    - Provisión de Décimo Tercer Mes (Aguinaldo, Art. 93-99).`);
  p(`--    - Provisión de Vacaciones (15 días por cada 6 meses continuos, Art. 76).`);
  p(`--    - Provisión de Indemnización por Antigüedad (Art. 45).`);
  p(`-- 3. INSS e INATEC:`);
  p(`--    - Aporte Laboral INSS: 7.00%`);
  p(`--    - Aporte Patronal INSS: 21.50%`);
  p(`--    - Aporte INATEC: 2.00%`);
  p(`-- =========================================================================================`);
  p(``);
  p(`SET NOCOUNT ON;`);
  p(`SET ANSI_NULLS ON;`);
  p(`SET QUOTED_IDENTIFIER ON;`);
  p(`USE [Instalaciones Raquel];`);
  go();

  p(`PRINT '=========================================================================================';`);
  p(`PRINT 'INICIANDO CARGA INTEGRAL DE REGISTROS REALES · INSTALACIONES RAQUEL';`);
  p(`PRINT '=========================================================================================';`);
  go();

  // 1. TERCEROS (Parties)
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 1. TERCEROS: CLIENTES Y PROVEEDORES (RUC DGI Y DIRECCIONES EN MANAGUA, NICARAGUA)`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Terceros (Clientes corporativos y Proveedores)...';`);
  for (const part of state.parties) {
    const cat = part.type === "proveedor" ? (part.category || "materiales") : "NULL";
    const status = part.type === "proveedor" ? (part.status || "activo") : "NULL";
    p(`MERGE dbo.Parties AS t`);
    p(`USING (SELECT N'${part.id}' AS PartyId) AS s ON t.PartyId = s.PartyId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    Name = N'${part.name.replace(/'/g, "''")}', Contact = N'${(part.contact || "").replace(/'/g, "''")}',`);
    p(`    Phone = N'${part.phone || ""}', PartyType = N'${part.type}',`);
    p(`    SupplierCategory = ${cat === "NULL" ? "NULL" : `N'${cat}'`},`);
    p(`    Email = N'${(part.email || "").replace(/'/g, "''")}', Address = N'${(part.address || "").replace(/'/g, "''")}',`);
    p(`    Ruc = N'${part.ruc || ""}', PaymentTerms = N'${(part.paymentTerms || "").replace(/'/g, "''")}',`);
    p(`    Observations = N'${(part.observations || "").replace(/'/g, "''")}',`);
    p(`    SupplierStatus = ${status === "NULL" ? "NULL" : `N'${status}'`},`);
    p(`    UpdatedAt = SYSUTCDATETIME()`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    PartyId, Name, Contact, Phone, PartyType, SupplierCategory, Email, Address,`);
    p(`    Ruc, PaymentTerms, Observations, SupplierStatus, CreatedAt, UpdatedAt`);
    p(`) VALUES (`);
    p(`    N'${part.id}', N'${part.name.replace(/'/g, "''")}', N'${(part.contact || "").replace(/'/g, "''")}', N'${part.phone || ""}',`);
    p(`    N'${part.type}', ${cat === "NULL" ? "NULL" : `N'${cat}'`}, N'${(part.email || "").replace(/'/g, "''")}', N'${(part.address || "").replace(/'/g, "''")}',`);
    p(`    N'${part.ruc || ""}', N'${(part.paymentTerms || "").replace(/'/g, "''")}', N'${(part.observations || "").replace(/'/g, "''")}',`);
    p(`    ${status === "NULL" ? "NULL" : `N'${status}'`}, SYSUTCDATETIME(), SYSUTCDATETIME()`);
    p(`);`);
  }
  go();

  // 2. PRODUCTOS
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 2. CATÁLOGO DE PRODUCTOS (ALUMINIO, VIDRIO DE SEGURIDAD Y ACCESORIOS)`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Catálogo de Productos...';`);
  for (const prod of state.products) {
    p(`MERGE dbo.Products AS t`);
    p(`USING (SELECT N'${prod.id}' AS ProductId) AS s ON t.ProductId = s.ProductId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    Code = N'${prod.code}', Name = N'${prod.name.replace(/'/g, "''")}', Category = N'${prod.category}',`);
    p(`    UnitPrice = ${prod.unitPrice}, MinQuantity = ${prod.minQuantity},`);
    p(`    Model = N'${(prod.model || "").replace(/'/g, "''")}', Brand = N'${(prod.brand || "").replace(/'/g, "''")}',`);
    p(`    Material = N'${(prod.material || "").replace(/'/g, "''")}', Measures = N'${(prod.measures || "").replace(/'/g, "''")}',`);
    p(`    Capacity = N'${(prod.capacity || "").replace(/'/g, "''")}', Finish = N'${(prod.finish || "").replace(/'/g, "''")}',`);
    p(`    ProductUse = N'${(prod.use || "").replace(/'/g, "''")}', Warranty = N'${(prod.warranty || "").replace(/'/g, "''")}'`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    ProductId, Code, Name, Category, UnitPrice, MinQuantity, CreatedAt,`);
    p(`    Model, Brand, Material, Measures, Capacity, Finish, ProductUse, Warranty`);
    p(`) VALUES (`);
    p(`    N'${prod.id}', N'${prod.code}', N'${prod.name.replace(/'/g, "''")}', N'${prod.category}', ${prod.unitPrice}, ${prod.minQuantity},`);
    p(`    '${prod.createdAt || "2026-09-01T08:00:00Z"}', N'${(prod.model || "").replace(/'/g, "''")}', N'${(prod.brand || "").replace(/'/g, "''")}',`);
    p(`    N'${(prod.material || "").replace(/'/g, "''")}', N'${(prod.measures || "").replace(/'/g, "''")}', N'${(prod.capacity || "").replace(/'/g, "''")}',`);
    p(`    N'${(prod.finish || "").replace(/'/g, "''")}', N'${(prod.use || "").replace(/'/g, "''")}', N'${(prod.warranty || "").replace(/'/g, "''")}'`);
    p(`);`);
  }
  go();

  // 3. LOTES DE INVENTARIO
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 3. LOTES DE INVENTARIO (BODEGA CENTRAL Y TALLER DE ENSAMBLAJE)`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Lotes de Inventario...';`);
  for (const lot of state.lots) {
    p(`MERGE dbo.InventoryLots AS t`);
    p(`USING (SELECT N'${lot.id}' AS LotId) AS s ON t.LotId = s.LotId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    ProductId = N'${lot.productId}', Quantity = ${lot.quantity}, UnitCost = ${lot.unitCost},`);
    p(`    EntryDate = '${lot.entryDate}', WarehouseId = N'${lot.warehouseId}'`);
    p(`WHEN NOT MATCHED THEN INSERT (LotId, ProductId, Quantity, UnitCost, EntryDate, WarehouseId)`);
    p(`VALUES (N'${lot.id}', N'${lot.productId}', ${lot.quantity}, ${lot.unitCost}, '${lot.entryDate}', N'${lot.warehouseId}');`);
  }
  go();

  // 4. KARDEX PEPS
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 4. MOVIMIENTOS DE KARDEX PEPS`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Movimientos de Kardex...';`);
  for (const kdx of state.kardex) {
    p(`MERGE dbo.KardexMoves AS t`);
    p(`USING (SELECT N'${kdx.id}' AS KardexMoveId) AS s ON t.KardexMoveId = s.KardexMoveId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    ProductId = N'${kdx.productId}', MoveType = N'${kdx.type}', Quantity = ${kdx.quantity},`);
    p(`    UnitCost = ${kdx.unitCost}, MoveDate = '${kdx.date}', Reason = N'${kdx.reason.replace(/'/g, "''")}', UserName = N'${kdx.userName.replace(/'/g, "''")}'`);
    p(`WHEN NOT MATCHED THEN INSERT (KardexMoveId, ProductId, MoveType, Quantity, UnitCost, MoveDate, Reason, UserName)`);
    p(`VALUES (N'${kdx.id}', N'${kdx.productId}', N'${kdx.type}', ${kdx.quantity}, ${kdx.unitCost}, '${kdx.date}', N'${kdx.reason.replace(/'/g, "''")}', N'${kdx.userName.replace(/'/g, "''")}');`);
  }
  go();

  // 5. VENTAS Y FACTURACIÓN DGI
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 5. FACTURACIÓN COMERCIAL Y CUMPLIMIENTO DGI (IVA 15%, QR FISCAL)`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Facturación Comercial con QR DGI...';`);
  for (const sale of state.sales) {
    p(`MERGE dbo.Sales AS t`);
    p(`USING (SELECT N'${sale.id}' AS SaleId) AS s ON t.SaleId = s.SaleId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    SaleNumber = N'${sale.saleNumber}', ClientName = N'${sale.clientName.replace(/'/g, "''")}',`);
    p(`    Subtotal = ${sale.subtotal}, DiscountAmount = ${sale.discountAmount || 0},`);
    p(`    TaxAmount = ${sale.taxAmount}, Total = ${sale.total}, Status = N'${sale.status}',`);
    p(`    SaleDate = '${sale.saleDate}', CreatedBy = N'${sale.createdBy}', QrPayload = N'${sale.qrPayload}'`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    SaleId, SaleNumber, ClientName, Subtotal, DiscountAmount, TaxAmount, Total, Status, SaleDate, CreatedBy, QrPayload`);
    p(`) VALUES (`);
    p(`    N'${sale.id}', N'${sale.saleNumber}', N'${sale.clientName.replace(/'/g, "''")}', ${sale.subtotal},`);
    p(`    ${sale.discountAmount || 0}, ${sale.taxAmount}, ${sale.total}, N'${sale.status}', '${sale.saleDate}',`);
    p(`    N'${sale.createdBy}', N'${sale.qrPayload}'`);
    p(`);`);

    if (sale.items) {
      let line = 1;
      for (const it of sale.items) {
        p(`IF NOT EXISTS (SELECT 1 FROM dbo.SaleItems WHERE SaleId = N'${sale.id}' AND LineNumber = ${line})`);
        p(`    INSERT INTO dbo.SaleItems (SaleId, LineNumber, ProductId, Quantity, UnitPrice)`);
        p(`    VALUES (N'${sale.id}', ${line}, N'${it.productId}', ${it.quantity}, ${it.unitPrice});`);
        line++;
      }
    }
  }
  go();

  // 6. PROFORMAS
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 6. PROFORMAS Y COTIZACIONES COMERCIALES`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Proformas Comerciales...';`);
  for (const prof of state.proformas) {
    p(`MERGE dbo.Proformas AS t`);
    p(`USING (SELECT N'${prof.id}' AS ProformaId) AS s ON t.ProformaId = s.ProformaId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    ProformaNumber = N'${prof.proformaNumber}', ClientName = N'${prof.clientName.replace(/'/g, "''")}',`);
    p(`    Subtotal = ${prof.subtotal}, DiscountAmount = ${prof.discountAmount || 0},`);
    p(`    TaxAmount = ${prof.taxAmount}, Total = ${prof.total}, Status = N'${prof.status}',`);
    p(`    ValidUntil = '${prof.validUntil}', Notes = N'${(prof.notes || "").replace(/'/g, "''")}',`);
    p(`    CreatedAt = '${prof.createdAt}', CreatedBy = N'${prof.createdBy}', QrPayload = N'${prof.qrPayload}'`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    ProformaId, ProformaNumber, ClientName, Subtotal, DiscountAmount, TaxAmount, Total, Status, ValidUntil, Notes, CreatedAt, CreatedBy, QrPayload`);
    p(`) VALUES (`);
    p(`    N'${prof.id}', N'${prof.proformaNumber}', N'${prof.clientName.replace(/'/g, "''")}', ${prof.subtotal},`);
    p(`    ${prof.discountAmount || 0}, ${prof.taxAmount}, ${prof.total}, N'${prof.status}', '${prof.validUntil}',`);
    p(`    N'${(prof.notes || "").replace(/'/g, "''")}', '${prof.createdAt}', N'${prof.createdBy}', N'${prof.qrPayload}'`);
    p(`);`);

    if (prof.items) {
      let line = 1;
      for (const it of prof.items) {
        p(`IF NOT EXISTS (SELECT 1 FROM dbo.ProformaItems WHERE ProformaId = N'${prof.id}' AND LineNumber = ${line})`);
        p(`    INSERT INTO dbo.ProformaItems (ProformaId, LineNumber, ProductId, Quantity, UnitPrice)`);
        p(`    VALUES (N'${prof.id}', ${line}, N'${it.productId}', ${it.quantity}, ${it.unitPrice});`);
        line++;
      }
    }
  }
  go();

  // 7. COMPRAS A PROVEEDORES
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 7. COMPRAS Y ÓRDENES DE COMPRA (OC)`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Órdenes de Compra a Proveedores...';`);
  for (const cmp of state.purchases) {
    p(`MERGE dbo.Purchases AS t`);
    p(`USING (SELECT N'${cmp.id}' AS PurchaseId) AS s ON t.PurchaseId = s.PurchaseId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    PurchaseNumber = N'${cmp.purchaseNumber}', SupplierName = N'${cmp.supplierName.replace(/'/g, "''")}',`);
    p(`    SupplierPartyId = N'${cmp.supplierId}', Total = ${cmp.total}, Status = N'${cmp.status}',`);
    p(`    PurchaseDate = '${cmp.purchaseDate}', CreatedBy = N'${cmp.createdBy}'`);
    p(`WHEN NOT MATCHED THEN INSERT (PurchaseId, PurchaseNumber, SupplierName, SupplierPartyId, Total, Status, PurchaseDate, CreatedBy)`);
    p(`VALUES (N'${cmp.id}', N'${cmp.purchaseNumber}', N'${cmp.supplierName.replace(/'/g, "''")}', N'${cmp.supplierId}', ${cmp.total}, N'${cmp.status}', '${cmp.purchaseDate}', N'${cmp.createdBy}');`);

    if (cmp.items) {
      let line = 1;
      for (const it of cmp.items) {
        p(`IF NOT EXISTS (SELECT 1 FROM dbo.PurchaseItems WHERE PurchaseId = N'${cmp.id}' AND LineNumber = ${line})`);
        p(`    INSERT INTO dbo.PurchaseItems (PurchaseId, LineNumber, ProductId, Quantity, UnitPrice)`);
        p(`    VALUES (N'${cmp.id}', ${line}, N'${it.productId}', ${it.quantity}, ${it.unitPrice});`);
        line++;
      }
    }
  }
  go();

  // 8. PROYECTOS Y PRODUCCIÓN
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 8. PROYECTOS DE CANCELERÍA Y ÓRDENES DE PRODUCCIÓN EN TALLER`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Proyectos y Producción...';`);
  const projectStateMap = {
    "prj-1": { state: "En proceso", stage: "instalacion", auth: "autorizada", col: "parcial", clientParty: "cl1", ownerEmp: "emp-01", budget: 125000 },
    "prj-2": { state: "En proceso", stage: "fabricacion", auth: "autorizada", col: "parcial", clientParty: "cl5", ownerEmp: "emp-03", budget: 64000 },
    "prj-3": { state: "Liquidada", stage: "entregado", auth: "autorizada", col: "pagado", clientParty: "cl4", ownerEmp: "emp-01", budget: 28000 },
    "prj-4": { state: "En proceso", stage: "fabricacion", auth: "autorizada", col: "parcial", clientParty: "cl6", ownerEmp: "emp-01", budget: 48000 },
    "prj-5": { state: "Pendiente", stage: "medicion", auth: "pendiente", col: "pendiente", clientParty: "cl2", ownerEmp: "emp-03", budget: 92000 }
  };

  for (const prj of state.projects) {
    const meta = projectStateMap[prj.id] || { state: "En proceso", stage: "fabricacion", auth: "autorizada", col: "parcial", clientParty: "cl1", ownerEmp: "emp-01", budget: prj.amount * 0.65 };
    p(`MERGE dbo.Projects AS t`);
    p(`USING (SELECT N'${prj.id}' AS ProjectId) AS s ON t.ProjectId = s.ProjectId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    Code = N'${prj.code}', Name = N'${prj.name.replace(/'/g, "''")}', Client = N'${prj.client.replace(/'/g, "''")}',`);
    p(`    ClientPartyId = N'${meta.clientParty}', Amount = ${prj.amount}, Budget = ${meta.budget},`);
    p(`    Progress = ${prj.progress}, ProjectState = N'${meta.state}', Owner = N'${prj.owner.replace(/'/g, "''")}',`);
    p(`    OwnerEmployeeId = N'${meta.ownerEmp}', OperationalStage = N'${meta.stage}',`);
    p(`    AuthorizationStatus = N'${meta.auth}', CollectionStatus = N'${meta.col}'`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    ProjectId, Code, Name, Client, ClientPartyId, Amount, Budget, Progress,`);
    p(`    ProjectState, Owner, OwnerEmployeeId, OperationalStage, AuthorizationStatus, CollectionStatus`);
    p(`) VALUES (`);
    p(`    N'${prj.id}', N'${prj.code}', N'${prj.name.replace(/'/g, "''")}', N'${prj.client.replace(/'/g, "''")}', N'${meta.clientParty}',`);
    p(`    ${prj.amount}, ${meta.budget}, ${prj.progress}, N'${meta.state}', N'${prj.owner.replace(/'/g, "''")}', N'${meta.ownerEmp}',`);
    p(`    N'${meta.stage}', N'${meta.auth}', N'${meta.col}'`);
    p(`);`);
  }

  for (const po of state.production) {
    p(`MERGE dbo.ProductionOrders AS t`);
    p(`USING (SELECT N'${po.id}' AS ProductionOrderId) AS s ON t.ProductionOrderId = s.ProductionOrderId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    Code = N'${po.code}', Product = N'${po.product.replace(/'/g, "''")}', Client = N'${po.client.replace(/'/g, "''")}',`);
    p(`    Quantity = ${po.qty}, Stage = N'${po.stage}', Sprint = N'${po.sprint}', Owner = N'${po.owner.replace(/'/g, "''")}'`);
    p(`WHEN NOT MATCHED THEN INSERT (ProductionOrderId, Code, Product, Client, Quantity, Stage, Sprint, Owner)`);
    p(`VALUES (N'${po.id}', N'${po.code}', N'${po.product.replace(/'/g, "''")}', N'${po.client.replace(/'/g, "''")}', ${po.qty}, N'${po.stage}', N'${po.sprint}', N'${po.owner.replace(/'/g, "''")}');`);
  }
  go();

  // 9. TALENTO HUMANO: EMPLEADOS Y CONTRATOS
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 9. TALENTO HUMANO: 14 EXPEDIENTES LABORALES Y CONTRATOS INDEFINIDOS DE LEY`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Colaboradores y Contratos de Trabajo (Ley 185)...';`);
  const empList = [
    { id: "emp-01", name: "Carlos Mendoza", pos: "Ingeniero de Proyectos y Producción", sal: 28500, area: "produccion", hire: "2024-01-15" },
    { id: "emp-02", name: "Jhonny Garcia", pos: "Administrador de Operaciones y Ventas", sal: 25000, area: "administracion", hire: "2024-02-01" },
    { id: "emp-03", name: "Francisco Valle", pos: "Maestro Aluminero y Supervisor", sal: 19500, area: "produccion", hire: "2024-03-01" },
    { id: "emp-04", name: "Roberto Toruño", pos: "Operario de Corte y Troquelado", sal: 14500, area: "produccion", hire: "2024-04-10" },
    { id: "emp-05", name: "Marlon Calero", pos: "Operario Especialista en Vidrio", sal: 15200, area: "produccion", hire: "2024-04-15" },
    { id: "emp-06", name: "Wilmer Jarquín", pos: "Armador de Ventanería y Fachadas", sal: 13800, area: "produccion", hire: "2024-05-02" },
    { id: "emp-07", name: "Denis Somarriba", pos: "Instalador Líder de Altura", sal: 16500, area: "produccion", hire: "2024-05-15" },
    { id: "emp-08", name: "José Blandón", pos: "Auxiliar de Instalación en Obra", sal: 11500, area: "produccion", hire: "2024-06-01" },
    { id: "emp-09", name: "Kevin Rivas", pos: "Auxiliar de Taller y Mantenimiento", sal: 10800, area: "produccion", hire: "2024-06-15" },
    { id: "emp-10", name: "Ana Silva", pos: "Ejecutiva de Ventas Técnicas", sal: 18000, area: "ventas", hire: "2024-02-15" },
    { id: "emp-11", name: "María Elena Cruz", pos: "Contadora General", sal: 26000, area: "contabilidad", hire: "2024-01-20" },
    { id: "emp-12", name: "Luis Morales", pos: "Encargado de Compras y Bodega", sal: 17000, area: "compras", hire: "2024-03-10" },
    { id: "emp-13", name: "Patricia Mayorga", pos: "Asistente Administrativa y RRHH", sal: 14000, area: "rrhh", hire: "2024-04-01" },
    { id: "emp-14", name: "Raquel López", pos: "Gerente General y Propietaria", sal: 38000, area: "direccion", hire: "2023-11-01" }
  ];

  for (const emp of empList) {
    p(`MERGE dbo.Employees AS t`);
    p(`USING (SELECT N'${emp.id}' AS EmployeeId) AS s ON t.EmployeeId = s.EmployeeId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    Name = N'${emp.name}', Position = N'${emp.pos}', Salary = ${emp.sal},`);
    p(`    Area = N'${emp.area}', HireDate = '${emp.hire}', IsActive = 1, EmploymentStatus = N'activo'`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    EmployeeId, Name, Position, Salary, Area, HireDate, IsActive, EmploymentStatus`);
    p(`) VALUES (`);
    p(`    N'${emp.id}', N'${emp.name}', N'${emp.pos}', ${emp.sal}, N'${emp.area}', '${emp.hire}', 1, N'activo'`);
    p(`);`);

    const contractNum = `CT-RAQUEL-2024-${emp.id.replace("emp-", "")}`;
    p(`IF NOT EXISTS (SELECT 1 FROM dbo.HrContracts WHERE EmployeeId = N'${emp.id}')`);
    p(`BEGIN`);
    p(`    INSERT INTO dbo.HrContracts (ContractId, EmployeeId, ContractNumber, ContractType, Position, WorkSchedule, StartDate, AgreedTerms, DocumentName, Status, CreatedAt, UpdatedAt)`);
    p(`    VALUES (NEWID(), N'${emp.id}', N'${contractNum}', N'indefinido', N'${emp.pos}', N'Lunes a Viernes 8:00 - 17:00 / Sábado 8:00 - 12:00', '${emp.hire}', N'Contrato por tiempo indefinido según Código del Trabajo de Nicaragua Ley 185. Jornada laboral legal de 8 horas diarias y 48 horas semanales. Beneficios de ley: INSS, Aguinaldo, Vacaciones e Indemnización por antigüedad.', N'Contrato_Laboral_Registrado.pdf', N'registrado', SYSUTCDATETIME(), SYSUTCDATETIME());`);
    p(`END;`);
  }
  go();

  // 10. TALENTO HUMANO: SOLICITUDES, ASISTENCIA Y SEGURIDAD
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 10. GESTIÓN DE BIENESTAR: ASISTENCIA, EPP, SOLICITUDES Y CAPACITACIONES`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Asistencias, Solicitudes y Entregas de EPP...';`);
  
  // Asistencias recientes para operarios
  for (const emp of empList) {
    p(`IF NOT EXISTS (SELECT 1 FROM dbo.HrAttendanceRecords WHERE EmployeeId = N'${emp.id}' AND RecordDate = '2026-10-16')`);
    p(`BEGIN`);
    p(`    INSERT INTO dbo.HrAttendanceRecords (AttendanceId, EmployeeId, RecordDate, ShiftName, ScheduledIn, ScheduledOut, ActualIn, ActualOut, HoursLogged, HoursReviewed, HoursAuthorized, Status, CreatedAt)`);
    p(`    VALUES (NEWID(), N'${emp.id}', '2026-10-16', N'Jornada Ordinaria Diurna', '08:00:00', '17:00:00', '07:55:00', '17:05:00', 8.00, 8.00, 8.00, N'autorizado_nomina', SYSUTCDATETIME());`);
    p(`END;`);
  }

  // Solicitudes laborales representativas
  const requestsData = [
    { empId: "emp-03", cat: "vacaciones", start: "2026-11-03", end: "2026-11-07", status: "aprobada", details: "Solicitud de 5 días de vacaciones anuales según Art. 76 Código del Trabajo.", res: "Aprobadas 5 días de vacaciones ordinarias acumuladas." },
    { empId: "emp-06", cat: "vacaciones", start: "2026-11-16", end: "2026-11-21", status: "en_revision", details: "Solicitud de 6 días de vacaciones por asuntos familiares.", res: "En revisión de disponibilidad de relevo en taller de corte." },
    { empId: "emp-07", cat: "permiso", start: "2026-10-20", end: "2026-10-21", status: "aprobada", details: "Cita médica programada en clínica médica previsional del INSS.", res: "Permiso con goce de salario por constancia de atención médica INSS." },
    { empId: "emp-05", cat: "seguridad", start: null, end: null, status: "enviada", details: "Reporte de desgaste preventivo en guantes anticorte y solicitud de reposición para corte de vidrio templado.", res: "Pendiente entrega en bodega de seguridad." }
  ];

  for (const req of requestsData) {
    const sDate = req.start ? `'${req.start}'` : "NULL";
    const eDate = req.end ? `'${req.end}'` : "NULL";
    const isDecided = req.status === "aprobada" || req.status === "rechazada";
    const decUser = isDecided ? "N'u-super'" : "NULL";
    const decAt = isDecided ? "SYSUTCDATETIME()" : "NULL";
    p(`IF NOT EXISTS (SELECT 1 FROM dbo.HrRequests WHERE EmployeeId = N'${req.empId}' AND Category = N'${req.cat}')`);
    p(`BEGIN`);
    p(`    INSERT INTO dbo.HrRequests (HrRequestId, MutationId, EmployeeId, Category, StartDate, EndDate, Details, Status, Resolution, AssignedToAppUserId, DecidedByAppUserId, DecidedAt, CreatedAt, UpdatedAt)`);
    p(`    VALUES (NEWID(), NEWID(), N'${req.empId}', N'${req.cat}', ${sDate}, ${eDate}, N'${req.details}', N'${req.status}', N'${req.res}', N'u-super', ${decUser}, ${decAt}, SYSUTCDATETIME(), SYSUTCDATETIME());`);
    p(`END;`);
  }

  // Entregas de EPP
  p(`DECLARE @EquipVidrio UNIQUEIDENTIFIER;`);
  p(`SELECT TOP 1 @EquipVidrio = EquipmentId FROM dbo.HrSafetyEquipment WHERE Category = 'vidrio' AND Name LIKE '%Guantes anticorte%';`);
  p(`IF @EquipVidrio IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = 'emp-05')`);
  p(`BEGIN`);
  p(`    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes, CreatedAt)`);
  p(`    VALUES (NEWID(), N'emp-05', @EquipVidrio, '2026-10-01', N'dotacion_inicial', '2026-12-30', N'Dotación de guantes anticorte nivel 5 para manipulación de cristales templados.', SYSUTCDATETIME());`);
  p(`END;`);

  p(`DECLARE @EquipAltura UNIQUEIDENTIFIER;`);
  p(`SELECT TOP 1 @EquipAltura = EquipmentId FROM dbo.HrSafetyEquipment WHERE Category = 'altura' AND Name LIKE '%Arnés%';`);
  p(`IF @EquipAltura IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.HrEquipmentDeliveries WHERE EmployeeId = 'emp-07')`);
  p(`BEGIN`);
  p(`    INSERT INTO dbo.HrEquipmentDeliveries (DeliveryId, EmployeeId, EquipmentId, DeliveryDate, DeliveryType, NextReplacementDate, Notes, CreatedAt)`);
  p(`    VALUES (NEWID(), N'emp-07', @EquipAltura, '2026-09-15', N'dotacion_inicial', '2027-03-15', N'Arnés de cuerpo entero 4 argollas para instalación de muro cortina en altura.', SYSUTCDATETIME());`);
  p(`END;`);
  go();

  // 11. NÓMINA FORMAL NICARAGÜENSE
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 11. PLANILLA DE NÓMINA NICARAGÜENSE 2026-10-1Q (LEY 185 Y LEY 822)`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Planilla de Nómina Quincenal y Desglose de 14 Colaboradores...';`);

  const runId = "pr-2026-10-1";
  p(`MERGE dbo.PayrollRuns AS t`);
  p(`USING (SELECT N'${runId}' AS PayrollRunId) AS s ON t.PayrollRunId = s.PayrollRunId`);
  p(`WHEN MATCHED THEN UPDATE SET`);
  p(`    Period = N'2026-10-1Q', StartDate = '2026-10-01', EndDate = '2026-10-15', PaymentDate = '2026-10-15',`);
  p(`    PaidAt = '2026-10-15 16:00:00', Status = N'cerrada', CalculationVersion = 1,`);
  p(`    Gross = 137150.00, InssLaboral = 9600.50, IncomeTax = 11746.96, Net = 115802.54,`);
  p(`    InssPatronal = 29487.25, Inatec = 2743.00, EmployerCost = 203667.74,`);
  p(`    ConfirmedPaymentsTotal = 115802.54, PendingDiscrepancyTotal = 0, UpdatedAt = SYSUTCDATETIME()`);
  p(`WHEN NOT MATCHED THEN INSERT (`);
  p(`    PayrollRunId, Period, PeriodType, StartDate, EndDate, PaymentDate, PaidAt, Status, CalculationVersion,`);
  p(`    Actor, Gross, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, EmployerCost,`);
  p(`    ConfirmedPaymentsTotal, PendingDiscrepancyTotal, CreatedAt, UpdatedAt`);
  p(`) VALUES (`);
  p(`    N'${runId}', N'2026-10-1Q', N'quincenal', '2026-10-01', '2026-10-15', '2026-10-15', '2026-10-15 16:00:00', N'cerrada', 1,`);
  p(`    N'María Elena Cruz', 137150.00, 9600.50, 11746.96, 115802.54, 29487.25, 2743.00, 203667.74,`);
  p(`    115802.54, 0, SYSUTCDATETIME(), SYSUTCDATETIME()`);
  p(`);`);

  // Desglose de cada trabajador en PayrollRunItems
  for (const emp of empList) {
    const ordinary = emp.sal / 2;
    const otHours = (emp.area === "produccion" && (emp.id === "emp-03" || emp.id === "emp-07")) ? 10 : 0;
    const hourly = emp.sal / 240;
    const otAmt = otHours * hourly * 2.0;
    const gross = ordinary + otAmt;
    const inssLab = Number((gross * 0.07).toFixed(2));
    const irBase = gross - inssLab;
    const projAnnual = irBase * 24;
    let annualTax = 0;
    if (projAnnual > 500000) annualTax = 82500 + (projAnnual - 500000) * 0.30;
    else if (projAnnual > 350000) annualTax = 45000 + (projAnnual - 350000) * 0.25;
    else if (projAnnual > 200000) annualTax = 15000 + (projAnnual - 200000) * 0.20;
    else if (projAnnual > 100000) annualTax = (projAnnual - 100000) * 0.15;
    const ir = Number((annualTax / 24).toFixed(2));
    const net = Number((gross - inssLab - ir).toFixed(2));
    const inssPat = Number((gross * 0.215).toFixed(2));
    const inatec = Number((gross * 0.02).toFixed(2));
    const aguinaldo = Number((gross * (1 / 12)).toFixed(2));
    const vacProv = Number((gross * (1 / 12)).toFixed(2));
    const indProv = Number((gross * (1 / 12)).toFixed(2));
    const empCost = Number((gross + inssPat + inatec + aguinaldo + vacProv + indProv).toFixed(2));
    const itemId = `item-${runId}-${emp.id}`;

    p(`MERGE dbo.PayrollRunItems AS t`);
    p(`USING (SELECT N'${itemId}' AS PayrollItemId) AS s ON t.PayrollItemId = s.PayrollItemId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    Gross = ${gross}, InssLaboral = ${inssLab}, IncomeTax = ${ir}, Net = ${net},`);
    p(`    InssPatronal = ${inssPat}, Inatec = ${inatec}, Aguinaldo = ${aguinaldo},`);
    p(`    EmployerCost = ${empCost}, PaymentStatus = N'pagado', ReceiptStatus = N'emitida'`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    PayrollItemId, PayrollRunId, EmployeeId, PositionSnapshot, AreaSnapshot, BaseSalaryMonthly,`);
    p(`    PeriodDaysWorked, PeriodHoursWorked, OrdinarySalary, OvertimeHours, OvertimeAmount,`);
    p(`    Gross, InssBase, IrBase, InssLaboral, IncomeTax, Net, InssPatronal, Inatec, Aguinaldo,`);
    p(`    VacacionesProv, IndemnizacionProv, EmployerCost, PaymentStatus, ReceiptStatus`);
    p(`) VALUES (`);
    p(`    N'${itemId}', N'${runId}', N'${emp.id}', N'${emp.pos}', N'${emp.area}', ${emp.sal},`);
    p(`    15.0, 120.0, ${ordinary}, ${otHours}, ${otAmt},`);
    p(`    ${gross}, ${gross}, ${irBase}, ${inssLab}, ${ir}, ${net}, ${inssPat}, ${inatec}, ${aguinaldo},`);
    p(`    ${vacProv}, ${indProv}, ${empCost}, N'pagado', N'emitida'`);
    p(`);`);
  }
  go();

  // 12. ASIENTOS CONTABLES Y TESORERÍA
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 12. ASIENTOS CONTABLES DE PARTIDA DOBLE Y MOVIMIENTOS BANCARIOS`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Cargando Asientos Contables Cuadrados y Movimientos de Caja y Bancos...';`);
  for (const ast of state.accounting) {
    p(`MERGE dbo.AccountingEntries AS t`);
    p(`USING (SELECT N'${ast.id}' AS AccountingEntryId) AS s ON t.AccountingEntryId = s.AccountingEntryId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    EntryNumber = N'${ast.entryNumber}', Description = N'${ast.description.replace(/'/g, "''")}',`);
    p(`    Debit = ${ast.debit}, Credit = ${ast.credit}, DebitAccount = N'${ast.debitAccount}',`);
    p(`    CreditAccount = N'${ast.creditAccount}', EntryDate = '${ast.entryDate}',`);
    p(`    ReferenceType = N'${ast.referenceType}', ReferenceId = N'${ast.referenceId || ""}'`);
    p(`WHEN NOT MATCHED THEN INSERT (`);
    p(`    AccountingEntryId, EntryNumber, Description, Debit, Credit, DebitAccount, CreditAccount, EntryDate, ReferenceType, ReferenceId`);
    p(`) VALUES (`);
    p(`    N'${ast.id}', N'${ast.entryNumber}', N'${ast.description.replace(/'/g, "''")}', ${ast.debit}, ${ast.credit},`);
    p(`    N'${ast.debitAccount}', N'${ast.creditAccount}', '${ast.entryDate}', N'${ast.referenceType}', N'${ast.referenceId || ""}'`);
    p(`);`);
  }

  for (const csh of state.cash) {
    p(`MERGE dbo.CashMoves AS t`);
    p(`USING (SELECT N'${csh.id}' AS CashMoveId) AS s ON t.CashMoveId = s.CashMoveId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    Account = N'${csh.account}', MoveType = N'${csh.type}', Amount = ${csh.amount},`);
    p(`    MoveDate = '${csh.date}', Concept = N'${csh.concept.replace(/'/g, "''")}'`);
    p(`WHEN NOT MATCHED THEN INSERT (CashMoveId, Account, MoveType, Amount, MoveDate, Concept)`);
    p(`VALUES (N'${csh.id}', N'${csh.account}', N'${csh.type}', ${csh.amount}, '${csh.date}', N'${csh.concept.replace(/'/g, "''")}');`);
  }

  for (const fn of state.finance) {
    p(`MERGE dbo.FinanceMoves AS t`);
    p(`USING (SELECT N'${fn.id}' AS FinanceMoveId) AS s ON t.FinanceMoveId = s.FinanceMoveId`);
    p(`WHEN MATCHED THEN UPDATE SET`);
    p(`    MoveType = N'${fn.type}', Category = N'${fn.category}', Amount = ${fn.amount},`);
    p(`    MoveDate = '${fn.date}', Note = N'${fn.note.replace(/'/g, "''")}', UserName = N'${fn.userName}'`);
    p(`WHEN NOT MATCHED THEN INSERT (FinanceMoveId, MoveType, Category, Amount, MoveDate, Note, UserName)`);
    p(`VALUES (N'${fn.id}', N'${fn.type}', N'${fn.category}', ${fn.amount}, '${fn.date}', N'${fn.note.replace(/'/g, "''")}', N'${fn.userName}');`);
  }
  go();

  // 13. VINCULACIONES DE CLAVES FORÁNEAS Y COHERENCIA
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 13. RESOLUCIÓN DE LLAVES FORÁNEAS Y COHERENCIA RELACIONAL`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Sincronizando relaciones de llaves foráneas...';`);
  p(`UPDATE s SET ClientPartyId = p.PartyId FROM dbo.Sales s JOIN dbo.Parties p ON s.ClientName = p.Name WHERE p.PartyType = 'cliente';`);
  p(`UPDATE pr SET ClientPartyId = p.PartyId FROM dbo.Proformas pr JOIN dbo.Parties p ON pr.ClientName = p.Name WHERE p.PartyType = 'cliente';`);
  p(`UPDATE pc SET SupplierPartyId = p.PartyId FROM dbo.Purchases pc JOIN dbo.Parties p ON pc.SupplierName = p.Name WHERE p.PartyType = 'proveedor';`);
  p(`UPDATE pj SET ClientPartyId = p.PartyId FROM dbo.Projects pj JOIN dbo.Parties p ON pj.Client = p.Name WHERE p.PartyType = 'cliente';`);
  p(`UPDATE pj SET OwnerEmployeeId = e.EmployeeId FROM dbo.Projects pj JOIN dbo.Employees e ON pj.Owner = e.Name;`);
  p(`UPDATE prun SET AccountingEntryId = 'ast-003', CashMoveId = 'csh-004' FROM dbo.PayrollRuns prun WHERE prun.PayrollRunId = 'pr-2026-10-1';`);
  go();

  // 14. SINCRONIZACIÓN DEL ESTADO GLOBAL JSON
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`-- 14. SINCRONIZACIÓN FINAL CON dbo.ErpState MEDIANTE dbo.usp_SaveErpState`);
  p(`-- -----------------------------------------------------------------------------------------`);
  p(`PRINT 'Sincronizando estado integral en dbo.ErpState...';`);
  p(`DECLARE @PayloadJson NVARCHAR(MAX) = N'${payloadStr.replace(/'/g, "''")}';`);
  p(`EXEC dbo.usp_SaveErpState @Payload = @PayloadJson;`);
  go();

  p(`PRINT '=========================================================================================';`);
  p(`PRINT 'CARGA INTEGRAL COMPLETADA CON ÉXITO AL 100%';`);
  p(`PRINT 'Todos los módulos están relacionados coherentemente con las leyes de Nicaragua.';`);
  p(`PRINT '=========================================================================================';`);
  go();

  fs.writeFileSync(targetFile, lines.join("\n"), "utf-8");
  console.log(`✓ Archivo regenerado exitosamente: ${targetFile} (${lines.length} líneas)`);
}

generate().then(() => process.exit(0)).catch(err => {
  console.error("Error generando script SQL:", err);
  process.exit(1);
});

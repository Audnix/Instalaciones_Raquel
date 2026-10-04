import type { ErpDatabase } from "../types/erp";

export type SchemaGroup = "Gobierno" | "Catálogo" | "Operación" | "Finanzas";
export type UmlRelationKind = "asociación" | "agregación" | "composición" | "generalización";

export type SchemaEntity = {
  id: string;
  name: string;
  umlClass: string;
  group: SchemaGroup;
  stereotype: string;
  tableKey?: keyof ErpDatabase;
  filter?: "cliente" | "proveedor";
  reqs: string[];
  umlDiagram: string;
  attributes: string[];
  operations: string[];
};

export type SchemaRelation = {
  from: string;
  to: string;
  label: string;
  multiplicity: string;
  kind: UmlRelationKind;
};

export const schemaEntities: SchemaEntity[] = [
  {
    id: "usuario",
    name: "Usuario",
    umlClass: "Usuario",
    group: "Gobierno",
    stereotype: "actor interno",
    tableKey: "users",
    reqs: ["RF01", "RF03", "RF16"],
    umlDiagram: "Clases + casos de uso",
    attributes: ["- id: String", "- name: String", "- email: String", "- hierarchy: HierarchyRole", "- areas: AreaRole[]", "- active: Boolean"],
    operations: ["+ autenticar()", "+ can(modulo, accion)"]
  },
  {
    id: "auditoria",
    name: "Auditoría",
    umlClass: "EventoAuditoria",
    group: "Gobierno",
    stereotype: "trazabilidad",
    tableKey: "audit",
    reqs: ["RF15", "RU08", "RS05"],
    umlDiagram: "Secuencia + clases",
    attributes: ["- at: DateTime", "- userName: String", "- action: String", "- module: String", "- detail: String"],
    operations: ["+ registrar()"]
  },
  {
    id: "producto",
    name: "Producto",
    umlClass: "Producto",
    group: "Catálogo",
    stereotype: "entidad maestra",
    tableKey: "products",
    reqs: ["RF02", "RF17", "RF18"],
    umlDiagram: "Clases / ER",
    attributes: ["- code: String", "- name: String", "- category: String", "- unitPrice: Number", "- minQuantity: Number"],
    operations: ["+ alta()", "+ stockOf()", "+ alertaMinimo()"]
  },
  {
    id: "lote",
    name: "Lote PEPS",
    umlClass: "LoteInventario",
    group: "Catálogo",
    stereotype: "valuación",
    tableKey: "lots",
    reqs: ["RD02", "RF21", "RS04"],
    umlDiagram: "Clases + objetos",
    attributes: ["- productId: String", "- quantity: Number", "- unitCost: Number", "- entryDate: DateTime", "- warehouseId: String"],
    operations: ["+ consumePeps()"]
  },
  {
    id: "kardex",
    name: "Kardex",
    umlClass: "MovimientoKardex",
    group: "Catálogo",
    stereotype: "histórico",
    tableKey: "kardex",
    reqs: ["RF21", "RU06"],
    umlDiagram: "Actividad",
    attributes: ["- type: entrada|salida", "- quantity: Number", "- unitCost: Number", "- reason: String"],
    operations: ["+ asentarMovimiento()"]
  },
  {
    id: "cliente",
    name: "Cliente",
    umlClass: "Cliente",
    group: "Catálogo",
    stereotype: "Party",
    tableKey: "parties",
    filter: "cliente",
    reqs: ["RF08", "RU01"],
    umlDiagram: "Clases (generalización)",
    attributes: ["- name: String", "- contact: String", "- phone: String", "- type = cliente"],
    operations: ["+ facturar()", "+ cotizar()"]
  },
  {
    id: "proveedor",
    name: "Proveedor",
    umlClass: "Proveedor",
    group: "Catálogo",
    stereotype: "Party",
    tableKey: "parties",
    filter: "proveedor",
    reqs: ["RF07", "RU04"],
    umlDiagram: "Clases (generalización)",
    attributes: ["- name: String", "- contact: String", "- phone: String", "- type = proveedor"],
    operations: ["+ recibirOrden()"]
  },
  {
    id: "promocion",
    name: "Promoción",
    umlClass: "Promocion",
    group: "Catálogo",
    stereotype: "ABC / oferta",
    tableKey: "promotions",
    reqs: ["RF06", "INN-05"],
    umlDiagram: "Clases",
    attributes: ["- title: String", "- minSubtotal: Number", "- percentOff: Number", "- active: Boolean"],
    operations: ["+ aplicar(subtotal)"]
  },
  {
    id: "venta",
    name: "Venta",
    umlClass: "Venta",
    group: "Operación",
    stereotype: "transacción",
    tableKey: "sales",
    reqs: ["RF08", "RF20", "RD01", "RD04"],
    umlDiagram: "Secuencia + colaboración",
    attributes: ["- saleNumber: String", "- clientName: String", "- items: ItemVenta[]", "- taxAmount: Number", "- total: Number", "- qrPayload: String"],
    operations: ["+ confirmar()", "+ emitirQR()"]
  },
  {
    id: "proforma",
    name: "Proforma",
    umlClass: "Proforma",
    group: "Operación",
    stereotype: "cotización",
    tableKey: "proformas",
    reqs: ["RF08", "RF19"],
    umlDiagram: "Estados",
    attributes: ["- proformaNumber: String", "- status: borrador|enviada|aceptada|vencida|convertida", "- validUntil: Date", "- convertedSaleId?: String"],
    operations: ["+ enviar()", "+ convertirAVenta()"]
  },
  {
    id: "compra",
    name: "Compra",
    umlClass: "OrdenCompra",
    group: "Operación",
    stereotype: "abastecimiento",
    tableKey: "purchases",
    reqs: ["RF07", "RU04"],
    umlDiagram: "Actividad",
    attributes: ["- purchaseNumber: String", "- supplierName: String", "- status: ordered|received", "- total: Number"],
    operations: ["+ recibir()", "+ crearLotes()"]
  },
  {
    id: "orden",
    name: "Orden de taller",
    umlClass: "OrdenProduccion",
    group: "Operación",
    stereotype: "Kanban / Scrum",
    tableKey: "production",
    reqs: ["RF11", "RD06", "RU03"],
    umlDiagram: "Estados + actividad",
    attributes: ["- code: String", "- stage: backlog|corte|ensamble|instalacion|entregado", "- sprint: String", "- qty: Number"],
    operations: ["+ avanzarEtapa()"]
  },
  {
    id: "proyecto",
    name: "Proyecto / obra",
    umlClass: "Proyecto",
    group: "Operación",
    stereotype: "instalación",
    tableKey: "projects",
    reqs: ["RF12", "RF10"],
    umlDiagram: "Clases",
    attributes: ["- code: String", "- client: String", "- amount: Number", "- progress: Number", "- state: String"],
    operations: ["+ actualizarAvance()"]
  },
  {
    id: "asiento",
    name: "Asiento",
    umlClass: "AsientoContable",
    group: "Finanzas",
    stereotype: "partida doble",
    tableKey: "accounting",
    reqs: ["RF05", "RD03", "RS01"],
    umlDiagram: "Colaboración",
    attributes: ["- entryNumber: String", "- debit: Number", "- credit: Number", "- debitAccount: String", "- creditAccount: String"],
    operations: ["+ equilibrar()", "+ cierreBatch()"]
  },
  {
    id: "finanza",
    name: "Movimiento financiero",
    umlClass: "MovimientoFinanciero",
    group: "Finanzas",
    stereotype: "flujo",
    tableKey: "finance",
    reqs: ["RF04", "RU02"],
    umlDiagram: "Actividad",
    attributes: ["- type: ingreso|egreso", "- category: String", "- amount: Number", "- note: String"],
    operations: ["+ registrar()"]
  },
  {
    id: "caja",
    name: "Caja / banco",
    umlClass: "MovimientoTesoreria",
    group: "Finanzas",
    stereotype: "tesorería",
    tableKey: "cash",
    reqs: ["RF09"],
    umlDiagram: "Secuencia",
    attributes: ["- account: caja|banco", "- type: entrada|salida", "- amount: Number", "- concept: String"],
    operations: ["+ cobrar()"]
  },
  {
    id: "empleado",
    name: "Empleado",
    umlClass: "Empleado",
    group: "Finanzas",
    stereotype: "RRHH",
    tableKey: "employees",
    reqs: ["RF13", "RU07"],
    umlDiagram: "Clases",
    attributes: ["- name: String", "- position: String", "- salary: Number", "- area: String"],
    operations: ["+ calcularNomina()"]
  },
  {
    id: "proyeccion",
    name: "Proyección",
    umlClass: "ProyeccionMensual",
    group: "Finanzas",
    stereotype: "planeación",
    tableKey: "projections",
    reqs: ["RF22", "RF04"],
    umlDiagram: "Clases",
    attributes: ["- month: String", "- expectedSales: Number", "- expectedCosts: Number"],
    operations: ["+ proyectar()"]
  }
];

export const schemaRelations: SchemaRelation[] = [
  { from: "usuario", to: "auditoria", label: "deja huella", multiplicity: "1..*", kind: "asociación" },
  { from: "usuario", to: "venta", label: "registra", multiplicity: "1..*", kind: "asociación" },
  { from: "cliente", to: "venta", label: "compra", multiplicity: "1..*", kind: "asociación" },
  { from: "cliente", to: "proforma", label: "solicita", multiplicity: "0..*", kind: "asociación" },
  { from: "cliente", to: "proyecto", label: "contrata obra", multiplicity: "0..*", kind: "asociación" },
  { from: "proveedor", to: "compra", label: "abastece", multiplicity: "1..*", kind: "asociación" },
  { from: "producto", to: "lote", label: "tiene lotes", multiplicity: "1..*", kind: "composición" },
  { from: "producto", to: "kardex", label: "historial", multiplicity: "1..*", kind: "agregación" },
  { from: "venta", to: "producto", label: "detalla ítems", multiplicity: "1..*", kind: "agregación" },
  { from: "venta", to: "asiento", label: "asiento espejo", multiplicity: "1", kind: "composición" },
  { from: "venta", to: "caja", label: "cobra", multiplicity: "1", kind: "composición" },
  { from: "venta", to: "kardex", label: "salida PEPS", multiplicity: "1..*", kind: "composición" },
  { from: "compra", to: "lote", label: "genera lotes", multiplicity: "1..*", kind: "composición" },
  { from: "proforma", to: "venta", label: "se convierte", multiplicity: "0..1", kind: "asociación" },
  { from: "promocion", to: "venta", label: "descuento", multiplicity: "0..*", kind: "asociación" },
  { from: "proyecto", to: "orden", label: "ordena taller", multiplicity: "0..*", kind: "agregación" },
  { from: "asiento", to: "finanza", label: "refleja flujo", multiplicity: "0..1", kind: "asociación" }
];

export const umlCoverage = [
  { diagram: "Casos de uso", evidencia: "Actores Superadmin, Admin, Estándar, Invitado sobre Venta, Compra, OT y Auditoría." },
  { diagram: "Clases", evidencia: "Cajas de 3 compartimentos con visibilidad y relaciones UML." },
  { diagram: "Objetos", evidencia: "Instancia viva FAC-1092: Torre Azul + VID-10T + AS-1001." },
  { diagram: "Estados", evidencia: "OT backlog→corte→ensamble→instalación→entregado y ciclo de Proforma." },
  { diagram: "Actividad", evidencia: "Flujo de cobro: cliente → PEPS → IVA 15% → asiento → caja." },
  { diagram: "Secuencia / colaboración", evidencia: "Mensajes addSale → consumePeps → asiento → log auditoría." },
  { diagram: "Paquetes", evidencia: "Paquetes Gobierno, Catálogo, Operación y Finanzas." },
  { diagram: "Componentes / despliegue", evidencia: "Presentación React, store transaccional y persistencia local." }
];

export const acidPipeline = [
  { step: "1", title: "Cliente y producto", detail: "Se elige cliente y líneas de aluminio/vidrio.", req: "RF08" },
  { step: "2", title: "Preview PEPS", detail: "Se consume primero el lote más antiguo.", req: "RD02 / RS04" },
  { step: "3", title: "IVA 15%", detail: "El dominio tributario calcula impuesto.", req: "RD01" },
  { step: "4", title: "Descontar lote + kardex", detail: "Stock y costo real salen juntos.", req: "RF21" },
  { step: "5", title: "Asiento + caja", detail: "Débito Caja = crédito Ventas, o nada.", req: "RD03 / RD04" },
  { step: "6", title: "QR y auditoría", detail: "El comprobante queda trazable.", req: "RF15 / RF19" }
];

export const otStates = ["backlog", "corte", "ensamble", "instalacion", "entregado"] as const;
export const proformaStates = ["borrador", "enviada", "aceptada", "vencida", "convertida"] as const;

export const tableCatalog: { key: keyof ErpDatabase; label: string; cols: string[] }[] = [
  { key: "products", label: "productos", cols: ["code", "name", "category", "unitPrice", "minQuantity"] },
  { key: "lots", label: "lotes", cols: ["productId", "quantity", "unitCost", "warehouseId"] },
  { key: "kardex", label: "kardex", cols: ["type", "quantity", "unitCost", "reason", "userName"] },
  { key: "sales", label: "ventas", cols: ["saleNumber", "clientName", "total", "status"] },
  { key: "proformas", label: "proformas", cols: ["proformaNumber", "clientName", "total", "status"] },
  { key: "purchases", label: "compras", cols: ["purchaseNumber", "supplierName", "total", "status"] },
  { key: "accounting", label: "asientos", cols: ["entryNumber", "description", "debit", "credit"] },
  { key: "finance", label: "finanzas", cols: ["type", "category", "amount", "note"] },
  { key: "cash", label: "caja", cols: ["account", "type", "amount", "concept"] },
  { key: "production", label: "órdenes", cols: ["code", "product", "client", "stage"] },
  { key: "projects", label: "proyectos", cols: ["code", "name", "client", "state"] },
  { key: "parties", label: "terceros", cols: ["name", "type", "contact", "phone"] },
  { key: "employees", label: "empleados", cols: ["name", "position", "area", "salary"] },
  { key: "users", label: "usuarios", cols: ["name", "email", "hierarchy"] },
  { key: "audit", label: "auditoría", cols: ["at", "userName", "action", "module", "detail"] }
];

export function countEntity(db: ErpDatabase, entity: SchemaEntity) {
  if (!entity.tableKey) return 0;
  const rows = db[entity.tableKey] as unknown as Array<Record<string, unknown>>;
  if (!entity.filter) return rows.length;
  return rows.filter((row) => row.type === entity.filter).length;
}

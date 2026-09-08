export type HierarchyRole = "superadmin" | "administrador" | "estandar" | "invitado";

export type AreaRole =
  | "produccion"
  | "inventario"
  | "finanzas"
  | "contabilidad"
  | "mercadotecnia"
  | "compras"
  | "ventas"
  | "rrhh"
  | "proyectos"
  | "gobierno";

export type Action = "read" | "write" | "approve" | "admin";

export type ModuleId =
  | "produccion"
  | "inventario"
  | "finanzas"
  | "caja"
  | "bancos"
  | "contabilidad"
  | "costos"
  | "ventas"
  | "clientes"
  | "mercadotecnia"
  | "compras"
  | "proveedores"
  | "proyectos"
  | "rrhh"
  | "nomina"
  | "reportes"
  | "auditoria"
  | "usuarios"
  | "datos"
  | "metodologia"
  | "ers";

export type SessionUser = {
  id: string;
  name: string;
  email: string;
  password: string;
  hierarchy: HierarchyRole;
  areas: AreaRole[];
  active: boolean;
};

export type Product = {
  id: string;
  code: string;
  name: string;
  category: string;
  unitPrice: number;
  minQuantity: number;
  createdAt: string;
};

export type InventoryLot = {
  id: string;
  productId: string;
  quantity: number;
  unitCost: number;
  entryDate: string;
  warehouseId: string;
};

export type KardexMove = {
  id: string;
  productId: string;
  type: "entrada" | "salida";
  quantity: number;
  unitCost: number;
  date: string;
  reason: string;
  userName: string;
};

export type SaleItem = { productId: string; quantity: number; unitPrice: number };

export type Sale = {
  id: string;
  saleNumber: string;
  clientName: string;
  items: SaleItem[];
  subtotal: number;
  discountAmount: number;
  promoCode?: string;
  taxAmount: number;
  total: number;
  status: "draft" | "completed";
  saleDate: string;
  createdBy: string;
  qrPayload: string;
};

export type Proforma = {
  id: string;
  proformaNumber: string;
  clientName: string;
  items: SaleItem[];
  subtotal: number;
  discountAmount: number;
  promoCode?: string;
  taxAmount: number;
  total: number;
  status: "borrador" | "enviada" | "aceptada" | "vencida" | "convertida";
  validUntil: string;
  notes: string;
  createdAt: string;
  createdBy: string;
  qrPayload: string;
  convertedSaleId?: string;
};

export type Promotion = {
  id: string;
  title: string;
  blurb: string;
  minSubtotal: number;
  percentOff: number;
  active: boolean;
  badge: string;
};

export type Purchase = {
  id: string;
  purchaseNumber: string;
  supplierName: string;
  items: SaleItem[];
  total: number;
  status: "ordered" | "received";
  purchaseDate: string;
  createdBy: string;
};

export type AccountingEntry = {
  id: string;
  entryNumber: string;
  description: string;
  debit: number;
  credit: number;
  debitAccount: string;
  creditAccount: string;
  entryDate: string;
  referenceType: "sale" | "purchase" | "manual" | "payroll" | "cash";
  referenceId?: string;
};

export type FinanceMove = {
  id: string;
  type: "ingreso" | "egreso";
  category: string;
  amount: number;
  date: string;
  note: string;
  userName: string;
};

export type Projection = {
  id: string;
  month: string;
  expectedSales: number;
  expectedCosts: number;
};

export type ProductionOrder = {
  id: string;
  code: string;
  product: string;
  client: string;
  qty: number;
  stage: "backlog" | "corte" | "ensamble" | "instalacion" | "entregado";
  sprint: string;
  owner: string;
};

export type Party = {
  id: string;
  name: string;
  contact: string;
  phone: string;
  type: "cliente" | "proveedor";
};

export type Employee = {
  id: string;
  name: string;
  position: string;
  salary: number;
  area: string;
};

export type Project = {
  id: string;
  code: string;
  name: string;
  client: string;
  amount: number;
  progress: number;
  state: string;
  owner: string;
};

export type CashMove = {
  id: string;
  account: "caja" | "banco";
  type: "entrada" | "salida";
  amount: number;
  date: string;
  concept: string;
};

export type AuditEvent = {
  id: string;
  at: string;
  userName: string;
  action: string;
  module: string;
  detail: string;
};

export type ErpDatabase = {
  products: Product[];
  lots: InventoryLot[];
  kardex: KardexMove[];
  sales: Sale[];
  proformas: Proforma[];
  promotions: Promotion[];
  purchases: Purchase[];
  accounting: AccountingEntry[];
  finance: FinanceMove[];
  projections: Projection[];
  production: ProductionOrder[];
  parties: Party[];
  employees: Employee[];
  projects: Project[];
  cash: CashMove[];
  users: SessionUser[];
  audit: AuditEvent[];
};

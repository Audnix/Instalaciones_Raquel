import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { buildDocToken } from "../lib/invoiceDoc";
import { catalogLots, catalogProducts, catalogPromotions } from "../data/catalog";
import { seedUsers } from "../auth/roles";
import type {
  AccountingEntry,
  AuditEvent,
  CashMove,
  Employee,
  ErpDatabase,
  FinanceMove,
  InventoryLot,
  KardexMove,
  Party,
  Product,
  ProductionOrder,
  Proforma,
  Project,
  Projection,
  Purchase,
  Sale,
  SessionUser
} from "../types/erp";

const DB_KEY = "raquel_erp_db_v5";

const now = () => new Date().toISOString();
const daysAgo = (days: number) => new Date(Date.now() - days * 86400000).toISOString();
const id = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;

const seed: ErpDatabase = {
  products: catalogProducts,
  lots: catalogLots,
  promotions: catalogPromotions,
  kardex: [
    { id: "kx1", productId: "p2", type: "salida", quantity: 6, unitCost: 310, date: daysAgo(4), reason: "Venta FAC-1092", userName: "Ana Ventas" },
    { id: "kx2", productId: "p1", type: "entrada", quantity: 40, unitCost: 140, date: daysAgo(7), reason: "OC-448 Alumex", userName: "Luis Compras" },
    { id: "kx3", productId: "p5", type: "entrada", quantity: 55, unitCost: 190, date: daysAgo(14), reason: "OC-451 Alumex", userName: "Luis Compras" },
    { id: "kx4", productId: "e4", type: "salida", quantity: 2, unitCost: 2400, date: daysAgo(1), reason: "Venta FAC-1108", userName: "Ana Ventas" }
  ],
  sales: [
    {
      id: "s1",
      saleNumber: "FAC-1092",
      clientName: "Torre Azul",
      items: [{ productId: "p2", quantity: 6, unitPrice: 420 }],
      subtotal: 2520,
      discountAmount: 126,
      promoCode: "Arranque 5%",
      taxAmount: 359.1,
      total: 2753.1,
      status: "completed",
      saleDate: daysAgo(4),
      createdBy: "Ana Ventas",
      qrPayload: ""
    },
    {
      id: "s2",
      saleNumber: "FAC-1095",
      clientName: "Grupo Hábitat",
      items: [
        { productId: "p1", quantity: 20, unitPrice: 186 },
        { productId: "p4", quantity: 8, unitPrice: 64 }
      ],
      subtotal: 4232,
      discountAmount: 338.56,
      promoCode: "Combo Hogar 8%",
      taxAmount: 584.02,
      total: 4477.46,
      status: "completed",
      saleDate: daysAgo(2),
      createdBy: "Ana Ventas",
      qrPayload: ""
    },
    {
      id: "s3",
      saleNumber: "FAC-1108",
      clientName: "Casa Norte",
      items: [{ productId: "e4", quantity: 2, unitPrice: 3200 }],
      subtotal: 6400,
      discountAmount: 512,
      promoCode: "Combo Hogar 8%",
      taxAmount: 883.2,
      total: 6771.2,
      status: "completed",
      saleDate: daysAgo(1),
      createdBy: "Ana Ventas",
      qrPayload: ""
    },
    {
      id: "s4",
      saleNumber: "FAC-1110",
      clientName: "Plaza Sur",
      items: [
        { productId: "e7", quantity: 1, unitPrice: 16800 },
        { productId: "e12", quantity: 2, unitPrice: 1800 }
      ],
      subtotal: 20400,
      discountAmount: 3060,
      promoCode: "Mega pack 15%",
      taxAmount: 2601,
      total: 19941,
      status: "completed",
      saleDate: daysAgo(0),
      createdBy: "Ana Ventas",
      qrPayload: ""
    }
  ],
  proformas: [
    {
      id: "pf1",
      proformaNumber: "PRF-220",
      clientName: "Residencial Sol",
      items: [
        { productId: "e1", quantity: 1, unitPrice: 18500 },
        { productId: "e2", quantity: 1, unitPrice: 12400 }
      ],
      subtotal: 30900,
      discountAmount: 4635,
      promoCode: "Mega pack 15%",
      taxAmount: 3939.75,
      total: 30204.75,
      status: "enviada",
      validUntil: daysAgo(-12),
      notes: "Pack cocina-lavado. Vigencia 12 días.",
      createdAt: daysAgo(3),
      createdBy: "Ana Ventas",
      qrPayload: ""
    },
    {
      id: "pf2",
      proformaNumber: "PRF-221",
      clientName: "Clínica del Lago",
      items: [{ productId: "e6", quantity: 2, unitPrice: 14900 }],
      subtotal: 29800,
      discountAmount: 4470,
      promoCode: "Mega pack 15%",
      taxAmount: 3799.5,
      total: 29129.5,
      status: "aceptada",
      validUntil: daysAgo(-8),
      notes: "Aires consultorios. Lista para facturar.",
      createdAt: daysAgo(5),
      createdBy: "Ana Ventas",
      qrPayload: ""
    },
    {
      id: "pf3",
      proformaNumber: "PRF-218",
      clientName: "Oficinas Metro",
      items: [{ productId: "p6", quantity: 40, unitPrice: 185 }],
      subtotal: 7400,
      discountAmount: 592,
      promoCode: "Combo Hogar 8%",
      taxAmount: 1021.2,
      total: 7829.2,
      status: "borrador",
      validUntil: daysAgo(-15),
      notes: "Mamparas preliminares.",
      createdAt: daysAgo(1),
      createdBy: "Ana Ventas",
      qrPayload: ""
    }
  ],
  purchases: [
    {
      id: "c1",
      purchaseNumber: "OC-448",
      supplierName: "Alumex",
      items: [{ productId: "p1", quantity: 40, unitPrice: 140 }],
      total: 5600,
      status: "received",
      purchaseDate: daysAgo(7),
      createdBy: "Luis Compras"
    },
    {
      id: "c2",
      purchaseNumber: "OC-451",
      supplierName: "Alumex",
      items: [{ productId: "p5", quantity: 55, unitPrice: 190 }],
      total: 10450,
      status: "received",
      purchaseDate: daysAgo(14),
      createdBy: "Luis Compras"
    },
    {
      id: "c3",
      purchaseNumber: "OC-455",
      supplierName: "Vidrios del Pacífico",
      items: [{ productId: "p2", quantity: 22, unitPrice: 325 }],
      total: 7150,
      status: "received",
      purchaseDate: daysAgo(6),
      createdBy: "Luis Compras"
    },
    {
      id: "c4",
      purchaseNumber: "OC-460",
      supplierName: "Ferretería Central",
      items: [{ productId: "p7", quantity: 10, unitPrice: 210 }],
      total: 2100,
      status: "ordered",
      purchaseDate: daysAgo(1),
      createdBy: "Luis Compras"
    }
  ],
  accounting: [
    { id: "a1", entryNumber: "AS-1001", description: "Venta FAC-1092 Torre Azul", debit: 2898, credit: 2898, debitAccount: "Caja", creditAccount: "Ventas", entryDate: daysAgo(4), referenceType: "sale", referenceId: "s1" },
    { id: "a2", entryNumber: "AS-1002", description: "Compra OC-448 Alumex", debit: 5600, credit: 5600, debitAccount: "Inventario", creditAccount: "Cuentas por pagar", entryDate: daysAgo(7), referenceType: "purchase", referenceId: "c1" },
    { id: "a3", entryNumber: "AS-1003", description: "Venta FAC-1095 Grupo Hábitat", debit: 4866.8, credit: 4866.8, debitAccount: "Caja", creditAccount: "Ventas", entryDate: daysAgo(2), referenceType: "sale", referenceId: "s2" },
    { id: "a4", entryNumber: "AS-1004", description: "Compra OC-451 Alumex", debit: 10450, credit: 10450, debitAccount: "Inventario", creditAccount: "Cuentas por pagar", entryDate: daysAgo(14), referenceType: "purchase", referenceId: "c2" },
    { id: "a5", entryNumber: "AS-1005", description: "Venta FAC-1101 Plaza Sur", debit: 2047, credit: 2047, debitAccount: "Banco", creditAccount: "Ventas", entryDate: daysAgo(0), referenceType: "sale", referenceId: "s4" }
  ],
  finance: [
    { id: "f1", type: "ingreso", category: "Ventas", amount: 2898, date: daysAgo(4), note: "Cobro FAC-1092", userName: "Ana Ventas" },
    { id: "f2", type: "egreso", category: "Materia prima", amount: 5600, date: daysAgo(7), note: "OC Alumex", userName: "Luis Compras" },
    { id: "f3", type: "ingreso", category: "Ventas", amount: 4866.8, date: daysAgo(2), note: "Cobro FAC-1095", userName: "Ana Ventas" },
    { id: "f4", type: "egreso", category: "Materia prima", amount: 10450, date: daysAgo(14), note: "OC-451", userName: "Luis Compras" },
    { id: "f5", type: "ingreso", category: "Instalación", amount: 2047, date: daysAgo(0), note: "Transferencia FAC-1101", userName: "Ana Ventas" },
    { id: "f6", type: "egreso", category: "Servicios", amount: 1850, date: daysAgo(3), note: "Energía taller", userName: "María Contadora" }
  ],
  projections: [
    { id: "pr1", month: "Ene", expectedSales: 980000, expectedCosts: 640000 },
    { id: "pr2", month: "Feb", expectedSales: 1120000, expectedCosts: 710000 },
    { id: "pr3", month: "Mar", expectedSales: 1280000, expectedCosts: 780000 },
    { id: "pr4", month: "Abr", expectedSales: 1540000, expectedCosts: 930000 },
    { id: "pr5", month: "May", expectedSales: 1680000, expectedCosts: 1010000 },
    { id: "pr6", month: "Jun", expectedSales: 1840000, expectedCosts: 1198000 },
    { id: "pr7", month: "Jul", expectedSales: 1920000, expectedCosts: 1210000 },
    { id: "pr8", month: "Ago", expectedSales: 2050000, expectedCosts: 1295000 },
    { id: "pr9", month: "Sep", expectedSales: 2180000, expectedCosts: 1340000 }
  ],
  production: [
    { id: "o1", code: "OT-2048", product: "Ventanas residenciales", client: "Las Palmas", qty: 18, stage: "ensamble", sprint: "Sprint 12", owner: "Carlos Producción" },
    { id: "o2", code: "OT-2049", product: "Fachada modular", client: "Torre Azul", qty: 4, stage: "corte", sprint: "Sprint 12", owner: "Carlos Producción" },
    { id: "o3", code: "OT-2050", product: "Puerta de vidrio", client: "Casa Norte", qty: 2, stage: "backlog", sprint: "Sprint 13", owner: "Taller" },
    { id: "o4", code: "OT-2031", product: "Barandal 12mm", client: "Plaza Sur", qty: 9, stage: "entregado", sprint: "Sprint 11", owner: "Instalación" },
    { id: "o5", code: "OT-2052", product: "Mamparas clínicas", client: "Clínica del Lago", qty: 6, stage: "instalacion", sprint: "Sprint 13", owner: "Instalación" },
    { id: "o6", code: "OT-2053", product: "Mosquiteros balcón", client: "Residencial Sol", qty: 14, stage: "corte", sprint: "Sprint 13", owner: "Carlos Producción" }
  ],
  parties: [
    { id: "cl1", name: "Grupo Hábitat", contact: "Rosa Méndez", phone: "8888-1100", type: "cliente" },
    { id: "cl2", name: "Torre Azul", contact: "Iván Solís", phone: "8777-2211", type: "cliente" },
    { id: "cl3", name: "Casa Norte", contact: "Elena Cruz", phone: "8555-3344", type: "cliente" },
    { id: "cl4", name: "Plaza Sur", contact: "Mario Peña", phone: "8666-7788", type: "cliente" },
    { id: "cl5", name: "Residencial Sol", contact: "Patricia Gómez", phone: "8444-9900", type: "cliente" },
    { id: "cl6", name: "Clínica del Lago", contact: "Dr. Rivas", phone: "8222-1010", type: "cliente" },
    { id: "pv1", name: "Alumex", contact: "Compras Alumex", phone: "2222-4400", type: "proveedor" },
    { id: "pv2", name: "Vidrios del Pacífico", contact: "Karla Ruiz", phone: "2255-9090", type: "proveedor" },
    { id: "pv3", name: "Ferretería Central", contact: "José Duarte", phone: "2277-3311", type: "proveedor" }
  ],
  employees: [
    { id: "e1", name: "Carlos Producción", position: "Supervisor de taller", salary: 18500, area: "Producción" },
    { id: "e2", name: "Ana Ventas", position: "Asesora comercial", salary: 14200, area: "Ventas" },
    { id: "e3", name: "Luis Compras", position: "Comprador", salary: 13800, area: "Compras" },
    { id: "e4", name: "María Contadora", position: "Contadora general", salary: 16800, area: "Contabilidad" },
    { id: "e5", name: "Diego Instalador", position: "Técnico de instalación", salary: 12500, area: "Producción" },
    { id: "e6", name: "Sofía Bodega", position: "Encargada de inventario", salary: 11800, area: "Inventario" }
  ],
  projects: [
    { id: "pj1", code: "PRJ-2048", name: "Residencial Las Palmas", client: "Grupo Hábitat", amount: 486200, progress: 68, state: "Fabricación", owner: "Supervisor" },
    { id: "pj2", code: "PRJ-2055", name: "Fachada Torre Azul", client: "Torre Azul", amount: 312900, progress: 42, state: "Instalación", owner: "Obra" },
    { id: "pj3", code: "PRJ-2060", name: "Barandales Plaza Sur", client: "Plaza Sur", amount: 158400, progress: 90, state: "Cierre", owner: "Instalación" },
    { id: "pj4", code: "PRJ-2062", name: "Mamparas Clínica del Lago", client: "Clínica del Lago", amount: 97400, progress: 55, state: "Instalación", owner: "Obra" }
  ],
  cash: [
    { id: "k1", account: "caja", type: "entrada", amount: 2898, date: daysAgo(4), concept: "Cobro FAC-1092" },
    { id: "k2", account: "banco", type: "salida", amount: 5600, date: daysAgo(7), concept: "Pago OC-448" },
    { id: "k3", account: "caja", type: "entrada", amount: 4866.8, date: daysAgo(2), concept: "Cobro FAC-1095" },
    { id: "k4", account: "banco", type: "entrada", amount: 2047, date: daysAgo(0), concept: "Transferencia FAC-1101" },
    { id: "k5", account: "caja", type: "salida", amount: 1850, date: daysAgo(3), concept: "Energía taller" },
    { id: "k6", account: "banco", type: "salida", amount: 10450, date: daysAgo(14), concept: "Pago OC-451" }
  ],
  users: seedUsers,
  audit: [
    { id: "au1", at: daysAgo(0), userName: "Sistema", action: "inicio", module: "datos", detail: "Base operativa lista." },
    { id: "au2", at: daysAgo(0), userName: "Ana Ventas", action: "venta", module: "ventas", detail: "FAC-1110" },
    { id: "au3", at: daysAgo(1), userName: "Luis Compras", action: "compra", module: "compras", detail: "OC-460 pedida" }
  ]
};

function hydrateQr(db: ErpDatabase): ErpDatabase {
  const names = Object.fromEntries(db.products.map((item) => [item.id, item.name]));
  const lineItems = (items: Sale["items"]) =>
    items.map((item) => ({
      name: names[item.productId] ?? item.productId,
      quantity: item.quantity,
      unitPrice: item.unitPrice
    }));
  return {
    ...db,
    promotions: db.promotions?.length ? db.promotions : catalogPromotions,
    sales: db.sales.map((sale) => ({
      ...sale,
      discountAmount: sale.discountAmount ?? 0,
      qrPayload: buildDocToken({
        kind: "FAC",
        number: sale.saleNumber,
        client: sale.clientName,
        date: sale.saleDate,
        total: sale.total,
        subtotal: sale.subtotal,
        discount: sale.discountAmount ?? 0,
        tax: sale.taxAmount,
        promo: sale.promoCode,
        items: lineItems(sale.items)
      })
    })),
    proformas: (db.proformas ?? []).map((row) => ({
      ...row,
      discountAmount: row.discountAmount ?? 0,
      qrPayload: buildDocToken({
        kind: "PRF",
        number: row.proformaNumber,
        client: row.clientName,
        date: row.createdAt,
        total: row.total,
        subtotal: row.subtotal,
        discount: row.discountAmount ?? 0,
        tax: row.taxAmount,
        promo: row.promoCode,
        items: lineItems(row.items)
      })
    }))
  };
}

const readySeed = hydrateQr(seed);

function loadDb(): ErpDatabase {
  const raw = localStorage.getItem(DB_KEY);
  if (!raw) return readySeed;
  try {
    const parsed = JSON.parse(raw) as ErpDatabase;
    return hydrateQr({
      ...readySeed,
      ...parsed,
      products: parsed.products?.length >= readySeed.products.length ? parsed.products : readySeed.products,
      lots: parsed.lots?.length >= readySeed.lots.length ? parsed.lots : readySeed.lots,
      promotions: parsed.promotions?.length ? parsed.promotions : catalogPromotions,
      proformas: parsed.proformas?.length ? parsed.proformas : readySeed.proformas,
      users: parsed.users?.length ? parsed.users : seedUsers
    });
  } catch {
    return readySeed;
  }
}

type PepsSlice = {
  lotId: string;
  take: number;
  unitCost: number;
  entryDate: string;
  warehouseId: string;
};

type NightlyCloseResult = {
  balanced: boolean;
  salesTotal: number;
  purchasesTotal: number;
  debit: number;
  credit: number;
  message: string;
};

type StoreValue = {
  db: ErpDatabase;
  stockOf: (productId: string) => number;
  previewPeps: (productId: string, qty: number) => PepsSlice[];
  runNightlyClose: (actor: string) => NightlyCloseResult;
  addProduct: (product: Omit<Product, "id" | "createdAt">, actor: string) => void;
  updateProduct: (id: string, patch: Partial<Product>, actor: string) => void;
  deleteProduct: (id: string, actor: string) => void;
  addKardex: (move: Omit<KardexMove, "id">, actor: string) => string | null;
  addSale: (sale: Omit<Sale, "id" | "saleNumber" | "qrPayload">, actor: string) => { error: string | null; sale?: Sale };
  addProforma: (proforma: Omit<Proforma, "id" | "proformaNumber" | "qrPayload" | "createdAt">, actor: string) => Proforma;
  convertProforma: (proformaId: string, actor: string) => { error: string | null; sale?: Sale };
  addPurchase: (purchase: Omit<Purchase, "id" | "purchaseNumber">, actor: string) => void;
  addAccounting: (entry: Omit<AccountingEntry, "id" | "entryNumber">, actor: string) => void;
  addFinance: (move: Omit<FinanceMove, "id">, actor: string) => void;
  upsertProjection: (row: Projection, actor: string) => void;
  moveProduction: (id: string, stage: ProductionOrder["stage"], actor: string) => void;
  addProduction: (order: Omit<ProductionOrder, "id">, actor: string) => void;
  addParty: (party: Omit<Party, "id">, actor: string) => void;
  addEmployee: (employee: Omit<Employee, "id">, actor: string) => void;
  addProject: (project: Omit<Project, "id">, actor: string) => void;
  addCash: (move: Omit<CashMove, "id">, actor: string) => void;
  upsertUser: (user: SessionUser, actor: string) => void;
  log: (event: Omit<AuditEvent, "id" | "at">) => void;
};

const StoreContext = createContext<StoreValue | null>(null);

async function fetchSnapshot(): Promise<ErpDatabase | null> {
  try {
    const response = await fetch("/api/erp/snapshot");
    if (!response.ok) return null;
    const payload = await response.json();
    return payload.snapshot ?? null;
  } catch {
    return null;
  }
}

function persistSnapshot(db: ErpDatabase) {
  void fetch("/api/erp/snapshot", {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ snapshot: db })
  }).catch(() => undefined);
}

export function ErpProvider({ children }: { children: ReactNode }) {
  const [db, setDb] = useState<ErpDatabase>(loadDb);
  const [pgReady, setPgReady] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void fetchSnapshot().then((snapshot) => {
      if (cancelled || !snapshot?.products?.length) {
        setPgReady(true);
        return;
      }
      setDb(hydrateQr(snapshot));
      localStorage.setItem(DB_KEY, JSON.stringify(snapshot));
      setPgReady(true);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    localStorage.setItem(DB_KEY, JSON.stringify(db));
    if (!pgReady) return;
    const timer = window.setTimeout(() => persistSnapshot(db), 700);
    return () => window.clearTimeout(timer);
  }, [db, pgReady]);

  useEffect(() => {
    const refreshQr = () => setDb((prev) => hydrateQr(prev));
    window.addEventListener("raquel-origin-ready", refreshQr);
    refreshQr();
    return () => window.removeEventListener("raquel-origin-ready", refreshQr);
  }, []);

  const log = useCallback((event: Omit<AuditEvent, "id" | "at">) => {
    setDb((prev) => ({
      ...prev,
      audit: [{ id: id("au"), at: now(), ...event }, ...prev.audit].slice(0, 200)
    }));
  }, []);

  const stockOf = useCallback(
    (productId: string) => db.lots.filter((lot) => lot.productId === productId).reduce((sum, lot) => sum + lot.quantity, 0),
    [db.lots]
  );

  const previewPeps = useCallback(
    (productId: string, qty: number): PepsSlice[] => {
      let remaining = qty;
      const slices: PepsSlice[] = [];
      const ordered = [...db.lots]
        .filter((lot) => lot.productId === productId && lot.quantity > 0)
        .sort((a, b) => new Date(a.entryDate).getTime() - new Date(b.entryDate).getTime());
      for (const lot of ordered) {
        if (remaining <= 0) break;
        const take = Math.min(lot.quantity, remaining);
        slices.push({
          lotId: lot.id,
          take,
          unitCost: lot.unitCost,
          entryDate: lot.entryDate,
          warehouseId: lot.warehouseId
        });
        remaining -= take;
      }
      return slices;
    },
    [db.lots]
  );

  const consumePeps = (lots: InventoryLot[], productId: string, qty: number) => {
    let remaining = qty;
    const next = [...lots]
      .map((lot) => ({ ...lot }))
      .sort((a, b) => new Date(a.entryDate).getTime() - new Date(b.entryDate).getTime());
    for (const lot of next.filter((item) => item.productId === productId)) {
      if (remaining <= 0) break;
      const take = Math.min(lot.quantity, remaining);
      lot.quantity -= take;
      remaining -= take;
    }
    return remaining === 0 ? next : null;
  };

  const value = useMemo<StoreValue>(
    () => ({
      db,
      stockOf,
      previewPeps,
      log,
      runNightlyClose: (actor) => {
        const salesTotal = db.sales.filter((item) => item.status === "completed").reduce((sum, item) => sum + item.total, 0);
        const purchasesTotal = db.purchases.filter((item) => item.status === "received").reduce((sum, item) => sum + item.total, 0);
        const debit = db.accounting.reduce((sum, item) => sum + item.debit, 0);
        const credit = db.accounting.reduce((sum, item) => sum + item.credit, 0);
        const balanced = Math.abs(debit - credit) < 0.01;
        const message = balanced
          ? `Cierre OK · ventas C$ ${salesTotal.toFixed(2)} · compras C$ ${purchasesTotal.toFixed(2)} · mayor cuadrado.`
          : `ALERTA descuadre · Débito C$ ${debit.toFixed(2)} ≠ Crédito C$ ${credit.toFixed(2)}.`;
        if (!balanced) {
          const entry: AccountingEntry = {
            id: id("as"),
            entryNumber: `CIERRE-${Date.now().toString().slice(-5)}`,
            description: "Cierre batch RS02 · descuadre detectado",
            debit: Math.abs(debit - credit),
            credit: Math.abs(debit - credit),
            debitAccount: "Descuadre detectado",
            creditAccount: "Pendiente auditoría",
            entryDate: now(),
            referenceType: "manual"
          };
          setDb((prev) => ({ ...prev, accounting: [entry, ...prev.accounting] }));
        }
        log({
          userName: actor,
          action: balanced ? "cierre OK" : "alerta descuadre",
          module: "contabilidad",
          detail: message
        });
        return { balanced, salesTotal, purchasesTotal, debit, credit, message };
      },
      addProduct: (product, actor) => {
        const row = { ...product, id: id("p"), createdAt: now() };
        setDb((prev) => ({ ...prev, products: [...prev.products, row] }));
        log({ userName: actor, action: "crear", module: "datos", detail: `Producto ${row.code}` });
      },
      updateProduct: (productId, patch, actor) => {
        setDb((prev) => ({ ...prev, products: prev.products.map((item) => (item.id === productId ? { ...item, ...patch } : item)) }));
        log({ userName: actor, action: "editar", module: "datos", detail: `Producto ${productId}` });
      },
      deleteProduct: (productId, actor) => {
        setDb((prev) => ({ ...prev, products: prev.products.filter((item) => item.id !== productId) }));
        log({ userName: actor, action: "eliminar", module: "datos", detail: `Producto ${productId}` });
      },
      addKardex: (move, actor) => {
        if (move.type === "salida" && stockOf(move.productId) < move.quantity) return "Stock insuficiente (validación PEPS).";
        setDb((prev) => {
          let lots = prev.lots;
          if (move.type === "entrada") {
            lots = [
              ...lots,
              { id: id("l"), productId: move.productId, quantity: move.quantity, unitCost: move.unitCost, entryDate: move.date, warehouseId: "Bodega central" }
            ];
          } else {
            const consumed = consumePeps(lots, move.productId, move.quantity);
            if (!consumed) return prev;
            lots = consumed;
          }
          return { ...prev, lots, kardex: [{ id: id("kx"), ...move }, ...prev.kardex] };
        });
        log({ userName: actor, action: move.type, module: "inventario", detail: move.reason });
        return null;
      },
      addSale: (sale, actor) => {
        for (const item of sale.items) {
          if (stockOf(item.productId) < item.quantity) return { error: "Stock insuficiente para completar la venta." };
        }
        const saleNumber = `FAC-${Date.now().toString().slice(-6)}`;
        const names = Object.fromEntries(db.products.map((item) => [item.id, item.name]));
        const qrPayload = buildDocToken({
          kind: "FAC",
          number: saleNumber,
          client: sale.clientName,
          date: sale.saleDate,
          total: sale.total,
          subtotal: sale.subtotal,
          discount: sale.discountAmount ?? 0,
          tax: sale.taxAmount,
          promo: sale.promoCode,
          items: sale.items.map((item) => ({
            name: names[item.productId] ?? item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice
          }))
        });
        const row: Sale = { ...sale, discountAmount: sale.discountAmount ?? 0, id: id("s"), saleNumber, qrPayload };
        setDb((prev) => {
          let lots = prev.lots;
          for (const item of sale.items) {
            const consumed = consumePeps(lots, item.productId, item.quantity);
            if (!consumed) return prev;
            lots = consumed;
          }
          const kardex: KardexMove[] = sale.items.map((item) => ({
            id: id("kx"),
            productId: item.productId,
            type: "salida",
            quantity: item.quantity,
            unitCost: item.unitPrice,
            date: sale.saleDate,
            reason: `Venta ${saleNumber}`,
            userName: actor
          }));
          const accounting: AccountingEntry = {
            id: id("as"),
            entryNumber: `AS-${Date.now().toString().slice(-5)}`,
            description: `Venta ${saleNumber} - ${sale.clientName}`,
            debit: sale.total,
            credit: sale.total,
            debitAccount: "Caja",
            creditAccount: "Ventas",
            entryDate: sale.saleDate,
            referenceType: "sale",
            referenceId: row.id
          };
          const finance: FinanceMove = {
            id: id("fn"),
            type: "ingreso",
            category: "Ventas",
            amount: sale.total,
            date: sale.saleDate,
            note: saleNumber,
            userName: actor
          };
          return {
            ...prev,
            lots,
            sales: [row, ...prev.sales],
            kardex: [...kardex, ...prev.kardex],
            accounting: [accounting, ...prev.accounting],
            finance: [finance, ...prev.finance],
            cash: [{ id: id("k"), account: "caja", type: "entrada", amount: sale.total, date: sale.saleDate, concept: saleNumber }, ...prev.cash]
          };
        });
        log({ userName: actor, action: "venta", module: "ventas", detail: saleNumber });
        return { error: null, sale: row };
      },
      addProforma: (proforma, actor) => {
        const proformaNumber = `PRF-${Date.now().toString().slice(-6)}`;
        const createdAt = now();
        const names = Object.fromEntries(db.products.map((item) => [item.id, item.name]));
        const row: Proforma = {
          ...proforma,
          discountAmount: proforma.discountAmount ?? 0,
          id: id("pf"),
          proformaNumber,
          createdAt,
          qrPayload: buildDocToken({
            kind: "PRF",
            number: proformaNumber,
            client: proforma.clientName,
            date: createdAt,
            total: proforma.total,
            subtotal: proforma.subtotal,
            discount: proforma.discountAmount ?? 0,
            tax: proforma.taxAmount,
            promo: proforma.promoCode,
            items: proforma.items.map((item) => ({
              name: names[item.productId] ?? item.productId,
              quantity: item.quantity,
              unitPrice: item.unitPrice
            }))
          })
        };
        setDb((prev) => ({ ...prev, proformas: [row, ...(prev.proformas ?? [])] }));
        log({ userName: actor, action: "proforma", module: "ventas", detail: proformaNumber });
        return row;
      },
      convertProforma: (proformaId, actor) => {
        const proforma = db.proformas.find((item) => item.id === proformaId);
        if (!proforma) return { error: "Proforma no encontrada." };
        if (proforma.status === "convertida") return { error: "Esta proforma ya fue facturada." };
        for (const item of proforma.items) {
          if (stockOf(item.productId) < item.quantity) return { error: "Stock insuficiente para convertir la proforma." };
        }
        const saleNumber = `FAC-${Date.now().toString().slice(-6)}`;
        const saleDate = now();
        const names = Object.fromEntries(db.products.map((item) => [item.id, item.name]));
        const qrPayload = buildDocToken({
          kind: "FAC",
          number: saleNumber,
          client: proforma.clientName,
          date: saleDate,
          total: proforma.total,
          subtotal: proforma.subtotal,
          discount: proforma.discountAmount ?? 0,
          tax: proforma.taxAmount,
          promo: proforma.promoCode,
          items: proforma.items.map((item) => ({
            name: names[item.productId] ?? item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice
          }))
        });
        const row: Sale = {
          id: id("s"),
          saleNumber,
          clientName: proforma.clientName,
          items: proforma.items,
          subtotal: proforma.subtotal,
          discountAmount: proforma.discountAmount ?? 0,
          promoCode: proforma.promoCode,
          taxAmount: proforma.taxAmount,
          total: proforma.total,
          status: "completed",
          saleDate,
          createdBy: actor,
          qrPayload
        };
        setDb((prev) => {
          let lots = prev.lots;
          for (const item of proforma.items) {
            const consumed = consumePeps(lots, item.productId, item.quantity);
            if (!consumed) return prev;
            lots = consumed;
          }
          return {
            ...prev,
            lots,
            sales: [row, ...prev.sales],
            kardex: [
              ...proforma.items.map((item) => ({
                id: id("kx"),
                productId: item.productId,
                type: "salida" as const,
                quantity: item.quantity,
                unitCost: item.unitPrice,
                date: saleDate,
                reason: `Venta ${saleNumber} desde ${proforma.proformaNumber}`,
                userName: actor
              })),
              ...prev.kardex
            ],
            accounting: [
              {
                id: id("as"),
                entryNumber: `AS-${Date.now().toString().slice(-5)}`,
                description: `Venta ${saleNumber} - ${proforma.clientName}`,
                debit: proforma.total,
                credit: proforma.total,
                debitAccount: "Caja",
                creditAccount: "Ventas",
                entryDate: saleDate,
                referenceType: "sale" as const,
                referenceId: row.id
              },
              ...prev.accounting
            ],
            finance: [
              {
                id: id("fn"),
                type: "ingreso" as const,
                category: "Ventas",
                amount: proforma.total,
                date: saleDate,
                note: `${saleNumber} ← ${proforma.proformaNumber}`,
                userName: actor
              },
              ...prev.finance
            ],
            cash: [{ id: id("k"), account: "caja" as const, type: "entrada" as const, amount: proforma.total, date: saleDate, concept: saleNumber }, ...prev.cash],
            proformas: prev.proformas.map((item) =>
              item.id === proformaId ? { ...item, status: "convertida" as const, convertedSaleId: row.id } : item
            )
          };
        });
        log({ userName: actor, action: "convertir proforma", module: "ventas", detail: `${proforma.proformaNumber} → ${saleNumber}` });
        return { error: null, sale: row };
      },
      addPurchase: (purchase, actor) => {
        const purchaseNumber = `OC-${Date.now().toString().slice(-6)}`;
        const row: Purchase = { ...purchase, id: id("oc"), purchaseNumber };
        setDb((prev) => {
          const lots: InventoryLot[] =
            purchase.status === "received"
              ? [
                  ...prev.lots,
                  ...purchase.items.map((item) => ({
                    id: id("l"),
                    productId: item.productId,
                    quantity: item.quantity,
                    unitCost: item.unitPrice,
                    entryDate: purchase.purchaseDate,
                    warehouseId: "Bodega central"
                  }))
                ]
              : prev.lots;
          const accounting: AccountingEntry = {
            id: id("as"),
            entryNumber: `AS-${Date.now().toString().slice(-5)}`,
            description: `Compra ${purchaseNumber} - ${purchase.supplierName}`,
            debit: purchase.total,
            credit: purchase.total,
            debitAccount: "Inventario",
            creditAccount: "Cuentas por pagar",
            entryDate: purchase.purchaseDate,
            referenceType: "purchase",
            referenceId: row.id
          };
          return {
            ...prev,
            lots,
            purchases: [row, ...prev.purchases],
            accounting: purchase.status === "received" ? [accounting, ...prev.accounting] : prev.accounting,
            finance:
              purchase.status === "received"
                ? [{ id: id("fn"), type: "egreso", category: "Compras", amount: purchase.total, date: purchase.purchaseDate, note: purchaseNumber, userName: actor }, ...prev.finance]
                : prev.finance
          };
        });
        log({ userName: actor, action: "compra", module: "compras", detail: purchaseNumber });
      },
      addAccounting: (entry, actor) => {
        const row = { ...entry, id: id("as"), entryNumber: `AS-${Date.now().toString().slice(-5)}` };
        setDb((prev) => ({ ...prev, accounting: [row, ...prev.accounting] }));
        log({ userName: actor, action: "asiento", module: "contabilidad", detail: row.description });
      },
      addFinance: (move, actor) => {
        setDb((prev) => ({ ...prev, finance: [{ id: id("fn"), ...move }, ...prev.finance] }));
        log({ userName: actor, action: move.type, module: "finanzas", detail: move.note });
      },
      upsertProjection: (row, actor) => {
        setDb((prev) => {
          const exists = prev.projections.some((item) => item.id === row.id);
          return { ...prev, projections: exists ? prev.projections.map((item) => (item.id === row.id ? row : item)) : [...prev.projections, row] };
        });
        log({ userName: actor, action: "proyeccion", module: "finanzas", detail: row.month });
      },
      moveProduction: (orderId, stage, actor) => {
        setDb((prev) => ({ ...prev, production: prev.production.map((item) => (item.id === orderId ? { ...item, stage } : item)) }));
        log({ userName: actor, action: "kanban", module: "produccion", detail: `${orderId} → ${stage}` });
      },
      addProduction: (order, actor) => {
        setDb((prev) => ({ ...prev, production: [{ id: id("ot"), ...order }, ...prev.production] }));
        log({ userName: actor, action: "crear OT", module: "produccion", detail: order.code });
      },
      addParty: (party, actor) => {
        setDb((prev) => ({ ...prev, parties: [{ id: id("pt"), ...party }, ...prev.parties] }));
        log({ userName: actor, action: "alta", module: party.type === "cliente" ? "clientes" : "proveedores", detail: party.name });
      },
      addEmployee: (employee, actor) => {
        setDb((prev) => ({ ...prev, employees: [{ id: id("e"), ...employee }, ...prev.employees] }));
        log({ userName: actor, action: "alta", module: "rrhh", detail: employee.name });
      },
      addProject: (project, actor) => {
        setDb((prev) => ({ ...prev, projects: [{ id: id("pj"), ...project }, ...prev.projects] }));
        log({ userName: actor, action: "alta", module: "proyectos", detail: project.name });
      },
      addCash: (move, actor) => {
        setDb((prev) => ({ ...prev, cash: [{ id: id("k"), ...move }, ...prev.cash] }));
        log({ userName: actor, action: move.type, module: move.account === "caja" ? "caja" : "bancos", detail: move.concept });
      },
      upsertUser: (user, actor) => {
        setDb((prev) => {
          const exists = prev.users.some((item) => item.id === user.id);
          return { ...prev, users: exists ? prev.users.map((item) => (item.id === user.id ? user : item)) : [...prev.users, user] };
        });
        log({ userName: actor, action: "usuario", module: "usuarios", detail: user.email });
      }
    }),
    [db, log, stockOf, previewPeps]
  );

  return <StoreContext.Provider value={value}>{children}</StoreContext.Provider>;
}

export function useErp() {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error("useErp debe usarse dentro de ErpProvider");
  return ctx;
}

import {emptyDatabase, normalizeErpState as mergeDb} from '../lib/normalizeErpState';
import { allocateInventory } from '../lib/inventoryAllocation';
import { createSnapshotQueue } from '../lib/snapshotQueue';
import { getApiBaseUrl } from '../lib/apiBase';
import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { eventFingerprint, GENESIS, inferSeverity } from "../lib/auditSeal";
import { buildDocToken } from "../lib/invoiceDoc";
import { authenticatedFetch, getAuthToken } from "../auth/apiSession";
import type {
  AccountingEntry,
  AuditEvent,
  CashMove,
  CatalogAlbum,
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

const DB_KEY = "raquel_erp_db_v7";
const API_URL = getApiBaseUrl();

const now = () => new Date().toISOString();
const id = (prefix: string) => `${prefix}-${globalThis.crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random().toString(36).slice(2, 12)}`}`;

function loadDb(): ErpDatabase {
  try { const raw = localStorage.getItem(DB_KEY); return raw ? mergeDb(JSON.parse(raw)) : emptyDatabase; }
  catch { return emptyDatabase; }
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
  syncStatus: "loading" | "connected" | "offline" | "conflict";
  saving: boolean;
  syncError: string | null;
  reloadState: () => void;
  stockOf: (productId: string) => number;
  previewPeps: (productId: string, qty: number) => PepsSlice[];
  runNightlyClose: (actor: string) => NightlyCloseResult;
  addProduct: (product: Omit<Product, "id" | "createdAt">, actor: string) => void;
  updateProduct: (id: string, patch: Partial<Product>, actor: string) => void;
  deleteProduct: (id: string, actor: string) => boolean;
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
  saveParty: (party: Partial<Party> & { name: string; type: Party["type"] }, actor: string) => Promise<{ error?: string; saved?: boolean }>;
  addEmployee: (employee: Omit<Employee, "id">, actor: string) => void;
  payPayroll: (period: string, actor: string) => { error: string | null; net?: number };
  publishAlbum: (album: Omit<CatalogAlbum, "id" | "createdAt">, actor: string) => CatalogAlbum;
  addProject: (project: Omit<Project, "id">, actor: string) => void;
  addCash: (move: Omit<CashMove, "id">, actor: string) => void;
  upsertUser: (user: SessionUser, actor: string) => void;
  log: (event: Omit<AuditEvent, "id" | "at" | "hash" | "prevHash">) => void;
};

const StoreContext = createContext<StoreValue | null>(null);

export function ErpProvider({ children }: { children: ReactNode }) {
  const [db, setDb] = useState<ErpDatabase>(loadDb);
  const [syncStatus, setSyncStatus] = useState<StoreValue["syncStatus"]>("loading");
  // Revisión (rowversion) del estado en SQL Server: el guardado exige que siga
  // siendo la misma para no sobrescribir cambios de otra sesión (OCC).
  const revisionRef = useRef<string | null>(null);
  const synchronizedDbRef = useRef<ErpDatabase | null>(null);
  const [sessionToken, setSessionToken] = useState(getAuthToken);
  const [saving, setSaving] = useState(false);
  const [syncError, setSyncError] = useState<string | null>(null);
  const [reloadGeneration, setReloadGeneration] = useState(0);
  const saveQueue = useRef<ReturnType<typeof createSnapshotQueue<ErpDatabase>> | null>(null);
  const reloadState = useCallback(() => setReloadGeneration(value => value + 1), []);

  useEffect(() => {
    const updateSession = () => setSessionToken(getAuthToken());
    window.addEventListener("raquel-auth-changed", updateSession);
    window.addEventListener("storage", updateSession);
    return () => {
      window.removeEventListener("raquel-auth-changed", updateSession);
      window.removeEventListener("storage", updateSession);
    };
  }, []);

  useEffect(() => {
    try { localStorage.setItem(DB_KEY, JSON.stringify({...db, users: db.users.map(({password: _password, ...user}) => user)})); } catch { /* SQL remains authoritative if browser storage is full. */ }
  }, [db]);

  useEffect(() => {
    const controller = new AbortController();
    saveQueue.current?.stop();
    saveQueue.current = null;
    setSaving(false);
    setSyncError(null);
    revisionRef.current = null;
    synchronizedDbRef.current = null;
    if (!sessionToken) {
      // Sin sesión válida no se consulta el estado (requiere autenticación).
      setSyncStatus("offline");
      return () => controller.abort();
    }

    setSyncStatus("loading");
    authenticatedFetch(`${API_URL}/api/state`, { signal: controller.signal })
      .then(async (response) => {
        if (!response.ok) throw new Error(`Carga SQL Server: HTTP ${response.status}`);
        return response.json() as Promise<{ state?: Partial<ErpDatabase> | null; revision?: string | null }>;
      })
      .then(({ state, revision }) => {
        if (!state || !revision) throw Error('SQL no devolvió un estado global y una revisión verificables. No se inicializan datos de ejemplo ni se sobrescriben tablas. Revisa la integración de la base.');
        revisionRef.current = revision ?? null;
        setDb((current) => {
          const loaded = state ? mergeDb(state) : emptyDatabase;
          synchronizedDbRef.current = loaded;
          return loaded;
        });
        saveQueue.current = createSnapshotQueue<ErpDatabase>({
          pending: () => setSaving(true),
          save: async (snapshot) => {
            if (getAuthToken() !== sessionToken) throw Error('La sesión cambió. No se envían cambios pendientes con otra cuenta.');
            const state = {...snapshot, users: snapshot.users.map(({password: _password, ...user}) => user)};
            const response = await authenticatedFetch(API_URL + '/api/state', {method: 'PUT', headers: {'Content-Type':'application/json'}, body: JSON.stringify({state, expectedRevision: revisionRef.current})});
            const body = await response.json().catch(() => ({}));
            if (!response.ok) throw Object.assign(new Error(body.message || 'Guardado SQL: HTTP ' + response.status), {status: response.status});
            if (body.saved !== true || typeof body.revision !== 'string' || !/^0x[0-9a-f]{16}$/i.test(body.revision)) throw Error('Confirmación de guardado incierta. Consulta SQL antes de repetir.');
            if (!controller.signal.aborted) revisionRef.current = body.revision;
          },
          saved: (snapshot) => { if (!controller.signal.aborted) { synchronizedDbRef.current = snapshot; setSaving(false); } },
          failed: (error) => {
            if (controller.signal.aborted) return;
            setSaving(false);
            setSyncError(error instanceof Error ? error.message : String(error));
            setSyncStatus([409,428].includes((error as {status?:number})?.status ?? 0) ? 'conflict' : 'offline');
          }
        });
        setSyncStatus("connected");
      })
      .catch((error: unknown) => {
        if (!controller.signal.aborted) {
          console.error("No se pudo cargar el estado desde SQL Server.", error);
          setSyncError(error instanceof Error ? error.message : String(error));
          setSyncStatus("offline");
        }
      });
    return () => { controller.abort(); saveQueue.current?.stop(); };
  }, [sessionToken, reloadGeneration]);

  useEffect(() => {
    if (syncStatus === 'connected' && synchronizedDbRef.current !== db) saveQueue.current?.enqueue(db);
  }, [db, syncStatus]);
  useEffect(() => {
    const warn = (event: BeforeUnloadEvent) => {
      if (synchronizedDbRef.current && synchronizedDbRef.current !== db) { event.preventDefault(); event.returnValue = ''; }
    };
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [db]);

  const log = useCallback((event: Omit<AuditEvent, "id" | "at" | "hash" | "prevHash">) => {
    setDb((prev) => {
      const at = now();
      const prevHash = prev.audit[0]?.hash ?? GENESIS;
      const payload = { id: id("au"), at, ...event, severity: event.severity ?? inferSeverity(event.action) };
      return {
        ...prev,
        audit: [
          { ...payload, prevHash, hash: eventFingerprint(payload, prevHash) },
          ...prev.audit
        ].slice(0, 200)
      };
    });
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
      syncStatus, saving: saving || (syncStatus === "connected" && synchronizedDbRef.current !== db), syncError, reloadState,
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
        const isReferenced = db.lots.some((item) => item.productId === productId)
          || db.kardex.some((item) => item.productId === productId)
          || db.sales.some((sale) => sale.items.some((item) => item.productId === productId))
          || db.proformas.some((proforma) => proforma.items.some((item) => item.productId === productId))
          || db.purchases.some((purchase) => purchase.items.some((item) => item.productId === productId))
          || db.albums.some((album) => album.productIds.includes(productId));
        if (isReferenced) return false;

        setDb((prev) => ({ ...prev, products: prev.products.filter((item) => item.id !== productId) }));
        log({ userName: actor, action: "eliminar", module: "datos", detail: `Producto ${productId}` });
        return true;
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
        if (!allocateInventory(db.lots, sale.items)) return { error: 'Cantidad inválida o stock insuficiente para el total del documento.' };
        const saleNumber = id("FAC");
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
          const allocation = allocateInventory(prev.lots, sale.items);
          if (!allocation) return prev;
          const lots = allocation.lots;
          const kardex: KardexMove[] = sale.items.map((item) => ({
            id: id("kx"),
            productId: item.productId,
            type: "salida",
            quantity: item.quantity,
            unitCost: allocation.unitCosts.get(item.productId) ?? 0,
            date: sale.saleDate,
            reason: `Venta ${saleNumber}`,
            userName: actor
          }));
          const accounting: AccountingEntry = {
            id: id("as"),
            entryNumber: id("AS"),
            description: `Venta ${saleNumber} - ${sale.clientName}`,
            debit: sale.total,
            credit: sale.total,
            debitAccount: "Cuentas por cobrar",
            creditAccount: "Ventas",
            entryDate: sale.saleDate,
            referenceType: "sale",
            referenceId: row.id
          };
          return {
            ...prev,
            lots,
            sales: [row, ...prev.sales],
            kardex: [...kardex, ...prev.kardex],
            accounting: [accounting, ...prev.accounting],
            finance: prev.finance,
            cash: prev.cash
          };
        });
        log({ userName: actor, action: "venta", module: "ventas", detail: saleNumber, reference: saleNumber, uml: "Secuencia RF08 / RF20" });
        return { error: null, sale: row };
      },
      addProforma: (proforma, actor) => {
        const proformaNumber = id("PRF");
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
        if (!allocateInventory(db.lots, proforma.items)) return { error: 'Cantidad inválida o stock insuficiente para el total del documento.' };
        const saleNumber = id("FAC");
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
          const allocation = allocateInventory(prev.lots, proforma.items);
          if (!allocation) return prev;
          const lots = allocation.lots;
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
                unitCost: allocation.unitCosts.get(item.productId) ?? 0,
                date: saleDate,
                reason: `Venta ${saleNumber} desde ${proforma.proformaNumber}`,
                userName: actor
              })),
              ...prev.kardex
            ],
            accounting: [
              {
                id: id("as"),
                entryNumber: id("AS"),
                description: `Venta ${saleNumber} - ${proforma.clientName}`,
                debit: proforma.total,
                credit: proforma.total,
                debitAccount: "Cuentas por cobrar",
                creditAccount: "Ventas",
                entryDate: saleDate,
                referenceType: "sale" as const,
                referenceId: row.id
              },
              ...prev.accounting
            ],
            finance: prev.finance, cash: prev.cash,
            proformas: prev.proformas.map((item) =>
              item.id === proformaId ? { ...item, status: "convertida" as const, convertedSaleId: row.id } : item
            )
          };
        });
        log({ userName: actor, action: "convertir proforma", module: "ventas", detail: `${proforma.proformaNumber} → ${saleNumber}` });
        return { error: null, sale: row };
      },
      addPurchase: (purchase, actor) => {
        const purchaseNumber = id("OC");
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
            entryNumber: id("AS"),
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
            kardex: purchase.status === "received" ? [...purchase.items.map(item => ({id: id("kx"), productId: item.productId, type: "entrada" as const, quantity: item.quantity, unitCost: item.unitPrice, date: purchase.purchaseDate, reason: `Recepción ${purchaseNumber}`, userName: actor})), ...prev.kardex] : prev.kardex,
            accounting: purchase.status === "received" ? [accounting, ...prev.accounting] : prev.accounting,
            // Recibir inventario crea una obligacion; el egreso nace al confirmar el pago.
            finance: prev.finance
          };
        });
        log({ userName: actor, action: "compra", module: "compras", detail: purchaseNumber, reference: purchaseNumber, uml: "Actividad RF07" });
      },
      addAccounting: (entry, actor) => {
        const row = { ...entry, id: id("as"), entryNumber: id("AS") };
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
        log({ userName: actor, action: "kanban", module: "produccion", detail: `${orderId} → ${stage}`, reference: orderId, uml: "Estados RF11" });
      },
      addProduction: (order, actor) => {
        setDb((prev) => ({ ...prev, production: [{ id: id("ot"), ...order }, ...prev.production] }));
        log({ userName: actor, action: "crear OT", module: "produccion", detail: order.code });
      },
      addParty: (party, actor) => {
        setDb((prev) => ({ ...prev, parties: [{ id: id("pt"), ...party }, ...prev.parties] }));
        log({ userName: actor, action: "alta", module: party.type === "cliente" ? "clientes" : "proveedores", detail: party.name });
      },
      saveParty: async (party, actor) => {
        if (party.id) {
          setDb((prev) => ({
            ...prev,
            parties: prev.parties.map((p) => (p.id === party.id ? ({ ...p, ...party } as Party) : p))
          }));
          log({ userName: actor, action: "modificacion", module: party.type === "cliente" ? "clientes" : "proveedores", detail: party.name });
        } else {
          setDb((prev) => ({
            ...prev,
            parties: [{ id: id("pt"), ...party } as Party, ...prev.parties]
          }));
          log({ userName: actor, action: "alta", module: party.type === "cliente" ? "clientes" : "proveedores", detail: party.name });
        }
        return { saved: true };
      },
      addEmployee: (employee, actor) => {
        setDb((prev) => ({ ...prev, employees: [{ id: id("e"), ...employee }, ...prev.employees] }));
        log({ userName: actor, action: "alta", module: "rrhh", detail: employee.name });
      },
      payPayroll: () => ({
        error: "El pago requiere cálculo y aprobación del servidor. Regístralo en Nómina → Pagos; sin conexión no se confirma ni se crea un egreso local."
      }),
      publishAlbum: (album, actor) => {
        const row: CatalogAlbum = { ...album, id: id("al"), createdAt: now() };
        setDb((prev) => {
          const exists = prev.albums.some((item) => item.month === album.month);
          return {
            ...prev,
            albums: exists
              ? prev.albums.map((item) => (item.month === album.month ? { ...item, ...album } : item))
              : [row, ...prev.albums]
          };
        });
        log({ userName: actor, action: "álbum", module: "mercadotecnia", detail: `${album.month} ${album.title}` });
        return row;
      },
      addProject: (project, actor) => {
        setDb((prev) => ({ ...prev, projects: [{ id: id("pj"), ...project }, ...prev.projects] }));
        log({ userName: actor, action: "alta", module: "proyectos", detail: project.name });
      },
      addCash: () => {
        throw new Error("Registra movimientos en Caja/Bancos mediante el servidor. Sin confirmación SQL no se crea un movimiento local.");
      },
      upsertUser: (user, actor) => {
        setDb((prev) => {
          const exists = prev.users.some((item) => item.id === user.id);
          return { ...prev, users: exists ? prev.users.map((item) => (item.id === user.id ? user : item)) : [...prev.users, user] };
        });
        log({ userName: actor, action: "usuario", module: "usuarios", detail: user.email });
      }
    }),
    [db, log, stockOf, previewPeps, syncStatus, saving, syncError, reloadState]
  );

  return <StoreContext.Provider value={value}>{children}</StoreContext.Provider>;
}

export function useErp() {
  const ctx = useContext(StoreContext);
  if (!ctx) throw new Error("useErp debe usarse dentro de ErpProvider");
  return ctx;
}

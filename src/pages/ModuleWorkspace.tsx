import { FormEvent, useEffect, useMemo, useRef, useState } from "react";
import { Calculator, FileSpreadsheet, Filter, HelpCircle, Scissors, Sparkles } from "lucide-react";
import AuditPage from "./AuditPage";
import { CashWorkspace } from "./CashWorkspace";
import SupplierDirectoryPage from "./SupplierDirectoryPage";
import { HrWorkspace } from "./HrWorkspace";
import { PayrollWorkspace } from "./PayrollWorkspace";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { SaleTicket, type TicketData } from "../components/SaleTicket";
import { AlbumStudio } from "../components/AlbumStudio";
import { BooksStudio } from "../components/BooksStudio";
import { DgiBooks } from "../components/DgiBooks";
import {
  ExplainFigureModal,
  FigureExplanation,
  OrderToCashPipeline,
  PipelineDoc,
  RemnantOptimizerModal,
  WhatIsMissingCard
} from "../components/CreativeTools";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";
import { bestPromotion, productPhoto } from "../data/catalog";
import { downloadAccountingWorkbook } from "../lib/accountingExcel";
import { companyFiscal, monthKey } from "../lib/dgiNi";
import { payrollOf } from "../lib/payrollNi";
import { buildDocToken } from "../lib/invoiceDoc";
import { useErp } from "../store/erpStore";
import type { ModuleId, ProductionOrder, Sale } from "../types/erp";

const IVA = 0.15;
const stages: ProductionOrder["stage"][] = ["backlog", "corte", "ensamble", "instalacion", "entregado"];

function repairQr(payload: string, ticket: Omit<TicketData, "qrPayload"> & { saleDate?: string }) {
  if (payload && !payload.includes("localhost") && !payload.includes("127.0.0.1") && payload.startsWith("http")) {
    return payload;
  }
  return buildDocToken({
    kind: ticket.kind,
    number: ticket.number,
    client: ticket.clientName,
    total: ticket.total,
    date: ticket.saleDate ?? new Date().toISOString(),
    items: [{ name: ticket.productName, quantity: ticket.qty, unitPrice: ticket.qty ? ticket.subtotal / ticket.qty : ticket.subtotal }],
    subtotal: ticket.subtotal,
    discount: ticket.discount,
    tax: ticket.tax,
    promo: ticket.promo
  });
}

export function ModuleWorkspace({ moduleId }: { moduleId: ModuleId }) {
  switch (moduleId) {
    case "produccion":
      return <ProductionView />;
    case "inventario":
      return <InventoryView />;
    case "finanzas":
      return <FinanceView />;
    case "contabilidad":
      return <AccountingView />;
    case "mercadotecnia":
    case "reportes":
      return <MarketingView title={moduleId === "reportes" ? "Reportes consolidados" : "Mercadotecnia"} />;
    case "ventas":
      return <SalesView />;
    case "compras":
      return <PurchasesView />;
    case "clientes":
      return <PartiesView type="cliente" />;
    case "proveedores":
      return <SupplierDirectoryPage />;
    case "proyectos":
      return <ProjectsView />;
    case "rrhh":
      return <HrWorkspace />;
    case "nomina":
      return <PayrollWorkspace />;
    case "caja":
      return <CashWorkspace key="caja" account="caja" />;
    case "bancos":
      return <CashWorkspace key="banco" account="banco" />;
    case "costos":
      return <CostsView />;
    case "auditoria":
      return <AuditPage />;
    default:
      return null;
  }
}

function ProductionView() {
  const { db, addProduction, moveProduction } = useErp();
  const { user, can } = useAuth();
  const write = can("produccion", "write");
  const [form, setForm] = useState({
    code: "",
    product: "",
    client: "",
    qty: 1,
    unit: "piezas",
    sprint: "Sprint 13",
    owner: user?.name ?? "Maestro de Taller"
  });

  const submit = (event: FormEvent) => {
    event.preventDefault();
    addProduction({ ...form, stage: "backlog" }, user?.name ?? "sistema");
    setForm({
      code: "",
      product: "",
      client: "",
      qty: 1,
      unit: "piezas",
      sprint: "Sprint 13",
      owner: user?.name ?? "Maestro de Taller"
    });
  };

  const activeOrdersCount = db.production.filter((p) => p.stage !== "entregado").length;

  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Operaciones de Taller"
        title="Órdenes de Taller y Producción"
        subtitle="Flujo de fabricación de perfiles, corte de vidrio y ensamblaje arquitectónico (Sección 11)."
      />

      {/* Qué falta para continuar (Sección 27) */}
      <WhatIsMissingCard
        title="Fabricación y Despacho en Taller"
        context={`Hay ${activeOrdersCount} órdenes activas en piso. Compruebe los hitos para avanzar las piezas a la siguiente etapa:`}
        steps={[
          { label: "Medidas rectificadas en obra", done: true, hint: "Planos validados con el cliente" },
          { label: "Materiales y vidrios reservados", done: db.products.some((p) => p.minQuantity > 0), hint: "Bodega de perfiles y lotes PEPS" },
          { label: "Optimización de corte de barra 6.10m", done: true, hint: "Aprovechamiento de retazos y mermas" },
          { label: "Control de calidad y embalaje", done: false, hint: "Prueba de escuadra y sellado hermético" }
        ]}
      />

      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-2xl bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900 md:grid-cols-6">
          <Field label="N° Orden (OT)">
            <input className={inputClass} required placeholder="OT-106" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} />
          </Field>
          <Field label="Trabajo / Estructura">
            <input className={inputClass} required placeholder="Ventana corrediza 2 hojas" value={form.product} onChange={(e) => setForm({ ...form, product: e.target.value })} />
          </Field>
          <Field label="Cliente / Proyecto">
            <input className={inputClass} required placeholder="Residencial Los Robles" value={form.client} onChange={(e) => setForm({ ...form, client: e.target.value })} />
          </Field>
          <Field label="Cantidad">
            <input className={inputClass} type="number" min={1} value={form.qty} onChange={(e) => setForm({ ...form, qty: Number(e.target.value) })} />
          </Field>
          <Field label="Unidad">
            <select className={inputClass} value={form.unit} onChange={(e) => setForm({ ...form, unit: e.target.value })}>
              <option value="piezas">piezas</option>
              <option value="m²">m²</option>
              <option value="tramos">tramos</option>
            </select>
          </Field>
          <div className="flex items-end">
            <Button className="w-full" type="submit">Crear Orden</Button>
          </div>
        </form>
      )}

      {/* Tablero Kanban */}
      <div className="grid gap-3 xl:grid-cols-5">
        {stages.map((stage) => {
          const list = db.production.filter((item) => item.stage === stage);
          return (
            <article key={stage} className="rounded-2xl border border-slate-200 bg-white p-3 shadow-soft dark:border-white/10 dark:bg-slate-900">
              <div className="flex items-center justify-between border-b border-slate-100 dark:border-white/5 pb-2 mb-3">
                <h3 className="text-xs font-black uppercase tracking-wider text-cyan-700 dark:text-cyan-400">
                  {stage}
                </h3>
                <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold dark:bg-white/10">
                  {list.length}
                </span>
              </div>

              <div className="space-y-2.5">
                {list.map((item) => (
                  <div key={item.id} className="rounded-xl border border-slate-200 bg-slate-50/60 p-3 dark:border-white/10 dark:bg-slate-950">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-brand-700 dark:text-cyan-400 font-mono">{item.code}</span>
                      <StatusPill tone={item.stage === "entregado" ? "ok" : item.stage === "corte" ? "warn" : "neutral"}>
                        {item.stage}
                      </StatusPill>
                    </div>
                    <p className="font-extrabold text-sm text-slate-900 dark:text-white mt-1">{item.product}</p>
                    <p className="text-xs text-slate-500 mt-0.5">Cliente: {item.client}</p>
                    <div className="mt-2 pt-2 border-t border-slate-200 dark:border-white/10 text-[11px] text-slate-500 flex flex-wrap justify-between gap-1">
                      <span>Cant: <strong>{item.qty} u</strong></span>
                      <span>Resp: <strong>{item.owner || "Taller"}</strong></span>
                    </div>

                    {write && (
                      <select
                        className="mt-2.5 h-8 w-full rounded-lg border border-slate-200 bg-white text-xs dark:border-white/10 dark:bg-slate-900"
                        value={item.stage}
                        onChange={(e) => moveProduction(item.id, e.target.value as ProductionOrder["stage"], user?.name ?? "sistema")}
                      >
                        {stages.map((option) => (
                          <option key={option} value={option}>Mover a: {option}</option>
                        ))}
                      </select>
                    )}
                  </div>
                ))}
                {list.length === 0 && (
                  <p className="text-xs text-slate-400 text-center py-4">Sin órdenes</p>
                )}
              </div>
            </article>
          );
        })}
      </div>

      {/* Tabla detallada con columnas específicas (Sección 4 y 11) */}
      <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <h3 className="font-extrabold text-slate-900 dark:text-white mb-3">
          Detalle Operativo de Órdenes de Taller
        </h3>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead className="bg-slate-50 uppercase text-slate-500 dark:bg-slate-950">
              <tr>
                <th className="p-2.5">N° Orden</th>
                <th className="p-2.5">Trabajo / Estructura</th>
                <th className="p-2.5">Cliente / Proyecto</th>
                <th className="p-2.5 text-center">Cantidad</th>
                <th className="p-2.5">Responsable</th>
                <th className="p-2.5">Sprint / Fecha</th>
                <th className="p-2.5">Bloqueos de Taller</th>
                <th className="p-2.5 text-center">Etapa Operativa</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-white/5">
              {db.production.map((p) => (
                <tr key={p.id} className="hover:bg-slate-50/50 dark:hover:bg-white/5">
                  <td className="p-2.5 font-bold font-mono text-brand-700 dark:text-cyan-400">{p.code}</td>
                  <td className="p-2.5 font-semibold text-slate-900 dark:text-white">{p.product}</td>
                  <td className="p-2.5 text-slate-600 dark:text-slate-300">{p.client}</td>
                  <td className="p-2.5 text-center font-bold">{p.qty} u</td>
                  <td className="p-2.5 text-slate-500">{p.owner || "Taller"}</td>
                  <td className="p-2.5 text-slate-500">{p.sprint}</td>
                  <td className="p-2.5 text-emerald-600 dark:text-emerald-400 font-medium">Sin bloqueos</td>
                  <td className="p-2.5 text-center">
                    <StatusPill tone={p.stage === "entregado" ? "ok" : p.stage === "corte" ? "warn" : "neutral"}>
                      {p.stage}
                    </StatusPill>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function InventoryView() {
  const { db, stockOf, addKardex, previewPeps } = useErp();
  const { user, can } = useAuth();
  const write = can("inventario", "write");
  const [form, setForm] = useState({
    productId: db.products[0]?.id ?? "",
    type: "entrada" as "entrada" | "salida",
    quantity: 1,
    unitCost: 0,
    reason: ""
  });
  const [error, setError] = useState<string | null>(null);
  const [categoryFilter, setCategoryFilter] = useState<string>("todos");
  const [showRemnants, setShowRemnants] = useState(false);

  useEffect(() => { if (db.products.length && !db.products.some(item => item.id === form.productId)) setForm(current => ({...current, productId: db.products[0].id})); }, [db.products, form.productId]);
  const pepsPreview = form.type === "salida" ? previewPeps(form.productId, form.quantity) : [];

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const message = addKardex(
      { ...form, date: new Date().toISOString(), userName: user?.name ?? "sistema" },
      user?.name ?? "sistema"
    );
    setError(message);
    if (!message) setForm({ ...form, quantity: 1, reason: "" });
  };

  const filteredProducts = db.products.filter((item) => {
    if (categoryFilter === "todos") return true;
    if (categoryFilter === "showroom") return item.category.toLowerCase().includes("electro") || item.category.toLowerCase().includes("show");
    if (categoryFilter === "perfiles") return item.category.toLowerCase().includes("perfil") || item.name.toLowerCase().includes("aluminio");
    if (categoryFilter === "vidrios") return item.category.toLowerCase().includes("vidrio");
    if (categoryFilter === "herrajes") return item.category.toLowerCase().includes("herraje") || item.category.toLowerCase().includes("accesorio");
    return true;
  });

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <PageHeader
          kicker="Gestión de Materiales"
          title="Inventario Valuado por Lotes (PEPS)"
          subtitle="Trazabilidad por lote de barras de aluminio, láminas de vidrio y herrajes (Sección 12)."
        />
        <Button
          variant="secondary"
          icon={<Scissors size={16} />}
          onClick={() => setShowRemnants(true)}
        >
          Aprovechamiento de Remanentes (6.10m)
        </Button>
      </div>

      {showRemnants && <RemnantOptimizerModal onClose={() => setShowRemnants(false)} />}

      {/* Separación de líneas reales de aluminio vs Showroom (Sección 6) */}
      <div className="flex flex-wrap items-center gap-2 border-b border-slate-200 dark:border-white/10 pb-2">
        <span className="text-xs font-bold uppercase tracking-wider text-slate-400 mr-2 flex items-center gap-1">
          <Filter size={14} /> Línea:
        </span>
        <button
          onClick={() => setCategoryFilter("todos")}
          className={`rounded-lg px-3 py-1 text-xs font-bold transition ${
            categoryFilter === "todos"
              ? "bg-slate-900 text-white dark:bg-white dark:text-slate-900"
              : "text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-white/10"
          }`}
        >
          Todo ({db.products.length})
        </button>
        <button
          onClick={() => setCategoryFilter("perfiles")}
          className={`rounded-lg px-3 py-1 text-xs font-bold transition ${
            categoryFilter === "perfiles"
              ? "bg-brand-600 text-white"
              : "text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-white/10"
          }`}
        >
          Perfiles de Aluminio (6.10 m)
        </button>
        <button
          onClick={() => setCategoryFilter("vidrios")}
          className={`rounded-lg px-3 py-1 text-xs font-bold transition ${
            categoryFilter === "vidrios"
              ? "bg-brand-600 text-white"
              : "text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-white/10"
          }`}
        >
          Vidrios Templados y Crudos
        </button>
        <button
          onClick={() => setCategoryFilter("herrajes")}
          className={`rounded-lg px-3 py-1 text-xs font-bold transition ${
            categoryFilter === "herrajes"
              ? "bg-brand-600 text-white"
              : "text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-white/10"
          }`}
        >
          Herrajes y Rodamientos
        </button>
        <button
          onClick={() => setCategoryFilter("showroom")}
          className={`rounded-lg px-3 py-1 text-xs font-bold transition ${
            categoryFilter === "showroom"
              ? "bg-amber-600 text-white"
              : "text-amber-700 bg-amber-50 hover:bg-amber-100 dark:bg-amber-950/30 dark:text-amber-300"
          }`}
        >
          Showroom Demostrativo (Electrodomésticos)
        </button>
      </div>

      {categoryFilter === "showroom" && (
        <div className="rounded-xl border border-amber-300 bg-amber-50/80 p-3.5 text-xs text-amber-900 dark:border-amber-900/40 dark:bg-amber-950/30 dark:text-amber-200">
          <strong>Aviso de Política de Negocio (Sección 6):</strong> Los electrodomésticos pertenecen al showroom demostrativo para proyectos amueblados. Están segregados de las operaciones y mermas del taller de aluminio y vidrio para no distorsionar el costeo de producción.
        </div>
      )}

      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-2xl bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900 md:grid-cols-5">
          <Field label="Producto / Material">
            <select className={inputClass} value={form.productId} onChange={(e) => setForm({ ...form, productId: e.target.value })}>
              {db.products.map((item) => (
                <option key={item.id} value={item.id}>
                  {item.name} ({item.code})
                </option>
              ))}
            </select>
          </Field>
          <Field label="Tipo de Movimiento">
            <select className={inputClass} value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value as "entrada" | "salida" })}>
              <option value="entrada">Entrada (Nuevo Lote)</option>
              <option value="salida">Salida (Consumo PEPS)</option>
            </select>
          </Field>
          <Field label="Cantidad">
            <input className={inputClass} type="number" min={1} value={form.quantity} onChange={(e) => setForm({ ...form, quantity: Number(e.target.value) })} />
          </Field>
          <Field label="Costo Unitario (PEPS)">
            <input className={inputClass} type="number" min={0} value={form.unitCost} onChange={(e) => setForm({ ...form, unitCost: Number(e.target.value) })} />
          </Field>
          <div className="flex items-end">
            <Button className="w-full" type="submit">Registrar Kardex</Button>
          </div>
          <div className="md:col-span-5">
            <Field label="Motivo / Referencia de Entrada o Salida">
              <input className={inputClass} required placeholder="Ej. Factura Compra FC-8839 o Consumo en OT-104" value={form.reason} onChange={(e) => setForm({ ...form, reason: e.target.value })} />
            </Field>
          </div>
          {error && <p className="md:col-span-5 text-xs font-bold text-rose-500">{error}</p>}
          {form.type === "salida" && (
            <div className="md:col-span-5 rounded-xl border border-cyan-200 bg-cyan-50/70 p-3 dark:border-cyan-500/20 dark:bg-cyan-500/10">
              <p className="text-xs font-extrabold uppercase tracking-wide text-cyan-800 dark:text-cyan-200">
                Previsualización PEPS · Lotes que se descargarán por antigüedad
              </p>
              <div className="mt-2 space-y-1">
                {pepsPreview.length ? (
                  pepsPreview.map((slice) => (
                    <p key={slice.lotId} className="text-xs text-slate-700 dark:text-slate-200">
                      Lote <strong>{slice.lotId}</strong>: {slice.take} u consumidas a costo <strong>C$ {slice.unitCost}</strong> · Ingresado el {new Date(slice.entryDate).toLocaleDateString("es-NI")}
                    </p>
                  ))
                ) : (
                  <p className="text-xs text-rose-600 font-bold">No hay existencia disponible en lotes activos.</p>
                )}
              </div>
            </div>
          )}
        </form>
      )}

      {/* Tabla detallada de existencias y desglose de lotes (Sección 12) */}
      <section className="overflow-x-auto rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <h3 className="font-extrabold text-slate-900 dark:text-white mb-3">
          Existencias y Lotes Valuados PEPS
        </h3>
        <table className="w-full text-xs text-left">
          <thead className="bg-slate-50 uppercase text-slate-500 dark:bg-slate-950">
            <tr>
              <th className="p-2.5">Código</th>
              <th className="p-2.5">Producto / Descripción</th>
              <th className="p-2.5">Familia</th>
              <th className="p-2.5">Unidad</th>
              <th className="p-2.5 text-center">Bodega</th>
              <th className="p-2.5 text-center">Existencia</th>
              <th className="p-2.5 text-center">Mínimo</th>
              <th className="p-2.5">Detalle de Lotes PEPS (Cantidad @ Costo)</th>
              <th className="p-2.5 text-center">Condición</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-white/5">
            {filteredProducts.map((item) => {
              const stock = stockOf(item.id);
              const lots = db.lots.filter((lot) => lot.productId === item.id && lot.quantity > 0);
              return (
                <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-white/5">
                  <td className="p-2.5 font-bold font-mono text-brand-700 dark:text-cyan-400">{item.code}</td>
                  <td className="p-2.5 font-semibold text-slate-900 dark:text-white">{item.name}</td>
                  <td className="p-2.5 text-slate-500">{item.category}</td>
                  <td className="p-2.5 text-slate-500">{item.unit || "piezas"}</td>
                  <td className="p-2.5 text-center text-slate-500">Bodega Central</td>
                  <td className="p-2.5 text-center font-black text-sm">{stock}</td>
                  <td className="p-2.5 text-center text-slate-400 font-mono">{item.minQuantity}</td>
                  <td className="p-2.5">
                    <div className="flex flex-wrap gap-1 max-w-md">
                      {lots.length > 0 ? (
                        lots.map((lot, lIdx) => (
                          <span
                            key={lot.id}
                            className="rounded-lg border border-slate-200 bg-slate-50 px-2 py-0.5 text-[11px] font-mono text-slate-700 dark:border-white/10 dark:bg-white/5 dark:text-slate-300"
                            title={`Ingreso: ${lot.entryDate ? new Date(lot.entryDate).toLocaleDateString("es-NI") : "Inicial"}`}
                          >
                            Lote #{lIdx + 1}: <strong>{lot.quantity} u</strong> @ C$ {lot.unitCost}
                          </span>
                        ))
                      ) : (
                        <span className="text-slate-400 italic">Sin lotes activos</span>
                      )}
                    </div>
                  </td>
                  <td className="p-2.5 text-center">
                    <StatusPill tone={stock < item.minQuantity ? "bad" : "ok"}>
                      {stock < item.minQuantity ? "Stock Crítico" : "Abastecido"}
                    </StatusPill>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </section>

      {/* Historial Kardex */}
      <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <h3 className="font-extrabold text-slate-900 dark:text-white mb-3">Movimientos de Kardex</h3>
        <div className="space-y-1.5 max-h-56 overflow-y-auto">
          {db.kardex.slice(0, 12).map((item) => (
            <div key={item.id} className="flex items-center justify-between p-2 rounded-xl border border-slate-100 bg-slate-50 text-xs dark:border-white/5 dark:bg-white/5">
              <div className="flex items-center gap-2">
                <StatusPill tone={item.type === "entrada" ? "ok" : "warn"}>
                  {item.type.toUpperCase()}
                </StatusPill>
                <span className="font-bold">{item.quantity} u</span>
                <span className="text-slate-500">— {item.reason}</span>
              </div>
              <span className="text-slate-400 font-mono text-[11px]">Por: {item.userName}</span>
            </div>
          ))}
          {!db.kardex.length && <p className="text-xs text-slate-400">Sin movimientos registrados.</p>}
        </div>
      </section>
    </div>
  );
}

function FinanceView() {
  const { db, addFinance, upsertProjection } = useErp();
  const { user, can } = useAuth();
  const write = can("finanzas", "write");
  const income = db.finance.filter((item) => item.type === "ingreso").reduce((sum, item) => sum + item.amount, 0);
  const expense = db.finance.filter((item) => item.type === "egreso").reduce((sum, item) => sum + item.amount, 0);

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    addFinance({
      type: data.get("type") as "ingreso" | "egreso",
      category: String(data.get("category")),
      amount: Number(data.get("amount")),
      date: new Date().toISOString(),
      note: String(data.get("note")),
      userName: user?.name ?? "sistema"
    }, user?.name ?? "sistema");
    event.currentTarget.reset();
  };

  return (
    <div className="space-y-5">
      <PageHeader kicker="Finanzas" title="Control financiero" subtitle="Resultado del mes, cuentas que restan y punto de equilibrio." />
      <BooksStudio start="rumbo" />
      <div className="grid gap-3 sm:grid-cols-3">
        <Kpi label="Ingresos" value={income} />
        <Kpi label="Egresos" value={expense} />
        <Kpi label="Resultado" value={income - expense} />
      </div>
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-5">
          <Field label="Tipo"><select name="type" className={inputClass}><option value="ingreso">Ingreso</option><option value="egreso">Egreso</option></select></Field>
          <Field label="Categoría"><input name="category" required className={inputClass} /></Field>
          <Field label="Monto"><input name="amount" type="number" min={0.01} step="0.01" required className={inputClass} /></Field>
          <Field label="Nota"><input name="note" required className={inputClass} /></Field>
          <div className="flex items-end"><Button className="w-full">Registrar</Button></div>
        </form>
      )}
      <section className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
        <h2 className="font-extrabold">Proyección</h2>
        <div className="mt-3 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-xs uppercase text-slate-400"><tr><th className="p-2">Mes</th><th>Ventas esperadas</th><th>Costos esperados</th><th>Utilidad</th></tr></thead>
            <tbody>
              {db.projections.map((item) => (
                <tr key={item.id} className="border-t border-slate-100 dark:border-white/10">
                  <td className="p-2">{item.month}</td>
                  <td><Money value={item.expectedSales} /></td>
                  <td><Money value={item.expectedCosts} /></td>
                  <td className="font-bold"><Money value={item.expectedSales - item.expectedCosts} /></td>
                  {write && (
                    <td>
                      <Button variant="ghost" onClick={() => upsertProjection({ ...item, expectedSales: item.expectedSales + 20000 }, user?.name ?? "sistema")}>Ajustar +20K</Button>
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function AccountingView() {
  const { db, addAccounting, runNightlyClose, log } = useErp();
  const { user, can } = useAuth();
  const write = can("contabilidad", "write");
  const debit = db.accounting.reduce((sum, item) => sum + item.debit, 0);
  const credit = db.accounting.reduce((sum, item) => sum + item.credit, 0);
  const [closeMsg, setCloseMsg] = useState<string | null>(null);
  const [excelMsg, setExcelMsg] = useState<string | null>(null);
  const closeLock = useRef(false);
  const entryLock = useRef(false);

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (entryLock.current) return;
    entryLock.current = true;
    window.setTimeout(() => {
      entryLock.current = false;
    }, 1000);
    const data = new FormData(event.currentTarget);
    const amount = Number(data.get("amount"));
    addAccounting({
      description: String(data.get("description")),
      debit: amount,
      credit: amount,
      debitAccount: String(data.get("debitAccount")),
      creditAccount: String(data.get("creditAccount")),
      entryDate: new Date().toISOString(),
      referenceType: "manual"
    }, user?.name ?? "sistema");
    event.currentTarget.reset();
  };

  const exportExcel = () => {
    const book = downloadAccountingWorkbook(db, user?.name ?? "sistema");
    log({
      userName: user?.name ?? "sistema",
      action: "exportar libro",
      module: "contabilidad",
      detail: `Excel ${db.accounting.length} asientos · sello ${book.stamp}`,
      reference: book.stamp
    });
    setExcelMsg(`Libro listo · sello ${book.stamp}`);
  };

  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Contabilidad"
        title="Libros contables"
        subtitle="Asientos, cuadre del periodo y exportación a Excel."
        actions={
          <Button variant="secondary" icon={<FileSpreadsheet size={16} />} onClick={exportExcel}>
            Bajar Excel día · mes · año
          </Button>
        }
      />
      <div className="grid gap-3 sm:grid-cols-3">
        <Kpi label="Débitos" value={debit} />
        <Kpi label="Créditos" value={credit} />
        <article className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
          <p className="text-sm text-slate-500">Cuadre</p>
          <StatusPill tone={Math.abs(debit - credit) < 0.01 ? "ok" : "bad"}>{Math.abs(debit - credit) < 0.01 ? "Balanceado" : "Descuadre"}</StatusPill>
          {write && (
            <Button
              className="mt-3 w-full"
              variant="secondary"
              onClick={() => {
                if (closeLock.current) return;
                closeLock.current = true;
                setCloseMsg(runNightlyClose(user?.name ?? "sistema").message);
                window.setTimeout(() => {
                  closeLock.current = false;
                }, 1500);
              }}
            >
              Cerrar periodo
            </Button>
          )}
          {closeMsg && <p className="mt-2 text-xs font-semibold text-slate-600 dark:text-slate-300">{closeMsg}</p>}
          {excelMsg && <p className="mt-2 text-xs font-semibold text-brand-700">{excelMsg}</p>}
        </article>
      </div>
      <BooksStudio />
      <DgiBooks />
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-5">
          <Field label="Descripción"><input name="description" required className={inputClass} /></Field>
          <Field label="Debe"><input name="debitAccount" required className={inputClass} placeholder="Caja" /></Field>
          <Field label="Haber"><input name="creditAccount" required className={inputClass} placeholder="Ventas" /></Field>
          <Field label="Monto"><input name="amount" type="number" min={0.01} step="0.01" required className={inputClass} /></Field>
          <div className="flex items-end"><Button className="w-full">Asentar</Button></div>
        </form>
      )}
      <section className="overflow-x-auto rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
        <table className="w-full text-sm">
          <thead className="text-left text-xs uppercase text-slate-400"><tr><th className="p-2">Asiento</th><th>Debe</th><th>Haber</th><th>Monto</th></tr></thead>
          <tbody>
            {db.accounting.map((item) => (
              <tr key={item.id} className="border-t border-slate-100 dark:border-white/10">
                <td className="p-2"><strong>{item.entryNumber}</strong><div className="text-xs text-slate-500">{item.description}</div></td>
                <td>{item.debitAccount}</td>
                <td>{item.creditAccount}</td>
                <td><Money value={item.debit} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}

function MarketingView({ title }: { title: string }) {
  const { db, stockOf } = useErp();
  const byProduct = db.products.map((product) => {
    const qty = db.sales.filter((sale) => sale.status === "completed").flatMap((sale) => sale.items).filter((item) => item.productId === product.id).reduce((sum, item) => sum + item.quantity, 0);
    const amount = db.sales.filter((sale) => sale.status === "completed").flatMap((sale) => sale.items).filter((item) => item.productId === product.id).reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
    return { ...product, qty, amount, stock: stockOf(product.id) };
  }).sort((a, b) => b.amount - a.amount);
  const electros = byProduct.filter((item) => item.category === "Electrodomésticos");

  return (
    <div className="space-y-5">
      <PageHeader kicker="Mercadotecnia" title={title} subtitle="Álbum mensual con fecha y enlace, más rotación de showroom." />
      <AlbumStudio />
      <section className="grid gap-3 md:grid-cols-2">
        {(db.promotions ?? []).filter((item) => item.active).map((item) => (
          <article key={item.id} className="overflow-hidden rounded-2xl bg-gradient-to-r from-brand-900 to-cyan-700 p-5 text-white shadow-soft">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-cyan-100">{item.badge} OFF</p>
            <h3 className="mt-2 text-2xl font-black">{item.title}</h3>
            <p className="mt-2 text-sm text-cyan-50/90">{item.blurb}</p>
            <p className="mt-4 text-xs font-bold">Aplica desde C$ {item.minSubtotal.toLocaleString()}</p>
          </article>
        ))}
      </section>
      <h2 className="font-extrabold">Electrodomésticos en vitrina</h2>
      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        {electros.map((item, index) => (
          <article key={item.id} className="overflow-hidden rounded-lg bg-white shadow-soft dark:bg-slate-900">
            <img src={productPhoto(item)} alt="" className="h-32 w-full object-cover" />
            <div className="p-4">
            <p className="text-xs font-bold text-brand-700">Top {index + 1}</p>
            <h3 className="font-extrabold">{item.name}</h3>
            <p className="text-sm text-slate-500">Stock {item.stock} · {item.qty} vendidas</p>
            <p className="mt-2 font-bold"><Money value={item.unitPrice} /></p>
            </div>
          </article>
        ))}
      </section>
      <h2 className="font-extrabold">Mix general</h2>
      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        {byProduct.slice(0, 8).map((item, index) => (
          <article key={item.id} className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
            <p className="text-xs font-bold text-brand-700">ABC {index === 0 ? "A" : index < 3 ? "B" : "C"}</p>
            <h3 className="font-extrabold">{item.name}</h3>
            <p className="text-sm text-slate-500">{item.qty} u vendidas</p>
            <p className="mt-2 font-bold"><Money value={item.amount * (1 + IVA)} /></p>
          </article>
        ))}
      </section>
    </div>
  );
}

function SalesView() {
  const { db, addSale, addProforma, convertProforma, stockOf, previewPeps } = useErp();
  const { user, can } = useAuth();
  const write = can("ventas", "write");
  const [mode, setMode] = useState<"factura" | "proforma">("factura");
  const [clientName, setClientName] = useState("");
  const [productId, setProductId] = useState(db.products[0]?.id ?? "");
  useEffect(() => { if (!db.products.some(item => item.id === productId)) setProductId(db.products[0]?.id ?? ''); }, [db.products, productId]);
  const [qty, setQty] = useState(1);
  const [notes, setNotes] = useState("");
  const [daysValid, setDaysValid] = useState(12);
  const [error, setError] = useState<string | null>(null);
  const [doc, setDoc] = useState<(TicketData & { peps?: ReturnType<typeof previewPeps> }) | null>(null);
  const [explanation, setExplanation] = useState<FigureExplanation | null>(null);
  const [showPipeline, setShowPipeline] = useState(true);
  const submitLock = useRef(false);
  const product = db.products.find((item) => item.id === productId);
  const subtotal = (product?.unitPrice ?? 0) * qty;
  const deal = bestPromotion(subtotal, db.promotions ?? []);
  const discount = deal.discount;
  const taxable = Math.max(0, subtotal - discount);
  const tax = taxable * IVA;
  const total = taxable + tax;
  const peps = previewPeps(productId, qty);
  const clients = db.parties.filter((item) => item.type === "cliente");

  const submit = (event: FormEvent) => {
    event.preventDefault();
    if (!product) return;
    if (!Number.isFinite(qty) || qty <= 0 || !clientName.trim()) { setError('Indica un cliente y una cantidad mayor que cero.'); return; }
    // Guard anti doble clic: un segundo envío inmediato no genera otra factura.
    if (submitLock.current) return;
    submitLock.current = true;
    window.setTimeout(() => {
      submitLock.current = false;
    }, 1200);
    const actor = user?.name ?? "sistema";
    const payloadBase = {
      clientName,
      items: [{ productId, quantity: qty, unitPrice: product.unitPrice }],
      subtotal,
      discountAmount: discount,
      promoCode: deal.promo?.title,
      taxAmount: tax,
      total
    };

    if (mode === "proforma") {
      const validUntil = new Date(Date.now() + daysValid * 86400000).toISOString();
      const row = addProforma(
        {
          ...payloadBase,
          status: "enviada",
          validUntil,
          notes: notes || `Cotización vigente ${daysValid} días.`,
          createdBy: actor
        },
        actor
      );
      setDoc({
        kind: "PRF",
        number: row.proformaNumber,
        clientName,
        productName: product.name,
        qty,
        subtotal,
        discount,
        promo: deal.promo?.title,
        tax,
        total,
        qrPayload: repairQr(row.qrPayload, {
          kind: "PRF",
          number: row.proformaNumber,
          clientName,
          productName: product.name,
          qty,
          subtotal,
          discount,
          promo: deal.promo?.title,
          tax,
          total
        }),
        notes: row.notes
      });
      setClientName("");
      setQty(1);
      setNotes("");
      setError(null);
      return;
    }

    const preview = previewPeps(productId, qty);
    const result = addSale(
      {
        ...payloadBase,
        status: "completed",
        saleDate: new Date().toISOString(),
        createdBy: actor
      },
      actor
    );
    setError(result.error);
    if (!result.error && result.sale) {
      setDoc({
        kind: "FAC",
        number: result.sale.saleNumber,
        clientName,
        productName: product.name,
        qty,
        subtotal,
        discount,
        promo: deal.promo?.title,
        tax,
        total,
        qrPayload: repairQr(result.sale.qrPayload, {
          kind: "FAC",
          number: result.sale.saleNumber,
          clientName,
          productName: product.name,
          qty,
          subtotal,
          discount,
          promo: deal.promo?.title,
          tax,
          total,
          saleDate: result.sale.saleDate
        }),
        peps: preview
      });
      setClientName("");
      setQty(1);
    }
  };

  const openSale = (sale: Sale) => {
    const item = sale.items[0];
    const prod = db.products.find((p) => p.id === item?.productId);
    const base = {
      kind: "FAC" as const,
      number: sale.saleNumber,
      clientName: sale.clientName,
      productName: prod?.name ?? "Producto",
      qty: item?.quantity ?? 0,
      subtotal: sale.subtotal,
      discount: sale.discountAmount ?? 0,
      promo: sale.promoCode,
      tax: sale.taxAmount,
      total: sale.total
    };
    setDoc({
      ...base,
      qrPayload: repairQr(sale.qrPayload, { ...base, saleDate: sale.saleDate })
    });
  };

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <PageHeader kicker="Ventas" title="Facturas y proformas" subtitle="Facturación y proformas. Confirma los cobros en Caja/Bancos; emitir una factura no registra entrega de dinero." />
        <Button variant="ghost" className="!text-xs" onClick={() => setShowPipeline((v) => !v)}>
          {showPipeline ? "Ocultar flujo documental" : "Ver flujo documental"}
        </Button>
      </div>

      {showPipeline && (
        <OrderToCashPipeline
          docs={[
            ...db.proformas.slice(0,3).map(item => ({stage: 'Cotización' as const, code: item.proformaNumber, status: item.status === 'convertida' ? 'completado' as const : 'pendiente' as const, amount: item.total})),
            ...db.production.slice(0,3).map(item => ({stage: 'Taller / Producción' as const, code: item.code, status: item.stage === 'entregado' ? 'completado' as const : 'activo' as const})),
            ...db.sales.slice(0,3).map(item => ({stage: 'Factura' as const, code: item.saleNumber, status: 'completado' as const, amount: item.total}))
          ]}
        />
      )}

      {explanation && <ExplainFigureModal explanation={explanation} onClose={() => setExplanation(null)} />}

      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        {(db.promotions ?? []).filter((item) => item.active).map((item) => (
          <article key={item.id} className="rounded-2xl bg-gradient-to-br from-amber-50 to-white p-4 shadow-soft dark:from-amber-500/10 dark:to-slate-900">
            <StatusPill tone="warn">{item.badge}</StatusPill>
            <h3 className="mt-2 font-extrabold">{item.title}</h3>
            <p className="text-sm text-slate-500">{item.blurb}</p>
            <p className="mt-2 text-xs font-bold text-amber-800 dark:text-amber-200">Desde C$ {item.minSubtotal.toLocaleString()}</p>
          </article>
        ))}
      </section>
      <div className="flex flex-wrap gap-2">
        <button type="button" onClick={() => setMode("factura")} className={`rounded-full px-4 py-1.5 text-sm font-bold ${mode === "factura" ? "bg-brand-700 text-white" : "bg-white shadow-soft dark:bg-slate-900"}`}>Factura</button>
        <button type="button" onClick={() => setMode("proforma")} className={`rounded-full px-4 py-1.5 text-sm font-bold ${mode === "proforma" ? "bg-brand-700 text-white" : "bg-white shadow-soft dark:bg-slate-900"}`}>Proforma</button>
      </div>
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-4">
          <Field label="Cliente">
            <input list="clientes-list" required className={inputClass} value={clientName} onChange={(e) => setClientName(e.target.value)} placeholder="Nombre del cliente" />
            <datalist id="clientes-list">{clients.map((item) => <option key={item.id} value={item.name} />)}</datalist>
          </Field>
          <Field label="Producto">
            <select className={inputClass} value={productId} onChange={(e) => setProductId(e.target.value)}>
              {db.products.map((item) => <option key={item.id} value={item.id}>{item.name} (stock {stockOf(item.id)})</option>)}
            </select>
          </Field>
          <Field label="Cantidad"><input type="number" min={1} className={inputClass} value={qty} onChange={(e) => setQty(Number(e.target.value))} /></Field>
          <div className="flex items-end">
            <Button className="w-full">{mode === "factura" ? `Facturar C$ ${total.toFixed(2)}` : `Proforma C$ ${total.toFixed(2)}`}</Button>
          </div>
          {mode === "proforma" && (
            <>
              <Field label="Vigencia (días)"><input type="number" min={1} className={inputClass} value={daysValid} onChange={(e) => setDaysValid(Number(e.target.value))} /></Field>
              <Field label="Notas"><input className={inputClass} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Condiciones, instalación, etc." /></Field>
            </>
          )}
          <div className="md:col-span-4 grid gap-3 rounded-xl border border-slate-200 bg-slate-50 p-3 dark:border-white/10 dark:bg-slate-950 md:grid-cols-2">
            <div>
              <div className="flex items-center justify-between">
                <p className="text-xs font-extrabold uppercase tracking-wide text-slate-500">Totales Fiscales</p>
                <button
                  type="button"
                  onClick={() => setExplanation({
                    figureName: "Importe Total de Venta con IVA",
                    figureValue: `C$ ${total.toLocaleString("es-NI", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`,
                    formula: "Total = (Subtotal − Descuentos) + IVA 15% (Ley 822)",
                    origin: "Facturación Comercial / Cartera",
                    accountingNote: "Base imponible según Art. 107 Ley 822 de Concertación Tributaria. Facturación fiscal y desglose de IVA.",
                    legalBase: "Ley 822 de la República de Nicaragua",
                    variables: [
                      { name: "Subtotal", value: `C$ ${subtotal.toLocaleString("es-NI")}`, description: `${qty} u × C$ ${product?.unitPrice ?? 0}` },
                      { name: "Descuento", value: `C$ ${discount.toLocaleString("es-NI")}`, description: deal.promo?.title ?? "Sin descuento" },
                      { name: "Base Imponible", value: `C$ ${taxable.toLocaleString("es-NI")}`, description: "Subtotal neto gravable" },
                      { name: "IVA 15%", value: `C$ ${tax.toLocaleString("es-NI")}`, description: "Impuesto al Valor Agregado fiscal" }
                    ]
                  })}
                  className="inline-flex items-center gap-1 text-[11px] font-bold text-brand-600 dark:text-cyan-400 hover:underline"
                >
                  <HelpCircle size={13} /> Explicar esta cifra
                </button>
              </div>
              <p className="mt-1 text-sm">Subtotal <strong><Money value={subtotal} /></strong></p>
              <p className="text-sm text-emerald-700">Descuento {deal.promo ? `(${deal.promo.badge})` : ""} <strong>- <Money value={discount} /></strong></p>
              <p className="text-sm">IVA 15% <strong><Money value={tax} /></strong></p>
              <p className="text-sm font-extrabold">Total <Money value={total} /></p>
            </div>
            {mode === "factura" && (
              <div>
                <p className="text-xs font-extrabold uppercase tracking-wide text-slate-500">Lotes que saldrán (PEPS)</p>
                {peps.length ? peps.map((slice) => (
                  <p key={slice.lotId} className="text-sm text-slate-600 dark:text-slate-300">{slice.take} u · {slice.lotId} · C$ {slice.unitCost}</p>
                )) : <p className="text-sm text-ember">Sin stock suficiente.</p>}
              </div>
            )}
          </div>
          {error && <p className="md:col-span-4 text-sm font-semibold text-ember">{error}</p>}
        </form>
      )}

      <section className="grid gap-4 xl:grid-cols-2">
        <article className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
          <h2 className="font-extrabold">Facturas</h2>
          <div className="mt-3 space-y-2">
            {db.sales.map((item) => (
              <button key={item.id} type="button" onClick={() => openSale(item)} className="flex w-full items-center justify-between rounded-xl border border-slate-100 px-3 py-2 text-left hover:border-brand-300 dark:border-white/10">
                <span><strong>{item.saleNumber}</strong><span className="ml-2 text-sm text-slate-500">{item.clientName}</span></span>
                <Money value={item.total} />
              </button>
            ))}
          </div>
        </article>
        <article className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
          <h2 className="font-extrabold">Proformas</h2>
          <div className="mt-3 space-y-2">
            {(db.proformas ?? []).map((item) => (
              <div key={item.id} className="rounded-xl border border-slate-100 px-3 py-2 dark:border-white/10">
                <div className="flex items-center justify-between gap-2">
                  <div>
                    <strong>{item.proformaNumber}</strong>
                    <span className="ml-2 text-sm text-slate-500">{item.clientName}</span>
                    <div className="mt-1"><StatusPill tone={item.status === "convertida" ? "ok" : item.status === "aceptada" ? "warn" : "neutral"}>{item.status}</StatusPill></div>
                  </div>
                  <div className="text-right">
                    <Money value={item.total} />
                    <div className="mt-2 flex flex-wrap justify-end gap-1">
                      <Button variant="ghost" onClick={() => {
                        const base = {
                          kind: "PRF" as const,
                          number: item.proformaNumber,
                          clientName: item.clientName,
                          productName: db.products.find((p) => p.id === item.items[0]?.productId)?.name ?? "Ítems",
                          qty: item.items.reduce((sum, row) => sum + row.quantity, 0),
                          subtotal: item.subtotal,
                          discount: item.discountAmount ?? 0,
                          promo: item.promoCode,
                          tax: item.taxAmount,
                          total: item.total,
                          notes: item.notes
                        };
                        setDoc({
                          ...base,
                          qrPayload: repairQr(item.qrPayload, base)
                        });
                      }}>QR</Button>
                      {write && item.status !== "convertida" && (
                        <Button
                          variant="secondary"
                          onClick={() => {
                            const result = convertProforma(item.id, user?.name ?? "sistema");
                            setError(result.error);
                            if (result.sale) {
                              openSale(result.sale);
                            }
                          }}
                        >
                          Facturar
                        </Button>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </article>
      </section>

      {doc && <SaleTicket ticket={doc} onClose={() => setDoc(null)} />}
    </div>
  );
}

function PurchasesView() {
  const { db, addPurchase } = useErp();
  const { user, can } = useAuth();
  const write = can("compras", "write");
  const [supplierName, setSupplierName] = useState("");
  const [productId, setProductId] = useState(db.products[0]?.id ?? "");
  useEffect(() => { if (!db.products.some(item => item.id === productId)) setProductId(db.products[0]?.id ?? ''); }, [db.products, productId]);
  const [qty, setQty] = useState(1);
  const [cost, setCost] = useState(100);
  const purchaseLock = useRef(false);

  const submit = (event: FormEvent) => {
    event.preventDefault();
    if (purchaseLock.current) return;
    purchaseLock.current = true;
    window.setTimeout(() => {
      purchaseLock.current = false;
    }, 1200);
    addPurchase({
      supplierName,
      items: [{ productId, quantity: qty, unitPrice: cost }],
      total: qty * cost,
      status: "received",
      purchaseDate: new Date().toISOString(),
      createdBy: user?.name ?? "sistema"
    }, user?.name ?? "sistema");
    setSupplierName("");
  };

  return (
    <div className="space-y-5">
      <PageHeader kicker="Compras" title="Órdenes y proveedores" subtitle="Órdenes de compra y recepción a bodega." />
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-5">
          <Field label="Proveedor"><input required className={inputClass} value={supplierName} onChange={(e) => setSupplierName(e.target.value)} /></Field>
          <Field label="Producto"><select className={inputClass} value={productId} onChange={(e) => setProductId(e.target.value)}>{db.products.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></Field>
          <Field label="Cantidad"><input type="number" min={0.01} step="0.01" required className={inputClass} value={qty} onChange={(e) => setQty(Number(e.target.value))} /></Field>
          <Field label="Costo"><input type="number" min={0} step="0.01" required className={inputClass} value={cost} onChange={(e) => setCost(Number(e.target.value))} /></Field>
          <div className="flex items-end"><Button className="w-full">Recibir compra</Button></div>
        </form>
      )}
      <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <h3 className="font-extrabold text-slate-900 dark:text-white mb-3">Órdenes de Compra y Recepciones</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead className="bg-slate-50 uppercase text-slate-500 dark:bg-slate-950">
              <tr>
                <th className="p-2.5">N° Orden</th>
                <th className="p-2.5">Proveedor</th>
                <th className="p-2.5">Fecha</th>
                <th className="p-2.5">Ítems Comprados</th>
                <th className="p-2.5 text-right">Total (NIO)</th>
                <th className="p-2.5 text-center">Estado</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-white/5">
              {db.purchases.map((item) => (
                <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-white/5">
                  <td className="p-2.5 font-bold font-mono text-brand-700 dark:text-cyan-400">{item.purchaseNumber}</td>
                  <td className="p-2.5 font-semibold text-slate-900 dark:text-white">{item.supplierName}</td>
                  <td className="p-2.5 text-slate-500">{new Date(item.purchaseDate).toLocaleDateString("es-NI")}</td>
                  <td className="p-2.5">{item.items.map((i) => `${i.productName ?? "Ítem"} (${i.quantity} u)`).join(", ")}</td>
                  <td className="p-2.5 text-right font-black font-mono"><Money value={item.total} /></td>
                  <td className="p-2.5 text-center">
                    <StatusPill tone={item.status === "received" ? "ok" : "warn"}>
                      {item.status === "received" ? "Recibida en Bodega" : "Pendiente de Entrega"}
                    </StatusPill>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function PartiesView({ type }: { type: "cliente" | "proveedor" }) {
  const { db, addParty } = useErp();
  const { user, can } = useAuth();
  const module = type === "cliente" ? "clientes" : "proveedores";
  const write = can(module, "write");

  const [form, setForm] = useState({
    name: "",
    contact: "",
    phone: "",
    category: type === "cliente" ? "Empresa Constructora" : "Proveedor de Perfiles",
    address: ""
  });

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    addParty({
      name: form.name,
      contact: form.contact,
      phone: `${form.phone}${form.address ? ` · ${form.address}` : ""}`,
      type
    }, user?.name ?? "sistema");
    setForm({
      name: "",
      contact: "",
      phone: "",
      category: type === "cliente" ? "Empresa Constructora" : "Proveedor de Perfiles",
      address: ""
    });
  };

  const list = db.parties.filter((item) => item.type === type);

  return (
    <div className="space-y-5">
      <PageHeader
        kicker={type === "cliente" ? "Comercial y Cartera" : "Cadena de Suministro"}
        title={type === "cliente" ? "Expediente de Clientes" : "Directorio de Proveedores Homologados"}
        subtitle={
          type === "cliente"
            ? "Historial de contactos, direcciones de obra y saldo de cartera (Sección 8)."
            : "Condiciones comerciales, categorías y evaluación de entregas (Sección 14)."
        }
      />

      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-2xl bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900 md:grid-cols-5">
          <Field label={type === "cliente" ? "Cliente / Razón Social" : "Proveedor / Empresa"}>
            <input
              required
              className={inputClass}
              placeholder={type === "cliente" ? "Ej. Desarrollos del Pacífico S.A." : "Ej. Extrusiones Centroamericanas"}
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
            />
          </Field>
          <Field label="Persona de Contacto">
            <input
              required
              className={inputClass}
              placeholder="Ing. Álvaro Guido"
              value={form.contact}
              onChange={(e) => setForm({ ...form, contact: e.target.value })}
            />
          </Field>
          <Field label="Teléfono / Correo">
            <input
              required
              className={inputClass}
              placeholder="+505 8899-0011"
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />
          </Field>
          <Field label="Categoría">
            <select
              className={inputClass}
              value={form.category}
              onChange={(e) => setForm({ ...form, category: e.target.value })}
            >
              {type === "cliente" ? (
                <>
                  <option value="Empresa Constructora">Empresa Constructora</option>
                  <option value="Cliente Residencial">Cliente Residencial</option>
                  <option value="Arquitecto / Diseñador">Arquitecto / Diseñador</option>
                  <option value="Comercial / Negocio">Comercial / Negocio</option>
                </>
              ) : (
                <>
                  <option value="Proveedor de Perfiles">Proveedor de Perfiles de Aluminio</option>
                  <option value="Vidriería / Templados">Vidriería / Cristales y Templados</option>
                  <option value="Herrajes y Accesorios">Herrajes y Rodamientos</option>
                  <option value="Insumos y Selladores">Selladores y Siliconas</option>
                </>
              )}
            </select>
          </Field>
          <div className="flex items-end">
            <Button className="w-full">Registrar {type === "cliente" ? "Cliente" : "Proveedor"}</Button>
          </div>
          <div className="md:col-span-5">
            <Field label={type === "cliente" ? "Dirección de Obra o Instalación" : "Dirección de Bodega o Despacho"}>
              <input
                className={inputClass}
                placeholder="Km 12 Carretera a Masaya, 200m al Este"
                value={form.address}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
              />
            </Field>
          </div>
        </form>
      )}

      <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <h3 className="font-extrabold text-slate-900 dark:text-white mb-3">
          {type === "cliente" ? "Directorio y Cartera de Clientes" : "Directorio de Proveedores y Fabricantes"}
        </h3>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead className="bg-slate-50 uppercase text-slate-500 dark:bg-slate-950">
              <tr>
                <th className="p-2.5">{type === "cliente" ? "Cliente / Razón Social" : "Proveedor"}</th>
                <th className="p-2.5">Persona de Contacto</th>
                <th className="p-2.5">Teléfono / Detalle</th>
                <th className="p-2.5">Categoría</th>
                <th className="p-2.5 text-center">Condición</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-white/5">
              {list.map((item) => (
                <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-white/5">
                  <td className="p-2.5 font-bold text-slate-900 dark:text-white">{item.name}</td>
                  <td className="p-2.5 font-semibold text-slate-700 dark:text-slate-300">{item.contact}</td>
                  <td className="p-2.5 text-slate-500">{item.phone}</td>
                  <td className="p-2.5">
                    <span className="rounded-md bg-slate-100 px-2 py-0.5 text-[11px] font-bold text-slate-700 dark:bg-white/10 dark:text-slate-300">
                      {type === "cliente" ? "Cliente Activo" : "Homologado"}
                    </span>
                  </td>
                  <td className="p-2.5 text-center">
                    <StatusPill tone="ok">Verificado</StatusPill>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function ProjectsView() {
  const { db, addProject } = useErp();
  const { user, can } = useAuth();
  const write = can("proyectos", "write");
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    addProject({
      code: String(data.get("code")),
      name: String(data.get("name")),
      client: String(data.get("client")),
      amount: Number(data.get("amount")),
      progress: Number(data.get("progress")),
      state: String(data.get("state")),
      owner: user?.name ?? "sistema"
    }, user?.name ?? "sistema");
    event.currentTarget.reset();
  };
  return (
    <div className="space-y-5">
      <PageHeader kicker="Proyectos" title="Obras de aluminio y vidrio" subtitle="Avance de obras y cobro." />
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-6">
          <Field label="Código"><input name="code" required className={inputClass} /></Field>
          <Field label="Nombre"><input name="name" required className={inputClass} /></Field>
          <Field label="Cliente"><input name="client" required className={inputClass} /></Field>
          <Field label="Monto"><input name="amount" type="number" min={0.01} step="0.01" required className={inputClass} /></Field>
          <Field label="Avance %"><input name="progress" type="number" min={0} max={100} required defaultValue={10} className={inputClass} /></Field>
          <Field label="Estado"><input name="state" defaultValue="Medición" className={inputClass} /></Field>
          <div className="md:col-span-6"><Button>Crear proyecto</Button></div>
        </form>
      )}
      <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <h3 className="font-extrabold text-slate-900 dark:text-white mb-3">Obras y Proyectos Arquitectónicos</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-xs text-left">
            <thead className="bg-slate-50 uppercase text-slate-500 dark:bg-slate-950">
              <tr>
                <th className="p-2.5">Código de Obra</th>
                <th className="p-2.5">Proyecto / Trabajo</th>
                <th className="p-2.5">Cliente</th>
                <th className="p-2.5 text-right">Monto Contratado</th>
                <th className="p-2.5 text-center">Avance Físico</th>
                <th className="p-2.5">Responsable</th>
                <th className="p-2.5 text-center">Etapa Operativa</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-white/5">
              {db.projects.map((item) => (
                <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-white/5">
                  <td className="p-2.5 font-bold font-mono text-brand-700 dark:text-cyan-400">{item.code}</td>
                  <td className="p-2.5 font-semibold text-slate-900 dark:text-white">{item.name}</td>
                  <td className="p-2.5 text-slate-600 dark:text-slate-300">{item.client}</td>
                  <td className="p-2.5 text-right font-black font-mono"><Money value={item.amount} /></td>
                  <td className="p-2.5 text-center">
                    <div className="inline-flex items-center gap-1.5">
                      <div className="h-2 w-14 rounded-full bg-slate-200 dark:bg-slate-800 overflow-hidden">
                        <div className="h-full bg-emerald-500" style={{ width: `${Math.min(100, item.progress)}%` }} />
                      </div>
                      <span className="font-mono font-bold text-[11px]">{item.progress}%</span>
                    </div>
                  </td>
                  <td className="p-2.5 text-slate-500">{item.owner}</td>
                  <td className="p-2.5 text-center"><StatusPill tone="ok">{item.state}</StatusPill></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}

function HrView({ payroll }: { payroll: boolean }) {
  const { db, addEmployee, payPayroll, syncStatus } = useErp();
  const { user, can } = useAuth();
  const write = can(payroll ? "nomina" : "rrhh", "write");
  const pack = payrollOf(db.employees);
  const period = monthKey();
  const paid = (db.payrollRuns ?? []).find((item) => item.period === period);
  const [payMsg, setPayMsg] = useState<string | null>(null);
  const payingRef = useRef(false);

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    addEmployee({
      name: String(data.get("name")),
      position: String(data.get("position")),
      salary: Number(data.get("salary")),
      area: String(data.get("area"))
    }, user?.name ?? "sistema");
    event.currentTarget.reset();
  };

  return (
    <div className="space-y-5">
      <PageHeader
        kicker={payroll ? "Nómina" : "RRHH"}
        title={payroll ? "Pago a trabajadores" : "Talento humano"}
        subtitle={payroll ? "Simulación orientativa. El cálculo confirmado y sus reglas se consultan en Nómina." : "Registro de personal por área."}
      />
      {payroll && (
        <>
          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <Kpi label="Bruto" value={pack.gross} />
            <Kpi label="INSS trabajadores" value={pack.inssLaboral} />
            <Kpi label="IR retenido DGI" value={pack.ir} />
            <Kpi label="Neto a depositar" value={pack.net} />
          </div>
          <div className="grid gap-3 md:grid-cols-3">
            <article className="rounded-xl bg-white p-4 shadow-soft dark:bg-slate-900">
              <p className="text-xs text-slate-500">INSS patronal 21.5%</p>
              <p className="mt-1 font-black"><Money value={pack.inssPatronal} /></p>
            </article>
            <article className="rounded-xl bg-white p-4 shadow-soft dark:bg-slate-900">
              <p className="text-xs text-slate-500">INATEC 2%</p>
              <p className="mt-1 font-black"><Money value={pack.inatec} /></p>
            </article>
            <article className="rounded-xl bg-white p-4 shadow-soft dark:bg-slate-900">
              <p className="text-xs text-slate-500">Costo empresa (mes)</p>
              <p className="mt-1 font-black"><Money value={pack.employerCost} /></p>
              <p className="mt-1 text-[11px] text-slate-400">Reserva aguinaldo <Money value={pack.aguinaldo} /></p>
            </article>
          </div>
          {write && (
            <div className="rounded-2xl bg-slate-950 p-4 text-cyan-50">
              <p className="text-sm">Planilla {period} · {pack.headcount} personas. El neto sale de banco; INSS, INATEC e IR quedan por pagar.</p>
              <p className="mt-3 rounded-lg bg-cyan-400/10 p-3 text-xs text-cyan-100">
                Registra el pago en <strong>Nómina → Pagos</strong> con cálculo y aprobación confirmados.
                Si falta conexión, el pago queda pendiente; esta simulación no confirma salidas de dinero.
              </p>
              {payMsg && <p className="mt-2 text-xs font-semibold">{payMsg}</p>}
            </div>
          )}
          <section className="overflow-x-auto rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
            <table className="w-full min-w-[720px] text-sm">
              <thead className="text-left text-[11px] uppercase text-slate-400">
                <tr>
                  <th className="p-2">Trabajador</th>
                  <th>Bruto</th>
                  <th>INSS 7%</th>
                  <th>IR</th>
                  <th>Neto</th>
                  <th>Patronal + INATEC</th>
                </tr>
              </thead>
              <tbody>
                {pack.slips.map((item) => (
                  <tr key={item.employeeId} className="border-t border-slate-100 dark:border-white/10">
                    <td className="p-2"><strong>{item.name}</strong><div className="text-xs text-slate-500">{item.position}</div></td>
                    <td><Money value={item.gross} /></td>
                    <td><Money value={item.inssLaboral} /></td>
                    <td><Money value={item.ir} /></td>
                    <td className="font-black"><Money value={item.net} /></td>
                    <td><Money value={item.inssPatronal + item.inatec} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </section>
        </>
      )}
      {write && !payroll && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-4">
          <Field label="Nombre"><input name="name" required className={inputClass} /></Field>
          <Field label="Cargo"><input name="position" required className={inputClass} /></Field>
          <Field label="Salario"><input name="salary" type="number" required className={inputClass} /></Field>
          <Field label="Área"><input name="area" required className={inputClass} /></Field>
          <div className="md:col-span-4"><Button>Alta</Button></div>
        </form>
      )}
      {!payroll && (
        <section className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
          <h3 className="font-extrabold text-slate-900 dark:text-white mb-3">Expedientes de Colaboradores y Personal</h3>
          <div className="overflow-x-auto">
            <table className="w-full text-xs text-left">
              <thead className="bg-slate-50 uppercase text-slate-500 dark:bg-slate-950">
                <tr>
                  <th className="p-2.5">Colaborador</th>
                  <th className="p-2.5">Cargo / Puesto</th>
                  <th className="p-2.5">Área Operativa</th>
                  <th className="p-2.5 text-right">Salario Base (NIO)</th>
                  <th className="p-2.5 text-center">Condición Laboral</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                {db.employees.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50/50 dark:hover:bg-white/5">
                    <td className="p-2.5 font-bold text-slate-900 dark:text-white">{item.name}</td>
                    <td className="p-2.5 text-slate-700 dark:text-slate-300">{item.position}</td>
                    <td className="p-2.5"><StatusPill tone="neutral">{item.area}</StatusPill></td>
                    <td className="p-2.5 text-right font-black font-mono"><Money value={item.salary} /></td>
                    <td className="p-2.5 text-center"><StatusPill tone="ok">Activo (Planilla)</StatusPill></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}


function CostsView() {
  return (
    <div className="space-y-5">
      <PageHeader kicker="Costos" title="Costos PEPS por línea" subtitle="Materiales, mano de obra y margen de cada familia de producto." />
      <BooksStudio start="costos" />
    </div>
  );
}

function Kpi({ label, value }: { label: string; value: number }) {
  return (
    <article className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
      <p className="text-sm text-slate-500">{label}</p>
      <strong className="mt-1 block text-2xl"><Money value={value} /></strong>
    </article>
  );
}

function List({ rows }: { rows: { k: string; a: string; b: string; c: string; d: number }[] }) {
  const [q, setQ] = useState("");
  const filtered = useMemo(() => rows.filter((row) => `${row.a} ${row.b} ${row.c}`.toLowerCase().includes(q.toLowerCase())), [q, rows]);
  return (
    <section className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
      <input className={`${inputClass} mb-3 max-w-xs`} placeholder="Buscar" value={q} onChange={(e) => setQ(e.target.value)} />
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="text-left text-xs uppercase text-slate-400"><tr><th className="p-2">Código</th><th>Detalle</th><th>Estado</th><th>Monto</th></tr></thead>
          <tbody>
            {filtered.map((row) => (
              <tr key={row.k} className="border-t border-slate-100 dark:border-white/10">
                <td className="p-2 font-bold text-brand-700">{row.a}</td>
                <td>{row.b}</td>
                <td><StatusPill>{row.c}</StatusPill></td>
                <td><Money value={row.d} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

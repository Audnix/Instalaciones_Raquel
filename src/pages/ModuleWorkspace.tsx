import { FormEvent, useMemo, useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { SaleTicket, type TicketData } from "../components/SaleTicket";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";
import { bestPromotion } from "../data/catalog";
import { buildDocToken } from "../lib/invoiceDoc";
import { getPublicOrigin } from "../lib/publicOrigin";
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
      return <PartiesView type="proveedor" />;
    case "proyectos":
      return <ProjectsView />;
    case "rrhh":
    case "nomina":
      return <HrView payroll={moduleId === "nomina"} />;
    case "caja":
      return <CashView account="caja" />;
    case "bancos":
      return <CashView account="banco" />;
    case "costos":
      return <CostsView />;
    case "auditoria":
      return <AuditView />;
    default:
      return null;
  }
}

function ProductionView() {
  const { db, addProduction, moveProduction } = useErp();
  const { user, can } = useAuth();
  const write = can("produccion", "write");
  const [form, setForm] = useState({ code: "", product: "", client: "", qty: 1, sprint: "Sprint 13", owner: user?.name ?? "" });

  const submit = (event: FormEvent) => {
    event.preventDefault();
    addProduction({ ...form, stage: "backlog" }, user?.name ?? "sistema");
    setForm({ code: "", product: "", client: "", qty: 1, sprint: "Sprint 13", owner: user?.name ?? "" });
  };

  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Producción"
        title="Taller Kanban / Scrum"
        subtitle="Órdenes del taller en tablero Kanban."
      />
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-6">
          <Field label="OT"><input className={inputClass} required value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} /></Field>
          <Field label="Producto"><input className={inputClass} required value={form.product} onChange={(e) => setForm({ ...form, product: e.target.value })} /></Field>
          <Field label="Cliente"><input className={inputClass} required value={form.client} onChange={(e) => setForm({ ...form, client: e.target.value })} /></Field>
          <Field label="Cantidad"><input className={inputClass} type="number" min={1} value={form.qty} onChange={(e) => setForm({ ...form, qty: Number(e.target.value) })} /></Field>
          <Field label="Sprint"><input className={inputClass} value={form.sprint} onChange={(e) => setForm({ ...form, sprint: e.target.value })} /></Field>
          <div className="flex items-end"><Button className="w-full" type="submit">Crear orden</Button></div>
        </form>
      )}
      <div className="grid gap-3 xl:grid-cols-5">
        {stages.map((stage) => (
          <article key={stage} className="rounded-lg bg-white p-3 shadow-soft dark:bg-slate-900">
            <h3 className="mb-3 text-sm font-extrabold uppercase tracking-wide">{stage}</h3>
            <div className="space-y-2">
              {db.production.filter((item) => item.stage === stage).map((item) => (
                <div key={item.id} className="rounded-lg border border-slate-200 p-3 dark:border-white/10">
                  <p className="text-xs font-bold text-brand-700">{item.code}</p>
                  <p className="font-semibold">{item.product}</p>
                  <p className="text-xs text-slate-500">{item.client} · {item.qty} u · {item.sprint}</p>
                  {write && (
                    <select
                      className="mt-2 h-9 w-full rounded border border-slate-200 bg-slate-50 text-xs dark:border-white/10 dark:bg-slate-950"
                      value={item.stage}
                      onChange={(e) => moveProduction(item.id, e.target.value as ProductionOrder["stage"], user?.name ?? "sistema")}
                    >
                      {stages.map((option) => <option key={option}>{option}</option>)}
                    </select>
                  )}
                </div>
              ))}
            </div>
          </article>
        ))}
      </div>
    </div>
  );
}

function InventoryView() {
  const { db, stockOf, addKardex, previewPeps } = useErp();
  const { user, can } = useAuth();
  const write = can("inventario", "write");
  const [form, setForm] = useState({ productId: db.products[0]?.id ?? "", type: "entrada" as "entrada" | "salida", quantity: 1, unitCost: 0, reason: "" });
  const [error, setError] = useState<string | null>(null);
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

  return (
    <div className="space-y-5">
      <PageHeader kicker="Inventario" title="Inventario PEPS" subtitle="Entradas, salidas y lotes PEPS." />
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-5">
          <Field label="Producto">
            <select className={inputClass} value={form.productId} onChange={(e) => setForm({ ...form, productId: e.target.value })}>
              {db.products.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
            </select>
          </Field>
          <Field label="Tipo">
            <select className={inputClass} value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value as "entrada" | "salida" })}>
              <option value="entrada">Entrada</option>
              <option value="salida">Salida</option>
            </select>
          </Field>
          <Field label="Cantidad"><input className={inputClass} type="number" min={1} value={form.quantity} onChange={(e) => setForm({ ...form, quantity: Number(e.target.value) })} /></Field>
          <Field label="Costo unit."><input className={inputClass} type="number" min={0} value={form.unitCost} onChange={(e) => setForm({ ...form, unitCost: Number(e.target.value) })} /></Field>
          <div className="flex items-end"><Button className="w-full" type="submit">Registrar</Button></div>
          <Field label="Motivo"><input className={inputClass} required value={form.reason} onChange={(e) => setForm({ ...form, reason: e.target.value })} /></Field>
          {error && <p className="md:col-span-5 text-sm font-semibold text-ember">{error}</p>}
          {form.type === "salida" && (
            <div className="md:col-span-5 rounded-xl border border-cyan-200 bg-cyan-50/70 p-3 dark:border-cyan-500/20 dark:bg-cyan-500/10">
              <p className="text-xs font-extrabold uppercase tracking-wide text-cyan-800 dark:text-cyan-200">Preview PEPS · lotes que saldrán primero</p>
              <div className="mt-2 space-y-1">
                {pepsPreview.length ? pepsPreview.map((slice) => (
                  <p key={slice.lotId} className="text-sm text-slate-700 dark:text-slate-200">
                    Lote <strong>{slice.lotId}</strong> · {slice.take} u · costo C$ {slice.unitCost} · {new Date(slice.entryDate).toLocaleDateString("es-NI")}
                  </p>
                )) : <p className="text-sm text-ember">No hay stock suficiente en lotes.</p>}
              </div>
            </div>
          )}
        </form>
      )}
      <section className="overflow-x-auto rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
        <table className="w-full text-sm">
          <thead className="text-left text-xs uppercase text-slate-400"><tr><th className="p-2">Producto</th><th>Stock</th><th>Mínimo</th><th>Lotes vivos</th><th>Estado</th></tr></thead>
          <tbody>
            {db.products.map((item) => {
              const stock = stockOf(item.id);
              const lots = db.lots.filter((lot) => lot.productId === item.id && lot.quantity > 0);
              return (
                <tr key={item.id} className="border-t border-slate-100 dark:border-white/10">
                  <td className="p-2 font-semibold">{item.name}<div className="text-xs text-slate-500">{item.code}</div></td>
                  <td>{stock}</td>
                  <td>{item.minQuantity}</td>
                  <td className="text-xs text-slate-500">{lots.map((lot) => `${lot.quantity}@${lot.unitCost}`).join(" · ") || "—"}</td>
                  <td><StatusPill tone={stock < item.minQuantity ? "bad" : "ok"}>{stock < item.minQuantity ? "Crítico" : "Normal"}</StatusPill></td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </section>
      <section className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
        <h2 className="font-extrabold">Kardex</h2>
        <div className="mt-3 space-y-2">
          {db.kardex.slice(0, 12).map((item) => (
            <p key={item.id} className="text-sm"><StatusPill tone={item.type === "entrada" ? "ok" : "warn"}>{item.type}</StatusPill> {item.quantity} u · {item.reason} · {item.userName}</p>
          ))}
          {!db.kardex.length && <p className="text-sm text-slate-500">Sin movimientos todavía.</p>}
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
      <PageHeader kicker="Finanzas" title="Ingresos, egresos y proyecciones" subtitle="Ingresos, egresos y proyección mensual." />
      <div className="grid gap-3 sm:grid-cols-3">
        <Kpi label="Ingresos" value={income} />
        <Kpi label="Egresos" value={expense} />
        <Kpi label="Resultado" value={income - expense} />
      </div>
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-5">
          <Field label="Tipo"><select name="type" className={inputClass}><option value="ingreso">Ingreso</option><option value="egreso">Egreso</option></select></Field>
          <Field label="Categoría"><input name="category" required className={inputClass} /></Field>
          <Field label="Monto"><input name="amount" type="number" required className={inputClass} /></Field>
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
  const { db, addAccounting, runNightlyClose } = useErp();
  const { user, can } = useAuth();
  const write = can("contabilidad", "write");
  const debit = db.accounting.reduce((sum, item) => sum + item.debit, 0);
  const credit = db.accounting.reduce((sum, item) => sum + item.credit, 0);
  const [closeMsg, setCloseMsg] = useState<string | null>(null);

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
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

  return (
    <div className="space-y-5">
      <PageHeader kicker="Contabilidad" title="Diario de operaciones" subtitle="Diario, cuadre y cierre de periodo." />
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
              onClick={() => setCloseMsg(runNightlyClose(user?.name ?? "sistema").message)}
            >
              Ejecutar cierre RS02
            </Button>
          )}
          {closeMsg && <p className="mt-2 text-xs font-semibold text-slate-600 dark:text-slate-300">{closeMsg}</p>}
        </article>
      </div>
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-5">
          <Field label="Descripción"><input name="description" required className={inputClass} /></Field>
          <Field label="Debe"><input name="debitAccount" required className={inputClass} placeholder="Caja" /></Field>
          <Field label="Haber"><input name="creditAccount" required className={inputClass} placeholder="Ventas" /></Field>
          <Field label="Monto"><input name="amount" type="number" required className={inputClass} /></Field>
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
      <PageHeader kicker="Mercadotecnia" title={title} subtitle="Promos activas y rotación de showroom." />
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
          <article key={item.id} className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
            <p className="text-xs font-bold text-brand-700">Top {index + 1}</p>
            <h3 className="font-extrabold">{item.name}</h3>
            <p className="text-sm text-slate-500">Stock {item.stock} · {item.qty} vendidas</p>
            <p className="mt-2 font-bold"><Money value={item.unitPrice} /></p>
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
  const [qty, setQty] = useState(1);
  const [notes, setNotes] = useState("");
  const [daysValid, setDaysValid] = useState(12);
  const [error, setError] = useState<string | null>(null);
  const [doc, setDoc] = useState<(TicketData & { peps?: ReturnType<typeof previewPeps> }) | null>(null);
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
      <PageHeader kicker="Ventas" title="Facturas y proformas" subtitle="Al facturar sale el ticket con QR. Guardá en PDF y abrilo en el celular con la IP de red." />
      <div className="rounded-2xl border border-cyan-200 bg-cyan-50 px-4 py-3 text-sm text-cyan-950 dark:border-cyan-500/30 dark:bg-cyan-500/10 dark:text-cyan-50">
        En el celular abrí: <strong className="font-mono">{getPublicOrigin() || "http://192.168.1.8:5173"}</strong> (misma Wi‑Fi). No uses <span className="font-mono">localhost</span>.
      </div>
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
              <p className="text-xs font-extrabold uppercase tracking-wide text-slate-500">Totales</p>
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
  const [qty, setQty] = useState(1);
  const [cost, setCost] = useState(100);

  const submit = (event: FormEvent) => {
    event.preventDefault();
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
          <Field label="Cantidad"><input type="number" className={inputClass} value={qty} onChange={(e) => setQty(Number(e.target.value))} /></Field>
          <Field label="Costo"><input type="number" className={inputClass} value={cost} onChange={(e) => setCost(Number(e.target.value))} /></Field>
          <div className="flex items-end"><Button className="w-full">Recibir compra</Button></div>
        </form>
      )}
      <List rows={db.purchases.map((item) => ({ k: item.id, a: item.purchaseNumber, b: item.supplierName, c: item.status, d: item.total }))} />
    </div>
  );
}

function PartiesView({ type }: { type: "cliente" | "proveedor" }) {
  const { db, addParty } = useErp();
  const { user, can } = useAuth();
  const module = type === "cliente" ? "clientes" : "proveedores";
  const write = can(module, "write");
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    addParty({ name: String(data.get("name")), contact: String(data.get("contact")), phone: String(data.get("phone")), type }, user?.name ?? "sistema");
    event.currentTarget.reset();
  };
  return (
    <div className="space-y-5">
      <PageHeader kicker={type === "cliente" ? "Clientes" : "Proveedores"} title={type === "cliente" ? "Cartera de clientes" : "Directorio de proveedores"} subtitle="Directorio operativo." />
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-4">
          <Field label="Nombre"><input name="name" required className={inputClass} /></Field>
          <Field label="Contacto"><input name="contact" required className={inputClass} /></Field>
          <Field label="Teléfono"><input name="phone" required className={inputClass} /></Field>
          <div className="flex items-end"><Button className="w-full">Guardar</Button></div>
        </form>
      )}
      <div className="grid gap-3 md:grid-cols-2">
        {db.parties.filter((item) => item.type === type).map((item) => (
          <article key={item.id} className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
            <h3 className="font-extrabold">{item.name}</h3>
            <p className="text-sm text-slate-500">{item.contact} · {item.phone}</p>
          </article>
        ))}
      </div>
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
          <Field label="Monto"><input name="amount" type="number" required className={inputClass} /></Field>
          <Field label="Avance %"><input name="progress" type="number" defaultValue={10} className={inputClass} /></Field>
          <Field label="Estado"><input name="state" defaultValue="Medición" className={inputClass} /></Field>
          <div className="md:col-span-6"><Button>Crear proyecto</Button></div>
        </form>
      )}
      <List rows={db.projects.map((item) => ({ k: item.id, a: item.code, b: item.name, c: item.state, d: item.amount }))} />
    </div>
  );
}

function HrView({ payroll }: { payroll: boolean }) {
  const { db, addEmployee } = useErp();
  const { user, can } = useAuth();
  const write = can(payroll ? "nomina" : "rrhh", "write");
  const total = db.employees.reduce((sum, item) => sum + item.salary, 0);
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
      <PageHeader kicker={payroll ? "Nómina" : "RRHH"} title={payroll ? "Planilla quincenal" : "Talento humano"} subtitle={payroll ? `Planilla estimada: C$ ${total.toLocaleString()}` : "Registro de personal por área."} />
      {write && !payroll && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-4">
          <Field label="Nombre"><input name="name" required className={inputClass} /></Field>
          <Field label="Cargo"><input name="position" required className={inputClass} /></Field>
          <Field label="Salario"><input name="salary" type="number" required className={inputClass} /></Field>
          <Field label="Área"><input name="area" required className={inputClass} /></Field>
          <div className="md:col-span-4"><Button>Alta</Button></div>
        </form>
      )}
      <List rows={db.employees.map((item) => ({ k: item.id, a: item.name, b: item.position, c: item.area, d: item.salary }))} />
    </div>
  );
}

function CashView({ account }: { account: "caja" | "banco" }) {
  const { db, addCash } = useErp();
  const { user, can } = useAuth();
  const write = can(account === "caja" ? "caja" : "bancos", "write");
  const rows = db.cash.filter((item) => item.account === account);
  const balance = rows.reduce((sum, item) => sum + (item.type === "entrada" ? item.amount : -item.amount), 0);
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    addCash({
      account,
      type: data.get("type") as "entrada" | "salida",
      amount: Number(data.get("amount")),
      date: new Date().toISOString(),
      concept: String(data.get("concept"))
    }, user?.name ?? "sistema");
    event.currentTarget.reset();
  };
  return (
    <div className="space-y-5">
      <PageHeader kicker={account === "caja" ? "Caja" : "Bancos"} title={`Saldo: ${balance.toLocaleString()} C$`} subtitle="Entradas y salidas del día." />
      {write && (
        <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-4">
          <Field label="Tipo"><select name="type" className={inputClass}><option value="entrada">Entrada</option><option value="salida">Salida</option></select></Field>
          <Field label="Monto"><input name="amount" type="number" required className={inputClass} /></Field>
          <Field label="Concepto"><input name="concept" required className={inputClass} /></Field>
          <div className="flex items-end"><Button className="w-full">Registrar</Button></div>
        </form>
      )}
      <List rows={rows.map((item) => ({ k: item.id, a: item.type, b: item.concept, c: item.date.slice(0, 10), d: item.amount }))} />
    </div>
  );
}

function CostsView() {
  const { db } = useErp();
  const material = db.purchases.filter((item) => item.status === "received").reduce((sum, item) => sum + item.total, 0);
  const labor = db.employees.reduce((sum, item) => sum + item.salary, 0);
  return (
    <div className="space-y-5">
      <PageHeader kicker="Costos" title="Estructura de costos" subtitle="Materiales y mano de obra por obra." />
      <div className="grid gap-3 md:grid-cols-3">
        <Kpi label="Materiales" value={material} />
        <Kpi label="Mano de obra (mes)" value={labor} />
        <Kpi label="Costo combinado" value={material + labor} />
      </div>
    </div>
  );
}

function AuditView() {
  const { db } = useErp();
  return (
    <div className="space-y-5">
      <PageHeader kicker="Gobierno" title="Auditoría y trazabilidad" subtitle="Historial de movimientos del sistema." />
      <div className="space-y-2">
        {db.audit.map((item) => (
          <article key={item.id} className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <strong>{item.action} · {item.module}</strong>
              <span className="text-xs text-slate-500">{new Date(item.at).toLocaleString("es-NI")}</span>
            </div>
            <p className="text-sm text-slate-500">{item.userName}: {item.detail}</p>
          </article>
        ))}
      </div>
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

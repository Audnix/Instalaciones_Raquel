import { FormEvent, useMemo, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { Database, GitBranch, Layers3, Link2, ShieldCheck, Workflow } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";
import {
  acidPipeline,
  countEntity,
  otStates,
  proformaStates,
  schemaEntities,
  schemaRelations,
  tableCatalog,
  type SchemaEntity
} from "../data/umlSchema";
import { useErp } from "../store/erpStore";
import type { ErpDatabase } from "../types/erp";

type Tab = "resumen" | "modelo" | "clases" | "objetos" | "acid" | "tablas" | "productos";

const groups = ["Gobierno", "Catálogo", "Operación", "Finanzas"] as const;

export default function DataHubPage() {
  const { db, addProduct, deleteProduct, stockOf } = useErp();
  const { user, can } = useAuth();
  const write = can("datos", "write");
  const [tab, setTab] = useState<Tab>("resumen");
  const [selectedId, setSelectedId] = useState("venta");
  const [tableKey, setTableKey] = useState<keyof ErpDatabase>("sales");
  const [saleId, setSaleId] = useState(db.sales[0]?.id ?? "");

  const selected = schemaEntities.find((item) => item.id === selectedId) ?? schemaEntities[0];
  const related = schemaRelations.filter((item) => item.from === selected.id || item.to === selected.id);
  const inventoryValue = db.lots.reduce((sum, lot) => sum + lot.quantity * lot.unitCost, 0);
  const salesTotal = db.sales.filter((item) => item.status === "completed").reduce((sum, item) => sum + item.total, 0);
  const debit = db.accounting.reduce((sum, item) => sum + item.debit, 0);
  const credit = db.accounting.reduce((sum, item) => sum + item.credit, 0);
  const balanced = Math.abs(debit - credit) < 0.01;

  const sale = db.sales.find((item) => item.id === saleId) ?? db.sales[0];
  const saleProduct = db.products.find((item) => item.id === sale?.items[0]?.productId);
  const saleKardex = db.kardex.find((item) => item.reason.includes(sale?.saleNumber ?? ""));
  const saleEntry = db.accounting.find((item) => item.referenceId === sale?.id);
  const saleCash = db.cash.find((item) => item.concept.includes(sale?.saleNumber ?? ""));

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    addProduct(
      {
        code: String(data.get("code")),
        name: String(data.get("name")),
        category: String(data.get("category")),
        unitPrice: Number(data.get("unitPrice")),
        minQuantity: Number(data.get("minQuantity"))
      },
      user?.name ?? "sistema"
    );
    event.currentTarget.reset();
  };

  const table = tableCatalog.find((item) => item.key === tableKey) ?? tableCatalog[0];
  const tableRows = useMemo(() => {
    const rows = (db[table.key] as unknown as Array<Record<string, unknown>>) ?? [];
    return rows.slice(0, 40);
  }, [db, table.key]);

  return (
    <motion.div className="space-y-5" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}>
      <PageHeader
        kicker="Gobierno"
        title="Base de datos"
        subtitle="Productos, lotes, ventas y asientos en el mismo almacén."
        actions={
          <div className="flex flex-wrap gap-2">
            <Link to="/metodologia"><Button variant="secondary">Modelos</Button></Link>
            <Link to="/ers"><Button variant="ghost">Requerimientos</Button></Link>
          </div>
        }
      />

      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-900 via-brand-700 to-cyan-600 p-5 text-white shadow-soft">
        <div className="pointer-events-none absolute -right-10 top-0 h-40 w-40 rounded-full bg-white/10 blur-2xl" />
        <div className="relative grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <Pulse icon={<Database size={18} />} label="Entidades" value={String(schemaEntities.length)} hint="Catálogo maestro" />
          <Pulse icon={<Layers3 size={18} />} label="Registros" value={String(schemaEntities.reduce((sum, item) => sum + countEntity(db, item), 0))} hint="Operación del día" />
          <Pulse icon={<ShieldCheck size={18} />} label="Partida doble" value={balanced ? "OK" : "Descuadre"} hint={balanced ? "Débito = crédito" : "Revisar asientos"} />
          <Pulse icon={<Workflow size={18} />} label="Inventario PEPS" value="" amount={inventoryValue} hint="Lotes en bodega" />
        </div>
      </section>

      <div className="flex flex-wrap gap-2">
        {(
          [
            ["resumen", "Resumen"],
            ["modelo", "Relaciones"],
            ["clases", "Estructura"],
            ["objetos", "Instantánea"],
            ["acid", "Cobro"],
            ["tablas", "Tablas"],
            ["productos", "Productos"]
          ] as const
        ).map(([id, label]) => (
          <Button key={id} variant={tab === id ? "primary" : "secondary"} onClick={() => setTab(id)}>
            {label}
          </Button>
        ))}
      </div>

      {tab === "resumen" && (
        <div className="space-y-4">
          <div className="grid gap-3 md:grid-cols-4">
            <Stat label="Productos" value={String(db.products.length)} />
            <Stat label="Ventas cobradas" value="" amount={salesTotal} />
            <Stat label="Asientos" value={String(db.accounting.length)} />
            <Stat label="OT de taller" value={String(db.production.length)} />
          </div>
        </div>
      )}

      {tab === "modelo" && (
        <div className="grid gap-4 xl:grid-cols-[1.2fr_.8fr]">
          <section className="space-y-4 rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
            <div className="flex items-center gap-2">
              <GitBranch size={18} className="text-brand-700" />
              <h2 className="font-extrabold">Relación entre áreas</h2>
            </div>
            <p className="text-sm text-slate-500">Taller, bodega, caja y gobierno conectados.</p>
            {groups.map((group) => (
              <div key={group}>
                <p className="mb-2 text-xs font-bold uppercase tracking-wide text-slate-400">{group}</p>
                <div className="flex flex-wrap gap-2">
                  {schemaEntities.filter((item) => item.group === group).map((item) => (
                    <button
                      key={item.id}
                      type="button"
                      onClick={() => setSelectedId(item.id)}
                      className={`rounded-xl border px-3 py-2 text-left transition ${
                        selected.id === item.id
                          ? "border-brand-500 bg-brand-50 shadow-soft dark:bg-brand-500/10"
                          : "border-slate-200 bg-white hover:border-brand-200 dark:border-white/10 dark:bg-slate-950"
                      }`}
                    >
                      <p className="text-sm font-extrabold">{item.name}</p>
                      <p className="text-[11px] text-slate-500">{countEntity(db, item)} registros</p>
                    </button>
                  ))}
                </div>
              </div>
            ))}
          </section>
          <EntityCard entity={selected} related={related} count={countEntity(db, selected)} />
        </div>
      )}

      {tab === "clases" && (
        <div className="grid gap-4 xl:grid-cols-[1fr_320px]">
          <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
            {schemaEntities.map((item) => (
              <button key={item.id} type="button" onClick={() => setSelectedId(item.id)} className="text-left">
                <UmlClassBox entity={item} active={selected.id === item.id} />
              </button>
            ))}
          </section>
          <aside className="h-fit space-y-3 rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
            <h2 className="font-extrabold">Vínculos</h2>
            <p className="text-sm text-slate-500">Cliente y proveedor comparten ficha. La venta arrastra asiento, kardex y caja.</p>
            {schemaRelations.slice(0, 9).map((item) => (
              <p key={`${item.from}-${item.to}`} className="rounded-lg bg-slate-50 p-2 text-xs dark:bg-slate-950">
                <strong>{item.from}</strong> {item.kind} {item.to} · {item.multiplicity}
              </p>
            ))}
          </aside>
        </div>
      )}

      {tab === "objetos" && sale && (
        <div className="space-y-4">
          <section className="rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <div>
                <h2 className="font-extrabold">Foto del cobro</h2>
                <p className="text-sm text-slate-500">Cómo quedó esa factura en bodega, caja y contabilidad.</p>
              </div>
              <select className={inputClass + " max-w-xs"} value={sale.id} onChange={(event) => setSaleId(event.target.value)}>
                {db.sales.map((item) => (
                  <option key={item.id} value={item.id}>{item.saleNumber} · {item.clientName}</option>
                ))}
              </select>
            </div>
          </section>
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            <ObjectBox title=":Venta" values={[`${sale.saleNumber}`, `cliente = ${sale.clientName}`, `total = ${sale.total}`, `iva = ${sale.taxAmount}`, `estado = ${sale.status}`]} />
            <ObjectBox title=":Producto" values={[saleProduct?.code ?? "—", saleProduct?.name ?? "—", `precio = ${sale.items[0]?.unitPrice ?? 0}`, `qty = ${sale.items[0]?.quantity ?? 0}`]} />
            <ObjectBox title=":Kardex" values={[saleKardex?.type ?? "salida", saleKardex?.reason ?? sale.saleNumber, `costo = ${saleKardex?.unitCost ?? "PEPS"}`, saleKardex?.userName ?? sale.createdBy]} />
            <ObjectBox title=":AsientoContable" values={[saleEntry?.entryNumber ?? "—", saleEntry?.description ?? "espejo de venta", `débito = ${saleEntry?.debit ?? sale.total}`, `crédito = ${saleEntry?.credit ?? sale.total}`]} />
            <ObjectBox title=":Tesoreria" values={[saleCash?.account ?? "caja", saleCash?.type ?? "entrada", `monto = ${saleCash?.amount ?? sale.total}`, saleCash?.concept ?? sale.saleNumber]} />
            <ObjectBox title=":Usuario" values={[sale.createdBy, "rol = estándar ventas", "módulo = ventas", "deja auditoría"]} />
          </div>
        </div>
      )}

      {tab === "acid" && (
        <div className="space-y-4">
          <section className="rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
            <h2 className="font-extrabold">Cobro en un acto</h2>
            <p className="mt-1 text-sm text-slate-500">Stock, kardex, asiento y caja salen juntos.</p>
            <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-6">
              {acidPipeline.map((item) => (
                <article key={item.step} className="rounded-xl bg-slate-50 p-3 text-center dark:bg-slate-950">
                  <div className="mx-auto mb-2 grid h-10 w-10 place-items-center rounded-full bg-brand-600 text-sm font-extrabold text-white">{item.step}</div>
                  <p className="text-sm font-extrabold">{item.title}</p>
                  <p className="mt-1 text-xs text-slate-500">{item.detail}</p>
                </article>
              ))}
            </div>
          </section>
          <section className="grid gap-4 xl:grid-cols-2">
            <article className="rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
              <h3 className="font-extrabold">Estados de la orden de taller</h3>
              <div className="mt-4 flex flex-wrap gap-2">
                {otStates.map((stage, index) => (
                  <span key={stage} className="rounded-full bg-brand-50 px-3 py-1 text-xs font-bold text-brand-800 dark:bg-brand-500/10 dark:text-cyan-100">
                    {index + 1}. {stage}
                    {index < otStates.length - 1 ? " →" : ""}
                  </span>
                ))}
              </div>
              <p className="mt-3 text-sm text-slate-500">La orden avanza en el tablero de taller.</p>
            </article>
            <article className="rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
              <h3 className="font-extrabold">Estados de la proforma</h3>
              <div className="mt-4 flex flex-wrap gap-2">
                {proformaStates.map((stage) => (
                  <span key={stage} className="rounded-full bg-amber-50 px-3 py-1 text-xs font-bold text-amber-800 dark:bg-amber-500/10 dark:text-amber-100">{stage}</span>
                ))}
              </div>
              <p className="mt-3 text-sm text-slate-500">Si la aceptan, pasa a factura con el mismo cobro.</p>
            </article>
          </section>
        </div>
      )}

      {tab === "tablas" && (
        <section className="space-y-4 rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
          <div className="flex flex-wrap gap-2">
            {tableCatalog.map((item) => (
              <Button key={item.key} variant={table.key === item.key ? "primary" : "secondary"} onClick={() => setTableKey(item.key)}>
                {item.label}
              </Button>
            ))}
          </div>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] text-sm">
              <thead className="bg-brand-900 text-left text-xs uppercase tracking-wide text-cyan-50">
                <tr>
                  {table.cols.map((col) => (
                    <th key={col} className="p-3">{col}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {tableRows.map((row, index) => (
                  <tr key={String(row.id ?? index)} className="border-t border-slate-100 dark:border-white/10">
                    {table.cols.map((col) => (
                      <td key={col} className="p-2">
                        {formatCell(row[col])}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {tab === "productos" && (
        <div className="space-y-4">
          {write && (
            <form onSubmit={submit} className="grid gap-3 rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900 md:grid-cols-5">
              <Field label="Código"><input name="code" required className={inputClass} /></Field>
              <Field label="Nombre"><input name="name" required className={inputClass} /></Field>
              <Field label="Categoría"><input name="category" required className={inputClass} /></Field>
              <Field label="Precio"><input name="unitPrice" type="number" required className={inputClass} /></Field>
              <Field label="Mínimo"><input name="minQuantity" type="number" required className={inputClass} /></Field>
              <div className="md:col-span-5"><Button>Alta de producto</Button></div>
            </form>
          )}
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {db.products.map((item) => {
              const stock = stockOf(item.id);
              return (
                <article key={item.id} className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="text-xs font-bold text-brand-700">{item.code}</p>
                      <h3 className="font-extrabold">{item.name}</h3>
                      <p className="text-sm text-slate-500">{item.category} · stock {stock}</p>
                    </div>
                    <StatusPill tone={stock < item.minQuantity ? "bad" : "ok"}>{stock < item.minQuantity ? "Crítico" : "OK"}</StatusPill>
                  </div>
                  {write && <Button variant="danger" className="mt-3" onClick={() => {
                    if (!deleteProduct(item.id, user?.name ?? "sistema")) {
                      window.alert("No se puede eliminar: el producto tiene movimientos o documentos asociados.");
                    }
                  }}>Eliminar</Button>}
                </article>
              );
            })}
          </div>
        </div>
      )}
    </motion.div>
  );
}

function Pulse({ icon, label, value, amount, hint }: { icon: ReactNode; label: string; value: string; amount?: number; hint: string }) {
  return (
    <div className="rounded-xl bg-white/10 p-4 backdrop-blur">
      <div className="text-cyan-100">{icon}</div>
      <p className="mt-2 text-xs font-bold uppercase tracking-wide text-cyan-100">{label}</p>
      <p className="text-2xl font-black">{amount != null ? <Money value={amount} /> : value}</p>
      <p className="text-xs text-cyan-50/80">{hint}</p>
    </div>
  );
}

function Stat({ label, value, amount }: { label: string; value: string; amount?: number }) {
  return (
    <article className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
      <p className="text-sm text-slate-500">{label}</p>
      <strong className="text-2xl">{amount != null ? <Money value={amount} /> : value}</strong>
    </article>
  );
}

function EntityCard({ entity, related, count }: { entity: SchemaEntity; related: typeof schemaRelations; count: number }) {
  return (
    <aside className="h-fit rounded-xl bg-white p-5 shadow-soft dark:bg-slate-900">
      <p className="font-mono text-xs font-extrabold text-brand-700">{entity.umlClass}</p>
      <h2 className="mt-1 text-xl font-black">{entity.name}</h2>
      <div className="mt-2 flex flex-wrap gap-1.5">
        <StatusPill tone="ok">{entity.stereotype}</StatusPill>
        <StatusPill>{count} objetos</StatusPill>
      </div>
      <p className="mt-3 text-sm text-slate-500">{entity.stereotype}</p>
      <h3 className="mt-4 text-xs font-bold uppercase tracking-wide text-slate-400">Cardinalidades</h3>
      <div className="mt-2 space-y-2">
        {related.map((item) => (
          <p key={`${item.from}-${item.to}`} className="flex items-start gap-2 text-sm">
            <Link2 size={14} className="mt-1 text-brand-600" />
            <span>
              <strong>{item.label}</strong> · {item.kind} {item.multiplicity}
              <span className="block text-xs text-slate-500">{item.from} → {item.to}</span>
            </span>
          </p>
        ))}
      </div>
    </aside>
  );
}

function UmlClassBox({ entity, active }: { entity: SchemaEntity; active: boolean }) {
  return (
    <article className={`overflow-hidden rounded-xl border bg-white text-sm shadow-soft dark:bg-slate-900 ${active ? "border-brand-500" : "border-slate-200 dark:border-white/10"}`}>
      <header className="bg-brand-900 px-3 py-2 text-center text-white">
        <p className="text-[10px] uppercase tracking-wide text-cyan-100">«{entity.stereotype}»</p>
        <h3 className="font-extrabold">{entity.umlClass}</h3>
      </header>
      <ul className="border-t border-slate-100 px-3 py-2 font-mono text-[11px] dark:border-white/10">
        {entity.attributes.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
      <ul className="border-t border-slate-100 px-3 py-2 font-mono text-[11px] text-brand-800 dark:border-white/10 dark:text-cyan-100">
        {entity.operations.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </article>
  );
}

function ObjectBox({ title, values }: { title: string; values: string[] }) {
  return (
    <article className="rounded-xl border border-dashed border-brand-300 bg-white p-4 shadow-soft dark:border-brand-500/30 dark:bg-slate-900">
      <p className="text-center font-extrabold text-brand-800 dark:text-cyan-100">{title}</p>
      <ul className="mt-3 space-y-1 font-mono text-xs text-slate-600 dark:text-slate-300">
        {values.map((item) => (
          <li key={item}>{item}</li>
        ))}
      </ul>
    </article>
  );
}

function formatCell(value: unknown) {
  if (value == null) return "—";
  if (typeof value === "number") return value.toLocaleString("es-NI");
  if (typeof value === "string" && value.includes("T") && value.includes("Z")) return value.slice(0, 16).replace("T", " ");
  return String(value);
}

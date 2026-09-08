import { FormEvent, useState } from "react";
import { Database } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { Field, inputClass, Money, PageHeader, StatusPill } from "../components/Ui";
import { useErp } from "../store/erpStore";

export default function DataHubPage() {
  const { db, addProduct, deleteProduct, stockOf } = useErp();
  const { user, can } = useAuth();
  const write = can("datos", "write");
  const [tab, setTab] = useState<"resumen" | "productos" | "ventas" | "compras" | "asientos">("resumen");

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    addProduct({
      code: String(data.get("code")),
      name: String(data.get("name")),
      category: String(data.get("category")),
      unitPrice: Number(data.get("unitPrice")),
      minQuantity: Number(data.get("minQuantity"))
    }, user?.name ?? "sistema");
    event.currentTarget.reset();
  };

  const inventoryValue = db.lots.reduce((sum, lot) => sum + lot.quantity * lot.unitCost, 0);
  const sales = db.sales.filter((item) => item.status === "completed").reduce((sum, item) => sum + item.total, 0);

  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Datos"
        title="Base central"
        subtitle="Productos, ventas, compras y asientos en un solo lugar."
      />
      <div className="flex flex-wrap gap-2">
        {(["resumen", "productos", "ventas", "compras", "asientos"] as const).map((item) => (
          <Button key={item} variant={tab === item ? "primary" : "secondary"} onClick={() => setTab(item)}>{item}</Button>
        ))}
      </div>
      {tab === "resumen" && (
        <div className="grid gap-3 md:grid-cols-4">
          <Stat icon={<Database size={18} />} label="Productos" value={String(db.products.length)} />
          <Stat icon={<Database size={18} />} label="Valor inventario" value="" amount={inventoryValue} />
          <Stat icon={<Database size={18} />} label="Ventas" value="" amount={sales} />
          <Stat icon={<Database size={18} />} label="Asientos" value={String(db.accounting.length)} />
        </div>
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
                  {write && <Button variant="danger" className="mt-3" onClick={() => deleteProduct(item.id, user?.name ?? "sistema")}>Eliminar</Button>}
                </article>
              );
            })}
          </div>
        </div>
      )}
      {tab === "ventas" && <Simple rows={db.sales.map((item) => [item.saleNumber, item.clientName, item.total])} />}
      {tab === "compras" && <Simple rows={db.purchases.map((item) => [item.purchaseNumber, item.supplierName, item.total])} />}
      {tab === "asientos" && <Simple rows={db.accounting.map((item) => [item.entryNumber, item.description, item.debit])} />}
    </div>
  );
}

function Stat({ icon, label, value, amount }: { icon: React.ReactNode; label: string; value: string; amount?: number }) {
  return (
    <article className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
      <div className="text-brand-600">{icon}</div>
      <p className="mt-2 text-sm text-slate-500">{label}</p>
      <strong className="text-2xl">{amount != null ? <Money value={amount} /> : value}</strong>
    </article>
  );
}

function Simple({ rows }: { rows: [string, string, number][] }) {
  return (
    <section className="overflow-x-auto rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
      <table className="w-full text-sm">
        <tbody>
          {rows.map((row) => (
            <tr key={row[0]} className="border-t border-slate-100 dark:border-white/10">
              <td className="p-2 font-bold text-brand-700">{row[0]}</td>
              <td>{row[1]}</td>
              <td className="text-right"><Money value={row[2]} /></td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

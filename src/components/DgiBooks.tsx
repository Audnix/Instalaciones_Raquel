import { useMemo, useState } from "react";
import { Money, StatusPill } from "./Ui";
import { buildDmi, companyFiscal, monthKey, monthLabel } from "../lib/dgiNi";
import { useErp } from "../store/erpStore";

export function DgiBooks() {
  const { db } = useErp();
  const [month, setMonth] = useState(monthKey());
  const dmi = useMemo(() => buildDmi(db.sales, db.purchases, month), [db.purchases, db.sales, month]);
  const months = useMemo(() => {
    const keys = new Set([monthKey(), ...db.sales.map((item) => item.saleDate.slice(0, 7)), ...db.purchases.map((item) => item.purchaseDate.slice(0, 7))]);
    return [...keys].sort().reverse();
  }, [db.purchases, db.sales]);

  return (
    <section className="space-y-4 rounded-2xl bg-white p-5 shadow-soft dark:bg-slate-900">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand-700">DGI Nicaragua</p>
          <h2 className="mt-1 font-black">Libro del mes · {companyFiscal.regimen}</h2>
          <p className="text-sm text-slate-500">RUC {companyFiscal.ruc} · IVA 15% · {companyFiscal.dmiHint}</p>
        </div>
        <select className="h-10 rounded-lg border border-slate-200 bg-white px-3 text-sm dark:border-white/10 dark:bg-slate-950" value={month} onChange={(e) => setMonth(e.target.value)}>
          {months.map((item) => (
            <option key={item} value={item}>{monthLabel(item)}</option>
          ))}
        </select>
      </div>
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <Stat label="Ventas con IVA" value={dmi.saleTotal} />
        <Stat label="IVA débito" value={dmi.saleIva} />
        <Stat label="IVA crédito compras" value={dmi.buyIva} />
        <article className="rounded-xl bg-slate-50 p-3 dark:bg-slate-950">
          <p className="text-xs text-slate-500">IVA a pagar</p>
          <p className="mt-1 text-lg font-black"><Money value={Math.max(0, dmi.ivaPagar)} /></p>
          <StatusPill tone={dmi.ivaPagar >= 0 ? "ok" : "warn"}>{dmi.ivaPagar >= 0 ? "Débito" : "Saldo a favor"}</StatusPill>
        </article>
      </div>
      <div className="grid gap-3 md:grid-cols-3">
        <p className="rounded-xl bg-cyan-50 px-3 py-2 text-xs text-cyan-900 dark:bg-cyan-500/10 dark:text-cyan-100">Retención IR 2% (código 22, compras ≥ C$ 1,000): <strong><Money value={dmi.retencion} /></strong></p>
        <p className="rounded-xl bg-amber-50 px-3 py-2 text-xs text-amber-900 dark:bg-amber-500/10 dark:text-amber-100">Anticipo IR 1% sobre ventas: <strong><Money value={dmi.anticipo} /></strong></p>
        <p className="rounded-xl bg-slate-100 px-3 py-2 text-xs text-slate-700 dark:bg-slate-800 dark:text-slate-200">IM municipal 1%: <strong><Money value={dmi.im} /></strong></p>
      </div>
      <div className="grid gap-4 xl:grid-cols-2">
        <MiniTable
          title="Libro de ventas"
          rows={dmi.saleRows.map((item) => [item.saleNumber, item.clientName, item.saleDate.slice(0, 10), item.total])}
        />
        <MiniTable
          title="Libro de compras"
          rows={dmi.buyRows.map((item) => [item.purchaseNumber, item.supplierName, item.purchaseDate.slice(0, 10), item.total])}
        />
      </div>
    </section>
  );
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <article className="rounded-xl bg-slate-50 p-3 dark:bg-slate-950">
      <p className="text-xs text-slate-500">{label}</p>
      <p className="mt-1 text-lg font-black"><Money value={value} /></p>
    </article>
  );
}

function MiniTable({ title, rows }: { title: string; rows: Array<[string, string, string, number]> }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-slate-100 dark:border-white/10">
      <p className="px-3 py-2 text-xs font-bold uppercase tracking-wide text-slate-400">{title}</p>
      <table className="w-full text-sm">
        <tbody>
          {rows.length === 0 && (
            <tr><td className="p-3 text-slate-400">Sin movimientos en este mes.</td></tr>
          )}
          {rows.map((row) => (
            <tr key={row[0]} className="border-t border-slate-100 dark:border-white/10">
              <td className="p-2 font-bold">{row[0]}</td>
              <td className="p-2 text-slate-500">{row[1]}</td>
              <td className="p-2 text-xs">{row[2]}</td>
              <td className="p-2 text-right"><Money value={row[3]} /></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

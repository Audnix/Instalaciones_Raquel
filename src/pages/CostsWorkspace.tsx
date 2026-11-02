import { useSessionView } from "../lib/useSessionView";
﻿import { useMemo, useState } from 'react';
import { useErp } from '../store/erpStore';
import { Field, inputClass, Money, PageHeader, StatusPill } from '../components/Ui';
import { displayText, materialCosts } from '../lib/materialCosts';

export function CostsWorkspace() {
  const { db } = useErp();
  const [search, setSearch] = useSessionView("search", '');
  const rows = useMemo(() => materialCosts(db.products, db.lots), [db.products, db.lots]);
  const filtered = rows.filter(row => displayText(`${row.product.code} ${row.product.name}`).toLocaleLowerCase().includes(search.toLocaleLowerCase()));
  const total = rows.reduce((sum, row) => sum + row.value, 0);
  return <div className="space-y-5">
    <PageHeader kicker="Costos" title="Costos de materiales por lote" subtitle="Existencias y valor de los lotes registrados en SQL Server. Mano de obra y salarios no forman parte de esta consulta." />
    <div className="grid gap-4 md:grid-cols-3">
      <article className="rounded-2xl border border-cyan-100 bg-white p-5 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <p className="text-sm text-slate-500">Valor de materiales disponibles</p><div className="mt-2 text-2xl font-extrabold text-brand-700"><Money value={total} /></div>
      </article>
      <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <p className="text-sm text-slate-500">Productos con existencias</p><p className="mt-2 text-2xl font-extrabold">{rows.filter(row => row.quantity > 0).length}</p>
      </article>
      <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-soft dark:border-white/10 dark:bg-slate-900">
        <p className="text-sm text-slate-500">Productos sin existencias</p><p className="mt-2 text-2xl font-extrabold">{rows.filter(row => row.quantity <= 0).length}</p>
      </article>
    </div>
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-soft dark:border-white/10 dark:bg-slate-900">
      <div className="flex flex-wrap items-end justify-between gap-4 border-b border-slate-100 p-5 dark:border-white/10">
        <div><h2 className="font-extrabold">Valor por producto</h2><p className="mt-1 text-sm text-slate-500">El valor se calcula como cantidad disponible por costo de cada lote.</p></div>
        <Field label="Buscar producto"><input className={inputClass} value={search} onChange={event => setSearch(event.target.value)} placeholder="Nombre o código" /></Field>
      </div>
      <div className="overflow-x-auto"><table className="w-full text-sm">
        <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500 dark:bg-slate-950"><tr>
          <th className="px-5 py-4 text-left">Producto</th><th className="px-5 py-4 text-right">Existencias</th><th className="px-5 py-4 text-right">Costo unitario promedio</th><th className="px-5 py-4 text-right">Valor de materiales</th><th className="px-5 py-4 text-left">Lotes</th>
        </tr></thead>
        <tbody className="divide-y divide-slate-100 dark:divide-white/10">{filtered.map(row => <tr key={row.product.id} className="hover:bg-slate-50 dark:hover:bg-white/5">
          <td className="px-5 py-4"><p className="font-semibold">{displayText(row.product.name)}</p><p className="mt-1 text-xs text-slate-500">{row.product.code}</p></td>
          <td className="whitespace-nowrap px-5 py-4 text-right tabular-nums">{row.quantity.toLocaleString('es-NI')} {displayText(row.product.unit ?? '')}</td>
          <td className="whitespace-nowrap px-5 py-4 text-right tabular-nums">{row.quantity > 0 ? <Money value={row.averageCost} /> : <span className="text-slate-400">Sin existencias</span>}</td>
          <td className="whitespace-nowrap px-5 py-4 text-right font-bold tabular-nums"><Money value={row.value} /></td>
          <td className="px-5 py-4"><details><summary className="cursor-pointer text-brand-700">Ver {row.lots.length} lote(s)</summary><ul className="mt-2 space-y-2 text-xs text-slate-500">{row.lots.map(lot => <li key={lot.id}>{lot.entryDate.slice(0, 10)} · {lot.quantity} × <Money value={lot.unitCost} /></li>)}</ul></details></td>
        </tr>)}</tbody>
        <tfoot className="border-t border-slate-200 bg-slate-50 font-bold dark:border-white/10 dark:bg-slate-950"><tr><td colSpan={3} className="px-5 py-4">Total de productos mostrados ({filtered.length})</td><td className="px-5 py-4 text-right"><Money value={filtered.reduce((sum, row) => sum + row.value, 0)} /></td><td /></tr></tfoot>
      </table></div>
      {!filtered.length && <p className="p-6 text-center text-slate-500">No hay productos que coincidan con la búsqueda.</p>}
    </section>
    <StatusPill tone="neutral">Consulta de materiales; no modifica inventario ni realiza pagos.</StatusPill>
  </div>;
}

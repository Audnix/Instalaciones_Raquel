import { useMemo, useState } from "react";
import { Download, Filter, Search, Settings2 } from "lucide-react";
import { rows } from "../data/erpData";
import { Button } from "./Button";

export function DataTable() {
  const [query, setQuery] = useState("");
  const filtered = useMemo(
    () => rows.filter((row) => Object.values(row).join(" ").toLowerCase().includes(query.toLowerCase())),
    [query]
  );

  return (
    <section className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
      <div className="flex flex-col gap-3 pb-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 className="text-lg font-extrabold text-ink dark:text-white">Operaciones recientes</h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">Ventas, inventario, proyectos y aprobaciones en una sola vista.</p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <label className="relative">
            <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={17} />
            <input
              className="h-10 w-full rounded-lg border border-slate-200 bg-slate-50 pl-9 pr-3 text-sm outline-none transition focus:border-brand-500 focus:bg-white dark:border-white/10 dark:bg-slate-950 dark:text-white"
              placeholder="Buscar"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
            />
          </label>
          <Button variant="secondary" icon={<Filter size={17} />}>Filtros</Button>
          <Button variant="secondary" icon={<Settings2 size={17} />}>Columnas</Button>
          <Button icon={<Download size={17} />}>Exportar</Button>
        </div>
      </div>
      <div className="table-scrollbar overflow-x-auto">
        <table className="min-w-[820px] w-full border-separate border-spacing-y-2 text-left text-sm">
          <thead className="text-xs uppercase tracking-wide text-slate-400">
            <tr>
              <th className="px-3 py-2"><input aria-label="Seleccionar todos" type="checkbox" /></th>
              <th className="px-3 py-2">Codigo</th>
              <th className="px-3 py-2">Operacion</th>
              <th className="px-3 py-2">Responsable</th>
              <th className="px-3 py-2">Monto / Cantidad</th>
              <th className="px-3 py-2">Estado</th>
              <th className="px-3 py-2">Avance</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((row) => (
              <tr key={row.code} className="rounded-lg bg-slate-50 transition hover:bg-brand-50 dark:bg-slate-950/70 dark:hover:bg-white/10">
                <td className="rounded-l-lg px-3 py-3"><input aria-label={`Seleccionar ${row.code}`} type="checkbox" /></td>
                <td className="px-3 py-3 font-bold text-brand-700 dark:text-glass">{row.code}</td>
                <td className="px-3 py-3">
                  <div className="font-semibold text-ink dark:text-white">{row.name}</div>
                  <div className="text-xs text-slate-500">{row.client}</div>
                </td>
                <td className="px-3 py-3 text-slate-600 dark:text-slate-300">{row.owner}</td>
                <td className="px-3 py-3 font-semibold text-slate-700 dark:text-slate-200">{row.amount}</td>
                <td className="px-3 py-3">
                  <span className="rounded-full bg-white px-3 py-1 text-xs font-bold text-slate-600 shadow-sm dark:bg-slate-800 dark:text-slate-200">
                    {row.state}
                  </span>
                </td>
                <td className="rounded-r-lg px-3 py-3">
                  <div className="flex items-center gap-2">
                    <div className="h-2 w-24 rounded-full bg-slate-200 dark:bg-slate-800">
                      <div className="h-full rounded-full bg-brand-500" style={{ width: `${row.progress}%` }} />
                    </div>
                    <span className="text-xs font-bold text-slate-500">{row.progress}%</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

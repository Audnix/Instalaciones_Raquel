import { PageHeader, StatusPill } from "../components/Ui";

const reports = [
  { category: "Finanzas", name: "Flujo de dinero por período", source: "Movimientos de caja y bancos; servicio de lectura pendiente" },
  { category: "Contabilidad", name: "Resultado y asientos", source: "Libro contable; consulta de reporte autorizada pendiente" },
  { category: "Operación", name: "Presupuesto y costo real por proyecto", source: "Proyectos y etapas de costo; relación transaccional pendiente" },
  { category: "Operación", name: "Consumo y desperdicio", source: "Kardex y órdenes; vínculo verificable pendiente" },
  { category: "Talento humano", name: "Nómina, vacaciones y contratos", source: "Datos personales y salariales; API con permiso explícito pendiente" },
  { category: "Cumplimiento", name: "Documentación por revisar", source: "Matriz de obligaciones y evidencia; persistencia pendiente" }
] as const;

export default function ReportsPage() {
  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Gobierno"
        title="Reportes e indicadores"
        subtitle="Catálogo propuesto. No se muestran cifras hasta verificar fuentes, filtros y autorización de exportación."
      />
      <p role="note" className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950 dark:border-amber-700 dark:bg-amber-950/40 dark:text-amber-100">
        Las proyecciones no son ingresos confirmados. Esta pantalla no ejecuta consultas ni exportaciones y no certifica el origen
        de datos; cada reporte requiere servicio backend, pruebas y filtros por período antes de publicarse.
      </p>
      <section className="grid gap-3 md:grid-cols-2">
        {reports.map((report) => (
          <article key={report.name} className="rounded-xl bg-white p-4 shadow-soft dark:bg-slate-900">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <p className="text-xs font-bold uppercase tracking-wide text-slate-500">{report.category}</p>
              <StatusPill tone="warn">Propuesta · fuente pendiente</StatusPill>
            </div>
            <h2 className="mt-2 font-extrabold">{report.name}</h2>
            <p className="mt-2 text-sm text-slate-500">{report.source}</p>
            <dl className="mt-3 grid gap-2 text-xs text-slate-500 sm:grid-cols-2">
              <div><dt className="font-bold">Período</dt><dd>No consultado</dd></div>
              <div><dt className="font-bold">Filtros</dt><dd>No disponibles</dd></div>
              <div><dt className="font-bold">Generación</dt><dd>No generado</dd></div>
              <div><dt className="font-bold">Exportación</dt><dd>No disponible</dd></div>
            </dl>
          </article>
        ))}
      </section>
    </div>
  );
}

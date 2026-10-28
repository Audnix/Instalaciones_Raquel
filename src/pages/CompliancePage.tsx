import { PageHeader, StatusPill } from "../components/Ui";

const obligations = [
  {
    area: "Laboral",
    obligation: "Revisar requisitos laborales aplicables",
    reference: "Ley 185 · Código del Trabajo",
    state: "Pendiente de revisión"
  },
  {
    area: "Seguridad y salud",
    obligation: "Revisar requisitos de higiene y seguridad aplicables",
    reference: "Ley 618 · Higiene y Seguridad del Trabajo",
    state: "Pendiente de revisión"
  },
  {
    area: "Datos personales",
    obligation: "Definir tratamiento y controles aplicables a datos personales",
    reference: "Ley 787 · Protección de Datos Personales",
    state: "Pendiente de revisión"
  },
  {
    area: "Tributaria",
    obligation: "Revisar obligaciones tributarias y reformas vigentes",
    reference: "Ley 822 · Concertación Tributaria y reformas",
    state: "Pendiente de revisión"
  },
  {
    area: "Tributaria",
    obligation: "Revisar obligaciones y procedimientos tributarios aplicables",
    reference: "Ley 562 · Código Tributario",
    state: "Pendiente de revisión"
  },
  {
    area: "Seguridad social",
    obligation: "Identificar normativa vigente y obligaciones aplicables",
    reference: "Normativa de INSS e INATEC por verificar",
    state: "Pendiente de revisión"
  }
] as const;

export default function CompliancePage() {
  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Gobierno · propuesta"
        title="Cumplimiento y documentos"
        subtitle="Matriz informativa para organizar una revisión futura; no es asesoría, dictamen ni certificación."
      />

      <section role="note" className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-sm text-amber-950 dark:border-amber-700 dark:bg-amber-950/40 dark:text-amber-100">
        Estas referencias no se han contrastado aquí con publicaciones oficiales vigentes. No hay responsables asignados,
        fechas de vencimiento, constancias ni evidencias registradas. El estado de cada fila es únicamente “Pendiente de revisión”.
      </section>

      <section className="overflow-x-auto rounded-xl bg-white p-4 shadow-soft dark:bg-slate-900">
        <h2 className="mb-3 font-extrabold">Matriz inicial de revisión</h2>
        <table className="w-full min-w-[760px] text-left text-sm">
          <thead className="text-xs uppercase text-slate-400">
            <tr>
              <th className="p-2">Área</th>
              <th className="p-2">Obligación por analizar</th>
              <th className="p-2">Referencia indicada</th>
              <th className="p-2">Estado</th>
            </tr>
          </thead>
          <tbody>
            {obligations.map((item) => (
              <tr key={`${item.area}-${item.reference}`} className="border-t border-slate-100 dark:border-white/10">
                <td className="p-2 font-semibold">{item.area}</td>
                <td className="p-2">{item.obligation}</td>
                <td className="p-2 text-slate-500">{item.reference}</td>
                <td className="p-2"><StatusPill tone="warn">{item.state}</StatusPill></td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <p className="text-xs text-slate-500">
        Esta pantalla es una propuesta de interfaz y usa una lista estática. No guarda documentos ni demuestra presentación,
        recepción o aceptación de trámites por una autoridad.
      </p>
    </div>
  );
}

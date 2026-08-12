import { useMemo } from "react";
import { useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { Plus, UploadCloud } from "lucide-react";
import { modules } from "../data/erpData";
import { Button } from "../components/Button";
import { DataTable } from "../components/DataTable";

export default function ModulePage() {
  const { moduleId } = useParams();
  const module = useMemo(() => modules.find((item) => item.id === moduleId) ?? modules[0], [moduleId]);
  const Icon = module.icon;

  return (
    <motion.div className="space-y-5" initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }}>
      <section className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div className="flex items-center gap-4">
            <div className={`grid h-14 w-14 place-items-center rounded-lg ${module.accent} text-white`}>
              <Icon size={26} />
            </div>
            <div>
              <p className="text-sm font-bold uppercase tracking-[0.18em] text-brand-700 dark:text-glass">Modulo ERP</p>
              <h1 className="text-2xl font-extrabold">{module.label}</h1>
            </div>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <Button variant="secondary" icon={<UploadCloud size={17} />}>Importar</Button>
            <Button icon={<Plus size={17} />}>Nuevo registro</Button>
          </div>
        </div>
      </section>
      <section className="grid gap-4 lg:grid-cols-3">
        {["Pendientes", "Aprobados", "Auditados"].map((item, index) => (
          <motion.article key={item} className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900" whileHover={{ y: -4 }}>
            <p className="text-sm text-slate-500">{item}</p>
            <strong className="mt-2 block text-3xl font-extrabold">{[18, 64, 143][index]}</strong>
            <div className="mt-4 h-2 rounded-full bg-slate-100 dark:bg-slate-800">
              <div className="h-full rounded-full bg-brand-500" style={{ width: `${[38, 72, 91][index]}%` }} />
            </div>
          </motion.article>
        ))}
      </section>
      <section className="grid gap-4 xl:grid-cols-[.68fr_1.32fr]">
        <form className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="text-lg font-extrabold">Registro inteligente</h2>
          <div className="mt-4 space-y-4">
            {["Nombre", "Responsable", "Fecha", "Monto estimado"].map((field) => (
              <label key={field} className="block">
                <span className="mb-1 block text-sm font-semibold">{field}</span>
                <input className="h-11 w-full rounded-lg border border-slate-200 bg-slate-50 px-3 outline-none transition focus:border-brand-500 focus:bg-white dark:border-white/10 dark:bg-slate-950" placeholder={field} />
              </label>
            ))}
            <label className="grid min-h-32 place-items-center rounded-lg border-2 border-dashed border-brand-200 bg-brand-50/50 text-center text-sm font-semibold text-brand-700 dark:border-brand-500/30 dark:bg-brand-500/10 dark:text-glass">
              <input type="file" className="sr-only" multiple />
              Adjuntos, fotos, facturas o planos
            </label>
            <Button className="w-full">Guardar borrador</Button>
          </div>
        </form>
        <DataTable />
      </section>
    </motion.div>
  );
}

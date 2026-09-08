import { motion } from "framer-motion";
import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { innovations, requirements, validationMatrix, type ReqEstado, type ReqFamilia } from "../data/requirements";
import { PageHeader, StatusPill } from "../components/Ui";
import { Button } from "../components/Button";

const familias: Array<ReqFamilia | "Todas"> = ["Todas", "RF", "RNF", "RD", "RU", "RS"];
const estados: Array<ReqEstado | "Todos"> = ["Todos", "Validado", "Parcial", "Innovación"];

function tone(estado: ReqEstado): "ok" | "warn" | "neutral" {
  if (estado === "Validado") return "ok";
  if (estado === "Parcial") return "warn";
  return "neutral";
}

export default function RequirementsPage() {
  const [familia, setFamilia] = useState<(typeof familias)[number]>("Todas");
  const [estado, setEstado] = useState<(typeof estados)[number]>("Todos");
  const [q, setQ] = useState("");

  const filtrados = useMemo(() => {
    return requirements.filter((item) => {
      const okF = familia === "Todas" || item.familia === familia;
      const okE = estado === "Todos" || item.estado === estado;
      const blob = `${item.id} ${item.nombre} ${item.descripcion} ${item.area}`.toLowerCase();
      const okQ = !q.trim() || blob.includes(q.trim().toLowerCase());
      return okF && okE && okQ;
    });
  }, [familia, estado, q]);

  const stats = useMemo(() => {
    const total = requirements.length;
    const validados = requirements.filter((item) => item.estado === "Validado").length;
    const funciones = validationMatrix.filter((item) => item.estado === "Validado").length;
    return { total, validados, funciones, cobertura: Math.round((validados / total) * 100) };
  }, []);

  return (
    <motion.div className="space-y-5" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}>
      <PageHeader
        kicker="Requerimientos"
        title="Catálogo del sistema"
        subtitle="Funciones, calidad, dominio y validación del prototipo."
      />

      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-900 via-brand-700 to-cyan-600 p-6 text-white shadow-soft">
        <div className="pointer-events-none absolute -right-10 -top-10 h-44 w-44 rounded-full bg-white/10 blur-2xl" />
        <div className="relative grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <PulseStat label="Requerimientos" value={String(stats.total)} hint="RF · RNF · RD · RU · RS" />
          <PulseStat label="Validados" value={String(stats.validados)} hint={`${stats.cobertura}% del catálogo`} />
          <PulseStat label="Funciones OK" value={`${stats.funciones}/${validationMatrix.length}`} hint="Matriz de validación" />
          <PulseStat label="Innovaciones" value="6" hint="Pulse · QR · Proformas" />
        </div>
        <div className="relative mt-4 flex flex-wrap gap-2">
          <Link to="/"><Button variant="secondary">Inicio</Button></Link>
          <Link to="/metodologia"><Button variant="ghost" className="!text-white hover:!bg-white/15">Modelos</Button></Link>
          <Link to="/ventas"><Button variant="ghost" className="!text-white hover:!bg-white/15">Ventas</Button></Link>
        </div>
      </section>

      <section className="flex flex-wrap gap-2">
        {familias.map((item) => (
          <button
            key={item}
            type="button"
            onClick={() => setFamilia(item)}
            className={`rounded-full px-3 py-1.5 text-xs font-bold transition ${familia === item ? "bg-brand-700 text-white" : "bg-white text-slate-600 shadow-soft dark:bg-slate-900 dark:text-slate-300"}`}
          >
            {item}
          </button>
        ))}
        <span className="mx-1 hidden h-8 w-px bg-slate-200 sm:block dark:bg-white/10" />
        {estados.map((item) => (
          <button
            key={item}
            type="button"
            onClick={() => setEstado(item)}
            className={`rounded-full px-3 py-1.5 text-xs font-bold transition ${estado === item ? "bg-moss text-white" : "bg-white text-slate-600 shadow-soft dark:bg-slate-900 dark:text-slate-300"}`}
          >
            {item}
          </button>
        ))}
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Buscar RF01, PEPS, IVA…"
          className="ml-auto h-9 min-w-[180px] flex-1 rounded-full border border-slate-200 bg-white px-4 text-sm dark:border-white/10 dark:bg-slate-900 sm:max-w-xs"
        />
      </section>

      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {filtrados.map((item, index) => (
          <motion.article
            key={item.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: Math.min(index * 0.02, 0.3) }}
            className="rounded-xl border border-slate-100 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900"
          >
            <div className="flex items-start justify-between gap-2">
              <div>
                <p className="font-mono text-xs font-extrabold text-brand-700">{item.id}</p>
                <h3 className="mt-1 font-extrabold leading-snug">{item.nombre}</h3>
              </div>
              <StatusPill tone={tone(item.estado)}>{item.estado}</StatusPill>
            </div>
            <div className="mt-2 flex flex-wrap gap-1.5">
              <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-slate-600 dark:bg-slate-800 dark:text-slate-300">{item.prioridad}</span>
              <span className="rounded-full bg-cyan-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-cyan-800 dark:bg-cyan-500/10 dark:text-cyan-200">{item.area}</span>
              <span className="rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wide text-amber-800 dark:bg-amber-500/10 dark:text-amber-200">{item.fuente}</span>
            </div>
            <dl className="mt-3 space-y-2 text-sm">
              <div>
                <dt className="text-xs font-bold uppercase tracking-wide text-slate-400">Características</dt>
                <dd className="text-slate-600 dark:text-slate-300">{item.caracteristicas}</dd>
              </div>
              <div>
                <dt className="text-xs font-bold uppercase tracking-wide text-slate-400">Descripción</dt>
                <dd className="text-slate-600 dark:text-slate-300">{item.descripcion}</dd>
              </div>
              <div>
                <dt className="text-xs font-bold uppercase tracking-wide text-slate-400">RNF / estándar</dt>
                <dd className="font-semibold text-brand-800 dark:text-cyan-200">{item.rnf}</dd>
              </div>
            </dl>
          </motion.article>
        ))}
      </section>

      <section className="space-y-3">
        <h2 className="text-lg font-extrabold">Matriz de validación de funciones</h2>
        <div className="overflow-x-auto rounded-xl bg-white shadow-soft dark:bg-slate-900">
          <table className="w-full min-w-[760px] text-sm">
            <thead className="bg-brand-900 text-left text-xs uppercase tracking-wide text-cyan-50">
              <tr>
                <th className="p-3">Función</th>
                <th className="p-3">Módulo</th>
                <th className="p-3">Req.</th>
                <th className="p-3">Estado</th>
                <th className="p-3">Evidencia</th>
              </tr>
            </thead>
            <tbody>
              {validationMatrix.map((row) => (
                <tr key={`${row.funcion}-${row.req}`} className="border-t border-slate-100 dark:border-white/10">
                  <td className="p-3 font-semibold">{row.funcion}</td>
                  <td className="p-3 text-slate-500">{row.modulo}</td>
                  <td className="p-3 font-mono text-xs font-bold text-brand-700">{row.req}</td>
                  <td className="p-3"><StatusPill tone={tone(row.estado)}>{row.estado}</StatusPill></td>
                  <td className="p-3 text-slate-500">{row.evidencia}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="space-y-3">
        <h2 className="text-lg font-extrabold">Raquel Pulse · innovaciones</h2>
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
          {innovations.map((item) => (
            <article key={item.id} className="rounded-xl bg-gradient-to-br from-white to-cyan-50 p-4 shadow-soft dark:from-slate-900 dark:to-slate-950">
              <StatusPill tone="ok">{item.id}</StatusPill>
              <h3 className="mt-2 font-extrabold">{item.title}</h3>
              <p className="mt-1 text-sm text-slate-600 dark:text-slate-300">{item.desc}</p>
            </article>
          ))}
        </div>
      </section>
    </motion.div>
  );
}

function PulseStat({ label, value, hint }: { label: string; value: string; hint: string }) {
  return (
    <div className="rounded-xl bg-white/10 p-4 backdrop-blur">
      <p className="text-xs font-bold uppercase tracking-wide text-cyan-100">{label}</p>
      <p className="mt-1 text-3xl font-black">{value}</p>
      <p className="text-xs text-cyan-50/80">{hint}</p>
    </div>
  );
}

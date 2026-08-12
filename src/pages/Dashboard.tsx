import { motion } from "framer-motion";
import { Area, AreaChart, Bar, BarChart, CartesianGrid, Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { activity, calendar, kpis, production, quickStats, revenue } from "../data/erpData";
import { DataTable } from "../components/DataTable";
import { KpiCard } from "../components/KpiCard";

const colors = ["#0a92c8", "#2f9b73", "#e84b5f", "#f59e0b", "#8b5cf6"];

export default function Dashboard() {
  return (
    <motion.div className="space-y-5" initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }}>
      <section className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p className="text-sm font-bold uppercase tracking-[0.18em] text-brand-700 dark:text-glass">Centro de mando</p>
          <h1 className="mt-1 text-3xl font-extrabold text-ink dark:text-white">Dashboard operativo</h1>
          <p className="mt-2 max-w-2xl text-sm text-slate-500 dark:text-slate-400">Ventas, compras, inventario, proyectos, caja, nomina y alertas criticas actualizadas para decisiones rapidas.</p>
        </div>
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
          {quickStats.map((item) => (
            <div key={item.label} className="rounded-lg bg-white p-3 shadow-soft dark:bg-slate-900">
              <item.icon className="mb-2 text-brand-600 dark:text-glass" size={18} />
              <p className="text-xs text-slate-500">{item.label}</p>
              <strong className="text-sm text-ink dark:text-white">{item.value}</strong>
            </div>
          ))}
        </div>
      </section>
      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {kpis.map((kpi) => <KpiCard key={kpi.label} {...kpi} />)}
      </section>
      <section className="grid gap-4 xl:grid-cols-[1.35fr_.65fr]">
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="text-lg font-extrabold">Rendimiento financiero</h2>
          <div className="mt-5 h-[320px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={revenue}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,.22)" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Area dataKey="ventas" stroke="#0a92c8" fill="#72d4ef" fillOpacity={0.2} strokeWidth={3} />
                <Area dataKey="costos" stroke="#e84b5f" fill="#e84b5f" fillOpacity={0.12} strokeWidth={2} />
                <Area dataKey="utilidad" stroke="#2f9b73" fill="#2f9b73" fillOpacity={0.14} strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </article>
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="text-lg font-extrabold">Produccion</h2>
          <div className="mt-4 h-[250px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={production} innerRadius={58} outerRadius={92} dataKey="value" paddingAngle={4}>
                  {production.map((entry, index) => <Cell key={entry.name} fill={colors[index]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="space-y-2">
            {production.map((item, index) => (
              <div key={item.name} className="flex items-center justify-between text-sm">
                <span className="flex items-center gap-2"><i className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: colors[index] }} />{item.name}</span>
                <strong>{item.value}%</strong>
              </div>
            ))}
          </div>
        </article>
      </section>
      <section className="grid gap-4 xl:grid-cols-[.72fr_1.28fr]">
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="text-lg font-extrabold">Agenda semanal</h2>
          <div className="mt-5 h-[220px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={calendar}>
                <XAxis dataKey="day" />
                <Tooltip />
                <Bar dataKey="count" radius={[8, 8, 0, 0]} fill="#0a92c8" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </article>
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="text-lg font-extrabold">Timeline</h2>
          <div className="mt-4 space-y-3">
            {activity.map((item) => (
              <motion.div key={item.title} className="flex gap-3 rounded-lg bg-slate-50 p-3 dark:bg-slate-950" whileHover={{ x: 5 }}>
                <span className="mt-1 h-3 w-3 rounded-full bg-brand-500 ring-4 ring-brand-100 dark:ring-brand-500/20" />
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-3">
                    <strong className="truncate text-sm">{item.title}</strong>
                    <span className="rounded-full bg-white px-2 py-1 text-xs font-bold text-brand-700 dark:bg-slate-800 dark:text-glass">{item.status}</span>
                  </div>
                  <p className="mt-1 text-xs text-slate-500">{item.meta}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </article>
      </section>
      <DataTable />
    </motion.div>
  );
}

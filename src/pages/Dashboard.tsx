import type { ReactNode } from "react";
import { motion } from "framer-motion";
import { Link } from "react-router-dom";
import { Area, AreaChart, CartesianGrid, Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useAuth } from "../auth/AuthContext";
import { hierarchyMeta } from "../auth/roles";
import { Button } from "../components/Button";
import { KpiCard } from "../components/KpiCard";
import { Money, PageHeader, StatusPill } from "../components/Ui";
import { modules } from "../data/erpData";
import { useErp } from "../store/erpStore";
import { BadgeDollarSign, Boxes, BriefcaseBusiness, CircleDollarSign, ScrollText, Sparkles } from "lucide-react";

const colors = ["#0a92c8", "#2f9b73", "#e84b5f", "#f59e0b", "#8b5cf6"];

export default function Dashboard() {
  const { db, stockOf } = useErp();
  const { user, canAccess } = useAuth();
  const sales = db.sales.filter((item) => item.status === "completed").reduce((sum, item) => sum + item.total, 0);
  const costs = db.purchases.filter((item) => item.status === "received").reduce((sum, item) => sum + item.total, 0);
  const criticalItems = db.products.filter((item) => stockOf(item.id) < item.minQuantity);
  const critical = criticalItems.length;
  const activeOt = db.production.filter((item) => item.stage !== "entregado").length;
  const margin = sales - costs;
  const openProformas = (db.proformas ?? []).filter((item) => item.status !== "convertida").length;
  const mix = db.products.map((item) => ({
    name: item.name,
    value: Math.max(1, db.sales.flatMap((sale) => sale.items).filter((row) => row.productId === item.id).reduce((sum, row) => sum + row.quantity, 0))
  }));

  return (
    <motion.div className="space-y-5" initial={{ opacity: 0, y: 18 }} animate={{ opacity: 1, y: 0 }}>
      <PageHeader
        kicker="Inicio"
        title={`Hola, ${user?.name ?? "equipo"}`}
        subtitle={user ? hierarchyMeta[user.hierarchy].label : ""}
      />

      <section className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand-900 via-brand-700 to-cyan-600 p-5 text-white shadow-soft">
        <div className="pointer-events-none absolute -right-8 top-0 h-40 w-40 rounded-full bg-white/10 blur-2xl" />
        <div className="relative flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-wide text-cyan-100">Hoy en taller</p>
            <h2 className="mt-1 text-2xl font-black">Instalaciones Raquel</h2>
            <p className="mt-1 max-w-xl text-sm text-cyan-50/90">Órdenes activas, stock corto, margen y proformas abiertas.</p>
          </div>
          <div className="flex flex-wrap gap-2">
            {canAccess("ers") && (
              <Link to="/ers"><Button variant="secondary" icon={<ScrollText size={16} />}>Requerimientos</Button></Link>
            )}
            <Link to="/ventas"><Button variant="ghost" className="!text-white hover:!bg-white/15" icon={<Sparkles size={16} />}>Facturar</Button></Link>
            {canAccess("metodologia") && (
              <Link to="/metodologia"><Button variant="ghost" className="!text-white hover:!bg-white/15">Cobro pantalla a pantalla</Button></Link>
            )}
          </div>
        </div>
        <div className="relative mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <PulseChip label="Margen" value={<Money value={margin} />} />
          <PulseChip label="OT activas" value={String(activeOt)} />
          <PulseChip label="Stock corto" value={String(critical)} />
          <PulseChip label="Proformas" value={String(openProformas)} />
        </div>
      </section>

      <section className="grid gap-3 md:grid-cols-3">
        {(db.promotions ?? []).filter((item) => item.active).slice(0, 3).map((item) => (
          <Link key={item.id} to="/ventas" className="rounded-2xl border border-amber-200 bg-gradient-to-br from-amber-50 to-white p-4 shadow-soft transition hover:-translate-y-0.5 dark:border-amber-500/20 dark:from-amber-500/10 dark:to-slate-900">
            <StatusPill tone="warn">{item.badge}</StatusPill>
            <h3 className="mt-2 font-extrabold">{item.title}</h3>
            <p className="text-sm text-slate-500">{item.blurb}</p>
          </Link>
        ))}
      </section>

      <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <KpiCard label="Ventas" value={sales.toLocaleString("es-NI", { style: "currency", currency: "NIO", maximumFractionDigits: 0 }).replace("NIO", "C$")} change="Registradas" tone="from-brand-600 to-cyan-500" icon={CircleDollarSign} />
        <KpiCard label="Compras" value={costs.toLocaleString("es-NI", { style: "currency", currency: "NIO", maximumFractionDigits: 0 }).replace("NIO", "C$")} change="Recibidas" tone="from-moss to-emerald-400" icon={BadgeDollarSign} />
        <KpiCard label="Proyectos" value={String(db.projects.length)} change="Obras" tone="from-amber-500 to-orange-400" icon={BriefcaseBusiness} />
        <KpiCard label="Stock crítico" value={String(critical)} change="Bodega" tone="from-ember to-rose-400" icon={Boxes} />
      </section>

      {criticalItems.length > 0 && (
        <section className="rounded-xl border border-rose-200 bg-rose-50 p-4 dark:border-rose-500/30 dark:bg-rose-500/10">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="font-extrabold text-rose-800 dark:text-rose-200">Stock bajo mínimo</h2>
            <Link to="/inventario" className="text-sm font-bold text-rose-700 underline dark:text-rose-200">Ir a inventario</Link>
          </div>
          <div className="mt-3 flex flex-wrap gap-2">
            {criticalItems.map((item) => (
              <StatusPill key={item.id} tone="bad">{item.name}: {stockOf(item.id)} / mín {item.minQuantity}</StatusPill>
            ))}
          </div>
        </section>
      )}

      <section className="grid gap-4 xl:grid-cols-[1.35fr_.65fr]">
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="text-lg font-extrabold">Proyección</h2>
          <div className="mt-5 h-[320px]">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={db.projections}>
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(148,163,184,.22)" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Area dataKey="expectedSales" name="ventas" stroke="#0a92c8" fill="#72d4ef" fillOpacity={0.2} strokeWidth={3} />
                <Area dataKey="expectedCosts" name="costos" stroke="#e84b5f" fill="#e84b5f" fillOpacity={0.12} strokeWidth={2} />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </article>
        <article className="rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="text-lg font-extrabold">Mix de producto</h2>
          <div className="mt-4 h-[250px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={mix} innerRadius={58} outerRadius={92} dataKey="value" paddingAngle={4}>
                  {mix.map((entry, index) => <Cell key={entry.name} fill={colors[index % colors.length]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </article>
      </section>

      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {modules.filter((item) => canAccess(item.id)).slice(0, 6).map((item, index) => (
          <motion.article
            key={item.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.04 }}
            className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900"
          >
            <StatusPill>{item.group}</StatusPill>
            <h3 className="mt-2 font-extrabold">{item.label}</h3>
            <p className="text-sm text-slate-500">{item.description}</p>
            <Link to={`/${item.id}`} className="mt-3 inline-block text-sm font-bold text-brand-700">Abrir →</Link>
          </motion.article>
        ))}
      </section>

      <section className="rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
        <h2 className="font-extrabold">Actividad reciente</h2>
        <div className="mt-3 space-y-2">
          {db.audit.slice(0, 6).map((item) => (
            <p key={item.id} className="text-sm"><strong>{item.userName}</strong> {item.action} en {item.module}: {item.detail}</p>
          ))}
        </div>
      </section>
    </motion.div>
  );
}

function PulseChip({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="rounded-xl bg-white/10 p-3 backdrop-blur">
      <p className="text-[11px] font-bold uppercase tracking-wide text-cyan-100">{label}</p>
      <div className="mt-1 text-xl font-black">{value}</div>
    </div>
  );
}

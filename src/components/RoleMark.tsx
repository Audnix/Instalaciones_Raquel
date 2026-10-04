import { Crown, Eye, Hammer, Shield } from "lucide-react";
import type { LucideIcon } from "lucide-react";
import { hierarchyMeta, powerLabels, rolePowers, type PowerValue, type RolePower } from "../auth/roles";
import type { HierarchyRole } from "../types/erp";

const icons: Record<HierarchyRole, LucideIcon> = {
  superadmin: Crown,
  administrador: Shield,
  estandar: Hammer,
  invitado: Eye
};

const tones: Record<HierarchyRole, string> = {
  superadmin: "bg-amber-100 text-amber-800 dark:bg-amber-500/20 dark:text-amber-200",
  administrador: "bg-sky-100 text-sky-800 dark:bg-sky-500/20 dark:text-sky-200",
  estandar: "bg-emerald-100 text-emerald-800 dark:bg-emerald-500/20 dark:text-emerald-200",
  invitado: "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300"
};

export function RoleIcon({ role, size = 16 }: { role: HierarchyRole; size?: number }) {
  const Icon = icons[role];
  return <Icon size={size} />;
}

export function RoleMark({ role, compact }: { role: HierarchyRole; compact?: boolean }) {
  const meta = hierarchyMeta[role];
  return (
    <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-extrabold ${tones[role]}`}>
      <RoleIcon role={role} size={13} />
      {compact ? meta.mark : `${meta.mark} · ${meta.markHint}`}
    </span>
  );
}

function cell(value: PowerValue) {
  if (value === true) return <span className="font-black text-emerald-600">●</span>;
  if (value === "área") return <span className="text-[10px] font-bold text-sky-700">área</span>;
  return <span className="text-slate-300">○</span>;
}

export function RolePowerGrid() {
  return (
    <section className="overflow-x-auto rounded-2xl bg-white p-4 shadow-soft dark:bg-slate-900">
      <div className="mb-3 flex flex-wrap items-end justify-between gap-2">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand-700">Simbología</p>
          <h2 className="mt-1 font-black">Quién administra y quién ejecuta</h2>
        </div>
        <p className="text-xs text-slate-500">● sí · ○ no · área = solo su equipo</p>
      </div>
      <table className="w-full min-w-[560px] text-sm">
        <thead className="text-left text-[11px] uppercase tracking-wide text-slate-400">
          <tr>
            <th className="p-2">Símbolo</th>
            {powerLabels.map((power) => (
              <th key={power} className="p-2 capitalize">{power}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {(Object.keys(hierarchyMeta) as HierarchyRole[]).map((role) => (
            <tr key={role} className="border-t border-slate-100 dark:border-white/10">
              <td className="p-2">
                <div className="flex items-center gap-2">
                  <RoleMark role={role} compact />
                  <span className="text-xs font-semibold">{hierarchyMeta[role].label}</span>
                </div>
              </td>
              {powerLabels.map((power: RolePower) => (
                <td key={power} className="p-2">{cell(rolePowers[role][power])}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

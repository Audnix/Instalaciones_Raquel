import { FormEvent, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { ShieldCheck } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { areaMeta, hierarchyMeta } from "../auth/roles";
import { Button } from "../components/Button";
import { RoleMark, RolePowerGrid } from "../components/RoleMark";
import { Field, inputClass, PageHeader, StatusPill } from "../components/Ui";
import { LOGIN_MAX_FAILS, loginFails, loginLockMs } from "../lib/loginGuard";
import { useErp } from "../store/erpStore";
import type { AreaRole, HierarchyRole, SessionUser } from "../types/erp";

const areas = Object.keys(areaMeta) as AreaRole[];

export default function UsersPage() {
  const { db, upsertUser } = useErp();
  const { user, can } = useAuth();
  const write = can("usuarios", "write") || user?.hierarchy === "superadmin" || user?.hierarchy === "administrador";
  const lockMs = loginLockMs();
  const fails = loginFails();
  const [form, setForm] = useState<SessionUser>({
    id: "",
    name: "",
    email: "",
    password: "raquel2026",
    hierarchy: "estandar",
    areas: ["ventas"],
    active: true
  });

  const sessionHint = useMemo(() => {
    if (!user) return "Sin sesión";
    const meta = hierarchyMeta[user.hierarchy];
    return `${meta.mark} · ${meta.markHint}`;
  }, [user]);

  const submit = (event: FormEvent) => {
    event.preventDefault();
    if (user?.hierarchy === "administrador" && form.hierarchy === "superadmin") return;
    upsertUser({ ...form, id: form.id || `u-${Date.now()}` }, user?.name ?? "sistema");
    setForm({ id: "", name: "", email: "", password: "raquel2026", hierarchy: "estandar", areas: ["ventas"], active: true });
  };

  return (
    <div className="space-y-5">
      <PageHeader
        kicker="Accesos"
        title="Quién entra y con qué poder"
        subtitle="Corona administra y ejecuta. Mano solo opera. Ojo solo mira."
      />

      <RolePowerGrid />

      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        {(Object.keys(hierarchyMeta) as HierarchyRole[]).map((key) => (
          <article key={key} className="rounded-2xl bg-white p-4 shadow-soft dark:bg-slate-900">
            <RoleMark role={key} />
            <h3 className="mt-3 font-extrabold">{hierarchyMeta[key].label}</h3>
            <p className="mt-2 text-sm text-slate-500">{hierarchyMeta[key].duty}</p>
          </article>
        ))}
      </section>

      <section className="grid gap-3 lg:grid-cols-3">
        <article className="rounded-2xl bg-slate-950 p-4 text-cyan-50">
          <p className="text-xs font-bold uppercase tracking-wide text-cyan-200">Sesión actual</p>
          <p className="mt-2 font-black">{user?.name ?? "—"}</p>
          <p className="text-sm text-cyan-100/80">{sessionHint}</p>
        </article>
        <article className="rounded-2xl bg-white p-4 shadow-soft dark:bg-slate-900">
          <p className="text-xs font-bold uppercase tracking-wide text-slate-400">Candado de clave</p>
          <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">
            Tras {LOGIN_MAX_FAILS} intentos malos se cierra 90 s.
            {fails ? ` Llevás ${fails}.` : " Sin fallos en esta sesión."}
          </p>
          {lockMs > 0 && <StatusPill tone="bad">Bloqueado {Math.ceil(lockMs / 1000)} s</StatusPill>}
        </article>
        <article className="rounded-2xl bg-white p-4 shadow-soft dark:bg-slate-900">
          <p className="text-xs font-bold uppercase tracking-wide text-slate-400">Huella</p>
          <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">Cada acceso y cada cambio de usuario queda sellado.</p>
          <Link to="/auditoria" className="mt-3 inline-flex">
            <Button variant="secondary" icon={<ShieldCheck size={16} />}>Ver sello</Button>
          </Link>
        </article>
      </section>

      {write && (
        <form onSubmit={submit} className="space-y-4 rounded-lg bg-white p-5 shadow-soft dark:bg-slate-900">
          <h2 className="font-extrabold">{form.id ? "Editar usuario" : "Nuevo usuario"}</h2>
          <div className="grid gap-3 md:grid-cols-2">
            <Field label="Nombre"><input className={inputClass} required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></Field>
            <Field label="Correo"><input className={inputClass} type="email" required value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></Field>
            <Field label="Contraseña"><input className={inputClass} type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} /></Field>
            <Field label="Jerarquía">
              <select className={inputClass} value={form.hierarchy} onChange={(e) => setForm({ ...form, hierarchy: e.target.value as HierarchyRole })}>
                {(Object.keys(hierarchyMeta) as HierarchyRole[])
                  .filter((key) => user?.hierarchy === "superadmin" || key !== "superadmin")
                  .map((key) => <option key={key} value={key}>{hierarchyMeta[key].mark} · {hierarchyMeta[key].label}</option>)}
              </select>
            </Field>
          </div>
          <div>
            <p className="mb-2 text-sm font-semibold">Áreas compartidas</p>
            <div className="flex flex-wrap gap-2">
              {areas.map((area) => {
                const on = form.areas.includes(area);
                return (
                  <button
                    type="button"
                    key={area}
                    onClick={() => setForm({ ...form, areas: on ? form.areas.filter((item) => item !== area) : [...form.areas, area] })}
                    className={`rounded-full px-3 py-1 text-xs font-bold ${on ? "bg-brand-600 text-white" : "bg-slate-100 dark:bg-slate-800"}`}
                  >
                    {areaMeta[area].label}
                  </button>
                );
              })}
            </div>
          </div>
          <Button type="submit">Guardar usuario</Button>
        </form>
      )}
      <section className="overflow-x-auto rounded-lg bg-white p-4 shadow-soft dark:bg-slate-900">
        <table className="w-full text-sm">
          <thead className="text-left text-xs uppercase text-slate-400">
            <tr><th className="p-2">Usuario</th><th>Símbolo</th><th>Áreas</th><th>Estado</th><th /></tr>
          </thead>
          <tbody>
            {db.users.map((item) => (
              <tr key={item.id} className="border-t border-slate-100 dark:border-white/10">
                <td className="p-2"><strong>{item.name}</strong><div className="text-xs text-slate-500">{item.email}</div></td>
                <td><RoleMark role={item.hierarchy} compact /></td>
                <td className="max-w-sm text-xs">{item.areas.map((area) => areaMeta[area].label).join(", ")}</td>
                <td><StatusPill tone={item.active ? "ok" : "bad"}>{item.active ? "Activo" : "Inactivo"}</StatusPill></td>
                <td className="whitespace-nowrap">
                  {write && <Button variant="ghost" onClick={() => setForm(item)}>Editar</Button>}
                  {write && (
                    <Button
                      variant="ghost"
                      onClick={() => upsertUser({ ...item, active: !item.active }, user?.name ?? "sistema")}
                    >
                      {item.active ? "Bloquear" : "Activar"}
                    </Button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
    </div>
  );
}

import { FormEvent, useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import {
  Check,
  CheckCircle2,
  Copy,
  ExternalLink,
  KeyRound,
  LogOut,
  Mail,
  Plus,
  RefreshCw,
  Send,
  ShieldAlert,
  ShieldCheck,
  UserCheck,
  UserPlus,
  UserX,
  X
} from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { areaMeta, hierarchyMeta } from "../auth/roles";
import { Button } from "../components/Button";
import { RoleMark, RolePowerGrid } from "../components/RoleMark";
import { Field, inputClass, PageHeader, StatusPill } from "../components/Ui";
import type { AreaRole, HierarchyRole } from "../types/erp";

const areas = Object.keys(areaMeta) as AreaRole[];

interface ManagedUser {
  id: string;
  name: string;
  email: string;
  hierarchy: HierarchyRole;
  areas: AreaRole[];
  isActive: boolean;
  activeSessions: number;
  invitationPending: boolean;
  invitationExpiresAt?: string | null;
  isLocked: boolean;
}

interface InvitationResult {
  token: string;
  link: string;
  expiresAt: string;
  recipientName: string;
  recipientEmail: string;
  smtpConfigured: boolean;
  deliveryProcedure: string;
}

export default function UsersPage() {
  const { user } = useAuth();
  const [users, setUsers] = useState<ManagedUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Modal para nuevo usuario
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [createForm, setCreateForm] = useState({
    name: "",
    email: "",
    hierarchy: "estandar" as HierarchyRole,
    areas: ["ventas"] as AreaRole[]
  });
  const [creating, setCreating] = useState(false);

  // Modal de entrega de invitación
  const [invitationModal, setInvitationModal] = useState<InvitationResult | null>(null);
  const [copiedLink, setCopiedLink] = useState(false);
  const [copiedToken, setCopiedToken] = useState(false);

  // Acciones en curso
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const isSuperadmin = user?.hierarchy === "superadmin";
  const isAdmin = user?.hierarchy === "administrador";
  const canManage = isSuperadmin || isAdmin;

  const loadUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const token = localStorage.getItem("raquel_token") || sessionStorage.getItem("raquel_token");
      const res = await fetch("/api/users", {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      });
      if (!res.ok) {
        throw new Error("No se pudo obtener la lista de usuarios.");
      }
      const data = await res.json();
      setUsers(data.users || []);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Error de comunicación con SQL Server.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadUsers();
  }, []);

  const handleCreateUser = async (e: FormEvent) => {
    e.preventDefault();
    if (!createForm.name || !createForm.email) return;

    // Validación de jerarquía: Administrador no puede crear Superadmin
    if (isAdmin && createForm.hierarchy === "superadmin") {
      alert("Un Administrador de área no puede crear una cuenta Superadministrador.");
      return;
    }

    setCreating(true);
    try {
      const token = localStorage.getItem("raquel_token") || sessionStorage.getItem("raquel_token");
      const res = await fetch("/api/users", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        },
        body: JSON.stringify(createForm)
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Error al crear usuario.");
      }

      setShowCreateModal(false);
      setCreateForm({
        name: "",
        email: "",
        hierarchy: "estandar",
        areas: ["ventas"]
      });

      // Mostrar modal de invitación generada
      if (data.invitation) {
        setInvitationModal({
          token: data.invitation.token,
          link: data.invitation.link,
          expiresAt: data.invitation.expiresAt,
          recipientName: data.user.name,
          recipientEmail: data.user.email,
          smtpConfigured: Boolean(data.smtpConfigured),
          deliveryProcedure: data.deliveryProcedure || ""
        });
      }

      await loadUsers();
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Error al crear usuario");
    } finally {
      setCreating(false);
    }
  };

  const handleResendInvitation = async (u: ManagedUser) => {
    setActionLoading(`resend-${u.id}`);
    try {
      const token = localStorage.getItem("raquel_token") || sessionStorage.getItem("raquel_token");
      const res = await fetch(`/api/users/${u.id}/resend-invitation`, {
        method: "POST",
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Error al generar nueva invitación.");
      }

      setInvitationModal({
        token: data.invitation.token,
        link: data.invitation.link,
        expiresAt: data.invitation.expiresAt,
        recipientName: u.name,
        recipientEmail: u.email,
        smtpConfigured: Boolean(data.smtpConfigured),
        deliveryProcedure: data.deliveryProcedure || ""
      });

      await loadUsers();
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "No se pudo reenviar la invitación.");
    } finally {
      setActionLoading(null);
    }
  };

  const handleRevokeSessions = async (u: ManagedUser) => {
    if (!confirm(`¿Revocar todas las sesiones activas de ${u.name}? El usuario será desconectado de inmediato.`)) return;
    setActionLoading(`revoke-${u.id}`);
    try {
      const token = localStorage.getItem("raquel_token") || sessionStorage.getItem("raquel_token");
      const res = await fetch(`/api/users/${u.id}/revoke-sessions`, {
        method: "POST",
        headers: token ? { Authorization: `Bearer ${token}` } : {}
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || "Error al revocar sesiones.");
      alert(`Sesiones de ${u.name} revocadas correctamente en SQL Server.`);
      await loadUsers();
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Error al revocar sesiones");
    } finally {
      setActionLoading(null);
    }
  };

  const handleToggleStatus = async (u: ManagedUser) => {
    const actionName = u.isActive ? "suspender" : "activar";
    if (!confirm(`¿Confirma que desea ${actionName} la cuenta de ${u.name}?`)) return;
    setActionLoading(`status-${u.id}`);
    try {
      const token = localStorage.getItem("raquel_token") || sessionStorage.getItem("raquel_token");
      const res = await fetch(`/api/users/${u.id}/status`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        },
        body: JSON.stringify({ active: !u.isActive })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || "Error al actualizar estado.");
      await loadUsers();
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Error al cambiar estado");
    } finally {
      setActionLoading(null);
    }
  };

  const copyToClipboard = async (text: string, isLink: boolean) => {
    try {
      await navigator.clipboard.writeText(text);
      if (isLink) {
        setCopiedLink(true);
        setTimeout(() => setCopiedLink(false), 2000);
      } else {
        setCopiedToken(true);
        setTimeout(() => setCopiedToken(false), 2000);
      }
    } catch {
      // Fallback
    }
  };

  const sessionHint = useMemo(() => {
    if (!user) return "Sin sesión";
    const meta = hierarchyMeta[user.hierarchy];
    return `${meta.mark} · ${meta.markHint}`;
  }, [user]);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <PageHeader
          kicker="Gobierno y Seguridad"
          title="Usuarios, Roles y Permisos"
          subtitle="Invitaciones de un solo uso, revocación de sesiones y control estricto de jerarquías en SQL Server."
        />
        <div className="flex items-center gap-2">
          <Button
            variant="secondary"
            icon={<RefreshCw size={16} className={loading ? "animate-spin" : ""} />}
            onClick={() => void loadUsers()}
          >
            Actualizar
          </Button>
          {canManage && (
            <Button icon={<UserPlus size={16} />} onClick={() => setShowCreateModal(true)}>
              Nuevo Usuario
            </Button>
          )}
        </div>
      </div>

      <RolePowerGrid />

      <section className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        {(Object.keys(hierarchyMeta) as HierarchyRole[]).map((key) => (
          <article key={key} className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
            <RoleMark role={key} />
            <h3 className="mt-3 font-extrabold text-slate-900 dark:text-white">{hierarchyMeta[key].label}</h3>
            <p className="mt-2 text-xs text-slate-500 leading-relaxed">{hierarchyMeta[key].duty}</p>
          </article>
        ))}
      </section>

      <section className="grid gap-3 lg:grid-cols-3">
        <article className="rounded-2xl bg-[#0c2336] p-4 text-cyan-50 border border-white/5 shadow-md">
          <p className="text-[11px] font-bold uppercase tracking-wider text-cyan-300">Sesión Actual</p>
          <p className="mt-2 text-base font-black text-white">{user?.name ?? "—"}</p>
          <p className="text-xs text-cyan-200/80">{user?.email}</p>
          <p className="mt-2 text-xs font-semibold text-cyan-300">{sessionHint}</p>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
          <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Política de Invitaciones</p>
          <p className="mt-2 text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
            Las contraseñas no se fijan por el administrador. Se entrega una invitación individual de un solo uso que vence a las 48 horas.
          </p>
          <p className="mt-2 text-[11px] font-bold text-emerald-600 dark:text-emerald-400">
            ✓ Reenviar invalida la invitación previa automáticamente.
          </p>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
          <p className="text-[11px] font-bold uppercase tracking-wider text-slate-400">Auditoría Sellada ACID</p>
          <p className="mt-2 text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
            Cada creación de usuario, invitación, activación y revocación de sesión queda registrada con hash SHA-256 en dbo.AppAuditLog.
          </p>
          <Link to="/auditoria" className="mt-2 inline-flex items-center gap-1.5 text-xs font-bold text-brand-600 dark:text-cyan-400">
            <ShieldCheck size={14} /> Ver bitácora inmutable →
          </Link>
        </article>
      </section>

      {/* TABLA DE USUARIOS REGISTRADOS */}
      <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-soft dark:border-white/10 dark:bg-slate-900">
        <div className="border-b border-slate-200 dark:border-white/10 px-5 py-4 flex items-center justify-between">
          <div>
            <h3 className="font-extrabold text-slate-900 dark:text-white">Colaboradores y Cuentas Activas</h3>
            <p className="text-xs text-slate-500">
              Registros en SQL Server (tabla dbo.AppUsers y dbo.AppUserInvitations)
            </p>
          </div>
          <span className="text-xs font-bold text-slate-400">
            Total: {users.length} cuenta{users.length !== 1 ? "s" : ""}
          </span>
        </div>

        {loading ? (
          <div className="py-12 text-center text-slate-400">
            <RefreshCw className="mx-auto h-8 w-8 animate-spin text-brand-500 mb-2" />
            <p className="text-sm">Cargando directorio de usuarios...</p>
          </div>
        ) : error ? (
          <div className="p-8 text-center text-rose-500">
            <ShieldAlert className="mx-auto h-8 w-8 mb-2" />
            <p className="text-sm font-bold">{error}</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-50 text-[11px] font-bold uppercase text-slate-500 dark:bg-slate-950 dark:text-slate-400">
                <tr>
                  <th className="px-5 py-3.5">Colaborador</th>
                  <th className="px-4 py-3.5">Rol / Jerarquía</th>
                  <th className="px-4 py-3.5">Áreas Autorizadas</th>
                  <th className="px-4 py-3.5">Estado de Cuenta</th>
                  <th className="px-4 py-3.5 text-center">Sesiones Activas</th>
                  <th className="px-5 py-3.5 text-right">Acciones de Seguridad</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 dark:divide-white/5">
                {users.map((u) => (
                  <tr key={u.id} className="hover:bg-slate-50/60 dark:hover:bg-white/5 transition">
                    <td className="px-5 py-3.5">
                      <div className="font-bold text-slate-900 dark:text-white text-sm">{u.name}</div>
                      <div className="text-slate-400 font-mono text-[11px]">{u.email}</div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex items-center gap-2">
                        <RoleMark role={u.hierarchy} compact />
                        <span className="font-semibold text-slate-700 dark:text-slate-300">
                          {hierarchyMeta[u.hierarchy]?.label}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      <div className="flex flex-wrap gap-1 max-w-xs">
                        {u.areas.map((a) => (
                          <span
                            key={a}
                            className="rounded-md bg-slate-100 px-2 py-0.5 text-[10px] font-semibold text-slate-700 dark:bg-white/10 dark:text-slate-300"
                          >
                            {areaMeta[a]?.label ?? a}
                          </span>
                        ))}
                      </div>
                    </td>
                    <td className="px-4 py-3.5">
                      {u.isLocked ? (
                        <StatusPill tone="bad">Candado (intentos)</StatusPill>
                      ) : !u.isActive ? (
                        <StatusPill tone="bad">Suspendido</StatusPill>
                      ) : u.invitationPending ? (
                        <StatusPill tone="warn">Invitación Pendiente</StatusPill>
                      ) : (
                        <StatusPill tone="ok">Activo</StatusPill>
                      )}
                    </td>
                    <td className="px-4 py-3.5 text-center">
                      <span
                        className={`inline-flex items-center justify-center rounded-full px-2 py-0.5 text-[11px] font-black ${
                          u.activeSessions > 0
                            ? "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300"
                            : "bg-slate-100 text-slate-500 dark:bg-white/10 dark:text-slate-400"
                        }`}
                      >
                        {u.activeSessions}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-right whitespace-nowrap space-x-1.5">
                      {canManage && (
                        <>
                          {u.invitationPending && (
                            <Button
                              variant="ghost"
                              className="!text-xs !py-1 !px-2.5 text-cyan-600 hover:text-cyan-700 dark:text-cyan-400"
                              icon={<Send size={13} />}
                              disabled={actionLoading === `resend-${u.id}`}
                              onClick={() => void handleResendInvitation(u)}
                            >
                              Reenviar Invitación
                            </Button>
                          )}

                          {u.activeSessions > 0 && (
                            <Button
                              variant="ghost"
                              className="!text-xs !py-1 !px-2.5 text-amber-600 hover:text-amber-700 dark:text-amber-400"
                              icon={<LogOut size={13} />}
                              disabled={actionLoading === `revoke-${u.id}`}
                              onClick={() => void handleRevokeSessions(u)}
                            >
                              Revocar Sesiones
                            </Button>
                          )}

                          {/* No permitir suspenderse a sí mismo */}
                          {user?.id !== u.id && (
                            <Button
                              variant="ghost"
                              className={`!text-xs !py-1 !px-2.5 ${
                                u.isActive
                                  ? "text-rose-600 hover:text-rose-700 dark:text-rose-400"
                                  : "text-emerald-600 hover:text-emerald-700 dark:text-emerald-400"
                              }`}
                              icon={u.isActive ? <UserX size={13} /> : <UserCheck size={13} />}
                              disabled={actionLoading === `status-${u.id}`}
                              onClick={() => void handleToggleStatus(u)}
                            >
                              {u.isActive ? "Suspender" : "Activar"}
                            </Button>
                          )}
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* MODAL CREAR USUARIO (Superadmin o Admin) */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm">
          <div className="relative w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-white/10 dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-white/10 pb-4">
              <div className="flex items-center gap-2.5">
                <div className="grid h-10 w-10 place-items-center rounded-2xl bg-brand-500/10 text-brand-600 dark:text-cyan-400">
                  <UserPlus size={20} />
                </div>
                <div>
                  <h3 className="font-extrabold text-slate-900 dark:text-white">Crear Usuario y Generar Invitación</h3>
                  <p className="text-xs text-slate-500">El usuario establecerá su propia contraseña al entrar</p>
                </div>
              </div>
              <button
                type="button"
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-white/10"
                onClick={() => setShowCreateModal(false)}
              >
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleCreateUser} className="mt-4 space-y-4">
              <div className="grid gap-3 sm:grid-cols-2">
                <Field label="Nombre Completo">
                  <input
                    className={inputClass}
                    required
                    placeholder="Ej. Carlos Mendoza"
                    value={createForm.name}
                    onChange={(e) => setCreateForm({ ...createForm, name: e.target.value })}
                  />
                </Field>

                <Field label="Correo Institucional">
                  <input
                    className={inputClass}
                    type="email"
                    required
                    placeholder="carlos@raquel.com"
                    value={createForm.email}
                    onChange={(e) => setCreateForm({ ...createForm, email: e.target.value })}
                  />
                </Field>
              </div>

              <Field label="Jerarquía / Nivel de Poder">
                <select
                  className={inputClass}
                  value={createForm.hierarchy}
                  onChange={(e) => setCreateForm({ ...createForm, hierarchy: e.target.value as HierarchyRole })}
                >
                  {(Object.keys(hierarchyMeta) as HierarchyRole[])
                    .filter((key) => isSuperadmin || key !== "superadmin")
                    .map((key) => (
                      <option key={key} value={key}>
                        {hierarchyMeta[key].mark} · {hierarchyMeta[key].label}
                      </option>
                    ))}
                </select>
              </Field>

              <div>
                <span className="mb-2 block text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300">
                  Áreas Autorizadas
                </span>
                <div className="flex flex-wrap gap-1.5">
                  {areas.map((area) => {
                    const selected = createForm.areas.includes(area);
                    return (
                      <button
                        type="button"
                        key={area}
                        onClick={() => {
                          const newAreas = selected
                            ? createForm.areas.filter((a) => a !== area)
                            : [...createForm.areas, area];
                          setCreateForm({ ...createForm, areas: newAreas });
                        }}
                        className={`rounded-xl px-3 py-1.5 text-xs font-bold transition ${
                          selected
                            ? "bg-brand-600 text-white shadow-sm"
                            : "bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-white/5 dark:text-slate-400"
                        }`}
                      >
                        {areaMeta[area].label}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="rounded-xl border border-cyan-500/20 bg-cyan-500/5 p-3 text-xs text-slate-600 dark:text-slate-300 leading-relaxed">
                <strong>Flujo seguro:</strong> Al guardar, se creará el registro en SQL Server y se generará un enlace de invitación seguro. No se requiere ni se almacena una contraseña predeterminada.
              </div>

              <div className="flex justify-end gap-2 pt-2 border-t border-slate-100 dark:border-white/10">
                <Button type="button" variant="ghost" onClick={() => setShowCreateModal(false)}>
                  Cancelar
                </Button>
                <Button type="submit" disabled={creating || createForm.areas.length === 0}>
                  {creating ? "Generando usuario..." : "Crear y Generar Invitación"}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL DE ENTREGA AUTORIZADA DE INVITACIÓN */}
      {invitationModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm">
          <div className="relative w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-white/10 dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-slate-100 dark:border-white/10 pb-4">
              <div className="flex items-center gap-2.5">
                <div className="grid h-10 w-10 place-items-center rounded-2xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400">
                  <CheckCircle2 size={22} />
                </div>
                <div>
                  <h3 className="font-extrabold text-slate-900 dark:text-white">Invitación Segura Creada</h3>
                  <p className="text-xs text-slate-500">Para {invitationModal.recipientName} ({invitationModal.recipientEmail})</p>
                </div>
              </div>
              <button
                type="button"
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-white/10"
                onClick={() => setInvitationModal(null)}
              >
                <X size={18} />
              </button>
            </div>

            <div className="mt-4 space-y-4">
              {/* Notificación transparente de SMTP */}
              {!invitationModal.smtpConfigured ? (
                <div className="rounded-2xl border border-amber-200 bg-amber-50 p-4 dark:border-amber-900/40 dark:bg-amber-950/30">
                  <p className="text-xs font-black uppercase tracking-wider text-amber-800 dark:text-amber-300">
                    Servicio de correo SMTP no configurado
                  </p>
                  <p className="mt-1 text-xs text-amber-700 dark:text-amber-200 leading-relaxed">
                    No se envió correo automático. {invitationModal.deliveryProcedure}
                  </p>
                </div>
              ) : (
                <div className="rounded-2xl border border-emerald-200 bg-emerald-50 p-4 dark:border-emerald-900/40 dark:bg-emerald-950/30">
                  <p className="text-xs font-black uppercase tracking-wider text-emerald-800 dark:text-emerald-300">
                    Invitación enviada por correo
                  </p>
                  <p className="mt-1 text-xs text-emerald-700 dark:text-emerald-200 leading-relaxed">
                    Se despachó el correo con el enlace de un solo uso a {invitationModal.recipientEmail}.
                  </p>
                </div>
              )}

              {/* Procedimiento de entrega autorizada: Enlace directo */}
              <div className="space-y-2">
                <span className="block text-xs font-bold uppercase tracking-wider text-slate-500">
                  Enlace seguro de activación (Vence en 48 horas):
                </span>
                <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 p-2.5 dark:border-white/10 dark:bg-slate-950">
                  <input
                    type="text"
                    readOnly
                    value={`${window.location.origin}/invitacion/${invitationModal.token}`}
                    className="flex-1 bg-transparent text-xs font-mono text-slate-700 dark:text-slate-300 focus:outline-none"
                  />
                  <Button
                    variant="ghost"
                    className="!py-1 !px-2.5 !text-xs shrink-0"
                    icon={copiedLink ? <Check size={14} className="text-emerald-500" /> : <Copy size={14} />}
                    onClick={() => copyToClipboard(`${window.location.origin}/invitacion/${invitationModal.token}`, true)}
                  >
                    {copiedLink ? "Copiado" : "Copiar"}
                  </Button>
                </div>
              </div>

              {/* Token individual */}
              <div className="space-y-2">
                <span className="block text-xs font-bold uppercase tracking-wider text-slate-500">
                  Token de verificación:
                </span>
                <div className="flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 p-2.5 dark:border-white/10 dark:bg-slate-950">
                  <input
                    type="text"
                    readOnly
                    value={invitationModal.token}
                    className="flex-1 bg-transparent text-xs font-mono text-slate-700 dark:text-slate-300 focus:outline-none"
                  />
                  <Button
                    variant="ghost"
                    className="!py-1 !px-2.5 !text-xs shrink-0"
                    icon={copiedToken ? <Check size={14} className="text-emerald-500" /> : <Copy size={14} />}
                    onClick={() => copyToClipboard(invitationModal.token, false)}
                  >
                    {copiedToken ? "Copiado" : "Copiar Token"}
                  </Button>
                </div>
              </div>

              <div className="flex items-center justify-between pt-2 border-t border-slate-100 dark:border-white/10">
                <a
                  href={`/invitacion/${invitationModal.token}`}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-brand-600 dark:text-cyan-400 hover:underline"
                >
                  <ExternalLink size={14} /> Abrir página de activación
                </a>
                <Button onClick={() => setInvitationModal(null)}>Entendido</Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

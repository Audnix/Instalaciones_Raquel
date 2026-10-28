import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { CheckCircle2, KeyRound, Lock, ShieldAlert, Sparkles } from "lucide-react";
import logo from "../assets/logo-window.png";
import { hierarchyMeta, areaMeta } from "../auth/roles";
import { Button } from "../components/Button";
import { RoleMark } from "../components/RoleMark";
import type { HierarchyRole, AreaRole } from "../types/erp";

interface InvitationData {
  id: string;
  name: string;
  email: string;
  hierarchy: HierarchyRole;
  areas: AreaRole[];
  expiresAt: string;
}

export default function InvitationPage() {
  const { token } = useParams<{ token: string }>();
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [invitation, setInvitation] = useState<InvitationData | null>(null);

  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);

  useEffect(() => {
    if (!token) {
      setError("Token de invitación no proporcionado.");
      setLoading(false);
      return;
    }

    async function checkToken() {
      try {
        const res = await fetch(`/api/auth/invitation/${token}`);
        const data = await res.json();
        if (!res.ok || !data.valid) {
          throw new Error(data.message || "La invitación no es válida o ha vencido.");
        }
        setInvitation(data.user);
      } catch (err: unknown) {
        setError(err instanceof Error ? err.message : "Error al validar la invitación.");
      } finally {
        setLoading(false);
      }
    }

    void checkToken();
  }, [token]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password.length < 8) {
      setError("La contraseña debe tener al menos 8 caracteres.");
      return;
    }
    if (password !== confirmPassword) {
      setError("Las contraseñas no coinciden.");
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const res = await fetch("/api/auth/invitation/accept", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token, password })
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "No se pudo activar la cuenta.");
      }
      setSuccess(true);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : "Error al activar la cuenta.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <main className="relative grid min-h-screen overflow-hidden p-4 md:place-items-center bg-slate-900 text-white">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(10,146,200,.22),transparent_40%),radial-gradient(circle_at_80%_80%,rgba(232,75,95,.18),transparent_40%)]" />

      <section className="relative w-full max-w-lg overflow-hidden rounded-3xl border border-white/10 bg-slate-950/80 p-6 sm:p-10 shadow-2xl backdrop-blur-xl">
        <div className="flex items-center gap-4 border-b border-white/10 pb-6">
          <img src={logo} alt="Instalaciones Raquel" className="h-14 w-14 rounded-2xl bg-white p-1.5 shadow-md object-contain" />
          <div>
            <h1 className="text-xl font-extrabold tracking-tight">Instalaciones Raquel</h1>
            <p className="text-xs text-cyan-200 uppercase tracking-widest font-semibold">Activación de Cuenta</p>
          </div>
        </div>

        {loading ? (
          <div className="py-12 text-center text-slate-400">
            <div className="mx-auto h-8 w-8 animate-spin rounded-full border-2 border-brand-500 border-t-transparent mb-3" />
            <p className="text-sm">Validando invitación autorizada...</p>
          </div>
        ) : error && !invitation ? (
          <div className="py-8 space-y-4 text-center">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-rose-500/20 text-rose-400">
              <ShieldAlert size={30} />
            </div>
            <h2 className="text-lg font-bold text-rose-300">Invitación no disponible</h2>
            <p className="text-sm text-slate-400 max-w-sm mx-auto">{error}</p>
            <div className="pt-2">
              <Link to="/login">
                <Button variant="secondary">Ir al Inicio de Sesión</Button>
              </Link>
            </div>
          </div>
        ) : success ? (
          <div className="py-8 space-y-4 text-center">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-emerald-500/20 text-emerald-400">
              <CheckCircle2 size={36} />
            </div>
            <h2 className="text-2xl font-black text-emerald-300">¡Cuenta Activada!</h2>
            <p className="text-sm text-slate-300">
              Tu contraseña fue establecida correctamente. Ya podés acceder a tu puesto en Instalaciones Raquel.
            </p>
            <div className="pt-4">
              <Button className="w-full" onClick={() => navigate("/login")}>
                Iniciar Sesión Ahora
              </Button>
            </div>
          </div>
        ) : invitation ? (
          <form onSubmit={handleSubmit} className="mt-6 space-y-5">
            <div className="rounded-2xl border border-cyan-500/20 bg-cyan-950/30 p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-bold uppercase tracking-wider text-cyan-300">Invitación personalizada para</p>
                  <h2 className="text-lg font-black text-white mt-0.5">{invitation.name}</h2>
                  <p className="text-xs text-slate-400">{invitation.email}</p>
                </div>
                <RoleMark role={invitation.hierarchy} compact />
              </div>

              <div className="mt-3 pt-3 border-t border-cyan-500/15 flex flex-wrap gap-1.5 items-center">
                <span className="text-[11px] font-semibold text-slate-400">Áreas asignadas:</span>
                {invitation.areas.map((a) => (
                  <span key={a} className="rounded-md bg-white/10 px-2 py-0.5 text-[11px] font-bold text-cyan-200">
                    {areaMeta[a]?.label ?? a}
                  </span>
                ))}
              </div>
              <p className="mt-2 text-[11px] text-slate-400">
                Puesto: <strong>{hierarchyMeta[invitation.hierarchy]?.label}</strong>
              </p>
            </div>

            <div className="space-y-4">
              <label className="block">
                <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-slate-300">
                  Establecer tu contraseña
                </span>
                <span className="relative block">
                  <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                  <input
                    type="password"
                    required
                    minLength={8}
                    className="h-12 w-full rounded-xl border border-white/15 bg-white/5 pl-11 pr-4 text-sm text-white placeholder-slate-500 focus:border-cyan-400 focus:outline-none"
                    placeholder="Mínimo 8 caracteres"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                </span>
              </label>

              <label className="block">
                <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-slate-300">
                  Confirmar contraseña
                </span>
                <span className="relative block">
                  <KeyRound className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                  <input
                    type="password"
                    required
                    minLength={8}
                    className="h-12 w-full rounded-xl border border-white/15 bg-white/5 pl-11 pr-4 text-sm text-white placeholder-slate-500 focus:border-cyan-400 focus:outline-none"
                    placeholder="Repetí la misma contraseña"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                  />
                </span>
              </label>
            </div>

            {error && (
              <div className="rounded-xl bg-rose-500/20 border border-rose-500/30 p-3 text-xs text-rose-300 font-medium">
                {error}
              </div>
            )}

            <Button type="submit" className="h-12 w-full font-bold" disabled={submitting || !password}>
              {submitting ? "Activando cuenta..." : "Activar mi cuenta y entrar"}
            </Button>

            <p className="text-center text-[11px] text-slate-500">
              Las contraseñas se almacenan mediante hash seguro (bcrypt) y nunca se transmiten en texto claro.
            </p>
          </form>
        ) : null}
      </section>
    </main>
  );
}

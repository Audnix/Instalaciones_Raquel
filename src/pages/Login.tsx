import { useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { motion, AnimatePresence } from "framer-motion";
import { CheckCircle2, Eye, EyeOff, HelpCircle, KeyRound, Lock, Mail, Moon, ShieldCheck, Sun, X } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import logo from "../assets/logo-window.png";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { clearLoginGuard, loginLockMs, registerLoginFail } from "../lib/loginGuard";
import { useErp } from "../store/erpStore";

const schema = z.object({
  email: z.string().email("Correo electrónico inválido"),
  password: z.string().min(6, "Mínimo 6 caracteres"),
  remember: z.boolean()
});

type FormValues = z.infer<typeof schema>;

export default function Login({ dark, toggleTheme }: { dark: boolean; toggleTheme: () => void }) {
  const { login } = useAuth();
  const { log } = useErp();
  const [show, setShow] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lockLeft, setLockLeft] = useState(() => loginLockMs());

  // Estado para modal de recuperación de contraseña
  const [showRecoverModal, setShowRecoverModal] = useState(false);
  const [recoverEmail, setRecoverEmail] = useState("");
  const [recoverStep, setRecoverStep] = useState<"request" | "verify">("request");
  const [recoverCode, setRecoverCode] = useState("");
  const [recoverNewPassword, setRecoverNewPassword] = useState("");
  const [recoverLoading, setRecoverLoading] = useState(false);
  const [recoverNotice, setRecoverNotice] = useState<{
    tone: "info" | "success" | "warn" | "error";
    message: string;
    authCode?: string;
  } | null>(null);

  const {
    register,
    handleSubmit,
    formState: { errors, isValid }
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    mode: "onChange",
    defaultValues: { email: "admin@raquel.com", password: "", remember: true }
  });

  const submit = handleSubmit(async (values) => {
    const locked = loginLockMs();
    if (locked > 0) {
      setLockLeft(locked);
      setError(`Acceso cerrado temporalmente (${Math.ceil(locked / 1000)} s restantes).`);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      await login(values.email, values.password, values.remember);
      clearLoginGuard();
    } catch (err) {
      const guard = registerLoginFail();
      setLockLeft(guard.locked ? guard.until - Date.now() : 0);
      log({
        userName: values.email,
        action: "acceso denegado",
        module: "usuarios",
        detail: guard.locked ? "exceso de intentos · candado temporal" : "credenciales incorrectas"
      });
      setError(
        guard.locked
          ? "Múltiples intentos fallidos. Por seguridad el acceso se bloquea temporalmente por 90 segundos."
          : (err instanceof Error ? err.message : "Credenciales no autorizadas")
      );
    } finally {
      setLoading(false);
    }
  });

  const handleRecoverRequest = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!recoverEmail || !recoverEmail.includes("@")) {
      setRecoverNotice({ tone: "error", message: "Ingrese un correo electrónico válido." });
      return;
    }
    setRecoverLoading(true);
    setRecoverNotice(null);
    try {
      const res = await fetch("/api/auth/recover-request", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: recoverEmail })
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Error al solicitar recuperación.");
      }
      if (data.smtpConfigured) {
        setRecoverNotice({
          tone: "info",
          message: "Se ha enviado un código de recuperación a su correo electrónico."
        });
      } else {
        setRecoverNotice({
          tone: "warn",
          message: `${data.message} ${data.authorizedDeliveryProcedure}`,
          authCode: data.authorizedCode
        });
        if (data.authorizedCode) {
          setRecoverCode(data.authorizedCode);
        }
      }
      setRecoverStep("verify");
    } catch (err: unknown) {
      setRecoverNotice({
        tone: "error",
        message: err instanceof Error ? err.message : "Error al procesar la solicitud."
      });
    } finally {
      setRecoverLoading(false);
    }
  };

  const handleRecoverVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    if (recoverNewPassword.length < 8) {
      setRecoverNotice({ tone: "error", message: "La nueva contraseña debe tener al menos 8 caracteres." });
      return;
    }
    setRecoverLoading(true);
    try {
      const res = await fetch("/api/auth/recover-verify", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: recoverEmail,
          code: recoverCode,
          newPassword: recoverNewPassword
        })
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Código inválido o expirado.");
      }
      setRecoverNotice({
        tone: "success",
        message: "Contraseña actualizada exitosamente. Ya puede iniciar sesión con su nueva clave."
      });
      setTimeout(() => {
        setShowRecoverModal(false);
        setRecoverStep("request");
        setRecoverNotice(null);
        setRecoverCode("");
        setRecoverNewPassword("");
      }, 2500);
    } catch (err: unknown) {
      setRecoverNotice({
        tone: "error",
        message: err instanceof Error ? err.message : "No se pudo restablecer la contraseña."
      });
    } finally {
      setRecoverLoading(false);
    }
  };

  return (
    <main className="relative grid min-h-screen overflow-hidden p-4 md:place-items-center">
      <div className="absolute inset-0 bg-[linear-gradient(120deg,rgba(10,146,200,.18),transparent_35%,rgba(232,75,95,.10)_72%,transparent)]" />
      <section className="relative grid w-full max-w-6xl overflow-hidden rounded-3xl bg-white shadow-2xl dark:bg-slate-950 md:grid-cols-[0.95fr_1.05fr]">
        <motion.div
          className="glass-panel flex min-h-[680px] flex-col justify-between p-6 sm:p-10"
          initial={{ x: -24, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <img src={logo} alt="Instalaciones Raquel" className="h-14 w-14 rounded-2xl bg-white object-contain p-1.5 shadow-md" />
              <div>
                <h1 className="text-lg font-extrabold tracking-tight">Instalaciones Raquel</h1>
                <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">ERP Aluminio, Vidrio y Fachadas</p>
              </div>
            </div>
            <button
              className="rounded-xl p-2.5 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-white/10 transition"
              onClick={toggleTheme}
              aria-label="Cambiar tema"
            >
              {dark ? <Sun size={20} /> : <Moon size={20} />}
            </button>
          </div>

          <form onSubmit={submit} className="mx-auto w-full max-w-sm space-y-4 my-auto py-6" noValidate>
            <div>
              <h2 className="text-3xl font-black tracking-tight text-slate-900 dark:text-white">Iniciar Sesión</h2>
              <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
                Cada colaborador ingresa con su correo personal y contraseña cifrada.
              </p>
            </div>

            <label className="block">
              <span className="mb-2 block text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300">
                Correo Electrónico
              </span>
              <span className="relative block">
                <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input
                  type="email"
                  className="h-12 w-full rounded-xl border border-slate-200 bg-white/90 pl-11 pr-3 text-sm font-medium dark:border-white/10 dark:bg-white/5 focus:border-brand-500 focus:outline-none transition"
                  placeholder="usuario@raquel.com"
                  {...register("email")}
                />
              </span>
              {errors.email && <span className="mt-1.5 block text-xs font-semibold text-rose-500">{errors.email.message}</span>}
            </label>

            <label className="block">
              <div className="mb-2 flex items-center justify-between">
                <span className="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-slate-300">
                  Contraseña
                </span>
                <button
                  type="button"
                  onClick={() => setShowRecoverModal(true)}
                  className="text-xs font-semibold text-brand-600 hover:text-brand-700 dark:text-cyan-400"
                >
                  ¿Olvidaste tu clave?
                </button>
              </div>
              <span className="relative block">
                <Lock className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input
                  type={show ? "text" : "password"}
                  className="h-12 w-full rounded-xl border border-slate-200 bg-white/90 pl-11 pr-12 text-sm font-medium dark:border-white/10 dark:bg-white/5 focus:border-brand-500 focus:outline-none transition"
                  placeholder="••••••••"
                  {...register("password")}
                />
                <button
                  type="button"
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 rounded-lg p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
                  onClick={() => setShow((value) => !value)}
                  aria-label="Mostrar u ocultar contraseña"
                >
                  {show ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </span>
              {errors.password && <span className="mt-1.5 block text-xs font-semibold text-rose-500">{errors.password.message}</span>}
            </label>

            <div className="flex items-center justify-between text-xs">
              <label className="flex items-center gap-2 font-medium text-slate-600 dark:text-slate-300 cursor-pointer">
                <input type="checkbox" className="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" {...register("remember")} />
                Mantener sesión activa
              </label>
            </div>

            {error && (
              <div className="rounded-xl border border-rose-200 bg-rose-50 p-3 text-xs font-semibold text-rose-700 dark:border-rose-900/40 dark:bg-rose-950/40 dark:text-rose-300">
                {error}
              </div>
            )}

            <Button className="h-12 w-full font-bold shadow-soft" disabled={!isValid || loading || lockLeft > 0}>
              {loading ? "Verificando credenciales..." : lockLeft > 0 ? `Bloqueo activo (${Math.ceil(lockLeft / 1000)} s)` : "Ingresar al ERP"}
            </Button>

            <div className="pt-2 text-center">
              <p className="text-[11px] text-slate-400">
                Acceso restringido a colaboradores autorizados · Cifrado bcrypt y sesiones activas en SQL Server
              </p>
            </div>
          </form>

          <footer className="text-center sm:text-left flex items-center justify-between text-xs text-slate-400 border-t border-slate-100 dark:border-white/5 pt-4">
            <span>Instalaciones Raquel S.A.</span>
            <span>Seguridad & Auditoría ACID</span>
          </footer>
        </motion.div>

        {/* Panel lateral institucional y de taller */}
        <div className="relative hidden min-h-[680px] overflow-hidden bg-gradient-to-br from-[#0c2336] via-[#091b2c] to-[#040c14] p-10 text-white md:flex md:flex-col md:justify-between">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_20%_20%,rgba(10,146,200,.25),transparent_40%),radial-gradient(circle_at_80%_80%,rgba(232,75,95,.18),transparent_40%)]" />

          <div className="relative flex items-center justify-between">
            <div className="flex items-center gap-2">
              <ShieldCheck className="text-cyan-400" size={24} />
              <span className="text-xs font-bold uppercase tracking-widest text-cyan-200">Gestión Integral de Taller y Obras</span>
            </div>
            <div className="grid h-16 w-16 place-items-center rounded-2xl bg-white/10 backdrop-blur-md border border-white/10">
              <img src={logo} alt="" className="h-12 w-12 object-contain" />
            </div>
          </div>

          <div className="relative space-y-6 my-auto max-w-md">
            <div>
              <span className="inline-block rounded-full bg-cyan-500/20 border border-cyan-400/30 px-3 py-1 text-xs font-extrabold uppercase tracking-wider text-cyan-300 mb-3">
                Operaciones 2026
              </span>
              <h2 className="text-3xl font-black leading-tight">
                Control Exacto de Perfilería, Vidrios y Remanentes.
              </h2>
              <p className="mt-3 text-sm text-cyan-100/80 leading-relaxed">
                Trazabilidad completa: Cotización → Pedido de Obra → Corte y Armado en Taller → Control de Retazos (Barras 6.10m) → Instalación y Facturación.
              </p>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="rounded-xl border border-white/10 bg-white/5 p-3.5 backdrop-blur-sm">
                <p className="font-extrabold text-cyan-300">Líneas Reales</p>
                <p className="text-slate-300 mt-1">Perfiles de aluminio, vidrio templado/crudo y herrajes de obra.</p>
              </div>
              <div className="rounded-xl border border-white/10 bg-white/5 p-3.5 backdrop-blur-sm">
                <p className="font-extrabold text-cyan-300">Costeo PEPS</p>
                <p className="text-slate-300 mt-1">Valuación estricta de inventario por lotes y márgenes reales.</p>
              </div>
              <div className="rounded-xl border border-white/10 bg-white/5 p-3.5 backdrop-blur-sm">
                <p className="font-extrabold text-cyan-300">Auditoría Sellada</p>
                <p className="text-slate-300 mt-1">Registro inmutable de accesos, permisos y transacciones.</p>
              </div>
              <div className="rounded-xl border border-white/10 bg-white/5 p-3.5 backdrop-blur-sm">
                <p className="font-extrabold text-cyan-300">Normativa Nicaragua</p>
                <p className="text-slate-300 mt-1">Cumplimiento fiscal Ley 822, INSS, INATEC y Código del Trabajo.</p>
              </div>
            </div>
          </div>

          <div className="relative pt-6 border-t border-white/10 flex items-center justify-between text-xs text-cyan-200/70">
            <span>Conexión cifrada a SQL Server 2025</span>
            <span>Instalaciones Raquel · Managua</span>
          </div>
        </div>
      </section>

      {/* Modal de Recuperación Segura de Contraseña */}
      <AnimatePresence>
        {showRecoverModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/70 backdrop-blur-sm">
            <motion.div
              className="relative w-full max-w-md rounded-3xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-white/10 dark:bg-slate-900"
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
            >
              <div className="flex items-center justify-between border-b border-slate-100 dark:border-white/10 pb-4">
                <div className="flex items-center gap-2">
                  <div className="grid h-9 w-9 place-items-center rounded-xl bg-brand-500/10 text-brand-600 dark:text-cyan-400">
                    <KeyRound size={20} />
                  </div>
                  <div>
                    <h3 className="font-extrabold text-slate-900 dark:text-white">Recuperar Contraseña</h3>
                    <p className="text-xs text-slate-500 dark:text-slate-400">Restablecimiento seguro de un solo uso</p>
                  </div>
                </div>
                <button
                  type="button"
                  className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 dark:hover:bg-white/10"
                  onClick={() => {
                    setShowRecoverModal(false);
                    setRecoverNotice(null);
                    setRecoverStep("request");
                  }}
                  aria-label="Cerrar ventana"
                >
                  <X size={18} />
                </button>
              </div>

              {recoverStep === "request" ? (
                <form onSubmit={handleRecoverRequest} className="mt-4 space-y-4">
                  <p className="text-xs text-slate-600 dark:text-slate-300">
                    Ingrese el correo electrónico registrado con el que fue habilitada su cuenta en el sistema.
                  </p>

                  <label className="block">
                    <span className="mb-1.5 block text-xs font-bold text-slate-700 dark:text-slate-300">
                      Correo Electrónico
                    </span>
                    <input
                      type="email"
                      required
                      value={recoverEmail}
                      onChange={(e) => setRecoverEmail(e.target.value)}
                      placeholder="usuario@raquel.com"
                      className="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-sm dark:border-white/10 dark:bg-white/5 focus:border-brand-500 focus:outline-none"
                    />
                  </label>

                  {recoverNotice && (
                    <div
                      className={`rounded-xl p-3 text-xs font-medium ${
                        recoverNotice.tone === "error"
                          ? "bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300"
                          : "bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300"
                      }`}
                    >
                      {recoverNotice.message}
                    </div>
                  )}

                  <div className="flex justify-end gap-2 pt-2">
                    <Button
                      type="button"
                      variant="ghost"
                      onClick={() => setShowRecoverModal(false)}
                    >
                      Cancelar
                    </Button>
                    <Button type="submit" disabled={recoverLoading}>
                      {recoverLoading ? "Comprobando..." : "Solicitar código"}
                    </Button>
                  </div>
                </form>
              ) : (
                <form onSubmit={handleRecoverVerify} className="mt-4 space-y-4">
                  {recoverNotice && (
                    <div
                      className={`rounded-xl p-3 text-xs leading-relaxed ${
                        recoverNotice.tone === "warn"
                          ? "bg-amber-50 border border-amber-200 text-amber-800 dark:bg-amber-950/40 dark:border-amber-800/40 dark:text-amber-300"
                          : recoverNotice.tone === "success"
                            ? "bg-emerald-50 border border-emerald-200 text-emerald-800 dark:bg-emerald-950/40 dark:border-emerald-800/40 dark:text-emerald-300"
                            : "bg-cyan-50 border border-cyan-200 text-cyan-800 dark:bg-cyan-950/40 dark:border-cyan-800/40 dark:text-cyan-300"
                      }`}
                    >
                      <p className="font-bold">{recoverNotice.message}</p>
                      {recoverNotice.authCode && (
                        <div className="mt-2 rounded-lg bg-white/60 p-2 dark:bg-black/30 flex items-center justify-between">
                          <span className="text-[11px] font-mono">Código de entrega autorizada:</span>
                          <span className="font-mono font-black text-sm tracking-widest text-brand-700 dark:text-cyan-300">
                            {recoverNotice.authCode}
                          </span>
                        </div>
                      )}
                    </div>
                  )}

                  <label className="block">
                    <span className="mb-1.5 block text-xs font-bold text-slate-700 dark:text-slate-300">
                      Código de 6 dígitos
                    </span>
                    <input
                      type="text"
                      required
                      maxLength={6}
                      value={recoverCode}
                      onChange={(e) => setRecoverCode(e.target.value)}
                      placeholder="123456"
                      className="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-center font-mono text-base font-bold tracking-widest dark:border-white/10 dark:bg-white/5 focus:border-brand-500 focus:outline-none"
                    />
                  </label>

                  <label className="block">
                    <span className="mb-1.5 block text-xs font-bold text-slate-700 dark:text-slate-300">
                      Nueva Contraseña
                    </span>
                    <input
                      type="password"
                      required
                      minLength={8}
                      value={recoverNewPassword}
                      onChange={(e) => setRecoverNewPassword(e.target.value)}
                      placeholder="Mínimo 8 caracteres"
                      className="h-11 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 text-sm dark:border-white/10 dark:bg-white/5 focus:border-brand-500 focus:outline-none"
                    />
                  </label>

                  <div className="flex justify-end gap-2 pt-2">
                    <Button
                      type="button"
                      variant="ghost"
                      onClick={() => setRecoverStep("request")}
                    >
                      Atrás
                    </Button>
                    <Button type="submit" disabled={recoverLoading}>
                      {recoverLoading ? "Actualizando..." : "Restablecer contraseña"}
                    </Button>
                  </div>
                </form>
              )}
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </main>
  );
}

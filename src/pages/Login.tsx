import { useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { motion } from "framer-motion";
import { Eye, EyeOff, Lock, Mail, Moon, Sun } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import logo from "../assets/logo-window.png";
import { useAuth } from "../auth/AuthContext";
import { seedUsers } from "../auth/roles";
import { Button } from "../components/Button";
import { RoleMark } from "../components/RoleMark";
import { clearLoginGuard, loginLockMs, registerLoginFail } from "../lib/loginGuard";
import { useErp } from "../store/erpStore";

const schema = z.object({
  email: z.string().email("Correo inválido"),
  password: z.string().min(6, "Mínimo 6 caracteres"),
  remember: z.boolean()
});

type FormValues = z.infer<typeof schema>;

export default function Login({ dark, toggleTheme }: { dark: boolean; toggleTheme: () => void }) {
  const { login } = useAuth();
  const { db, log } = useErp();
  const [show, setShow] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lockLeft, setLockLeft] = useState(() => loginLockMs());
  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors, isValid }
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    mode: "onChange",
    defaultValues: { email: "admin@raquel.com", password: "raquel2026", remember: true }
  });

  const submit = handleSubmit(async (values) => {
    const locked = loginLockMs();
    if (locked > 0) {
      setLockLeft(locked);
      setError(`Acceso cerrado ${Math.ceil(locked / 1000)} s. Probá de nuevo.`);
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
        detail: guard.locked ? "clave mala · candado" : "clave mala"
      });
      setError(guard.locked
        ? "Tres claves malas. El acceso se cierra 90 segundos."
        : (err instanceof Error ? err.message : "No se pudo iniciar sesión"));
    } finally {
      setLoading(false);
    }
  });

  const directory = db.users.length ? db.users : seedUsers;

  return (
    <main className="relative grid min-h-screen overflow-hidden p-4 md:place-items-center">
      <div className="absolute inset-0 bg-[linear-gradient(120deg,rgba(10,146,200,.18),transparent_35%,rgba(232,75,95,.10)_72%,transparent)]" />
      <section className="relative grid w-full max-w-6xl overflow-hidden rounded-2xl bg-white shadow-glow dark:bg-slate-950 md:grid-cols-[.92fr_1.08fr]">
        <motion.div className="glass-panel flex min-h-[720px] flex-col justify-between p-6 sm:p-8" initial={{ x: -24, opacity: 0 }} animate={{ x: 0, opacity: 1 }}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <img src={logo} alt="Instalaciones Raquel" className="h-14 w-14 rounded-xl bg-white object-contain p-1 shadow-soft" />
              <div>
                <h1 className="text-lg font-extrabold">Instalaciones Raquel</h1>
                <p className="text-sm text-slate-500 dark:text-slate-300">ERP Aluminio y Vidrio</p>
              </div>
            </div>
            <button className="rounded-lg p-2 hover:bg-slate-100 dark:hover:bg-white/10" onClick={toggleTheme} aria-label="Cambiar tema">
              {dark ? <Sun size={20} /> : <Moon size={20} />}
            </button>
          </div>

          <form onSubmit={submit} className="mx-auto w-full max-w-sm space-y-4" noValidate>
            <div>
              <h2 className="text-3xl font-extrabold">Bienvenido</h2>
              <p className="mt-2 text-sm text-slate-500">Entrá con tu cuenta para continuar.</p>
            </div>
            <label className="block">
              <span className="mb-2 block text-sm font-semibold">Correo</span>
              <span className="relative block">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input className="h-12 w-full rounded-lg border border-slate-200 bg-white/80 pl-10 pr-3 dark:border-white/10 dark:bg-white/10" {...register("email")} />
              </span>
              {errors.email && <span className="mt-2 block text-xs font-semibold text-ember">{errors.email.message}</span>}
            </label>
            <label className="block">
              <span className="mb-2 block text-sm font-semibold">Contraseña</span>
              <span className="relative block">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input type={show ? "text" : "password"} className="h-12 w-full rounded-lg border border-slate-200 bg-white/80 pl-10 pr-12 dark:border-white/10 dark:bg-white/10" {...register("password")} />
                <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 rounded p-1" onClick={() => setShow((value) => !value)} aria-label="Mostrar contraseña">
                  {show ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </span>
              {errors.password && <span className="mt-2 block text-xs font-semibold text-ember">{errors.password.message}</span>}
            </label>
            <label className="flex items-center gap-2 text-sm font-medium">
              <input type="checkbox" className="h-4 w-4" {...register("remember")} />
              Recordar sesión
            </label>
            {error && <div className="rounded-lg bg-rose-50 px-3 py-2 text-xs font-semibold text-rose-700">{error}</div>}
            <Button className="h-12 w-full" disabled={!isValid || loading || lockLeft > 0}>
              {loading ? "Entrando..." : lockLeft > 0 ? `Cerrado ${Math.ceil(lockLeft / 1000)} s` : "Iniciar sesión"}
            </Button>
            <div className="grid gap-2">
              {directory.map((item) => (
                <button
                  type="button"
                  key={item.id}
                  className="rounded-lg border border-slate-200 px-3 py-2 text-left text-xs hover:border-brand-400 dark:border-white/10"
                  onClick={() => {
                    setValue("email", item.email, { shouldValidate: true });
                    setValue("password", item.password, { shouldValidate: true });
                  }}
                >
                    <span className="flex items-center justify-between gap-2">
                    <strong>{item.name}</strong>
                    <RoleMark role={item.hierarchy} compact />
                  </span>
                  <div className="text-slate-400">{item.email}</div>
                </button>
              ))}
            </div>
          </form>
          <p className="text-xs text-slate-400">Demo · raquel2026</p>
        </motion.div>
        <div className="relative hidden min-h-[720px] overflow-hidden bg-brand-900 p-10 text-white md:block">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(114,212,239,.32),transparent_32%),radial-gradient(circle_at_80%_88%,rgba(232,75,95,.22),transparent_28%)]" />
          <motion.div
            className="absolute left-10 top-24 h-28 w-44 rounded-xl border border-white/20 bg-white/10"
            animate={{ y: [0, -12, 0], rotate: [-1, 2, -1] }}
            transition={{ duration: 5, repeat: Infinity }}
          />
          <motion.div
            className="absolute bottom-28 right-12 h-36 w-24 rounded-lg border border-cyan-200/30 bg-gradient-to-b from-white/25 to-transparent"
            animate={{ y: [0, 10, 0] }}
            transition={{ duration: 4.2, repeat: Infinity }}
          />
          <div className="relative flex h-full flex-col justify-between">
            <div className="ml-auto grid h-24 w-24 place-items-center rounded-2xl bg-white/10">
              <img src={logo} alt="" className="h-20 w-20 object-contain" />
            </div>
            <motion.div className="rounded-2xl border border-white/15 bg-white/10 p-6" animate={{ y: [0, -8, 0] }} transition={{ duration: 5, repeat: Infinity }}>
              <p className="text-sm font-bold uppercase tracking-[0.2em] text-cyan-100">Promo showroom</p>
              <h3 className="mt-2 text-2xl font-extrabold">Hasta 15% en packs de electrodomésticos y obras grandes.</h3>
              <div className="mt-5 grid grid-cols-2 gap-3 text-sm">
                <div className="rounded-lg bg-white/10 p-3">TV + Aire</div>
                <div className="rounded-lg bg-white/10 p-3">Refri + Lavadora</div>
                <div className="rounded-lg bg-white/10 p-3">Factura con QR</div>
                <div className="rounded-lg bg-white/10 p-3">Proformas vivos</div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>
    </main>
  );
}

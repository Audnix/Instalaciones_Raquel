import { useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { motion } from "framer-motion";
import { Eye, EyeOff, Lock, Mail, Moon, Sun } from "lucide-react";
import { useForm } from "react-hook-form";
import { z } from "zod";
import logo from "../assets/logo-window.png";
import { Button } from "../components/Button";

const schema = z.object({
  email: z.string().email("Correo invalido"),
  password: z.string().min(6, "Minimo 6 caracteres"),
  remember: z.boolean()
});

type FormValues = z.infer<typeof schema>;

export default function Login({ onLogin, dark, toggleTheme }: { onLogin: () => void; dark: boolean; toggleTheme: () => void }) {
  const [show, setShow] = useState(false);
  const [loading, setLoading] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors, isValid }
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    mode: "onChange",
    defaultValues: { email: "admin@raquel.com", password: "raquel2026", remember: true }
  });

  const submit = handleSubmit(() => {
    setLoading(true);
    window.setTimeout(onLogin, 850);
  });

  return (
    <main className="relative grid min-h-screen overflow-hidden p-4 md:place-items-center">
      <div className="absolute inset-0 bg-[linear-gradient(120deg,rgba(10,146,200,.18),transparent_35%,rgba(232,75,95,.10)_72%,transparent)]" />
      <div className="absolute left-8 top-8 hidden h-64 w-64 rounded-full border border-white/50 bg-white/30 blur-3xl dark:bg-cyan-400/10 md:block" />
      <section className="relative grid w-full max-w-6xl overflow-hidden rounded-2xl bg-white shadow-glow dark:bg-slate-950 md:grid-cols-[.92fr_1.08fr]">
        <motion.div
          className="glass-panel flex min-h-[680px] flex-col justify-between p-6 sm:p-8"
          initial={{ x: -24, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ duration: 0.55 }}
        >
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <img src={logo} alt="Instalaciones Raquel" className="h-14 w-14 rounded-xl bg-white object-contain p-1 shadow-soft" />
              <div>
                <h1 className="text-lg font-extrabold text-ink dark:text-white">Instalaciones Raquel</h1>
                <p className="text-sm text-slate-500 dark:text-slate-300">ERP Aluminio y Vidrio</p>
              </div>
            </div>
            <button className="rounded-lg p-2 hover:bg-slate-100 dark:hover:bg-white/10" onClick={toggleTheme} aria-label="Cambiar tema">
              {dark ? <Sun size={20} /> : <Moon size={20} />}
            </button>
          </div>

          <form onSubmit={submit} className="mx-auto w-full max-w-sm space-y-5" noValidate>
            <div>
              <motion.h2 className="text-3xl font-extrabold text-ink dark:text-white" initial={{ y: 12, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
                Acceso empresarial
              </motion.h2>
              <p className="mt-2 text-sm text-slate-500 dark:text-slate-300">Control total de ventas, inventario, proyectos, finanzas y produccion.</p>
            </div>
            <label className="block">
              <span className="mb-2 block text-sm font-semibold">Correo</span>
              <span className="relative block">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input className="h-12 w-full rounded-lg border border-slate-200 bg-white/80 pl-10 pr-3 transition focus:border-brand-500 dark:border-white/10 dark:bg-white/10" {...register("email")} />
              </span>
              {errors.email && <span className="mt-2 block text-xs font-semibold text-ember">{errors.email.message}</span>}
            </label>
            <label className="block">
              <span className="mb-2 block text-sm font-semibold">Contrasena</span>
              <span className="relative block">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input type={show ? "text" : "password"} className="h-12 w-full rounded-lg border border-slate-200 bg-white/80 pl-10 pr-12 transition focus:border-brand-500 dark:border-white/10 dark:bg-white/10" {...register("password")} />
                <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 rounded p-1 text-slate-500 hover:bg-slate-100 dark:hover:bg-white/10" onClick={() => setShow((value) => !value)} aria-label="Mostrar contrasena">
                  {show ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </span>
              {errors.password && <span className="mt-2 block text-xs font-semibold text-ember">{errors.password.message}</span>}
            </label>
            <div className="flex items-center justify-between gap-3 text-sm">
              <label className="flex items-center gap-2 font-medium">
                <input type="checkbox" className="h-4 w-4 rounded border-slate-300 text-brand-600" {...register("remember")} />
                Recordar sesion
              </label>
              <button type="button" className="font-bold text-brand-700 hover:underline dark:text-glass">Recuperar</button>
            </div>
            <Button className="h-12 w-full" disabled={!isValid || loading}>
              {loading ? "Validando..." : "Iniciar sesion"}
            </Button>
            <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs font-semibold text-emerald-800 dark:border-emerald-400/20 dark:bg-emerald-400/10 dark:text-emerald-100">
              Demo seguro con validacion en tiempo real y transicion animada.
            </div>
          </form>

          <p className="text-xs text-slate-500 dark:text-slate-400">Auditoria, roles, permisos y trazabilidad desde el primer acceso.</p>
        </motion.div>
        <div className="relative hidden min-h-[680px] overflow-hidden bg-brand-900 p-10 text-white md:block">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(114,212,239,.32),transparent_32%),radial-gradient(circle_at_80%_88%,rgba(232,75,95,.22),transparent_28%)]" />
          <div className="relative flex h-full flex-col justify-between">
            <div className="ml-auto grid h-24 w-24 place-items-center rounded-2xl bg-white/10 backdrop-blur">
              <img src={logo} alt="" className="h-20 w-20 object-contain" />
            </div>
            <motion.div className="rounded-2xl border border-white/15 bg-white/10 p-6 backdrop-blur-xl" animate={{ y: [0, -8, 0] }} transition={{ duration: 5, repeat: Infinity }}>
              <div className="mb-5 grid grid-cols-3 gap-3">
                {["Ventas", "Stock", "Caja"].map((item, index) => (
                  <div key={item} className="rounded-lg bg-white/14 p-3">
                    <p className="text-xs text-cyan-100">{item}</p>
                    <p className="mt-2 text-xl font-extrabold">{index === 0 ? "1.84M" : index === 1 ? "94%" : "428K"}</p>
                  </div>
                ))}
              </div>
              <div className="h-3 rounded-full bg-white/15">
                <div className="h-full w-[72%] rounded-full bg-glass" />
              </div>
              <p className="mt-4 text-sm text-cyan-50">Panel unificado para fabricar, instalar, cobrar, pagar y auditar cada movimiento.</p>
            </motion.div>
          </div>
        </div>
      </section>
    </main>
  );
}

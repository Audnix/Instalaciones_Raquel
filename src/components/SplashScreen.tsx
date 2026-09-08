import { motion } from "framer-motion";
import { useEffect } from "react";
import logo from "../assets/logo-window.png";

export function SplashScreen({ onDone }: { onDone: () => void }) {
  useEffect(() => {
    const timer = window.setTimeout(onDone, 2800);
    return () => window.clearTimeout(timer);
  }, [onDone]);

  return (
    <motion.div
      className="fixed inset-0 z-[100] grid place-items-center overflow-hidden bg-[#071820] text-white"
      initial={{ opacity: 1 }}
      exit={{ opacity: 0, scale: 1.02 }}
      transition={{ duration: 0.5 }}
    >
      <div className="pointer-events-none absolute inset-0">
        <motion.div
          className="absolute -left-24 top-10 h-72 w-72 rounded-full bg-cyan-400/20 blur-3xl"
          animate={{ x: [0, 40, 0], y: [0, 30, 0] }}
          transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
        />
        <motion.div
          className="absolute -right-16 bottom-0 h-80 w-80 rounded-full bg-rose-500/15 blur-3xl"
          animate={{ x: [0, -30, 0], y: [0, -40, 0] }}
          transition={{ duration: 7, repeat: Infinity, ease: "easeInOut" }}
        />
        {[0, 1, 2, 3, 4].map((i) => (
          <motion.div
            key={i}
            className="absolute h-px bg-gradient-to-r from-transparent via-cyan-200/40 to-transparent"
            style={{ top: `${18 + i * 16}%`, left: "-10%", width: "120%" }}
            animate={{ x: ["-8%", "8%", "-8%"], opacity: [0.15, 0.45, 0.15] }}
            transition={{ duration: 4 + i * 0.4, repeat: Infinity, ease: "easeInOut", delay: i * 0.2 }}
          />
        ))}
        <motion.div
          className="absolute left-[12%] top-[22%] h-24 w-40 rounded-lg border border-cyan-200/20 bg-white/5 backdrop-blur-sm"
          animate={{ y: [0, -14, 0], rotate: [-2, 2, -2] }}
          transition={{ duration: 5, repeat: Infinity }}
        />
        <motion.div
          className="absolute bottom-[18%] right-[14%] h-28 w-20 rounded-md border border-white/15 bg-gradient-to-b from-white/20 to-white/5"
          animate={{ y: [0, 12, 0], rotate: [3, -2, 3] }}
          transition={{ duration: 4.5, repeat: Infinity }}
        />
      </div>

      <div className="relative flex flex-col items-center px-6 text-center">
        <motion.div
          className="relative mb-6"
          initial={{ scale: 0.7, opacity: 0, rotate: -8 }}
          animate={{ scale: 1, opacity: 1, rotate: 0 }}
          transition={{ type: "spring", stiffness: 120, damping: 14 }}
        >
          <motion.div
            className="absolute -inset-6 rounded-[2rem] border border-cyan-300/30"
            animate={{ rotate: 360 }}
            transition={{ duration: 18, repeat: Infinity, ease: "linear" }}
          />
          <motion.div
            className="absolute -inset-3 rounded-[1.6rem] border border-white/10"
            animate={{ rotate: -360 }}
            transition={{ duration: 12, repeat: Infinity, ease: "linear" }}
          />
          <div className="relative grid h-28 w-28 place-items-center rounded-3xl bg-white shadow-[0_0_60px_rgba(114,212,239,.35)]">
            <img src={logo} alt="Instalaciones Raquel" className="h-20 w-20 object-contain" />
          </div>
        </motion.div>

        <motion.p
          className="text-xs font-bold uppercase tracking-[0.35em] text-cyan-200"
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          Aluminio · Vidrio · Operación
        </motion.p>
        <motion.h1
          className="mt-3 text-3xl font-black tracking-tight sm:text-4xl"
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.35 }}
        >
          Instalaciones Raquel
        </motion.h1>
        <motion.p
          className="mt-2 max-w-md text-sm text-cyan-50/75"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
        >
          Taller, bodega, caja y cobro en un solo flujo.
        </motion.p>

        <motion.div className="mt-8 flex flex-wrap justify-center gap-2" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.65 }}>
          {["Producción", "Inventario", "Ventas", "Finanzas"].map((label, index) => (
            <motion.span
              key={label}
              className="rounded-full border border-white/15 bg-white/5 px-3 py-1 text-[11px] font-semibold text-cyan-50"
              animate={{ y: [0, -6, 0] }}
              transition={{ duration: 2.2, repeat: Infinity, delay: index * 0.18 }}
            >
              {label}
            </motion.span>
          ))}
        </motion.div>

        <div className="mt-10 h-1 w-44 overflow-hidden rounded-full bg-white/10">
          <motion.div
            className="h-full rounded-full bg-gradient-to-r from-cyan-300 to-[#0a92c8]"
            initial={{ width: "0%" }}
            animate={{ width: "100%" }}
            transition={{ duration: 2.4, ease: "easeInOut" }}
          />
        </div>
      </div>
    </motion.div>
  );
}

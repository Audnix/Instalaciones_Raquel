import { motion } from "framer-motion";
import logo from "../assets/logo-window.png";

export function Loader({ label = "Cargando" }: { label?: string }) {
  return (
    <div className="grid min-h-screen place-items-center bg-slate-50 text-ink dark:bg-slate-950 dark:text-white">
      <motion.div
        className="flex flex-col items-center gap-4"
        initial={{ opacity: 0, scale: 0.96 }}
        animate={{ opacity: 1, scale: 1 }}
      >
        <div className="grid h-20 w-20 place-items-center rounded-2xl bg-white shadow-glow dark:bg-slate-900">
          <img src={logo} alt="Instalaciones Raquel" className="h-14 w-14 object-contain" />
        </div>
        <div className="h-2 w-44 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-800">
          <motion.div
            className="h-full rounded-full bg-brand-500"
            initial={{ x: "-100%" }}
            animate={{ x: "100%" }}
            transition={{ duration: 1.1, repeat: Infinity, ease: "easeInOut" }}
          />
        </div>
        <p className="text-sm font-semibold text-slate-500 dark:text-slate-300">{label}</p>
      </motion.div>
    </div>
  );
}

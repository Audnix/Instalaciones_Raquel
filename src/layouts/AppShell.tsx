import { ReactNode, useMemo, useState } from "react";
import { NavLink } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import { Bell, LogOut, Menu, Moon, PanelLeftClose, Search, Sun } from "lucide-react";
import logo from "../assets/logo-window.png";
import { useAuth } from "../auth/AuthContext";
import { hierarchyMeta } from "../auth/roles";
import { Button } from "../components/Button";
import { modules } from "../data/erpData";
import { useErp } from "../store/erpStore";

export function AppShell({
  children,
  dark,
  toggleTheme,
  onLogout
}: {
  children: ReactNode;
  dark: boolean;
  toggleTheme: () => void;
  onLogout: () => void;
}) {
  const [open, setOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const { user, canAccess } = useAuth();
  const { db } = useErp();
  const visible = useMemo(() => modules.filter((item) => canAccess(item.id)), [canAccess]);
  const grouped = useMemo(() => {
    const map: Record<string, typeof visible> = {};
    visible.forEach((item) => {
      map[item.group] = map[item.group] ? [...map[item.group], item] : [item];
    });
    return map;
  }, [visible]);
  const alerts = db.products.filter((item) => db.lots.filter((lot) => lot.productId === item.id).reduce((sum, lot) => sum + lot.quantity, 0) < item.minQuantity);

  const sidebar = (
    <aside className="flex h-full flex-col bg-brand-900 text-white">
      <div className="flex h-20 items-center gap-3 px-4">
        <img src={logo} alt="Instalaciones Raquel" className="h-12 w-12 rounded-xl bg-white object-contain p-1 shadow-glow" />
        {!collapsed && (
          <div>
            <p className="text-sm font-extrabold leading-tight">Instalaciones Raquel</p>
            <p className="text-xs text-cyan-100">Aluminio y Vidrio</p>
          </div>
        )}
      </div>
      <nav className="table-scrollbar flex-1 space-y-1 overflow-y-auto px-3 pb-4">
        <NavLink to="/" onClick={() => setOpen(false)} className={({ isActive }) => `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold ${isActive ? "bg-white text-brand-900 shadow-lg" : "text-cyan-50 hover:bg-white/12"}`}>
          <PanelLeftClose size={18} />
          {!collapsed && "Dashboard"}
        </NavLink>
        {Object.entries(grouped).map(([group, items]) => (
          <div key={group}>
            {!collapsed && <p className="mb-1 mt-4 px-3 text-[11px] font-bold uppercase tracking-wide text-cyan-200">{group}</p>}
            {items.map((item) => (
              <NavLink key={item.id} to={`/${item.id}`} title={item.description} onClick={() => setOpen(false)} className={({ isActive }) => `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold ${isActive ? "bg-white text-brand-900 shadow-lg" : "text-cyan-50 hover:bg-white/12"}`}>
                <item.icon size={18} />
                {!collapsed && item.label}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>
      <div className="border-t border-white/10 p-3">
        <button className="hidden w-full items-center justify-center rounded-lg p-2 text-cyan-50 hover:bg-white/10 lg:flex" onClick={() => setCollapsed((value) => !value)} aria-label="Alternar menú">
          <PanelLeftClose size={18} />
        </button>
      </div>
    </aside>
  );

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[auto_1fr]">
      <div className={`hidden lg:block ${collapsed ? "w-[76px]" : "w-[250px]"} transition-[width] duration-300`}>{sidebar}</div>
      <AnimatePresence>
        {open && (
          <motion.div className="fixed inset-0 z-50 lg:hidden" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
            <button className="absolute inset-0 bg-slate-950/50" aria-label="Cerrar menú" onClick={() => setOpen(false)} />
            <motion.div className="relative h-full w-[286px] max-w-[86vw]" initial={{ x: -300 }} animate={{ x: 0 }} exit={{ x: -300 }}>
              {sidebar}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
      <main className="min-w-0">
        <header className="sticky top-0 z-30 border-b border-slate-200/70 bg-white/82 px-4 py-3 backdrop-blur-xl dark:border-white/10 dark:bg-slate-950/76 lg:px-6">
          <div className="flex items-center gap-3">
            <button className="rounded-lg p-2 hover:bg-slate-100 dark:hover:bg-white/10 lg:hidden" onClick={() => setOpen(true)} aria-label="Abrir menú">
              <Menu size={22} />
            </button>
            <label className="relative hidden flex-1 md:block">
              <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <input className="h-11 w-full rounded-lg border border-slate-200 bg-slate-50 pl-10 pr-4 text-sm dark:border-white/10 dark:bg-slate-900" placeholder="Buscar clientes, facturas, proyectos o productos" />
            </label>
            <button className="rounded-lg p-2 hover:bg-slate-100 dark:hover:bg-white/10" onClick={toggleTheme} aria-label="Cambiar tema">
              {dark ? <Sun size={20} /> : <Moon size={20} />}
            </button>
            <div className="group relative">
              <button className="relative rounded-lg p-2 hover:bg-slate-100 dark:hover:bg-white/10" aria-label="Notificaciones">
                <Bell size={20} />
                {alerts.length > 0 && <span className="absolute right-1.5 top-1.5 h-2.5 w-2.5 rounded-full bg-ember ring-2 ring-white" />}
              </button>
              <div className="invisible absolute right-0 top-12 w-80 rounded-lg bg-white p-3 opacity-0 shadow-soft transition group-hover:visible group-hover:opacity-100 dark:bg-slate-900">
                {alerts.length ? alerts.map((item) => (
                  <p key={item.id} className="rounded-lg p-2 text-sm"><strong>{item.name}</strong> bajo mínimo.</p>
                )) : <p className="text-sm text-slate-500">Sin alertas de stock.</p>}
              </div>
            </div>
            {user && (
              <div className="hidden text-right sm:block">
                <p className="text-xs font-bold">{user.name}</p>
                <p className="text-[11px] text-slate-500">{hierarchyMeta[user.hierarchy].label}</p>
              </div>
            )}
            <Button variant="ghost" icon={<LogOut size={18} />} onClick={onLogout}>Salir</Button>
          </div>
        </header>
        <div className="p-4 lg:p-6">{children}</div>
      </main>
    </div>
  );
}

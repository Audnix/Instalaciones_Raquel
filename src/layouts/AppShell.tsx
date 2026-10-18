import { ReactNode, useEffect, useMemo, useState } from "react";
import { NavLink } from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import {
  Bell,
  LayoutDashboard,
  ListTodo,
  LogOut,
  Menu,
  Moon,
  PanelLeftClose,
  Search,
  Sun
} from "lucide-react";
import logo from "../assets/logo-window.png";
import { useAuth } from "../auth/AuthContext";
import { hierarchyMeta } from "../auth/roles";
import { Button } from "../components/Button";
import { RoleMark } from "../components/RoleMark";
import { modules } from "../data/erpData";
import { useErp } from "../store/erpStore";

const groupOrder = [
  "Producción",
  "Finanzas",
  "Contabilidad",
  "Mercadotecnia",
  "Compras",
  "Operación",
  "Talento Humano",
  "Gobierno"
];

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
  const [pendingTasksCount, setPendingTasksCount] = useState<number>(0);
  const { user, canAccess } = useAuth();
  const { db, syncStatus } = useErp();

  useEffect(() => {
    let isMounted = true;
    async function fetchTasks() {
      try {
        const token = localStorage.getItem("raquel_token") || sessionStorage.getItem("raquel_token");
        const res = await fetch("/api/tasks/my-tasks", {
          headers: token ? { Authorization: `Bearer ${token}` } : {}
        });
        if (res.ok) {
          const data = await res.json();
          if (isMounted) {
            setPendingTasksCount(data.tasks?.length ?? 0);
          }
        }
      } catch {
        // Fallback a cálculo local
        if (isMounted) {
          const count =
            db.production.filter((p) => p.stage !== "entregado").length +
            (db.proformas ?? []).filter((p) => p.status !== "convertida").length;
          setPendingTasksCount(count);
        }
      }
    }
    void fetchTasks();
    return () => {
      isMounted = false;
    };
  }, [db.production, db.proformas]);

  const visible = useMemo(() => modules.filter((item) => canAccess(item.id)), [canAccess]);

  const grouped = useMemo(() => {
    const map: Record<string, typeof visible> = {};
    visible.forEach((item) => {
      map[item.group] = map[item.group] ? [...map[item.group], item] : [item];
    });
    // Ordenar según groupOrder
    const sorted: Record<string, typeof visible> = {};
    groupOrder.forEach((grp) => {
      if (map[grp] && map[grp].length > 0) {
        sorted[grp] = map[grp];
      }
    });
    // Añadir grupos extras si existieran
    Object.keys(map).forEach((grp) => {
      if (!sorted[grp]) sorted[grp] = map[grp];
    });
    return sorted;
  }, [visible]);

  const alerts = db.products.filter(
    (item) =>
      db.lots
        .filter((lot) => lot.productId === item.id)
        .reduce((sum, lot) => sum + lot.quantity, 0) < item.minQuantity
  );

  const sidebar = (
    <aside className="flex h-full flex-col bg-[#0c2336] text-white select-none border-r border-white/5">
      {/* Encabezado Logo */}
      <div className="flex h-20 items-center gap-3 px-4 border-b border-white/5">
        <img
          src={logo}
          alt="Instalaciones Raquel"
          className="h-11 w-11 rounded-xl bg-white object-contain p-1 shadow-md shrink-0"
        />
        {!collapsed && (
          <div className="overflow-hidden">
            <p className="text-sm font-extrabold leading-tight text-white tracking-tight">
              Instalaciones Raquel
            </p>
            <p className="text-[11px] font-semibold text-cyan-300">Aluminio y Vidrio</p>
          </div>
        )}
      </div>

      {/* Navegación con Scroll */}
      <nav className="table-scrollbar flex-1 space-y-1 overflow-y-auto px-3 py-4">
        {/* VISTAS PRINCIPALES */}
        <div className="space-y-1">
          <NavLink
            to="/"
            end
            onClick={() => setOpen(false)}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-xl px-3 py-2 text-xs transition duration-150 ${
                isActive
                  ? "bg-white text-slate-900 shadow-md font-bold"
                  : "text-slate-200 hover:bg-white/10 hover:text-white font-medium"
              }`
            }
          >
            <LayoutDashboard size={17} className="shrink-0" />
            {!collapsed && <span className="flex-1">Dashboard</span>}
          </NavLink>

          <NavLink
            to="/tareas"
            onClick={() => setOpen(false)}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-xl px-3 py-2 text-xs transition duration-150 ${
                isActive
                  ? "bg-white text-slate-900 shadow-md font-bold"
                  : "text-slate-200 hover:bg-white/10 hover:text-white font-medium"
              }`
            }
          >
            <ListTodo size={17} className="shrink-0 text-cyan-300" />
            {!collapsed && (
              <span className="flex flex-1 items-center justify-between">
                <span>Mis tareas</span>
                {pendingTasksCount > 0 && (
                  <span className="rounded-full bg-cyan-400 px-1.5 py-0.2 text-[10px] font-black text-slate-950">
                    {pendingTasksCount}
                  </span>
                )}
              </span>
            )}
          </NavLink>
        </div>

        {/* GRUPOS MODULARES */}
        {Object.entries(grouped).map(([group, items]) => (
          <div key={group} className="pt-2">
            {!collapsed && (
              <p className="mb-1.5 px-3 text-[10px] font-black uppercase tracking-wider text-cyan-400">
                {group}
              </p>
            )}
            {items.map((item) => (
              <NavLink
                key={item.id}
                to={`/${item.id}`}
                title={item.description}
                onClick={() => setOpen(false)}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-xl px-3 py-2 text-xs transition duration-150 ${
                    isActive
                      ? "bg-white text-slate-900 shadow-md font-bold"
                      : "text-slate-200 hover:bg-white/10 hover:text-white font-medium"
                  }`
                }
              >
                <item.icon size={17} className="shrink-0" />
                {!collapsed && <span>{item.label}</span>}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      {/* Botón de Colapsar Sidebar */}
      <div className="border-t border-white/5 p-3">
        <button
          className="hidden w-full items-center justify-center rounded-xl p-2 text-cyan-200 hover:bg-white/10 transition lg:flex"
          onClick={() => setCollapsed((value) => !value)}
          aria-label={collapsed ? "Expandir menú lateral" : "Colapsar menú lateral"}
        >
          <PanelLeftClose size={18} className={collapsed ? "rotate-180" : ""} />
        </button>
      </div>
    </aside>
  );

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 lg:grid lg:grid-cols-[auto_1fr]">
      {/* Sidebar Desktop */}
      <div
        className={`hidden lg:block ${
          collapsed ? "w-[72px]" : "w-[240px]"
        } transition-[width] duration-300`}
      >
        {sidebar}
      </div>

      {/* Sidebar Mobile Drawer */}
      <AnimatePresence>
        {open && (
          <motion.div
            className="fixed inset-0 z-50 lg:hidden"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            <button
              className="absolute inset-0 bg-slate-950/60 backdrop-blur-sm"
              aria-label="Cerrar menú"
              onClick={() => setOpen(false)}
            />
            <motion.div
              className="relative h-full w-[270px] max-w-[85vw]"
              initial={{ x: -280 }}
              animate={{ x: 0 }}
              exit={{ x: -280 }}
            >
              {sidebar}
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Main Content Area */}
      <main className="min-w-0 flex flex-col">
        {/* Header Bar */}
        <header className="sticky top-0 z-30 border-b border-slate-200/80 bg-white/80 px-4 py-2.5 backdrop-blur-xl dark:border-white/10 dark:bg-slate-900/80 lg:px-6">
          <div className="flex items-center gap-3">
            <button
              className="rounded-xl p-2 hover:bg-slate-100 dark:hover:bg-white/10 lg:hidden"
              onClick={() => setOpen(true)}
              aria-label="Abrir menú"
            >
              <Menu size={20} />
            </button>

            <label className="relative hidden flex-1 md:block max-w-md">
              <Search
                className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400"
                size={16}
              />
              <input
                className="h-9 w-full rounded-xl border border-slate-200 bg-slate-50 pl-9 pr-4 text-xs font-medium dark:border-white/10 dark:bg-slate-950/50 focus:border-brand-500 focus:outline-none transition"
                placeholder="Buscar clientes, OT, facturas o inventario..."
              />
            </label>

            <div className="ml-auto flex items-center gap-2 sm:gap-3">
              <button
                className="rounded-xl p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-white/10 transition"
                onClick={toggleTheme}
                aria-label="Cambiar tema claro/oscuro"
              >
                {dark ? <Sun size={18} /> : <Moon size={18} />}
              </button>

              <span
                className={`hidden items-center gap-1.5 rounded-lg px-2.5 py-1 text-[11px] font-bold sm:inline-flex ${
                  syncStatus === "connected"
                    ? "bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300 border border-emerald-200/50"
                    : syncStatus === "loading"
                      ? "bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300 border border-amber-200/50"
                      : "bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300 border border-rose-200/50"
                }`}
                title="Conexión SQL Server 2025 (Instalaciones Raquel)"
              >
                <span className="h-1.5 w-1.5 rounded-full bg-current animate-pulse" />
                {syncStatus === "connected"
                  ? "SQL Server Conectado"
                  : syncStatus === "loading"
                    ? "Conectando..."
                    : "Solo local"}
              </span>

              {/* Notificaciones */}
              <div className="group relative">
                <button
                  className="relative rounded-xl p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-white/10 transition"
                  aria-label="Notificaciones del sistema"
                >
                  <Bell size={18} />
                  {alerts.length > 0 && (
                    <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-rose-500 ring-2 ring-white" />
                  )}
                </button>
                <div className="invisible absolute right-0 top-11 w-72 rounded-2xl border border-slate-200 bg-white p-3 opacity-0 shadow-xl transition group-hover:visible group-hover:opacity-100 dark:border-white/10 dark:bg-slate-900 z-40">
                  <p className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
                    Alertas de Bodega
                  </p>
                  {alerts.length ? (
                    <div className="space-y-1.5 max-h-48 overflow-y-auto">
                      {alerts.map((item) => (
                        <p
                          key={item.id}
                          className="rounded-lg bg-rose-50 p-2 text-xs text-rose-800 dark:bg-rose-950/30 dark:text-rose-300"
                        >
                          <strong>{item.name}</strong> bajo mínimo.
                        </p>
                      ))}
                    </div>
                  ) : (
                    <p className="text-xs text-slate-500">Sin alertas de existencias.</p>
                  )}
                </div>
              </div>

              {/* Usuario activo */}
              {user && (
                <div className="hidden items-center gap-2.5 pl-2 sm:flex border-l border-slate-200 dark:border-white/10">
                  <div className="text-right">
                    <p className="text-xs font-bold leading-tight text-slate-800 dark:text-white">
                      {user.name}
                    </p>
                    <p className="text-[10px] text-slate-500 dark:text-slate-400">
                      {hierarchyMeta[user.hierarchy]?.label}
                    </p>
                  </div>
                  <RoleMark role={user.hierarchy} compact />
                </div>
              )}

              <Button
                variant="ghost"
                className="!text-xs !py-1.5 !px-2.5"
                icon={<LogOut size={16} />}
                onClick={onLogout}
              >
                Salir
              </Button>
            </div>
          </div>
        </header>

        {/* View Content */}
        <div className="flex-1 p-4 lg:p-6">{children}</div>
      </main>
    </div>
  );
}

import { useCallback, useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { CheckCircle2, ArrowRight, RefreshCw } from "lucide-react";
import { authenticatedFetch } from "../auth/apiSession";
import { getApiBaseUrl } from "../lib/apiBase";
import { useSessionView } from "../lib/useSessionView";
import { parseTaskResponse, type ErpTask } from "../lib/taskResponse";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";
import { PageHeader, StatusPill } from "../components/Ui";

export default function MyTasksPage() {
  const { user } = useAuth();
  const [tasks, setTasks] = useState<ErpTask[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useSessionView<"todas" | "alta" | "media">("priority", "todas");

  const [error, setError] = useState("");
  const requestVersion = useRef(0);
  const loadTasks = useCallback(async () => {
    const version = ++requestVersion.current;
    setLoading(true);
    try {
      setError("");
      const res = await authenticatedFetch(`${getApiBaseUrl()}/api/tasks/my-tasks`);
      if (!res.ok) throw new Error("No se pudieron consultar los pendientes.");
      if (res.ok) {
        const tasks = parseTaskResponse(await res.json());
        if (version === requestVersion.current) setTasks(tasks);
      }
    } catch {
      if (version === requestVersion.current) setError("No se pudieron consultar los pendientes. Pulse Actualizar para reintentar.");
    } finally {
      if (version === requestVersion.current) setLoading(false);
    }
  }, [user?.id]);

  useEffect(() => {
    setTasks([]);
    void loadTasks();
    return () => { requestVersion.current += 1; };
  }, [loadTasks]);

  const filteredTasks = tasks.filter((t) => {
    if (filter === "todas") return true;
    return t.priority === filter;
  });

  const highCount = tasks.filter((t) => t.priority === "alta").length;

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <PageHeader
          kicker="Bandeja Operativa"
          title="Mis Tareas y Pendientes"
          subtitle={`Tareas asignadas para ${user?.name ?? "colaborador"} según su área y responsabilidades autorizadas.`}
        />
        <Button
          variant="secondary"
          icon={<RefreshCw size={16} className={loading ? "animate-spin" : ""} />}
          disabled={loading}
          onClick={() => void loadTasks()}
        >
          Actualizar
        </Button>
      </div>

      <div className="grid gap-3 sm:grid-cols-3">
        <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-soft dark:border-white/10 dark:bg-slate-900">
          <p className="text-xs font-bold uppercase text-slate-400">Total Pendientes</p>
          <div className="mt-1 flex items-baseline gap-2">
            <span className="text-2xl font-black text-slate-800 dark:text-white">{loading || error ? "—" : tasks.length}</span>
            <span className="text-xs text-slate-500">en su bandeja</span>
          </div>
        </div>
        <div className="rounded-2xl border border-rose-200 bg-rose-50/50 p-4 shadow-soft dark:border-rose-900/30 dark:bg-rose-950/20">
          <p className="text-xs font-bold uppercase text-rose-500">Prioridad Alta</p>
          <div className="mt-1 flex items-baseline gap-2">
            <span className="text-2xl font-black text-rose-700 dark:text-rose-300">{loading || error ? "—" : highCount}</span>
            <span className="text-xs text-rose-600/80">requieren atención pronta</span>
          </div>
        </div>
        <div className="rounded-2xl border border-cyan-200 bg-cyan-50/50 p-4 shadow-soft dark:border-cyan-900/30 dark:bg-cyan-950/20">
          <p className="text-xs font-bold uppercase text-cyan-600 dark:text-cyan-400">Áreas Conectadas</p>
          <div className="mt-1 text-sm font-bold text-slate-700 dark:text-slate-300">
            {user?.areas?.length ? user.areas.join(", ") : "Área General"}
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2 border-b border-slate-200 dark:border-white/10 pb-2">
        <span className="text-xs font-bold uppercase tracking-wider text-slate-400 mr-2">Filtrar:</span>
        <button
          onClick={() => setFilter("todas")}
          className={`rounded-lg px-3 py-1 text-xs font-bold transition ${
            filter === "todas"
              ? "bg-slate-900 text-white dark:bg-white dark:text-slate-900"
              : "text-slate-500 hover:bg-slate-100 dark:hover:bg-white/10"
          }`}
        >
          Todas ({loading || error ? "—" : tasks.length})
        </button>
        <button
          onClick={() => setFilter("alta")}
          className={`rounded-lg px-3 py-1 text-xs font-bold transition ${
            filter === "alta"
              ? "bg-rose-600 text-white"
              : "text-slate-500 hover:bg-slate-100 dark:hover:bg-white/10"
          }`}
        >
          Alta prioridad ({loading || error ? "—" : highCount})
        </button>
      </div>

      {loading ? (
        <div className="py-12 text-center text-slate-400">
          <RefreshCw className="mx-auto h-8 w-8 animate-spin text-brand-500 mb-2" />
          <p className="text-sm">Consultando tareas y pendientes de su área...</p>
        </div>
      ) : error ? (
        <div role="alert" className="rounded-xl border border-rose-300 p-4 text-rose-700 dark:text-rose-300">{error}</div>
      ) : filteredTasks.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-slate-300 p-12 text-center dark:border-white/10">
          <CheckCircle2 className="mx-auto h-12 w-12 text-emerald-500 mb-3" />
          <h3 className="text-lg font-bold text-slate-800 dark:text-white">{tasks.length ? "Sin pendientes para este filtro" : "Al día en sus tareas"}</h3>
          <p className="text-sm text-slate-500 mt-1 max-w-sm mx-auto">
            {tasks.length ? "Tiene otros pendientes disponibles. Seleccione Todas para consultarlos." : "No tiene pendientes asignados a su puesto en este momento."}
          </p>
        </div>
      ) : (
        <div className="grid gap-3">
          {filteredTasks.map((t) => (
            <div
              key={t.id}
              className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-soft transition hover:border-brand-300 dark:border-white/10 dark:bg-slate-900"
            >
              <div className="space-y-1.5">
                <div className="flex items-center gap-2">
                  <StatusPill tone={t.priority === "alta" ? "bad" : "warn"}>
                    {t.priority === "alta" ? "Urgente" : "Pendiente"}
                  </StatusPill>
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-400">
                    Módulo: {t.module}
                  </span>
                </div>
                <h4 className="font-extrabold text-slate-900 dark:text-white text-base">{t.title}</h4>
                <p className="text-sm text-slate-600 dark:text-slate-300">{t.detail}</p>
              </div>

              <div className="flex-shrink-0">
                <Link to={t.actionUrl}>
                  <Button variant="secondary" icon={<ArrowRight size={16} />}>
                    {t.actionLabel}
                  </Button>
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

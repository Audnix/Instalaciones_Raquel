import { useMemo } from "react";
import { Link, useParams } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { modules } from "../data/erpData";
import DataHubPage from "./DataHubPage";
import MethodologyPage from "./MethodologyPage";
import RequirementsPage from "./RequirementsPage";
import { ModuleWorkspace } from "./ModuleWorkspace";
import UsersPage from "./UsersPage";
import type { ModuleId } from "../types/erp";

export default function ModulePage() {
  const { moduleId } = useParams();
  const { canAccess } = useAuth();
  const module = useMemo(() => modules.find((item) => item.id === moduleId) ?? modules[0], [moduleId]);

  if (!canAccess(module.id)) {
    return (
      <div className="grid min-h-[50vh] place-items-center">
        <div className="text-center">
          <h1 className="text-2xl font-extrabold">Acceso denegado</h1>
          <p className="mt-2 text-slate-500">Tu rol no incluye el módulo {module.label}.</p>
          <Link to="/" className="mt-4 inline-block rounded-lg bg-brand-600 px-4 py-2 text-white">Volver al dashboard</Link>
        </div>
      </div>
    );
  }

  if (module.id === "usuarios") return <UsersPage />;
  if (module.id === "metodologia") return <MethodologyPage />;
  if (module.id === "ers") return <RequirementsPage />;
  if (module.id === "datos") return <DataHubPage />;
  return <ModuleWorkspace moduleId={module.id as ModuleId} />;
}

import type { ReactNode } from 'react';
import { useErp, scopedWrites, type ModuleScope } from '../store/erpStore';
import { useAuth } from '../auth/AuthContext';
import { Button } from './Button';

export function AreaOperationControl({ children, moduleId }: { children: ReactNode; moduleId: ModuleScope }) {
  const { syncStatus, saving, syncError, reloadState } = useErp();
  const { can } = useAuth();
  const ready = syncStatus === 'connected';
  return <div className="space-y-3">
    <div role="status" className="rounded-xl border p-3 text-sm">
      {saving ? 'Guardando en SQL Server...' : ready ? 'Datos del área confirmados en SQL Server.' : 'No se pudo confirmar la consulta del área.'}
      {syncError && <p>{syncError}</p>}
      {!ready && !saving && <Button onClick={() => { if (syncStatus !== 'conflict' || window.confirm('Se reemplazarán los cambios locales por la versión guardada en SQL. ¿Continuar?')) reloadState(); }}>Consultar de nuevo</Button>}
      {ready && (!can(moduleId, 'write') || !scopedWrites[moduleId].length) && <p>Tu perfil tiene acceso de consulta.</p>}
    </div>
    {ready ? <fieldset disabled={saving} className="m-0 min-w-0 border-0 p-0">{children}</fieldset> : null}
  </div>;
}

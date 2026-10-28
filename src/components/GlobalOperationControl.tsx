import type { ReactNode } from 'react';
import { useErp } from '../store/erpStore';
import { useAuth } from '../auth/AuthContext';
import { Button } from './Button';

export function GlobalOperationControl({children}: {children: ReactNode}) {
  const {db, syncStatus, saving, syncError, reloadState} = useErp();
  const {user} = useAuth();
  const locked = syncStatus !== 'connected' || saving || user?.hierarchy !== 'superadmin';
  const exportPending = () => {
    const state = {...db, users: db.users.map(({password: _password, ...item}) => item)};
    const url=URL.createObjectURL(new Blob([JSON.stringify(state,null,2)],{type:'application/json'}));
    const link=document.createElement('a'); link.href=url; link.download='cambios_pendientes_ERP.json'; link.click();
    setTimeout(()=>URL.revokeObjectURL(url),1000);
  };
  return <div className="space-y-3">
    <div role="status" className={`rounded-xl border p-3 text-sm ${locked ? 'border-amber-300 bg-amber-50 text-amber-950' : 'border-emerald-200 bg-emerald-50 text-emerald-950'}`}>
      {saving ? 'Guardando cambios en SQL. Espera la confirmación antes de registrar otra operación.' : syncStatus === 'connected' ? 'Consulta actualizada desde SQL. Cada cambio se valida y se guarda automáticamente.' : 'Consulta sin confirmar: las operaciones quedan pausadas para evitar cambios sin respaldo.'}
      {user?.hierarchy !== 'superadmin' && <p>Este módulo utiliza el guardado global reservado a superadministración. Tu perfil conserva los servicios específicos autorizados.</p>}
      {syncError && <p className="mt-1">{syncError}</p>}
      {!saving && syncStatus !== 'connected' && <div className="mt-2 flex gap-2">
        <Button type="button" variant="secondary" onClick={exportPending}>Descargar copia de consulta/cambios</Button>
        <Button type="button" onClick={() => { if (!syncError || window.confirm('Se consultará SQL y se reemplazará la copia local. Si tienes cambios sin confirmar, descárgalos antes. ¿Continuar?')) reloadState(); }}>Consultar SQL de nuevo</Button>
      </div>}
    </div>
    <fieldset disabled={locked} className="min-w-0 border-0 p-0 m-0">{children}</fieldset>
  </div>;
}

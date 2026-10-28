import { getApiBaseUrl } from '../lib/apiBase';
import {useEffect,useState} from 'react';
import {authenticatedFetch} from '../auth/apiSession';
import {Button} from './Button';
import {StatusPill} from './Ui';
import {OperationalControlPanel} from './OperationalControlPanel';
type Script={name:string;category:string;order:number|null;exists:boolean;bytes:number};
type Status={sourceComplete:boolean;expectedTables:number;visibleTables:number;missingOrInvisibleTables:string[];foreignKeys:number;checkedAt:string;scope:string;catalog:Script[];metadata:{fullMetadataVisible:number;paymentIntegrity:number|null;payrollAccrual:number|null;snapshotLinks:number|null}};
const API=getApiBaseUrl();
export function DatabaseScriptPanel({allowed}:{allowed:boolean}){
 const [status,setStatus]=useState<Status|null>(null);const [error,setError]=useState('');const [busy,setBusy]=useState(false);
 const load=async()=>{setBusy(true);setError('');try{const response=await authenticatedFetch(`${API}/api/database/status`);const data=await response.json();if(!response.ok)throw Error(data.message||'No se pudo inspeccionar SQL Server.');setStatus(data);}catch(e){setStatus(null);setError(e instanceof Error?e.message:String(e));}finally{setBusy(false);}};
 useEffect(()=>{if(allowed)void load();},[allowed]);
 const download=async()=>{setBusy(true);setError('');try{const response=await authenticatedFetch(`${API}/api/database/structure.sql`);if(!response.ok){const data=await response.json();throw Error(data.message||'No se pudo generar el script.');}const url=URL.createObjectURL(await response.blob());const link=document.createElement('a');link.href=url;link.download='Instalaciones_Raquel_estructura_nueva.sql';link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}catch(e){setError(e instanceof Error?e.message:String(e));}finally{setBusy(false);}};
 if(!allowed)return <p className="rounded-xl border p-4 text-sm">La inspección SQL y la descarga del script completo requieren superadministración.</p>;
 return <><OperationalControlPanel/><section className="space-y-4 rounded-2xl border border-slate-200 bg-white p-5 dark:border-white/10 dark:bg-slate-900">
  <div className="flex flex-wrap items-center justify-between gap-3"><div><h2 className="text-lg font-extrabold">SQL Server: scripts y cobertura</h2><p className="text-xs text-slate-500">Inspección de solo lectura. Descargar no ejecuta ningún script.</p></div><div className="flex gap-2"><Button type="button" variant="secondary" disabled={busy} onClick={()=>void load()}>Verificar SQL</Button><Button type="button" disabled={busy} onClick={()=>void download()}>Descargar estructura SQL</Button></div></div>
  <div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900 dark:border-amber-800 dark:bg-amber-950/30 dark:text-amber-200">El paquete descargado es para una base nueva y se bloquea si la base ya existe. Para actualizar tu instalación se revisan únicamente las migraciones pendientes con respaldo. No incluye reconstrucción, usuarios de ejemplo, importaciones operativas ni cambios de contraseña.</div>
  {error&&<p role="alert" className="text-sm text-rose-700 dark:text-rose-300">Consulta no confirmada: {error}</p>}
  {busy&&<p className="text-xs text-slate-500">Procesando…</p>}
  {status&&<><div className="grid gap-3 text-sm sm:grid-cols-3"><div><strong>Archivos del catálogo</strong><p>{status.sourceComplete?'Todos presentes':'Hay archivos faltantes'}</p></div><div><strong>Tablas declaradas</strong><p>{status.expectedTables} esperadas · {status.visibleTables} visibles</p></div><div><strong>Relaciones activas</strong><p>{status.foreignKeys} claves foráneas</p></div></div>
   <div className="flex flex-wrap gap-2">{[['Pagos 30',status.metadata.paymentIntegrity],['Nómina 31',status.metadata.payrollAccrual],['Enlaces 32',status.metadata.snapshotLinks]].map(([label,value])=><StatusPill key={String(label)} tone={value?'ok':'warn'}>{label}: {value?'marcador presente':'sin confirmar'}</StatusPill>)}</div>
   {status.missingOrInvisibleTables.length>0&&<p className="text-xs text-amber-700">Tablas ausentes o no visibles para esta conexión: {status.missingOrInvisibleTables.join(', ')}.</p>}
   <p className="text-xs text-slate-500">{status.scope} Consulta: {new Date(status.checkedAt).toLocaleString('es-NI')}. {status.metadata.fullMetadataVisible? 'Metadatos visibles con permiso de definición.':'La visibilidad de metadatos está limitada por los permisos de la conexión.'}</p>
   <div className="overflow-x-auto"><table className="w-full text-left text-xs"><thead><tr><th className="p-2">Orden de estructura</th><th>Archivo</th><th>Uso</th><th>Archivo presente</th></tr></thead><tbody>{status.catalog.map(script=><tr key={script.name} className="border-t border-slate-100 dark:border-white/10"><td className="p-2">{script.order??'Separado'}</td><td className="font-mono">{script.name}</td><td>{script.category.replace(/_/g,' ')}</td><td>{script.exists?'Sí':'Falta'}</td></tr>)}</tbody></table></div>
  </>}
 </section></>;
}

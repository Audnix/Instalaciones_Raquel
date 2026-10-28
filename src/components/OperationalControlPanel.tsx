import {useCallback,useEffect,useState} from 'react';
import {authenticatedFetch,parseApiResponse} from '../auth/apiSession';
import {getApiBaseUrl} from '../lib/apiBase';
import {Button} from './Button';
type Report={snapshotAvailable:boolean;checkedAt:string;scope:string;issues:{module:string;id:string;message:string}[];collections:Record<string,number>;staleSessions:{account:string;sessionDate:string}[];payroll:{unverifiedPayrolls:number}};
export function OperationalControlPanel(){
 const [report,setReport]=useState<Report|null>(null),[error,setError]=useState(''),[busy,setBusy]=useState(false);
 const load=useCallback(async()=>{setBusy(true);setError('');try{setReport(await parseApiResponse<Report>(await authenticatedFetch(getApiBaseUrl()+'/api/database/operations')));}catch(e){setReport(null);setError(e instanceof Error?e.message:String(e));}finally{setBusy(false);}},[]);
 useEffect(()=>{void load();},[load]);
 return <section className="mb-4 space-y-3 rounded-2xl border bg-white p-5 dark:bg-slate-900">
  <div className="flex justify-between gap-3"><div><h2 className="text-lg font-extrabold">Control general de operaciones</h2><p className="text-xs text-slate-500">Comprobación automática al abrir esta sección. Solo consulta; conserva los datos históricos.</p></div><Button type="button" disabled={busy} onClick={()=>void load()}>{busy?'Revisando…':'Revisar operaciones'}</Button></div>
  {error&&<p role="alert" className="text-rose-700">Revisión no confirmada: {error}</p>}
  {report&&<>
   <p>{report.snapshotAvailable?`${Object.keys(report.collections).length} colecciones revisadas · ${report.issues.length} hallazgos del estado guardado`:'No hay un estado global disponible para verificar.'}</p>
   {report.staleSessions.map(session=><p key={session.account} className="text-amber-800">{session.account}: sesión del {session.sessionDate} pendiente de arqueo y cierre.</p>)}
   <p>Planillas con acumulado distinto de sus pagos confirmados: {report.payroll.unverifiedPayrolls}. Se revisan con comprobantes.</p>
   <div className="flex flex-wrap gap-2 text-xs">{Object.entries(report.collections).map(([key,value])=><span key={key} className="rounded border px-2 py-1">{key}: {value}</span>)}</div>
   {report.issues.length>0&&<div className="max-h-96 overflow-auto"><table className="w-full text-left text-xs"><thead><tr><th>Módulo</th><th>Registro</th><th>Revisión necesaria</th></tr></thead><tbody>{report.issues.slice(0,100).map((issue,index)=><tr key={index} className="border-t"><td className="p-2">{issue.module}</td><td>{issue.id}</td><td>{issue.message}</td></tr>)}</tbody></table>{report.issues.length>100&&<p>Se muestran los primeros 100 de {report.issues.length} hallazgos.</p>}</div>}
   <p className="text-xs text-slate-500">{report.scope} {new Date(report.checkedAt).toLocaleString('es-NI')}</p>
  </>}
 </section>;
}

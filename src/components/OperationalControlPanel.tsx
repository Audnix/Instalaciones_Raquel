import {Link} from 'react-router-dom';
import {useCallback,useEffect,useState} from 'react';
import {authenticatedFetch,parseApiResponse} from '../auth/apiSession';
import {getApiBaseUrl} from '../lib/apiBase';
import {Button} from './Button';
type Report={snapshotAvailable:boolean;checkedAt:string;scope:string;issues:{module:string;id:string;message:string}[];collections:Record<string,number>;staleSessions:{account:string;sessionDate:string}[];payroll:{unverifiedPayrolls:number;confirmedTestPayrolls?:number;discrepancies?:{id:string;period:string;status:string;confirmedCount:number;testDataConfirmed?:boolean|number;confirmedCashMoves?:number;recordedMatchesLinkedCash?:number;reason:string}[]}};
export function OperationalControlPanel(){
 const [report,setReport]=useState<Report|null>(null),[error,setError]=useState(''),[busy,setBusy]=useState(false);
 const load=useCallback(async()=>{setBusy(true);setReport(null);setError('');try{setReport(await parseApiResponse<Report>(await authenticatedFetch(getApiBaseUrl()+'/api/database/operations')));}catch(e){setReport(null);setError(e instanceof Error?e.message:String(e));}finally{setBusy(false);}},[]);
 useEffect(()=>{void load();},[load]);
 return <section className="mb-4 space-y-3 rounded-2xl border bg-white p-5 dark:bg-slate-900">
  <div className="flex justify-between gap-3"><div><h2 className="text-lg font-extrabold">Control general de operaciones</h2><p className="text-xs text-slate-500">Comprobación automática al abrir esta sección. Solo consulta; conserva los datos históricos.</p></div><Button type="button" disabled={busy} onClick={()=>void load()}>{busy?'Revisando…':'Revisar operaciones'}</Button></div>
  {error&&<p role="alert" className="text-rose-700">Revisión no confirmada: {error}</p>}
  {busy&&<p role="status" className="text-sm text-slate-500">Consultando el estado actual de las operaciones…</p>}
  {report&&<>
   <p>{report.snapshotAvailable?`${Object.keys(report.collections).length} colecciones revisadas · ${report.issues.length} hallazgos del estado guardado`:'No hay un estado global disponible para verificar.'}</p>
   {report.staleSessions.map(session=><p key={session.account} className="text-amber-800">{session.account}: sesión del {session.sessionDate} pendiente de arqueo y cierre. <Link className="underline" to={session.account==='banco'?'/bancos':'/caja'}>Revisar sesión</Link></p>)}
   <p>Planillas con diferencias históricas: {report.payroll.unverifiedPayrolls}. Identificadas como datos de prueba: {report.payroll.confirmedTestPayrolls ?? 0}. Las diferencias se conservan para revisión.</p>
   {!!report.payroll.discrepancies?.length&&<div className="overflow-x-auto"><table className="w-full text-left text-xs"><thead><tr><th className="p-2">Planilla</th><th>Estado</th><th>Revisión necesaria</th><th>Evidencia en banco/caja</th><th>Acción</th></tr></thead><tbody>{report.payroll.discrepancies.map(run=><tr key={run.id} className="border-t"><td className="p-2">{run.period}{Boolean(run.testDataConfirmed)&&<span className="ml-2 rounded bg-amber-100 px-2 py-0.5 font-bold text-amber-900">Prueba confirmada</span>}</td><td>{run.status}</td><td>{run.reason==='sin_pagos_registrados'?'Acumulado en cabecera sin pagos confirmados registrados':'Acumulado distinto de los pagos confirmados'}</td><td>{run.recordedMatchesLinkedCash===1?'Las salidas vinculadas coinciden con el acumulado; falta conciliar el detalle de pagos':run.confirmedCashMoves===0?'Sin salidas confirmadas vinculadas; requiere comprobar si hubo pago externo':'Revisar las salidas vinculadas y sus comprobantes'}</td><td><Link className="text-brand-700 underline dark:text-cyan-300" to={`/nomina?runId=${encodeURIComponent(run.id)}`}>Revisar planilla</Link></td></tr>)}</tbody></table><p className="mt-2 text-xs text-slate-500">Contraste los comprobantes antes de registrar otro pago o corregir un acumulado.</p></div>}
   <div className="flex flex-wrap gap-2 text-xs">{Object.entries(report.collections).map(([key,value])=><span key={key} className="rounded border px-2 py-1">{key}: {value}</span>)}</div>
   {report.issues.length>0&&<div className="max-h-96 overflow-auto"><table className="w-full text-left text-xs"><thead><tr><th>Módulo</th><th>Registro</th><th>Revisión necesaria</th></tr></thead><tbody>{report.issues.slice(0,100).map((issue,index)=><tr key={index} className="border-t"><td className="p-2">{issue.module}</td><td>{issue.id}</td><td>{issue.message}</td></tr>)}</tbody></table>{report.issues.length>100&&<p>Se muestran los primeros 100 de {report.issues.length} hallazgos.</p>}</div>}
   <p className="text-xs text-slate-500">{report.scope} {new Date(report.checkedAt).toLocaleString('es-NI')}</p>
  </>}
 </section>;
}

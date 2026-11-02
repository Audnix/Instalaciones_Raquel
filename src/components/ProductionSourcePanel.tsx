import {useEffect,useState} from 'react';
import {Link,useSearchParams} from 'react-router-dom';
import {authenticatedFetch,parseApiResponse} from '../auth/apiSession';
import {getApiBaseUrl} from '../lib/apiBase';
import {productionDraft,type ProductionSource} from '../lib/productionDraft';
import type {ProductionOrder} from '../types/erp';
import {Button} from './Button';
import {inputClass} from './Ui';

export function ProductionSourcePanel({orders,onPrepare}:{orders:ProductionOrder[];onPrepare:(draft:NonNullable<ReturnType<typeof productionDraft>>)=>void}){
 const [params,setParams]=useSearchParams();const invoice=params.get('invoice')?.trim()??'';
 const [invoiceInput,setInvoiceInput]=useState('');
 const [source,setSource]=useState<ProductionSource|null>(null),[error,setError]=useState('');
 const [line,setLine]=useState(0),[attempt,setAttempt]=useState(0);
 const [loading,setLoading]=useState(false);
 useEffect(()=>{
  setSource(null);setError('');if(!invoice)return;
  const controller=new AbortController();setLoading(true);
  void authenticatedFetch(`${getApiBaseUrl()}/api/module-state/produccion/source?invoice=${encodeURIComponent(invoice)}`,{signal:controller.signal})
   .then(response=>parseApiResponse<ProductionSource>(response))
   .then(data=>{if(!controller.signal.aborted){setSource(data);setLine(data.lines[0]?.lineNumber??0);}})
   .catch(error=>{if(!controller.signal.aborted)setError(error instanceof Error?error.message:String(error));})
   .finally(()=>{if(!controller.signal.aborted)setLoading(false);});
  return ()=>controller.abort();
 },[invoice,attempt]);
 if(!invoice)return <form className="flex flex-wrap items-end gap-3 rounded-xl border border-slate-200 p-4 dark:border-white/10" onSubmit={event=>{
  event.preventDefault();if(!invoiceInput.trim())return;
  setParams(previous=>{const next=new URLSearchParams(previous);next.set('invoice',invoiceInput.trim());return next;});
 }}>
  <label className="text-sm font-semibold">Preparar desde factura<input className={inputClass} required maxLength={80} value={invoiceInput} placeholder="Número de factura" onChange={event=>setInvoiceInput(event.target.value)}/></label>
  <Button type="submit" variant="secondary">Consultar factura</Button>
 </form>;
 const draft=source?productionDraft(source,line):null;
 const existing=draft?orders.find(order=>order.code.trim().toLowerCase()===draft.code.toLowerCase()):null;
 return <section className="space-y-3 rounded-xl border border-cyan-200 bg-cyan-50 p-4 dark:border-cyan-900 dark:bg-cyan-950/30">
  <h3 className="font-bold">Preparar orden desde factura {invoice}</h3>
  <button type="button" className="text-xs underline" onClick={()=>setParams(previous=>{const next=new URLSearchParams(previous);next.delete('invoice');return next;})}>Cambiar factura</button>
  {loading&&<p role="status">Consultando detalle…</p>}
  {error&&<p role="alert" className="text-sm text-rose-700 dark:text-rose-300">{error} <button type="button" className="underline" onClick={()=>setAttempt(value=>value+1)}>Reintentar</button></p>}
  {source&&<><p className="text-sm">Cliente: {source.clientName}</p>
   <label className="block text-sm">Trabajo a preparar<select aria-label="Trabajo de la factura" className={inputClass} value={line} onChange={event=>setLine(Number(event.target.value))}>
    {source.lines.map(row=><option key={row.lineNumber} value={row.lineNumber}>{row.product} · cantidad {row.quantity}</option>)}
   </select></label>
   {existing?<p className="text-sm">Ya existe la orden sugerida. <Link className="underline" to={`/produccion#production-${encodeURIComponent(existing.code)}`}>Revisar orden {existing.code}</Link></p>:<Button type="button" disabled={!draft||loading} onClick={()=>{if(draft)onPrepare(draft);}}>Completar formulario de orden</Button>}
   <p className="text-xs text-slate-500 dark:text-slate-400">Revisa las medidas, la unidad y el código antes de crear la orden. El formulario permite preparar un trabajo de la factura cada vez.</p>
  </>}
 </section>;
}

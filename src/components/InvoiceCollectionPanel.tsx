import {useEffect,useState} from 'react';
import {useSearchParams} from 'react-router-dom';
import {useAuth} from '../auth/AuthContext';
import {authenticatedFetch,parseApiResponse} from '../auth/apiSession';
import {getApiBaseUrl} from '../lib/apiBase';
import {Button} from './Button';
import {Money} from './Ui';

export type InvoiceBalance={saleNumber:string;clientName:string;total:number;confirmedPaid:number;pending:number};
export function InvoiceCollectionPanel({enabled,canPrepare,refresh,onPrepare}:{enabled:boolean;canPrepare:boolean;refresh:number;onPrepare:(balance:InvoiceBalance)=>void}){
 const [params]=useSearchParams();
 const invoice=params.get('invoice')?.trim()??'';
 const {user}=useAuth();
 const [balance,setBalance]=useState<InvoiceBalance|null>(null);
 const [error,setError]=useState('');
 const [loading,setLoading]=useState(false);
 const [attempt,setAttempt]=useState(0);
 useEffect(()=>{
  setBalance(null);setError('');
  if(!enabled||!invoice)return;
  const controller=new AbortController();setLoading(true);
  void authenticatedFetch(`${getApiBaseUrl()}/api/cash/sale-balance?reference=${encodeURIComponent(invoice)}`,{signal:controller.signal})
   .then(response=>parseApiResponse<InvoiceBalance>(response))
   .then(data=>{if(!controller.signal.aborted)setBalance(data);})
   .catch(error=>{if(!controller.signal.aborted)setError(error instanceof Error?error.message:String(error));})
   .finally(()=>{if(!controller.signal.aborted)setLoading(false);});
  return ()=>controller.abort();
 },[enabled,invoice,refresh,user?.id,attempt]);
 if(!invoice||!enabled)return null;
 return <section className="space-y-2 rounded-xl border border-cyan-200 bg-cyan-50 p-4 dark:border-cyan-900 dark:bg-cyan-950/30">
  <h3 className="font-bold">Cobro de factura {invoice}</h3>
  <button type="button" className="text-xs font-semibold underline" disabled={loading} onClick={()=>setAttempt(value=>value+1)}>Actualizar saldo</button>
  {loading&&<p role="status" className="text-sm">Consultando saldo pendiente…</p>}
  {error&&<p role="alert" className="text-sm text-rose-700 dark:text-rose-300">{error}</p>}
  {balance&&<><p className="text-sm">{balance.clientName} · Pendiente: <Money value={balance.pending}/></p>
   {balance.pending<=0.005?<p className="text-sm">La factura ya no tiene saldo pendiente.</p>:<>
    <Button type="button" disabled={!canPrepare||loading} onClick={()=>onPrepare(balance)}>Preparar cobro</Button>
    <p className="text-xs text-slate-500 dark:text-slate-400">{canPrepare?'Completa el formulario con el pendiente actual. Puedes reducir el importe para registrar un abono.':'Abre una sesión del día y resuelve los avisos de la cuenta para preparar el cobro.'} El movimiento se registra al confirmar el formulario.</p>
   </>}
  </>}
 </section>;
}

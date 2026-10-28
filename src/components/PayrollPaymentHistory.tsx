import {Money} from './Ui';
export type PayrollPaidAllocation={employeeId:string;amount:number;ordinarySalary?:number|null;bonusesAmount?:number|null;inssLaboral?:number|null;incomeTax?:number|null;otherDeductions?:number|null;netPay?:number|null};
export type PayrollHistoryPayment={id:string;amount:number;employeeId?:string|null;paymentDate:string;confirmedAt?:string;paymentMethod:string;paymentReference:string;cashMoveId?:string|null;confirmedByName?:string|null;period?:string;calculationVersion?:number;allocations?:PayrollPaidAllocation[]};
export function PayrollPaymentHistory({payments,items,period,ready}:{payments:PayrollHistoryPayment[];items:Array<{employeeId:string;employeeName:string}>;period:string;ready:boolean}){
 const money=(amount:number|null|undefined)=>amount==null?<span className="text-slate-400">Sin detalle verificable</span>:<Money value={Number(amount)} />;
 return <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-white/10 dark:bg-slate-900">
  <div className="border-b border-slate-100 p-4 dark:border-white/10"><p className="text-[10px] font-bold uppercase tracking-widest text-brand-600">Historial</p><h3 className="text-lg font-extrabold">Pagos de nómina</h3><p className="mt-1 text-[11px] text-slate-500">El neto del cálculo es la obligación del período; el importe pagado es solo este abono. Los datos de cálculo se muestran cuando coinciden las versiones.</p></div>
  <div className="overflow-x-auto"><table className="w-full min-w-[1150px] text-left text-xs"><thead className="bg-slate-50 text-[10px] uppercase text-slate-500 dark:bg-slate-950"><tr>{['Fecha','Trabajador','Período','Base del período','Bonos','INSS laboral','IR','Otras ded.','Neto del cálculo','Importe pagado','Método','Referencia / movimiento'].map(label=><th key={label} className="p-3">{label}</th>)}</tr></thead>
   <tbody className="divide-y divide-slate-100 dark:divide-white/10">
   {!ready&&<tr><td colSpan={12} className="p-4 text-slate-500">Historial pendiente de verificar.</td></tr>}
   {ready&&payments.length===0&&<tr><td colSpan={12} className="p-4 text-slate-500">Sin pagos confirmados en esta planilla.</td></tr>}
   {ready&&payments.flatMap(payment=>(payment.allocations?.length?payment.allocations:[{employeeId:payment.employeeId??'',amount:payment.amount}]).map((allocation,index)=><tr key={payment.id+'-'+index}>
    <td className="p-3 whitespace-nowrap">{new Date(payment.paymentDate).toLocaleDateString('es-NI',{timeZone:'UTC'})}{payment.confirmedAt&&<span className="block text-[10px] text-slate-400">{new Date(payment.confirmedAt).toLocaleTimeString('es-NI',{timeZone:'America/Managua'})}</span>}</td>
    <td className="p-3 font-semibold">{items.find(item=>item.employeeId===allocation.employeeId)?.employeeName??(allocation.employeeId||'Histórico sin distribución')}<span className="block text-[10px] text-slate-400">{payment.confirmedByName||''}</span></td>
    <td className="p-3">{payment.period||period}<span className="block text-[10px] text-slate-400">Versión {payment.calculationVersion??'no disponible'}</span></td>
    <td className="p-3">{money(allocation.ordinarySalary)}</td><td className="p-3">{money(allocation.bonusesAmount)}</td>
    <td className="p-3">{money(allocation.inssLaboral)}</td><td className="p-3">{money(allocation.incomeTax)}</td><td className="p-3">{money(allocation.otherDeductions)}</td><td className="p-3">{money(allocation.netPay)}</td>
    <td className="p-3 font-extrabold text-emerald-700 dark:text-emerald-300"><Money value={Number(allocation.amount)} /></td><td className="p-3">{payment.paymentMethod.replace(/_/g,' ')}</td><td className="p-3 font-mono text-[10px]">{payment.paymentReference}<span className="block text-slate-400">{payment.cashMoveId||'Sin movimiento vinculado'}</span></td>
   </tr>))}
   </tbody></table></div>
 </section>;
}

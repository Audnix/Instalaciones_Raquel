import { getApiBaseUrl } from '../lib/apiBase';
import {useRef,useState,type FormEvent} from 'react';
import {authenticatedFetch} from '../auth/apiSession';
import {Button} from './Button';
import {Field,inputClass} from './Ui';
const newWorkerCode=()=> 'EMP-'+(globalThis.crypto?.randomUUID?.()??(Date.now().toString(36)+'-'+Math.random().toString(36).slice(2,10)));
const API=getApiBaseUrl();
export function PayrollStaffRegistration({allowed,onCreated}:{allowed:boolean;onCreated:(employee:{id:string;name:string;position:string;area:string})=>void}){
 const [expanded,setExpanded]=useState(false);const [busy,setBusy]=useState(false);const [message,setMessage]=useState('');
 const pending=useRef(false);const code=useRef(newWorkerCode());
 const submit=async(event:FormEvent<HTMLFormElement>)=>{event.preventDefault();if(!allowed||pending.current)return;const form=event.currentTarget;const data=new FormData(form);pending.current=true;setBusy(true);setMessage('');
  try{const response=await authenticatedFetch(`${API}/api/hr/employees`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({code:code.current,name:String(data.get('name')).trim(),position:String(data.get('position')).trim(),area:String(data.get('area')).trim(),salary:Number(data.get('salary')),hireDate:String(data.get('hireDate'))})});const result=await response.json();if(!response.ok)throw Error(result.message||'No se pudo registrar al trabajador.');if(!result.employee)throw Error('Respuesta incierta: conserva el código y verifica el directorio antes de repetir.');onCreated({id:result.employee.id||result.employee.EmployeeId||code.current,name:String(data.get('name')).trim(),position:String(data.get('position')).trim(),area:String(data.get('area')).trim()});code.current=newWorkerCode();form.reset();setMessage('Trabajador registrado en Talento Humano. Aún debes incluirlo en la planilla y calcular su período antes de pagar.');}
  catch(error){setMessage((error instanceof Error?error.message:String(error))+' Código de esta solicitud: '+code.current);}finally{pending.current=false;setBusy(false);}
 };
 if(!allowed)return null;
 return <div className="my-3 rounded-xl border border-slate-200 p-3 dark:border-white/10"><Button type="button" variant="secondary" disabled={busy} onClick={()=>setExpanded(value=>!value)}>{expanded?'Ocultar alta de personal':'Agregar trabajador nuevo'}</Button>
 {expanded&&<form onSubmit={submit} className="mt-3 grid gap-3 text-xs sm:grid-cols-2"><fieldset disabled={busy} className="contents">
 <Field label="Nombre completo"><input name="name" required maxLength={240} className={inputClass}/></Field><Field label="Cargo / puesto"><input name="position" required maxLength={200} className={inputClass}/></Field>
 <Field label="Área"><input name="area" required maxLength={120} className={inputClass}/></Field><Field label="Salario mensual (C$)"><input name="salary" type="number" required min="0.01" step="0.01" className={inputClass}/></Field>
 <Field label="Fecha real de ingreso"><input name="hireDate" type="date" required className={inputClass}/></Field><div className="flex items-end"><Button disabled={busy} className="w-full">{busy?'Guardando…':'Registrar trabajador'}</Button></div>
 <p className="text-[11px] text-slate-500 sm:col-span-2">Registrar personal no confirma un pago ni concede una cuenta de acceso. La API valida el salario y la identidad de quien realiza el alta.</p></fieldset></form>}
 {message&&<p role="status" className="mt-2 text-xs">{message}</p>}
 </div>;
}

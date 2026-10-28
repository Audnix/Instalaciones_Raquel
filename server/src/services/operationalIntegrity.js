const collections=['products','lots','kardex','sales','proformas','purchases','accounting','finance','projections','production','parties','employees','payrollRuns','albums','projects','cash','users','audit','promotions'];
export const requiredStateCollections=collections;
const positive=v=>typeof v==='number'&&Number.isFinite(v)&&v>0;
const nonnegative=v=>typeof v==='number'&&Number.isFinite(v)&&v>=0;
const date=v=>typeof v==='string'&&v.length>=10&&Number.isFinite(Date.parse(v));
export function auditOperationalState(state,previous=null){
 const issues=[];const add=(module,id,message)=>issues.push({module,id:String(id??''),message});
 for(const key of collections){
  if(state[key]===undefined&&!Array.isArray(previous?.[key]))continue;
  if(!Array.isArray(state[key])){add(key,'','Se requiere la colección completa; no se acepta omitirla.');continue;}
  const old=new Map((previous?.[key]??[]).map(row=>[row.id,row]));const ids=new Set();
  for(const row of state[key]){
   if(!row||typeof row!=='object'||typeof row.id!=='string'||!row.id.trim()){add(key,'','Registro sin identificador válido.');continue;}
   if(ids.has(row.id))add(key,row.id,'Identificador duplicado.');ids.add(row.id);
   if(previous&&JSON.stringify(old.get(row.id))===JSON.stringify(row))continue;
   const number=(field,valid=nonnegative)=>{if(!valid(row[field]))add(key,row.id,`${field}: valor numérico fuera de rango.`);};
   if(key==='products'){number('unitPrice');number('minQuantity');if(!row.code?.trim()||!row.name?.trim())add(key,row.id,'Código y nombre son obligatorios.');}
   if(key==='lots'){number('quantity');number('unitCost');if(!date(row.entryDate))add(key,row.id,'Fecha de entrada inválida.');}
   if(key==='kardex'){number('quantity',positive);number('unitCost');if(!['entrada','salida'].includes(row.type))add(key,row.id,'Tipo de movimiento inválido.');}
   if(['lots','kardex'].includes(key)&&!(state.products??[]).some(p=>p.id===row.productId))add(key,row.id,'Producto inexistente.');
   if(['sales','proformas','purchases'].includes(key)){
    if(!Array.isArray(row.items)||!row.items.length){add(key,row.id,'El documento requiere al menos un producto.');continue;}
    for(const item of row.items){if(!positive(item.quantity)||!nonnegative(item.unitPrice))add(key,row.id,'Cantidad o precio de detalle inválido.');if(!(state.products??[]).some(p=>p.id===item.productId))add(key,row.id,'Detalle vinculado a un producto inexistente.');}
    number('total');
    const subtotal=row.items.reduce((sum,item)=>sum+item.quantity*item.unitPrice,0);
    if(key==='purchases'){
      if(Math.abs(subtotal-row.total)>0.02)add(key,row.id,'Total de compra distinto de sus productos.');
      if(!['ordered','received'].includes(row.status)||!date(row.purchaseDate))add(key,row.id,'Estado o fecha de compra inválidos.');
      continue;
    }
    number('subtotal');number('taxAmount');
    const discount=row.discountAmount??0;
    if(!nonnegative(discount)||discount>row.subtotal||Math.abs(subtotal-row.subtotal)>0.02||Math.abs(row.subtotal-discount+row.taxAmount-row.total)>0.02)add(key,row.id,'Los importes no coinciden con el detalle, descuento e impuesto.');
   }
   if(key==='accounting'){number('debit');number('credit');if(Math.abs(row.debit-row.credit)>0.005)add(key,row.id,'El asiento debe estar balanceado antes de guardarse.');if(!date(row.entryDate))add(key,row.id,'Fecha contable inválida.');}
   if(key==='finance'){number('amount',positive);if(!['ingreso','egreso'].includes(row.type))add(key,row.id,'Tipo financiero inválido.');if(!date(row.date))add(key,row.id,'Fecha financiera inválida.');}
   if(key==='production'){number('qty',positive);if(!['backlog','corte','ensamble','instalacion','entregado'].includes(row.stage))add(key,row.id,'Etapa de producción inválida.');}
   if(key==='projects'){if(!row.name?.trim())add(key,row.id,'Nombre de proyecto obligatorio.');number('amount');number('progress');if(row.progress>100)add(key,row.id,'El avance no puede superar 100%.');}
   if(key==='parties'&&(!row.name?.trim()||!['cliente','proveedor'].includes(row.type)))add(key,row.id,'Nombre y tipo de tercero son obligatorios.');
  }
 }
 return issues;
}
export function validateOperationalChange(state,previous){
 const issues=auditOperationalState(state,previous);
 if(previous&&Array.isArray(previous.lots)&&Array.isArray(state.lots)&&Array.isArray(state.kardex)){
  const sum=rows=>rows.reduce((map,row)=>map.set(row.productId,(map.get(row.productId)??0)+row.quantity),new Map());
  const before=sum(previous.lots),after=sum(state.lots),oldMoves=new Map((previous.kardex??[]).map(row=>[row.id,row]));
  const effects=new Map();
  for(const row of state.kardex){
   const old=oldMoves.get(row.id);
   if(old&&JSON.stringify(old)!==JSON.stringify(row))issues.push({module:'kardex',id:row.id,message:'El historial de inventario no puede reescribirse; registra un movimiento de ajuste.'});
   if(!old)effects.set(row.productId,(effects.get(row.productId)??0)+(row.type==='entrada'?row.quantity:-row.quantity));
  }
  for(const id of new Set([...before.keys(),...after.keys(),...effects.keys()])){
   if(Math.abs((after.get(id)??0)-(before.get(id)??0)-(effects.get(id)??0))>0.00001)issues.push({module:'inventario',id,message:'El cambio de existencias no coincide con sus movimientos de kardex.'});
  }
  if((previous.kardex??[]).some(row=>!state.kardex.some(item=>item.id===row.id)))issues.push({module:'kardex',id:'',message:'No se puede eliminar el historial de inventario.'});
 }
 if(issues.length)throw Object.assign(new Error(`No se guardó: ${issues[0].module} ${issues[0].id}: ${issues[0].message}`),{status:422,code:'OPERATIONAL_INTEGRITY',issues});
}

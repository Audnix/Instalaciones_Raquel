import test from 'node:test';
import assert from 'node:assert/strict';
import {modulePolicies,authorizeModule,projectModuleState,mergeModuleState} from '../src/services/moduleState.js';
import {requiredStateCollections,validateOperationalChange} from '../src/services/operationalIntegrity.js';
const user={name:'Prueba',hierarchy:'estandar'};
const state=()=>Object.fromEntries(requiredStateCollections.map(key=>[key,[]]));
function auth(module,area,method='GET',hierarchy='estandar'){
 const out={status:200,next:false};authorizeModule({params:{module},method,user:{...user,hierarchy,areas:[area]}},{status(n){out.status=n;return this;},json(){return this;}},()=>out.next=true);return out;
}
test('todos los modulos adicionales autorizan su area y deniegan otra',()=>{
 for(const [module,area]of [['proyectos','proyectos'],['contabilidad','contabilidad'],['costos','finanzas'],['ventas','ventas'],['clientes','ventas'],['mercadotecnia','mercadotecnia'],['compras','compras'],['reportes','contabilidad']]){
  assert.equal(auth(module,area).next,true,module);assert.equal(auth(module,'rrhh').status,403,module);
  assert.equal(auth(module,area,'PUT').status,modulePolicies[module].write.length?200:403,module);
  assert.equal(auth(module,area,'PUT','invitado').status,403,module);
 }
 assert.equal(auth('reportes','rrhh','GET','administrador').next,true);
 assert.equal(auth('__proto__','ventas').status,403);
});
test('reportes y costos no exponen nomina ni usuarios y rechazan escrituras',()=>{
 const previous=state();previous.employees=[{id:'privado'}];previous.users=[{id:'usuario'}];
 for(const module of ['reportes','costos']){const read=projectModuleState(previous,module);assert.equal('employees'in read,false);assert.equal('users'in read,false);assert.throws(()=>mergeModuleState({},previous,module,user),e=>e.status===422);}
});
test('clientes conserva proveedores ocultos y no puede alterarlos',()=>{
 const previous=state();previous.parties=[{id:'s',name:'Proveedor',type:'proveedor'}];
 const incoming={parties:[{id:'c',name:'Cliente',type:'cliente'}]};
 const next=mergeModuleState(incoming,previous,'clientes',user);assert.deepEqual(next.parties[0],previous.parties[0]);assert.equal(projectModuleState(next,'clientes').parties.length,1);validateOperationalChange(next,previous);
 assert.throws(()=>mergeModuleState({parties:[{id:'s',name:'Otro',type:'cliente'}]},previous,'clientes',user),e=>e.status===422);
});
function trade(sales){
 const previous=state();previous.products=[{id:'p',code:'P',name:'Perfil',minQuantity:0,unitPrice:100}];
 previous.accounting=[{id:'privado',referenceType:'payroll',debit:100,credit:100}];
 const collection=sales?'sales':'purchases',module=sales?'ventas':'compras';
 const doc={id:'d',items:[{productId:'p',quantity:2,unitPrice:sales?100:10}],total:sales?230:20,status:sales?'completed':'received',...(sales?{saleDate:'2026-10-27',clientName:'Cliente',subtotal:200,taxAmount:30}:{purchaseDate:'2026-10-27'})};
 previous.lots=sales?[{id:'l',productId:'p',quantity:5,unitCost:10,entryDate:'2026-10-20',warehouseId:'Bodega'}]:[];
 const incoming={lots:sales?[{...previous.lots[0],quantity:3}]:[{id:'n',productId:'p',quantity:2,unitCost:10,entryDate:'2026-10-27',warehouseId:'Bodega'}],kardex:[{id:'k',productId:'p',quantity:2,type:sales?'salida':'entrada',unitCost:10}],accounting:[{id:'a',referenceId:'d',referenceType:sales?'sale':'purchase',entryDate:'2026-10-27',debit:doc.total,credit:doc.total,debitAccount:sales?'Cuentas por cobrar':'Inventario',creditAccount:sales?'Ventas':'Cuentas por pagar'}],[collection]:[doc],...(sales?{proformas:[]}:{})};
 return {previous,incoming,module};
}
test('venta y compra guardan documento, kardex y asiento sin sobrescribir nomina',()=>{
 for(const sales of [true,false]){const {previous,incoming,module}=trade(sales);const next=mergeModuleState(incoming,previous,module,user);validateOperationalChange(next,previous);assert.deepEqual(next.accounting.find(row=>row.id==='privado'),previous.accounting[0]);assert.equal(projectModuleState(next,module).accounting.some(row=>row.id==='privado'),false);}
});
test('no se aceptan ventas ni compras con kardex, costos o asientos falsos',()=>{
 for(const sales of [true,false])for(const kind of ['quantity','cost','accounting']){
  const {previous,incoming,module}=trade(sales);
  if(kind==='quantity')incoming.kardex[0].quantity=99;
  if(kind==='cost'){if(sales)incoming.kardex[0].unitCost=0;else incoming.lots[0].unitCost=0;}
  if(kind==='accounting')incoming.accounting[0].referenceType='manual';
  assert.throws(()=>mergeModuleState(incoming,previous,module,user),e=>e.status===422,module+kind);
 }
});
test('proyectos y albumes conservan datos de otras areas y se validan antes de guardar',()=>{
 const previous=state();previous.products=[{id:'p',code:'P',name:'Perfil',unitPrice:1,minQuantity:0}];
 const next=mergeModuleState({projects:[{id:'pr',code:'PR',name:'Obra',client:'Cliente',amount:100,progress:10}]},previous,'proyectos',user);validateOperationalChange(next,previous);
 assert.deepEqual(next.products,previous.products);
 assert.throws(()=>validateOperationalChange({...next,projects:[{...next.projects[0],progress:101}]},previous),e=>e.status===422);
 assert.throws(()=>mergeModuleState({albums:[{id:'al',title:'Mes',month:'2026-10',productIds:['no-existe']}]},previous,'mercadotecnia',user),e=>e.status===422);
});

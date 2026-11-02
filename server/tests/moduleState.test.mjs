import test from 'node:test';
import assert from 'node:assert/strict';
import {authorizeModule, projectModuleState, mergeModuleState} from '../src/services/moduleState.js';
import {saveStateSnapshot} from '../src/services/stateSnapshot.js';
import {requiredStateCollections, validateOperationalChange} from '../src/services/operationalIntegrity.js';
const user={name:'Operador',hierarchy:'estandar',areas:['produccion']};
function authorize(module,areas,hierarchy='estandar',method='GET',mustChangePassword=false){
 const out={status:200,next:false};
 authorizeModule({params:{module},method,user:{areas,hierarchy,mustChangePassword}}, {status(n){out.status=n;return this;},json(){return this;}},()=>out.next=true);
 return out;
}
const state=()=>({...Object.fromEntries(requiredStateCollections.map(key=>[key,[]])),users:[{id:'secret-user'}],employees:[{id:'secret-employee'}],cash:[{id:'cash-existing'}]});
test('cada area solo permite sus perfiles; invitados leen y no escriben',()=>{
 for(const [module,area] of [['produccion','produccion'],['inventario','inventario'],['finanzas','finanzas']]){
  assert.equal(authorize(module,[area]).next,true);
  assert.equal(authorize(module,['rrhh']).status,403);
  assert.equal(authorize(module,[area],'invitado','GET').next,true);
  assert.equal(authorize(module,[area],'invitado','PUT').status,403);
  assert.equal(authorize(module,[area],'estandar','PUT',true).status,403);
 }
 assert.equal(authorize('inventario',['produccion'],'estandar','PUT').next,true);
 assert.equal(authorize('finanzas',[],'superadmin','PUT').next,true);
 assert.equal(authorize('usuarios',['produccion']).status,403);
});
test('consulta por area no expone empleados, usuarios ni dinero de otras areas',()=>{
 const previous=state();previous.production=[{id:'ot'}];
 assert.deepEqual(Object.keys(projectModuleState(previous,'produccion')).sort(),['production','products']);
 for(const module of ['produccion','inventario','finanzas']){
  const projected=projectModuleState(previous,module);
  for(const key of ['users','employees','payrollRuns','cash'])assert.equal(key in projected,false);
 }
});
test('guardar produccion conserva otras areas y sella auditoria con actor del servidor',()=>{
 const previous=state();
 const production=[{id:'ot',code:'OT-1',product:'Ventana',client:'Prueba',qty:1,stage:'corte'}];
 const next=mergeModuleState({production},previous,'produccion',user);
 assert.deepEqual(next.users,previous.users);assert.deepEqual(next.cash,previous.cash);
 assert.equal(next.audit[0].userName,'Operador');assert.equal(next.audit[0].module,'produccion');
 validateOperationalChange(next,previous);
 assert.throws(()=>mergeModuleState({production,users:[]},previous,'produccion',user),e=>e.status===422);
});
test('inventario conserva kardex y exige correspondencia entre existencias y movimientos',()=>{
 const previous=state();previous.products=[{id:'p',code:'P',name:'Perfil',unitPrice:1,minQuantity:1}];
 const lots=[{id:'l',productId:'p',quantity:2,unitCost:10,entryDate:'2026-10-27'}];
 const kardex=[{id:'k',productId:'p',quantity:2,unitCost:10,type:'entrada',userName:'falso'}];
 const next=mergeModuleState({lots,kardex},previous,'inventario',user);
 assert.equal(next.kardex[0].userName,user.name);validateOperationalChange(next,previous);
 assert.throws(()=>validateOperationalChange({...next,lots:[]},previous),e=>e.status===422);
 assert.throws(()=>mergeModuleState({lots,kardex:[]},next,'inventario',user),e=>e.status===422);
});
test('finanzas no permite reescribir movimientos y valida proyecciones',()=>{
 const previous=state();previous.finance=[{id:'f',amount:10,type:'ingreso',date:'2026-10-27'}];
 assert.throws(()=>mergeModuleState({finance:[{...previous.finance[0],amount:20}],projections:[]},previous,'finanzas',user),e=>e.status===422);
 assert.throws(()=>mergeModuleState({finance:previous.finance,projections:[{id:'p',expectedSales:-1,expectedCosts:0}]},previous,'finanzas',user),e=>e.status===422);
});
test('fusion parcial ocurre bajo bloqueo y guarda el estado completo con revision comprobada',async()=>{
 const previous=state(),events=[];let stored;
 const rev=Buffer.from('0000000000000001','hex');
 const transaction={on(){},async begin(){events.push('begin');},async commit(){events.push('commit');},async rollback(){events.push('rollback');}};
 const request=()=>({input(key,valueType,value){if(key==='payload')stored=JSON.parse(value);return this;},async query(q){events.push(q.includes('UPDLOCK')?'lock':'read');return {recordset:[{Revision:rev,Payload:JSON.stringify(previous)}]};},async execute(){events.push('write');}});
 await saveStateSnapshot(null,JSON.stringify({production:[]}),'0x0000000000000001',{transaction,request,transform:(incoming,current)=>{events.push('merge');return mergeModuleState(incoming,current,'produccion',user);}});
 assert.deepEqual(events,['begin','lock','merge','write','read','commit']);assert.deepEqual(stored.cash,previous.cash);assert.deepEqual(stored.users,previous.users);
 events.length=0;
 await assert.rejects(saveStateSnapshot(null,'{}','0x0000000000000002',{transaction,request,transform(){throw Error('no debe llamarse');}}),e=>e.status===409);
 assert.deepEqual(events,['begin','lock','rollback']);
});

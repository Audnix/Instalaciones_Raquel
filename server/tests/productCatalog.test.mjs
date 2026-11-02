import test from 'node:test';
import assert from 'node:assert/strict';
import {authorizeModule,projectModuleState,mergeModuleState} from '../src/services/moduleState.js';
import {requiredStateCollections,validateOperationalChange} from '../src/services/operationalIntegrity.js';
const product={id:'p1',code:'GRAB-01-MARCO',name:'Marco',category:'Aluminio',unitPrice:700,minQuantity:2};
const state=()=>Object.fromEntries(requiredStateCollections.map(key=>[key,[]]));
const user={name:'Administrador',hierarchy:'administrador',areas:['ventas']};
function auth(hierarchy,areas,method){
 const result={status:200,allowed:false};
 authorizeModule({params:{module:'datos'},method,user:{hierarchy,areas}}, {status(n){result.status=n;return this;},json(){return this;}},()=>result.allowed=true);
 return result;
}
test('administracion y personal de inventario registran productos; otros perfiles no',()=>{
 assert.equal(auth('administrador',['ventas'],'PUT').allowed,true);
 assert.equal(auth('estandar',['inventario'],'PUT').allowed,true);
 assert.equal(auth('invitado',['inventario'],'PUT').status,403);
 assert.equal(auth('estandar',['gobierno'],'PUT').status,403);
 assert.equal(auth('estandar',['compras'],'PUT').status,403);
 assert.equal(auth('estandar',['ventas'],'GET').status,403);
 assert.equal(auth('estandar',['inventario'],'GET').allowed,true);
});
test('alta conserva otras areas, no crea stock y deja auditoria del servidor',()=>{
 const previous=state();previous.users=[{id:'u'}];previous.employees=[{id:'e'}];
 const next=mergeModuleState({products:[product]},previous,'datos',user);
 validateOperationalChange(next,previous);
 assert.deepEqual(next.products,[product]);assert.deepEqual(next.lots,[]);
 assert.deepEqual(next.users,previous.users);assert.deepEqual(next.employees,previous.employees);
 assert.equal(next.audit[0].userName,user.name);
 assert.deepEqual(Object.keys(projectModuleState(next,'datos')).sort(),['lots','products']);
});
test('rechaza duplicados, importes invalidos y cambios a productos existentes',()=>{
 const previous=state();previous.products=[product];
 for(const row of [{...product,id:'p2',code:' grab-01-marco '},{...product,id:'p2',code:'P2',unitPrice:-1},{...product,id:'p2',code:'P2',minQuantity:Infinity}]){
  assert.throws(()=>mergeModuleState({products:[product,row]},previous,'datos',user),e=>e.status===422);
 }
 assert.throws(()=>mergeModuleState({products:[{...product,unitPrice:1}]},previous,'datos',user),e=>e.status===422);
 assert.throws(()=>mergeModuleState({products:[]},previous,'datos',user),e=>e.status===422);
 assert.throws(()=>mergeModuleState({products:[product],users:[]},previous,'datos',user),e=>e.status===422);
});

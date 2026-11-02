import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
import {readProductionSource} from '../src/services/productionSource.js';
import {authorizeModule,mergeModuleState} from '../src/services/moduleState.js';
import {requiredStateCollections} from '../src/services/operationalIntegrity.js';
const code=ts.transpileModule(fs.readFileSync(new URL('../../src/lib/productionDraft.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {productionDraft}=await import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));

test('origen de producción parametriza factura y proyecta cantidades sin importes',async()=>{
 const reference="FAC' 1",inputs=[];
 const request=()=>({input(name,type,value){inputs.push({name,value});return this;},async query(sql){
  assert.equal(sql.includes(reference),false);assert.doesNotMatch(sql,/UnitPrice|Salary|Total/);
  return {recordset:[{SaleNumber:reference,ClientName:'Cliente',LineNumber:1,ProductName:'Vidrio',Quantity:0.5,UnitPrice:200}]};
 }});
 const source=await readProductionSource(request,reference);
 assert.deepEqual(source,{saleNumber:reference,clientName:'Cliente',lines:[{lineNumber:1,product:'Vidrio',quantity:0.5}]});
 assert.deepEqual(inputs,[{name:'Reference',value:reference}]);
 assert.equal(productionDraft(source,1).qty,0.5);
 assert.equal(productionDraft(source,9),null);
});
test('código sugerido distingue líneas y cabe en la columna SQL',()=>{
 const source={saleNumber:'A'.repeat(80),clientName:'Cliente',lines:[{lineNumber:1,product:'Vidrio',quantity:1},{lineNumber:2,product:'Perfil',quantity:2}]};
 assert.ok(productionDraft(source,1).code.length<=80);
 assert.notEqual(productionDraft(source,1).code,productionDraft(source,2).code);
});
test('área de ventas no puede consultar origen de taller y producción sí',()=>{
 for(const [area,allowed] of [['ventas',false],['produccion',true]]){
  let next=false,status;
  authorizeModule({params:{module:'produccion'},method:'GET',user:{hierarchy:'estandar',areas:[area]}},{status(value){status=value;return this;},json(){}},()=>{next=true;});
  assert.equal(next,allowed);if(!allowed)assert.equal(status,403);
 }
});
test('servidor rechaza códigos de orden duplicados con diferencias de espacios y mayúsculas',()=>{
 const previous=Object.fromEntries(requiredStateCollections.map(key=>[key,[]]));
 const order={id:'o1',code:'OT-1',product:'Vidrio',client:'Cliente',qty:1,stage:'backlog',sprint:'Prueba',owner:'Taller'};
 assert.throws(()=>mergeModuleState({production:[order,{...order,id:'o2',code:' ot-1 '}]},previous,'produccion',{name:'Taller'}),error=>error.status===422&&error.message.includes('código'));
});

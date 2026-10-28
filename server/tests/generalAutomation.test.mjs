import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
import {auditOperationalState,validateOperationalChange} from '../src/services/operationalIntegrity.js';
const code=ts.transpileModule(fs.readFileSync(new URL('../../src/lib/snapshotQueue.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2020}}).outputText;
const {createSnapshotQueue}=await import(`data:text/javascript;base64,${Buffer.from(code).toString('base64')}`);
const tick=()=>new Promise(resolve=>setImmediate(resolve));
test('guardado global serializa cambios rápidos sin cancelar el que SQL procesa',async()=>{
 const calls=[],acks=[];let resolveFirst;let revision=1;
 const q=createSnapshotQueue({save:async value=>{calls.push([value,revision]);if(value===1)await new Promise(resolve=>{resolveFirst=resolve});revision++;},saved:value=>acks.push(value),failed:()=>assert.fail('No debe fallar'),pending:()=>{}});
 q.enqueue(1);q.enqueue(2);q.enqueue(3);assert.deepEqual(calls,[[1,1]]);
 resolveFirst();await tick();assert.deepEqual(calls,[[1,1],[3,2]]);assert.deepEqual(acks,[1,3]);
});
test('fallo de guardado detiene la cola y no reenvía un estado incierto',async()=>{
 const calls=[];let failed=0;
 const q=createSnapshotQueue({save:async value=>{calls.push(value);throw Error('respuesta perdida')},saved:()=>assert.fail(),failed:()=>failed++,pending:()=>{}});
 q.enqueue(1);q.enqueue(2);await tick();q.enqueue(3);await tick();assert.deepEqual(calls,[1]);assert.equal(failed,1);
});
test('cambio de sesión detiene confirmaciones antiguas',async()=>{
 let finish;let saved=false;
 const q=createSnapshotQueue({save:()=>new Promise(resolve=>{finish=resolve}),saved:()=>saved=true,failed:()=>{},pending:()=>{}});
 q.enqueue(1);q.enqueue(2);q.stop();finish();await tick();assert.equal(saved,false);
});
const old={products:[{id:'p',code:'P',name:'Vidrio',unitPrice:10,minQuantity:0}],lots:[{id:'l',productId:'p',quantity:10,unitCost:4,entryDate:'2026-10-25'}],kardex:[],sales:[],purchases:[],accounting:[]};
const copy=()=>structuredClone(old);
test('servidor rechaza existencias cambiadas sin kardex y acepta recepción coherente',()=>{
 const next=copy();next.lots[0].quantity=12;assert.throws(()=>validateOperationalChange(next,old),e=>e.code==='OPERATIONAL_INTEGRITY');
 next.kardex.push({id:'k',productId:'p',type:'entrada',quantity:2,unitCost:4});assert.doesNotThrow(()=>validateOperationalChange(next,old));
});
test('documentos inválidos, productos inexistentes y asientos desbalanceados no pasan',()=>{
 const next=copy();next.sales.push({id:'s',items:[{productId:'missing',quantity:-1,unitPrice:10}],subtotal:10,total:99,taxAmount:0});next.accounting.push({id:'a',debit:10,credit:9,entryDate:'2026-10-25'});
 const issues=auditOperationalState(next,old);assert.ok(issues.some(e=>e.module==='sales'));assert.ok(issues.some(e=>e.module==='accounting'));
});
test('compras ordered/received usan su propio contrato sin inventar campos fiscales',()=>{
 const next=copy();next.purchases.push({id:'oc',items:[{productId:'p',quantity:2,unitPrice:10}],total:20,status:'ordered',purchaseDate:'2026-10-25'});assert.doesNotThrow(()=>validateOperationalChange(next,old));
});
test('no se eliminan colecciones ni se reescribe historial al guardar otro módulo',()=>{
 const next=copy();delete next.lots;assert.throws(()=>validateOperationalChange(next,old));
 const legacy=copy();legacy.accounting=[{id:'old',debit:1,credit:2,entryDate:'old'}];assert.doesNotThrow(()=>validateOperationalChange(legacy,legacy));assert.ok(auditOperationalState(legacy).length>0);
});
const normalizedCode=ts.transpileModule(fs.readFileSync(new URL('../../src/lib/normalizeErpState.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2020}}).outputText;
const {normalizeErpState}=await import(`data:text/javascript;base64,${Buffer.from(normalizedCode).toString('base64')}`);
const allocationCode=ts.transpileModule(fs.readFileSync(new URL('../../src/lib/inventoryAllocation.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2020}}).outputText;
const {allocateInventory}=await import(`data:text/javascript;base64,${Buffer.from(allocationCode).toString('base64')}`);
const {putStateSchema}=await import('../src/routes/state.js');
test('SQL vacío conserva listas vacías y no reincorpora ventas ni productos de ejemplo',()=>{
 const normalized=normalizeErpState({products:[],sales:[],lots:[],users:[{id:'u',password:'no-conservar',name:'Operador'}]});
 assert.deepEqual(normalized.products,[]);assert.deepEqual(normalized.sales,[]);assert.deepEqual(normalized.lots,[]);assert.equal('password' in normalized.users[0],false);
});
test('PEPS agrega cantidades repetidas, conserva original y usa costo del lote',()=>{
 const lots=[{id:'l1',productId:'p',quantity:2,unitCost:4,entryDate:'2026-10-01'},{id:'l2',productId:'p',quantity:3,unitCost:7,entryDate:'2026-10-02'}];
 assert.equal(allocateInventory(lots,[{productId:'p',quantity:3},{productId:'p',quantity:3}]),null);
 const result=allocateInventory(lots,[{productId:'p',quantity:3}]);assert.equal(result.totalCost,15);assert.equal(result.unitCosts.get('p'),5);assert.equal(result.lots[0].quantity,0);assert.equal(result.lots[1].quantity,2);assert.equal(lots[0].quantity,2);
 assert.equal(allocateInventory(lots,[{productId:'p',quantity:-1}]),null);
});
test('snapshot parcial se rechaza antes de ejecutar el guardado',()=>{
 assert.equal(putStateSchema.safeParse({state:{sales:[]}}).success,false);
 assert.equal(putStateSchema.safeParse({state:normalizeErpState({})}).success,true);
});
test('migración global preserva proveedores y fija opciones de índices sin cargas operativas',()=>{
 const sql=fs.readFileSync(new URL('../../Database/SQLServer_Completo/34_preservar_proveedores_guardado_global.sql',import.meta.url),'utf8');
 assert.ok(sql.includes('SET QUOTED_IDENTIFIER ON'));assert.ok(sql.includes('SET ANSI_NULLS ON'));assert.ok(sql.includes('BEGIN TRANSACTION'));assert.ok(sql.includes('uses_quoted_identifier'));assert.equal(/INSERT\s+INTO\s+dbo\./i.test(sql),false);
});

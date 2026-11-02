import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
const source=fs.readFileSync(new URL('../../src/lib/navigationSearch.ts',import.meta.url),'utf8');
const code=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText;
const {navigationSearch}=await import('data:text/javascript;base64,'+Buffer.from(code).toString('base64'));
const modules=[{id:'ventas',label:'Ventas',description:'Facturas'},{id:'produccion',label:'Producción',description:'Órdenes'}];
const state={sales:[{saleNumber:'FAC/ 10',clientName:'María'}],proformas:[],production:[{code:'OT 1',client:'María',product:'Ventana'}],products:[],purchases:[],parties:[],employees:[{name:'Privado'}],users:[{name:'Privado'}]};

test('busca sin acentos y genera enlaces exactos con caracteres especiales',()=>{
 assert.equal(navigationSearch('produccion',modules,state)[0].url,'/produccion');
 const results=navigationSearch('maria',modules,state);
 assert.ok(results.some(result=>result.url==='/ventas#sale-FAC%2F%2010'));
 assert.ok(results.some(result=>result.url==='/produccion#production-OT%201'));
});
test('no muestra registros de módulos no autorizados ni datos de nómina o usuarios',()=>{
 assert.deepEqual(navigationSearch('maria',[],state),[]);
 const results=navigationSearch('maria',[modules[1]],state);
 assert.equal(results.length,1);assert.match(results[0].url,/^\/produccion/);
 assert.deepEqual(navigationSearch('privado',modules,state),[]);
});
test('evita resultados para consultas cortas y limita listas extensas',()=>{
 assert.deepEqual(navigationSearch(' ',modules,state),[]);
 assert.deepEqual(navigationSearch('a',modules,state),[]);
 const many={...state,sales:Array.from({length:30},(_,i)=>({saleNumber:'FAC '+i,clientName:'Cliente'}))};
 assert.equal(navigationSearch('cliente',[modules[0]],many).length,12);
});

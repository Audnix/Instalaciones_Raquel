import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
const compile=async(path)=>{const js=ts.transpileModule(fs.readFileSync(new URL(path,import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;return import(`data:text/javascript;base64,${Buffer.from(js).toString('base64')}`)};
const {cashSessionBlock,explicitCashCount}=await compile('../../src/lib/cashReadiness.ts');
const {parseApiResponse}=await compile('../../src/auth/apiSession.ts');
test('caja exige sesión del día confirmado por servidor',()=>{
 assert.match(cashSessionBlock(undefined,'2026-10-25'),/Abre/);
 assert.match(cashSessionBlock('2026-10-21T00:00:00Z','2026-10-25'),/arqueo y cierre/);
 assert.match(cashSessionBlock('2026-10-25',null),/servidor/);
 assert.equal(cashSessionBlock('2026-10-25T00:00:00Z','2026-10-25'),null);
});
test('arqueo y apertura no convierten campo vacío en dinero contado',()=>{
 for(const input of ['', ' ', '-1','abc','1.001'])assert.equal(explicitCashCount(input),null);
 assert.equal(explicitCashCount('0'),0);assert.equal(explicitCashCount('2250.50'),2250.5);
});
test('respuestas sin JSON explican límite y error HTTP sin confirmar éxito',async()=>{
 await assert.rejects(parseApiResponse(new Response('Too many requests',{status:429})),e=>e.code==='TOO_MANY_REQUESTS');
 await assert.rejects(parseApiResponse(new Response('',{status:500})),e=>e.message.includes('HTTP 500'));
 await assert.rejects(parseApiResponse(new Response('',{status:404})),e=>e.code==='API_ROUTE_UNAVAILABLE');
});

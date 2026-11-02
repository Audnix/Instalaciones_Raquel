import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
const source = fs.readFileSync(new URL('../../src/lib/taskResponse.ts', import.meta.url), 'utf8');
const code = ts.transpileModule(source, {compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {parseTaskResponse} = await import('data:text/javascript;base64,' + Buffer.from(code).toString('base64'));
const task = {id:'sale-1',module:'ventas',title:'Factura pendiente',detail:'Revisar',priority:'alta',actionUrl:'/ventas#sale-FAC%201',actionLabel:'Abrir'};

test('distingue una bandeja vacía confirmada de una respuesta incompleta', () => {
  assert.deepEqual(parseTaskResponse({tasks:[]}), []);
  assert.deepEqual(parseTaskResponse({tasks:[task]}), [task]);
  for (const response of [null, {}, {tasks:null}, {tasks:'sin pendientes'}]) assert.throws(() => parseTaskResponse(response));
});
test('rechaza tareas incompletas, prioridades inválidas e identificadores duplicados', () => {
  for (const row of [null, {...task,title:null}, {...task,priority:'urgente'}, {...task,id:''}]) assert.throws(() => parseTaskResponse({tasks:[row]}));
  assert.throws(() => parseTaskResponse({tasks:[task,task]}));
});
test('los accesos de tareas solo aceptan rutas internas sin controles ni barras inversas', () => {
  for (const actionUrl of ['https://example.com', '//example.com', '/\\example.com', '/ventas\n', '/ ventas']) assert.throws(() => parseTaskResponse({tasks:[{...task,actionUrl}]}));
  assert.equal(parseTaskResponse({tasks:[{...task,actionUrl:'/nomina?runId=PL%201'}]})[0].actionUrl,'/nomina?runId=PL%201');
});

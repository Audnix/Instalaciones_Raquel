import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
const source=fs.readFileSync(new URL('../../src/lib/apiBase.ts',import.meta.url),'utf8').replace('import.meta.env.VITE_API_URL','undefined').replace('import.meta.env.DEV','false');
const compiled=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {resolveApiBase}=await import(`data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`);
test('desarrollo usa el proxy para API loopback y evita conexiones del navegador a otro puerto',()=>{
 for(const base of ['http://localhost:4000','http://127.0.0.1:4000/','http://[::1]:4000'])assert.equal(resolveApiBase(base,true),'');
 assert.equal(resolveApiBase(undefined,true),'');
});
test('conserva API remota y configuración de producción',()=>{
 assert.equal(resolveApiBase('https://api.example.com/',true),'https://api.example.com');
 assert.equal(resolveApiBase('http://localhost:4000',false),'http://localhost:4000');
 assert.equal(resolveApiBase('http://localhost:4000/custom',true),'http://localhost:4000/custom');
});

import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const root=new URL('../../Database/SQLServer_Completo/',import.meta.url);
const source=fs.readFileSync(new URL('26_integridad_caja_nomina_pagos.sql',root),'utf8').replaceAll('\r\n','\n');
const migration=fs.readFileSync(new URL('32_conservar_enlaces_snapshot.sql',root),'utf8');
const pairs=[...migration.matchAll(/SET @Before=N'((?:''|[^'])*)';\s*SET @After=N'((?:''|[^'])*)';/g)]
 .map(([,before,after])=>[before.replaceAll("''","'"),after.replaceAll("''","'")]);
function apply(definition){for(const [before,after]of pairs){if(definition.includes(after))continue;if(!definition.includes(before))throw Error('Definicion diferente');definition=definition.replaceAll(before,after);}return definition;}
test('el parche preserva enlaces de caja, contabilidad y finanzas confirmados',()=>{
 assert.equal(pairs.length,7);const patched=apply(source);
 for(const alias of ['cashMove','accounting','financeMove'])assert.ok(patched.includes(`WHERE ${alias}.OperationKey IS NULL;`));
});
test('reaplicar el parche no vuelve a modificar la definicion',()=>{
 const once=apply(source);assert.equal(apply(once),once);
});
test('una definicion distinta exige revision y no se reemplaza a ciegas',()=>{
 assert.throws(()=>apply(source.replace(pairs[0][0],'/* procedimiento distinto */')),/Definicion diferente/);
});

test('las ordenes no recibidas no crean deuda y los anulados no cuentan como pagos',()=>{
 const patched=apply(source);assert.ok(patched.includes("WHERE p.Status=N'received';"));
 assert.ok(patched.includes("m.MoveType = N'salida' AND m.MoveState=N'confirmado'"));
 assert.ok(patched.includes("WHEN pagos.Pagado>0 THEN N'parcial'"));
});

test('las fechas existentes se conservan; no se inventa vencimiento para un documento nuevo',()=>{const patched=apply(source);assert.ok(patched.includes('INSERT @IntegrityReceivableDates SELECT'));assert.ok(patched.includes('INSERT @IntegrityPayableDates SELECT'));assert.ok(patched.includes('FROM @IntegrityPayableDates d WHERE d.PayableId'));});

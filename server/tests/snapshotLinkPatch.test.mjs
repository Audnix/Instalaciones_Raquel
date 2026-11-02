import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const root=new URL('../../Database/SQLServer_Completo/',import.meta.url);
const source=fs.readFileSync(new URL('26_integridad_caja_nomina_pagos.sql',root),'utf8').replaceAll('\r\n','\n');
const migration=fs.readFileSync(new URL('32_conservar_enlaces_snapshot.sql',root),'utf8');
const normalize=value=>value.replaceAll('\r\n','\n');
function readPairs(sql){
 return [...sql.matchAll(/SET @Before=N'((?:''|[^'])*)';\s*SET @After=N'((?:''|[^'])*)';([\s\S]*?)IF CHARINDEX\(@After,@Definition\)=0/g)]
  .map(([,before,after,preparation])=>{
   assert.ok(preparation.includes('SET @Before=REPLACE(@Before,CHAR(13)+CHAR(10),CHAR(10));'));
   assert.ok(preparation.includes('SET @After=REPLACE(@After,CHAR(13)+CHAR(10),CHAR(10));'));
   return [normalize(before.replaceAll("''","'")),normalize(after.replaceAll("''","'"))];
  });
}
const pairs=readPairs(migration);
function apply(definition,patterns=pairs){definition=normalize(definition);for(const [before,after]of patterns){if(definition.includes(after))continue;if(!definition.includes(before))throw Error('Definicion diferente');definition=definition.replaceAll(before,after);}return definition;}

test('el parche normaliza patrones y definicion con archivos LF y CRLF',()=>{
 assert.ok(migration.includes('SET @Definition=REPLACE(@Definition,CHAR(13)+CHAR(10),CHAR(10));'));
 const expected=apply(source);
 for(const sqlEnding of ['\n','\r\n']){
  const patterns=readPairs(normalize(migration).replaceAll('\n',sqlEnding));
  assert.equal(patterns.length,7);
  for(const procedureEnding of ['\n','\r\n']){
   const patched=apply(source.replaceAll('\n',procedureEnding),patterns);
   assert.equal(patched,expected);
   assert.equal(apply(patched,patterns),patched);
  }
 }
});

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

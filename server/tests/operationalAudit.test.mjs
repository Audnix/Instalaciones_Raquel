import test from 'node:test';
import assert from 'node:assert/strict';
import {readOperationalAudit} from '../src/services/operationalAudit.js';

test('auditoría conserva las diferencias identificables sin escribir ni reparar pagos',async()=>{
 const discrepancies=[{id:'run-1',period:'2026-10',status:'cerrada',confirmedCount:0,reason:'sin_pagos_registrados'}];
 const pool={request(){return {async query(sql){
  assert.doesNotMatch(sql,/\b(?:UPDATE|DELETE|INSERT|MERGE|EXEC|ALTER|DROP)\b/i);
  return {recordsets:[[{Payload:JSON.stringify({products:[]})}],[{account:'banco',sessionDate:'2026-10-27'}],[{unverifiedPayrolls:1}],discrepancies]};
 }}}};
 const report=await readOperationalAudit(pool);
 assert.equal(report.readOnly,true);
 assert.equal(report.payroll.unverifiedPayrolls,1);
 assert.deepEqual(report.payroll.discrepancies,discrepancies);
 assert.equal(report.staleSessions[0].account,'banco');
 assert.equal(report.snapshotAvailable,true);
});

test('sin estado guardado no se afirma que existe una revisión completa',async()=>{
 const pool={request(){return {async query(){return {recordsets:[[],[],[{unverifiedPayrolls:0}],[]]};}}}};
 const report=await readOperationalAudit(pool);
 assert.equal(report.snapshotAvailable,false);
 assert.deepEqual(report.payroll.discrepancies,[]);
});


test('clasificar datos de prueba no oculta ni corrige las diferencias históricas',async()=>{
 const discrepancies=[{id:'test-run',testDataConfirmed:true},{id:'other-run',testDataConfirmed:false}];
 const pool={request(){return {async query(){return {recordsets:[[],[],[{unverifiedPayrolls:2}],discrepancies]};}}}};
 const report=await readOperationalAudit(pool);
 assert.equal(report.payroll.unverifiedPayrolls,2);
 assert.equal(report.payroll.confirmedTestPayrolls,1);
 assert.equal(report.payroll.discrepancies.length,2);
});

import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
import { evaluatePaymentCheck, checkPayrollPayment } from '../src/services/payrollPaymentCheck.js';
const compiled = ts.transpileModule(fs.readFileSync(new URL('../../src/lib/payrollGuide.ts',import.meta.url),'utf8'),{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const { payrollPaymentGuide: guide } = await import(`data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`);
const context={status:'borrador',calculationCurrent:false,workers:2,blocking:0,historyReady:true,totalsConsistent:true,pending:1000};
test('la guía dirige cálculo, revisión, aprobación y abonos sin autoaprobar',()=>{
 assert.equal(guide(context).action,'calcular');
 assert.equal(guide({...context,status:'calculada',calculationCurrent:true}).action,'revisar');
 assert.equal(guide({...context,status:'revisada',calculationCurrent:true}).action,'aprobaciones');
 assert.equal(guide({...context,status:'aprobada',calculationCurrent:true}).action,'abono');
 assert.equal(guide({...context,status:'pago_registrado',calculationCurrent:true}).label,'Registrar siguiente abono');
});
test('la guía no permite saltarse errores, historial sin verificar ni conciliaciones inconsistentes',()=>{
 assert.equal(guide({...context,workers:0}).action,'trabajadores');
 assert.equal(guide({...context,status:'aprobada',calculationCurrent:true,blocking:1}).action,'validaciones');
 assert.equal(guide({...context,status:'aprobada',calculationCurrent:true,historyReady:false}).action,'actualizar');
 assert.equal(guide({...context,status:'conciliada'}).action,'historial');
 assert.equal(guide({...context,status:'aprobada'}).action,'validaciones');
});
test('cubrir el pendiente lleva a conciliación; el cierre sigue siendo una acción separada',()=>{
 assert.equal(guide({...context,status:'pago_registrado',calculationCurrent:true,pending:0}).action,'aprobaciones');
 assert.equal(guide({...context,status:'conciliada',calculationCurrent:true,pending:0}).label,'Revisar cierre');
});
test('diferencias de cabecera o pagos no se envían a una lista vacía de validaciones',()=>{
 const calculated={...context,status:'pago_registrado',calculationCurrent:true,blocking:0};
 assert.equal(guide({...calculated,totalsConsistent:false}).action,'diferencias');
 assert.equal(guide({...calculated,paymentTotalsConsistent:false}).label,'Revisar respaldo de pagos');
});
const request={amount:200,paymentDate:'2026-10-21'};
const snapshot={run:{status:'aprobada',calculatedAt:'2026-10-21',version:2,stale:false,gross:1200,deductions:200,net:1000,itemNet:1000,itemDeductions:200,headerPaid:100,actualPaid:100},worker:{net:600,paid:100},session:{date:'2026-10-21',currency:'NIO',available:400},blocking:0};
test('prevalidación acepta un abono individual y explica el pendiente',()=>{
 const result=evaluatePaymentCheck(snapshot,request);
 assert.equal(result.ready,true);assert.equal(result.pending,500);assert.equal(result.available,400);
});
test('prevalidación rechaza exceso individual, falta de fondos, otra moneda, sesión y fecha',()=>{
 for(const [change,code] of [
  [{worker:{net:250,paid:100}},'pending'],[{session:{...snapshot.session,available:100}},'funds'],
  [{session:{...snapshot.session,currency:'USD'}},'currency'],[{session:null},'session'],
  [{session:{...snapshot.session,date:'2026-10-20'}},'session']]){
  const result=evaluatePaymentCheck({...snapshot,...change},request);
  assert.equal(result.ready,false);assert.equal(result.checks.find(c=>c.code===code).ok,false);
 }
});
test('prevalidación rechaza cálculo antiguo, acumulado falso, planilla cerrada y trabajador ajeno',()=>{
 for(const change of [{run:{...snapshot.run,stale:true}},{run:{...snapshot.run,headerPaid:500}},
  {run:{...snapshot.run,status:'cerrada'}},{run:{...snapshot.run,invalidItems:1}},
  {run:{...snapshot.run,unallocatedPayments:1}},{worker:null},{blocking:1}])
  assert.equal(evaluatePaymentCheck({...snapshot,...change},request).ready,false);
});
test('recuperar la misma clave confirmada llega al procedimiento autoritativo sin duplicar pagos',async()=>{
 let reads=0;
 const pool={request(){return{input(){return this;},async query(){reads++;return{recordset:[{PaymentId:'existing'}]};}};}};
 const result=await checkPayrollPayment(pool,'run',{mutationId:'key',paymentMethod:'efectivo'});
 assert.equal(result.retryExisting,true);assert.equal(reads,1);
});

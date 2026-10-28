import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
const source=fs.readFileSync(new URL('../../src/lib/payrollPayments.ts',import.meta.url),'utf8');
const js=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.ESNext}}).outputText;
const {paidToEmployee,pendingForEmployee}=await import(`data:text/javascript;base64,${Buffer.from(js).toString('base64')}`);
test('una dispersion general reduce el pendiente individual sin contarse dos veces',()=>{
  const payments=[{amount:300,employeeId:null,allocations:[{employeeId:'a',amount:100},{employeeId:'b',amount:200}]},
    {amount:50,employeeId:'a',allocations:[{employeeId:'a',amount:50}]}];
  assert.equal(paidToEmployee(payments,'a'),150);
  assert.equal(paidToEmployee(payments,'b'),200);
  assert.equal(paidToEmployee(payments,'c'),0);
});
test('historico individual y centavos conservan el pendiente correcto',()=>{
  assert.equal(paidToEmployee([{amount:0.1,employeeId:'a'},{amount:0.2,employeeId:'a'}],'a'),0.3);
  assert.equal(paidToEmployee([],'a'),0);
});
test('el pendiente individual resta pagos conjuntos y pagos separados',()=>{
  const payments=[{amount:300,employeeId:null,allocations:[{employeeId:'a',amount:100},{employeeId:'b',amount:200}]},
    {amount:50,employeeId:'a',allocations:[{employeeId:'a',amount:50}]}];
  assert.equal(pendingForEmployee(200,payments,'a'),50);
  assert.equal(pendingForEmployee(200,payments,'b'),0);
  assert.equal(pendingForEmployee(80,payments,'c'),80);
});

test('abonos sucesivos respetan netos diferentes y no pagan al otro trabajador',()=>{
  const payments=[];
  const nets={ana:9500,carlos:7200};
  payments.push({amount:2000,employeeId:'ana'});
  assert.equal(pendingForEmployee(nets.ana,payments,'ana'),7500);
  assert.equal(pendingForEmployee(nets.carlos,payments,'carlos'),7200);
  payments.push({amount:1200,employeeId:'carlos'});
  payments.push({amount:2500,employeeId:'ana'});
  assert.equal(paidToEmployee(payments,'ana'),4500);
  assert.equal(pendingForEmployee(nets.ana,payments,'ana'),5000);
  assert.equal(pendingForEmployee(nets.carlos,payments,'carlos'),6000);
  payments.push({amount:5000,employeeId:'ana'});
  assert.equal(pendingForEmployee(nets.ana,payments,'ana'),0);
  assert.equal(pendingForEmployee(nets.carlos,payments,'carlos'),6000);
});

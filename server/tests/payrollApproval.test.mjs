import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
const code = ts.transpileModule(fs.readFileSync(new URL('../../src/lib/payrollApproval.ts', import.meta.url), 'utf8'), { compilerOptions: { module: ts.ModuleKind.ESNext } }).outputText;
const { payrollApprovalBlock } = await import('data:text/javascript;base64,' + Buffer.from(code).toString('base64'));
const run = { preparedById: 'preparador', calculatedById: 'calculador' };
test('ni preparador ni calculador pueden autoaprobar aunque sean superadministradores', () => {
  assert.match(payrollApprovalBlock(run, { id: 'preparador', hierarchy: 'superadmin' }), /otra persona/);
  assert.match(payrollApprovalBlock(run, { id: 'calculador', hierarchy: 'superadmin' }), /otra persona/);
});
test('otra persona con permisos financieros puede aprobar; RRHH por sí solo no', () => {
  assert.equal(payrollApprovalBlock(run, { id: 'finanzas', hierarchy: 'administrador', areas: ['finanzas'] }), null);
  assert.equal(payrollApprovalBlock(run, { id: 'supervisor', hierarchy: 'superadmin' }), null);
  assert.ok(payrollApprovalBlock(run, { id: 'rrhh', hierarchy: 'administrador', areas: ['rrhh'] }));
});
test('sin identidad o datos de autoría no se ofrece aprobación automática', () => {
  assert.ok(payrollApprovalBlock(run, null));
  assert.ok(payrollApprovalBlock({}, { id: 'supervisor', hierarchy: 'superadmin' }));
  assert.equal(payrollApprovalBlock({ preparedById: null, calculatedById: null }, { id: 'supervisor', hierarchy: 'superadmin' }), null);
});

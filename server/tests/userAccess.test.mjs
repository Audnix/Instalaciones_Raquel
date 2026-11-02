import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
import { canManagePayrollMoney } from '../src/services/payrollPermissions.js';
const code = ts.transpileModule(fs.readFileSync(new URL('../../src/auth/roles.ts', import.meta.url), 'utf8'), { compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 } }).outputText;
const { canAccess, can, modulesForUser } = await import('data:text/javascript;base64,' + Buffer.from(code).toString('base64'));
const user = (hierarchy, areas, extra = {}) => ({ id: 'user', name: 'Usuario', email: 'test@example.com', hierarchy, areas, active: true, ...extra });

test('administrador puede abrir catalogo de productos sin privilegios de superadministracion', () => {
  const actor = user('administrador', ['ventas']);
  assert.equal(canAccess(actor, 'datos'), true);
  assert.equal(can(actor, 'datos', 'write'), true);
  assert.equal(canAccess(user('estandar', ['ventas']), 'datos'), false);
  assert.equal(can(user('invitado', ['inventario']), 'datos', 'write'), false);
  assert.equal(can(user('estandar', ['inventario']), 'datos', 'write'), true);
  assert.equal(can(user('estandar', ['gobierno']), 'datos', 'write'), false);
  assert.equal(can(user('estandar', ['compras']), 'datos', 'write'), false);
});
test('contador y finanzas administradores pueden abrir nómina y tienen permiso financiero en servidor', () => {
  for (const area of ['contabilidad', 'finanzas']) {
    const actor = user('administrador', [area]);
    assert.equal(canAccess(actor, 'nomina'), true);
    assert.equal(can(actor, 'nomina', 'approve'), true);
    assert.equal(canManagePayrollMoney(actor), true);
  }
});
test('RRHH prepara nómina sin obtener aprobación financiera ni acceso a contabilidad', () => {
  const actor = user('administrador', ['rrhh']);
  assert.equal(can(actor, 'nomina', 'write'), true);
  assert.equal(can(actor, 'nomina', 'approve'), false);
  assert.equal(canManagePayrollMoney(actor), false);
  assert.equal(canAccess(actor, 'contabilidad'), false);
});
test('usuarios estándar, invitados y otras áreas no reciben el módulo administrativo de nómina', () => {
  for (const actor of [user('estandar', ['rrhh']), user('invitado', ['finanzas']), user('administrador', ['ventas'])]) assert.equal(canAccess(actor, 'nomina'), false);
  assert.equal(can(user('estandar', ['ventas']), 'ventas', 'write'), true);
  assert.equal(can(user('invitado', ['ventas']), 'ventas', 'write'), false);
});
test('cuentas inactivas o pendientes de activar no habilitan módulos', () => {
  assert.deepEqual(modulesForUser(user('superadmin', [], { active: false })), []);
  assert.deepEqual(modulesForUser(user('superadmin', [], { mustChangePassword: true })), []);
  assert.doesNotThrow(() => modulesForUser(user('administrador', ['area_invalida'])));
});

import test from 'node:test';
import assert from 'node:assert/strict';
import { authorizeModule, projectModuleState, mergeModuleState } from '../src/services/moduleState.js';

function authorize(hierarchy, areas, method = 'GET') {
  const result = { status: 200, allowed: false };
  authorizeModule({ params: { module: 'auditoria' }, method, user: { hierarchy, areas } }, {
    status(status) { result.status = status; return this; }, json() { return this; }
  }, () => { result.allowed = true; });
  return result;
}

test('administrador de cualquier area puede consultar auditoria sin acceso global', () => {
  assert.equal(authorize('administrador', ['produccion']).allowed, true);
  assert.equal(authorize('administrador', []).allowed, true);
  assert.equal(authorize('superadmin', []).allowed, true);
  assert.equal(authorize('invitado', ['gobierno']).allowed, true);
  assert.equal(authorize('estandar', ['ventas']).status, 403);
  assert.equal(authorize('invitado', ['ventas']).status, 403);
});
test('auditoria es solo lectura incluso para administracion', () => {
  for (const role of ['superadmin', 'administrador', 'estandar', 'invitado']) {
    assert.equal(authorize(role, ['gobierno'], 'PUT').status, 403);
  }
  assert.throws(() => mergeModuleState({ audit: [] }, {}, 'auditoria', {}), e => e.status === 422);
});

test('consulta contiene evidencia del expediente sin directorio de usuarios ni nomina', () => {
  const keys = ['audit', 'sales', 'kardex', 'accounting', 'cash', 'products', 'lots'];
  const state = Object.fromEntries([...keys, 'users', 'employees', 'payrollRuns', 'parties'].map(key => [key, [{ id: key }]]));
  const projected = projectModuleState(state, 'auditoria');
  assert.deepEqual(Object.keys(projected).sort(), keys.sort());
  for (const key of keys) assert.deepEqual(projected[key], state[key]);
  assert.equal('users' in projected, false);
  assert.equal('employees' in projected, false);
  assert.equal('payrollRuns' in projected, false);
});

import test from 'node:test';
import assert from 'node:assert/strict';
import { saveStateSnapshot } from '../src/services/stateSnapshot.js';
import { stateRouter } from '../src/routes/state.js';

const old = '0x0000000000000001', saved = '0x0000000000000002';
function fixture({ failExecute = false, failRead = false, missing = false } = {}) {
  const events = [];
  const transaction = { on() {}, async begin() { events.push('begin'); },
    async commit() { events.push('commit'); }, async rollback() { events.push('rollback'); } };
  const request = () => ({ input() { return this; },
    async query(query) {
      const locked = query.includes('UPDLOCK, HOLDLOCK');
      events.push(locked ? 'lock-read' : 'saved-read');
      if (!locked && failRead) throw Error('connection lost');
      return { recordset: missing && locked ? [] : [{ Revision: Buffer.from((locked ? old : saved).slice(2), 'hex') }] };
    },
    async execute() { events.push('write'); if (failExecute) throw Error('SQL failure'); }
  });
  return { events, dependencies: { transaction, request } };
}
test('revisión confirmada se captura bajo bloqueo antes de liberar la transacción', async () => {
  const f = fixture();
  assert.deepEqual(await saveStateSnapshot(null, '{}', old, f.dependencies), { saved: true, revision: saved });
  assert.deepEqual(f.events, ['begin', 'lock-read', 'write', 'saved-read', 'commit']);
});
test('snapshot de otra sesión se rechaza sin escribir ni adoptar una revisión ajena', async () => {
  const f = fixture();
  await assert.rejects(saveStateSnapshot(null, '{}', saved, f.dependencies), e => e.status === 409);
  assert.deepEqual(f.events, ['begin', 'lock-read', 'rollback']);
});
test('estado existente exige revisión y devuelve 428 sin escribir', async () => {
  const f = fixture();
  await assert.rejects(saveStateSnapshot(null, '{}', null, f.dependencies), e => e.status === 428 && e.revision === old);
  assert.deepEqual(f.events, ['begin', 'lock-read', 'rollback']);
});
test('fallos de escritura o lectura final revierten y nunca anuncian guardado', async () => {
  for (const options of [{ failExecute: true }, { failRead: true }]) {
    const f = fixture(options);
    await assert.rejects(saveStateSnapshot(null, '{}', old, f.dependencies));
    assert.equal(f.events.at(-1), 'rollback');
    assert.equal(f.events.includes('commit'), false);
  }
});
test('revisión de un estado eliminado no puede recrearlo silenciosamente', async () => {
  const f = fixture({ missing: true });
  await assert.rejects(saveStateSnapshot(null, '{}', old, f.dependencies), e => e.status === 409);
  assert.equal(f.events.includes('write'), false);
});
test('snapshot de todas las áreas rechaza perfiles inferiores y exige cambio de contraseña al escribir', () => {
  // Se comprueba la política REAL montada después de requireAuth.
  const roleCheck = stateRouter.stack[1].handle;
  const passwordCheck = stateRouter.stack[2].handle;
  const invoke = (handler, hierarchy, method = 'PUT', mustChangePassword = false) => {
    const result = { next: false, status: 200 };
    const res = { status(code) { result.status = code; return this; }, json() { return this; } };
    handler({ user: { hierarchy, mustChangePassword }, method }, res, () => { result.next = true; });
    return result;
  };
  for (const role of ['administrador', 'estandar', 'invitado']) {
    assert.equal(invoke(roleCheck, role).status, 403);
  }
  assert.equal(invoke(roleCheck, 'superadmin').next, true);
  assert.equal(invoke(passwordCheck, 'superadmin', 'PUT', true).status, 403);
  assert.equal(invoke(passwordCheck, 'superadmin', 'GET', true).next, true);
});

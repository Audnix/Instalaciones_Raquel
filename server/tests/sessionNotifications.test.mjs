import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import ts from '../../node_modules/typescript/lib/typescript.js';
const source = fs.readFileSync(new URL('../../src/auth/apiSession.ts', import.meta.url), 'utf8');
const compiled = ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.ESNext } }).outputText;
const api = await import(`data:text/javascript;base64,${Buffer.from(compiled).toString('base64')}`);
const storage = () => {
  const values = new Map();
  return { getItem: key => values.get(key) ?? null, setItem: (key, value) => values.set(key, value), removeItem: key => values.delete(key) };
};
test('inicio, cambio de cuenta y cierre notifican la sesión ya almacenada a los consumidores', () => {
  const previous = { window: globalThis.window, localStorage: globalThis.localStorage, sessionStorage: globalThis.sessionStorage };
  try {
    globalThis.localStorage = storage();
    globalThis.sessionStorage = storage();
    const observed = [];
    globalThis.window = { dispatchEvent(event) {
      if (event.type === 'raquel-auth-changed') observed.push([api.getAuthToken(), api.readAuthUser()?.id ?? null]);
    } };
    api.saveAuthSession('test-token-a', { id: 'a' }, true);
    api.saveAuthSession('test-token-b', { id: 'b' }, false);
    api.clearAuthSession();
    assert.deepEqual(observed, [['test-token-a', 'a'], ['test-token-b', 'b'], [null, null]]);
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete globalThis[key]; else globalThis[key] = value;
    }
  }
});

test('actualizar los mismos permisos no reescribe el token ni dispara sincronización entre pestañas', () => {
  const previous = { window: globalThis.window, localStorage: globalThis.localStorage, sessionStorage: globalThis.sessionStorage };
  try {
    let writes = 0; let notifications = 0;
    const local = storage(); const originalSet = local.setItem;
    local.setItem = (key, value) => { writes++; originalSet(key, value); };
    globalThis.localStorage = local; globalThis.sessionStorage = storage();
    globalThis.window = { dispatchEvent() { notifications++; } };
    const user = { id: 'contador', hierarchy: 'administrador', areas: ['contabilidad'] };
    api.saveAuthSession('token', user, true);
    const initialWrites = writes;
    api.saveAuthSession('token', user, true);
    assert.equal(writes, initialWrites); assert.equal(notifications, 1);
    api.saveAuthSession('token', { ...user, areas: ['finanzas'] }, true);
    assert.equal(notifications, 2);
    assert.deepEqual(api.readAuthUser().areas, ['finanzas']);
  } finally {
    for (const [key, value] of Object.entries(previous)) { if (value === undefined) delete globalThis[key]; else globalThis[key] = value; }
  }
});

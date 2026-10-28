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

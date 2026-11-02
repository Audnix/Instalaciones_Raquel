import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync(new URL('../src/routes/tasks.js', import.meta.url), 'utf8');
// Exercise the real route handler with an isolated read-only SQL adapter.
async function run(user, fail = false) {
  const queries = [], inputs = [];
  let result, error;
  const fixtures = {
    Proformas: [{ ProformaNumber: 'PRF 1', ClientName: 'Cliente', Total: 100, Status: 'aceptada' }],
    ProductionOrders: [{ Code: 'OT 1', Product: 'Ventana', Client: 'Cliente', Stage: 'corte', Owner: 'Taller' }],
    Products: [{ Code: 'VID 1', Name: 'Vidrio', MinQuantity: 5, OnHand: 2 }],
    Purchases: [{ PurchaseNumber: 'OC 1', SupplierName: 'Proveedor', Total: 50 }],
    HrRequests: []
  };
  const pool = { request() { return {
    input(name, type, value) { inputs.push({ name, value }); return this; },
    async query(sql) {
      queries.push(sql);
      if (fail) throw new Error('SQL unavailable');
      // These invalid fields previously made the entire superadmin inbox fail.
      assert.doesNotMatch(sql, /DeletedAt|\bDescription\b/);
      const table = sql.match(/FROM dbo\.(\w+)/)?.[1];
      assert.ok(table in fixtures, 'Unexpected query: ' + table);
      return { recordset: fixtures[table] };
    }
  }; } };
  let handler;
  const Router = () => ({ use() {}, get(path, fn) { handler = fn; } });
  const body = source.replace(/^import .*;\r?\n/gm, '').replace('export const tasksRouter', 'const tasksRouter');
  new Function('Router', 'sql', 'getDatabase', 'requireAuth', body)(Router, { NVarChar: () => 'text' }, async () => pool, () => {});
  await handler({ user }, { json(data) { result = data; } }, err => { error = err; });
  return { queries, inputs, result, error };
}

test('Mis tareas consulta todas las áreas sin columnas inexistentes y conserva enlaces a registros', async () => {
  const { result, error, queries, inputs } = await run({ id: 'u-test', hierarchy: 'superadmin', areas: [] });
  assert.equal(error, undefined);
  assert.equal(result.count, 5);
  assert.equal(queries.length, 6);
  for (const url of ['/ventas#proforma-PRF%201', '/produccion#production-OT%201', '/inventario#product-VID%201', '/compras#purchase-OC%201']) {
    assert.ok(result.tasks.some(task => task.actionUrl === url), url);
  }
  assert.deepEqual(inputs, [{ name: 'UserId', value: 'u-test' }]);
});

test('Mis tareas de colaborador consulta únicamente sus solicitudes con identidad parametrizada', async () => {
  const { result, queries, inputs } = await run({ id: 'u-personal', hierarchy: 'estandar', areas: [] });
  assert.equal(result.count, 0);
  assert.equal(queries.length, 1);
  assert.match(queries[0], /e\.AppUserId = @UserId/);
  assert.deepEqual(inputs, [{ name: 'UserId', value: 'u-personal' }]);
});

test('un error SQL se propaga y no se presenta como bandeja vacía', async () => {
  const { result, error } = await run({ id: 'u-test', hierarchy: 'superadmin', areas: [] }, true);
  assert.equal(result, undefined);
  assert.equal(error.message, 'SQL unavailable');
});


test('compras recibe alertas de inventario y órdenes pendientes', async () => {
  const { result, error } = await run({ id: 'u-compras', hierarchy: 'estandar', areas: ['compras'] });
  assert.equal(error, undefined);
  assert.deepEqual(result.tasks.map(task => task.module), ['inventario', 'compras']);
});

test('finanzas recibe un enlace a su área y no a contabilidad restringida', async () => {
  const { result } = await run({ id: 'u-finanzas', hierarchy: 'estandar', areas: ['finanzas'] });
  assert.equal(result.tasks[0].module, 'finanzas');
  assert.equal(result.tasks[0].actionUrl, '/finanzas');
});

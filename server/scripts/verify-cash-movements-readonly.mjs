// Ejecuta la misma consulta que GET /api/cash/movements. Sin escrituras.
import assert from 'node:assert/strict';
import dotenv from 'dotenv';
import sql from 'mssql';
import { CASH_MOVEMENTS_SQL } from '../src/services/cashLedgerSql.js';
dotenv.config({ path: new URL('../../.env', import.meta.url), quiet: true });
const { getDatabase } = await import('../src/config/sqlserver.js');
const pool = await getDatabase();
if (!pool) throw Error('SQL Server no configurado');
try {
  for (const account of ['caja', 'banco']) {
    for (const from of [null, '2026-10-01']) {
      const result = await pool.request().input('Account', sql.NVarChar(30), account)
        .input('FromDate', sql.Date, from).input('ToDate', sql.Date, from ? '2026-10-21' : null)
        .input('Limit', sql.Int, 500).query(CASH_MOVEMENTS_SQL);
      assert.ok(result.recordset.columns.exit, 'La API conserva el campo JSON exit');
      for (const row of result.recordset) {
        assert.equal(row.account, account);
        assert.ok(Number.isFinite(Number(row.balance)));
        if (row.type === 'salida') assert.ok(Number(row.exit) > 0);
        if (row.type === 'entrada') assert.ok(Number(row.entry) > 0);
      }
      console.log('PASS movimientos', account, from ?? 'sin filtro', result.recordset.length, 'filas');
    }
  }
} finally { await pool.close(); }

import fs from 'node:fs';
import dotenv from 'dotenv';
dotenv.config({ path: new URL('../../.env', import.meta.url), quiet: true });
const { getDatabase } = await import('../src/config/sqlserver.js');
const pool = await getDatabase();
if (!pool) throw Error('SQL Server no configurado');
try {
  const source = fs.readFileSync(new URL('../../docs/30_auditoria_integridad_solo_lectura.sql', import.meta.url), 'utf8');
  const queries = source.split(/^GO\s*$/mi).filter(s => s.trim());
  const findings = [];
  for (const query of queries) findings.push(...(await pool.request().query(query)).recordsets);
  const metadata = await pool.request().query(`SELECT
    (SELECT COUNT(*) FROM dbo.PayrollRuns) AS runs,
    (SELECT COUNT(*) FROM dbo.PayrollRunItems) AS items,
    (SELECT COUNT(*) FROM dbo.PayrollPayments) AS payments,
    (SELECT COUNT(*) FROM dbo.CashMoves) AS cashMoves,
    (SELECT COUNT(*) FROM dbo.CashSessions) AS sessions;
    SELECT OBJECT_ID(N'dbo.usp_PayrollPaymentIntegrityVersion',N'P') AS migration30,
      OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') AS migration31,
      HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CREATE PROCEDURE') AS canCreateProcedure;
    SELECT name,is_disabled,OBJECT_NAME(parent_id) AS target FROM sys.triggers WHERE parent_class=1;`);
  const report = { capturedAt: new Date().toISOString(), readOnly: true,
    counts: metadata.recordsets[0][0], deployment: metadata.recordsets[1][0],
    visibleTriggers: metadata.recordsets[2], findings };
  fs.writeFileSync(new URL('../../docs/auditoria_integridad_actual.json', import.meta.url), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({ counts: report.counts, deployment: report.deployment,
    findingsPerQuery: findings.map(rows => rows.length), report: 'docs/auditoria_integridad_actual.json' }));
} finally { await pool.close(); }

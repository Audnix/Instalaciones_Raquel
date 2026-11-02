import dotenv from 'dotenv';
import fs from 'node:fs';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase,database}=await import('../src/config/sqlserver.js');
try {
 const pool=await getDatabase();
 if(!pool)throw Error('SQL Server no configurado.');
 const data=await pool.request().query(`
 SELECT r.PayrollRunId AS id,r.Period AS period,r.Status AS status,
 CASE WHEN ISNULL(r.ConfirmedPaymentsTotal,0)=0 THEN 1 ELSE 0 END AS recordedIsZero,
 CASE WHEN ISNULL(p.confirmedTotal,0)=0 THEN 1 ELSE 0 END AS confirmedIsZero,
 ISNULL(p.confirmedCount,0) AS confirmedCount,ISNULL(p.otherCount,0) AS otherCount,
 ISNULL(p.missingCashCount,0) AS missingCashCount
 FROM dbo.PayrollRuns r OUTER APPLY (
 SELECT SUM(CASE WHEN p.Status=N'confirmado' THEN p.Amount ELSE 0 END) confirmedTotal,
 SUM(CASE WHEN p.Status=N'confirmado' THEN 1 ELSE 0 END) confirmedCount,
 SUM(CASE WHEN p.Status<>N'confirmado' THEN 1 ELSE 0 END) otherCount,
 SUM(CASE WHEN p.Status=N'confirmado' AND (m.CashMoveId IS NULL OR m.MoveState<>N'confirmado' OR m.MoveType<>N'salida' OR m.Amount<>p.Amount OR m.PayrollRunId IS NULL OR m.PayrollRunId<>p.PayrollRunId) THEN 1 ELSE 0 END) missingCashCount
 FROM dbo.PayrollPayments p LEFT JOIN dbo.CashMoves m ON m.CashMoveId=p.CashMoveId
 WHERE p.PayrollRunId=r.PayrollRunId)p
 WHERE ABS(ISNULL(r.ConfirmedPaymentsTotal,0)-ISNULL(p.confirmedTotal,0))>0.005;
 SELECT Account AS account,CONVERT(varchar(10),SessionDate,23) AS sessionDate,
 (SELECT COUNT(*) FROM dbo.CashMoves m WHERE m.SessionId=s.CashSessionId AND m.MoveState=N'confirmado') AS confirmedMovements
 FROM dbo.CashSessions s WHERE Status=N'abierta' AND SessionDate<CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time');
 `);
 const report={readOnly:true,checkedAt:new Date().toISOString(),payroll:data.recordsets[0],cashSessions:data.recordsets[1]};
 try {
 const backups=await pool.request().query("SELECT TOP (1) CONVERT(varchar(33),backup_finish_date,126) AS finishedAt,type AS backupType,is_copy_only AS copyOnly FROM msdb.dbo.backupset WHERE database_name=DB_NAME() ORDER BY backup_finish_date DESC");
 report.lastBackup=backups.recordset[0]??null;
 }catch {report.backupHistoryUnavailable=true;}
 fs.writeFileSync(new URL('../../docs/conciliacion_diagnostico_2026-10-30.json',import.meta.url),JSON.stringify(report,null,2));
 console.log(JSON.stringify(report));
} finally {if(database)await database.close();}

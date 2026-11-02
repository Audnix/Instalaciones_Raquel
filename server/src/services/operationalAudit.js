import {auditOperationalState} from './operationalIntegrity.js';
export async function readOperationalAudit(pool){
 const data=await pool.request().query(`SELECT Payload FROM dbo.ErpState WHERE StateId=1;
 SELECT CONVERT(VARCHAR(10),SessionDate,23) AS sessionDate,Account AS account FROM dbo.CashSessions WHERE Status=N'abierta' AND SessionDate<>CONVERT(DATE,SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time');
 SELECT COUNT(*) AS unverifiedPayrolls FROM dbo.PayrollRuns r WHERE ABS(ISNULL(r.ConfirmedPaymentsTotal,0)-ISNULL((SELECT SUM(p.Amount) FROM dbo.PayrollPayments p WHERE p.PayrollRunId=r.PayrollRunId AND p.Status=N'confirmado'),0))>0.005;
 SELECT r.PayrollRunId AS id,r.Period AS period,r.Status AS status,
 CAST(CASE WHEN EXISTS(SELECT 1 FROM dbo.PayrollHistoryEvents h WHERE h.PayrollRunId=r.PayrollRunId AND h.EventType=N'clasificacion_prueba') THEN 1 ELSE 0 END AS bit) AS testDataConfirmed,
 ISNULL(p.confirmedCount,0) AS confirmedCount,
 (SELECT COUNT(*) FROM dbo.CashMoves m WHERE m.PayrollRunId=r.PayrollRunId AND m.MoveType=N'salida' AND m.MoveState=N'confirmado') AS confirmedCashMoves,
 CASE WHEN r.ConfirmedPaymentsTotal=ISNULL((SELECT SUM(m.Amount) FROM dbo.CashMoves m WHERE m.PayrollRunId=r.PayrollRunId AND m.MoveType=N'salida' AND m.MoveState=N'confirmado'),0) THEN 1 ELSE 0 END AS recordedMatchesLinkedCash,
 CASE WHEN ISNULL(p.confirmedCount,0)=0 THEN N'sin_pagos_registrados' ELSE N'acumulado_distinto' END AS reason
 FROM dbo.PayrollRuns r OUTER APPLY (
 SELECT SUM(Amount) AS confirmedTotal,COUNT(*) AS confirmedCount
 FROM dbo.PayrollPayments WHERE PayrollRunId=r.PayrollRunId AND Status=N'confirmado') p
 WHERE ABS(ISNULL(r.ConfirmedPaymentsTotal,0)-ISNULL(p.confirmedTotal,0))>0.005
 ORDER BY r.Period,r.PayrollRunId;`);
 const payload=data.recordsets[0][0]?.Payload;
 const state=JSON.parse(payload??'{}');
 const discrepancies=data.recordsets[3]??[];
 const confirmedTestPayrolls=discrepancies.filter(row=>row.testDataConfirmed===true||row.testDataConfirmed===1).length;
 return {readOnly:true,checkedAt:new Date().toISOString(),snapshotAvailable:Boolean(payload&&Object.keys(state).length),issues:auditOperationalState(state),collections:Object.fromEntries(Object.entries(state).filter(([,v])=>Array.isArray(v)).map(([k,v])=>[k,v.length])),staleSessions:data.recordsets[1],payroll:{...data.recordsets[2][0],confirmedTestPayrolls,discrepancies},scope:'Validación del estado operativo guardado y comprobaciones de sesiones y pagos. Los hallazgos históricos requieren revisión; no se corrigen importes automáticamente.'};
}

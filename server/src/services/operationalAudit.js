import {auditOperationalState} from './operationalIntegrity.js';
export async function readOperationalAudit(pool){
 const data=await pool.request().query(`SELECT Payload FROM dbo.ErpState WHERE StateId=1;
 SELECT CONVERT(VARCHAR(10),SessionDate,23) AS sessionDate,Account AS account FROM dbo.CashSessions WHERE Status=N'abierta' AND SessionDate<>CONVERT(DATE,SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time');
 SELECT COUNT(*) AS unverifiedPayrolls FROM dbo.PayrollRuns r WHERE ABS(ISNULL(r.ConfirmedPaymentsTotal,0)-ISNULL((SELECT SUM(p.Amount) FROM dbo.PayrollPayments p WHERE p.PayrollRunId=r.PayrollRunId AND p.Status=N'confirmado'),0))>0.005;`);
 const payload=data.recordsets[0][0]?.Payload;
 const state=JSON.parse(payload??'{}');
 return {readOnly:true,checkedAt:new Date().toISOString(),snapshotAvailable:Boolean(payload&&Object.keys(state).length),issues:auditOperationalState(state),collections:Object.fromEntries(Object.entries(state).filter(([,v])=>Array.isArray(v)).map(([k,v])=>[k,v.length])),staleSessions:data.recordsets[1],payroll:data.recordsets[2][0],scope:'Validación del estado operativo guardado y comprobaciones de sesiones y pagos. Los hallazgos históricos requieren revisión; no se corrigen importes automáticamente.'};
}

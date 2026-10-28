import fs from 'node:fs';
import dotenv from 'dotenv';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase();
try{
 const result=await pool.request().query(`SELECT r.PayrollRunId AS id,r.Period AS period,r.Status AS status,r.Net AS net,r.ConfirmedPaymentsTotal AS headerPaid,
  (SELECT ISNULL(SUM(p.Amount),0) FROM dbo.PayrollPayments p WHERE p.PayrollRunId=r.PayrollRunId AND p.Status=N'confirmado') AS confirmedPaymentReceipts,
  (SELECT COUNT(*) FROM dbo.PayrollPayments p WHERE p.PayrollRunId=r.PayrollRunId AND p.Status=N'confirmado') AS receiptCount,
  (SELECT COUNT(*) FROM dbo.PayrollRunItems i WHERE i.PayrollRunId=r.PayrollRunId) AS workers
  FROM dbo.PayrollRuns r WHERE r.Period=N'TEST-DYN-7929';`);
 fs.writeFileSync(new URL('../../docs/payroll_TEST-DYN-7929_readonly.json',import.meta.url),JSON.stringify({capturedAt:new Date().toISOString(),readOnly:true,runs:result.recordset},null,2));
 console.log(JSON.stringify(result.recordset));
}finally{await pool.close();}

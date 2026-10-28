import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import dotenv from 'dotenv';
import {checkPayrollPayment} from '../src/services/payrollPaymentCheck.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');const pool=await getDatabase();
try{
 const rows=(await pool.request().query(`SELECT TOP(1) r.PayrollRunId AS runId,r.Status AS status,i.EmployeeId AS employeeId FROM dbo.PayrollRuns r JOIN dbo.PayrollRunItems i ON i.PayrollRunId=r.PayrollRunId WHERE r.Period=N'TEST-DYN-7929' ORDER BY i.EmployeeId;
 SELECT CONVERT(VARCHAR(10),SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time',23) AS date;
 SELECT COUNT(*) AS payments FROM dbo.PayrollPayments;`)).recordsets;
 const fixture=rows[0][0];assert.ok(fixture);
 const result=await checkPayrollPayment(pool,fixture.runId,{mutationId:randomUUID(),employeeId:fixture.employeeId,paymentMethod:'efectivo',paymentDate:rows[1][0].date,amount:100});
 assert.equal(result.checks.length,10);
 if(fixture.status==='borrador') assert.equal(result.ready,false);
 assert.equal((await pool.request().query('SELECT COUNT(*) AS payments FROM dbo.PayrollPayments')).recordset[0].payments,rows[2][0].payments);
 console.log(JSON.stringify({readOnly:true,status:fixture.status,ready:result.ready,checks:result.checks,confirmedPaymentsCreated:0}));
}finally{await pool.close();}

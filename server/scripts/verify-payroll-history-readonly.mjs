import dotenv from 'dotenv';
import sql from 'mssql';
import {PAYROLL_PAYMENTS_SQL} from '../src/services/payrollHistorySql.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');const pool=await getDatabase();
try{const runs=(await pool.request().query('SELECT PayrollRunId FROM dbo.PayrollRuns')).recordset;
for(const run of runs){const result=await pool.request().input('PayrollRunId',sql.NVarChar(100),run.PayrollRunId).query(PAYROLL_PAYMENTS_SQL);for(const payment of result.recordset){JSON.parse(payment.allocationsJson||'[]');} }
console.log('PASS consulta real de historial versionado:',runs.length,'planillas. Solo lectura.');}finally{await pool.close();}

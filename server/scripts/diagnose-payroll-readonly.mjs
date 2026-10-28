import assert from 'node:assert/strict';
import { PAYROLL_RUNS_SQL } from '../src/services/payrollReadSql.js';
import dotenv from 'dotenv';
import sql from 'mssql';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase();
try {
 const r=await pool.request().input('IncludeClosed',sql.Bit,1).query(PAYROLL_RUNS_SQL);
 for(const run of r.recordset){ assert.ok(Number.isInteger(run.workersCount)); assert.ok(run.startDate); assert.ok(run.endDate); assert.ok(Number.isFinite(Number(run.employerCostTotal))); }
 console.log('PASS contrato de lectura de planillas: contadores, fechas y costo patronal');
 console.log(JSON.stringify({runs:r.recordset.length,runFields:Object.keys(r.recordset[0]??{})}));
 console.log(JSON.stringify((await pool.request().query(`SELECT OBJECT_ID(N'dbo.usp_PayrollPaymentIntegrityVersion',N'P') AS migration30,OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') AS migration31,OBJECT_ID(N'dbo.usp_SnapshotLinkIntegrityVersion',N'P') AS migration32,HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','CREATE PROCEDURE') AS canCreate; SELECT TOP(1) AppUserId AS id FROM dbo.AppUsers WHERE IsActive=1;`)).recordsets[0]));
 const actor=(await pool.request().query('SELECT TOP(1) AppUserId AS id FROM dbo.AppUsers WHERE IsActive=1')).recordset[0]?.id;
 if(r.recordset[0]&&actor){ const items=await pool.request().input('PayrollRunId',sql.NVarChar(100),r.recordset[0].id).input('ActorId',sql.NVarChar(100),actor).execute('dbo.usp_GetPayrollRunItems'); console.log(JSON.stringify({items:items.recordset.length,itemFields:Object.keys(items.recordset[0]??{})})); }
}finally{await pool.close();}

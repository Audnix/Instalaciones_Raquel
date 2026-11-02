// Only the specific fixtures explicitly confirmed as test data in this chat.
// Default: rehearse and roll back. --apply commits the same bounded maintenance.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import dotenv from 'dotenv';
import sql from 'mssql';
import {cashRequest} from '../src/services/cashTransaction.js';

dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase,database}=await import('../src/config/sqlserver.js');
const apply=process.argv.includes('--apply');
const ids=['PL-2026-10-Q1','pr-2026-10-1','run-test-mvfbrouy'];
const marker='[CIERRE SIMULADO - DATOS DE PRUEBA]';
const explanation=marker+' Usuario confirmó en chat que son datos de prueba. Se utiliza el saldo calculado del fixture como conteo simulado; no es conciliación con un banco real.';
let tx,ended=false;
try{
 const pool=await getDatabase();assert.ok(pool);
 assert.equal((await pool.request().query('SELECT DB_NAME() AS name')).recordset[0].name,'Instalaciones Raquel');
 tx=new sql.Transaction(pool);tx.on('rollback',()=>{ended=true;});await tx.begin();
 const request=()=>new sql.Request(tx);
 const scoped=()=>{const req=request();ids.forEach((id,i)=>req.input('Run'+i,sql.NVarChar(100),id));return req;};
 const before=(await scoped().query(`SELECT PayrollRunId AS id,Status AS status,ConfirmedPaymentsTotal AS recordedTotal,Net AS net,
 (SELECT COUNT(*) FROM dbo.PayrollHistoryEvents h WHERE h.PayrollRunId=r.PayrollRunId AND h.EventType=N'clasificacion_prueba') AS classifications
 FROM dbo.PayrollRuns r WITH(UPDLOCK,HOLDLOCK) WHERE PayrollRunId IN(@Run0,@Run1,@Run2);
 SELECT s.CashSessionId AS id,s.Status AS status,s.Currency AS currency,s.Explanation AS explanation,
 s.OpeningBalance+ISNULL((SELECT SUM(CASE WHEN m.MoveType=N'entrada' THEN m.Amount ELSE -m.Amount END)
 FROM dbo.CashMoves m WHERE m.SessionId=s.CashSessionId AND m.MoveState=N'confirmado' AND ISNULL(m.DocumentType,N'')<>N'apertura'),0) AS expected
 FROM dbo.CashSessions s WITH(UPDLOCK,HOLDLOCK) WHERE s.Account=N'banco' AND s.SessionDate=CONVERT(date,'2026-10-27')
 AND (s.Status=N'abierta' OR s.Explanation LIKE N'[[]CIERRE SIMULADO - DATOS DE PRUEBA]%');
 SELECT TOP(1) AppUserId AS id FROM dbo.AppUsers WHERE IsActive=1 AND Hierarchy=N'superadmin' ORDER BY AppUserId;`)).recordsets;
 assert.equal(before[0].length,3,'Deben existir exactamente los tres fixtures confirmados.');
 assert.equal(before[1].length,1,'La sesión de banco debe ser inequívoca.');
 assert.ok(before[2][0],'Se requiere un administrador existente como responsable del cierre simulado.');
 const session=before[1][0];
 assert.ok(['C$','NIO'].includes(session.currency),'Moneda distinta de la observada.');
 assert.ok(Math.abs(Number(session.expected)-4152.67)<0.005,'El saldo cambió desde la captura; revisar antes de cerrar.');
 const beforeFile=new URL('../../docs/datos_prueba_antes_mantenimiento.json',import.meta.url);
 if(apply&&!fs.existsSync(beforeFile))fs.writeFileSync(beforeFile,JSON.stringify({database:'Instalaciones Raquel',capturedAt:new Date().toISOString(),records:before.slice(0,2)},null,2));
 if(session.status==='abierta'){
  const closed=(await cashRequest(pool,{transaction:tx})
   .input('SessionId',sql.NVarChar(100),session.id).input('CountedCash',sql.Decimal(19,4),session.expected)
   .input('Explanation',sql.NVarChar(1000),explanation)
   .input('ActorId',sql.NVarChar(100),before[2][0].id)
   .input('ActorName',sql.NVarChar(240),'Mantenimiento de pruebas autorizado en chat')
   .execute('dbo.usp_ArquearYCerrarCaja')).recordset[0];
  assert.equal(Number(closed.Difference),0);
 }else assert.ok(session.explanation?.startsWith(marker));
 for(const run of before[0]){
  if(run.classifications)continue;
  await request().input('Run',sql.NVarChar(100),run.id).input('Status',sql.NVarChar(30),run.status)
   .input('Description',sql.NVarChar(1000),'Usuario confirmó en chat que esta planilla corresponde a datos de prueba. Se conserva la inconsistencia histórica sin crear pagos, borrar datos ni modificar acumulados.')
   .query(`INSERT dbo.PayrollHistoryEvents(PayrollRunId,ActorId,ActorName,EventType,PreviousStatus,NewStatus,Description)
    VALUES(@Run,N'mantenimiento-pruebas',N'Mantenimiento de pruebas autorizado en chat',N'clasificacion_prueba',@Status,@Status,@Description);`);
 }
 const after=(await scoped().input('SessionId',sql.NVarChar(100),session.id).query(`SELECT PayrollRunId AS id,Status AS status,ConfirmedPaymentsTotal AS recordedTotal,Net AS net,
 (SELECT COUNT(*) FROM dbo.PayrollHistoryEvents h WHERE h.PayrollRunId=r.PayrollRunId AND h.EventType=N'clasificacion_prueba') AS classifications
 FROM dbo.PayrollRuns r WHERE PayrollRunId IN(@Run0,@Run1,@Run2);
 SELECT Status AS status,Explanation AS explanation FROM dbo.CashSessions WHERE CashSessionId=@SessionId;`)).recordsets;
 for(const run of before[0]){const updated=after[0].find(row=>row.id===run.id);assert.equal(updated.status,run.status);assert.equal(updated.recordedTotal,run.recordedTotal);assert.equal(updated.net,run.net);assert.equal(updated.classifications,1);}
 assert.equal(after[1][0].status,'cerrada');assert.ok(after[1][0].explanation.startsWith(marker));
 const report={committed:apply,simulated:true,checkedAt:new Date().toISOString(),bankSessionClosed:true,simulatedBalance:4152.67,payrollsClassified:3,payrollAmountsChanged:false,paymentsCreated:false,recordsDeleted:false};
 if(apply){await tx.commit();ended=true;fs.writeFileSync(new URL('../../docs/mantenimiento_datos_prueba.json',import.meta.url),JSON.stringify(report,null,2));}
 else{await tx.rollback();ended=true;}
 console.log(JSON.stringify(report));
}finally{if(tx&&!ended&&tx._acquiredConnection)await tx.rollback();if(database)await database.close();}

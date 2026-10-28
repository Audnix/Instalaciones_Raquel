import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import sql from 'mssql';
import dotenv from 'dotenv';
import {cashRequest} from '../src/services/cashTransaction.js';
import {CASH_LEDGER_CTE,CASH_SUGGESTED_OPENING_SQL} from '../src/services/cashLedgerSql.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase();if(!pool) throw Error('SQL no configurado');
const counts=async()=> (await pool.request().query(`SELECT
 (SELECT COUNT(*) FROM dbo.CashSessions) AS sessions,
 (SELECT COUNT(*) FROM dbo.CashMoves) AS movements,
 (SELECT COUNT(*) FROM dbo.PayrollPayments) AS payments`)).recordset[0];
const before=await counts();const tx=new sql.Transaction(pool);let aborted=false;
tx.on('rollback',()=>{aborted=true;});
try{
 await tx.begin();
 const check=(await new sql.Request(tx).query(`SELECT TOP(2) AppUserId AS id,Name AS name FROM dbo.AppUsers WHERE IsActive=1 ORDER BY AppUserId;
 SELECT COUNT(*) AS openCount FROM dbo.CashSessions WHERE Account=N'caja' AND Status=N'abierta';`)).recordsets;
 assert.equal(check[1][0].openCount,0,'Hay una caja operativa abierta: no se ejecuta el fixture');
 const actor=check[0][0];assert.ok(actor,'Falta responsable activo');
 const operationKey='test-cash-'+randomUUID();
 const opening=()=>cashRequest(pool,{transaction:tx}).input('Account',sql.NVarChar(30),'caja').input('Currency',sql.NVarChar(10),'C$').input('InitialBalance',sql.Decimal(19,4),1000)
  .input('ActorId',sql.NVarChar(100),actor.id).input('ActorName',sql.NVarChar(240),'Prueba reversible de Caja')
  .input('OperationKey',sql.NVarChar(160),operationKey).execute('dbo.usp_AbrirCaja');
 const opened=(await opening()).recordset[0],again=(await opening()).recordset[0];
 assert.equal(again.CashSessionId,opened.CashSessionId);assert.equal(again.Resultado,'repetida');
 const session=opened.CashSessionId;console.log('PASS apertura y reintento sin duplicacion');
 async function move(type,amount,key){return (await cashRequest(pool,{transaction:tx})
  .input('Account',sql.NVarChar(30),'caja').input('MoveType',sql.NVarChar(10),type).input('Amount',sql.Decimal(19,4),amount)
  .input('Concept',sql.NVarChar(300),'Prueba de '+type).input('Method',sql.NVarChar(30),'efectivo')
  .input('MoveTime',sql.NVarChar(8),'12:00:00')
  .input('DocumentType',sql.NVarChar(40),'otro').input('SessionId',sql.NVarChar(100),session)
  .input('ActorId',sql.NVarChar(100),actor.id).input('ActorName',sql.NVarChar(240),'Prueba reversible de Caja')
  .input('OperationKey',sql.NVarChar(160),key).execute('dbo.usp_RegistrarMovimientoCaja')).recordset[0];}
 const entryKey='test-entry-'+randomUUID();const entry=await move('entrada',500,entryKey);const repeated=await move('entrada',500,entryKey);
 assert.equal(entry.CashMoveId,repeated.CashMoveId);
 const exit=await move('salida',200,'test-exit-'+randomUUID());
 const ledger=(await new sql.Request(tx).input('Session',sql.NVarChar(100),session).query(`${CASH_LEDGER_CTE}
  SELECT CashMoveId,Entrada,Salida,SaldoAcumulado FROM CashLedger WHERE SessionId=@Session;
 `)).recordset;
 assert.equal(ledger.length,3);assert.equal(ledger.find(r=>r.CashMoveId===entry.CashMoveId).SaldoAcumulado,1500);
 assert.equal(ledger.find(r=>r.CashMoveId===exit.CashMoveId).SaldoAcumulado,1300);
 console.log('PASS entrada 500, salida 200, saldo 1300 y movimiento visible');
 await assert.rejects(move('entrada',501,entryKey),e=>e.number===50611);
 console.log('PASS misma clave con otros datos se rechaza');
 await assert.rejects(move('salida',1301,'test-overdraw-'+randomUUID()),e=>e.number===50609);
 console.log('PASS no permite salida superior al saldo');
 const close=(await cashRequest(pool,{transaction:tx}).input('SessionId',sql.NVarChar(100),session).input('CountedCash',sql.Decimal(19,4),1300)
  .input('ActorId',sql.NVarChar(100),actor.id).input('ActorName',sql.NVarChar(240),'Prueba reversible de Caja')
  .execute('dbo.usp_ArquearYCerrarCaja')).recordset[0];
 assert.equal(close.ExpectedCash,1300);assert.equal(close.Difference,0);assert.equal(close.Resultado,'cerrada');
 console.log('PASS arqueo y cierre sin diferencia');
 const suggested=(await new sql.Request(tx).input('Account',sql.NVarChar(30),'caja').query(CASH_SUGGESTED_OPENING_SQL)).recordset[0];
 assert.equal(suggested.suggestedOpening,1300);console.log('PASS saldo sugerido para la siguiente apertura');
 await assert.rejects(move('entrada',50,'test-closed-'+randomUUID()),e=>e.number===50572);
 console.log('PASS no registra movimientos en la sesion cerrada');
 const reopened=(await cashRequest(pool,{transaction:tx}).input('Account',sql.NVarChar(30),'caja').input('Currency',sql.NVarChar(10),'C$')
  .input('InitialBalance',sql.Decimal(19,4),1300).input('ActorId',sql.NVarChar(100),actor.id).input('ActorName',sql.NVarChar(240),'Prueba reversible de Caja')
  .input('OperationKey',sql.NVarChar(160),'test-reopen-'+randomUUID()).execute('dbo.usp_AbrirCaja')).recordset[0];
 const last=(await new sql.Request(tx).input('Session',sql.NVarChar(100),reopened.CashSessionId)
  .query(`${CASH_LEDGER_CTE} SELECT SaldoAcumulado FROM CashLedger WHERE SessionId=@Session`)).recordset[0];
 assert.equal(last.SaldoAcumulado,1300);console.log('PASS reapertura mantiene 1300 sin duplicar el saldo anterior');
}finally{
 if(!aborted&&tx._acquiredConnection) await tx.rollback();
 const after=await counts();assert.deepEqual(after,before,'Los datos deben conservarse tras revertir');
 console.log('ROLLBACK: registros conservados',JSON.stringify(after));await pool.close();
}

import assert from 'node:assert/strict';
import sql from 'mssql';
import dotenv from 'dotenv';
import {randomUUID} from 'node:crypto';
import {cashRequest} from '../src/services/cashTransaction.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase();const tx=new sql.Transaction(pool);let ended=false;
tx.on('rollback',()=>{ended=true});
try{await tx.begin();
 const request=()=>new sql.Request(tx);
 const sets=(await request().query("SELECT CONVERT(VARCHAR(10),SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time',23) AS today; SELECT TOP(1) CashSessionId,CONVERT(VARCHAR(10),SessionDate,23) AS date FROM dbo.CashSessions WHERE Account=N'caja' AND Status=N'abierta'; SELECT TOP(1) AppUserId FROM dbo.AppUsers WHERE IsActive=1; SELECT COUNT(*) AS count FROM dbo.CashMoves;")).recordsets;
 const current=sets[1][0];assert.ok(current&&current.date!==sets[0][0].today,'Esta prueba requiere la sesión antigua observada; no crea ni cambia sesiones');
 await assert.rejects(cashRequest(pool,{transaction:tx}).input('Account',sql.NVarChar(30),'caja').input('MoveType',sql.NVarChar(10),'entrada').input('Amount',sql.Decimal(19,4),1).input('Concept',sql.NVarChar(300),'Prueba rechazada').input('Method',sql.NVarChar(30),'efectivo').input('DocumentType',sql.NVarChar(40),'otro').input('SessionId',sql.NVarChar(100),current.CashSessionId).input('ActorId',sql.NVarChar(100),sets[2][0].AppUserId).input('OperationKey',sql.NVarChar(160),'test-stale-'+randomUUID()).execute('dbo.usp_RegistrarMovimientoCaja'),e=>e.number===50612&&e.message.includes('arqueo y cierre'));
 assert.equal((await request().query('SELECT COUNT(*) AS count FROM dbo.CashMoves')).recordset[0].count,sets[3][0].count);
 console.log('PASS sesión antigua rechazada con instrucción de arqueo; ningún movimiento creado');
}finally{if(!ended&&tx._acquiredConnection)await tx.rollback();await pool.close();}

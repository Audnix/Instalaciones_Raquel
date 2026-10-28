// Ejecuta la consulta REAL de la API sobre valores sinteticos, sin escrituras.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import dotenv from 'dotenv';
import sql from 'mssql';
import {CASH_LEDGER_CTE,CASH_SUMMARY_SQL} from '../src/services/cashLedgerSql.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase(); if(!pool) throw Error('SQL Server no configurado');
const query=CASH_SUMMARY_SQL;
const fixture=`WITH CashLedger AS (
  SELECT CONVERT(NVARCHAR(30),'caja') AS Account, CONVERT(NVARCHAR(100),id) AS CashMoveId,
    CONVERT(DATETIMEOFFSET(3),date) AS MoveDate, CONVERT(TIME(0),'00:00:00') AS MoveTime,
    CONVERT(NVARCHAR(40),doc) AS DocumentType, CONVERT(NVARCHAR(20),type) AS MoveType,
    CONVERT(DECIMAL(19,4),entry) AS Entrada,CONVERT(DECIMAL(19,4),exitAmount) AS Salida,
    CONVERT(DECIMAL(19,4),balance) AS SaldoAcumulado, ROW_NUMBER() OVER(ORDER BY id) AS LedgerOrder
  FROM (VALUES
    ('a','2026-10-20T00:00:00-06:00','apertura','entrada',1000,0,1000),
    ('b','2026-10-20T12:00:00-06:00','cobro','entrada',500,0,1500),
    ('c','2026-10-20T23:00:00-06:00','otro','salida',0,200,1300),
    ('d','2026-10-21T00:00:00-06:00','apertura','entrada',1300,0,1300),
    ('e','2026-10-21T12:00:00-06:00','otro','salida',0,100,1200)
  ) v(id,date,doc,type,entry,exitAmount,balance)
)`;
try{
  for(const [from,to,expected] of [
    ['2026-10-20','2026-10-20',{saldoAnterior:0,aperturas:1000,entradas:500,salidas:200,movimientos:3}],
    ['2026-10-21','2026-10-21',{saldoAnterior:1300,aperturas:0,entradas:0,salidas:100,movimientos:2}],
    ['2026-10-20','2026-10-21',{saldoAnterior:0,aperturas:1000,entradas:500,salidas:300,movimientos:5}]
  ]){
    const r=await pool.request().input('Account',sql.NVarChar(30),'caja').input('FromDate',sql.Date,from).input('ToDate',sql.Date,to)
      .query(query.replace(CASH_LEDGER_CTE,fixture));
    assert.deepEqual(r.recordset[0],expected);console.log('PASS',from,to,JSON.stringify(r.recordset[0]));
  }
}finally{await pool.close();}

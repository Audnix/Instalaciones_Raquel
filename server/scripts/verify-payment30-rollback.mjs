// Comprueba el cuerpo EXACTO de la migracion 30 sin instalarla. Usa una
// distribucion temporal y revierte cada fixture; no valida despliegue ni permisos HTTP.
import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import assert from 'node:assert/strict';
import dotenv from 'dotenv';
import sql from 'mssql';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase();
if(!pool) throw Error('SQL Server no configurado');
const migration=fs.readFileSync(new URL('../../Database/SQLServer_Completo/30_pagos_individuales_atomicos.sql',import.meta.url),'utf8');
const body=migration.split('WITH EXECUTE AS OWNER\nAS\n')[1]?.split('\nGO\n')[0].replaceAll('dbo.PayrollPaymentAllocations','#PaymentAllocations');
if(!body) throw Error('No se encontro el cuerpo del procedimiento');
const cases=[];
async function scenario(name,fn){
  const tx=new sql.Transaction(pool); let rolledBack=false;
  tx.on('rollback',()=>{rolledBack=true;});
  await tx.begin();
  try {
    await new sql.Request(tx).batch(`CREATE TABLE #PaymentAllocations(PaymentId NVARCHAR(100), EmployeeId NVARCHAR(100), Amount DECIMAL(19,4));`);
    const fixture=await new sql.Request(tx).query(`
      SELECT TOP(1) r.PayrollRunId AS runId FROM dbo.PayrollRuns r
      WHERE r.Status=N'calculada' AND NOT EXISTS(SELECT 1 FROM dbo.PayrollPayments p WHERE p.PayrollRunId=r.PayrollRunId)
      ORDER BY r.PayrollRunId;
      SELECT TOP(1) AppUserId AS actorId FROM dbo.AppUsers WHERE IsActive=1;
    `);
    const run=fixture.recordsets[0][0]?.runId, actor=fixture.recordsets[1][0]?.actorId;
    assert.ok(run&&actor,'Se necesita una planilla calculada sin pagos para el fixture reversible');
    const employee=(await new sql.Request(tx).input('Run',sql.NVarChar(100),run).query(`
      UPDATE dbo.PayrollRuns SET Status=N'aprobada',CalculatedAt=SYSUTCDATETIME(),CalculationStale=0,
        TotalDeductions=(SELECT SUM(TotalDeductions) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run),
        Net=(SELECT SUM(Net) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run)
      WHERE PayrollRunId=@Run;
      SELECT TOP(1) EmployeeId AS id, Net AS net FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run AND Net>100 ORDER BY EmployeeId;
    `)).recordset[0];
    assert.ok(employee,'Falta trabajador con neto para el fixture');
    await new sql.Request(tx).input('Actor',sql.NVarChar(100),actor).query(`
      IF EXISTS(SELECT 1 FROM dbo.CashSessions WHERE Status=N'abierta') THROW 50999,'Cierra las sesiones operativas antes de ejecutar esta prueba.',1;
      INSERT dbo.CashSessions(CashSessionId,Account,Currency,SessionDate,OpeningBalance,Status,OpenedByAppUserId)
      VALUES(N'test30-caja',N'caja',N'C$',CONVERT(DATE,GETDATE()),1000000,N'abierta',@Actor),
            (N'test30-banco',N'banco',N'C$',CONVERT(DATE,GETDATE()),1000000,N'abierta',@Actor);
    `);
    const date=(await new sql.Request(tx).query("SELECT CONVERT(VARCHAR(10),GETDATE(),23) AS date")).recordset[0].date;
    const pay=async(overrides={})=>{
      const data={key:randomUUID(),employeeId:employee.id,amount:50,method:'efectivo',reference:randomUUID(),notes:null,actorId:actor,...overrides};
      const req=new sql.Request(tx)
        .input('PayrollRunId',sql.NVarChar(100),run).input('Amount',sql.Decimal(19,4),data.amount)
        .input('PaymentMethod',sql.NVarChar(60),data.method).input('PaymentReference',sql.NVarChar(120),data.reference)
        .input('PaymentDate',sql.Date,date).input('Notes',sql.NVarChar(1000),data.notes)
        .input('IdempotencyKey',sql.UniqueIdentifier,data.key).input('EmployeeId',sql.NVarChar(100),data.employeeId)
        .input('ActorId',sql.NVarChar(100),data.actorId).input('ActorName',sql.NVarChar(240),'Prueba reversible 30');
      return (await req.query(body)).recordset[0];
    };
    await fn({tx,pay,employee,run});
    cases.push({name,result:'PASS'}); console.log('PASS',name);
  } finally {if(!rolledBack) await tx.rollback();}
}
try {
  await scenario('reintento crea un solo recibo, movimiento y asiento',async({tx,pay,run})=>{
    const key=randomUUID(),reference=randomUUID();
    const first=await pay({key,reference}); const repeated=await pay({key,reference});
    assert.equal(first.PaymentId,repeated.PaymentId); assert.equal(repeated.Resultado,'repetida');
    const r=(await new sql.Request(tx).input('Run',sql.NVarChar(100),run).query(`SELECT
      (SELECT COUNT(*) FROM dbo.PayrollPayments WHERE PayrollRunId=@Run) AS payments,
      (SELECT COUNT(*) FROM dbo.CashMoves WHERE PayrollRunId=@Run AND OperationKey LIKE 'pago-nomina:%') AS moves,
      (SELECT COUNT(*) FROM dbo.AccountingEntries WHERE PayrollRunId=@Run AND OperationKey LIKE 'pago-nomina:%') AS entries;`)).recordset[0];
    assert.deepEqual(r,{payments:1,moves:1,entries:1});
  });
  await scenario('misma clave con otro importe produce conflicto',async({pay})=>{
    const key=randomUUID(),reference=randomUUID();await pay({key,reference});
    await assert.rejects(pay({key,reference,amount:51}),e=>e.number===50602);
  });
  await scenario('pago individual no puede superar el pendiente personal',async({pay,employee})=>{
    await pay({amount:50}); await assert.rejects(pay({amount:employee.net}),e=>e.number===50605);
  });
  await scenario('pagos en caja y banco conservan sus importes independientes',async({tx,pay})=>{
    const cash=await pay();const bank=await pay({method:'transferencia_bancaria',amount:25});
    const r=(await new sql.Request(tx).input('Cash',sql.NVarChar(100),cash.CashMoveId).input('Bank',sql.NVarChar(100),bank.CashMoveId)
      .query('SELECT Account AS account,Amount AS amount FROM dbo.CashMoves WHERE CashMoveId IN (@Cash,@Bank) ORDER BY Account')).recordset;
    assert.deepEqual(r,[{account:'banco',amount:25},{account:'caja',amount:50}]);
  });
  await scenario('dispersion general se distribuye y reduce el pendiente individual',async({tx,pay,employee})=>{
    await pay({employeeId:null,amount:50});
    const allocated=(await new sql.Request(tx).input('Employee',sql.NVarChar(100),employee.id)
      .query('SELECT ISNULL(SUM(Amount),0) AS amount FROM #PaymentAllocations WHERE EmployeeId=@Employee')).recordset[0].amount;
    assert.equal(allocated,50);
    await assert.rejects(pay({amount:employee.net}),e=>e.number===50605);
  });
  await scenario('se rechaza pagar sin fondos confirmados',async({tx,pay})=>{
    await new sql.Request(tx).query("UPDATE dbo.CashSessions SET OpeningBalance=0 WHERE CashSessionId=N'test30-caja'");
    await assert.rejects(pay(),e=>e.number===50609);
  });
  await scenario('una referencia repetida no duplica pago con otra clave',async({pay})=>{
    const reference=randomUUID();await pay({reference});
    await assert.rejects(pay({reference,notes:'otro texto'}),e=>e.number===50607);
  });
  await scenario('un fallo al insertar el recibo revierte el movimiento previo',async({pay,run})=>{
    await assert.rejects(pay({actorId:'test30-usuario-inexistente'}),e=>e.number===547);
    const r=(await pool.request().input('Run',sql.NVarChar(100),run).query(`SELECT
      (SELECT COUNT(*) FROM dbo.PayrollPayments WHERE PayrollRunId=@Run) AS payments,
      (SELECT COUNT(*) FROM dbo.CashMoves WHERE PayrollRunId=@Run AND OperationKey LIKE 'pago-nomina:%') AS moves;`)).recordset[0];
    assert.deepEqual(r,{payments:0,moves:0});
  });
} finally {await pool.close();}
console.log(JSON.stringify({cases,rolledBack:true,installed:false},null,2));

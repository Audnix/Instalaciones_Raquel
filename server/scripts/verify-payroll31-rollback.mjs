import fs from 'node:fs';
import assert from 'node:assert/strict';
import sql from 'mssql';
import dotenv from 'dotenv';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase();if(!pool)throw Error('SQL no configurado');
const source=fs.readFileSync(new URL('../../Database/SQLServer_Completo/31_reglas_periodo_y_devengo_nomina.sql',import.meta.url),'utf8');
const body=(name)=>source.split('CREATE OR ALTER PROCEDURE dbo.'+name)[1].split('WITH EXECUTE AS OWNER\nAS\n')[1].split('\nGO\n')[0];
const calcBody=body('usp_CalculatePayroll').replaceAll('dbo.PayrollRulesCatalog','#Rules');
const flowBody=body('usp_TransitionPayrollStatus').replaceAll('dbo.PayrollInstitutionalObligations','#Obligations');
async function scenario(name,fn){
 const tx=new sql.Transaction(pool);let aborted=false;tx.on('rollback',()=>{aborted=true;});await tx.begin();
 try{
  await new sql.Request(tx).batch(`SELECT * INTO #Rules FROM dbo.PayrollRulesCatalog;
   CREATE TABLE #Obligations(ObligationId NVARCHAR(100),PayrollRunId NVARCHAR(100),EntityName NVARCHAR(50),
   PeriodLabel NVARCHAR(50),BaseAmount DECIMAL(19,4),PayableAmount DECIMAL(19,4),DueDate DATE NULL,Status NVARCHAR(30),PaymentReceiptRef NVARCHAR(200));`);
  const rows=(await new sql.Request(tx).query(`SELECT TOP(1) r.PayrollRunId AS id,r.PreparedByAppUserId AS preparedBy FROM dbo.PayrollRuns r
   WHERE r.Status=N'calculada' AND NOT EXISTS(SELECT 1 FROM dbo.AccountingEntries a WHERE a.PayrollRunId=r.PayrollRunId)
   AND NOT EXISTS(SELECT 1 FROM dbo.PayrollPayments p WHERE p.PayrollRunId=r.PayrollRunId) ORDER BY r.PayrollRunId;
   SELECT AppUserId AS id FROM dbo.AppUsers WHERE IsActive=1 ORDER BY AppUserId;`)).recordsets;
  const run=rows[0][0];assert.ok(run,'Se necesita planilla calculada sin devengo ni pagos para el fixture');
  const calculator=rows[1][0].id,approver=rows[1].find(a=>a.id!==calculator&&a.id!==run.preparedBy)?.id;
  assert.ok(approver,'Falta segundo responsable para aprobar');
  const revision=async()=> (await new sql.Request(tx).input('Run',sql.NVarChar(100),run.id)
   .query('SELECT Revision FROM dbo.PayrollRuns WHERE PayrollRunId=@Run')).recordset[0].Revision;
  const request=async(actor)=>new sql.Request(tx).input('PayrollRunId',sql.NVarChar(100),run.id)
   .input('ExpectedRevision',sql.VarBinary(8),await revision()).input('ActorId',sql.NVarChar(100),actor)
   .input('ActorName',sql.NVarChar(240),'Prueba reversible 31');
  const calculate=async()=> (await (await request(calculator)).query(calcBody)).recordset[0];
  const transition=async(target,actor=approver)=> (await (await request(actor)).input('TargetStatus',sql.NVarChar(30),target)
   .input('Notes',sql.NVarChar(1000),'Prueba reversible de integridad').query(flowBody)).recordset[0];
  await fn({tx,run,calculate,transition,calculator,approver});
  console.log('PASS',name);
 }finally{if(!aborted)await tx.rollback();}
}
try{
 await scenario('calculo con reglas del periodo conserva cabecera, neto y explicacion',async({tx,run,calculate})=>{
  await calculate();const r=(await new sql.Request(tx).input('Run',sql.NVarChar(100),run.id).query(`SELECT r.Gross,r.TotalDeductions,r.Net,
   (SELECT SUM(Net) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run) AS itemNet,
   (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run AND JSON_QUERY(CalculationExplanationJson,'$.reglas_aplicadas') IS NOT NULL) AS snapshots,
   (SELECT COUNT(*) FROM dbo.PayrollRunItems WHERE PayrollRunId=@Run) AS items
   FROM dbo.PayrollRuns r WHERE PayrollRunId=@Run`)).recordset[0];
  assert.equal(Math.round((r.Gross-r.TotalDeductions)*100),Math.round(r.Net*100));assert.equal(r.itemNet,r.Net);assert.equal(r.snapshots,r.items);
 });
 await scenario('una regla sin verificar bloquea en vez de inventar una tasa',async({tx,calculate})=>{
  await new sql.Request(tx).query("UPDATE #Rules SET IsVerified=0 WHERE RuleCode=N'INSS_LABORAL'");
  await assert.rejects(calculate(),e=>e.number===50620);
 });
 await scenario('IR se lee del catalogo y no de una tarifa codificada',async({tx,run,calculate})=>{
  await new sql.Request(tx).query(`UPDATE #Rules SET ParameterJson=N'{"brackets":[{"from":0.01,"to":null,"rate":0,"base":0,"excess":0}]}' WHERE RuleCode=N'IR_PROGRESIVO'`);
  await calculate();const r=(await new sql.Request(tx).input('Run',sql.NVarChar(100),run.id).query('SELECT IncomeTax FROM dbo.PayrollRuns WHERE PayrollRunId=@Run')).recordset[0];assert.equal(r.IncomeTax,0);
 });
 await scenario('aprobar separa neto, retenciones y patronales sin duplicar bruto',async({tx,run,calculate,transition})=>{
  await calculate();await transition('revisada');await transition('aprobada');
  const result=(await new sql.Request(tx).input('Run',sql.NVarChar(100),run.id).query(`SELECT r.Net,r.Gross,r.InssLaboral,r.IncomeTax,r.Inatec,
   (SELECT SUM(Credit) FROM dbo.AccountingEntries WHERE PayrollRunId=@Run AND CreditAccount=N'Sueldos por pagar') AS salaryDebt,
   (SELECT SUM(Debit) FROM dbo.AccountingEntries WHERE PayrollRunId=@Run AND DebitAccount=N'Nómina') AS salaryExpense,
   (SELECT SUM(Credit) FROM dbo.AccountingEntries WHERE PayrollRunId=@Run AND CreditAccount=N'IR por pagar') AS taxDebt,
   (SELECT SUM(Credit) FROM dbo.AccountingEntries WHERE PayrollRunId=@Run AND CreditAccount=N'INATEC por pagar') AS inatecDebt
   FROM dbo.PayrollRuns r WHERE PayrollRunId=@Run`)).recordset[0];
  assert.equal(result.salaryDebt,result.Net);assert.equal(result.salaryExpense,result.Gross);assert.equal(result.taxDebt,result.IncomeTax);assert.equal(result.inatecDebt,result.Inatec);
 });
 await scenario('quien calcula no puede aprobar su propio calculo',async({calculate,transition,calculator})=>{
  await calculate();await transition('revisada');await assert.rejects(transition('aprobada',calculator),e=>e.number===50511);
 });
 await scenario('tras aprobar no se permite retroceder y conservar un devengo anterior',async({calculate,transition})=>{
  await calculate();await transition('revisada');await transition('aprobada');await assert.rejects(transition('borrador'),e=>e.number===50621);
 });
 await scenario('reglas historicas del periodo sirven aunque su vigencia ya haya terminado hoy',async({tx,run,calculate})=>{
  await new sql.Request(tx).input('Run',sql.NVarChar(100),run.id).query(`UPDATE #Rules SET EffectiveTo=(SELECT EndDate FROM dbo.PayrollRuns WHERE PayrollRunId=@Run),Status=N'historica'`);
  await calculate();
 });
 await scenario('no aplica al periodo una regla que inicia despues',async({tx,run,calculate})=>{
  await new sql.Request(tx).input('Run',sql.NVarChar(100),run.id).query(`UPDATE #Rules SET EffectiveFrom=DATEADD(DAY,1,(SELECT EndDate FROM dbo.PayrollRuns WHERE PayrollRunId=@Run)) WHERE RuleCode=N'INSS_LABORAL'`);
  await assert.rejects(calculate(),e=>e.number===50620);
 });
 await scenario('una cabecera marcada pagada sin recibos no puede conciliarse',async({tx,run,transition})=>{
  await new sql.Request(tx).input('Run',sql.NVarChar(100),run.id).query("UPDATE dbo.PayrollRuns SET Status=N'pago_registrado',ConfirmedPaymentsTotal=Net WHERE PayrollRunId=@Run");
  await assert.rejects(transition('conciliada'),e=>[50597,50621].includes(e.number));
 });
}finally{await pool.close();}
console.log('Todos los fixtures revertidos; migracion 31 NO instalada.');

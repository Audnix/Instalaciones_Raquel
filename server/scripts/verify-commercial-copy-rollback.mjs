import {readProductionSource} from '../src/services/productionSource.js';
import {productionDraft} from '../../src/lib/productionDraft.ts';
import {readSaleBalance} from '../src/services/saleReceipt.js';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import sql from 'mssql';
import dotenv from 'dotenv';
import {allocateInventory} from '../../src/lib/inventoryAllocation.ts';
import {cashRequest} from '../src/services/cashTransaction.js';
import {validateTradeChange} from '../src/services/moduleTradeIntegrity.js';
import {saveStateSnapshot,revisionToHex} from '../src/services/stateSnapshot.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
// This test never accepts the operational database as its destination.
const target='Instalaciones_Raquel_Prueba_20261030';
process.env.DB_NAME=target;
const {getDatabase,database}=await import('../src/config/sqlserver.js');
let tx,aborted=false,before;
const token=()=>randomUUID();
const checks=[];
try {
 const pool=await getDatabase();
 assert.equal((await pool.request().query('SELECT DB_NAME() AS name')).recordset[0].name,target);
 const inspect=async()=> (await pool.request().query(`SELECT CONVERT(varchar(64),HASHBYTES('SHA2_256',Payload),2) AS hash,Revision FROM dbo.ErpState WHERE StateId=1;
 SELECT (SELECT COUNT(*) FROM dbo.Purchases) AS purchases,(SELECT COUNT(*) FROM dbo.Proformas) AS proformas,
 (SELECT COUNT(*) FROM dbo.Sales) AS sales,(SELECT COUNT(*) FROM dbo.ProductionOrders) AS production,
 (SELECT COUNT(*) FROM dbo.CashMoves) AS cash,(SELECT COUNT(*) FROM dbo.InventoryLots) AS lots;`)).recordsets;
 before=await inspect();
 tx=new sql.Transaction(pool);tx.on('rollback',()=>{aborted=true;});await tx.begin();
 const request=()=>new sql.Request(tx);
 const load=async()=>{const row=(await request().query('SELECT Payload,Revision FROM dbo.ErpState WHERE StateId=1')).recordset[0];return {state:JSON.parse(row.Payload),revision:revisionToHex(row.Revision)};};
 const adapter={on:(...args)=>tx.on(...args),begin:async()=>{},commit:async()=>{},rollback:()=>tx.rollback()};
 const save=async(next,previous,module)=>{
  if(module)validateTradeChange(next,previous,module);
  const {revision}=await load();
  await saveStateSnapshot(pool,JSON.stringify(next),revision,{transaction:adapter,request});
  return (await load()).state;
 };
 let state=(await load()).state;
 const product=state.products.find(p=>Number.isFinite(p.unitPrice)&&p.unitPrice>0);assert.ok(product,'Se necesita un producto con precio positivo.');
 const date=new Date().toISOString(),actor='Prueba reversible comercial',purchaseId='test-purchase-'+token();
 let next=structuredClone(state);
 next.purchases.unshift({id:purchaseId,purchaseNumber:'TEST-OC-'+token(),supplierName:'Proveedor de prueba',items:[{productId:product.id,quantity:2,unitPrice:10}],total:20,status:'received',purchaseDate:date,createdBy:actor});
 next.lots.push({id:'test-lot-'+token(),productId:product.id,quantity:2,unitCost:10,entryDate:date,warehouseId:'Bodega central'});
 next.kardex.unshift({id:'test-kx-'+token(),productId:product.id,type:'entrada',quantity:2,unitCost:10,date,reason:'Recepción de prueba',userName:actor});
 next.accounting.unshift({id:'test-as-'+token(),entryNumber:'TEST-AS-'+token(),description:'Recepción de prueba',debit:20,credit:20,debitAccount:'Inventario',creditAccount:'Cuentas por pagar',entryDate:date,referenceType:'purchase',referenceId:purchaseId});
 state=await save(next,state,'compras');
 assert.equal((await request().input('Id',sql.NVarChar(100),purchaseId).query('SELECT Status FROM dbo.Purchases WHERE PurchaseId=@Id')).recordset[0].Status,'received');
 checks.push('Recepción de compra con lotes, kardex y asiento coherentes');
 const proforma={id:'test-proforma-'+token(),proformaNumber:'TEST-PRF-'+token(),clientName:'Cliente de prueba',items:[{productId:product.id,quantity:1,unitPrice:product.unitPrice}],subtotal:product.unitPrice,discountAmount:0,taxAmount:0,total:product.unitPrice,status:'aceptada',validUntil:new Date(Date.now()+7*86400000).toISOString(),notes:'Prueba reversible',createdAt:date,createdBy:actor,qrPayload:''};
 next=structuredClone(state);next.proformas.unshift(proforma);state=await save(next,state,'ventas');
 function converted(previous) {
  const result=structuredClone(previous),allocation=allocateInventory(result.lots,proforma.items);assert.ok(allocation);
  const saleId='test-sale-'+token();result.lots=allocation.lots;
  result.sales.unshift({id:saleId,saleNumber:'TEST-FAC-'+token(),clientName:proforma.clientName,items:proforma.items,subtotal:proforma.subtotal,discountAmount:0,taxAmount:0,total:proforma.total,status:'completed',saleDate:date,createdBy:actor,qrPayload:''});
  result.kardex.unshift({id:'test-kx-'+token(),productId:product.id,type:'salida',quantity:1,unitCost:allocation.unitCosts.get(product.id),date,reason:'Venta de prueba',userName:actor});
  result.accounting.unshift({id:'test-as-'+token(),entryNumber:'TEST-AS-'+token(),description:'Venta de prueba',debit:proforma.total,credit:proforma.total,debitAccount:'Cuentas por cobrar',creditAccount:'Ventas',entryDate:date,referenceType:'sale',referenceId:saleId});
  Object.assign(result.proformas.find(p=>p.id===proforma.id),{status:'convertida',convertedSaleId:saleId});
  return {result,saleId};
 }
 const first=converted(state);state=await save(first.result,state,'ventas');
 const conversion=(await request().input('Id',sql.NVarChar(100),proforma.id).query('SELECT Status,ConvertedSaleId FROM dbo.Proformas WHERE ProformaId=@Id')).recordset[0];
 assert.equal(conversion.Status,'convertida');assert.equal(conversion.ConvertedSaleId,first.saleId);
 assert.throws(()=>validateTradeChange(converted(state).result,state,'ventas'),error=>error.status===422);
 checks.push('Cotización convertida conserva vínculo a factura; reconversión rechazada por validador de ventas');
 const productionId='test-production-'+token();
 const source=await readProductionSource(request,state.sales.find(s=>s.id===first.saleId).saleNumber);assert.ok(source);
 const draft=productionDraft(source,source.lines[0].lineNumber);assert.ok(draft);assert.equal(draft.client,proforma.clientName);
 next=structuredClone(state);next.production.unshift({id:productionId,...draft,stage:'backlog',sprint:'Prueba',owner:actor});
 state=await save(next,state);
 for(const stage of ['corte','ensamble','instalacion','entregado']){
  next=structuredClone(state);next.production.find(p=>p.id===productionId).stage=stage;state=await save(next,state);
  assert.equal((await request().input('Id',sql.NVarChar(100),productionId).query('SELECT Stage FROM dbo.ProductionOrders WHERE ProductionOrderId=@Id')).recordset[0].Stage,stage);
 }
 checks.push('Orden de producción manual recorre corte, ensamble, instalación y entrega');
 assert.equal((await request().query('SELECT COUNT(*) AS count FROM dbo.CashMoves')).recordset[0].count,before[1][0].cash);
 checks.push('Venta y recepción no crean cobros o pagos ficticios');
 const actorRow=(await request().query('SELECT TOP(1) AppUserId AS id FROM dbo.AppUsers WHERE IsActive=1 ORDER BY AppUserId')).recordset[0];assert.ok(actorRow);
 assert.equal((await request().query("SELECT COUNT(*) AS count FROM dbo.CashSessions WHERE Account=N'banco' AND Status=N'abierta'")).recordset[0].count,0,'Banco debe estar libre en la copia para este fixture');
 const opened=(await cashRequest(pool,{transaction:tx}).input('Account',sql.NVarChar(30),'banco').input('Currency',sql.NVarChar(10),'C$').input('InitialBalance',sql.Decimal(19,4),1).input('ActorId',sql.NVarChar(100),actorRow.id).input('ActorName',sql.NVarChar(240),actor).input('OperationKey',sql.NVarChar(160),'test-open-'+token()).execute('dbo.usp_AbrirCaja')).recordset[0];
 const sale=state.sales.find(s=>s.id===first.saleId),payKey='test-receipt-'+token();
 const receipt=(key=payKey,amount=sale.total,reference=sale.saleNumber)=>cashRequest(pool,{transaction:tx}).input('Account',sql.NVarChar(30),'banco').input('MoveType',sql.NVarChar(10),'entrada').input('Amount',sql.Decimal(19,4),amount).input('Concept',sql.NVarChar(300),'Cobro de factura de prueba').input('Method',sql.NVarChar(30),'transferencia').input('DocumentType',sql.NVarChar(40),'venta').input('DocumentRef',sql.NVarChar(120),reference).input('SessionId',sql.NVarChar(100),opened.CashSessionId).input('ActorId',sql.NVarChar(100),actorRow.id).input('ActorName',sql.NVarChar(240),actor).input('OperationKey',sql.NVarChar(160),key).execute('dbo.usp_RegistrarMovimientoCaja');
 assert.equal((await readSaleBalance(request,sale.saleNumber)).pending,sale.total);
 const collected=(await receipt()).recordset[0];
 const link=(await request().input('Id',sql.NVarChar(100),collected.CashMoveId).query('SELECT m.SaleId,CONVERT(varchar(10),m.MoveDate,23) AS movementDate,CONVERT(varchar(10),s.SessionDate,23) AS sessionDate FROM dbo.CashMoves m JOIN dbo.CashSessions s ON s.CashSessionId=m.SessionId WHERE m.CashMoveId=@Id')).recordset[0];
 assert.equal(link.SaleId,first.saleId,'El cobro debe quedar vinculado a la factura');
 assert.equal(link.movementDate,link.sessionDate,'Sin fecha explícita el movimiento usa el día operativo local');
 assert.equal((await receipt()).recordset[0].CashMoveId,collected.CashMoveId,'Un reintento no debe duplicar el cobro');
 assert.equal(Number((await request().input('Id',sql.NVarChar(100),first.saleId).query('SELECT Balance FROM dbo.AccountsReceivable WHERE SaleId=@Id')).recordset[0].Balance),0,'El cobro total debe saldar la cuenta por cobrar');
 await assert.rejects(receipt('test-overpay-'+token(),1),e=>e.number===50612);
 await assert.rejects(receipt('test-invalid-'+token(),1,'FACTURA-INEXISTENTE'),e=>e.number===50612);
 checks.push('Cobro vinculado a factura, reintento idempotente, saldo por cobrar y rechazo de sobrecobro');
 await cashRequest(pool,{transaction:tx}).input('CashMoveId',sql.NVarChar(100),collected.CashMoveId).input('Reason',sql.NVarChar(1000),'Anulación de prueba reversible').input('ActorId',sql.NVarChar(100),actorRow.id).input('ActorName',sql.NVarChar(240),actor).execute('dbo.usp_AnularMovimientoCaja');
 const debt=async()=>Number((await request().input('Id',sql.NVarChar(100),first.saleId).query('SELECT Balance FROM dbo.AccountsReceivable WHERE SaleId=@Id')).recordset[0].Balance);
 assert.equal(await debt(),sale.total,'Anular el cobro debe reponer el saldo por cobrar');
 const partial=Math.round(sale.total*50)/100;
 await receipt('test-partial-'+token(),partial);
 assert.ok(Math.abs(await debt()-(sale.total-partial))<0.005);
 assert.ok(Math.abs((await readSaleBalance(request,sale.saleNumber)).pending-(sale.total-partial))<0.005);
 checks.push('Anulación repone el saldo y un abono parcial descuenta solo lo confirmado');
 await tx.rollback();
 assert.deepEqual(await inspect(),before,'Hash, revisión y conteos deben conservarse tras rollback');
 console.log(JSON.stringify({database:target,passed:true,checks,rollbackConfirmed:true}));
} finally {
 if(tx&&!aborted&&tx._acquiredConnection)await tx.rollback();
 if(database)await database.close();
}

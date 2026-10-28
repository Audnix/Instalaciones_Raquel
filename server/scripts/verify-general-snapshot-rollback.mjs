import fs from 'node:fs';
import assert from 'node:assert/strict';
import sql from 'mssql';
import dotenv from 'dotenv';
import {randomUUID} from 'node:crypto';
import {validateOperationalChange} from '../src/services/operationalIntegrity.js';
import {saveStateSnapshot,revisionToHex} from '../src/services/stateSnapshot.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');const pool=await getDatabase();
const inspect=async()=> (await pool.request().query("SELECT Revision,CONVERT(VARCHAR(64),HASHBYTES('SHA2_256',Payload),2) AS hash FROM dbo.ErpState WHERE StateId=1; SELECT (SELECT COUNT(*) FROM dbo.Employees) AS employees,(SELECT COUNT(*) FROM dbo.CashMoves) AS movements,(SELECT COUNT(*) FROM dbo.PayrollPayments) AS payments,(SELECT COUNT(*) FROM dbo.Sales) AS sales,(SELECT COUNT(*) FROM dbo.InventoryLots) AS lots;")).recordsets;
const before=await inspect();const tx=new sql.Transaction(pool);let rolledBack=false;tx.on('rollback',()=>rolledBack=true);
try{
 await tx.begin();
 const row=(await new sql.Request(tx).query('SELECT Payload,Revision FROM dbo.ErpState WHERE StateId=1')).recordset[0];
 const adapter={on:(...args)=>tx.on(...args),begin:async()=>{},commit:async()=>{},rollback:()=>tx.rollback()};
 const result=await saveStateSnapshot(pool,row.Payload,revisionToHex(row.Revision),{transaction:adapter,request:()=>new sql.Request(tx)});
 assert.equal(result.saved,true);console.log('PASS guardado completo en transacción exterior sin commit real');
 const savedRow=(await new sql.Request(tx).query('SELECT Payload,Revision FROM dbo.ErpState WHERE StateId=1')).recordset[0];
 const state=JSON.parse(savedRow.Payload),next=structuredClone(state);
 const lot=next.lots.filter(row=>row.quantity>=1).sort((a,b)=>a.entryDate.localeCompare(b.entryDate))[0];assert.ok(lot,'Se requiere stock existente para esta prueba reversible');
 const product=next.products.find(row=>row.id===lot.productId);assert.ok(product);
 const saleId='test-sale-'+randomUUID(),stamp=new Date().toISOString();
 lot.quantity-=1;
 assert.throws(()=>validateOperationalChange(next,state),e=>e.code==='OPERATIONAL_INTEGRITY');
 next.kardex.unshift({id:'test-kx-'+randomUUID(),productId:product.id,type:'salida',quantity:1,unitCost:lot.unitCost,date:stamp,reason:'Prueba reversible de factura',userName:'Verificacion reversible'});
 next.sales.unshift({id:saleId,saleNumber:'TEST-'+randomUUID(),clientName:'Prueba reversible',items:[{productId:product.id,quantity:1,unitPrice:product.unitPrice}],subtotal:product.unitPrice,discountAmount:0,taxAmount:0,total:product.unitPrice,status:'completed',saleDate:stamp,createdBy:'Verificacion reversible',qrPayload:''});
 next.accounting.unshift({id:'test-as-'+randomUUID(),entryNumber:'TEST-'+randomUUID(),description:'Prueba reversible',debit:product.unitPrice,credit:product.unitPrice,debitAccount:'Cuentas por cobrar',creditAccount:'Ventas',entryDate:stamp,referenceType:'sale',referenceId:saleId});
 const saleSave=await saveStateSnapshot(pool,JSON.stringify(next),revisionToHex(savedRow.Revision),{transaction:adapter,request:()=>new sql.Request(tx)});assert.equal(saleSave.saved,true);
 const checked=await new sql.Request(tx).input('Id',sql.NVarChar(100),saleId).query('SELECT COUNT(*) AS count FROM dbo.Sales WHERE SaleId=@Id; SELECT COUNT(*) AS count FROM dbo.CashMoves;');
 assert.equal(checked.recordsets[0][0].count,1);assert.equal(checked.recordsets[1][0].count,before[1][0].movements);
 console.log('PASS factura, stock, kardex y asiento guardados juntos; sin inventar un cobro de caja');

}finally{
 if(!rolledBack&&tx._acquiredConnection)await tx.rollback();
 const after=await inspect();assert.deepEqual(after,before,'La prueba debe conservar versión, hash y conteos reales');console.log('ROLLBACK confirmado: estado y conteos originales conservados',JSON.stringify(after[1][0]));await pool.close();
}

import test from 'node:test';
import assert from 'node:assert/strict';
import {validateSaleReceipt,prepareSaleReceipt,readSaleBalance} from '../src/services/saleReceipt.js';
const sale={SaleId:'s',Status:'completed',Total:100};
const payment={MoveType:'entrada',Amount:40};
test('cobro permite abono y saldo exacto pero rechaza exceso, salida y factura inexistente',()=>{
 assert.doesNotThrow(()=>validateSaleReceipt(payment,sale,60));
 assert.doesNotThrow(()=>validateSaleReceipt(payment,sale,0));
 for(const [p,s,paid] of [[payment,sale,61],[{...payment,MoveType:'salida'},sale,0],[payment,null,0],[payment,{...sale,Status:'draft'},0],[{...payment,Amount:NaN},sale,0]])assert.throws(()=>validateSaleReceipt(p,s,paid),e=>e.number===50612);
});
test('otros movimientos no buscan factura y cobros sin referencia se rechazan antes de consultar',async()=>{
 const request=()=>{throw Error('No debe consultar');};
 assert.equal(await prepareSaleReceipt(request,{DocumentType:'otro'}),null);
 await assert.rejects(prepareSaleReceipt(request,{DocumentType:'cobro',DocumentRef:' '}),e=>e.number===50612);
});


test('saldo de factura usa pagos confirmados y parametriza la referencia',async()=>{
 const inputs=[];let calls=0;
 const reference="FAC' 1";
 const request=()=>({input(name,type,value){inputs.push({name,value});return this;},async query(sql){
  assert.equal(sql.includes(reference),false);
  return {recordset:++calls===1?[{SaleId:'s',SaleNumber:reference,ClientName:'Cliente',Total:100}]:[{paid:35}]};
 }});
 assert.deepEqual(await readSaleBalance(request,reference),{saleNumber:reference,clientName:'Cliente',total:100,confirmedPaid:35,pending:65});
 assert.deepEqual(inputs[0],{name:'Reference',value:reference});
});
test('factura inexistente no ofrece un saldo para cobrar',async()=>{
 const request=()=>({input(){return this;},async query(){return {recordset:[]};}});
 assert.equal(await readSaleBalance(request,'NO-EXISTE'),null);
});

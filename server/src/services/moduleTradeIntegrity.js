const reject = message => { throw Object.assign(new Error(message), {status:422}); };
const near = (a,b) => Number.isFinite(a) && Number.isFinite(b) && Math.abs(a-b)<0.00001;
export function validateTradeChange(next, previous, module) {
  const sales=module==='ventas';
  const collection=sales?'sales':'purchases';
  const oldIds=new Set((previous[collection]??[]).map(row=>row.id));
  const docs=next[collection].filter(row=>!oldIds.has(row.id));
  const oldMoves=new Set((previous.kardex??[]).map(row=>row.id));
  const moves=next.kardex.filter(row=>!oldMoves.has(row.id));
  const expected=new Map(), actual=new Map();
  const add=(map,id,value)=>map.set(id,(map.get(id)??0)+value);
  for (const doc of docs) {
    if (sales && doc.status!=='completed') reject('La factura debe estar confirmada.');
    if (!Array.isArray(doc.items)||!doc.items.length) reject('Documento sin detalle.');
    if (sales || doc.status==='received') for(const item of doc.items) add(expected,item.productId,item.quantity);
  }
  for(const move of moves) {
    if(move.type!==(sales?'salida':'entrada'))reject('El movimiento no corresponde al documento.');
    add(actual,move.productId,move.quantity);
  }
  for(const id of new Set([...expected.keys(),...actual.keys()])) if(!near(expected.get(id)??0,actual.get(id)??0))reject('El kardex no coincide con los documentos nuevos.');
  const oldEntries=new Set((previous.accounting??[]).map(row=>row.id));
  const entries=next.accounting.filter(row=>!oldEntries.has(row.id));
  const accounted=docs.filter(doc=>sales||doc.status==='received');
  if(entries.length!==accounted.length)reject('Cada documento requiere su asiento contable.');
  for(const doc of accounted) {
    const linked=entries.filter(row=>row.referenceId===doc.id && row.referenceType===(sales?'sale':'purchase'));
    if(linked.length!==1 || !near(linked[0].debit,doc.total) || !near(linked[0].credit,doc.total) || linked[0].debitAccount!==(sales?'Cuentas por cobrar':'Inventario') || linked[0].creditAccount!==(sales?'Ventas':'Cuentas por pagar'))reject('El asiento no corresponde al documento y su importe.');
  }
  if(sales) {
    const lots=previous.lots.map(row=>({...row}));
    const consumedCosts=new Map();
    for(const doc of docs)for(const item of doc.items){
      let remaining=item.quantity;
      for(const lot of lots.filter(row=>row.productId===item.productId&&row.quantity>0).sort((a,b)=>a.entryDate.localeCompare(b.entryDate)||a.id.localeCompare(b.id))){const take=Math.min(remaining,lot.quantity);add(consumedCosts,lot.productId,take*lot.unitCost);lot.quantity-=take;remaining-=take;if(remaining<0.00000001)break;}
      if(remaining>0.00000001)reject('Existencias insuficientes.');
    }
    if(next.lots.length!==lots.length || lots.some(row=>!near(row.quantity,next.lots.find(item=>item.id===row.id)?.quantity)))reject('La venta debe consumir los lotes en orden PEPS.');
    const moveCosts=new Map();for(const move of moves)add(moveCosts,move.productId,move.quantity*move.unitCost);
    for(const id of new Set([...consumedCosts.keys(),...moveCosts.keys()]))if(!near(consumedCosts.get(id)??0,moveCosts.get(id)??0))reject('El costo de salida no corresponde a los lotes PEPS.');
    for(const old of previous.proformas??[]){
      const row=next.proformas.find(item=>item.id===old.id);
      if(JSON.stringify(old)===JSON.stringify(row))continue;
      if(old.status==='convertida'||row?.status!=='convertida'||!docs.some(doc=>doc.id===row.convertedSaleId))reject('La cotizacion solo cambia al facturarla.');
      const sale=docs.find(doc=>doc.id===row.convertedSaleId);
      if(!near(sale.total,old.total)||sale.clientName!==old.clientName||JSON.stringify(sale.items)!==JSON.stringify(old.items))reject('La factura no coincide con la cotizacion.');
      const {status,convertedSaleId,...base}=row;
      const {status:oldStatus,convertedSaleId:oldSale,...oldBase}=old;
      if(JSON.stringify(base)!==JSON.stringify(oldBase))reject('No se permite alterar una cotizacion al convertirla.');
    }
  } else {
    const oldLots=new Set(previous.lots.map(row=>row.id));
    const added=next.lots.filter(row=>!oldLots.has(row.id));
    const expectedCosts=new Map(),actualCosts=new Map(),expectedLots=new Map(),actualLots=new Map();
    const lotKey=(product,cost,date)=>JSON.stringify([product,cost,date]);
    for(const doc of accounted)for(const item of doc.items)add(expectedLots,lotKey(item.productId,item.unitPrice,doc.purchaseDate),item.quantity);
    for(const lot of added)add(actualLots,lotKey(lot.productId,lot.unitCost,lot.entryDate),lot.quantity);
    for(const key of new Set([...expectedLots.keys(),...actualLots.keys()]))if(!near(expectedLots.get(key)??0,actualLots.get(key)??0))reject('Los lotes no coinciden con cantidades, costos y fechas de recepcion.');
    for(const doc of accounted)for(const item of doc.items)add(expectedCosts,item.productId,item.quantity*item.unitPrice);
    for(const lot of previous.lots)if(!near(lot.quantity,next.lots.find(row=>row.id===lot.id)?.quantity))reject('Una recepcion no consume lotes anteriores.');
    for(const lot of added)add(actualCosts,lot.productId,lot.quantity*lot.unitCost);
    for(const id of new Set([...expectedCosts.keys(),...actualCosts.keys()]))if(!near(expectedCosts.get(id)??0,actualCosts.get(id)??0))reject('El costo recibido no coincide con la compra.');
  }
}

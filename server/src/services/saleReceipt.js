import sql from 'mssql';

const reject=message=>{throw Object.assign(new Error(message),{number:50612});};
export function validateSaleReceipt(payment,sale,paid=0){
 if(payment.MoveType!=='entrada')reject('El cobro de una factura debe registrarse como entrada.');
 if(!sale||sale.Status!=='completed')reject('Indica el número exacto de una factura confirmada. Para ingresos sin factura utiliza Otro.');
 if(!Number.isFinite(payment.Amount)||payment.Amount<=0||!Number.isFinite(Number(sale.Total))||!Number.isFinite(Number(paid)))reject('No se pudo comprobar el importe de la factura.');
 if(payment.Amount>Number(sale.Total)-Number(paid)+0.005)reject('El cobro supera el saldo pendiente de la factura. Revisa sus cobros confirmados.');
}
const paidSql=`SELECT ISNULL(SUM(Amount),0) AS paid FROM dbo.CashMoves
 WHERE MoveState=N'confirmado' AND MoveType=N'entrada'
 AND (SaleId=@SaleId OR (SaleId IS NULL AND DocumentRef=@SaleNumber AND DocumentType IN(N'venta',N'cobro')))`;

export async function readSaleBalance(request,reference){
 const sale=(await request().input('Reference',sql.NVarChar(120),reference).query('SELECT SaleId,SaleNumber,ClientName,Total FROM dbo.Sales WHERE SaleNumber=@Reference AND Status=N\'completed\'')).recordset[0];
 if(!sale)return null;
 const paid=(await request().input('SaleId',sql.NVarChar(100),sale.SaleId).input('SaleNumber',sql.NVarChar(120),sale.SaleNumber).query(paidSql)).recordset[0].paid;
 return {saleNumber:sale.SaleNumber,clientName:sale.ClientName,total:Number(sale.Total),confirmedPaid:Number(paid),pending:Math.max(0,Number(sale.Total)-Number(paid))};
}

export async function prepareSaleReceipt(request,p){
 if(!['venta','cobro'].includes(p.DocumentType))return null;
 if(!p.DocumentRef?.trim())reject('El cobro requiere el número de factura en Referencia. Para otros ingresos utiliza Otro.');
 const sale=(await request().input('Reference',sql.NVarChar(120),p.DocumentRef.trim()).query('SELECT SaleId,SaleNumber,Total,Status FROM dbo.Sales WITH(UPDLOCK,HOLDLOCK) WHERE SaleNumber=@Reference')).recordset[0];
 const paid=sale?(await request().input('SaleId',sql.NVarChar(100),sale.SaleId).input('SaleNumber',sql.NVarChar(120),sale.SaleNumber).query(paidSql)).recordset[0].paid:0;
 validateSaleReceipt(p,sale,paid);
 return sale;
}

export async function refreshSaleReceivable(request,saleId){
 const sale=(await request().input('Id',sql.NVarChar(100),saleId).query('SELECT SaleId,SaleNumber,Total FROM dbo.Sales WITH(UPDLOCK,HOLDLOCK) WHERE SaleId=@Id')).recordset[0];
 if(!sale)return;
 const paid=(await request().input('SaleId',sql.NVarChar(100),sale.SaleId).input('SaleNumber',sql.NVarChar(120),sale.SaleNumber).query(paidSql)).recordset[0].paid;
 const balance=Math.max(0,Number(sale.Total)-Number(paid));
 await request().input('SaleId',sql.NVarChar(100),sale.SaleId).input('Balance',sql.Decimal(19,4),balance).input('Paid',sql.Decimal(19,4),paid).query(`UPDATE dbo.AccountsReceivable SET Balance=@Balance,Status=CASE WHEN @Balance<=0.005 THEN N'cobrada' WHEN @Paid>0 THEN N'parcial' WHEN DueDate<CONVERT(date,SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time') THEN N'vencida' ELSE N'abierta' END WHERE SaleId=@SaleId`);
}

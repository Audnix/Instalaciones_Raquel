import sql from 'mssql';

// Projection for workshop staff: quantities and descriptions, without prices.
export async function readProductionSource(request,reference){
 const rows=(await request().input('Reference',sql.NVarChar(80),reference).query(`
 SELECT s.SaleNumber,s.ClientName,i.LineNumber,i.Quantity,p.Name AS ProductName
 FROM dbo.Sales s JOIN dbo.SaleItems i ON i.SaleId=s.SaleId
 JOIN dbo.Products p ON p.ProductId=i.ProductId
 WHERE s.SaleNumber=@Reference AND s.Status=N'completed'
 ORDER BY i.LineNumber`)).recordset;
 if(!rows.length)return null;
 return {saleNumber:rows[0].SaleNumber,clientName:rows[0].ClientName,
  lines:rows.map(row=>({lineNumber:row.LineNumber,product:row.ProductName,quantity:Number(row.Quantity)}))};
}

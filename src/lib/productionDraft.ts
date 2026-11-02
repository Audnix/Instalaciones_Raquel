export type ProductionSource={saleNumber:string;clientName:string;lines:{lineNumber:number;product:string;quantity:number}[]};
export function productionDraft(source:ProductionSource,lineNumber:number){
 const line=source.lines.find(row=>row.lineNumber===lineNumber);
 if(!line||!Number.isFinite(line.quantity)||line.quantity<=0)return null;
 return {code:`OT-${source.saleNumber.slice(0,60)}-${line.lineNumber}`,product:line.product,client:source.clientName,qty:line.quantity};
}

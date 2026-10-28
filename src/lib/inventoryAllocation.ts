import type {InventoryLot,SaleItem} from '../types/erp';
export function allocateInventory(source: InventoryLot[], items: SaleItem[]) {
  if (!items.length || items.some(item => !Number.isFinite(item.quantity) || item.quantity <= 0)) return null;
  const lots=source.map(lot=>({...lot}));
  const costs=new Map<string,number>(), quantities=new Map<string,number>();
  for(const item of items){
    let remaining=item.quantity;
    const ordered=lots.filter(lot=>lot.productId===item.productId&&lot.quantity>0).sort((a,b)=>a.entryDate.localeCompare(b.entryDate)||a.id.localeCompare(b.id));
    for(const lot of ordered){
      if(remaining<=0.00000001)break;
      const taken=Math.min(remaining,lot.quantity);
      lot.quantity=Math.max(0,lot.quantity-taken);remaining-=taken;
      costs.set(item.productId,(costs.get(item.productId)??0)+taken*lot.unitCost);
    }
    if(remaining>0.00000001)return null;
    quantities.set(item.productId,(quantities.get(item.productId)??0)+item.quantity);
  }
  return {lots,unitCosts:new Map([...costs].map(([product,cost])=>[product,cost/quantities.get(product)!])),totalCost:[...costs.values()].reduce((sum,cost)=>sum+cost,0)};
}

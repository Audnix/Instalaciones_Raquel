import type { ErpDatabase, ModuleId } from '../types/erp';

export type SearchModule = { id: ModuleId; label: string; description: string };
export type NavigationResult = { label: string; detail: string; url: string };
const normalize = (value: string) => value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();

// Only index records for modules the caller may open; never index salaries or users.
export function navigationSearch(query: string, allowed: SearchModule[], db: ErpDatabase): NavigationResult[] {
 const term = normalize(query.trim());
 if (term.length < 2) return [];
 const results: NavigationResult[] = [];
 const access = new Set(allowed.map(module => module.id));
 const add = (label: string, detail: string, url: string) => {
  if (normalize(`${label} ${detail}`).includes(term)) results.push({label, detail, url});
 };
 allowed.forEach(module => add(module.label, module.description, `/${module.id}`));
 if (access.has('ventas')) {
  db.sales.forEach(row => add(row.saleNumber, `Factura · ${row.clientName}`, `/ventas#sale-${encodeURIComponent(row.saleNumber)}`));
  db.proformas.forEach(row => add(row.proformaNumber, `Cotización · ${row.clientName}`, `/ventas#proforma-${encodeURIComponent(row.proformaNumber)}`));
 }
 if (access.has('produccion')) db.production.forEach(row => add(row.code, `Orden · ${row.client} · ${row.product}`, `/produccion#production-${encodeURIComponent(row.code)}`));
 if (access.has('inventario')) db.products.forEach(row => add(row.code, row.name, `/inventario#product-${encodeURIComponent(row.code)}`));
 if (access.has('compras')) db.purchases.forEach(row => add(row.purchaseNumber, `Compra · ${row.supplierName}`, `/compras#purchase-${encodeURIComponent(row.purchaseNumber)}`));
 if (access.has('clientes')) db.parties.filter(row => row.type === 'cliente').forEach(row => add(row.name, 'Cliente', `/clientes#party-${encodeURIComponent(row.id)}`));
 return results.slice(0, 12);
}

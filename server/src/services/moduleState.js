import { randomUUID } from 'node:crypto';
import { validateTradeChange } from './moduleTradeIntegrity.js';

export const modulePolicies = {
  datos: { areas: ['inventario','gobierno'], administrators: true, read: ['products','lots'], write: ['products'] },
  auditoria: { areas: ['gobierno'], administrators: true, read: ['audit','sales','kardex','accounting','cash','products','lots'], write: [] },
  produccion: { areas: ['produccion'], read: ['production', 'products'], write: ['production'] },
  inventario: { areas: ['inventario', 'produccion', 'compras'], read: ['products', 'lots', 'kardex'], write: ['lots', 'kardex'] },
  finanzas: { areas: ['finanzas'], read: ['finance', 'projections'], write: ['finance', 'projections'] },
  proyectos: { areas: ['proyectos'], read: ['projects'], write: ['projects'] },
  contabilidad: { areas: ['contabilidad'], read: ['accounting','sales','purchases','products','lots'], write: ['accounting'] },
  costos: { areas: ['finanzas','contabilidad'], read: ['products','lots','kardex','purchases'], write: [] },
  ventas: { areas: ['ventas','mercadotecnia'], read: ['products','lots','kardex','sales','proformas','promotions','parties','accounting'], write: ['lots','kardex','sales','proformas','accounting'] },
  clientes: { areas: ['ventas'], read: ['parties'], write: ['parties'] },
  mercadotecnia: { areas: ['mercadotecnia'], read: ['products','lots','sales','promotions','albums'], write: ['albums'] },
  compras: { areas: ['compras'], read: ['products','lots','kardex','purchases','accounting'], write: ['lots','kardex','purchases','accounting'] },
  reportes: { areas: ['contabilidad','mercadotecnia','gobierno'], administrators: true, read: ['products','lots','sales','promotions','albums'], write: [] }
};

export function authorizeModule(req, res, next) {
  const policy = Object.hasOwn(modulePolicies, req.params.module) ? modulePolicies[req.params.module] : null;
  const user = req.user;
  if (!policy || !user || (user.hierarchy !== 'superadmin' && !(policy.administrators && user.hierarchy === 'administrador') && !policy.areas.some(area => user.areas?.includes(area)))) {
    return res.status(403).json({ message: 'Tu cuenta no tiene acceso a esta área.' });
  }
  if (req.method !== 'GET' && (!policy.write.length || user.mustChangePassword || !['superadmin', 'administrador', 'estandar'].includes(user.hierarchy))) {
    return res.status(403).json({ message: 'Tu cuenta no puede registrar cambios en esta área.' });
  }
  if (req.params.module === 'datos' && req.method !== 'GET' && !['superadmin','administrador'].includes(user.hierarchy) && !(user.hierarchy === 'estandar' && user.areas?.includes('inventario'))) {
    return res.status(403).json({ message: 'El registro de productos requiere administración o personal autorizado de Inventario.' });
  }
  next();
}

export function visibleModuleRows(state, module, key) {
  const rows=state?.[key] ?? [];
  if (key==='parties' && ['clientes','ventas'].includes(module)) return rows.filter(row=>row.type==='cliente');
  if (key==='accounting' && ['ventas','compras'].includes(module)) return rows.filter(row=>row.referenceType===(module==='ventas'?'sale':'purchase'));
  return rows;
}
export function projectModuleState(state, module) {
  return Object.fromEntries(modulePolicies[module].read.map(key => [key, visibleModuleRows(state,module,key)]));
}

function reject(message) { throw Object.assign(new Error(message), { status: 422 }); }

export function mergeModuleState(incoming, previous, module, user) {
  if (!previous) reject('No existe un estado SQL para esta área.');
  const policy = modulePolicies[module];
  if (!policy?.write.length) reject('Este modulo es de solo consulta.');
  const keys = Object.keys(incoming);
  if (keys.some(key => !policy.write.includes(key)) || policy.write.some(key => !Array.isArray(incoming[key]))) {
    reject('Solo se permiten las colecciones de escritura de esta área.');
  }
  const merged = { ...previous, ...incoming };
  if (module === 'datos') {
    const codes = new Set();
    for (const product of incoming.products) {
      if (typeof product.code !== 'string' || !product.code.trim() || product.code.trim().length > 80 ||
          typeof product.name !== 'string' || !product.name.trim() || product.name.trim().length > 200 ||
          typeof product.category !== 'string' || !product.category.trim() || product.category.trim().length > 120 ||
          typeof product.unitPrice !== 'number' || !Number.isFinite(product.unitPrice) || product.unitPrice < 0 ||
          typeof product.minQuantity !== 'number' || !Number.isFinite(product.minQuantity) || product.minQuantity < 0) reject('Revisa código, nombre, categoría, precio y mínimo del producto.');
      const code = product.code.trim().toLowerCase();
      if (codes.has(code)) reject('Ya existe un producto con ese código.');
      codes.add(code);
      const old = previous.products?.find(row => row.id === product.id);
      if (old && JSON.stringify(old) !== JSON.stringify(product)) reject('Este formulario permite agregar productos; no modificar los existentes.');
    }
  }
  // Los movimientos confirmados no se editan ni eliminan desde estos formularios.
  for (const key of policy.write) {
    const visible = visibleModuleRows(previous,module,key);
    const hidden = (previous[key] ?? []).filter(row=>!visible.some(item=>item.id===row.id));
    if (incoming[key].some(row=>hidden.some(item=>item.id===row.id))) reject('Registro ajeno al modulo.');
    merged[key] = [...hidden,...incoming[key]];
    const ids = new Set(incoming[key].map(row => row.id));
    if (visible.some(row => !ids.has(row.id))) reject('No se permite eliminar registros de esta área.');
    if (['kardex', 'finance', 'accounting', 'sales', 'purchases'].includes(key)) {
      for (const old of visible) {
        if (JSON.stringify(old) !== JSON.stringify(incoming[key].find(row => row.id === old.id))) reject('No se permite reescribir movimientos existentes.');
      }
      const oldIds = new Set((previous[key] ?? []).map(row => row.id));
      merged[key] = [...hidden,...incoming[key].map(row => oldIds.has(row.id) ? row : ['kardex','finance'].includes(key) ? { ...row, userName: user.name } : ['sales','purchases'].includes(key) ? { ...row, createdBy: user.name } : row)];
    }
  }
  if (module==='clientes' && incoming.parties.some(row=>row.type!=='cliente')) reject('Solo se permiten clientes en este modulo.');
  if (policy.write.includes('lots')) {
    for (const old of previous.lots ?? []) {
      const row=merged.lots.find(item=>item.id===old.id);
      if (!row || ['productId','unitCost','entryDate','warehouseId'].some(key=>row[key]!==old[key])) reject('No se permite reescribir el origen o costo de un lote existente.');
    }
  }
  if (['ventas','compras'].includes(module)) validateTradeChange(merged,previous,module);
  if (module==='contabilidad') {
    const oldIds=new Set((previous.accounting??[]).map(row=>row.id));
    if (merged.accounting.some(row=>!oldIds.has(row.id)&&row.referenceType!=='manual')) reject('Los asientos de documentos se generan desde su operacion original.');
  }
  if (module==='mercadotecnia') {
    for (const album of merged.albums) {
      if (!album.title?.trim() || !/^\d{4}-\d{2}$/.test(album.month) || !Array.isArray(album.productIds) || !album.productIds.length || album.productIds.some(id=>!previous.products.some(row=>row.id===id))) reject('Album sin titulo, mes o productos validos.');
    }
  }
  const productionCodes=new Set();
  for (const order of merged.production ?? []) {
    if (module === 'produccion' && (!order.code?.trim() || !order.product?.trim() || !order.client?.trim())) reject('La orden requiere código, trabajo y cliente.');
    if(module==='produccion'){
      const code=order.code.trim().toLowerCase();
      if(productionCodes.has(code))reject('Ya existe una orden con ese código.');
      productionCodes.add(code);
    }
  }
  if (module === 'finanzas') {
    for (const row of merged.projections) {
      if (![row.expectedSales, row.expectedCosts].every(n => typeof n === 'number' && Number.isFinite(n) && n >= 0)) reject('La proyección requiere importes válidos.');
    }
  }
  const event = {
    id: `au-${randomUUID()}`, at: new Date().toISOString(), userName: user.name,
    action: 'guardar área', module, detail: `Cambios confirmados en ${module}`, severity: 'info',
    prevHash: previous.audit?.[0]?.hash ?? 'GENESIS'
  };
  let hash = 2166136261;
  const text = `${event.prevHash}|${event.at}|${event.userName}|${event.action}|${event.module}|${event.detail}`;
  for (let i = 0; i < text.length; i++) { hash ^= text.charCodeAt(i); hash = Math.imul(hash, 16777619); }
  event.hash = (hash >>> 0).toString(16).padStart(8, '0');
  merged.audit = [event, ...(previous.audit ?? [])].slice(0, 200);
  return merged;
}

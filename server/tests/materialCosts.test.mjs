import test from 'node:test';
import assert from 'node:assert/strict';
import {displayText,materialCosts} from '../../src/lib/materialCosts.ts';

test('nombres reparan mojibake sin alterar acentos correctos ni unidades',()=>{
 assert.equal(displayText('Silic\u00c3\u00b3n'),'Silic\u00f3n');
 assert.equal(displayText('hidr\u00c3\u00a1ulico'),'hidr\u00e1ulico');
 assert.equal(displayText('m\u00c2\u00b2'),'m\u00b2');
 assert.equal(displayText('m\u00c3\u201a\u00c2\u00b2'),'m\u00b2');
 assert.equal(displayText('Vidrio templado de seguridad 10mm (m\u00b2)'), 'Vidrio templado de seguridad 10mm (m\u00b2)');
 assert.equal(displayText('C\u00f3rdobas, instalaci\u00f3n y ni\u00f1ez'), 'C\u00f3rdobas, instalaci\u00f3n y ni\u00f1ez');
 assert.equal(displayText(''), '');
});
test('costos suman cantidad por costo de cada lote y no promedios simples',()=>{
 const products=[{id:'p',name:'Perfil'},{id:'empty',name:'Sin stock'}];
 const lots=[{id:'l1',productId:'p',quantity:2,unitCost:100},{id:'l2',productId:'p',quantity:8,unitCost:50}];
 const before=JSON.stringify({products,lots});const rows=materialCosts(products,lots);
 assert.equal(rows[0].quantity,10);assert.equal(rows[0].value,600);assert.equal(rows[0].averageCost,60);
 assert.equal(rows[1].quantity,0);assert.equal(rows[1].value,0);assert.equal(rows[1].averageCost,0);
 assert.equal(JSON.stringify({products,lots}),before);
});

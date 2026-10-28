import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { databaseScriptCatalog,buildStructureScript,structureOrder,requiredDatabaseTables,sqlScriptsDirectory } from '../src/services/databaseScripts.js';
test('todos los scripts fuente están catalogados y no se omiten archivos inexistentes',()=>{
 const catalog=databaseScriptCatalog();
 assert.equal(catalog.every(file=>file.exists),true);
 const actual=fs.readdirSync(sqlScriptsDirectory).filter(name=>name.endsWith('.sql')&&name!=='paquete_estructura_actual.sql');
 assert.deepEqual(new Set(catalog.map(file=>file.name)),new Set(actual));
 assert.equal(catalog.some(file=>file.name==='18_invitaciones_y_gobierno.sql'),false);
});
test('estructura respeta dependencias y termina con las protecciones vigentes',()=>{
 const position=name=>structureOrder.indexOf(name);
 assert.ok(position('17_modulo_nomina_completo.sql')<position('07_procedimiento_sincronizacion.sql'));
 assert.ok(position('12_sincronizacion_proveedores.sql')<position('19_directorio_proveedores.sql'));
 assert.ok(position('26_integridad_caja_nomina_pagos.sql')<position('19_directorio_proveedores.sql'));
 assert.ok(position('30_pagos_individuales_atomicos.sql')<position('31_reglas_periodo_y_devengo_nomina.sql'));
 assert.ok(position('32_conservar_enlaces_snapshot.sql')>position('31_reglas_periodo_y_devengo_nomina.sql'));
 assert.equal(structureOrder.at(-1),'34_preservar_proveedores_guardado_global.sql');
 assert.ok(requiredDatabaseTables().includes('PayrollPaymentAllocations'));
});
test('paquete bloquea base existente y excluye reconstrucciones, cargas y credenciales',()=>{
 const script=buildStructureScript();
 assert.ok(script.indexOf("IF DB_ID(N'Instalaciones Raquel') IS NOT NULL")<script.indexOf('/* ARCHIVO 1/'));
 assert.ok(script.includes('SET NOEXEC ON'));
 for(const name of ['08_semilla.sql','09_login_aplicacion.sql','19_carga_integral_datos_reales.sql','21_mejoras_directorio_proveedores.sql','24_cargar_registros_talento_humano_y_nomina.sql']) assert.equal(structureOrder.includes(name),false);
 assert.equal(/\b(?:CREATE|ALTER)\s+LOGIN\b/i.test(script),false);
 assert.equal(/DROP\s+DATABASE/i.test(script),false);
 assert.equal(script.includes('\uFEFF'),false);
});

import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
export const sqlScriptsDirectory = fileURLToPath(new URL('../../../Database/SQLServer_Completo/', import.meta.url));
export const structureOrder = [
 '00_crear_base.sql','01_catalogos.sql','02_gobierno_y_maestros.sql','11_actualizar_proveedores.sql',
 '03_inventario_y_comercial.sql','04_produccion_proyectos.sql','05_finanzas_nomina.sql','06_vistas.sql',
 '12_sincronizacion_proveedores.sql','13_autenticacion_y_sesiones.sql',
 '14_recuperacion_contrasena.sql','15_expedientes_proyectos.sql','16_talento_humano_base.sql','17_modulo_nomina_completo.sql','07_procedimiento_sincronizacion.sql',
 '25_mejoras_gestion_talento_humano_y_nomina.sql',
 '25_operaciones_hr_nomina.sql','26_integridad_caja_nomina_pagos.sql','19_directorio_proveedores.sql','28_ajuste_pagos_caja.sql',
 '29_coherencia_caja_nomina_snapshot.sql','30_pagos_individuales_atomicos.sql','31_reglas_periodo_y_devengo_nomina.sql',
 '32_conservar_enlaces_snapshot.sql','33_eventos_novedades_nomina.sql','34_preservar_proveedores_guardado_global.sql'
];
const otherScripts = {
 '21_mejoras_directorio_proveedores.sql':'datos_opcionales', '00_reconstruir_desde_cero.sql':'destructivo', '08_semilla.sql':'datos_opcionales', '09_login_aplicacion.sql':'acceso_separado',
 '10_verificar.sql':'verificacion', '18_verificar_usuarios.sql':'verificacion', '19_carga_integral_datos_reales.sql':'datos_opcionales',
 '20_verificar_integracion_total.sql':'verificacion','22_verificar_modulo_proveedores.sql':'verificacion',
 '23_verificar_talento_humano_y_nomina.sql':'verificacion','24_cargar_registros_talento_humano_y_nomina.sql':'datos_opcionales',
 '27_reporte_inconsistencias.sql':'verificacion','SQLQuery3Verificar.sql':'verificacion'
};
export function databaseScriptCatalog() {
 const known=[...structureOrder,...Object.keys(otherScripts)];
 const extra=fs.readdirSync(sqlScriptsDirectory).filter(name=>name.endsWith('.sql')&&name!=='paquete_estructura_actual.sql'&&!known.includes(name));
 return [...known,...extra].map(name=>{
  const path=new URL(name,new URL('../../../Database/SQLServer_Completo/',import.meta.url));
  const exists=fs.existsSync(path);const source=exists?fs.readFileSync(path,'utf8'):'';
  return {name,category:structureOrder.includes(name)?'estructura':(otherScripts[name]??'sin_clasificar'),order:structureOrder.includes(name)?structureOrder.indexOf(name)+1:null,
   exists,bytes:Buffer.byteLength(source),sha256:exists?createHash('sha256').update(source).digest('hex'):null};
 });
}
export function requiredDatabaseTables() {
 const tables=new Set();
 for(const name of structureOrder){const source=fs.readFileSync(new URL(name,new URL('../../../Database/SQLServer_Completo/',import.meta.url)),'utf8').replace(/^\uFEFF/,'');
  for(const match of source.matchAll(/CREATE\s+TABLE\s+dbo\.\[?([A-Za-z0-9_]+)\]?/gi)) tables.add(match[1]);
 }
 return [...tables].sort();
}
export function buildStructureScript() {
 const catalog=databaseScriptCatalog();
 const unknown=catalog.filter(script=>script.category==='sin_clasificar');
 if(unknown.length)throw Error('Scripts sin clasificar: '+unknown.map(script=>script.name).join(', '));
 const missing=catalog.filter(script=>!script.exists);
 if(missing.length)throw Error('Archivos SQL faltantes: '+missing.map(script=>script.name).join(', '));
 const header=`/* INSTALACIONES RAQUEL: ESTRUCTURA PARA INSTALACION NUEVA
Generado a partir de ${structureOrder.length} archivos en orden explicito.
No ejecutar sobre una base existente: la comprobacion siguiente lo bloquea.
No incluye reconstruccion, cargas de ejemplo, importaciones operativas ni cambio de credenciales.
Los catalogos y reglas tecnicas definidos dentro de las migraciones se mantienen.
El paquete no certifica vigencia normativa ni sustituye pruebas funcionales.
En SSMS ejecutar completo; en sqlcmd utilizar -b. Configurar el usuario de aplicacion por separado. */
USE master;
GO
IF DB_ID(N'Instalaciones Raquel') IS NOT NULL
BEGIN
 RAISERROR('La base ya existe. Este paquete es solo para instalacion nueva; revisar migraciones individuales con respaldo.',16,1);
 SET NOEXEC ON;
END;
GO
`;
 return header+structureOrder.map((name,index)=>`\n/* ARCHIVO ${index+1}/${structureOrder.length}: ${name} */\n`+fs.readFileSync(new URL(name,new URL('../../../Database/SQLServer_Completo/',import.meta.url)),'utf8').replace(/^\uFEFF/,'')+'\nGO\n').join('')+'\nSET NOEXEC OFF;\nGO\n';
}

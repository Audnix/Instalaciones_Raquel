import fs from 'node:fs';
import {databaseScriptCatalog,structureOrder,requiredDatabaseTables} from '../src/services/databaseScripts.js';
const readme=new URL('../../Database/SQLServer_Completo/README.md',import.meta.url);
const archive=new URL('../../docs/README_SQL_pre_revision_2026-10-25.md',import.meta.url);
if(!fs.existsSync(archive))fs.copyFileSync(readme,archive);
const catalog=databaseScriptCatalog();
const text=`# Instalaciones Raquel — SQL Server

Revisión del 25 de octubre de 2026. Esta carpeta contiene estructura, migraciones, diagnósticos y cargas opcionales. No son archivos intercambiables y no deben ejecutarse todos por orden alfabético.

## Comprobar y descargar desde la aplicación

En **Base de datos → SQL y migraciones**, superadministración puede consultar cobertura de archivos, tablas declaradas y marcadores conocidos, y descargar la estructura completa. La inspección es de solo lectura. Si la conexión no tiene visibilidad completa de metadatos, las tablas se muestran como ausentes o no visibles, sin certificar que falten físicamente.

El diagnóstico de cobertura no prueba cada columna, procedimiento, regla, dato ni flujo funcional. Ver evidencia en ../../docs/schema_coverage_readonly_result.txt y ../../docs/database_source_catalog_2026-10-25.json.

## Instalación nueva

Desde la raíz del proyecto:

- npm run db:plan: muestra el catálogo y el orden, sin ejecutar SQL.
- npm run db:bundle: genera paquete_estructura_actual.sql en esta carpeta.
- npm run db:install: muestra el plan; ya no reinstala silenciosamente.
- npm run db:install -- --apply: aplica únicamente el paquete de estructura mediante sqlcmd, autenticación integrada de Windows, UTF-8 y detención por errores. Requiere una instancia donde la base [Instalaciones Raquel] todavía no exista.

El paquete contiene ${structureOrder.length} archivos de estructura en orden explícito, ${requiredDatabaseTables().length} tablas declaradas detectadas y las migraciones de integridad hasta 34. Se ejecuta completo en SSMS o con sqlcmd -b -f 65001. Se bloquea si la base ya existe; no debe usarse como actualización.

Se excluyen reconstrucción, semilla general, cargas operativas y cambios de contraseña del login. Los catálogos técnicos, cuentas y reglas que definen las migraciones permanecen incluidos; no se certifica su vigencia normativa. Las cargas de demostración de Talento Humano requieren una activación explícita de raquel_include_demo y no se ejecutan por defecto. Nunca habilitarlas para completar una base real.

09_login_aplicacion.sql se mantiene como paso de acceso separado: puede crear o cambiar el login y requiere revisión de la cuenta administradora. No se incluye en la descarga ni se pasan contraseñas al generador. El paquete nuevo termina sin usuarios de aplicación. Un administrador debe registrar de forma controlada el superadministrador inicial con su correo real; db:bootstrap-user activa una cuenta superadministradora que ya exista, no la crea. No se crean usuarios de ejemplo con el paquete de estructura.

## Base existente

No ejecutar paquete_estructura_actual.sql, db:rebuild, 00_reconstruir_desde_cero.sql, 08_semilla.sql ni importaciones para solucionar una migración faltante. db:rebuild queda bloqueado en el instalador seguro. El archivo destructivo original se conserva para revisión, sin invocarlo automáticamente.

Primero inspeccionar el esquema, respaldar y verificar el respaldo; después aplicar solo la migración necesaria. Las migraciones antiguas redefinen procedimientos, por lo que repetirlas puede sustituir una versión más reciente. La cuenta de la API no debe recibir permisos administrativos para instalar migraciones.

En esta revisión se detectó PayrollNoveltyEvents faltante en la instancia existente y se aplicó únicamente 33_eventos_novedades_nomina.sql, con respaldo previo. No se copiaron datos de la base temporal ni de los ejemplos a la instalación real. La nueva tabla conserva auditoría de novedades; no registra pagos ni cambia salarios.

## Orden real de la estructura

07_procedimiento_sincronizacion.sql requiere columnas de nómina creadas por 17; por eso se instala después de 17, no después de 06. Las protecciones 26–33 se aplican después. La fuente de este orden es server/src/services/databaseScripts.js; el instalador y la descarga usan ese mismo catálogo.

| Orden | Archivo |
|---|---|
${structureOrder.map((name,index)=>`| ${index+1} | ${name} |`).join('\n')}

## Archivos separados

| Archivo | Clasificación |
|---|---|
${catalog.filter(file=>file.order===null).map(file=>`| ${file.name} | ${file.category} |`).join('\n')}

Los archivos 19_carga_integral_datos_reales.sql y 24_cargar_registros_talento_humano_y_nomina.sql contienen registros operativos; sus nombres no constituyen prueba de autenticidad ni autorización para cargarlos. 21_mejoras_directorio_proveedores.sql mezcla una lectura y datos de demostración de proveedores, por eso se excluye de estructura y queda protegido por activación explícita. Su campo legalName pertenece al documento JSON, no a una columna inexistente de Parties.

Los scripts de verificación son diagnósticos; no instalan la estructura ni se consideran una certificación integral. No se omiten archivos faltantes silenciosamente.

## Nómina y pagos

Ver ../../docs/guia_pago_trabajador.md. El formulario en Nómina utiliza trabajadores y cálculos del servidor, y conserva períodos, versiones, aprobaciones, pendientes individuales y referencias. Bonos y deducciones se configuran como novedades antes de aprobar. No se copian tasas de una imagen ni se vuelve a descontar al registrar el abono. La consulta previa no envía dinero ni reserva fondos; el procedimiento SQL vuelve a validar en la transacción de pago.

La tabla de historial distingue neto del cálculo e importe pagado por abono. Los conceptos del cálculo se muestran solo si la versión del recibo coincide con el detalle de la planilla; en otro caso no se inventa un snapshot.

## Pruebas y límites

La estructura se probó en una base temporal aislada sin empleados, planillas ni pagos de ejemplo. La base real se inspeccionó por separado. Se conservaron resultados en ../../docs/schema_check_isolated_result.txt y ../../docs/schema_coverage_readonly_result.txt. La prueba de creación no ejecuta por sí sola todos los procedimientos ni los recorridos funcionales del ERP. Los pagos reales y los históricos requieren sus documentos y autorizaciones.
`;
fs.writeFileSync(readme,text);
console.log('README SQL actualizado:',catalog.length,'archivos catalogados;',structureOrder.length,'de estructura.');

import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import dotenv from 'dotenv';
import {databaseScriptCatalog,buildStructureScript} from '../src/services/databaseScripts.js';
const root=new URL('../../',import.meta.url);
dotenv.config({path:new URL('.env',root),quiet:true});
const catalog=databaseScriptCatalog();
const missing=catalog.filter(script=>!script.exists);
if(missing.length){console.error('Faltan archivos SQL:',missing.map(script=>script.name).join(', '));process.exit(1);}
if(process.argv.includes('--rebuild')){console.error('La reconstruccion no forma parte del instalador seguro. No se ejecutaron cambios.');process.exit(1);}
if(!process.argv.includes('--bundle')&&!process.argv.includes('--apply')){
 console.log('PLAN DE ESTRUCTURA (sin ejecutar SQL)');
 for(const script of catalog)console.log(`${script.order??'-'} | ${script.category} | ${script.name}`);
 console.log('Generar script: npm run db:bundle. Aplicar exclusivamente a una instancia sin la base: npm run db:install -- --apply. Para una base existente, revisar solo migraciones faltantes con respaldo.');
 process.exit(0);
}
const output=new URL('Database/SQLServer_Completo/paquete_estructura_actual.sql',root);
fs.writeFileSync(output,buildStructureScript());
console.log('Paquete generado:',fileURLToPath(output));
if(process.argv.includes('--apply')){
 const server=process.env.DB_SERVER||'127.0.0.1';
 const target=process.env.DB_PORT?`${server},${process.env.DB_PORT}`:server;
 const result=spawnSync('sqlcmd',['-S',target,'-E','-C','-b','-f','65001','-i',fileURLToPath(output)],{cwd:fileURLToPath(root),stdio:'inherit'});
 if(result.error){console.error(result.error.message);process.exit(1);}
 process.exit(result.status??1);
}

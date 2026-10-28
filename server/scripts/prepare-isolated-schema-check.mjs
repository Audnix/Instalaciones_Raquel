import fs from 'node:fs';
import {randomUUID} from 'node:crypto';
import {buildStructureScript} from '../src/services/databaseScripts.js';
const name='Raquel_Schema_Check_20261025_'+randomUUID().replaceAll('-','').slice(0,8);
const source=buildStructureScript();
if(/\b(?:CREATE|ALTER)\s+LOGIN\b/i.test(source)||/DROP\s+DATABASE/i.test(source))throw Error('El paquete contiene operaciones fuera de una prueba de estructura');
fs.writeFileSync(new URL('../../docs/schema_check_target.json',import.meta.url),JSON.stringify({database:name,productionUntouched:true},null,2));
fs.writeFileSync(new URL('../../docs/schema_check_isolated.sql',import.meta.url),source.replaceAll('Instalaciones Raquel',name));
console.log(name);

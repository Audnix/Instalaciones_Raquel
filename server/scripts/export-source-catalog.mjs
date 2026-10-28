import fs from 'node:fs';
import {databaseScriptCatalog,structureOrder,requiredDatabaseTables} from '../src/services/databaseScripts.js';
fs.writeFileSync(new URL('../../docs/database_source_catalog_2026-10-25.json',import.meta.url),JSON.stringify({date:'2026-10-25',structureScripts:structureOrder.length,expectedTables:requiredDatabaseTables().length,catalog:databaseScriptCatalog()},null,2));

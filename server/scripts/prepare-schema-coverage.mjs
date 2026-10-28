import fs from 'node:fs';
import {requiredDatabaseTables,databaseScriptCatalog,structureOrder} from '../src/services/databaseScripts.js';
const target=JSON.parse(fs.readFileSync(new URL('../../docs/schema_check_target.json',import.meta.url),'utf8')).database;
if(!/^Raquel_Schema_Check_20261025_[0-9a-f]{8}$/.test(target))throw Error('Nombre temporal no autorizado');
const expected=requiredDatabaseTables();
const values=expected.map(name=>`(N'${name}')`).join(',');
const parts=[target,'Instalaciones Raquel'].map((name,index)=>`USE [${name}];\nGO\nSET NOCOUNT ON;\nDECLARE @Expected TABLE(Name SYSNAME); INSERT @Expected VALUES ${values};
SELECT DB_NAME() AS DatabaseName,${expected.length} AS ExpectedTables,(SELECT COUNT(*) FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo')) AS ActualTables,
(SELECT COUNT(*) FROM @Expected e WHERE OBJECT_ID(N'dbo.'+e.Name,N'U') IS NULL) AS MissingExpectedTables,
(SELECT COUNT(*) FROM sys.procedures WHERE schema_id=SCHEMA_ID(N'dbo')) AS Procedures,
(SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=0) AS ActiveForeignKeys,
(SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled=1) AS DisabledForeignKeys;
SELECT Name AS MissingTable FROM @Expected e WHERE OBJECT_ID(N'dbo.'+e.Name,N'U') IS NULL;
SELECT OBJECT_ID(N'dbo.usp_PayrollPaymentIntegrityVersion',N'P') AS Migration30,OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') AS Migration31,OBJECT_ID(N'dbo.usp_SnapshotLinkIntegrityVersion',N'P') AS Migration32;
SELECT (SELECT COUNT(*) FROM dbo.Employees) AS Employees,(SELECT COUNT(*) FROM dbo.PayrollRuns) AS PayrollRuns,(SELECT COUNT(*) FROM dbo.PayrollPayments) AS PayrollPayments,(SELECT COUNT(*) FROM dbo.CashMoves) AS CashMoves;
GO\n`);
fs.writeFileSync(new URL('../../docs/schema_coverage_readonly.sql',import.meta.url),parts.join('\n'));
fs.writeFileSync(new URL('../../docs/database_source_catalog_2026-10-25.json',import.meta.url),JSON.stringify({date:'2026-10-25',structureScripts:structureOrder.length,expectedTables:expected.length,catalog:databaseScriptCatalog()},null,2));
fs.writeFileSync(new URL('../../docs/schema_check_cleanup.sql',import.meta.url),`USE master;\nGO\nIF DB_ID(N'${target}') IS NOT NULL DROP DATABASE [${target}];\nGO\n`);

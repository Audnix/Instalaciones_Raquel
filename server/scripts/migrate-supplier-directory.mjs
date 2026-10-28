import { readFile, mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { resolve, dirname } from "node:path";
import dotenv from "dotenv";
import sql from "mssql";

const root=resolve(dirname(fileURLToPath(import.meta.url)),"../..");
dotenv.config({path:resolve(root,".env")});
const {getDatabase}=await import("../src/config/sqlserver.js");
let pool;
try {
  pool=await getDatabase();
  if(!pool)throw new Error("Falta configuración de SQL Server.");
  const check=await pool.request().query("SELECT DB_NAME() AS databaseName, OBJECT_ID(N'dbo.usp_UpsertSupplier',N'P') AS upsertId, OBJECT_ID(N'dbo.usp_ReadSupplierDirectory',N'P') AS directoryId");
  console.log(JSON.stringify(check.recordset[0]));
  if(!process.argv.includes("--apply")) {
    console.log("Diagnóstico de solo lectura. Usa --apply para aplicar únicamente la migración 19, sin semilla ni reconstrucción.");
  } else {
    if(!check.recordset[0].upsertId)throw new Error("Falta la migración 12. Aplica 11 y 12 con una cuenta de migraciones.");
    const old=await pool.request().query("SELECT OBJECT_DEFINITION(OBJECT_ID(N'dbo.usp_SaveErpState')) AS source");
    if(!old.recordset[0]?.source)throw new Error("Esta cuenta no puede respaldar la definición del procedimiento existente.");
    const backup=resolve(root,"work/supplier-migration-backups");
    await mkdir(backup,{recursive:true});
    await writeFile(resolve(backup,`snapshot-${Date.now()}.sql`),old.recordset[0].source,"utf8");
    const migration=await readFile(resolve(root,"Database/SQLServer_Completo/19_directorio_proveedores.sql"),"utf8");
    const transaction=new sql.Transaction(pool);
    await transaction.begin();
    try {
      for(const batch of migration.split(/^\s*GO\s*$/gim).filter(s=>s.trim()))await new sql.Request(transaction).batch(batch);
      await transaction.commit();
      console.log("Migración 19 confirmada. No se ejecutaron semillas ni scripts de reconstrucción.");
    }catch(error){await transaction.rollback().catch(()=>{});throw error;}
  }
}catch(error){console.error("No se completó la operación:",error.code||error.message);process.exitCode=1;}
finally{await pool?.close();}

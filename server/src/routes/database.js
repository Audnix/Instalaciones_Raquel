import {Router} from 'express';
import {requireAuth,requireHierarchy} from '../middleware/auth.js';
import {getDatabase} from '../config/sqlserver.js';
import {databaseScriptCatalog,requiredDatabaseTables,buildStructureScript} from '../services/databaseScripts.js';
import {readOperationalAudit} from '../services/operationalAudit.js';
export const databaseRouter=Router();
databaseRouter.use(requireAuth,requireHierarchy('superadmin'));
databaseRouter.get('/operations',async(_req,res,next)=>{
 try{
  const pool=await getDatabase();if(!pool)return res.status(503).json({message:'SQL Server no disponible.'});
  res.json(await readOperationalAudit(pool));
 }catch(error){next(error);}
});
databaseRouter.get('/status',async(_req,res,next)=>{
 try{
  const catalog=databaseScriptCatalog();const expected=requiredDatabaseTables();const pool=await getDatabase();
  if(!pool)return res.status(503).json({message:'SQL Server no configurado.'});
  const result=await pool.request().query(`SELECT name FROM sys.tables WHERE schema_id=SCHEMA_ID(N'dbo');
   SELECT COUNT(*) AS foreignKeys FROM sys.foreign_keys WHERE is_disabled=0;
   SELECT HAS_PERMS_BY_NAME(DB_NAME(),'DATABASE','VIEW DEFINITION') AS fullMetadataVisible,
    OBJECT_ID(N'dbo.usp_PayrollPaymentIntegrityVersion',N'P') AS paymentIntegrity,
    OBJECT_ID(N'dbo.usp_PayrollAccrualIntegrityVersion',N'P') AS payrollAccrual,
    OBJECT_ID(N'dbo.usp_SnapshotLinkIntegrityVersion',N'P') AS snapshotLinks;`);
  const visible=result.recordsets[0].map(row=>row.name);
  const names=new Set(visible.map(name=>name.toLowerCase()));
  const missing=expected.filter(name=>!names.has(name.toLowerCase()));
  res.json({readOnly:true,checkedAt:new Date().toISOString(),catalog,
   sourceComplete:catalog.every(script=>script.exists&&script.category!=='sin_clasificar'),expectedTables:expected.length,visibleTables:visible.length,
   missingOrInvisibleTables:missing,foreignKeys:result.recordsets[1][0].foreignKeys,
   metadata:result.recordsets[2][0],scope:'Cobertura de archivos, tablas declaradas y marcadores conocidos. No certifica columnas, reglas, datos ni recorridos funcionales completos.'});
 }catch(error){next(error);}
});
databaseRouter.get('/structure.sql',(_req,res,next)=>{
 try{res.attachment('Instalaciones_Raquel_estructura_nueva.sql').type('text/plain').send(buildStructureScript());}
 catch(error){next(error);}
});

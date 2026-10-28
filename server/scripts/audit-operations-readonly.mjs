import fs from 'node:fs';
import dotenv from 'dotenv';
import {readOperationalAudit} from '../src/services/operationalAudit.js';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');const pool=await getDatabase();
try{const report=await readOperationalAudit(pool);fs.writeFileSync(new URL('../../docs/operational_audit_2026-10-25.json',import.meta.url),JSON.stringify(report,null,2));console.log(JSON.stringify({collections:report.collections,issues:report.issues.length,staleSessions:report.staleSessions,payroll:report.payroll}));}finally{await pool.close();}

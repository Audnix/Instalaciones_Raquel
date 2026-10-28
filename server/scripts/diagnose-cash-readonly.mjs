import dotenv from 'dotenv';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');
const pool=await getDatabase();
try{const result=await pool.request().query("SELECT CONVERT(VARCHAR(10),SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time',23) AS today; SELECT CashSessionId,Account,CONVERT(VARCHAR(10),SessionDate,23) AS sessionDate,Status,OpeningBalance FROM dbo.CashSessions WHERE Status=N'abierta'; SELECT COUNT(*) AS movements FROM dbo.CashMoves;");console.log(JSON.stringify(result.recordsets));}finally{await pool.close();}

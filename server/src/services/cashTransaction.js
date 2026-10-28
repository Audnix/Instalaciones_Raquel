import sql from 'mssql';
import {CASH_LEDGER_CTE} from './cashLedgerSql.js';

function reject(number,message){throw Object.assign(new Error(message),{number});}
const same=(a,b)=>String(a??'')===String(b??'');
const iso=(value)=>value instanceof Date?value.toISOString().slice(0,10):String(value??'').slice(0,10);

// Mantiene los procedimientos existentes dentro de UNA transaccion exterior.
// Se utiliza el mismo bloqueo de cuenta que la migracion de pagos de nomina.
export function cashRequest(pool,{transaction}={}){
 const parameters=[];
 return {
  input(...args){parameters.push(args);return this;},
  async execute(procedure){
   const p=Object.fromEntries(parameters.map(([key,,value])=>[key,value]));
   const tx=transaction??new sql.Transaction(pool);let aborted=false;const onRollback=()=>{aborted=true;};tx.on('rollback',onRollback);
   if(!transaction) await tx.begin();
   const request=()=>new sql.Request(tx);
   try{
    const lock=async(resource)=>{
     const result=await request().input('Resource',sql.NVarChar(255),resource).query(`DECLARE @r INT;
      EXEC @r=sys.sp_getapplock @Resource=@Resource,@LockMode='Exclusive',@LockOwner='Transaction',@LockTimeout=10000;
      SELECT @r AS result;`);
     if(result.recordset[0].result<0) reject(50610,'La cuenta esta ocupada. Reintenta la misma operacion.');
    };
    if(p.OperationKey) await lock('cash-operation:'+p.OperationKey);
    let account=p.Account;
    if(!account&&p.SessionId){account=(await request().input('Id',sql.NVarChar(100),p.SessionId)
     .query('SELECT Account FROM dbo.CashSessions WHERE CashSessionId=@Id')).recordset[0]?.Account;}
    if(!account&&p.CashMoveId){account=(await request().input('Id',sql.NVarChar(100),p.CashMoveId)
     .query('SELECT Account FROM dbo.CashMoves WHERE CashMoveId=@Id')).recordset[0]?.Account;}
    if(account) await lock('cash-account:'+account);
    if(procedure==='dbo.usp_AbrirCaja'){
     const old=(await request().input('Key',sql.NVarChar(160),p.OperationKey)
      .query('SELECT * FROM dbo.CashSessions WHERE OperationKey=@Key')).recordset[0];
     if(old&&(!same(old.Account,p.Account)||Number(old.OpeningBalance)!==p.InitialBalance||!same(old.Currency,p.Currency)
       ||!same(old.Notes,p.Notes)||!same(old.OpenedByAppUserId,p.ActorId)||(p.SessionDate&&iso(old.SessionDate)!==iso(p.SessionDate))))
      reject(50611,'La clave de apertura ya fue utilizada con otros datos. Revisa la sesion existente.');
     if(!p.SessionDate){
      const date=old?.SessionDate??(await request().query("SELECT CONVERT(DATE,SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time') AS date")).recordset[0].date;
      const parameter=parameters.find(([name])=>name==='SessionDate');
      if(parameter) parameter[2]=date;else parameters.push(['SessionDate',sql.Date,date]);
     }
    }
    if(procedure==='dbo.usp_RegistrarMovimientoCaja'){
     if(['apertura','nomina'].includes(p.DocumentType)) reject(50612,'Las aperturas y pagos de nomina se registran desde su proceso correspondiente.');
     const old=(await request().input('Key',sql.NVarChar(160),p.OperationKey)
      .query('SELECT * FROM dbo.CashMoves WHERE OperationKey=@Key')).recordset[0];
     if(old){
      if(old.MoveState!=='confirmado') reject(50612,'La operacion original fue anulada. No se registra nuevamente con la misma clave.');
      if(!same(old.Account,p.Account)||!same(old.MoveType,p.MoveType)||Number(old.Amount)!==p.Amount||!same(old.Method,p.Method)
       ||!same(old.Concept,p.Concept)||!same(old.DocumentType,p.DocumentType)||!same(old.DocumentRef,p.DocumentRef)
       ||!same(old.ResponsibleAppUserId,p.ActorId)||(p.MoveDate&&iso(old.MoveDate)!==iso(p.MoveDate))
       ||(p.SessionId&&!same(old.SessionId,p.SessionId))) reject(50611,'La clave de movimiento ya fue utilizada con otros datos. Revisa el movimiento existente.');
     }else{
      const session=(await request().input('Account',sql.NVarChar(30),account).query(`SELECT TOP(1) * FROM dbo.CashSessions WITH(UPDLOCK,HOLDLOCK)
       WHERE Account=@Account AND Status=N'abierta'`)).recordset[0];
      if(!session) reject(50572,'Abre una sesion en la cuenta antes de registrar el movimiento.');
      if(p.SessionId&&!same(p.SessionId,session.CashSessionId)) reject(50573,'La sesion seleccionada ya no esta abierta.');
      const today=(await request().query("SELECT CONVERT(VARCHAR(10),SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time',23) AS date")).recordset[0].date;
      if(iso(session.SessionDate)!==iso(p.MoveDate||today)) reject(50612,`La sesion abierta corresponde al ${iso(session.SessionDate)} y el movimiento al ${iso(p.MoveDate||today)}. Realiza el arqueo y cierre de la sesion anterior y abre la del dia antes de registrar movimientos.`);
      // El banco tambien necesita vinculo de sesion para que el cierre incluya su movimiento.
      p.SessionId=session.CashSessionId;
      const existingParameter=parameters.find(([name])=>name==='SessionId');
      if(existingParameter) existingParameter[2]=p.SessionId;else parameters.push(['SessionId',sql.NVarChar(100),p.SessionId]);
      if(!p.MoveDate){const parameter=parameters.find(([name])=>name==='MoveDate');
       if(parameter) parameter[2]=today;else parameters.push(['MoveDate',sql.Date,today]);}
      if(!p.MoveTime){const time=(await request().query("SELECT CONVERT(VARCHAR(8),CONVERT(TIME(0),SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time')) AS time")).recordset[0].time;
       const parameter=parameters.find(([name])=>name==='MoveTime');if(parameter)parameter[2]=time;else parameters.push(['MoveTime',sql.NVarChar(8),time]);}
      if(p.MoveType==='salida'){
       const balance=(await request().input('Session',sql.NVarChar(100),p.SessionId).query(`SELECT s.OpeningBalance+
        ISNULL((SELECT SUM(CASE WHEN MoveType=N'entrada' THEN Amount ELSE -Amount END) FROM dbo.CashMoves
         WHERE SessionId=s.CashSessionId AND MoveState=N'confirmado' AND ISNULL(DocumentType,N'')<>N'apertura'),0) AS available
        FROM dbo.CashSessions s WHERE CashSessionId=@Session`)).recordset[0].available;
       if(p.Amount>balance) reject(50609,'La salida supera el saldo confirmado de la sesion.');
      }
     }
    }
    if(procedure==='dbo.usp_AnularMovimientoCaja'){
     const linked=(await request().input('Id',sql.NVarChar(100),p.CashMoveId).query(`SELECT m.DocumentType,
      (SELECT COUNT(*) FROM dbo.PayrollPayments p WHERE p.CashMoveId=m.CashMoveId AND p.Status=N'confirmado') AS payments
      FROM dbo.CashMoves m WHERE m.CashMoveId=@Id`)).recordset[0];
     if(linked?.payments||linked?.DocumentType==='apertura') reject(50612,'Este movimiento requiere el reverso de su proceso de origen. No puede anularse aisladamente.');
    }
    const req=request();for(const args of parameters) req.input(...args);
    const result=await req.execute(procedure);
    if(procedure==='dbo.usp_AbrirCaja'&&result.recordset[0]?.Resultado!=='repetida'){
     await request().input('Session',sql.NVarChar(100),result.recordset[0].CashSessionId).query(`UPDATE dbo.CashMoves
      SET MoveTime=CONVERT(TIME(0),SYSDATETIMEOFFSET() AT TIME ZONE 'Central America Standard Time')
      WHERE SessionId=@Session AND DocumentType=N'apertura'`);
    }
    if(procedure==='dbo.usp_RegistrarMovimientoCaja'&&result.recordset[0]?.Resultado!=='repetida'){
     // Monotonia de creacion incluso cuando dos solicitudes comparten milisegundo.
     const id=result.recordset[0]?.CashMoveId;
     await request().input('Id',sql.NVarChar(100),id).input('Account',sql.NVarChar(30),account).query(`
      DECLARE @latest DATETIMEOFFSET(3)=(SELECT MAX(CreatedAt) FROM dbo.CashMoves WHERE Account=@Account AND CashMoveId<>@Id);
      UPDATE dbo.CashMoves SET CreatedAt=CASE WHEN @latest>=CreatedAt THEN DATEADD(MILLISECOND,1,@latest) ELSE CreatedAt END WHERE CashMoveId=@Id;`);
     result.recordset=(await request().input('Id',sql.NVarChar(100),id).query(`${CASH_LEDGER_CTE} SELECT N'confirmada' AS Resultado,* FROM CashLedger WHERE CashMoveId=@Id`)).recordset;
    }
    if(!transaction) await tx.commit();return result;
   }catch(error){if(!transaction&&!aborted) await tx.rollback();throw error;}
   finally{tx.off('rollback',onRollback);}
  }
 };
}

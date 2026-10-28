import dotenv from 'dotenv';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const {getDatabase}=await import('../src/config/sqlserver.js');const p=await getDatabase();
try{console.log(JSON.stringify((await p.request().query(`DECLARE @id NVARCHAR(100)=N'run-mvfbxste-d83c30';
 SELECT Status,CalculationVersion,CalculationStale,CalculatedAt,PreparedByAppUserId,ReviewedByAppUserId,ApprovedByAppUserId,ApprovedAt,ReconciledAt FROM dbo.PayrollRuns WHERE PayrollRunId=@id;
 SELECT AccountingEntryId,Debit,Credit,DebitAccount,CreditAccount,OperationKey FROM dbo.AccountingEntries WHERE PayrollRunId=@id OR ReferenceId=@id;
 SELECT CashMoveId,MoveType,Amount,MoveState,OperationKey FROM dbo.CashMoves WHERE PayrollRunId=@id;
 SELECT FinanceMoveId,MoveType,Amount,OperationKey FROM dbo.FinanceMoves WHERE PayrollRunId=@id;
 SELECT COUNT(*) AS obligations FROM dbo.PayrollInstitutionalObligations WHERE PayrollRunId=@id;
 SELECT name,is_nullable FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.PayrollHistoryEvents');`)).recordsets));}finally{await p.close();}

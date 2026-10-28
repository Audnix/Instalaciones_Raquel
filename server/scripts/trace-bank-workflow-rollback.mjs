import sql from 'mssql';
for(const method of ['query','execute']){const original=sql.Request.prototype[method];sql.Request.prototype[method]=async function(...args){const label=String(args[0]).trim().replace(/\s+/g,' ').slice(0,105);const start=Date.now();console.log('START',method,label);try{return await original.apply(this,args);}finally{console.log('END',Date.now()-start,method,label);}};}
await import('./verify-bank-workflow-rollback.mjs');

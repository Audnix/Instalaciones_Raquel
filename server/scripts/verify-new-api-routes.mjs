import dotenv from 'dotenv';
dotenv.config({path:new URL('../../.env',import.meta.url),quiet:true});
const base=`http://127.0.0.1:${Number(process.env.PORT)||4000}`;
for(const path of ['/health','/api/database/status','/api/database/structure.sql']){
 const response=await fetch(base+path,{signal:AbortSignal.timeout(5000)});
 console.log(path,response.status);
 if(path!=='/health'&&response.status!==401)throw Error('No se confirmo la ruta protegida: '+path);
}

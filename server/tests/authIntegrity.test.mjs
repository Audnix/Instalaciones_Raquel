import test from 'node:test';
import assert from 'node:assert/strict';
import {createAuthMiddleware,signUser} from '../src/middleware/auth.js';
const user={id:'employee-test',name:'Prueba',hierarchy:'superadmin',areas:['finanzas']};
const token=signUser(user,'65522ce9-359b-49d1-a018-2506ef6ceacc');
const current={AppUserId:user.id,Name:user.name,Hierarchy:'estandar',AreasJson:'[{"area":"inventario"}]',IsActive:true,MustChangePassword:true};
async function invoke(loadDatabase,bearer=token){
  const req={headers:{authorization:`Bearer ${bearer}`}};
  const result={status:200,next:false};
  const res={status(code){result.status=code;return this;},json(body){result.body=body;return this;}};
  await createAuthMiddleware({loadDatabase})(req,res,()=>{result.next=true;});
  return {...result,user:req.user};
}
const poolFor=(row)=>async()=>({request(){return{input(){return this;},async execute(){return{recordset:row?[row]:[]};}};}});
test('permisos actuales sustituyen los privilegios antiguos del token',async()=>{
  const result=await invoke(poolFor(current));
  assert.equal(result.next,true);assert.equal(result.user.hierarchy,'estandar');
  assert.deepEqual(result.user.areas,['inventario']);assert.equal(result.user.mustChangePassword,true);
});
test('si falla SQL no se conserva un permiso antiguo',async()=>{
  const result=await invoke(async()=>{throw Error('offline');});assert.equal(result.status,503);assert.equal(result.next,false);
});
test('sesion revocada o de otro usuario se rechaza',async()=>{
  assert.equal((await invoke(poolFor(null))).status,401);
  assert.equal((await invoke(poolFor({...current,AppUserId:'another'}))).status,401);
});
test('token sin sesion y areas corruptas no habilitan operaciones',async()=>{
  assert.equal((await invoke(poolFor(current),signUser(user))).status,401);
  assert.equal((await invoke(poolFor({...current,AreasJson:'invalid'}))).status,503);
});

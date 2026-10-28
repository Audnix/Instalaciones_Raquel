import test from "node:test";
import assert from "node:assert/strict";
import {supplierInput,supplierRights,resolveSupplierChange,attachmentBytes,dateOnly} from "../src/services/supplierDirectory.js";
const admin={id:"admin",name:"Responsable",hierarchy:"administrador",areas:["compras"]};
const standard={id:"user",name:"Operador",hierarchy:"estandar",areas:["compras"]};
const input=()=>supplierInput.parse({name:"Proveedor de prueba",category:"materiales",specialty:"vidrio",email:"ventas@example.test",currency:"NIO",leadDays:null,status:"pendiente",reviewStatus:"pendiente",nextReviewDate:"",contacts:[],documents:[],expectedVersion:null,mutationId:"9c7b35f1-a684-43a8-8b95-9787c252129e",reason:"Registro de prueba"});
const doc=()=>({id:"1167ada7-c4a2-4ca6-8d0c-6849ea1886b7",title:"Ficha técnica",type:"Referencia",reference:"Expediente físico 001",issuedOn:"2026-01-01",expiresOn:"",review:"pendiente",reviewNote:"",fileName:"",fileType:"",uploadedAt:"",reviewedAt:"",reviewedBy:""});
test("área y jerarquía limitan consulta, escritura y aprobación",()=>{
 assert.equal(supplierRights({...admin,areas:["ventas"]}).read,false);
 assert.deepEqual(supplierRights({...admin,hierarchy:"invitado"}),{read:true,write:false,approve:false});
 assert.equal(supplierRights(standard).approve,false);assert.equal(supplierRights({hierarchy:"superadmin",areas:[]}).approve,true);
});
test("fechas reales, años bisiestos y referencia documental",()=>{
 assert.equal(dateOnly.safeParse("2026-02-30").success,false);assert.equal(dateOnly.safeParse("2024-02-29").success,true);
 assert.equal(supplierInput.safeParse({...input(),documents:[{...doc(),expiresOn:"2025-12-31"}]}).success,false);
});
test("datos de contacto y resolución deben tener fundamento",()=>{
 assert.equal(supplierInput.safeParse({...input(),email:"",phone:""}).success,false);
 assert.equal(supplierInput.safeParse({...input(),reviewStatus:"aprobado"}).success,false);
});
test("operador puede registrar pero no autoaprobar o habilitar",()=>{
 assert.equal(resolveSupplierChange(input(),null,standard).reviewStatus,"pendiente");
 assert.throws(()=>resolveSupplierChange({...input(),status:"activo"},null,standard),e=>e.status===403);
 assert.throws(()=>resolveSupplierChange({...input(),reviewStatus:"aprobado",reviewEvidence:"Revisión"},null,standard),e=>e.status===403);
});
test("responsable y fechas proceden del servidor",()=>{
 const d=resolveSupplierChange({...input(),reviewStatus:"aprobado",reviewEvidence:"Expediente revisado",status:"inactivo"},null,admin,"2026-10-18T15:00:00Z");
 assert.equal(d.reviewedBy,admin.name);assert.equal(d.inactiveAt,"2026-10-18T15:00:00Z");assert.equal(d.updatedBy,admin.name);
});
test("no se borran ni sobrescriben documentos históricos",()=>{
 const old={...input(),documents:[doc()]};assert.throws(()=>resolveSupplierChange(input(),old,admin));
 assert.throws(()=>resolveSupplierChange({...input(),documents:[{...doc(),title:"Otro título"}]},old,admin));
});
test("operador no puede falsificar revisión o su autor",()=>{
 assert.throws(()=>resolveSupplierChange({...input(),documents:[{...doc(),review:"aceptado",reviewNote:"ok"}]},null,standard),e=>e.status===403);
 const d=resolveSupplierChange({...input(),documents:[{...doc(),reviewedBy:"Falso",reviewedAt:"ayer"}]},null,standard,"2026-10-18T15:00:00Z");
 assert.equal(d.documents[0].reviewedBy,"");assert.equal(d.documents[0].uploadedAt,"2026-10-18T15:00:00Z");
});
test("no se acepta un documento vencido",()=>{
 const d={...doc(),expiresOn:"2026-01-02"};assert.throws(()=>resolveSupplierChange({...input(),documents:[{...d,review:"aceptado",reviewNote:"revisión"}]},{...input(),documents:[d]},admin,"2026-10-18T15:00:00Z"));
});
test("archivos privados verifican tamaño, tipo y firma",()=>{
 const d={...doc(),fileName:"ficha.pdf",fileType:"application/pdf"};
 const valid={...input(),documents:[d],attachment:{documentId:d.id,content:Buffer.from("%PDF-1.7\nfixture").toString("base64")}};
 assert.ok(attachmentBytes(valid,null));
 assert.throws(()=>attachmentBytes({...valid,attachment:{...valid.attachment,content:Buffer.from("<script>malicioso</script>").toString("base64")}},null));
 assert.throws(()=>attachmentBytes(valid,{documents:[d]}));
});

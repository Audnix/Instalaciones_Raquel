import { Router } from "express";
import { createHash } from "node:crypto";
import sql from "mssql";
import { z } from "zod";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth } from "../middleware/auth.js";
import { supplierInput, supplierRights, resolveSupplierChange, attachmentBytes } from "../services/supplierDirectory.js";

export const supplierDirectoryRouter = Router();
supplierDirectoryRouter.use(requireAuth, async (req,res,next) => {
  if (!supplierRights(req.user).read) return res.status(403).json({message:"Tu cuenta no incluye Compras y proveedores."});
  // Fail closed for this module even when the shared middleware tolerates SQL outages.
  try {
    if (!req.user.sessionId) return res.status(401).json({message:"Inicia sesión nuevamente para abrir proveedores."});
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({message:"SQL Server no está configurado."});
    const session = await pool.request().input("SessionId",sql.UniqueIdentifier,req.user.sessionId).execute("dbo.usp_GetAppUserSession");
    const row = session.recordset?.[0];
    if (!row) return res.status(401).json({message:"La sesión ya no está activa."});
    req.user.hierarchy = row.Hierarchy;
    req.user.name = row.Name;
    req.user.areas = JSON.parse(row.AreasJson || "[]").map(a => a.area);
    if (!supplierRights(req.user).read) return res.status(403).json({message:"Tu cuenta ya no incluye Compras."});
    req.supplierPool = pool;
    next();
  } catch { res.status(503).json({message:"No se pudo validar la sesión con SQL Server. Tus cambios no se han guardado."}); }
});

function normalize(row) {
  const profile = JSON.parse(row.profile || "{}");
  return {...profile,...row,profile:undefined,nextReviewDate:row.nextReviewDate ?? "",reviewStatus:profile.reviewStatus ?? "pendiente",contacts:profile.contacts ?? [],documents:profile.documents ?? []};
}
function failure(error,res) {
  if (error.name === "ZodError") return res.status(400).json({message:error.issues.map(i=>`${i.path.join(".")}: ${i.message}`).join(" · ")});
  if ([50502,50503,50309,50310,2601,2627].includes(error.number)) return res.status(409).json({message:error.number===50503 ? "Otro usuario modificó este proveedor. Recarga y compara antes de guardar." : "La operación coincide con un registro o solicitud existente. Revisa nombre e identificación fiscal."});
  if (error.status) return res.status(error.status).json({message:error.message});
  console.error("Directorio de proveedores",error.code || error.number || error.name);
  return res.status(503).json({message:"No se pudo completar la operación en SQL Server. Comprueba la conexión y la migración 19_directorio_proveedores.sql. Conserva el formulario y reintenta la misma operación."});
}
const idSchema = z.string().trim().min(1).max(100);
supplierDirectoryRouter.get("/",async(req,res)=>{
  try {
    const result = await req.supplierPool.request().execute("dbo.usp_ReadSupplierDirectory");
    res.set("Cache-Control","no-store").json({suppliers:result.recordset.map(normalize),permissions:supplierRights(req.user)});
  } catch(error) { failure(error,res); }
});
supplierDirectoryRouter.get("/:id",async(req,res)=>{
  try {
    const id=idSchema.parse(req.params.id);
    const result=await req.supplierPool.request().input("PartyId",sql.NVarChar(100),id).execute("dbo.usp_ReadSupplierDirectory");
    if (!result.recordset[0]) return res.status(404).json({message:"Proveedor no encontrado."});
    const events=(result.recordsets[1] ?? []).map(e=>({...e,beforeData:e.beforeData ? JSON.parse(e.beforeData):null,afterData:JSON.parse(e.afterData)}));
    res.set("Cache-Control","no-store").json({supplier:normalize(result.recordset[0]),events,purchases:result.recordsets[2] ?? [],files:result.recordsets[3] ?? []});
  } catch(error) { failure(error,res); }
});
supplierDirectoryRouter.put("/:id",async(req,res)=>{
  try {
    if (!supplierRights(req.user).write) return res.status(403).json({message:"No tienes permiso para guardar proveedores."});
    const id=idSchema.parse(req.params.id),input=supplierInput.parse(req.body);
    const hash=createHash("sha256").update(JSON.stringify(input)).digest("hex");
    const receipt=await req.supplierPool.request().input("MutationId",sql.UniqueIdentifier,input.mutationId).execute("dbo.usp_ReadSupplierDirectoryReceipt");
    if (receipt.recordset[0]) {
      const r=receipt.recordset[0];
      if (r.PartyId!==id || r.ActorId!==req.user.id || r.RequestHash!==hash) return res.status(409).json({message:"Esta operación ya se utilizó con datos diferentes."});
      return res.json({saved:true,supplier:normalize(JSON.parse(r.Response)),replayed:true});
    }
    const current=await req.supplierPool.request().input("PartyId",sql.NVarChar(100),id).execute("dbo.usp_ReadSupplierDirectory");
    const previous=current.recordset[0] ? normalize(current.recordset[0]):null;
    if (previous && previous.version !== input.expectedVersion) return res.status(409).json({message:"Otro usuario modificó el expediente. Conserva tus cambios y recarga para comparar."});
    if (!previous && input.expectedVersion) return res.status(409).json({message:"El proveedor solicitado ya no está disponible."});
    const data=resolveSupplierChange(input,previous,req.user);
    const bytes=attachmentBytes(input,previous);
    for (const d of input.documents) {
      const old=previous?.documents?.find(p=>p.id===d.id);
      if (!old && d.fileName && d.id!==input.attachment?.documentId) return res.status(400).json({message:"Falta el archivo del documento nuevo."});
      if (!old && !d.fileName && !d.reference) return res.status(400).json({message:"Agrega un archivo o una referencia documental."});
    }
    const result=await req.supplierPool.request()
      .input("PartyId",sql.NVarChar(100),id).input("Data",sql.NVarChar(sql.MAX),JSON.stringify(data))
      .input("ExpectedVersion",sql.VarChar(18),input.expectedVersion).input("MutationId",sql.UniqueIdentifier,input.mutationId)
      .input("ActorId",sql.NVarChar(100),req.user.id).input("ActorName",sql.NVarChar(200),req.user.name)
      .input("Reason",sql.NVarChar(500),input.reason).input("RequestHash",sql.VarChar(64),hash)
      .input("FileId",sql.UniqueIdentifier,input.attachment?.documentId ?? null).input("FileContent",sql.VarBinary(sql.MAX),bytes)
      .execute("dbo.usp_SaveSupplierDirectory");
    res.json({saved:true,supplier:normalize(JSON.parse(result.recordset[0].response))});
  } catch(error) { failure(error,res); }
});
supplierDirectoryRouter.get("/:id/documents/:documentId",async(req,res)=>{
  try {
    const id=idSchema.parse(req.params.id), doc=z.string().uuid().parse(req.params.documentId);
    const result=await req.supplierPool.request().input("PartyId",sql.NVarChar(100),id).input("DocumentId",sql.UniqueIdentifier,doc).execute("dbo.usp_ReadSupplierDirectoryFile");
    const file=result.recordset[0];
    if (!file) return res.status(404).json({message:"Archivo no encontrado."});
    res.set({"Content-Type":file.ContentType,"Content-Disposition":`attachment; filename*=UTF-8''${encodeURIComponent(file.FileName.replace(/[\r\n]/g,""))}`,"Cache-Control":"no-store","X-Content-Type-Options":"nosniff"}).send(file.Content);
  } catch(error) { failure(error,res); }
});

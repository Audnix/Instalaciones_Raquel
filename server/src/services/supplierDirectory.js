import { z } from "zod";

export const categories = ["materiales", "servicios", "transporte", "herramientas", "otro"];
export const specialties = ["perfiles", "vidrio", "herrajes", "consumibles", "transporte", "servicios", "otro"];
export const dateOnly = z.string().refine((v) => !v || (/^\d{4}-\d{2}-\d{2}$/.test(v) && !Number.isNaN(Date.parse(`${v}T00:00:00Z`)) && new Date(`${v}T00:00:00Z`).toISOString().slice(0, 10) === v), "La fecha no es válida.");
const email = z.union([z.string().trim().email().max(320), z.literal("")]);
const text = (n) => z.string().trim().max(n).default("");
export const supplierInput = z.object({
  name: z.string().trim().min(1).max(240), legalName: text(240), category: z.enum(categories),
  specialty: z.enum(specialties), contact: text(200), contactRole: text(120), phone: text(80), email,
  address: text(500), dispatchAddress: text(500), productsServices: text(1000), ruc: text(40),
  paymentTerms: text(80), currency: z.enum(["NIO", "USD"]), leadDays: z.number().int().min(0).max(3650).nullable(),
  bankDetails: text(500), discounts: text(500), transportTerms: text(500),
  observations: text(2000), status: z.enum(["activo", "pendiente", "inactivo"]),
  reviewStatus: z.enum(["pendiente", "en_revision", "aprobado", "rechazado"]), reviewEvidence: text(2000),
  nextReviewDate: dateOnly, reason: z.string().trim().min(3).max(500),
  contacts: z.array(z.object({ name: z.string().trim().min(1).max(200), role: text(120), phone: text(80), email })).max(20),
  documents: z.array(z.object({
    id: z.string().uuid(), title: z.string().trim().min(1).max(240), type: text(100),
    reference: text(500), issuedOn: dateOnly, expiresOn: dateOnly,
    review: z.enum(["pendiente", "aceptado", "rechazado"]), reviewNote: text(1000),
    fileName: text(200), fileType: text(80), uploadedAt: text(40), reviewedAt: text(40), reviewedBy: text(200)
  }).superRefine((doc, ctx) => {
    if (doc.issuedOn && doc.expiresOn && doc.expiresOn < doc.issuedOn) ctx.addIssue({code:"custom", path:["expiresOn"], message:"El vencimiento no puede ser anterior a la emisión."});
  })).max(50),
  expectedVersion: z.string().regex(/^0x[0-9a-f]{16}$/i).nullable(), mutationId: z.string().uuid(),
  attachment: z.object({ documentId: z.string().uuid(), content: z.string().max(4200000) }).optional()
}).superRefine((v, ctx) => {
  if (!v.phone && !v.email) ctx.addIssue({code:"custom", path:["phone"], message:"Indica un teléfono o correo."});
  if (v.leadDays !== null && v.leadDays < 0) ctx.addIssue({code:"custom", path:["leadDays"], message:"El plazo debe ser positivo."});
  if (["aprobado", "rechazado"].includes(v.reviewStatus) && !v.reviewEvidence) ctx.addIssue({code:"custom", path:["reviewEvidence"], message:"La resolución requiere evidencia o fundamento."});
  if (new Set(v.documents.map(d => d.id)).size !== v.documents.length) ctx.addIssue({code:"custom", path:["documents"], message:"Documento duplicado."});
});

export function supplierRights(user) {
  const area = user?.hierarchy === "superadmin" || user?.areas?.includes("compras");
  return { read: Boolean(area), write: Boolean(area && ["superadmin", "administrador", "estandar"].includes(user?.hierarchy)), approve: Boolean(area && ["superadmin", "administrador"].includes(user?.hierarchy)) };
}

export function resolveSupplierChange(input, previous, user, clock = new Date().toISOString()) {
  const rights = supplierRights(user);
  if (!rights.write) throw Object.assign(new Error("No puedes modificar proveedores."), {status:403});
  if (!rights.approve && (input.reviewStatus !== (previous?.reviewStatus ?? "pendiente") || input.reviewEvidence !== (previous?.reviewEvidence ?? "") || input.status !== (previous?.status ?? "pendiente"))) {
    throw Object.assign(new Error("Cambiar estado o resolución requiere un administrador de Compras."), {status:403});
  }
  const originalDocs = new Map((previous?.documents ?? []).map(d => [d.id, d]));
  if ([...originalDocs.keys()].some(id => !input.documents.some(d => d.id === id))) throw Object.assign(new Error("Conserva los documentos históricos; agrega una nueva versión."), {status:400});
  const documents = input.documents.map(d => {
    const old = originalDocs.get(d.id);
    if (old && JSON.stringify([d.title,d.type,d.reference,d.issuedOn,d.expiresOn,d.fileName,d.fileType]) !== JSON.stringify([old.title,old.type,old.reference,old.issuedOn,old.expiresOn,old.fileName,old.fileType])) throw Object.assign(new Error("Los documentos son históricos: agrega otra versión para corregir sus datos."), {status:400});
    const changed = d.review !== (old?.review ?? "pendiente") || d.reviewNote !== (old?.reviewNote ?? "");
    if (changed && !rights.approve) throw Object.assign(new Error("Revisar documentos requiere aprobación."), {status:403});
    if (changed && !d.reviewNote) throw Object.assign(new Error("Explica la revisión del documento."), {status:400});
    if (old && (d.review !== "pendiente") && d.expiresOn && d.expiresOn < clock.slice(0,10) && d.review === "aceptado" && changed) throw Object.assign(new Error("No se puede aceptar un documento vencido."), {status:400});
    return {...d, uploadedAt: old?.uploadedAt ?? clock, reviewedAt: changed ? clock : old?.reviewedAt ?? "", reviewedBy: changed ? user.name : old?.reviewedBy ?? ""};
  });
  const reviewChanged = input.reviewStatus !== (previous?.reviewStatus ?? "pendiente") || input.reviewEvidence !== (previous?.reviewEvidence ?? "");
  const {expectedVersion, mutationId, attachment, reason, ...data} = input;
  return {...data, documents, reviewedAt: reviewChanged ? clock : previous?.reviewedAt ?? "", reviewedBy: reviewChanged ? user.name : previous?.reviewedBy ?? "", inactiveAt: input.status === "inactivo" ? previous?.inactiveAt || clock : "", updatedBy:user.name};
}

export function attachmentBytes(input, previous) {
  if (!input.attachment) return null;
  const doc = input.documents.find(d => d.id === input.attachment.documentId);
  if (!doc || previous?.documents?.some(d => d.id === doc.id)) throw Object.assign(new Error("El adjunto requiere un documento nuevo."), {status:400});
  const content = input.attachment.content;
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(content) || content.length % 4) throw Object.assign(new Error("Archivo inválido."), {status:400});
  const bytes = Buffer.from(content,"base64");
  if (!bytes.length || bytes.length > 3*1024*1024) throw Object.assign(new Error("Máximo 3 MB por archivo."), {status:400});
  const valid = (doc.fileType === "application/pdf" && bytes.subarray(0,5).toString() === "%PDF-") || (doc.fileType === "image/png" && bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) || (doc.fileType === "image/jpeg" && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255);
  if (!valid) throw Object.assign(new Error("Solo PDF, PNG o JPEG con contenido válido."), {status:400});
  return bytes;
}

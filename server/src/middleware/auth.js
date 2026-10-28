import jwt from "jsonwebtoken";
import sql from "mssql";
import { getDatabase } from "../config/sqlserver.js";

const secret = () => process.env.JWT_SECRET || "raquel-erp-jwt-secret-secure-key-2026";

export function signUser(user, sessionId) {
  return jwt.sign(
    {
      sub: user.id || user.AppUserId,
      sessionId,
      email: user.email || user.Email,
      name: user.full_name || user.name || user.Name,
      hierarchy: user.hierarchy || user.Hierarchy,
      areas: user.areas || []
    },
    secret(),
    { expiresIn: "12h" }
  );
}

// La jerarquia y las areas se leen de la sesion vigente, no de un token antiguo.
export function createAuthMiddleware({ loadDatabase = getDatabase } = {}) {
  return async function requireAuth(req, res, next) {
    const header = req.headers.authorization;
    const token = header?.startsWith("Bearer ") ? header.slice(7) : null;
    if (!token) return res.status(401).json({ message: "Se requiere autenticacion activa." });
    let payload;
    try { payload = jwt.verify(token, secret()); }
    catch { return res.status(401).json({ message: "Token invalido o expirado." }); }
    if (!payload.sessionId || !payload.sub) return res.status(401).json({ message: "Inicie sesion nuevamente para verificar sus permisos." });
    let row;
    try {
      const pool = await loadDatabase();
      if (!pool) throw new Error("SQL no disponible");
      const result = await pool.request().input("SessionId", sql.UniqueIdentifier, payload.sessionId)
        .execute("dbo.usp_GetAppUserSession");
      row = result.recordset?.[0];
    } catch {
      return res.status(503).json({ code: "SESSION_CHECK_UNAVAILABLE", message: "No se pudo verificar la sesion y sus permisos. Reintente cuando vuelva la conexion." });
    }
    if (!row || row.AppUserId !== payload.sub || !row.IsActive) {
      return res.status(401).json({ message: "Sesion revocada o expirada. Inicie sesion nuevamente." });
    }
    let areas=[];
    try { areas=JSON.parse(row.AreasJson || "[]").map((area)=>area.area).filter((area)=>typeof area==="string"); }
    catch { return res.status(503).json({ message: "No se pudieron verificar las areas autorizadas." }); }
    req.user = { id:row.AppUserId,sessionId:payload.sessionId,email:row.Email,name:row.Name,
      hierarchy:row.Hierarchy,areas,mustChangePassword:Boolean(row.MustChangePassword) };
    return next();
  };
}
export const requireAuth = createAuthMiddleware();

export function requireHierarchy(...hierarchies) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ message: "Autenticación requerida." });
    if (req.user.hierarchy === "superadmin") return next();
    if (!hierarchies.includes(req.user.hierarchy)) {
      return res.status(403).json({ message: "Acceso no autorizado para tu nivel de rol." });
    }
    return next();
  };
}

export function requireArea(area) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ message: "Autenticación requerida." });
    if (req.user.hierarchy === "superadmin") return next();
    if (!req.user.areas?.includes(area)) {
      return res.status(403).json({ message: `Acceso denegado: tu cuenta no incluye el área ${area}.` });
    }
    return next();
  };
}

export function requireHrManagement(req, res, next) {
  if (!req.user) return res.status(401).json({ message: "Autenticación requerida." });
  if (req.user.mustChangePassword) {
    return res.status(403).json({ message: "Debes cambiar la contraseña temporal antes de continuar." });
  }
  const isSuper = req.user.hierarchy === "superadmin";
  const isAuthorizedAdmin = (req.user.hierarchy === "administrador" || req.user.hierarchy === "estandar")
    && req.user.areas?.includes("rrhh");

  if (!isSuper && !isAuthorizedAdmin) {
    return res.status(403).json({
      message: "Operación restringida a personal autorizado de Talento Humano."
    });
  }
  return next();
}


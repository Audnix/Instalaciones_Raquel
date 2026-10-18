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

export async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : null;
  if (!token) {
    return res.status(401).json({ message: "Se requiere autenticación activa." });
  }

  try {
    const payload = jwt.verify(token, secret());

    // Validar en SQL Server si la sesión no fue revocada
    if (payload.sessionId) {
      try {
        const pool = await getDatabase();
        if (pool) {
          const check = await pool.request()
            .input("SessionId", sql.UniqueIdentifier, payload.sessionId)
            .execute("dbo.usp_GetAppUserSession");

          if (!check.recordset || check.recordset.length === 0) {
            return res.status(401).json({ message: "Sesión revocada o expirada. Inicie sesión nuevamente." });
          }
          const sessionRow = check.recordset[0];
          payload.name = sessionRow.Name;
          payload.email = sessionRow.Email;
          payload.hierarchy = sessionRow.Hierarchy;
          if (sessionRow.AreasJson) {
            try {
              payload.areas = JSON.parse(sessionRow.AreasJson).map((a) => a.area);
            } catch {
              payload.areas = [];
            }
          }
        }
      } catch (dbErr) {
        // Si hay un fallo temporal en el pool de DB, continuamos con el token verificado si no es revocación
        console.warn("Validación de sesión en DB no disponible momentáneamente:", dbErr.message);
      }
    }

    req.user = {
      id: payload.sub,
      sessionId: payload.sessionId,
      email: payload.email,
      name: payload.name,
      hierarchy: payload.hierarchy,
      areas: payload.areas || []
    };
    return next();
  } catch (err) {
    return res.status(401).json({ message: "Token inválido o expirado." });
  }
}

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

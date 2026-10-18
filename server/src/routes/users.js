import { Router } from "express";
import crypto from "node:crypto";
import { z } from "zod";
import sql from "mssql";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth, requireHierarchy } from "../middleware/auth.js";

export const usersRouter = Router();

// Solo superadmin y administradores pueden acceder a la gestión de cuentas
usersRouter.use(requireAuth, requireHierarchy("superadmin", "administrador"));

const createUserSchema = z.object({
  name: z.string().min(2, "Nombre requerido"),
  email: z.string().email("Correo electrónico inválido"),
  hierarchy: z.enum(["superadmin", "administrador", "estandar", "invitado"]),
  areas: z.array(z.string()).min(1, "Debe asignar al menos un área")
});

function hashInvitationToken(token) {
  return crypto.createHash("sha256").update(token.trim()).digest("hex");
}

/* =========================================================
   1. LISTAR USUARIOS Y ESTADO DE INVITACIONES
   ========================================================= */
usersRouter.get("/", async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    const result = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .execute("dbo.usp_ListAppUsersWithStatus");

    const users = (result.recordset || []).map((row) => {
      let areas = [];
      if (row.AreasJson) {
        try {
          areas = JSON.parse(row.AreasJson).map((a) => a.area);
        } catch {
          areas = [];
        }
      }
      let invitation = null;
      if (row.LatestInvitationJson) {
        try {
          invitation = JSON.parse(row.LatestInvitationJson);
        } catch {
          invitation = null;
        }
      }
      return {
        id: row.AppUserId,
        name: row.Name,
        email: row.Email,
        hierarchy: row.Hierarchy,
        active: Boolean(row.IsActive),
        hasPasswordSet: Boolean(row.HasPasswordSet),
        mustChangePassword: Boolean(row.MustChangePassword),
        failedLoginCount: row.FailedLoginCount || 0,
        lockedUntil: row.LockedUntil,
        areas,
        invitation,
        activeSessionsCount: row.ActiveSessionsCount || 0
      };
    });

    res.json({ users });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   2. CREAR USUARIO Y GENERAR INVITACIÓN INDIVIDUAL SEGURA
   ========================================================= */
usersRouter.post("/", async (req, res, next) => {
  try {
    const { name, email, hierarchy, areas } = createUserSchema.parse(req.body);

    // Un administrador de área no puede otorgarse ni otorgar privilegios superiores
    if (req.user.hierarchy === "administrador") {
      if (hierarchy === "superadmin" || hierarchy === "administrador") {
        return res.status(403).json({
          message: "Un administrador de área no puede crear cuentas con jerarquía de Administrador o Superadministrador."
        });
      }
      // Verificar que las áreas asignadas estén dentro de las áreas del administrador
      const invalidAreas = areas.filter((area) => !req.user.areas.includes(area));
      if (invalidAreas.length > 0) {
        return res.status(403).json({
          message: `No tienes autorización para asignar áreas fuera de tu alcance: ${invalidAreas.join(", ")}.`
        });
      }
    }

    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    // Generar token seguro e individual de un solo uso
    const rawToken = crypto.randomBytes(24).toString("hex");
    const tokenHash = hashInvitationToken(rawToken);
    const tokenPrefix = rawToken.slice(0, 8);
    const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000); // 48 horas de vigencia

    const isSmtpConfigured = Boolean(process.env.SMTP_HOST && process.env.SMTP_USER);
    const deliveryMethod = isSmtpConfigured ? "smtp_email" : "manual_authorized_delivery";
    const deliveryStatus = isSmtpConfigured ? "sent" : "manual_ready";
    const deliveryNotes = isSmtpConfigured
      ? "Enviada automáticamente por SMTP."
      : "Entrega presencial/autorizada generada por el administrador.";

    const result = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("Name", sql.NVarChar(200), name.trim())
      .input("Email", sql.NVarChar(320), email.trim().toLowerCase())
      .input("Hierarchy", sql.NVarChar(50), hierarchy)
      .input("AreasJson", sql.NVarChar(sql.MAX), JSON.stringify(areas))
      .input("DeliveryMethod", sql.NVarChar(40), deliveryMethod)
      .input("DeliveryStatus", sql.NVarChar(40), deliveryStatus)
      .input("DeliveryNotes", sql.NVarChar(500), deliveryNotes)
      .input("TokenHash", sql.Char(64), tokenHash)
      .input("TokenPrefix", sql.NVarChar(12), tokenPrefix)
      .input("ExpiresAt", sql.DateTimeOffset(3), expiresAt)
      .execute("dbo.usp_CreateUserWithInvitation");

    const created = result.recordset?.[0];
    const invitationUrl = `/invitacion/${rawToken}`;

    res.status(201).json({
      ok: true,
      user: {
        id: created?.AppUserId,
        name,
        email,
        hierarchy,
        areas,
        active: true
      },
      invitation: {
        id: created?.InvitationId,
        tokenPrefix,
        expiresAt,
        deliveryMethod,
        invitationUrl,
        rawToken // Se entrega de una sola vez al administrador para su entrega autorizada
      },
      message: isSmtpConfigured
        ? "Usuario creado e invitación enviada por correo electrónico."
        : "Usuario registrado. El correo SMTP no está configurado; copie el enlace de invitación para entrega autorizada."
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   3. REENVIAR O REGENERAR INVITACIÓN (INVALIDA LA ANTERIOR)
   ========================================================= */
usersRouter.post("/:id/resend-invitation", async (req, res, next) => {
  try {
    const appUserId = req.params.id;
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    const rawToken = crypto.randomBytes(24).toString("hex");
    const tokenHash = hashInvitationToken(rawToken);
    const tokenPrefix = rawToken.slice(0, 8);
    const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000); // 48 horas

    const isSmtpConfigured = Boolean(process.env.SMTP_HOST && process.env.SMTP_USER);
    const deliveryMethod = isSmtpConfigured ? "smtp_email" : "manual_authorized_delivery";
    const deliveryStatus = isSmtpConfigured ? "sent" : "manual_ready";
    const deliveryNotes = "Invitación reenviada. La anterior ha sido invalidada de inmediato.";

    const result = await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("AppUserId", sql.NVarChar(100), appUserId)
      .input("DeliveryMethod", sql.NVarChar(40), deliveryMethod)
      .input("DeliveryStatus", sql.NVarChar(40), deliveryStatus)
      .input("DeliveryNotes", sql.NVarChar(500), deliveryNotes)
      .input("TokenHash", sql.Char(64), tokenHash)
      .input("TokenPrefix", sql.NVarChar(12), tokenPrefix)
      .input("ExpiresAt", sql.DateTimeOffset(3), expiresAt)
      .execute("dbo.usp_ResendUserInvitation");

    const invitationUrl = `/invitacion/${rawToken}`;

    res.json({
      ok: true,
      invitation: {
        id: result.recordset?.[0]?.InvitationId,
        tokenPrefix,
        expiresAt,
        deliveryMethod,
        invitationUrl,
        rawToken
      },
      message: isSmtpConfigured
        ? "Nueva invitación enviada por correo. El enlace anterior quedó invalidado."
        : "Nueva invitación generada. El enlace anterior fue invalidado; copie el nuevo enlace para entrega autorizada."
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   4. ACTIVAR / DESACTIVAR USUARIO Y REVOCAR SESIONES
   ========================================================= */
usersRouter.patch("/:id/status", async (req, res, next) => {
  try {
    const appUserId = req.params.id;
    const { active } = z.object({ active: z.boolean() }).parse(req.body);

    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("AppUserId", sql.NVarChar(100), appUserId)
      .input("IsActive", sql.Bit, active)
      .execute("dbo.usp_SetAppUserStatus");

    res.json({
      ok: true,
      message: active ? "Usuario activado correctamente." : "Usuario suspendido y todas sus sesiones fueron revocadas."
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   5. REVOCAR TODAS LAS SESIONES ACTIVAS DE UN USUARIO
   ========================================================= */
usersRouter.delete("/:id/sessions", async (req, res, next) => {
  try {
    const appUserId = req.params.id;
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    await pool.request()
      .input("ActorId", sql.NVarChar(100), req.user.id)
      .input("AppUserId", sql.NVarChar(100), appUserId)
      .execute("dbo.usp_RevokeAllUserSessions");

    res.json({ ok: true, message: "Todas las sesiones activas del usuario fueron revocadas." });
  } catch (error) {
    next(error);
  }
});

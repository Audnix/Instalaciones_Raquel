import { Router } from "express";
import crypto from "node:crypto";
import { z } from "zod";
import bcrypt from "bcryptjs";
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
  areas: z.array(z.string()).min(1, "Debe asignar al menos un área"),
  initialPassword: z.string().min(8, "La contraseña debe tener al menos 8 caracteres").optional().or(z.literal(""))
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
      const isActive = Boolean(row.IsActive);
      const hasPassword = Boolean(row.HasPasswordSet);
      const isLocked = Boolean(row.LockedUntil && new Date(row.LockedUntil) > new Date());
      const activeSessions = row.ActiveSessionsCount || 0;

      return {
        id: row.AppUserId,
        name: row.Name,
        email: row.Email,
        hierarchy: row.Hierarchy,
        active: isActive,
        isActive,
        hasPasswordSet: hasPassword,
        invitationPending: !hasPassword,
        invitationExpiresAt: invitation?.ExpiresAt || null,
        mustChangePassword: Boolean(row.MustChangePassword),
        failedLoginCount: row.FailedLoginCount || 0,
        lockedUntil: row.LockedUntil,
        isLocked,
        areas,
        invitation,
        activeSessions,
        activeSessionsCount: activeSessions
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
    const { name, email, hierarchy, areas, initialPassword } = createUserSchema.parse(req.body);

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
    const hasInitialPass = Boolean(initialPassword && initialPassword.trim().length >= 8);
    const deliveryStatus = hasInitialPass ? "accepted" : (isSmtpConfigured ? "sent" : "manual_ready");
    const deliveryNotes = hasInitialPass
      ? "Contraseña inicial asignada directamente por el administrador."
      : (isSmtpConfigured
        ? "Enviada automáticamente por SMTP."
        : "Entrega presencial/autorizada generada por el administrador.");

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

    // Si se especificó contraseña inicial, activarla de inmediato
    let passwordSet = false;
    if (hasInitialPass) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(initialPassword.trim(), salt);
      await pool.request()
        .input("TokenHash", sql.Char(64), tokenHash)
        .input("PasswordHash", sql.NVarChar(100), passwordHash)
        .execute("dbo.usp_AcceptUserInvitation");
      passwordSet = true;
    }

    res.status(201).json({
      ok: true,
      user: {
        id: created?.AppUserId,
        name,
        email,
        hierarchy,
        areas,
        active: true,
        hasPasswordSet: passwordSet
      },
      invitation: {
        id: created?.InvitationId,
        tokenPrefix,
        expiresAt,
        deliveryMethod,
        invitationUrl,
        rawToken,
        token: rawToken,
        link: invitationUrl,
        accepted: passwordSet
      },
      smtpConfigured: isSmtpConfigured,
      deliveryProcedure: isSmtpConfigured
        ? "Invitación enviada por correo SMTP."
        : (hasInitialPass
          ? "Contraseña directa activada. El usuario puede ingresar de inmediato con su correo y contraseña."
          : "Servicio SMTP inactivo. Copie el enlace seguro para entrega presencial/autorizada."),
      message: passwordSet
        ? `Usuario creado y activado con contraseña directa. Ya puede iniciar sesión en /login con su correo (${email}) y la contraseña configurada.`
        : (isSmtpConfigured
          ? "Usuario creado e invitación enviada por correo electrónico."
          : "Usuario registrado. El correo SMTP no está configurado; copie el enlace de invitación para entrega autorizada.")
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
        rawToken,
        token: rawToken,
        link: invitationUrl
      },
      smtpConfigured: isSmtpConfigured,
      deliveryProcedure: isSmtpConfigured
        ? "Invitación enviada por correo SMTP."
        : "Servicio SMTP inactivo. Copie el enlace seguro para entrega presencial/autorizada.",
      message: isSmtpConfigured
        ? "Nueva invitación enviada por correo. El enlace anterior quedó invalidado."
        : "Nueva invitación generada. El enlace anterior fue invalidado; copie el nuevo enlace para entrega autorizada."
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   4. ASIGNAR / RESTABLECER CONTRASEÑA DIRECTA (ADMIN)
   ========================================================= */
usersRouter.post("/:id/set-password", async (req, res, next) => {
  try {
    const appUserId = req.params.id;
    const { newPassword } = z.object({
      newPassword: z.string().min(8, "La contraseña debe tener al menos 8 caracteres")
    }).parse(req.body);

    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    await pool.request()
      .input("AppUserId", sql.NVarChar(100), appUserId)
      .input("SessionId", sql.UniqueIdentifier, crypto.randomUUID())
      .input("PasswordHash", sql.NVarChar(100), passwordHash)
      .execute("dbo.usp_ChangeAppUserPassword");

    res.json({
      ok: true,
      message: "Contraseña asignada exitosamente. El usuario ya puede iniciar sesión directamente."
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   5. ACTIVAR / DESACTIVAR USUARIO Y REVOCAR SESIONES
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
   6. REVOCAR TODAS LAS SESIONES ACTIVAS DE UN USUARIO
   ========================================================= */
async function revokeSessionsHandler(req, res, next) {
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
}

usersRouter.post("/:id/revoke-sessions", revokeSessionsHandler);
usersRouter.delete("/:id/sessions", revokeSessionsHandler);

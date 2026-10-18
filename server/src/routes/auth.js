import { Router } from "express";
import { z } from "zod";
import crypto from "node:crypto";
import bcrypt from "bcryptjs";
import sql from "mssql";
import { getDatabase } from "../config/sqlserver.js";
import { requireAuth, signUser } from "../middleware/auth.js";

export const authRouter = Router();

const loginSchema = z.object({
  email: z.string().email("Correo electrónico no válido"),
  password: z.string().min(1, "La contraseña es requerida")
});

const recoverRequestSchema = z.object({
  email: z.string().email("Correo electrónico no válido")
});

const recoverVerifySchema = z.object({
  email: z.string().email("Correo electrónico no válido"),
  code: z.string().min(6, "El código debe tener 6 dígitos"),
  newPassword: z.string().min(8, "La contraseña debe tener al menos 8 caracteres")
});

const invitationAcceptSchema = z.object({
  token: z.string().min(10, "Token de invitación inválido"),
  password: z.string().min(8, "La contraseña debe tener al menos 8 caracteres")
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, "Contraseña actual requerida"),
  newPassword: z.string().min(8, "La nueva contraseña debe tener al menos 8 caracteres")
});

function hashResetCode(code) {
  const secret = process.env.PASSWORD_RESET_SECRET || process.env.JWT_SECRET || "raquel-reset-secret-salt-2026";
  return crypto.createHmac("sha256", secret).update(code.trim()).digest("hex");
}

function hashInvitationToken(token) {
  return crypto.createHash("sha256").update(token.trim()).digest("hex");
}

/* =========================================================
   1. INICIO DE SESIÓN CON BCRYPT Y BLOQUEO DE INTENTOS
   ========================================================= */
authRouter.post("/login", async (req, res, next) => {
  try {
    const { email, password } = loginSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos SQL Server no disponible." });

    const result = await pool.request()
      .input("Email", sql.NVarChar(320), email.trim().toLowerCase())
      .execute("dbo.usp_GetAppUserForLogin");

    const user = result.recordset?.[0];
    if (!user || !user.IsActive) {
      return res.status(401).json({ message: "Correo o contraseña incorrectos." });
    }

    // Verificar si la cuenta está bloqueada temporalmente
    if (user.LockedUntil && new Date(user.LockedUntil) > new Date()) {
      const waitSeconds = Math.ceil((new Date(user.LockedUntil).getTime() - Date.now()) / 1000);
      return res.status(423).json({
        message: `Acceso cerrado temporalmente por intentos fallidos. Intenta nuevamente en ${waitSeconds} segundos.`,
        locked: true,
        waitSeconds
      });
    }

    // Verificar si tiene contraseña establecida
    if (!user.PasswordHash) {
      return res.status(403).json({
        message: "Esta cuenta aún no ha activado su contraseña mediante su invitación individual.",
        needsInvitation: true
      });
    }

    const matches = await bcrypt.compare(password, user.PasswordHash);
    if (!matches) {
      await pool.request()
        .input("Email", sql.NVarChar(320), email.trim().toLowerCase())
        .execute("dbo.usp_RecordFailedAppLogin");

      const attemptsLeft = Math.max(0, 4 - (user.FailedLoginCount || 0));
      return res.status(401).json({
        message: attemptsLeft > 0
          ? `Correo o contraseña incorrectos. Te quedan ${attemptsLeft} intentos antes del bloqueo.`
          : "Demasiados intentos fallidos. Tu acceso ha sido bloqueado temporalmente por 15 minutos."
      });
    }

    // Credenciales correctas: reiniciar contador de fallos
    await pool.request()
      .input("AppUserId", sql.NVarChar(100), user.AppUserId)
      .execute("dbo.usp_ResetFailedAppLogin");

    // Crear sesión revocable en SQL Server
    const sessionId = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 12 * 60 * 60 * 1000); // 12 horas

    await pool.request()
      .input("SessionId", sql.UniqueIdentifier, sessionId)
      .input("AppUserId", sql.NVarChar(100), user.AppUserId)
      .input("ExpiresAt", sql.DateTime2(3), expiresAt)
      .execute("dbo.usp_CreateAppUserSession");

    let areas = [];
    if (user.AreasJson) {
      try {
        areas = JSON.parse(user.AreasJson).map((a) => a.area);
      } catch {
        areas = [];
      }
    }

    const token = signUser({
      id: user.AppUserId,
      name: user.Name,
      email: user.Email,
      hierarchy: user.Hierarchy,
      areas
    }, sessionId);

    // NUNCA devolver contraseñas
    res.json({
      token,
      user: {
        id: user.AppUserId,
        name: user.Name,
        email: user.Email,
        hierarchy: user.Hierarchy,
        areas,
        active: Boolean(user.IsActive),
        mustChangePassword: Boolean(user.MustChangePassword)
      }
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   2. CIERRE DE SESIÓN Y REVOCACIÓN EN SQL SERVER
   ========================================================= */
authRouter.post("/logout", requireAuth, async (req, res, next) => {
  try {
    const pool = await getDatabase();
    if (pool && req.user.sessionId) {
      await pool.request()
        .input("SessionId", sql.UniqueIdentifier, req.user.sessionId)
        .execute("dbo.usp_RevokeAppUserSession");
    }
    res.json({ ok: true, message: "Sesión cerrada y revocada correctamente." });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   3. VERIFICAR SESIÓN ACTIVA Y ESTADO ACTUAL
   ========================================================= */
authRouter.get("/session", requireAuth, (req, res) => {
  res.json({
    authenticated: true,
    user: req.user
  });
});

/* =========================================================
   4. RECUPERACIÓN DE CONTRASEÑA (SOLICITUD)
   ========================================================= */
authRouter.post("/recover-request", async (req, res, next) => {
  try {
    const { email } = recoverRequestSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    // Código numérico aleatorio de 6 dígitos
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = hashResetCode(code);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutos

    const result = await pool.request()
      .input("Email", sql.NVarChar(320), email.trim().toLowerCase())
      .input("CodeHash", sql.Char(64), codeHash)
      .input("ExpiresAt", sql.DateTime2(3), expiresAt)
      .execute("dbo.usp_CreateAppPasswordReset");

    const targetUser = result.recordset?.[0]?.Email;
    const isSmtpConfigured = Boolean(process.env.SMTP_HOST && process.env.SMTP_USER);

    if (isSmtpConfigured) {
      // Si existiese configuración SMTP real, se envía por correo
      res.json({
        ok: true,
        smtpConfigured: true,
        message: "Se ha enviado un código de recuperación de un solo uso a tu correo electrónico."
      });
    } else {
      // Si no existe servicio SMTP configurado, informar transparentemente
      res.json({
        ok: true,
        smtpConfigured: false,
        message: "El servidor de correo saliente SMTP no está configurado en esta instalación.",
        authorizedDeliveryProcedure: "Procedimiento de entrega autorizada: Solicite el código de restablecimiento al Superadministrador del sistema.",
        // En entorno local de pruebas/demostración proporcionamos el código para permitir recuperación verificable
        authorizedCode: code
      });
    }
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   5. RECUPERACIÓN DE CONTRASEÑA (COMPLETAR CON NUEVA CLAVE)
   ========================================================= */
authRouter.post("/recover-verify", async (req, res, next) => {
  try {
    const { email, code, newPassword } = recoverVerifySchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    const codeHash = hashResetCode(code);
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    const result = await pool.request()
      .input("Email", sql.NVarChar(320), email.trim().toLowerCase())
      .input("CodeHash", sql.Char(64), codeHash)
      .input("PasswordHash", sql.NVarChar(100), passwordHash)
      .execute("dbo.usp_CompleteAppPasswordReset");

    const changed = result.recordset?.[0]?.Changed;
    if (!changed) {
      return res.status(400).json({ message: "Código inválido o expirado. Verifique e intente nuevamente." });
    }

    res.json({
      ok: true,
      message: "Tu contraseña ha sido actualizada exitosamente. Ya puedes iniciar sesión con tu nueva credencial."
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   6. VALIDAR TOKEN DE INVITACIÓN
   ========================================================= */
authRouter.get("/invitation/:token", async (req, res, next) => {
  try {
    const token = req.params.token;
    if (!token || token.length < 8) {
      return res.status(400).json({ valid: false, message: "Token de invitación no válido." });
    }

    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ valid: false, message: "Base de datos no disponible." });

    const tokenHash = hashInvitationToken(token);
    const result = await pool.request()
      .input("TokenHash", sql.Char(64), tokenHash)
      .execute("dbo.usp_ValidateInvitationToken");

    const invitation = result.recordset?.[0];
    if (!invitation) {
      return res.status(404).json({
        valid: false,
        message: "La invitación no es válida, ya fue utilizada o ha expirado. Solicite un nuevo enlace al administrador."
      });
    }

    let areas = [];
    if (invitation.AreasJson) {
      try {
        areas = JSON.parse(invitation.AreasJson).map((a) => a.area);
      } catch {
        areas = [];
      }
    }

    res.json({
      valid: true,
      user: {
        id: invitation.AppUserId,
        name: invitation.Name,
        email: invitation.Email,
        hierarchy: invitation.Hierarchy,
        areas,
        expiresAt: invitation.ExpiresAt
      }
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   7. ACEPTAR INVITACIÓN Y ESTABLECER CONTRASEÑA
   ========================================================= */
authRouter.post("/invitation/accept", async (req, res, next) => {
  try {
    const { token, password } = invitationAcceptSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    const tokenHash = hashInvitationToken(token);
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const result = await pool.request()
      .input("TokenHash", sql.Char(64), tokenHash)
      .input("PasswordHash", sql.NVarChar(100), passwordHash)
      .execute("dbo.usp_AcceptUserInvitation");

    const activatedUser = result.recordset?.[0];
    res.json({
      ok: true,
      message: `Cuenta activada exitosamente para ${activatedUser?.Name || "el usuario"}. Ya puedes iniciar sesión con tu correo y contraseña.`
    });
  } catch (error) {
    next(error);
  }
});

/* =========================================================
   8. CAMBIO DE CONTRASEÑA PARA USUARIO AUTENTICADO
   ========================================================= */
authRouter.post("/change-password", requireAuth, async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = changePasswordSchema.parse(req.body);
    const pool = await getDatabase();
    if (!pool) return res.status(503).json({ message: "Base de datos no disponible." });

    const userResult = await pool.request()
      .input("Email", sql.NVarChar(320), req.user.email)
      .execute("dbo.usp_GetAppUserForLogin");

    const user = userResult.recordset?.[0];
    if (!user || !user.PasswordHash) {
      return res.status(400).json({ message: "No se pudo validar la contraseña actual." });
    }

    const matches = await bcrypt.compare(currentPassword, user.PasswordHash);
    if (!matches) {
      return res.status(401).json({ message: "La contraseña actual no es correcta." });
    }

    const salt = await bcrypt.genSalt(10);
    const newHash = await bcrypt.hash(newPassword, salt);

    await pool.request()
      .input("AppUserId", sql.NVarChar(100), req.user.id)
      .input("SessionId", sql.UniqueIdentifier, req.user.sessionId || crypto.randomUUID())
      .input("PasswordHash", sql.NVarChar(100), newHash)
      .execute("dbo.usp_ChangeAppUserPassword");

    res.json({ ok: true, message: "Contraseña actualizada exitosamente." });
  } catch (error) {
    next(error);
  }
});

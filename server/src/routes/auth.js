import { Router } from "express";
import { z } from "zod";
import { supabase, supabaseAuth } from "../config/supabase.js";

export const authRouter = Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6)
});

const sessionSchema = z.object({
  token: z.string().min(1)
});

async function buildSession(accessToken, user) {
  let { data: profile, error: profileError } = await supabase
    .from("user_profiles")
    .select("id, full_name, active")
    .eq("id", user.id)
    .maybeSingle();

  if (profileError) {
    throw profileError;
  }

  if (!profile) {
    const fullName =
      user.user_metadata?.full_name ??
      user.user_metadata?.name ??
      user.email?.split("@")[0] ??
      "Usuario";

    const { data: createdProfile, error: createError } = await supabase
      .from("user_profiles")
      .insert({ id: user.id, full_name: fullName, active: true })
      .select("id, full_name, active")
      .single();

    if (createError) {
      return null;
    }

    profile = createdProfile;
  }

  if (!profile?.active) {
    return null;
  }

  return {
    token: accessToken,
    user: {
      id: user.id,
      name: profile.full_name,
      email: user.email,
      role: "Usuario",
      permissions: ["read", "write"]
    }
  };
}

authRouter.post("/login", async (req, res, next) => {
  try {
    const credentials = loginSchema.parse(req.body);

    if (!supabaseAuth || !supabase) {
      return res.status(500).json({ message: "Supabase no esta configurado. Revisa SUPABASE_URL, SUPABASE_ANON_KEY y SUPABASE_SERVICE_ROLE_KEY." });
    }

    const { data, error } = await supabaseAuth.auth.signInWithPassword({
      email: credentials.email,
      password: credentials.password
    });

    if (error || !data.session || !data.user) {
      return res.status(401).json({ message: "Correo o contrasena incorrectos." });
    }

    const session = await buildSession(data.session.access_token, data.user);

    if (!session) {
      return res.status(403).json({ message: "Usuario sin perfil activo en el ERP." });
    }

    res.json(session);
  } catch (error) {
    next(error);
  }
});

authRouter.post("/session", async (req, res, next) => {
  try {
    const payload = sessionSchema.parse(req.body);

    if (!supabaseAuth || !supabase) {
      return res.status(500).json({ message: "Supabase no esta configurado. Revisa SUPABASE_URL, SUPABASE_ANON_KEY y SUPABASE_SERVICE_ROLE_KEY." });
    }

    const { data, error } = await supabaseAuth.auth.getUser(payload.token);

    if (error || !data.user) {
      return res.status(401).json({ message: "Sesion de Google invalida o expirada." });
    }

    const session = await buildSession(payload.token, data.user);

    if (!session) {
      return res.status(403).json({ message: "Usuario sin perfil activo en el ERP." });
    }

    res.json(session);
  } catch (error) {
    next(error);
  }
});

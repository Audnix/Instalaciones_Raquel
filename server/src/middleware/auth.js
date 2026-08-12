import { supabase } from "../config/supabase.js";

export async function requireAuth(req, res, next) {
  const token = req.headers.authorization?.replace("Bearer ", "");
  if (!token) return res.status(401).json({ message: "Token requerido" });

  try {
    if (!supabase) return res.status(500).json({ message: "Supabase no esta configurado." });

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) return res.status(401).json({ message: "Token invalido" });

    const { data: profile } = await supabase
      .from("user_profiles")
      .select("id, full_name, active")
      .eq("id", data.user.id)
      .single();

    if (!profile?.active) return res.status(403).json({ message: "Usuario sin perfil activo en el ERP." });

    req.user = {
      sub: data.user.id,
      email: data.user.email,
      role: "Usuario",
      permissions: ["read", "write"]
    };
    return next();
  } catch {
    return res.status(401).json({ message: "Token invalido" });
  }
}

export function permit(...permissions) {
  return (req, res, next) => {
    const userPermissions = req.user?.permissions ?? [];
    const allowed = permissions.every((permission) => userPermissions.includes(permission));
    if (!allowed) return res.status(403).json({ message: "Permiso insuficiente" });
    return next();
  };
}

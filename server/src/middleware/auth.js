import jwt from "jsonwebtoken";

const secret = () => process.env.JWT_SECRET ?? "raquel-erp-dev-secret";

export function signUser(user) {
  return jwt.sign(
    {
      sub: user.id,
      email: user.email,
      name: user.full_name ?? user.name,
      hierarchy: user.hierarchy
    },
    secret(),
    { expiresIn: "12h" }
  );
}

export function requireAuth(req, res, next) {
  const token = req.headers.authorization?.replace("Bearer ", "");
  if (!token) return res.status(401).json({ message: "Token requerido" });
  try {
    req.user = jwt.verify(token, secret());
    return next();
  } catch {
    return res.status(401).json({ message: "Token invalido" });
  }
}

export function permit(...permissions) {
  return (req, res, next) => {
    const userPermissions = req.user?.permissions ?? ["read", "write"];
    const allowed = permissions.every((permission) => userPermissions.includes(permission));
    if (!allowed) return res.status(403).json({ message: "Permiso insuficiente" });
    return next();
  };
}

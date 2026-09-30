import { Router } from "express";
import { z } from "zod";
import { findUserByCredentials } from "../db/snapshot.js";
import { signUser } from "../middleware/auth.js";

export const authRouter = Router();

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6)
});

authRouter.post("/login", async (req, res, next) => {
  try {
    const credentials = loginSchema.parse(req.body);
    const user = await findUserByCredentials(credentials.email, credentials.password);
    if (!user) {
      return res.status(401).json({ message: "Correo o contraseña incorrectos." });
    }
    const token = signUser(user);
    res.json({
      token,
      user: {
        id: user.id,
        name: user.full_name,
        email: user.email,
        password: credentials.password,
        hierarchy: user.hierarchy,
        areas: user.areas ?? [],
        active: user.active
      }
    });
  } catch (error) {
    next(error);
  }
});

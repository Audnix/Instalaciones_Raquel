import nodemailer from "nodemailer";

export async function sendPasswordResetEmail({ email, code }) {
  const host = process.env.SMTP_HOST?.trim();
  const user = process.env.SMTP_USER?.trim();
  const password = process.env.SMTP_PASSWORD?.trim();
  const port = Number(process.env.SMTP_PORT || 587);

  if (!host || !user || !password || !Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("Configura SMTP_HOST, SMTP_PORT, SMTP_USER y SMTP_PASSWORD para enviar correos.");
  }

  const transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass: password }
  });
  await transporter.sendMail({
    from: process.env.SMTP_FROM?.trim() || user,
    to: email,
    subject: "Código para recuperar tu contraseña",
    text: `Tu código de recuperación es ${code}. Vence en 15 minutos. Si no solicitaste este cambio, ignora este correo.`,
    html: `<p>Tu código de recuperación es:</p><p style="font-size:24px;font-weight:bold;letter-spacing:4px">${code}</p><p>Vence en 15 minutos. Si no solicitaste este cambio, ignora este correo.</p>`
  });
}

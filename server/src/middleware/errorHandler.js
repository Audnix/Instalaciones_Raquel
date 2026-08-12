export function errorHandler(err, _req, res, _next) {
  console.error(err);
  if (err.name === "ZodError") {
    return res.status(400).json({
      message: "Datos invalidos",
      issues: err.issues
    });
  }

  res.status(err.status ?? 500).json({
    message: err.message ?? "Error interno",
    code: err.code ?? "INTERNAL_ERROR"
  });
}

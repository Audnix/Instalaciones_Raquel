export function isMissingObjectError(error) {
  return error?.number === 208 || /Invalid object name|Could not find stored procedure/i.test(error?.message ?? "");
}

export function sendSqlFailure(res, error, fallbackMessage) {
  if (isMissingObjectError(error)) {
    return res.status(503).json({
      code: "SQL_STRUCTURE_PENDING",
      message:
        "La estructura SQL de Talento humano o Nómina está incompleta. Aplique la migración 25_operaciones_hr_nomina.sql sin reconstruir la base ni cargar semillas."
    });
  }
  if (error?.number) {
    return res.status(400).json({
      code: `SQL_${error.number}`,
      message: error.message || fallbackMessage
    });
  }
  return null;
}

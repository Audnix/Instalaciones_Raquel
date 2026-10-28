export function getPort(value) {
  const configuredPort = value?.trim();
  if (!configuredPort) return 4000;

  const port = Number(configuredPort);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error("PORT debe ser un número entero entre 1 y 65535.");
  }

  return port;
}

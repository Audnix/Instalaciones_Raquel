import sql from "mssql";

const server = process.env.DB_SERVER;
const databaseName = process.env.DB_NAME;
const username = process.env.DB_USER?.trim();
const password = process.env.DB_PASSWORD?.trim();
const useIntegratedSecurity = process.env.DB_USE_WINDOWS_AUTH === "true" || (!username && !password);

const hasConfiguration = Boolean(server && databaseName) && (useIntegratedSecurity || Boolean(username && password));

export const database = hasConfiguration
  ? new sql.ConnectionPool({
      server,
      database: databaseName,
      ...(useIntegratedSecurity ? {} : { user: username, password }),
      ...(process.env.DB_PORT ? { port: Number(process.env.DB_PORT) } : {}),
      options: {
        ...(process.env.DB_INSTANCE_NAME ? { instanceName: process.env.DB_INSTANCE_NAME } : {}),
        encrypt: process.env.DB_ENCRYPT === "true",
        trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE !== "false",
        ...(useIntegratedSecurity ? { integratedSecurity: true } : {})
      },
      pool: { min: 0, max: 10, idleTimeoutMillis: 30000 },
      connectionTimeout: 5000,
      requestTimeout: 15000
    })
  : null;

let connectionPromise;

export async function getDatabase() {
  if (!database) return null;
  if (database.connected) return database;
  connectionPromise ??= database.connect().catch((error) => {
    connectionPromise = undefined;
    throw error;
  });
  return connectionPromise;
}
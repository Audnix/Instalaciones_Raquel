import { spawnSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import dotenv from "dotenv";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = resolve(__dirname, "../..");
const envPath = resolve(rootDir, ".env");
if (existsSync(envPath)) dotenv.config({ path: envPath });

const server = process.env.DB_SERVER || "127.0.0.1";
const port = process.env.DB_PORT || "63454";
const dbName = process.env.DB_NAME || "Instalaciones Raquel";
const dbPassword = process.env.DB_PASSWORD || "";
const serverTarget = `${server},${port}`;

const scriptsDir = resolve(rootDir, "SQLServer_Completo");

const migrationOrder = [
  "00_crear_base.sql",
  "01_catalogos.sql",
  "02_gobierno_y_maestros.sql",
  "11_actualizar_proveedores.sql",
  "03_inventario_y_comercial.sql",
  "04_produccion_proyectos.sql",
  "05_finanzas_nomina.sql",
  "06_vistas.sql",
  "07_procedimiento_sincronizacion.sql",
  "08_semilla.sql",
  "09_login_aplicacion.sql",
  "12_sincronizacion_proveedores.sql",
  "13_autenticacion_y_sesiones.sql",
  "14_recuperacion_contrasena.sql",
  "15_expedientes_proyectos.sql",
  "16_talento_humano_base.sql",
  "17_modulo_nomina_completo.sql",
  "18_invitaciones_y_gobierno.sql",
  "10_verificar.sql"
];

const isRebuild = process.argv.includes("--rebuild");

console.log(`=== Instalador SQL Server: Instalaciones Raquel ===`);
console.log(`Destino: ${serverTarget} | Base: [${dbName}]`);

if (isRebuild) {
  console.log(`[!] RECONSTRUCCIÓN SOLICITADA: Ejecutando 00_reconstruir_desde_cero.sql`);
  runSqlCmd(resolve(scriptsDir, "00_reconstruir_desde_cero.sql"));
}

for (const scriptFile of migrationOrder) {
  const fullPath = resolve(scriptsDir, scriptFile);
  if (!existsSync(fullPath)) {
    console.warn(`[OMITIDO] No encontrado: ${scriptFile}`);
    continue;
  }
  console.log(`--> Aplicando: ${scriptFile}...`);
  const vars = scriptFile === "09_login_aplicacion.sql" ? [`AppPassword=${dbPassword}`] : [];
  runSqlCmd(fullPath, vars);
}

console.log(`=== Base de datos instalada y verificada exitosamente. ===`);

function runSqlCmd(filePath, variables = []) {
  const args = [
    "-S", serverTarget,
    "-E",
    "-C",
    "-i", filePath
  ];
  for (const v of variables) {
    args.push("-v", v);
  }
  const proc = spawnSync("sqlcmd", args, { stdio: "inherit", encoding: "utf8" });
  if (proc.status !== 0) {
    console.error(`Error al ejecutar ${filePath} (código ${proc.status})`);
    process.exit(proc.status || 1);
  }
}

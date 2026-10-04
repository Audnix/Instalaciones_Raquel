import { spawn } from "node:child_process";
import { createServer } from "node:net";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as delay } from "node:timers/promises";

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const serverRoot = resolve(projectRoot, "server");
const viteEntry = resolve(projectRoot, "node_modules/vite/bin/vite.js");
const apiPort = Number(process.env.PORT) || 4000;
const firstWebPort = Number(process.env.VITE_PORT) || 5173;
const apiUrl = `http://127.0.0.1:${apiPort}`;
const managedProcesses = [];
let shuttingDown = false;

async function getJson(url) {
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(1500) });
    if (!response.ok) return null;
    return await response.json();
  } catch {
    return null;
  }
}

async function isPortAvailable(port) {
  return new Promise((resolveResult) => {
    const probe = createServer();
    probe.once("error", () => resolveResult(false));
    probe.listen(port, "127.0.0.1", () => probe.close(() => resolveResult(true)));
  });
}

async function existingVite(port) {
  try {
    const response = await fetch(`http://127.0.0.1:${port}/`, { signal: AbortSignal.timeout(1500) });
    if (!response.ok) return false;
    return (await response.text()).includes("/@vite/client");
  } catch {
    return false;
  }
}

function startNode(args, cwd) {
  const child = spawn(process.execPath, args, { cwd, stdio: "inherit", env: process.env });
  managedProcesses.push(child);
  child.once("error", (error) => console.error(`No se pudo iniciar ${args.join(" ")}: ${error.message}`));
  return child;
}

async function waitForApi(child) {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    if (child.exitCode !== null) throw new Error("El backend se cerró antes de iniciar.");
    if ((await getJson(`${apiUrl}/health`))?.status === "ok") return;
    await delay(500);
  }
  throw new Error(`El backend no respondió en ${apiUrl}.`);
}

function openBrowser(url) {
  if (process.platform === "win32") {
    const browser = spawn("cmd.exe", ["/d", "/s", "/c", "start", "", url], {
      detached: true,
      stdio: "ignore",
      windowsHide: true
    });
    browser.unref();
  }
}

function stopManagedProcesses() {
  for (const child of managedProcesses) {
    if (child.exitCode === null) child.kill("SIGINT");
  }
}

async function keepRunning() {
  if (managedProcesses.length === 0) return;

  await new Promise((resolvePromise) => {
    let remaining = managedProcesses.length;
    const finish = () => {
      remaining -= 1;
      if (!shuttingDown) {
        shuttingDown = true;
        stopManagedProcesses();
      }
      if (remaining <= 0) resolvePromise();
    };

    for (const child of managedProcesses) child.once("exit", finish);
    process.once("SIGINT", () => {
      shuttingDown = true;
      stopManagedProcesses();
      if (managedProcesses.every((child) => child.exitCode !== null)) resolvePromise();
    });
    process.once("SIGTERM", () => {
      shuttingDown = true;
      stopManagedProcesses();
      if (managedProcesses.every((child) => child.exitCode !== null)) resolvePromise();
    });
  });
}

async function main() {
  let apiHealth = await getJson(`${apiUrl}/health`);
  let apiChild = null;

  if (apiHealth?.status === "ok") {
    console.log(`API existente reutilizada en ${apiUrl}.`);
  } else if (await isPortAvailable(apiPort)) {
    console.log("Iniciando API...");
    apiChild = startNode(["--watch", "src/index.js"], serverRoot);
    await waitForApi(apiChild);
  } else {
    throw new Error(`El puerto ${apiPort} está ocupado por otro proceso; no iniciaré una API duplicada.`);
  }

  const databaseHealth = await getJson(`${apiUrl}/health/database`);
  if (databaseHealth?.status === "ok") {
    console.log(`SQL Server conectado: ${databaseHealth.database}.`);
  } else {
    console.warn("La API está activa, pero SQL Server aún no responde correctamente.");
  }

  let webPort = null;
  for (let port = firstWebPort; port < firstWebPort + 20; port += 1) {
    if (await existingVite(port)) {
      webPort = port;
      console.log(`Interfaz existente reutilizada en http://localhost:${webPort}/.`);
      break;
    }
    if (webPort === null && await isPortAvailable(port)) webPort = port;
  }

  if (webPort === null) throw new Error("No encontré un puerto libre para iniciar la interfaz.");

  if (!(await existingVite(webPort))) {
    console.log(`Iniciando interfaz en http://localhost:${webPort}/...`);
    const viteChild = startNode([viteEntry, "--host", "--open", "--port", String(webPort), "--strictPort"], projectRoot);
    await delay(700);
    if (viteChild.exitCode !== null) throw new Error("Vite se cerró antes de iniciar.");
  } else {
    openBrowser(`http://localhost:${webPort}/`);
  }

  console.log(`ERP local: http://localhost:${webPort}/`);
  if (managedProcesses.length === 0) {
    console.log("La API y la interfaz ya estaban activas; no inicié copias duplicadas.");
    return;
  }
  console.log("Deja esta terminal abierta. Presiona Ctrl+C para detener los servicios iniciados aquí.");
  await keepRunning();
}

main().catch((error) => {
  console.error(error.message);
  stopManagedProcesses();
  process.exitCode = 1;
});
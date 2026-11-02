export interface ErpTask {
  id: string;
  module: string;
  title: string;
  detail: string;
  priority: "alta" | "media" | "baja";
  actionUrl: string;
  actionLabel: string;
}

export function parseTaskResponse(value: unknown): ErpTask[] {
  if (!value || typeof value !== "object" || !("tasks" in value) || !Array.isArray(value.tasks)) {
    throw new Error("Respuesta de pendientes no válida.");
  }
  const ids = new Set<string>();
  for (const task of value.tasks) {
    if (!task || typeof task !== "object" ||
      !["id", "module", "title", "detail", "actionUrl", "actionLabel"].every(key => typeof task[key] === "string") ||
      !task.id.trim() || ids.has(task.id) ||
      !["alta", "media", "baja"].includes(task.priority) ||
      !/^\/(?!\/)/.test(task.actionUrl) || /[\\\u0000-\u0020]/.test(task.actionUrl)) {
      throw new Error("Respuesta de pendientes no válida.");
    }
    ids.add(task.id);
  }
  return value.tasks;
}

import { FormEvent, useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { Button } from "../components/Button";

export function ChangePassword() {
  const { user, changePassword, logout } = useAuth();
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (password.length < 12) {
      setError("La contraseña debe tener al menos 12 caracteres.");
      return;
    }
    if (password !== confirmation) {
      setError("Las contraseñas no coinciden.");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await changePassword(undefined, password);
    } catch (failure) {
      setError(failure instanceof Error ? failure.message : "No se pudo actualizar la contraseña.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <main className="grid min-h-screen place-items-center p-4">
      <form onSubmit={submit} className="w-full max-w-md space-y-4 rounded-2xl bg-white p-6 shadow-glow dark:bg-slate-950">
        <div>
          <h1 className="text-2xl font-extrabold">Actualiza tu contraseña</h1>
          <p className="mt-2 text-sm text-slate-500">
            {user?.name}, la contraseña temporal debe cambiarse antes de continuar.
          </p>
        </div>
        <label className="block text-sm font-semibold">
          Nueva contraseña
          <input
            className="mt-2 h-12 w-full rounded-lg border border-slate-200 bg-transparent px-3 dark:border-white/10"
            type="password"
            autoComplete="new-password"
            minLength={12}
            required
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />
        </label>
        <label className="block text-sm font-semibold">
          Repite la nueva contraseña
          <input
            className="mt-2 h-12 w-full rounded-lg border border-slate-200 bg-transparent px-3 dark:border-white/10"
            type="password"
            autoComplete="new-password"
            minLength={12}
            required
            value={confirmation}
            onChange={(event) => setConfirmation(event.target.value)}
          />
        </label>
        {error && <p role="alert" className="rounded-lg bg-rose-50 px-3 py-2 text-sm text-rose-700">{error}</p>}
        <div className="flex gap-3">
          <Button className="flex-1" disabled={saving}>{saving ? "Guardando..." : "Guardar contraseña"}</Button>
          <Button type="button" variant="secondary" onClick={logout}>Cerrar sesión</Button>
        </div>
      </form>
    </main>
  );
}

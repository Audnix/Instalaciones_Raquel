export function createSnapshotQueue<T>(options: {
  save: (value: T) => Promise<void>;
  saved: (value: T) => void;
  failed: (error: unknown) => void;
  pending: () => void;
}) {
  let active = false, stopped = false;
  let next: { value: T } | null = null;
  const drain = async () => {
    if (active || stopped) return;
    active = true;
    try {
      while (next && !stopped) {
        const current = next.value;
        next = null;
        options.pending();
        await options.save(current);
        if (!stopped) options.saved(current);
      }
    } catch (error) {
      stopped = true;
      options.failed(error);
    } finally { active = false; }
  };
  return {
    enqueue(value: T) { if (!stopped) { next = { value }; options.pending(); void drain(); } },
    stop() { stopped = true; next = null; }
  };
}

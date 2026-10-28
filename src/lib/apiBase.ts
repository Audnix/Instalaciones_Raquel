export function resolveApiBase(configured: string | undefined, development: boolean): string {
  const base = configured?.trim().replace(/\/+$/, '') || '';
  // Vite already proxies /api to the local backend. Keep browser requests on
  // that origin, including when localhost resolves to IPv6 or Vite changes port.
  if (development && base) {
    try {
      const url = new URL(base);
      if (['localhost', '127.0.0.1', '[::1]'].includes(url.hostname) &&
          url.port === '4000' &&
          ['http:', 'https:'].includes(url.protocol) &&
          (url.pathname === '/' || url.pathname === '') && !url.search && !url.hash) return '';
    } catch { /* Preserve explicit configuration so failures remain visible. */ }
  }
  return base;
}

export function getApiBaseUrl(): string {
  return resolveApiBase(import.meta.env.VITE_API_URL, import.meta.env.DEV);
}

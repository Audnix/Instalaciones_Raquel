const ORIGIN_KEY = "raquel_public_origin";

function isLoopback(hostname: string) {
  return hostname === "localhost" || hostname === "127.0.0.1" || hostname === "::1" || hostname === "[::1]";
}

/** Detecta IP LAN por WebRTC (para que el QR no use localhost). */
export function detectLanIp(): Promise<string | null> {
  return new Promise((resolve) => {
    const RTCPeerConnection =
      window.RTCPeerConnection ||
      (window as unknown as { webkitRTCPeerConnection?: typeof window.RTCPeerConnection }).webkitRTCPeerConnection;
    if (!RTCPeerConnection) {
      resolve(null);
      return;
    }
    const pc = new RTCPeerConnection({ iceServers: [] });
    let done = false;
    const finish = (ip: string | null) => {
      if (done) return;
      done = true;
      try {
        pc.close();
      } catch {
        /* ignore */
      }
      resolve(ip);
    };
    const timer = window.setTimeout(() => finish(null), 1500);
    pc.createDataChannel("");
    pc.createOffer()
      .then((offer) => pc.setLocalDescription(offer))
      .catch(() => finish(null));
    pc.onicecandidate = (event) => {
      if (!event.candidate) return;
      const match = /([0-9]{1,3}(\.[0-9]{1,3}){3})/.exec(event.candidate.candidate);
      if (match?.[1] && !match[1].startsWith("127.")) {
        window.clearTimeout(timer);
        finish(match[1]);
      }
    };
  });
}

export function getPublicOrigin(): string {
  if (typeof window === "undefined") return "";
  const saved = localStorage.getItem(ORIGIN_KEY);
  if (saved && !saved.includes("localhost") && !saved.includes("127.0.0.1")) return saved.replace(/\/$/, "");

  const { protocol, hostname, port } = window.location;
  if (!isLoopback(hostname)) {
    return window.location.origin.replace(/\/$/, "");
  }

  const p = port || "5173";
  // Fallback de red local detectada en este entorno; se actualiza con ensurePublicOrigin()
  return `${protocol}//192.168.1.8:${p}`.replace(/\/$/, "");
}

export function setPublicOrigin(origin: string) {
  localStorage.setItem(ORIGIN_KEY, origin.replace(/\/$/, ""));
}

export async function ensurePublicOrigin(): Promise<string> {
  if (typeof window === "undefined") return "";
  const { protocol, hostname, port } = window.location;
  if (!isLoopback(hostname)) {
    const origin = window.location.origin.replace(/\/$/, "");
    setPublicOrigin(origin);
    return origin;
  }
  const ip = await detectLanIp();
  const p = port || "5173";
  const origin = ip ? `${protocol}//${ip}:${p}` : getPublicOrigin();
  setPublicOrigin(origin);
  return origin;
}

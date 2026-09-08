import { getPublicOrigin } from "./publicOrigin";

export type PortableLine = {
  n: string;
  q: number;
  p: number;
};

export type PortableDoc = {
  k: "FAC" | "PRF";
  n: string;
  c: string;
  d: string;
  i: PortableLine[];
  s: number;
  o: number;
  x: number;
  t: number;
  p?: string;
  v: string;
  brand?: string;
};

function hashCode(value: string) {
  let hash = 0;
  for (let i = 0; i < value.length; i += 1) {
    hash = (hash << 5) - hash + value.charCodeAt(i);
    hash |= 0;
  }
  return hash;
}

export function makeVerifyCode(number: string, total: number, date: string) {
  return Math.abs(hashCode(`${number}|${total}|${date}`)).toString(36).toUpperCase().slice(0, 6);
}

export function encodePortableDoc(doc: PortableDoc) {
  const json = JSON.stringify(doc);
  return btoa(unescape(encodeURIComponent(json)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

export function decodePortableDoc(raw: string): PortableDoc | null {
  try {
    let b64 = raw.replace(/-/g, "+").replace(/_/g, "/");
    while (b64.length % 4) b64 += "=";
    const json = decodeURIComponent(escape(atob(b64)));
    return JSON.parse(json) as PortableDoc;
  } catch {
    return null;
  }
}

export function buildValidateUrl(doc: PortableDoc) {
  const origin = getPublicOrigin();
  return `${origin}/validar#${encodePortableDoc(doc)}`;
}

export function buildPortableDoc(input: {
  kind: "FAC" | "PRF";
  number: string;
  client: string;
  date: string;
  items: Array<{ name: string; quantity: number; unitPrice: number }>;
  subtotal: number;
  discount: number;
  tax: number;
  total: number;
  promo?: string;
}): PortableDoc {
  return {
    k: input.kind,
    n: input.number,
    c: input.client,
    d: input.date.slice(0, 10),
    i: input.items.map((item) => ({ n: item.name.slice(0, 40), q: item.quantity, p: item.unitPrice })),
    s: Number(input.subtotal.toFixed(2)),
    o: Number(input.discount.toFixed(2)),
    x: Number(input.tax.toFixed(2)),
    t: Number(input.total.toFixed(2)),
    p: input.promo,
    v: makeVerifyCode(input.number, input.total, input.date),
    brand: "Instalaciones Raquel"
  };
}

/** @deprecated kept for old QRs — Prefer buildValidateUrl */
export function buildDocToken(input: {
  kind: "FAC" | "PRF";
  number: string;
  client: string;
  total: number;
  date: string;
  items?: Array<{ name: string; quantity: number; unitPrice: number }>;
  subtotal?: number;
  discount?: number;
  tax?: number;
  promo?: string;
}) {
  const doc = buildPortableDoc({
    kind: input.kind,
    number: input.number,
    client: input.client,
    date: input.date,
    items: input.items ?? [{ name: "Documento", quantity: 1, unitPrice: input.total }],
    subtotal: input.subtotal ?? input.total,
    discount: input.discount ?? 0,
    tax: input.tax ?? 0,
    total: input.total,
    promo: input.promo
  });
  return buildValidateUrl(doc);
}

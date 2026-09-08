import type { PortableDoc } from "./invoiceDoc";

function money(value: number) {
  return value.toLocaleString("es-NI", { style: "currency", currency: "NIO", maximumFractionDigits: 2 }).replace("NIO", "C$");
}

function wrapText(ctx: CanvasRenderingContext2D, text: string, maxWidth: number) {
  const words = text.split(" ");
  const lines: string[] = [];
  let line = "";
  for (const word of words) {
    const test = line ? `${line} ${word}` : word;
    if (ctx.measureText(test).width > maxWidth && line) {
      lines.push(line);
      line = word;
    } else {
      line = test;
    }
  }
  if (line) lines.push(line);
  return lines;
}

/** Dibuja un comprobante listo para guardar en el teléfono (PNG). */
export function renderInvoiceCanvas(doc: PortableDoc): HTMLCanvasElement {
  const lines = doc.i?.length ? doc.i : [{ n: "Detalle", q: 1, p: doc.t }];
  const width = 720;
  const padding = 36;
  const rowH = 34;
  const extraRows = Math.max(0, lines.length - 1) * 52 + (doc.p ? 40 : 0);
  const height = 920 + extraRows;
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) return canvas;

  // Fondo
  ctx.fillStyle = "#062029";
  ctx.fillRect(0, 0, width, height);

  // Tarjeta
  const cardX = 28;
  const cardY = 28;
  const cardW = width - 56;
  const cardH = height - 56;
  roundRect(ctx, cardX, cardY, cardW, cardH, 28, "#ffffff");

  // Header
  const grad = ctx.createLinearGradient(cardX, cardY, cardX + cardW, cardY + 180);
  grad.addColorStop(0, "#0a92c8");
  grad.addColorStop(0.55, "#0f6e86");
  grad.addColorStop(1, "#0b3b4a");
  roundRect(ctx, cardX, cardY, cardW, 188, 28, grad);
  ctx.fillStyle = grad;
  ctx.fillRect(cardX, cardY + 140, cardW, 48);

  ctx.fillStyle = "#e0f7ff";
  ctx.font = "bold 14px system-ui, sans-serif";
  ctx.fillText("INSTALACIONES RAQUEL", cardX + 28, cardY + 42);
  ctx.fillStyle = "#ffffff";
  ctx.font = "800 28px system-ui, sans-serif";
  ctx.fillText("Aluminio · Vidrio · Hogar", cardX + 28, cardY + 78);

  const kind = doc.k === "FAC" ? "Factura" : "Proforma";
  ctx.font = "600 16px system-ui, sans-serif";
  ctx.fillStyle = "#b8ecff";
  ctx.fillText(`${kind} válida`, cardX + 28, cardY + 118);
  ctx.fillStyle = "#ffffff";
  ctx.font = "800 32px system-ui, sans-serif";
  ctx.fillText(doc.n, cardX + 28, cardY + 156);

  ctx.textAlign = "right";
  ctx.font = "600 12px system-ui, sans-serif";
  ctx.fillStyle = "#b8ecff";
  ctx.fillText("TOTAL", cardX + cardW - 28, cardY + 118);
  ctx.font = "800 28px system-ui, sans-serif";
  ctx.fillStyle = "#ffffff";
  ctx.fillText(money(doc.t), cardX + cardW - 28, cardY + 156);
  ctx.textAlign = "left";

  let y = cardY + 220;
  ctx.fillStyle = "#ecfdf5";
  roundRect(ctx, cardX + 24, y - 22, cardW - 48, 44, 14, "#ecfdf5");
  ctx.fillStyle = "#047857";
  ctx.font = "bold 15px system-ui, sans-serif";
  ctx.fillText(`✓ Código verificado · ${doc.v}`, cardX + 40, y + 6);
  y += 56;

  // Cliente / fecha
  drawInfoBox(ctx, cardX + 24, y, (cardW - 60) / 2, "CLIENTE", doc.c);
  drawInfoBox(ctx, cardX + 36 + (cardW - 60) / 2, y, (cardW - 60) / 2, "FECHA", doc.d);
  y += 92;

  if (doc.p) {
    roundRect(ctx, cardX + 24, y - 18, cardW - 48, 40, 14, "#fffbeb");
    ctx.fillStyle = "#92400e";
    ctx.font = "bold 14px system-ui, sans-serif";
    ctx.fillText(`★ Promo: ${doc.p}`, cardX + 40, y + 8);
    y += 48;
  }

  ctx.fillStyle = "#94a3b8";
  ctx.font = "bold 12px system-ui, sans-serif";
  ctx.fillText("DETALLE", cardX + 28, y);
  y += 18;

  for (const line of lines) {
    roundRect(ctx, cardX + 24, y, cardW - 48, 58, 16, "#f8fafc");
    ctx.fillStyle = "#0f172a";
    ctx.font = "800 16px system-ui, sans-serif";
    const nameLines = wrapText(ctx, line.n, cardW - 180);
    ctx.fillText(nameLines[0] ?? line.n, cardX + 40, y + 24);
    ctx.fillStyle = "#64748b";
    ctx.font = "600 13px system-ui, sans-serif";
    ctx.fillText(`${line.q} × ${money(line.p)}`, cardX + 40, y + 44);
    ctx.textAlign = "right";
    ctx.fillStyle = "#0f172a";
    ctx.font = "800 16px system-ui, sans-serif";
    ctx.fillText(money(line.q * line.p), cardX + cardW - 40, y + 34);
    ctx.textAlign = "left";
    y += 70;
  }

  y += 8;
  roundRect(ctx, cardX + 24, y, cardW - 48, doc.o > 0 ? 128 : 108, 18, "#f1f5f9");
  y += 28;
  drawTotalRow(ctx, cardX + 40, cardX + cardW - 40, y, "Subtotal", money(doc.s), false);
  y += rowH;
  if (doc.o > 0) {
    drawTotalRow(ctx, cardX + 40, cardX + cardW - 40, y, "Descuento", `- ${money(doc.o)}`, false, "#047857");
    y += rowH;
  }
  drawTotalRow(ctx, cardX + 40, cardX + cardW - 40, y, "IVA 15%", money(doc.x), false);
  y += rowH;
  drawTotalRow(ctx, cardX + 40, cardX + cardW - 40, y, "Total a pagar", money(doc.t), true);

  y = height - 78;
  ctx.fillStyle = "#94a3b8";
  ctx.font = "600 13px system-ui, sans-serif";
  ctx.textAlign = "center";
  ctx.fillText("Comprobante digital · Instalaciones Raquel", width / 2, y);
  ctx.font = "600 11px system-ui, sans-serif";
  ctx.fillText("Guardado desde el ERP · válido con código QR", width / 2, y + 22);
  ctx.textAlign = "left";

  // avoid unused
  void padding;
  return canvas;
}

function roundRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
  fill: string | CanvasGradient
) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
  ctx.fillStyle = fill;
  ctx.fill();
}

function drawInfoBox(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, label: string, value: string) {
  roundRect(ctx, x, y, w, 72, 16, "#f8fafc");
  ctx.fillStyle = "#94a3b8";
  ctx.font = "bold 11px system-ui, sans-serif";
  ctx.fillText(label, x + 16, y + 24);
  ctx.fillStyle = "#0f172a";
  ctx.font = "800 15px system-ui, sans-serif";
  const lines = wrapText(ctx, value, w - 28);
  ctx.fillText(lines[0] ?? value, x + 16, y + 48);
}

function drawTotalRow(
  ctx: CanvasRenderingContext2D,
  left: number,
  right: number,
  y: number,
  label: string,
  value: string,
  bold: boolean,
  color = "#0f172a"
) {
  ctx.fillStyle = bold ? "#0f172a" : "#64748b";
  ctx.font = bold ? "800 18px system-ui, sans-serif" : "600 15px system-ui, sans-serif";
  ctx.textAlign = "left";
  ctx.fillText(label, left, y);
  ctx.fillStyle = color;
  ctx.font = bold ? "800 18px system-ui, sans-serif" : "700 15px system-ui, sans-serif";
  ctx.textAlign = "right";
  ctx.fillText(value, right, y);
  ctx.textAlign = "left";
}

export async function canvasToBlob(canvas: HTMLCanvasElement): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (blob) resolve(blob);
      else reject(new Error("No se pudo crear la imagen"));
    }, "image/png");
  });
}

export async function downloadInvoicePng(doc: PortableDoc) {
  const canvas = renderInvoiceCanvas(doc);
  const blob = await canvasToBlob(canvas);
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${doc.n || "factura-raquel"}.png`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
  return blob;
}

export async function shareInvoice(doc: PortableDoc) {
  const canvas = renderInvoiceCanvas(doc);
  const blob = await canvasToBlob(canvas);
  const file = new File([blob], `${doc.n}.png`, { type: "image/png" });
  const kind = doc.k === "FAC" ? "Factura" : "Proforma";
  const text = `${kind} ${doc.n} · Instalaciones Raquel · Total ${money(doc.t)}`;

  if (navigator.canShare?.({ files: [file] })) {
    await navigator.share({ title: `${kind} ${doc.n}`, text, files: [file] });
    return "shared";
  }
  if (navigator.share) {
    await navigator.share({ title: `${kind} ${doc.n}`, text, url: window.location.href });
    return "shared-link";
  }
  await downloadInvoicePng(doc);
  return "downloaded";
}

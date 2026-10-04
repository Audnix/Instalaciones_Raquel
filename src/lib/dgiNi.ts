import type { Purchase, Sale } from "../types/erp";

/** Datos fiscales de demostración · Ley 822 Ley de Concertación Tributaria */
export const companyFiscal = {
  name: "Instalaciones Raquel",
  ruc: "J0310000123456",
  regimen: "Régimen general",
  activity: "Aluminio, vidrio y electrodomésticos",
  city: "Nicaragua",
  dmiHint: "Declaración mensual DMI · primeros 5 días hábiles"
};

export const IVA_RATE = 0.15;
export const RETENCION_IR = 0.02;
export const RETENCION_CODE = "22";
export const RETENCION_MIN = 1000;
export const ANTICIPO_IR = 0.01;
export const IM_RATE = 0.01;

export function monthKey(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

export function monthLabel(key: string) {
  const [year, month] = key.split("-");
  const names = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"];
  return `${names[Number(month) - 1] ?? month} ${year}`;
}

export function inMonth(iso: string, key: string) {
  return iso.slice(0, 7) === key;
}

export function ivaOf(amount: number) {
  return Number((amount * IVA_RATE).toFixed(2));
}

export function retentionOf(amount: number) {
  if (amount < RETENCION_MIN) return 0;
  return Number((amount * RETENCION_IR).toFixed(2));
}

export function buildDmi(sales: Sale[], purchases: Purchase[], key: string) {
  const saleRows = sales.filter((item) => item.status === "completed" && inMonth(item.saleDate, key));
  const buyRows = purchases.filter((item) => item.status === "received" && inMonth(item.purchaseDate, key));
  const saleBase = saleRows.reduce((sum, item) => sum + item.subtotal - (item.discountAmount ?? 0), 0);
  const saleIva = saleRows.reduce((sum, item) => sum + item.taxAmount, 0);
  const saleTotal = saleRows.reduce((sum, item) => sum + item.total, 0);
  const buyTotal = buyRows.reduce((sum, item) => sum + item.total, 0);
  const buyBase = Number((buyTotal / (1 + IVA_RATE)).toFixed(2));
  const buyIva = Number((buyTotal - buyBase).toFixed(2));
  const retencion = buyRows.reduce((sum, item) => sum + retentionOf(item.total), 0);
  const anticipo = Number((saleTotal * ANTICIPO_IR).toFixed(2));
  const im = Number((saleTotal * IM_RATE).toFixed(2));
  const ivaPagar = Number((saleIva - buyIva).toFixed(2));
  return {
    key,
    saleRows,
    buyRows,
    saleBase,
    saleIva,
    saleTotal,
    buyTotal,
    buyBase,
    buyIva,
    retencion,
    anticipo,
    im,
    ivaPagar
  };
}

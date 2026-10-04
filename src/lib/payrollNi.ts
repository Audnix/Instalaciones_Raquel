import type { Employee } from "../types/erp";

/** Decreto 06-2019 INSS · Ley INATEC 2% · IR Art. 23 LCT (rentas del trabajo) */
export const INSS_LABORAL = 0.07;
export const INSS_PATRONAL = 0.215;
export const INATEC_RATE = 0.02;
export const AGUINALDO_RATE = 1 / 12;

export type Payslip = {
  employeeId: string;
  name: string;
  position: string;
  area: string;
  gross: number;
  inssLaboral: number;
  ir: number;
  net: number;
  inssPatronal: number;
  inatec: number;
  aguinaldo: number;
  employerCost: number;
};

function round(value: number) {
  return Number(value.toFixed(2));
}

/** Tarifa progresiva anual de rentas del trabajo (Art. 23 LCT). */
export function annualIr(netAnnual: number) {
  if (netAnnual <= 100000) return 0;
  if (netAnnual <= 200000) return round((netAnnual - 100000) * 0.15);
  if (netAnnual <= 350000) return round(15000 + (netAnnual - 200000) * 0.2);
  if (netAnnual <= 500000) return round(45000 + (netAnnual - 350000) * 0.25);
  return round(82500 + (netAnnual - 500000) * 0.3);
}

export function slipOf(employee: Employee): Payslip {
  const gross = employee.salary;
  const inssLaboral = round(gross * INSS_LABORAL);
  const ir = round(annualIr((gross - inssLaboral) * 12) / 12);
  const net = round(gross - inssLaboral - ir);
  const inssPatronal = round(gross * INSS_PATRONAL);
  const inatec = round(gross * INATEC_RATE);
  const aguinaldo = round(gross * AGUINALDO_RATE);
  return {
    employeeId: employee.id,
    name: employee.name,
    position: employee.position,
    area: employee.area,
    gross,
    inssLaboral,
    ir,
    net,
    inssPatronal,
    inatec,
    aguinaldo,
    employerCost: round(gross + inssPatronal + inatec)
  };
}

export function payrollOf(employees: Employee[]) {
  const slips = employees.map(slipOf);
  const sum = (key: keyof Omit<Payslip, "employeeId" | "name" | "position" | "area">) =>
    round(slips.reduce((total, item) => total + item[key], 0));
  return {
    slips,
    headcount: slips.length,
    gross: sum("gross"),
    inssLaboral: sum("inssLaboral"),
    ir: sum("ir"),
    net: sum("net"),
    inssPatronal: sum("inssPatronal"),
    inatec: sum("inatec"),
    aguinaldo: sum("aguinaldo"),
    employerCost: sum("employerCost")
  };
}

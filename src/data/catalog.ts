import type { InventoryLot, Product, Promotion } from "../types/erp";

const stamp = (daysAgo: number) => new Date(Date.now() - daysAgo * 86400000).toISOString();

export const catalogProducts: Product[] = [
  { id: "p1", code: "ALU-5020", name: "Perfil serie 5020", category: "Perfiles", unitPrice: 186, minQuantity: 40, createdAt: stamp(40) },
  { id: "p2", code: "VID-10T", name: "Vidrio templado 10mm", category: "Vidrios", unitPrice: 420, minQuantity: 20, createdAt: stamp(40) },
  { id: "p3", code: "SIL-NB", name: "Silicon neutro blanco", category: "Accesorios", unitPrice: 95, minQuantity: 12, createdAt: stamp(30) },
  { id: "p4", code: "ACC-HER", name: "Herraje de ventana", category: "Accesorios", unitPrice: 64, minQuantity: 30, createdAt: stamp(30) },
  { id: "p5", code: "ALU-7000", name: "Perfil serie 7000", category: "Perfiles", unitPrice: 245, minQuantity: 25, createdAt: stamp(20) },
  { id: "p6", code: "VID-6CL", name: "Vidrio claro 6mm", category: "Vidrios", unitPrice: 185, minQuantity: 35, createdAt: stamp(18) },
  { id: "p7", code: "MOS-INS", name: "Mosquitero enrollable", category: "Accesorios", unitPrice: 320, minQuantity: 10, createdAt: stamp(12) },
  { id: "p8", code: "BAR-12", name: "Barandal templado 12mm", category: "Vidrios", unitPrice: 890, minQuantity: 8, createdAt: stamp(10) },
  { id: "e1", code: "REF-18P", name: "Refrigeradora 18 pies", category: "Electrodomésticos", unitPrice: 18500, minQuantity: 3, createdAt: stamp(15) },
  { id: "e2", code: "LAV-16K", name: "Lavadora 16 kg", category: "Electrodomésticos", unitPrice: 12400, minQuantity: 4, createdAt: stamp(14) },
  { id: "e3", code: "SEC-8K", name: "Secadora 8 kg", category: "Electrodomésticos", unitPrice: 9800, minQuantity: 3, createdAt: stamp(14) },
  { id: "e4", code: "MIC-30L", name: "Microondas 30L", category: "Electrodomésticos", unitPrice: 3200, minQuantity: 6, createdAt: stamp(12) },
  { id: "e5", code: "EST-4Q", name: "Estufa 4 quemadores", category: "Electrodomésticos", unitPrice: 7600, minQuantity: 4, createdAt: stamp(11) },
  { id: "e6", code: "AIR-12K", name: "Aire acondicionado 12k BTU", category: "Electrodomésticos", unitPrice: 14900, minQuantity: 3, createdAt: stamp(10) },
  { id: "e7", code: "TV-55S", name: "Smart TV 55 pulgadas", category: "Electrodomésticos", unitPrice: 16800, minQuantity: 5, createdAt: stamp(9) },
  { id: "e8", code: "LIC-PRO", name: "Licuadora profesional", category: "Electrodomésticos", unitPrice: 2100, minQuantity: 8, createdAt: stamp(8) },
  { id: "e9", code: "CAF-ESP", name: "Cafetera espresso", category: "Electrodomésticos", unitPrice: 4500, minQuantity: 5, createdAt: stamp(7) },
  { id: "e10", code: "ASP-ROB", name: "Aspiradora robot", category: "Electrodomésticos", unitPrice: 8900, minQuantity: 4, createdAt: stamp(6) },
  { id: "e11", code: "HOR-ELE", name: "Horno eléctrico", category: "Electrodomésticos", unitPrice: 5400, minQuantity: 4, createdAt: stamp(5) },
  { id: "e12", code: "VEN-TOR", name: "Ventilador de torre", category: "Electrodomésticos", unitPrice: 1800, minQuantity: 10, createdAt: stamp(4) }
];

export const catalogLots: InventoryLot[] = [
  { id: "l1", productId: "p1", quantity: 120, unitCost: 140, entryDate: stamp(35), warehouseId: "Bodega central" },
  { id: "l1b", productId: "p1", quantity: 80, unitCost: 148, entryDate: stamp(10), warehouseId: "Bodega central" },
  { id: "l2", productId: "p2", quantity: 36, unitCost: 310, entryDate: stamp(28), warehouseId: "Bodega central" },
  { id: "l2b", productId: "p2", quantity: 22, unitCost: 325, entryDate: stamp(6), warehouseId: "Obra Torre Azul" },
  { id: "l3", productId: "p3", quantity: 8, unitCost: 62, entryDate: stamp(20), warehouseId: "Bodega central" },
  { id: "l4", productId: "p4", quantity: 90, unitCost: 38, entryDate: stamp(22), warehouseId: "Bodega central" },
  { id: "l5", productId: "p5", quantity: 55, unitCost: 190, entryDate: stamp(14), warehouseId: "Bodega central" },
  { id: "l6", productId: "p6", quantity: 70, unitCost: 120, entryDate: stamp(12), warehouseId: "Bodega central" },
  { id: "l7", productId: "p7", quantity: 9, unitCost: 210, entryDate: stamp(8), warehouseId: "Bodega central" },
  { id: "l8", productId: "p8", quantity: 6, unitCost: 640, entryDate: stamp(5), warehouseId: "Bodega central" },
  { id: "le1", productId: "e1", quantity: 5, unitCost: 14200, entryDate: stamp(15), warehouseId: "Showroom" },
  { id: "le2", productId: "e2", quantity: 6, unitCost: 9800, entryDate: stamp(14), warehouseId: "Showroom" },
  { id: "le3", productId: "e3", quantity: 4, unitCost: 7600, entryDate: stamp(14), warehouseId: "Showroom" },
  { id: "le4", productId: "e4", quantity: 12, unitCost: 2400, entryDate: stamp(12), warehouseId: "Showroom" },
  { id: "le5", productId: "e5", quantity: 7, unitCost: 5900, entryDate: stamp(11), warehouseId: "Showroom" },
  { id: "le6", productId: "e6", quantity: 4, unitCost: 11800, entryDate: stamp(10), warehouseId: "Showroom" },
  { id: "le7", productId: "e7", quantity: 8, unitCost: 12900, entryDate: stamp(9), warehouseId: "Showroom" },
  { id: "le8", productId: "e8", quantity: 15, unitCost: 1500, entryDate: stamp(8), warehouseId: "Showroom" },
  { id: "le9", productId: "e9", quantity: 9, unitCost: 3200, entryDate: stamp(7), warehouseId: "Showroom" },
  { id: "le10", productId: "e10", quantity: 5, unitCost: 6900, entryDate: stamp(6), warehouseId: "Showroom" },
  { id: "le11", productId: "e11", quantity: 6, unitCost: 4100, entryDate: stamp(5), warehouseId: "Showroom" },
  { id: "le12", productId: "e12", quantity: 18, unitCost: 1100, entryDate: stamp(4), warehouseId: "Showroom" }
];

export const catalogPromotions: Promotion[] = [
  {
    id: "promo1",
    title: "Combo Hogar 8%",
    blurb: "Llevá electrodomésticos o kit de ventana y ahorrá desde C$ 3,000.",
    minSubtotal: 3000,
    percentOff: 8,
    active: true,
    badge: "-8%"
  },
  {
    id: "promo2",
    title: "Renovación 12%",
    blurb: "Compras fuertes de taller o showroom. Ideal para proyectos y packs TV + aire.",
    minSubtotal: 10000,
    percentOff: 12,
    active: true,
    badge: "-12%"
  },
  {
    id: "promo3",
    title: "Mega pack 15%",
    blurb: "Pedidos grandes: refrigeradora, lavadora o fachadas completas.",
    minSubtotal: 20000,
    percentOff: 15,
    active: true,
    badge: "-15%"
  },
  {
    id: "promo4",
    title: "Arranque 5%",
    blurb: "Descuento de bienvenida en compras desde C$ 1,500.",
    minSubtotal: 1500,
    percentOff: 5,
    active: true,
    badge: "-5%"
  }
];

export function bestPromotion(subtotal: number, promotions: Promotion[]) {
  const eligible = promotions
    .filter((item) => item.active && subtotal >= item.minSubtotal)
    .sort((a, b) => b.percentOff - a.percentOff);
  const promo = eligible[0];
  if (!promo) return { promo: null, discount: 0 };
  return { promo, discount: Number(((subtotal * promo.percentOff) / 100).toFixed(2)) };
}

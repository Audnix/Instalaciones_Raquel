import type { InventoryLot, Product, Promotion } from "../types/erp";

const stamp = (daysAgo: number) => new Date(Date.now() - daysAgo * 86400000).toISOString();

export const catalogProducts: Product[] = [
  { id: "p1", code: "ALU-5020", name: "Perfil serie 5020", category: "Perfiles", unitPrice: 186, minQuantity: 40, createdAt: stamp(40), model: "Raquel 5020-A", brand: "Alumex / Raquel", material: "Aluminio 6063-T5", measures: "Barra 6.10 m · marco 50 mm", finish: "Mill finish / anodizado natural", use: "Ventanas corredizas residenciales", warranty: "10 años en perfil" },
  { id: "p2", code: "VID-10T", name: "Vidrio templado 10mm", category: "Vidrios", unitPrice: 420, minQuantity: 20, createdAt: stamp(40), model: "TEMP-10H", brand: "Vidrios del Pacífico", material: "Vidrio de seguridad templado", measures: "10 mm · corte a medida", finish: "Incoloro, canto pulido", use: "Puertas, mamparas y fachadas", warranty: "5 años contra defectos de temple" },
  { id: "p3", code: "SIL-NB", name: "Silicon neutro blanco", category: "Accesorios", unitPrice: 95, minQuantity: 12, createdAt: stamp(30), model: "SN-280B", brand: "Raquel Sellos", material: "Silicona neutra oxima", measures: "Cartucho 280 ml", finish: "Blanco mate", use: "Sellado de vidrio y aluminio", warranty: "12 meses" },
  { id: "p4", code: "ACC-HER", name: "Herraje de ventana", category: "Accesorios", unitPrice: 64, minQuantity: 30, createdAt: stamp(30), model: "HV-2026", brand: "Raquel Herrajes", material: "Zamac y acero inoxidable", measures: "Kit manija + chapa + 2 bisagras", finish: "Cromo satinado", use: "Ventana proyectante o corrediza", warranty: "2 años" },
  { id: "p5", code: "ALU-7000", name: "Perfil serie 7000", category: "Perfiles", unitPrice: 245, minQuantity: 25, createdAt: stamp(20), model: "Raquel 7000-F", brand: "Alumex / Raquel", material: "Aluminio 6063-T5 estructural", measures: "Barra 6.10 m · marco 70 mm", finish: "Anodizado bronce oscuro", use: "Fachadas y ventanería pesada", warranty: "10 años en perfil" },
  { id: "p6", code: "VID-6CL", name: "Vidrio claro 6mm", category: "Vidrios", unitPrice: 185, minQuantity: 35, createdAt: stamp(18), model: "FLT-6C", brand: "Vidrios del Pacífico", material: "Float incoloro", measures: "6 mm · lámina 2.14 × 3.30 m", finish: "Transparente", use: "Ventanas livianas y vitrinas", warranty: "1 año" },
  { id: "p7", code: "MOS-INS", name: "Mosquitero enrollable", category: "Accesorios", unitPrice: 320, minQuantity: 10, createdAt: stamp(12), model: "MOS-ROLL 120", brand: "Raquel Malla", material: "Fibra de vidrio + cassette aluminio", measures: "Hasta 1.20 × 1.50 m", finish: "Blanco", use: "Ventanas y balcones", warranty: "18 meses" },
  { id: "p8", code: "BAR-12", name: "Barandal templado 12mm", category: "Vidrios", unitPrice: 890, minQuantity: 8, createdAt: stamp(10), model: "BAR-12 SPG", brand: "Raquel Cristal", material: "Templado extra claro 12 mm", measures: "Paño hasta 1.10 × 2.40 m", finish: "Canto pulido, herraje inox", use: "Balcones y terrazas", warranty: "5 años" },
  { id: "e1", code: "REF-18P", name: "Refrigeradora 18 pies", category: "Electrodomésticos", unitPrice: 18500, minQuantity: 3, createdAt: stamp(15), model: "RQ-RF18 INOX", brand: "Raquel Hogar", material: "Acero inoxidable / no frost", measures: "70 × 68 × 175 cm", capacity: "510 L · 18 pies³", finish: "Inox fingerprint-proof", use: "Cocina familiar", warranty: "2 años + 5 compresor" },
  { id: "e2", code: "LAV-16K", name: "Lavadora 16 kg", category: "Electrodomésticos", unitPrice: 12400, minQuantity: 4, createdAt: stamp(14), model: "RQ-LW16 FL", brand: "Raquel Hogar", material: "Tambor inox, carcasa ABS", measures: "60 × 65 × 85 cm", capacity: "16 kg carga frontal", finish: "Blanco / visor cromo", use: "Hogar y lavandería", warranty: "2 años" },
  { id: "e3", code: "SEC-8K", name: "Secadora 8 kg", category: "Electrodomésticos", unitPrice: 9800, minQuantity: 3, createdAt: stamp(14), model: "RQ-DR08", brand: "Raquel Hogar", material: "Tambor inox", measures: "60 × 62 × 85 cm", capacity: "8 kg", finish: "Blanco", use: "Ropa de hogar", warranty: "2 años" },
  { id: "e4", code: "MIC-30L", name: "Microondas 30L", category: "Electrodomésticos", unitPrice: 3200, minQuantity: 6, createdAt: stamp(12), model: "RQ-MW30", brand: "Raquel Hogar", material: "Cavidad inox", measures: "52 × 42 × 31 cm", capacity: "30 L · 1000 W", finish: "Negro espejo", use: "Cocina y oficina", warranty: "1 año" },
  { id: "e5", code: "EST-4Q", name: "Estufa 4 quemadores", category: "Electrodomésticos", unitPrice: 7600, minQuantity: 4, createdAt: stamp(11), model: "RQ-ST4G", brand: "Raquel Hogar", material: "Cubierta inox, horno esmaltado", measures: "76 × 58 × 85 cm", capacity: "Horno 55 L", finish: "Inox / vidrio negro", use: "Cocina a gas", warranty: "2 años" },
  { id: "e6", code: "AIR-12K", name: "Aire acondicionado 12k BTU", category: "Electrodomésticos", unitPrice: 14900, minQuantity: 3, createdAt: stamp(10), model: "RQ-AC12 INV", brand: "Raquel Clima", material: "Split inverter R32", measures: "Unidad interior 80 × 28 × 20 cm", capacity: "12,000 BTU · 220 V", finish: "Blanco mate", use: "Habitación hasta 24 m²", warranty: "3 años + 5 compresor" },
  { id: "e7", code: "TV-55S", name: "Smart TV 55 pulgadas", category: "Electrodomésticos", unitPrice: 16800, minQuantity: 5, createdAt: stamp(9), model: "RQ-TV55 4K", brand: "Raquel Vision", material: "LED 4K UHD", measures: "123 × 72 × 8 cm", capacity: "55 pulgadas · Android TV", finish: "Marco ultrafino negro", use: "Sala y showroom", warranty: "2 años" },
  { id: "e8", code: "LIC-PRO", name: "Licuadora profesional", category: "Electrodomésticos", unitPrice: 2100, minQuantity: 8, createdAt: stamp(8), model: "RQ-BL1200", brand: "Raquel Hogar", material: "Vaso de vidrio, cuchillas inox", measures: "Vaso 1.8 L", capacity: "1200 W", finish: "Acero / negro", use: "Cocina y jugos", warranty: "1 año" },
  { id: "e9", code: "CAF-ESP", name: "Cafetera espresso", category: "Electrodomésticos", unitPrice: 4500, minQuantity: 5, createdAt: stamp(7), model: "RQ-ES15", brand: "Raquel Hogar", material: "Caldera inox", measures: "32 × 28 × 31 cm", capacity: "15 bar · 1.5 L", finish: "Inox cepillado", use: "Café espresso y capuchino", warranty: "1 año" },
  { id: "e10", code: "ASP-ROB", name: "Aspiradora robot", category: "Electrodomésticos", unitPrice: 8900, minQuantity: 4, createdAt: stamp(6), model: "RQ-RV200", brand: "Raquel Hogar", material: "ABS + lidar", measures: "Diámetro 35 cm · alto 9.5 cm", capacity: "Autonomía 120 min", finish: "Negro / plata", use: "Piso y baldosa", warranty: "2 años" },
  { id: "e11", code: "HOR-ELE", name: "Horno eléctrico", category: "Electrodomésticos", unitPrice: 5400, minQuantity: 4, createdAt: stamp(5), model: "RQ-OV45", brand: "Raquel Hogar", material: "Acero esmaltado, puerta de vidrio", measures: "45 × 40 × 35 cm", capacity: "45 L · 1800 W", finish: "Negro / inox", use: "Hornear y gratinar", warranty: "1 año" },
  { id: "e12", code: "VEN-TOR", name: "Ventilador de torre", category: "Electrodomésticos", unitPrice: 1800, minQuantity: 10, createdAt: stamp(4), model: "RQ-TF90", brand: "Raquel Clima", material: "ABS, motor silencioso", measures: "Alto 90 cm", capacity: "3 velocidades + oscilación", finish: "Negro", use: "Habitación y oficina", warranty: "1 año" }
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

export function productPhoto(product: { id: string; image?: string }) {
  return product.image || `/productos/prod-${product.id}.png`;
}

export function mergeProductSpecs(rows: Product[]) {
  return rows.map((item) => {
    const seed = catalogProducts.find((row) => row.id === item.id);
    if (!seed) return item;
    return {
      ...item,
      model: item.model ?? seed.model,
      brand: item.brand ?? seed.brand,
      material: item.material ?? seed.material,
      measures: item.measures ?? seed.measures,
      capacity: item.capacity ?? seed.capacity,
      finish: item.finish ?? seed.finish,
      use: item.use ?? seed.use,
      warranty: item.warranty ?? seed.warranty
    };
  });
}

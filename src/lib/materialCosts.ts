import type { Product, InventoryLot } from '../types/erp';

// Repairs UTF-8 text accidentally read as Windows-1252, for display only.
export function displayText(value: string): string {
  const decoder = new TextDecoder('windows-1252');
  const byteByChar = new Map(Array.from({ length: 256 }, (_, byte) => [decoder.decode(Uint8Array.of(byte)), byte] as const));
  let text = value;
  for (let pass = 0; pass < 2; pass++) {
    const chars = Array.from(text);
    let result = '';
    for (let i = 0; i < chars.length; i++) {
      const first = byteByChar.get(chars[i]);
      const length = first === 0xc2 || first === 0xc3 ? 2 : first === 0xe2 ? 3 : first === 0xf0 ? 4 : 0;
      if (length && i + length <= chars.length) {
        const bytes = chars.slice(i, i + length).map(char => byteByChar.get(char));
        if (bytes.slice(1).every(byte => byte !== undefined && byte >= 0x80 && byte <= 0xbf)) {
          try {
            result += new TextDecoder('utf-8', { fatal: true }).decode(Uint8Array.from(bytes as number[]));
            i += length - 1;
            continue;
          } catch { /* Keep original characters when they are not valid UTF-8. */ }
        }
      }
      result += chars[i];
    }
    if (result === text) break;
    text = result;
  }
  return text;
}

export function materialCosts(products: Product[], lots: InventoryLot[]) {
  return products.map(product => {
    const productLots = lots.filter(lot => lot.productId === product.id);
    const quantity = productLots.reduce((sum, lot) => sum + lot.quantity, 0);
    const value = productLots.reduce((sum, lot) => sum + lot.quantity * lot.unitCost, 0);
    return { product, quantity, value, averageCost: quantity > 0 ? value / quantity : 0, lots: productLots };
  });
}

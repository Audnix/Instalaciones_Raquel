import { Link, useParams } from "react-router-dom";
import { AlbumGrid } from "../components/AlbumStudio";
import { productPhoto } from "../data/catalog";
import { IVA_RATE, monthLabel } from "../lib/dgiNi";
import { useErp } from "../store/erpStore";
import { Money } from "../components/Ui";
import logo from "../assets/logo-window.png";
import type { Product } from "../types/erp";

export default function CatalogAlbumPage() {
  const { month, productId } = useParams();
  const { db, stockOf } = useErp();
  const album = (db.albums ?? []).find((item) => item.month === month && item.published) ?? (db.albums ?? []).find((item) => item.published);
  const months = [...(db.albums ?? [])].filter((item) => item.published).sort((a, b) => b.month.localeCompare(a.month));
  const product = productId ? db.products.find((item) => item.id === productId) : undefined;
  const featured = album ? db.products.find((item) => item.id === album.productIds[0]) : undefined;

  if (!album) {
    return (
      <main className="grid min-h-screen place-items-center bg-slate-950 p-6 text-white">
        <p>No hay álbum publicado.</p>
      </main>
    );
  }

  if (productId && !product) {
    return (
      <main className="grid min-h-screen place-items-center bg-slate-950 p-6 text-white">
        <p>Ese producto no está en vitrina.</p>
        <Link to={`/vitrina/${album.month}`} className="mt-3 font-bold text-cyan-300">Volver al álbum</Link>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-slate-950 pb-16 text-white">
      <header className="relative overflow-hidden">
        {(product ?? featured) && (
          <img src={productPhoto(product ?? featured!)} alt="" className="absolute inset-0 h-full w-full object-cover opacity-35" />
        )}
        <div className="absolute inset-0 bg-gradient-to-br from-brand-950/92 via-brand-800/82 to-cyan-900/70" />
        <div className="relative mx-auto max-w-5xl px-4 py-10">
          <div className="flex items-center gap-3">
            <img src={logo} alt="" className="h-12 w-12 rounded-xl bg-white object-contain p-1" />
            <div>
              <p className="text-xs font-bold uppercase tracking-[0.2em] text-cyan-100">Instalaciones Raquel</p>
              <h1 className="text-3xl font-black">{product ? product.name : album.title}</h1>
            </div>
          </div>
          {product ? (
            <p className="mt-3 text-sm font-bold text-cyan-100">Modelo {product.model ?? product.code} · {monthLabel(album.month)}</p>
          ) : (
            <>
              <p className="mt-4 max-w-2xl text-sm text-cyan-50/90">{album.blurb}</p>
              <p className="mt-2 text-sm font-bold">{monthLabel(album.month)} · tocá un producto para ver modelo y ficha</p>
            </>
          )}
        </div>
      </header>
      <div className="mx-auto max-w-5xl space-y-6 px-4 py-6">
        <div className="flex flex-wrap gap-2">
          {months.map((item) => (
            <Link
              key={item.id}
              to={`/vitrina/${item.month}`}
              className={`rounded-full px-3 py-1.5 text-xs font-bold ${item.month === album.month && !product ? "bg-cyan-400 text-slate-950" : "bg-white/10 text-cyan-50"}`}
            >
              {monthLabel(item.month)}
            </Link>
          ))}
        </div>
        {product ? (
          <ProductSheet product={product} month={album.month} stock={stockOf(product.id)} />
        ) : (
          <AlbumGrid month={album.month} productIds={album.productIds} products={db.products} />
        )}
      </div>
    </main>
  );
}

function ProductSheet({ product, month, stock }: { product: Product; month: string; stock: number }) {
  const withIva = product.unitPrice * (1 + IVA_RATE);
  const rows = [
    ["Modelo", product.model ?? product.code],
    ["SKU", product.code],
    ["Marca", product.brand ?? "Raquel"],
    ["Línea", product.category],
    ["Material", product.material],
    ["Medidas", product.measures],
    ["Capacidad", product.capacity],
    ["Acabado", product.finish],
    ["Uso", product.use],
    ["Garantía", product.warranty],
    ["Existencia", `${stock} u`]
  ].filter((item) => item[1]);

  return (
    <section className="grid gap-5 overflow-hidden rounded-3xl bg-white text-slate-900 shadow-soft lg:grid-cols-[1.05fr_.95fr] dark:bg-slate-900 dark:text-white">
      <img src={productPhoto(product)} alt={product.name} className="h-80 w-full object-cover lg:h-full" />
      <div className="p-5 sm:p-7">
        <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand-700">{product.category}</p>
        <h2 className="mt-2 text-3xl font-black leading-tight">{product.name}</h2>
        <p className="mt-2 text-sm font-bold text-slate-500">Modelo {product.model ?? product.code}</p>
        <div className="mt-4 flex flex-wrap items-end gap-4">
          <div>
            <p className="text-xs text-slate-500">Precio de vitrina</p>
            <p className="text-3xl font-black text-brand-800 dark:text-cyan-200"><Money value={withIva} /></p>
            <p className="text-xs text-slate-500">IVA 15% incluido · base <Money value={product.unitPrice} /></p>
          </div>
        </div>
        <dl className="mt-5 divide-y divide-slate-100 text-sm dark:divide-white/10">
          {rows.map(([label, value]) => (
            <div key={label} className="flex items-start justify-between gap-4 py-2">
              <dt className="text-slate-500">{label}</dt>
              <dd className="max-w-[60%] text-right font-bold">{value}</dd>
            </div>
          ))}
        </dl>
        <div className="mt-6 flex flex-wrap gap-2">
          <Link to={`/vitrina/${month}`} className="rounded-lg bg-slate-100 px-4 py-2 text-sm font-bold dark:bg-white/10">Volver al álbum</Link>
          <Link to="/login" className="rounded-lg bg-brand-600 px-4 py-2 text-sm font-bold text-white">Pedir en caja</Link>
        </div>
      </div>
    </section>
  );
}

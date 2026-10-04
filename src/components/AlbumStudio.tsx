import { FormEvent, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Copy, Share2 } from "lucide-react";
import { useAuth } from "../auth/AuthContext";
import { productPhoto } from "../data/catalog";
import { Button } from "./Button";
import { Field, inputClass, Money, StatusPill } from "./Ui";
import { IVA_RATE, monthKey, monthLabel } from "../lib/dgiNi";
import { getPublicOrigin } from "../lib/publicOrigin";
import { useErp } from "../store/erpStore";

export function AlbumStudio() {
  const { db, publishAlbum } = useErp();
  const { user, can } = useAuth();
  const write = can("mercadotecnia", "write");
  const [month, setMonth] = useState(monthKey());
  const [title, setTitle] = useState("Vitrina del mes");
  const [blurb, setBlurb] = useState("Productos en venta este mes. Tocá el enlace y recorré el álbum.");
  const [picked, setPicked] = useState<string[]>(db.albums.find((item) => item.month === month)?.productIds ?? []);
  const [copied, setCopied] = useState<string | null>(null);
  const albums = useMemo(() => [...(db.albums ?? [])].sort((a, b) => b.month.localeCompare(a.month)), [db.albums]);

  const shareUrl = (key: string) => `${getPublicOrigin()}/vitrina/${key}`;

  const copyLink = async (key: string) => {
    const album = db.albums.find((item) => item.month === key);
    const text = `${album?.title ?? "Álbum"} · ${monthLabel(key)}\nInstalaciones Raquel · catálogo con fotos\n${shareUrl(key)}`;
    await navigator.clipboard.writeText(text);
    setCopied(key);
  };

  const submit = (event: FormEvent) => {
    event.preventDefault();
    if (!picked.length) return;
    publishAlbum({
      month,
      title,
      blurb,
      productIds: picked,
      published: true
    }, user?.name ?? "sistema");
  };

  return (
    <section className="space-y-4">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-brand-700">Álbum del mes</p>
          <h2 className="mt-1 text-xl font-black">Catálogo con foto, fecha y enlace</h2>
          <p className="text-sm text-slate-500">Listo para WhatsApp o Facebook: se ve el producto, el precio y el mes.</p>
        </div>
      </div>

      {write && (
        <form onSubmit={submit} className="space-y-3 rounded-2xl bg-white p-5 shadow-soft dark:bg-slate-900">
          <div className="grid gap-3 md:grid-cols-3">
            <Field label="Mes">
              <input className={inputClass} type="month" value={month} onChange={(e) => setMonth(e.target.value)} />
            </Field>
            <Field label="Título del álbum">
              <input className={inputClass} value={title} onChange={(e) => setTitle(e.target.value)} />
            </Field>
            <Field label="Texto">
              <input className={inputClass} value={blurb} onChange={(e) => setBlurb(e.target.value)} />
            </Field>
          </div>
          <p className="text-sm font-semibold">Productos de este mes</p>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 xl:grid-cols-5">
            {db.products.map((item) => {
              const on = picked.includes(item.id);
              return (
                <button
                  type="button"
                  key={item.id}
                  onClick={() => setPicked(on ? picked.filter((id) => id !== item.id) : [...picked, item.id])}
                  className={`overflow-hidden rounded-xl border text-left ${on ? "border-brand-600 ring-2 ring-brand-500" : "border-slate-200 dark:border-white/10"}`}
                >
                  <img src={productPhoto(item)} alt="" className="h-20 w-full object-cover" />
                  <span className="block truncate px-2 py-1 text-[11px] font-bold">{item.name}</span>
                </button>
              );
            })}
          </div>
          <Button type="submit">Publicar álbum</Button>
        </form>
      )}

      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {albums.map((album) => (
          <article key={album.id} className="overflow-hidden rounded-2xl bg-white shadow-soft dark:bg-slate-900">
            <div className="grid grid-cols-4">
              {album.productIds.slice(0, 4).map((id) => {
                const product = db.products.find((item) => item.id === id);
                if (!product) return null;
                return <img key={id} src={productPhoto(product)} alt={product.name} className="h-20 w-full object-cover" />;
              })}
            </div>
            <div className="p-4">
              <div className="flex items-center justify-between gap-2">
                <StatusPill tone={album.published ? "ok" : "neutral"}>{monthLabel(album.month)}</StatusPill>
                {copied === album.month && <span className="text-[11px] font-bold text-emerald-700">Copiado</span>}
              </div>
              <h3 className="mt-3 font-black">{album.title}</h3>
              <p className="mt-1 text-sm text-slate-500">{album.blurb}</p>
              <p className="mt-3 truncate text-[11px] text-slate-400">{shareUrl(album.month)}</p>
              <div className="mt-3 flex flex-wrap gap-2">
                <Link to={`/vitrina/${album.month}`} target="_blank" rel="noreferrer">
                  <Button variant="secondary" icon={<Share2 size={14} />}>Abrir</Button>
                </Link>
                <Button variant="ghost" icon={<Copy size={14} />} onClick={() => void copyLink(album.month)}>Copiar fecha y link</Button>
              </div>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

export function AlbumGrid({
  productIds,
  products,
  month
}: {
  productIds: string[];
  products: Array<{
    id: string;
    name: string;
    code: string;
    category: string;
    unitPrice: number;
    image?: string;
    model?: string;
  }>;
  month: string;
}) {
  return (
    <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {productIds.map((id, index) => {
        const item = products.find((row) => row.id === id);
        if (!item) return null;
        const withIva = item.unitPrice * (1 + IVA_RATE);
        return (
          <Link
            key={item.id}
            to={`/vitrina/${month}/${item.id}`}
            className="group overflow-hidden rounded-3xl bg-white text-left shadow-soft transition hover:-translate-y-0.5 dark:bg-slate-900"
          >
            <div className="relative">
              <img src={productPhoto(item)} alt={item.name} className="h-56 w-full object-cover transition duration-300 group-hover:scale-[1.04]" />
              <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950 via-slate-950/80 to-transparent p-4 pt-16 text-white">
                <p className="text-[11px] font-bold uppercase tracking-wide text-cyan-200">{item.category}</p>
                <h3 className="mt-1 text-lg font-black leading-tight drop-shadow">{item.name}</h3>
                <p className="mt-1 text-xs font-semibold text-cyan-100">Modelo {item.model ?? item.code}</p>
                <div className="mt-2 flex items-center justify-between gap-2">
                  <span className="text-sm font-black"><Money value={withIva} /></span>
                  <span className="rounded-full bg-cyan-400 px-3 py-1 text-[11px] font-black text-slate-950">Ver ficha</span>
                </div>
              </div>
              {index === 0 && (
                <span className="absolute right-3 top-3 rounded-full bg-ember px-2 py-1 text-[10px] font-black uppercase text-white">Destacado</span>
              )}
            </div>
          </Link>
        );
      })}
    </section>
  );
}

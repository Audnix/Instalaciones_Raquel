import { getApiBaseUrl } from '../lib/apiBase';
import { useEffect, useState, useMemo } from "react";
import { Link } from "react-router-dom";
import { Search, Volume2, VolumeX, ZoomIn, ZoomOut, QrCode, Shield, ArrowLeft, BookOpen, AlertCircle } from "lucide-react";
import { QRCodeSVG } from "qrcode.react";

type RightsArticle = {
  id: string;
  slug: string;
  category: string;
  question: string;
  shortAnswer: string;
  practicalExample: string;
  legalSource: string;
  reviewedAt: string;
  editorialOwner: string;
};

const fallbackArticles: RightsArticle[] = [
  {
    id: "art-1",
    slug: "que-debo-revisar-en-un-contrato",
    category: "contratos",
    question: "¿Qué debo revisar en mi contrato de trabajo?",
    shortAnswer: "Tu contrato formaliza la relación laboral y debe detallar con precisión tu puesto específico, horario pactado, lugar donde desempeñarás tus labores, fecha de inicio y salario acordado.",
    practicalExample: "En Instalaciones Raquel, si fuiste contratado como armador de perfiles de aluminio o instalador en obra, tu contrato debe estipular la jornada diurna máxima de 48 horas semanales y las condiciones de seguridad en taller.",
    legalSource: "Código del Trabajo de Nicaragua (Ley 185), Artículos 19 al 24.",
    reviewedAt: "2026-10-01",
    editorialOwner: "Talento Humano Raquel"
  },
  {
    id: "art-2",
    slug: "como-entiendo-mi-comprobante-de-pago",
    category: "pagos",
    question: "¿Cómo entiendo mi comprobante de nómina?",
    shortAnswer: "Tu colilla desglosa tus ingresos devengados (salario base, horas extras autorizadas, comisiones) y tus deducciones legales obligatorias (7% de INSS laboral y retención del IR si aplica según escala tributaria).",
    practicalExample: "Por ejemplo, con un devengado de C$ 12,000, el 7% de INSS laboral equivale a C$ 840 deducidos para tu cobertura de salud y pensión. El salario neto a cobrar se calcula restando estas deducciones legales al devengado total.",
    legalSource: "Código del Trabajo (Ley 185) Art. 84; Ley de Concertación Tributaria (Ley 822) Art. 23.",
    reviewedAt: "2026-10-01",
    editorialOwner: "Contabilidad y Nómina"
  },
  {
    id: "art-3",
    slug: "como-solicito-vacaciones",
    category: "vacaciones",
    question: "¿Cómo solicito y disfruto mis vacaciones?",
    shortAnswer: "Acumulas 2.5 días hábiles de descanso por cada mes continuo de trabajo (15 días por semestre). Puedes solicitar tu período desde 'Mi espacio' con un mínimo de 15 días de anticipación para planificar la cobertura en taller.",
    practicalExample: "Si cumples un año continuo, habrás acumulado 30 días de vacaciones. Al solicitar 15 días, conservas 15 días disponibles. Las vacaciones deben gozarse efectivamente; la ley prohíbe compensarlas con dinero salvo al finalizar la relación laboral.",
    legalSource: "Código del Trabajo de Nicaragua (Ley 185), Artículos 76 al 81.",
    reviewedAt: "2026-10-01",
    editorialOwner: "Talento Humano Raquel"
  },
  {
    id: "art-4",
    slug: "que-hago-si-mis-datos-estan-incorrectos",
    category: "datos",
    question: "¿Qué hago si mis datos personales están incorrectos en el expediente?",
    shortAnswer: "Tienes derecho a la rectificación inmediata de tu número de cédula, afiliación INSS, número de cuenta bancaria o dirección domiciliaria mediante una solicitud de corrección en 'Mi espacio'.",
    practicalExample: "Si te mudaste de domicilio o renovaste tu cédula, envía la solicitud adjuntando el nuevo número. Talento humano valida la información oficial y actualiza el expediente sin sobrescribir el historial previo.",
    legalSource: "Ley de Protección de Datos Personales (Ley 787), Artículo 13.",
    reviewedAt: "2026-10-01",
    editorialOwner: "Seguridad y Cumplimiento"
  },
  {
    id: "art-5",
    slug: "que-proteccion-necesito-para-trabajar-con-vidrio",
    category: "seguridad_vidrio",
    question: "¿Qué protección obligatoria necesito para trabajar con vidrio y perfiles?",
    shortAnswer: "Para corte y trasiego de vidrio requieres guantes anticorte nivel 5 certificados, mangas protectoras para antebrazos, gafas de seguridad de impacto y calzado con puntera. Para trabajo en altura es obligatorio arnés de cuerpo entero con línea de vida.",
    practicalExample: "En Instalaciones Raquel todos los EPP son suministrados por la empresa sin costo alguno para el colaborador. Ante cualquier corte o rasgadura del guante, solicita reposición inmediata sin sanción.",
    legalSource: "Ley General de Higiene y Seguridad del Trabajo (Ley 618), Artículos 108 al 114 y 165.",
    reviewedAt: "2026-10-01",
    editorialOwner: "Seguridad Industrial"
  },
  {
    id: "art-6",
    slug: "como-comunico-una-condicion-insegura",
    category: "reportes",
    question: "¿Cómo comunico una condición o acto inseguro en el taller u obra?",
    shortAnswer: "Puedes registrar un reporte preventivo desde tu teléfono en 'Seguridad y bienestar' o avisar directamente a tu supervisor. Si detectas cables pelados, andamios inestables o ventosas defectuosas, repórtalo de inmediato.",
    practicalExample: "Aviso Importante: Un reporte dentro del sistema tiene carácter de mejora preventiva y no sustituye la llamada de emergencia inmediata ante un accidente grave (Cruz Blanca 128 o Bomberos 115).",
    legalSource: "Ley General de Higiene y Seguridad del Trabajo (Ley 618), Artículos 18 y 22.",
    reviewedAt: "2026-10-01",
    editorialOwner: "Seguridad Industrial"
  }
];

export default function PublicRightsPage() {
  const [articles, setArticles] = useState<RightsArticle[]>(fallbackArticles);
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<string>("todas");
  const [fontSizeLevel, setFontSizeLevel] = useState<number>(1); // 0 = normal, 1 = medio, 2 = grande
  const [speakingId, setSpeakingId] = useState<string | null>(null);
  const [showQr, setShowQr] = useState(false);

  useEffect(() => {
    fetch(`${getApiBaseUrl()}/api/hr/public/rights`)
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (data?.articles && Array.isArray(data.articles) && data.articles.length > 0) {
          setArticles(data.articles);
        }
      })
      .catch(() => {
        // Mantiene artículos de respaldo
      });
  }, []);

  const filteredArticles = useMemo(() => {
    return articles.filter((art) => {
      const matchesCategory = selectedCategory === "todas" || art.category === selectedCategory;
      const q = search.toLowerCase().trim();
      const matchesSearch = !q || art.question.toLowerCase().includes(q) || art.shortAnswer.toLowerCase().includes(q) || art.practicalExample.toLowerCase().includes(q) || art.legalSource.toLowerCase().includes(q);
      return matchesCategory && matchesSearch;
    });
  }, [articles, selectedCategory, search]);

  const toggleSpeak = (id: string, text: string) => {
    if (!("speechSynthesis" in window)) {
      alert("Tu navegador no soporta lectura de texto en voz alta.");
      return;
    }

    if (speakingId === id) {
      window.speechSynthesis.cancel();
      setSpeakingId(null);
      return;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = "es-NI";
    utterance.rate = 0.95;
    utterance.onend = () => setSpeakingId(null);
    utterance.onerror = () => setSpeakingId(null);
    setSpeakingId(id);
    window.speechSynthesis.speak(utterance);
  };

  const currentUrl = typeof window !== "undefined" ? window.location.href : "http://localhost:5173/derechos-y-seguridad";

  const fontClasses = ["text-sm leading-relaxed", "text-base leading-relaxed", "text-lg leading-loose"][fontSizeLevel];
  const questionFontClasses = ["text-lg font-bold", "text-xl font-bold", "text-2xl font-bold"][fontSizeLevel];

  return (
    <main className="min-h-screen bg-slate-50 px-4 py-8 text-slate-900 transition-colors dark:bg-slate-950 dark:text-slate-100 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-5xl space-y-6">
        
        {/* Encabezado Principal */}
        <header className="relative overflow-hidden rounded-2xl border border-brand-100 bg-white p-6 shadow-sm dark:border-white/10 dark:bg-slate-900 sm:p-8">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div className="flex items-center gap-2">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-500/10 text-brand-600 dark:text-brand-400">
                <Shield className="h-6 w-6" />
              </span>
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-brand-600 dark:text-brand-400">
                  Instalaciones Raquel · Aluminio y Vidrio
                </p>
                <h1 className="text-2xl font-extrabold sm:text-3xl">Conoce tus derechos y trabaja con seguridad</h1>
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setShowQr(!showQr)}
                className="flex items-center gap-1.5 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-100 dark:border-white/10 dark:bg-slate-800 dark:text-slate-200"
                title="Abrir en teléfono mediante código QR"
                aria-label="Mostrar código QR de orientación"
              >
                <QrCode className="h-4 w-4" />
                <span>Ver QR</span>
              </button>
              <Link
                to="/login"
                className="flex items-center gap-1.5 rounded-lg bg-brand-600 px-3.5 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-brand-700"
              >
                <span>Acceder a Mi espacio</span>
              </Link>
            </div>
          </div>

          <p className="mt-4 max-w-3xl text-sm leading-normal text-slate-600 dark:text-slate-300">
            Biblioteca pública de orientación para colaboradores, aprendices y la comunidad del sector vidrio y aluminio en Nicaragua.
            Esta guía orienta sobre buenas prácticas y normativa aplicable (Ley 185 y Ley 618); no constituye dictamen judicial para un caso particular ni expone expedientes internos.
          </p>

          {/* Modal / Desplegable de Código QR */}
          {showQr && (
            <div className="mt-6 rounded-xl border border-brand-200 bg-brand-50/50 p-4 dark:border-brand-900/50 dark:bg-slate-800/80">
              <div className="flex flex-col items-center gap-4 sm:flex-row sm:items-start">
                <div className="rounded-lg bg-white p-2 shadow-sm">
                  <QRCodeSVG value={currentUrl} size={130} />
                </div>
                <div className="space-y-1 text-center sm:text-left">
                  <h3 className="text-sm font-bold text-slate-800 dark:text-white">Escanea para consultar desde el móvil</h3>
                  <p className="text-xs text-slate-600 dark:text-slate-300">
                    Apunta la cámara de tu teléfono a este código. Abrirá esta misma biblioteca pública sin pedir contraseñas ni revelar información privada de expedientes.
                  </p>
                  <p className="text-[11px] text-slate-400">{currentUrl}</p>
                </div>
              </div>
            </div>
          )}
        </header>

        {/* Barra de Control de Accesibilidad y Búsqueda */}
        <section aria-label="Controles de búsqueda y lectura" className="flex flex-col gap-3 rounded-xl bg-white p-4 shadow-sm dark:bg-slate-900 sm:flex-row sm:items-center sm:justify-between">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
            <input
              type="search"
              className="h-10 w-full rounded-lg border border-slate-200 bg-slate-50 pl-9 pr-3 text-sm text-slate-900 outline-none transition focus:border-brand-500 focus:bg-white dark:border-white/10 dark:bg-slate-950 dark:text-slate-100"
              placeholder="Buscar por pregunta, norma (ej. Ley 185) o tema (corte, vacaciones, nómina)..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              aria-label="Buscar en la biblioteca de derechos"
            />
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs font-semibold text-slate-500">Tamaño de texto:</span>
            <button
              type="button"
              onClick={() => setFontSizeLevel(Math.max(0, fontSizeLevel - 1))}
              disabled={fontSizeLevel === 0}
              className="flex h-8 w-8 items-center justify-center rounded border border-slate-200 text-slate-600 hover:bg-slate-100 disabled:opacity-40 dark:border-white/10 dark:text-slate-300"
              aria-label="Reducir tamaño de letra"
            >
              <ZoomOut className="h-4 w-4" />
            </button>
            <button
              type="button"
              onClick={() => setFontSizeLevel(Math.min(2, fontSizeLevel + 1))}
              disabled={fontSizeLevel === 2}
              className="flex h-8 w-8 items-center justify-center rounded border border-slate-200 text-slate-600 hover:bg-slate-100 disabled:opacity-40 dark:border-white/10 dark:text-slate-300"
              aria-label="Aumentar tamaño de letra"
            >
              <ZoomIn className="h-4 w-4" />
            </button>
          </div>
        </section>

        {/* Categorías Rápidas */}
        <div className="flex flex-wrap gap-2 text-xs font-semibold" role="tablist" aria-label="Filtrar por categoría">
          {[
            ["todas", "Todas las consultas"],
            ["contratos", "Contratos y Jornada"],
            ["pagos", "Salarios y Deducciones"],
            ["vacaciones", "Vacaciones y Descansos"],
            ["seguridad_vidrio", "Protección y Vidrio"],
            ["reportes", "Condiciones Inseguras"],
            ["datos", "Datos Personales"]
          ].map(([catKey, catLabel]) => (
            <button
              key={catKey}
              type="button"
              onClick={() => setSelectedCategory(catKey)}
              className={`rounded-lg px-3 py-1.5 transition ${
                selectedCategory === catKey
                  ? "bg-brand-600 text-white shadow-sm"
                  : "bg-white text-slate-600 hover:bg-slate-100 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800"
              }`}
            >
              {catLabel}
            </button>
          ))}
        </div>

        {/* Lista de Fichas de Preguntas y Respuestas */}
        <section aria-label="Preguntas y Respuestas de Orientación" className="grid gap-4">
          {filteredArticles.length === 0 ? (
            <div className="rounded-xl bg-white p-8 text-center text-slate-500 dark:bg-slate-900">
              <p className="font-semibold">No se encontraron artículos con el criterio ingresado.</p>
              <p className="mt-1 text-xs">Prueba con palabras como "contrato", "vacaciones", "vidrio" o "nómina".</p>
            </div>
          ) : (
            filteredArticles.map((art) => {
              const fullTextToRead = `${art.question}. Explicación: ${art.shortAnswer}. Ejemplo práctico: ${art.practicalExample}. Base normativa: ${art.legalSource}.`;
              const isSpeakingThis = speakingId === art.id;

              return (
                <article
                  key={art.id}
                  className="rounded-xl border border-slate-200/80 bg-white p-5 shadow-sm transition hover:border-brand-200 dark:border-white/10 dark:bg-slate-900"
                >
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <h2 className={`${questionFontClasses} text-slate-900 dark:text-white`}>
                      {art.question}
                    </h2>
                    <button
                      type="button"
                      onClick={() => toggleSpeak(art.id, fullTextToRead)}
                      className={`flex items-center gap-1.5 rounded-lg border px-3 py-1 text-xs font-semibold transition ${
                        isSpeakingThis
                          ? "border-rose-400 bg-rose-50 text-rose-700 dark:bg-rose-950/40 dark:text-rose-300"
                          : "border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100 dark:border-white/10 dark:bg-slate-800 dark:text-slate-200"
                      }`}
                      aria-label={isSpeakingThis ? "Detener lectura en voz alta" : "Escuchar en voz alta"}
                    >
                      {isSpeakingThis ? <VolumeX className="h-3.5 w-3.5" /> : <Volume2 className="h-3.5 w-3.5" />}
                      <span>{isSpeakingThis ? "Detener" : "Escuchar"}</span>
                    </button>
                  </div>

                  <p className={`mt-3 ${fontClasses} text-slate-700 dark:text-slate-200`}>
                    {art.shortAnswer}
                  </p>

                  <div className="mt-3 rounded-lg border border-slate-100 bg-slate-50/80 p-3.5 text-xs text-slate-600 dark:border-white/5 dark:bg-slate-800/60 dark:text-slate-300">
                    <strong className="block font-semibold text-slate-800 dark:text-slate-100">
                      Ejemplo práctico de taller u obra:
                    </strong>
                    <span className="mt-1 block leading-relaxed">{art.practicalExample}</span>
                  </div>

                  <footer className="mt-4 flex flex-wrap items-center justify-between gap-2 border-t border-slate-100 pt-3 text-[11px] text-slate-500 dark:border-white/5 dark:text-slate-400">
                    <div>
                      <span className="font-semibold text-slate-700 dark:text-slate-300">Fuente legal: </span>
                      <span>{art.legalSource}</span>
                    </div>
                    <div className="flex items-center gap-3">
                      <span>Revisión: {art.reviewedAt}</span>
                      <span>Editorial: {art.editorialOwner}</span>
                    </div>
                  </footer>
                </article>
              );
            })
          )}
        </section>

        {/* Aviso de Emergencias y Seguridad Física */}
        <section className="rounded-xl border border-amber-300 bg-amber-50 p-4 text-amber-950 dark:border-amber-700/60 dark:bg-amber-950/30 dark:text-amber-100">
          <div className="flex items-start gap-3">
            <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
            <div className="space-y-1 text-xs leading-relaxed">
              <strong className="block text-sm font-bold">Protocolo ante emergencias inmediatas en taller u obra</strong>
              <p>
                Un formulario o solicitud digital dentro del sistema apoya la gestión preventiva y la auditoría interna; <strong>no sustituye la atención inmediata médica</strong> ante cortes profundos por vidrio, caídas de altura o descargas eléctricas.
              </p>
              <p className="font-semibold">
                Llama de inmediato a Cruz Blanca (128) o al Benemérito Cuerpo de Bomberos (115) y activa el botiquín de primeros auxilios del taller.
              </p>
            </div>
          </div>
        </section>

        {/* Pie de Página */}
        <footer className="flex flex-wrap items-center justify-between gap-4 border-t border-slate-200 pt-4 text-xs text-slate-500 dark:border-white/10 dark:text-slate-400">
          <p>© {new Date().getFullYear()} Instalaciones Raquel · Guía laboral y de seguridad industrial.</p>
          <div className="flex items-center gap-4">
            <Link to="/login" className="font-semibold text-brand-600 underline hover:text-brand-700 dark:text-brand-400">
              Ingresar a la plataforma
            </Link>
          </div>
        </footer>

      </div>
    </main>
  );
}

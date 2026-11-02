import {useEffect, useId, useMemo, useRef, useState} from 'react';
import {useLocation, useNavigate} from 'react-router-dom';
import {Search} from 'lucide-react';
import {useAuth} from '../auth/AuthContext';
import {useErp} from '../store/erpStore';
import {modules} from '../data/erpData';
import {navigationSearch} from '../lib/navigationSearch';

export function QuickNavigationSearch() {
 const {user, canAccess} = useAuth();
 const {db} = useErp();
 const navigate = useNavigate();
 const {pathname} = useLocation();
 const root = useRef<HTMLDivElement>(null);
 const resultsId = useId();
 const [query, setQuery] = useState('');
 const [open, setOpen] = useState(false);
 const [index, setIndex] = useState(0);
 const allowed = useMemo(() => modules.filter(module => canAccess(module.id)), [canAccess]);
 const results = useMemo(() => navigationSearch(query, allowed, db), [query, allowed, db]);
 const activeIndex = Math.min(index, Math.max(0, results.length - 1));
 const expanded = open && query.trim().length >= 2;
 useEffect(() => {
  if (expanded) document.getElementById(`${resultsId}-${activeIndex}`)?.scrollIntoView({block: 'nearest'});
 }, [expanded, activeIndex, query, resultsId]);
 useEffect(() => {setQuery(''); setOpen(false); setIndex(0);}, [user?.id, pathname]);
 useEffect(() => {
  const dismiss = (event: MouseEvent) => {if (!root.current?.contains(event.target as Node)) setOpen(false);};
  document.addEventListener('mousedown', dismiss);
  return () => document.removeEventListener('mousedown', dismiss);
 }, []);
 const go = (url: string) => {setOpen(false); setQuery(''); navigate(url);};
 return <div ref={root} onBlur={event => {if (!event.currentTarget.contains(event.relatedTarget as Node | null)) setOpen(false);}}
  className="relative hidden min-w-0 max-w-md flex-1 md:block">
  <Search aria-hidden="true" className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16}/>
  <input role="combobox" aria-label="Buscar módulos y registros" aria-autocomplete="list" aria-expanded={expanded}
   aria-controls={expanded ? resultsId : undefined}
   aria-activedescendant={expanded && results.length ? `${resultsId}-${activeIndex}` : undefined}
   className="h-9 w-full rounded-xl border border-slate-200 bg-slate-50 pl-9 pr-4 text-xs font-medium outline-none focus:border-brand-500 dark:border-white/10 dark:bg-slate-950/50"
   placeholder="Buscar módulos, clientes, facturas o materiales…" autoComplete="off" value={query}
   onChange={event => {setQuery(event.target.value); setOpen(true); setIndex(0);}}
   onFocus={() => setOpen(true)}
   onKeyDown={event => {
    if (event.key === 'Escape') {setOpen(false); return;}
    if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
     event.preventDefault(); setOpen(true);
     if (results.length) setIndex(current => (current + (event.key === 'ArrowDown' ? 1 : -1) + results.length) % results.length);
    }
    if (event.key === 'Enter' && expanded && results[activeIndex]) {event.preventDefault(); go(results[activeIndex].url);}
   }}/>
  {expanded && <div className="absolute left-0 top-full z-50 mt-2 w-full min-w-72 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xl dark:border-white/10 dark:bg-slate-900">
   <div id={resultsId} role="listbox" aria-label="Resultados de búsqueda" className="max-h-80 overflow-y-auto">
    {results.map((result, i) => <button key={result.url} id={`${resultsId}-${i}`} role="option" aria-selected={i === activeIndex}
     type="button" tabIndex={-1} onMouseDown={event => event.preventDefault()} onClick={() => go(result.url)}
     className={`block w-full px-4 py-2 text-left text-xs hover:bg-brand-50 dark:hover:bg-white/10 ${i === activeIndex ? 'bg-brand-50 dark:bg-white/10' : ''}`}>
     <strong className="block">{result.label}</strong><span className="text-slate-500 dark:text-slate-400">{result.detail}</span>
    </button>)}
   </div>
   {!results.length && <p role="status" className="p-4 text-xs text-slate-500">No hay coincidencias disponibles. Puedes abrir el módulo para consultar su listado.</p>}
  </div>}
 </div>;
}

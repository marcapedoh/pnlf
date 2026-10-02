import { formatDate, formatNumber } from '@angular/common';

/** Locale enregistrée au démarrage (voir core/i18n/register-locale-fr.ts). */
export const APP_LOCALE = 'fr';

interface LibelleUnite {
  singulier: string;
  pluriel: string;
}

const UNITES: Record<string, LibelleUnite> = {
  KG: { singulier: 'kg', pluriel: 'kg' },
  G: { singulier: 'g', pluriel: 'g' },
  TONNE: { singulier: 'tonne', pluriel: 'tonnes' },
  LITRE: { singulier: 'L', pluriel: 'L' },
  L: { singulier: 'L', pluriel: 'L' },
  SAC: { singulier: 'sac', pluriel: 'sacs' },
  UNITE: { singulier: 'unité', pluriel: 'unités' },
  PIECE: { singulier: 'pièce', pluriel: 'pièces' },
  BOTTE: { singulier: 'botte', pluriel: 'bottes' },
  PANIER: { singulier: 'panier', pluriel: 'paniers' },
};

/** Options d'unités proposées dans les formulaires (valeurs envoyées à l'API). */
export const UNITE_OPTIONS = [
  { value: 'KG', label: 'Kilogramme (kg)' },
  { value: 'TONNE', label: 'Tonne' },
  { value: 'LITRE', label: 'Litre (L)' },
  { value: 'SAC', label: 'Sac' },
  { value: 'UNITE', label: 'Unité' },
  { value: 'BOTTE', label: 'Botte' },
];

const DEVISES: Record<string, string> = { XAF: 'FCFA', XOF: 'FCFA', EUR: '€' };

function toNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null;
  const n = typeof value === 'number' ? value : Number(String(value).replace(',', '.'));
  return Number.isFinite(n) ? n : null;
}

/** Libellé lisible d'une unité (« BOTTE » -> « bottes » pour une quantité > 1). */
export function libelleUnite(unite: string | null | undefined, quantite?: number | string | null): string {
  if (!unite) return '';
  const def = UNITES[unite.toUpperCase()];
  if (!def) return unite.toLowerCase();
  const q = toNumber(quantite);
  return q !== null && Math.abs(q) >= 2 ? def.pluriel : def.singulier;
}

/** « 150.000 » + « BOTTE » -> « 150 bottes » ; « 12.500 » + « KG » -> « 12,5 kg ». */
export function formatQuantite(quantite: number | string | null | undefined, unite?: string | null): string {
  const q = toNumber(quantite);
  if (q === null) return '';
  const nombre = formatNumber(q, APP_LOCALE, '1.0-3');
  const u = libelleUnite(unite, q);
  return u ? `${nombre} ${u}` : nombre;
}

/** Libellé affiché d'une devise (XAF -> FCFA). La valeur envoyée à l'API reste le code ISO. */
export function libelleDevise(devise: string | null | undefined): string {
  if (!devise) return 'FCFA';
  return DEVISES[devise.toUpperCase()] ?? devise;
}

/** « 500.00 » -> « 500 FCFA ». */
export function formatMontant(montant: number | string | null | undefined, devise?: string | null): string {
  const m = toNumber(montant);
  if (m === null) return '';
  return `${formatNumber(m, APP_LOCALE, '1.0-0')} ${libelleDevise(devise)}`;
}

export type DateFormat = 'date' | 'datetime' | 'long' | 'time' | 'month';

const DATE_PATTERNS: Record<DateFormat, string> = {
  date: 'dd/MM/yyyy',
  datetime: "dd/MM/yyyy 'à' HH:mm",
  long: 'd MMMM yyyy',
  time: 'HH:mm',
  month: 'MMM yyyy',
};

/** Dates ISO (« 2026-09-27 » ou horodatage) au format français, heure locale. */
export function formatDateFr(value: string | Date | null | undefined, format: DateFormat = 'date'): string {
  if (!value) return '';
  try {
    return formatDate(value, DATE_PATTERNS[format], APP_LOCALE);
  } catch {
    return String(value);
  }
}

/** « +241077000206 » -> « +241 077 00 02 06 » ; laisse intacte une valeur non reconnue. */
export function formatTelephone(value: string | null | undefined): string {
  if (!value) return '';
  const compact = value.replace(/[\s.\-()]/g, '');
  if (!/^\+?\d{6,20}$/.test(compact)) return value;
  let prefixe = '';
  let reste = compact;
  if (compact.startsWith('+241')) {
    prefixe = '+241 ';
    reste = compact.slice(4);
  } else if (compact.startsWith('+')) {
    prefixe = `${compact.slice(0, 3)} `;
    reste = compact.slice(3);
  }
  const groupes: string[] = [];
  let i = 0;
  if (reste.length % 2 === 1) {
    groupes.push(reste.slice(0, 3));
    i = 3;
  }
  for (; i < reste.length; i += 2) groupes.push(reste.slice(i, i + 2));
  return prefixe + groupes.join(' ');
}

/** Date du jour au format ISO (yyyy-MM-dd) dans le fuseau du navigateur (pas en UTC). */
export function todayIso(): string {
  return formatDate(new Date(), 'yyyy-MM-dd', APP_LOCALE);
}

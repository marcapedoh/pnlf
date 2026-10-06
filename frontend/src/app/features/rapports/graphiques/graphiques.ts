import { ApexOptions } from 'ng-apexcharts';

import { Granularite } from '../../../core/models/rapports.model';

export const PALETTE = ['#146b3f', '#e4b91a', '#3260a3', '#6bc48a', '#a4650a', '#ab2626', '#7a5195', '#5b6670'];
export const COULEURS_STATUT_LOT = { brouillon: '#a4650a', valide: '#146b3f', commercialise: '#e4b91a' };

const POLICE = 'Public Sans, sans-serif';
const MOIS = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

const nombreFr = (v: number) => new Intl.NumberFormat('fr-FR').format(Math.round(v));

export function libellePeriode(iso: string, granularite: Granularite): string {
  const [annee, mois, jour] = iso.split('-').map(Number);
  if (granularite === 'mois') return `${MOIS[mois - 1]} ${annee}`;
  const jj = String(jour).padStart(2, '0');
  const mm = String(mois).padStart(2, '0');
  return granularite === 'semaine' ? `sem. du ${jj}/${mm}` : `${jj}/${mm}`;
}

function base(type: 'bar' | 'area' | 'line' | 'donut', hauteur: number, empile = false): ApexOptions['chart'] {
  return {
    type,
    height: hauteur,
    stacked: empile,
    fontFamily: POLICE,
    toolbar: { show: false },
    zoom: { enabled: false },
    animations: { enabled: false },
    defaultLocale: 'fr',
    locales: [
      {
        name: 'fr',
        options: {
          months: ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'],
          shortMonths: MOIS,
          days: ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'],
          shortDays: ['dim.', 'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.'],
          toolbar: { download: 'Télécharger', selection: 'Sélection', selectionZoom: 'Zoom', zoomIn: 'Zoomer', zoomOut: 'Dézoomer', pan: 'Déplacer', reset: 'Réinitialiser' },
        },
      },
    ],
  };
}

const COMMUNS: Partial<ApexOptions> = {
  dataLabels: { enabled: false },
  grid: { borderColor: '#edf0f2', strokeDashArray: 3 },
  tooltip: { y: { formatter: nombreFr } },
  noData: { text: 'Aucune donnée sur la période choisie.' },
  markers: { size: 0 },
  fill: { opacity: 1 },
  stroke: { width: 0 },
};

/** Évolution dans le temps (courbes ou barres empilées), une série par indicateur. */
export function evolution(
  categories: string[],
  series: { name: string; data: number[] }[],
  options: { type?: 'area' | 'bar'; empile?: boolean; couleurs?: string[]; hauteur?: number; titreY?: string } = {},
): ApexOptions {
  const type = options.type ?? 'area';
  return {
    ...COMMUNS,
    chart: base(type, options.hauteur ?? 300, options.empile),
    series,
    colors: options.couleurs ?? PALETTE,
    xaxis: {
      categories,
      tickAmount: Math.min(categories.length, 12),
      labels: { rotate: -35, hideOverlappingLabels: true, style: { fontSize: '11px' } },
    },
    yaxis: {
      min: 0,
      forceNiceScale: true,
      labels: { formatter: nombreFr },
      // ApexCharts lit yaxis.title.text sans garde : une clé title à undefined bloque tout le rendu.
      ...(options.titreY ? { title: { text: options.titreY, style: { fontSize: '12px', fontWeight: 600, color: '#5b6670' } } } : {}),
    },
    stroke: type === 'area' ? { curve: 'smooth', width: 2 } : { width: 0 },
    fill: type === 'area' ? { type: 'gradient', gradient: { opacityFrom: 0.35, opacityTo: 0.05 } } : { opacity: 1 },
    plotOptions: { bar: { borderRadius: 3, columnWidth: '60%' } },
    legend: { position: 'top', horizontalAlign: 'left', fontSize: '12px' },
  };
}

/** Classement horizontal (ou vertical) d'une seule série. */
export function classement(
  libelles: string[],
  valeurs: number[],
  nom: string,
  options: { horizontal?: boolean; couleurs?: string[]; hauteur?: number; distribue?: boolean } = {},
): ApexOptions {
  const horizontal = options.horizontal ?? true;
  const hauteur = options.hauteur ?? Math.max(220, Math.min(libelles.length, 12) * 34 + 60);
  return {
    ...COMMUNS,
    chart: base('bar', hauteur),
    series: [{ name: nom, data: valeurs }],
    colors: options.couleurs ?? PALETTE,
    xaxis: { categories: libelles, labels: { formatter: horizontal ? (v: string) => nombreFr(Number(v)) : undefined, style: { fontSize: '11px' } } },
    yaxis: { labels: { maxWidth: 220, style: { fontSize: '12px' } } },
    plotOptions: { bar: { horizontal, borderRadius: 4, barHeight: '65%', columnWidth: '55%', distributed: options.distribue ?? false } },
    dataLabels: { enabled: true, formatter: (v: number) => nombreFr(v), style: { fontSize: '11px', colors: ['#fff'] } },
    legend: { show: false },
  };
}

/** Répartition en anneau, avec total au centre. */
export function anneau(libelles: string[], valeurs: number[], options: { couleurs?: string[]; hauteur?: number; total?: string } = {}): ApexOptions {
  return {
    ...COMMUNS,
    chart: base('donut', options.hauteur ?? 280),
    series: valeurs,
    labels: libelles,
    colors: options.couleurs ?? PALETTE,
    stroke: { width: 2, colors: ['#fff'] },
    legend: { position: 'bottom', fontSize: '12px' },
    dataLabels: { enabled: true, formatter: (v: number) => `${Math.round(v)} %` },
    plotOptions: {
      pie: {
        donut: {
          size: '62%',
          labels: {
            show: true,
            total: { show: true, label: options.total ?? 'Total', formatter: (w) => nombreFr(w.globals.seriesTotals.reduce((a: number, b: number) => a + b, 0)) },
          },
        },
      },
    },
  };
}

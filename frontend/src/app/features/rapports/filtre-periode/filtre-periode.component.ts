import { ChangeDetectionStrategy, Component, DestroyRef, OnInit, inject, input, output, signal } from '@angular/core';

import { FiltresRapport, Granularite } from '../../../core/models/rapports.model';
import { IconComponent } from '../../../design-system/icon/icon.component';

const DELAI_SAISIE_MS = 400;

function isoLocal(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function ilYA(jours: number): string {
  const d = new Date();
  d.setDate(d.getDate() - jours + 1);
  return isoLocal(d);
}

export const PRESETS_PERIODE = [
  { jours: 7, libelle: '7 jours' },
  { jours: 30, libelle: '30 jours' },
  { jours: 90, libelle: '3 mois' },
  { jours: 365, libelle: '12 mois' },
] as const;

export function filtresParDefaut(): FiltresRapport {
  return { date_debut: ilYA(30), date_fin: isoLocal(new Date()), granularite: '', q: '' };
}

/** Période, regroupement et recherche communs à tous les onglets des rapports. */
@Component({
  selector: 'app-filtre-periode',
  imports: [IconComponent],
  templateUrl: './filtre-periode.component.html',
  styleUrl: './filtre-periode.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FiltrePeriodeComponent implements OnInit {
  readonly initial = input<FiltresRapport>(filtresParDefaut());
  readonly placeholderRecherche = input('Rechercher…');
  readonly changement = output<FiltresRapport>();

  readonly presets = PRESETS_PERIODE;
  readonly aujourdhui = isoLocal(new Date());
  readonly debut = signal('');
  readonly fin = signal('');
  readonly granularite = signal<Granularite | ''>('');
  readonly q = signal('');
  readonly erreur = signal('');

  private minuterie: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.annulerMinuterie());
  }

  ngOnInit(): void {
    const f = this.initial();
    this.debut.set(f.date_debut ?? '');
    this.fin.set(f.date_fin ?? '');
    this.granularite.set(f.granularite ?? '');
    this.q.set(f.q ?? '');
  }

  presetActif(jours: number): boolean {
    return this.fin() === this.aujourdhui && this.debut() === ilYA(jours);
  }

  choisirPreset(jours: number): void {
    this.debut.set(ilYA(jours));
    this.fin.set(this.aujourdhui);
    this.emettre();
  }

  changerDate(champ: 'debut' | 'fin', event: Event): void {
    this[champ].set((event.target as HTMLInputElement).value);
    this.emettre();
  }

  changerGranularite(event: Event): void {
    this.granularite.set((event.target as HTMLSelectElement).value as Granularite | '');
    this.emettre();
  }

  saisirRecherche(event: Event): void {
    this.q.set((event.target as HTMLInputElement).value);
    this.annulerMinuterie();
    this.minuterie = setTimeout(() => this.emettre(), DELAI_SAISIE_MS);
  }

  private emettre(): void {
    this.annulerMinuterie();
    const debut = this.debut();
    const fin = this.fin();
    if (debut && fin && debut > fin) {
      this.erreur.set('La date de début doit précéder la date de fin.');
      return;
    }
    this.erreur.set('');
    this.changement.emit({ date_debut: debut, date_fin: fin, granularite: this.granularite(), q: this.q().trim() });
  }

  private annulerMinuterie(): void {
    if (this.minuterie) {
      clearTimeout(this.minuterie);
      this.minuterie = null;
    }
  }
}

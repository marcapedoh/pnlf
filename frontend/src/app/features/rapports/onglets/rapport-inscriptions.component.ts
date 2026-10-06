import { ChangeDetectionStrategy, Component, DestroyRef, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Subscription } from 'rxjs';

import { toApiError } from '../../../core/http/api-error.util';
import { DemandeInscription, FiltresRapport, StatistiquesInscriptions } from '../../../core/models/rapports.model';
import { PdfPreviewService } from '../../../core/services/pdf-preview.service';
import { RapportsService } from '../../../core/services/rapports.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { BadgeTone, StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { KpiCardComponent } from '../../../design-system/kpi-card/kpi-card.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { PnlfDatePipe } from '../../../shared/pipes/format.pipes';
import { ExportRapportComponent } from '../export-rapport/export-rapport.component';
import { GraphiqueComponent } from '../graphiques/graphique.component';
import { anneau, classement, evolution, libellePeriode } from '../graphiques/graphiques';

export const TYPES_DEMANDE = [
  { value: 'PRODUCTEUR', label: 'Producteur' },
  { value: 'COLLECTEUR', label: 'Collecteur' },
  { value: 'COOPERATIVE', label: 'Coopérative' },
  { value: 'ACHETEUR', label: 'Acheteur' },
];

export const STATUTS_DEMANDE = [
  { value: 'EN_ATTENTE', label: 'En attente' },
  { value: 'VALIDEE', label: 'Validée' },
  { value: 'REJETEE', label: 'Rejetée' },
];

export function formaterDelai(heures: number | null | undefined): string {
  if (heures === null || heures === undefined) return 'Non applicable';
  if (heures < 1) return `${Math.max(1, Math.round(heures * 60))} min`;
  if (heures < 48) return `${heures.toLocaleString('fr-FR', { maximumFractionDigits: 1 })} h`;
  return `${(heures / 24).toLocaleString('fr-FR', { maximumFractionDigits: 1 })} jours`;
}

/** Onglet « Inscriptions » : demandes reçues, en attente, validées et rejetées, délai de traitement. */
@Component({
  selector: 'app-rapport-inscriptions',
  imports: [
    RouterLink,
    AlertBannerComponent,
    ButtonComponent,
    CardComponent,
    EmptyStateComponent,
    IconComponent,
    KpiCardComponent,
    PaginationComponent,
    SkeletonComponent,
    StatusBadgeComponent,
    PnlfDatePipe,
    ExportRapportComponent,
    GraphiqueComponent,
  ],
  templateUrl: './rapport-inscriptions.component.html',
  styleUrl: './onglets.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RapportInscriptionsComponent {
  private readonly rapports = inject(RapportsService);
  private readonly pdf = inject(PdfPreviewService);

  readonly filtres = input.required<FiltresRapport>();

  readonly donnees = signal<StatistiquesInscriptions | null>(null);
  readonly chargement = signal(true);
  readonly erreur = signal('');
  readonly typeDemande = signal('');
  readonly statut = signal('');
  readonly recherche = signal('');
  readonly page = signal(1);
  readonly pageSize = 20;

  readonly types = TYPES_DEMANDE;
  readonly statuts = STATUTS_DEMANDE;
  readonly delai = formaterDelai;

  private requete?: Subscription;
  private minuterieRecherche: ReturnType<typeof setTimeout> | null = null;
  private readonly rechercheAppliquee = signal('');

  /** La recherche de la liste prime sur la recherche générale de la barre de période. */
  readonly filtresExport = computed(() => ({
    ...this.filtres(),
    q: this.rechercheAppliquee() || this.filtres().q || '',
    type_demande: this.typeDemande(),
    statut: this.statut(),
  }));

  readonly graphEvolution = computed(() => {
    const d = this.donnees();
    if (!d) return null;
    const g = d.periode.granularite;
    return evolution(
      d.serie.map((p) => libellePeriode(p.periode, g)),
      [
        { name: 'Validées', data: d.serie.map((p) => p.validees) },
        { name: 'En attente', data: d.serie.map((p) => p.en_attente) },
        { name: 'Rejetées', data: d.serie.map((p) => p.rejetees) },
      ],
      { type: 'bar', empile: true, couleurs: ['#146b3f', '#e4b91a', '#ab2626'] },
    );
  });

  readonly graphStatuts = computed(() => {
    const t = this.donnees()?.totaux;
    return t
      ? anneau(['Validées', 'En attente', 'Rejetées'], [t.validees, t.en_attente, t.rejetees], {
          couleurs: ['#146b3f', '#e4b91a', '#ab2626'],
          total: 'Demandes',
        })
      : null;
  });

  readonly graphTypes = computed(() => {
    const d = this.donnees();
    return d ? classement(d.par_type.map((t) => t.libelle), d.par_type.map((t) => t.recues), 'Demandes reçues', { couleurs: ['#3260a3'] }) : null;
  });

  constructor() {
    effect(() => {
      this.filtres();
      untracked(() => {
        this.page.set(1);
        this.charger();
      });
    });
    inject(DestroyRef).onDestroy(() => {
      this.requete?.unsubscribe();
      if (this.minuterieRecherche) clearTimeout(this.minuterieRecherche);
    });
  }

  imprimerListe(): void {
    this.appliquerRecherche();
    const filtres = this.filtresExport();
    this.pdf.open('Liste des demandes d’inscription (PDF)', 'pfnl-liste-demandes.pdf', () => this.rapports.pdf('inscriptions', filtres));
  }

  rechercher(event: Event): void {
    this.recherche.set((event.target as HTMLInputElement).value);
    if (this.minuterieRecherche) clearTimeout(this.minuterieRecherche);
    this.minuterieRecherche = setTimeout(() => this.appliquerRecherche(), 350);
  }

  effacerRecherche(): void {
    this.recherche.set('');
    this.appliquerRecherche();
  }

  private appliquerRecherche(): void {
    if (this.minuterieRecherche) clearTimeout(this.minuterieRecherche);
    this.minuterieRecherche = null;
    const valeur = this.recherche().trim().slice(0, 100);
    if (valeur === this.rechercheAppliquee()) return;
    this.rechercheAppliquee.set(valeur);
    this.page.set(1);
    this.charger();
  }

  charger(): void {
    this.requete?.unsubscribe();
    this.chargement.set(true);
    this.erreur.set('');
    this.requete = this.rapports
      .inscriptions({ ...this.filtresExport(), page: this.page(), page_size: this.pageSize })
      .subscribe({
        next: (d) => {
          this.donnees.set(d);
          this.chargement.set(false);
        },
        error: (err) => {
          this.chargement.set(false);
          this.erreur.set(toApiError(err).message);
        },
      });
  }

  filtrer(champ: 'typeDemande' | 'statut', event: Event): void {
    this[champ].set((event.target as HTMLSelectElement).value);
    this.page.set(1);
    this.charger();
  }

  allerPage(page: number): void {
    this.page.set(page);
    this.charger();
  }

  tone(statut: string): BadgeTone {
    return statut === 'VALIDEE' ? 'success' : statut === 'REJETEE' ? 'danger' : 'warning';
  }

  lien(d: DemandeInscription): string[] | null {
    if (!d.enregistrement_id) return null;
    if (d.table_cible === 'producteurs') return ['/app/producteurs', d.enregistrement_id];
    if (d.table_cible === 'cooperatives') return ['/app/cooperatives', d.enregistrement_id];
    if (d.table_cible === 'utilisateurs') return ['/app/utilisateurs', d.enregistrement_id];
    return null;
  }

  tauxValidation(d: StatistiquesInscriptions): string {
    const traitees = d.totaux.validees + d.totaux.rejetees;
    return traitees ? `${Math.round((d.totaux.validees / traitees) * 100)} % des demandes traitées` : 'Aucune demande traitée';
  }
}

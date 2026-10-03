import { ChangeDetectionStrategy, Component, DestroyRef, computed, effect, inject, input, signal, untracked } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Subscription } from 'rxjs';

import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import { FiltresRapport, StatistiquesFiliere } from '../../../core/models/rapports.model';
import { RapportsService } from '../../../core/services/rapports.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { KpiCardComponent } from '../../../design-system/kpi-card/kpi-card.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { PnlfQuantitePipe } from '../../../shared/pipes/format.pipes';
import { ExportRapportComponent } from '../export-rapport/export-rapport.component';
import { GraphiqueComponent } from '../graphiques/graphique.component';
import { COULEURS_STATUT_LOT, anneau, classement, evolution, libellePeriode } from '../graphiques/graphiques';

const STATUTS = ['BROUILLON', 'VALIDE', 'COMMERCIALISE'] as const;

/** Onglet « Filière et lots » : lots selon les 3 statuts du cycle, par produit, province et période. */
@Component({
  selector: 'app-rapport-filiere',
  imports: [
    RouterLink,
    AlertBannerComponent,
    ButtonComponent,
    CardComponent,
    KpiCardComponent,
    SkeletonComponent,
    PnlfQuantitePipe,
    ExportRapportComponent,
    GraphiqueComponent,
  ],
  templateUrl: './rapport-filiere.component.html',
  styleUrl: './onglets.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RapportFiliereComponent {
  private readonly rapports = inject(RapportsService);
  private readonly reference = inject(ReferenceService);

  readonly filtres = input.required<FiltresRapport>();
  readonly peutExporter = input(false);

  readonly donnees = signal<StatistiquesFiliere | null>(null);
  readonly chargement = signal(true);
  readonly erreur = signal('');
  readonly province = signal('');
  readonly produit = signal('');
  readonly statut = signal('');
  readonly provinces = signal<{ id: string; nom: string }[]>([]);
  readonly produits = signal<{ id: string; nom: string }[]>([]);

  private requete?: Subscription;

  readonly filtresFiliere = computed(() => ({ ...this.filtres(), province: this.province(), produit: this.produit() }));
  readonly filtresLots = computed(() => ({ ...this.filtresFiliere(), statut: this.statut() }));

  readonly graphStatuts = computed(() => {
    const d = this.donnees();
    return d
      ? anneau(d.par_statut.map((s) => s.libelle), d.par_statut.map((s) => s.nombre), {
          couleurs: [COULEURS_STATUT_LOT.brouillon, COULEURS_STATUT_LOT.valide, COULEURS_STATUT_LOT.commercialise],
          total: 'Lots',
        })
      : null;
  });

  readonly graphEvolution = computed(() => {
    const d = this.donnees();
    if (!d) return null;
    const g = d.periode.granularite;
    return evolution(
      d.serie.map((p) => libellePeriode(p.periode, g)),
      [
        { name: 'Brouillon', data: d.serie.map((p) => p.brouillon) },
        { name: 'Validé', data: d.serie.map((p) => p.valide) },
        { name: 'Commercialisé', data: d.serie.map((p) => p.commercialise) },
      ],
      {
        type: 'bar',
        empile: true,
        couleurs: [COULEURS_STATUT_LOT.brouillon, COULEURS_STATUT_LOT.valide, COULEURS_STATUT_LOT.commercialise],
        titreY: 'Lots collectés',
      },
    );
  });

  readonly graphProduits = computed(() => {
    const d = this.donnees();
    if (!d) return null;
    const top = d.par_produit.slice(0, 10);
    return classement(top.map((p) => p.produit), top.map((p) => p.lots), 'Lots', { couleurs: ['#146b3f'] });
  });

  readonly graphProvinces = computed(() => {
    const d = this.donnees();
    if (!d) return null;
    return classement(d.par_province.map((p) => p.province), d.par_province.map((p) => p.lots), 'Lots', { couleurs: ['#3260a3'] });
  });

  readonly statutsLot = STATUTS;

  constructor() {
    this.reference.provinces().subscribe({ next: (r) => this.provinces.set(unwrapList(r).map((p) => ({ id: p.id, nom: p.nom }))) });
    this.reference.produits().subscribe({ next: (r) => this.produits.set(unwrapList(r).map((p) => ({ id: p.id, nom: p.nom }))) });
    effect(() => {
      this.filtres();
      untracked(() => this.charger());
    });
    inject(DestroyRef).onDestroy(() => this.requete?.unsubscribe());
  }

  charger(): void {
    this.requete?.unsubscribe();
    this.chargement.set(true);
    this.erreur.set('');
    this.requete = this.rapports.filiere(this.filtresFiliere()).subscribe({
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

  filtrer(champ: 'province' | 'produit', event: Event): void {
    this[champ].set((event.target as HTMLSelectElement).value);
    this.charger();
  }

  choisirStatut(event: Event): void {
    this.statut.set((event.target as HTMLSelectElement).value);
  }

  libelleStatut(statut: string): string {
    return { BROUILLON: 'Brouillon', VALIDE: 'Validé', COMMERCIALISE: 'Commercialisé' }[statut] ?? statut;
  }

  part(valeur: number, total: number): string {
    return total ? `${Math.round((valeur / total) * 100)} % des lots` : 'Aucun lot';
  }
}

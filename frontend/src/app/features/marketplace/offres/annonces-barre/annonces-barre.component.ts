import { ChangeDetectionStrategy, Component, DestroyRef, OnInit, inject, input, model, output, signal } from '@angular/core';

import {
  AnnoncesFiltres,
  TRIS_ANNONCES,
  TriAnnonces,
  VUES_ANNONCES,
  VueAnnonces,
  memoriserVueAnnonces,
} from '../../../../core/models/annonce.model';
import { STATUT_OFFRE_DEMANDE_LABELS } from '../../../../core/models/notification.model';
import { IconComponent } from '../../../../design-system/icon/icon.component';

export interface OptionReference {
  id: string;
  nom: string;
}

const DELAI_SAISIE_MS = 400;

/** Recherche, filtres, tri et choix d'affichage des annonces. Émet les filtres sans la pagination. */
@Component({
  selector: 'app-annonces-barre',
  imports: [IconComponent],
  templateUrl: './annonces-barre.component.html',
  styleUrl: './annonces-barre.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AnnoncesBarreComponent implements OnInit {
  readonly initial = input<AnnoncesFiltres>({});
  readonly produits = input<OptionReference[]>([]);
  readonly provinces = input<OptionReference[]>([]);
  readonly afficherStatut = input(false);
  readonly afficherMine = input(false);
  readonly total = input<number | null>(null);
  readonly vue = model<VueAnnonces>('grille');
  readonly changement = output<AnnoncesFiltres>();

  readonly vues = VUES_ANNONCES;
  readonly tris = TRIS_ANNONCES;
  readonly statuts = Object.entries(STATUT_OFFRE_DEMANDE_LABELS).map(([value, label]) => ({ value, label }));

  readonly q = signal('');
  readonly type = signal('');
  readonly produit = signal('');
  readonly province = signal('');
  readonly prixMin = signal('');
  readonly prixMax = signal('');
  readonly statut = signal('');
  readonly mine = signal(false);
  readonly tri = signal<TriAnnonces>('recent');
  readonly filtresAvances = signal(false);
  readonly erreurPrix = signal('');

  private minuterie: ReturnType<typeof setTimeout> | null = null;

  constructor() {
    inject(DestroyRef).onDestroy(() => this.annulerMinuterie());
  }

  ngOnInit(): void {
    const f = this.initial();
    this.q.set(f.q ?? '');
    this.type.set(f.type_annonce ?? '');
    this.produit.set(f.produit ?? '');
    this.province.set(f.province ?? '');
    this.statut.set(f.statut ?? '');
    this.mine.set(f.mine === '1');
    if (f.tri) this.tri.set(f.tri);
    if (this.nbFiltresActifs) this.filtresAvances.set(true);
  }

  get nbFiltresActifs(): number {
    return [this.produit(), this.province(), this.prixMin(), this.prixMax(), this.statut()].filter(Boolean).length;
  }

  get filtresModifies(): boolean {
    return !!(this.q() || this.type() || this.nbFiltresActifs || this.mine() || this.tri() !== 'recent');
  }

  choisirVue(vue: VueAnnonces): void {
    this.vue.set(vue);
    memoriserVueAnnonces(vue);
  }

  saisir(champ: 'q' | 'prixMin' | 'prixMax', event: Event): void {
    this[champ].set((event.target as HTMLInputElement).value);
    this.annulerMinuterie();
    this.minuterie = setTimeout(() => this.emettre(), DELAI_SAISIE_MS);
  }

  choisir(champ: 'type' | 'produit' | 'province' | 'statut', valeur: string): void {
    this[champ].set(valeur);
    this.emettre();
  }

  choisirTri(event: Event): void {
    this.tri.set((event.target as HTMLSelectElement).value as TriAnnonces);
    this.emettre();
  }

  basculerMine(event: Event): void {
    this.mine.set((event.target as HTMLInputElement).checked);
    this.emettre();
  }

  valeurSelect(event: Event): string {
    return (event.target as HTMLSelectElement).value;
  }

  reinitialiser(): void {
    this.q.set('');
    this.type.set('');
    this.produit.set('');
    this.province.set('');
    this.prixMin.set('');
    this.prixMax.set('');
    this.statut.set('');
    this.mine.set(false);
    this.tri.set('recent');
    this.emettre();
  }

  private emettre(): void {
    this.annulerMinuterie();
    const min = this.prixMin().trim();
    const max = this.prixMax().trim();
    if ((min && Number(min) < 0) || (max && Number(max) < 0)) {
      this.erreurPrix.set('Les prix doivent être positifs.');
      return;
    }
    if (min && max && Number(max) < Number(min)) {
      this.erreurPrix.set('Le prix maximum doit être supérieur ou égal au prix minimum.');
      return;
    }
    this.erreurPrix.set('');
    this.changement.emit({
      q: this.q().trim(),
      type_annonce: this.type(),
      produit: this.produit(),
      province: this.province(),
      prix_min: min,
      prix_max: max,
      statut: this.afficherStatut() ? this.statut() : '',
      mine: this.mine() ? '1' : '',
      tri: this.tri(),
    });
  }

  private annulerMinuterie(): void {
    if (this.minuterie) {
      clearTimeout(this.minuterie);
      this.minuterie = null;
    }
  }
}

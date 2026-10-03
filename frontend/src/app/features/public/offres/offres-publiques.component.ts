import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Subscription } from 'rxjs';

import { toApiError } from '../../../core/http/api-error.util';
import { AnnoncesFiltres, vueAnnoncesMemorisee } from '../../../core/models/annonce.model';
import { PublicOffreDemande } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { AnnoncesAffichageComponent } from '../../marketplace/offres/annonces-affichage/annonces-affichage.component';
import { AnnoncesBarreComponent, OptionReference } from '../../marketplace/offres/annonces-barre/annonces-barre.component';

@Component({
  selector: 'app-offres-publiques',
  imports: [EmptyStateComponent, SkeletonComponent, PaginationComponent, AnnoncesAffichageComponent, AnnoncesBarreComponent],
  templateUrl: './offres-publiques.component.html',
  styleUrl: './offres-publiques.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffresPubliquesComponent {
  private readonly publicService = inject(PublicService);

  private requete?: Subscription;

  readonly items = signal<PublicOffreDemande[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly provinces = signal<OptionReference[]>([]);
  readonly produits = signal<OptionReference[]>([]);
  readonly vue = signal(vueAnnoncesMemorisee());
  readonly filtres = signal<AnnoncesFiltres>({ tri: 'recent' });
  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 12;

  constructor() {
    this.publicService.provinces().subscribe({ next: (p) => this.provinces.set(p) });
    this.publicService.produits().subscribe({ next: (p) => this.produits.set(p) });
    this.load();
  }

  get filtresActifs(): boolean {
    const f = this.filtres();
    return !!(f.q || f.type_annonce || f.produit || f.province || f.prix_min || f.prix_max);
  }

  appliquerFiltres(filtres: AnnoncesFiltres): void {
    this.filtres.set(filtres);
    this.page.set(1);
    this.load();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.requete?.unsubscribe();
    this.loading.set(true);
    this.loadError.set('');
    this.requete = this.publicService
      .offres({ ...this.filtres(), page: this.page(), page_size: this.pageSize })
      .subscribe({
        next: (res) => {
          this.items.set(res.results);
          this.total.set(res.count ?? res.results.length);
          this.loading.set(false);
        },
        error: (err) => {
          this.loading.set(false);
          this.loadError.set(toApiError(err).message);
        },
      });
  }
}

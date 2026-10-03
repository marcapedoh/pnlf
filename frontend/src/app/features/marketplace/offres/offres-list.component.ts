import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Subscription } from 'rxjs';

import { toApiError } from '../../../core/http/api-error.util';
import { AuthService } from '../../../core/auth/auth.service';
import { AnnoncesFiltres, vueAnnoncesMemorisee } from '../../../core/models/annonce.model';
import { unwrapCount, unwrapList } from '../../../core/models/common.model';
import { OffreDemande } from '../../../core/models/notification.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { AnnoncesAffichageComponent } from './annonces-affichage/annonces-affichage.component';
import { AnnoncesBarreComponent, OptionReference } from './annonces-barre/annonces-barre.component';

@Component({
  selector: 'app-offres-list',
  imports: [
    RouterLink,
    ButtonComponent,
    EmptyStateComponent,
    AlertBannerComponent,
    IconComponent,
    SkeletonComponent,
    PaginationComponent,
    AnnoncesAffichageComponent,
    AnnoncesBarreComponent,
  ],
  templateUrl: './offres-list.component.html',
  styleUrl: './offres-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffresListComponent {
  private readonly service = inject(MarketplaceService);
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private requete?: Subscription;

  readonly items = signal<OffreDemande[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly produits = signal<OptionReference[]>([]);
  readonly provinces = signal<OptionReference[]>([]);
  readonly vue = signal(vueAnnoncesMemorisee());
  readonly filtres = signal<AnnoncesFiltres>({ tri: 'recent' });

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 12;

  readonly canPost = this.auth.hasRole(
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
    RoleUtilisateur.ACHETEUR,
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
  );

  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);

  readonly filtresInitiaux: AnnoncesFiltres = this.lireFiltresUrl();

  constructor() {
    this.filtres.set(this.filtresInitiaux);
    this.referenceService.produits().subscribe({
      next: (res) => this.produits.set(unwrapList(res).map((p) => ({ id: p.id, nom: p.nom }))),
    });
    this.referenceService.provinces().subscribe({
      next: (res) => this.provinces.set(unwrapList(res).map((p) => ({ id: p.id, nom: p.nom }))),
    });
    this.load();
  }

  private lireFiltresUrl(): AnnoncesFiltres {
    const p = this.route.snapshot.queryParamMap;
    const type = p.get('type_annonce') ?? '';
    return {
      tri: 'recent',
      statut: this.canValidate ? (p.get('statut') ?? '') : '',
      type_annonce: ['OFFRE', 'DEMANDE'].includes(type) ? type : '',
      mine: p.get('mine') === '1' ? '1' : '',
      q: (p.get('q') ?? '').slice(0, 120),
    };
  }

  get filtresActifs(): boolean {
    const f = this.filtres();
    return !!(f.q || f.type_annonce || f.produit || f.province || f.prix_min || f.prix_max || f.statut || f.mine);
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
    this.requete = this.service
      .rechercher({ ...this.filtres(), page: this.page(), page_size: this.pageSize })
      .subscribe({
        next: (res) => {
          this.items.set(unwrapList(res));
          this.total.set(unwrapCount(res));
          this.loading.set(false);
        },
        error: (err) => {
          this.loading.set(false);
          this.loadError.set(toApiError(err).message);
        },
      });
  }
}

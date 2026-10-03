import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { initialesStructure } from '../../../core/auth/display-name.util';
import { toApiError } from '../../../core/http/api-error.util';
import { TypeActeur } from '../../../core/models/producteur.model';
import {
  PublicProducteur,
  PublicProvince,
  TYPE_ACTEUR_PUBLIC_LABELS,
} from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';

@Component({
  selector: 'app-annuaire-public',
  imports: [
    RouterLink,
    FormsModule,
    SkeletonComponent,
    EmptyStateComponent,
    IconComponent,
    ButtonComponent,
    PaginationComponent,
  ],
  templateUrl: './annuaire-public.component.html',
  styleUrl: './annuaire-public.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AnnuairePublicComponent {
  private readonly publicService = inject(PublicService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private requete = 0;

  readonly producteurs = signal<PublicProducteur[]>([]);
  readonly provinces = signal<PublicProvince[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 12;
  readonly typeLabels = TYPE_ACTEUR_PUBLIC_LABELS;
  readonly TypeActeur = TypeActeur;

  province = '';
  typeActeur = '';
  produit = '';
  recherche = '';

  private readonly filter$ = new Subject<void>();

  constructor() {
    const params = this.route.snapshot.queryParamMap;
    this.recherche = params.get('q') ?? '';
    this.produit = params.get('produit') ?? '';
    this.province = params.get('province') ?? '';
    this.typeActeur = params.get('type_acteur') ?? '';
    const page = Number(params.get('page'));
    this.page.set(Number.isInteger(page) && page > 1 ? page : 1);

    this.publicService.provinces().subscribe((p) => this.provinces.set(p));
    this.filter$.pipe(debounceTime(300), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.syncUrl();
    const req = ++this.requete;
    this.publicService
      .producteurs({
        province: this.province || undefined,
        type_acteur: this.typeActeur || undefined,
        produit: this.produit.trim() || undefined,
        q: this.recherche.trim() || undefined,
        page: this.page(),
        page_size: this.pageSize,
      })
      .subscribe({
        next: (res) => {
          if (req !== this.requete) return;
          this.producteurs.set(res.results);
          this.total.set(res.count ?? res.results.length);
          this.loading.set(false);
        },
        error: (err) => {
          if (req !== this.requete) return;
          if (this.page() > 1 && (err as { status?: number })?.status === 404) {
            this.page.set(1);
            this.load();
            return;
          }
          this.loadError.set(toApiError(err).message);
          this.loading.set(false);
        },
      });
  }

  onFilterChange(): void {
    this.filter$.next();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
    if (typeof window !== 'undefined') window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  private syncUrl(): void {
    this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        q: this.recherche.trim() || null,
        produit: this.produit.trim() || null,
        province: this.province || null,
        type_acteur: this.typeActeur || null,
        page: this.page() > 1 ? this.page() : null,
      },
      replaceUrl: true,
    });
  }

  resetFilters(): void {
    this.recherche = '';
    this.produit = '';
    this.province = '';
    this.typeActeur = '';
    this.page.set(1);
    this.load();
  }

  initials(p: PublicProducteur): string {
    if (!p.prenoms?.trim()) return initialesStructure(p.nom);
    return `${p.prenoms.charAt(0)}${p.nom.charAt(0)}`.toUpperCase();
  }

  localisation(p: PublicProducteur): string {
    const province = (p.province_nom ?? '').trim();
    const communaute = (p.communaute ?? '').trim();
    if (!communaute || communaute.localeCompare(province, 'fr', { sensitivity: 'base' }) === 0) {
      return province || 'Province non renseignée';
    }
    return province ? `${province} · ${communaute}` : communaute;
  }
}

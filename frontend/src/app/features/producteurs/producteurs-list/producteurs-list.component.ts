import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { unwrapCount, unwrapList } from '../../../core/models/common.model';
import {
  Producteur,
  STATUT_PRODUCTEUR_LABELS,
  StatutProducteur,
  TypeActeur,
} from '../../../core/models/producteur.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { producteurStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-producteurs-list',
  imports: [
    RouterLink,
    FormsModule,
    ButtonComponent,
    StatusBadgeComponent,
    PaginationComponent,
    EmptyStateComponent,
    SkeletonComponent,
  ],
  templateUrl: './producteurs-list.component.html',
  styleUrl: './producteurs-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProducteursListComponent {
  private readonly service = inject(ProducteursService);
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly toast = inject(ToastService);
  private readonly search$ = new Subject<void>();

  readonly items = signal<Producteur[]>([]);
  readonly loading = signal(true);
  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 15;

  readonly search = signal('');
  readonly provinceFilter = signal('');
  readonly statutFilter = signal('');
  readonly provinces = signal<{ value: string; label: string }[]>([]);

  readonly statutLabels = STATUT_PRODUCTEUR_LABELS;
  readonly tone = producteurStatusTone;
  readonly TypeActeur = TypeActeur;
  readonly StatutProducteur = StatutProducteur;

  readonly canCreate = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );
  readonly canValidate = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });

    this.search$.pipe(debounceTime(350), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });

    this.load();
  }

  onSearchInput(value: string): void {
    this.search.set(value);
    this.search$.next();
  }

  onFilterChange(): void {
    this.page.set(1);
    this.load();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service
      .list({
        page: this.page(),
        page_size: this.pageSize,
        search: this.search(),
        province: this.provinceFilter(),
        statut: this.statutFilter(),
      })
      .subscribe({
        next: (res) => {
          this.items.set(unwrapList(res));
          this.total.set(unwrapCount(res));
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }

  valider(p: Producteur): void {
    this.service.valider(p.id).subscribe({
      next: () => {
        this.toast.success('Fiche validée', `${p.prenoms} ${p.nom} est désormais actif(ve).`);
        this.load();
      },
      error: () => this.toast.error('Échec de la validation'),
    });
  }

  rejeter(p: Producteur): void {
    this.service.rejeter(p.id).subscribe({
      next: () => {
        this.toast.info('Fiche rejetée', `La fiche de ${p.prenoms} ${p.nom} a été rejetée.`);
        this.load();
      },
      error: () => this.toast.error('Échec du rejet'),
    });
  }
}

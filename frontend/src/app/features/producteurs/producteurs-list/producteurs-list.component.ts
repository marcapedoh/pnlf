import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
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
import { PdfPreviewService } from '../../../core/services/pdf-preview.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { producteurStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';

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
    ConfirmDialogComponent,
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
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly pdfPreview = inject(PdfPreviewService);
  private readonly search$ = new Subject<void>();

  readonly items = signal<Producteur[]>([]);
  readonly loading = signal(true);
  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 10;

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
    RoleUtilisateur.COOPERATIVE,
  );
  readonly canValidate = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );
  readonly isProducteur = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);
  readonly dialog = signal<{ kind: 'desactiver' | 'rejeter'; item: Producteur } | null>(null);
  readonly dialogLoading = signal(false);

  constructor() {
    if (this.isProducteur) {
      this.loading.set(true);
      this.service.list({ page_size: 1 }).subscribe({
        next: (res) => {
          const own = unwrapList(res)[0];
          if (own) {
            this.router.navigate(['/app/producteurs', own.id], { replaceUrl: true });
            return;
          }
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
      return;
    }

    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });

    const statutInitial = this.route.snapshot.queryParamMap.get('statut');
    if (statutInitial) {
      this.statutFilter.set(statutInitial);
    }

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
    this.dialog.set({ kind: 'rejeter', item: p });
  }

  desactiver(p: Producteur): void {
    this.dialog.set({ kind: 'desactiver', item: p });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    const req$ =
      d.kind === 'rejeter' ? this.service.rejeter(d.item.id, value.trim()) : this.service.desactiver(d.item.id);
    req$.subscribe({
      next: () => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        this.toast.success(d.kind === 'rejeter' ? 'Fiche rejetée' : 'Fiche désactivée');
        this.load();
      },
      error: () => {
        this.dialogLoading.set(false);
        this.toast.error('Échec de l’opération');
      },
    });
  }

  activer(p: Producteur): void {
    this.service.activer(p.id).subscribe({
      next: () => {
        this.toast.success('Fiche réactivée', `${p.prenoms} ${p.nom} est de nouveau actif(ve).`);
        this.load();
      },
      error: () => this.toast.error('Échec de la réactivation'),
    });
  }

  exporterListePdf(): void {
    this.pdfPreview.open('Liste des producteurs/collecteurs', 'pnlf-producteurs.pdf', () =>
      this.service.listePdfBlob({
        search: this.search(),
        province: this.provinceFilter(),
        statut: this.statutFilter(),
      }),
    );
  }
}

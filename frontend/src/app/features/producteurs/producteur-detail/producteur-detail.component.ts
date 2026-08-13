import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { unwrapList } from '../../../core/models/common.model';
import { Lot, STATUT_LOT_LABELS } from '../../../core/models/lot.model';
import { Producteur, STATUT_PRODUCTEUR_LABELS, StatutProducteur } from '../../../core/models/producteur.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { LotsService } from '../../../core/services/lots.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { lotStatusTone, producteurStatusTone } from '../../../core/ui/status-tone.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-producteur-detail',
  imports: [RouterLink, DatePipe, CardComponent, StatusBadgeComponent, ButtonComponent, SkeletonComponent, EmptyStateComponent],
  templateUrl: './producteur-detail.component.html',
  styleUrl: './producteur-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProducteurDetailComponent {
  private readonly service = inject(ProducteursService);
  private readonly lotsService = inject(LotsService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly producteur = signal<Producteur | null>(null);
  readonly lots = signal<Lot[]>([]);
  readonly loading = signal(true);
  readonly statutLabels = STATUT_PRODUCTEUR_LABELS;
  readonly statutLotLabels = STATUT_LOT_LABELS;
  readonly tone = producteurStatusTone;
  readonly lotTone = lotStatusTone;
  readonly StatutProducteur = StatutProducteur;

  readonly canManage = this.auth.hasRole(
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
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.get(this.id).subscribe({
      next: (p) => {
        this.producteur.set(p);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/producteurs']);
      },
    });
    this.lotsService.list({ producteur: this.id, page_size: 10 }).subscribe((res) => {
      this.lots.set(unwrapList(res));
    });
  }

  valider(): void {
    this.service.valider(this.id).subscribe({
      next: () => {
        this.toast.success('Fiche validée avec succès');
        this.load();
      },
      error: () => this.toast.error('Échec de la validation'),
    });
  }

  rejeter(): void {
    this.service.rejeter(this.id).subscribe({
      next: () => {
        this.toast.info('Fiche rejetée');
        this.load();
      },
      error: () => this.toast.error('Échec du rejet'),
    });
  }
}

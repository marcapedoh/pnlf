import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';

import { AuthService } from '../../core/auth/auth.service';
import { DashboardService, InboxValidation } from '../../core/services/dashboard.service';
import { RoleUtilisateur } from '../../core/models/user.model';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';

@Component({
  selector: 'app-a-traiter',
  imports: [RouterLink, DatePipe, CardComponent, ButtonComponent, EmptyStateComponent, SkeletonComponent],
  templateUrl: './a-traiter.component.html',
  styleUrl: './a-traiter.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ATraiterComponent {
  private readonly dashboard = inject(DashboardService);
  private readonly auth = inject(AuthService);

  readonly loading = signal(true);
  readonly data = signal<InboxValidation | null>(null);
  readonly canValidateOffresCertifs = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
  );

  constructor() {
    this.dashboard.aTraiter().subscribe({
      next: (d) => {
        this.data.set(d);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  total(): number {
    const d = this.data();
    if (!d) return 0;
    return d.producteurs.count + d.cooperatives.count + d.certifications.count + d.offres.count + (d.acheteurs?.count ?? 0);
  }
}

import { DatePipe, JsonPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';

import { AuthService } from '../../core/auth/auth.service';
import { unwrapList } from '../../core/models/common.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { AppareilSync, SyncConflict } from '../../core/models/sync.model';
import { SyncService } from '../../core/services/sync.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { ToastService } from '../../design-system/toast/toast.service';

@Component({
  selector: 'app-synchronisation',
  imports: [DatePipe, JsonPipe, CardComponent, EmptyStateComponent, ButtonComponent],
  templateUrl: './synchronisation.component.html',
  styleUrl: './synchronisation.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SynchronisationComponent {
  private readonly syncService = inject(SyncService);
  private readonly toast = inject(ToastService);
  private readonly auth = inject(AuthService);

  readonly appareils = signal<AppareilSync[]>([]);
  readonly conflits = signal<SyncConflict[]>([]);
  readonly loading = signal(true);
  readonly resolvingId = signal<string | null>(null);

  readonly canResoudre = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);

  constructor() {
    this.syncService.appareils().subscribe((res) => this.appareils.set(unwrapList(res)));
    this.syncService.conflits().subscribe({
      next: (res) => {
        this.conflits.set(unwrapList(res));
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  resoudre(conflict: SyncConflict, choix: 'CLIENT' | 'SERVEUR'): void {
    this.resolvingId.set(conflict.id);
    const resolution = choix === 'CLIENT' ? 'Version terrain conservée' : 'Version serveur conservée';
    this.syncService.resoudre(conflict.id, resolution).subscribe({
      next: () => {
        this.conflits.update((list) => list.filter((c) => c.id !== conflict.id));
        this.resolvingId.set(null);
        this.toast.success('Conflit résolu.');
      },
      error: () => {
        this.resolvingId.set(null);
        this.toast.error('Échec de la résolution du conflit.');
      },
    });
  }
}

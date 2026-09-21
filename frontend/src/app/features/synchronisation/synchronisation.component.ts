import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { AuthService } from '../../core/auth/auth.service';
import { unwrapList } from '../../core/models/common.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { AppareilSync, SyncConflict } from '../../core/models/sync.model';
import { SyncService } from '../../core/services/sync.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { ToastService } from '../../design-system/toast/toast.service';

const FIELD_LABELS: Record<string, string> = {
  quantite: 'Quantité',
  latitude: 'Latitude',
  longitude: 'Longitude',
  statut: 'Statut',
  observations: 'Observations',
  nom: 'Nom',
  prenoms: 'Prénoms',
  telephone: 'Téléphone',
  date_collecte: 'Date de collecte',
  produit: 'Produit',
  unite: 'Unité',
};

@Component({
  selector: 'app-synchronisation',
  imports: [DatePipe, FormsModule, CardComponent, EmptyStateComponent, ButtonComponent],
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
  readonly deviceLibelle = signal('');
  readonly registering = signal(false);

  readonly canResoudre = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly isForestier = this.auth.hasRole(RoleUtilisateur.AGENT_FORESTIER);

  constructor() {
    this.reload();
  }

  reload(): void {
    this.syncService.appareils().subscribe((res) => this.appareils.set(unwrapList(res)));
    this.syncService.conflits().subscribe({
      next: (res) => {
        this.conflits.set(unwrapList(res));
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  fieldEntries(payload: Record<string, unknown> | null): { key: string; label: string; value: string }[] {
    if (!payload) return [];
    return Object.entries(payload)
      .filter(([k]) => !['id', 'client_uuid', 'sync_version'].includes(k))
      .map(([key, value]) => ({
        key,
        label: FIELD_LABELS[key] || key.replaceAll('_', ' '),
        value: value == null ? '—' : String(value),
      }));
  }

  enregistrerAppareil(): void {
    this.registering.set(true);
    const deviceId = localStorage.getItem('pnlf_device_id') || crypto.randomUUID();
    localStorage.setItem('pnlf_device_id', deviceId);
    this.syncService
      .enregistrerAppareil({
        device_id: deviceId,
        libelle: this.deviceLibelle().trim() || navigator.userAgent.slice(0, 80),
      })
      .subscribe({
        next: () => {
          this.registering.set(false);
          this.deviceLibelle.set('');
          this.toast.success('Appareil enregistré');
          this.reload();
        },
        error: () => {
          this.registering.set(false);
          this.toast.error('Impossible d’enregistrer cet appareil.');
        },
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

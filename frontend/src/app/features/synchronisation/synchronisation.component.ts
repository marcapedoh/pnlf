import { PnlfDatePipe } from '../../shared/pipes/format.pipes';
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
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { toApiError } from '../../core/http/api-error.util';

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

const ENTITE_LABELS: Record<string, string> = {
  lot: 'Lot',
  lots: 'Lot',
  producteur: 'Fiche producteur',
  producteurs: 'Fiche producteur',
  mouvement: 'Mouvement de lot',
  mouvements: 'Mouvement de lot',
  zone_collecte: 'Zone de collecte',
  zones_collecte: 'Zone de collecte',
};

@Component({
  selector: 'app-synchronisation',
  imports: [PnlfDatePipe, FormsModule, CardComponent, EmptyStateComponent, ButtonComponent, ConfirmDialogComponent],
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
  readonly loadError = signal('');
  readonly appareilsError = signal('');
  readonly resolvingId = signal<string | null>(null);
  readonly pendingResolution = signal<{ conflict: SyncConflict; choix: 'CLIENT' | 'SERVEUR' } | null>(null);
  readonly deviceLibelle = signal('');
  readonly registering = signal(false);

  readonly canResoudre = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);
  readonly isForestier = this.auth.hasRole(RoleUtilisateur.AGENT_FORESTIER);

  constructor() {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.appareilsError.set('');
    this.syncService.appareils().subscribe({
      next: (res) => this.appareils.set(unwrapList(res)),
      error: () => this.appareilsError.set('Impossible de charger la liste des appareils.'),
    });
    this.syncService.conflits().subscribe({
      next: (res) => {
        this.conflits.set(unwrapList(res));
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.loadError.set('Impossible de charger les conflits de synchronisation.');
      },
    });
  }

  entiteLabel(entite: string | null | undefined): string {
    return ENTITE_LABELS[(entite ?? '').toLowerCase()] ?? (entite || 'Élément');
  }

  fieldEntries(payload: Record<string, unknown> | null): { key: string; label: string; value: string }[] {
    if (!payload) return [];
    return Object.entries(payload)
      .filter(([k]) => !['id', 'client_uuid', 'sync_version'].includes(k))
      .map(([key, value]) => ({
        key,
        label: FIELD_LABELS[key] || key.replaceAll('_', ' '),
        value: value == null ? 'Non renseigné' : String(value),
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
        this.pendingResolution.set(null);
        this.toast.success('Conflit résolu');
      },
      error: (err) => {
        this.resolvingId.set(null);
        this.pendingResolution.set(null);
        this.toast.error('Échec de la résolution du conflit', toApiError(err).message);
      },
    });
  }
}

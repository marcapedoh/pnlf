import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { environment } from '../../../../environments/environment';
import {
  Lot,
  STATUT_LOT_LABELS,
  STATUT_LOT_ORDRE,
  StatutLot,
  TypeMouvement,
  TYPE_MOUVEMENT_LABELS,
} from '../../../core/models/lot.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { LotsService } from '../../../core/services/lots.service';
import { lotStatusTone } from '../../../core/ui/status-tone.util';
import { triggerBrowserDownload } from '../../../core/http/download-file.util';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-lot-detail',
  imports: [
    RouterLink,
    DatePipe,
    FormsModule,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    IconComponent,
  ],
  templateUrl: './lot-detail.component.html',
  styleUrl: './lot-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LotDetailComponent {
  private readonly service = inject(LotsService);
  private readonly http = inject(HttpClient);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly lot = signal<Lot | null>(null);
  readonly loading = signal(true);
  readonly changingStatus = signal(false);
  readonly nextStatut = signal('');
  readonly uploadingPhotos = signal(false);
  readonly showMouvementForm = signal(false);
  readonly savingMouvement = signal(false);
  readonly mouvementType = signal<string>(TypeMouvement.TRANSFERT);
  readonly mouvementDate = signal(new Date().toISOString().slice(0, 16));
  readonly mouvementLieu = signal('');
  readonly mouvementQuantite = signal('');
  readonly mouvementCommentaire = signal('');
  readonly mouvementTypes = Object.entries(TYPE_MOUVEMENT_LABELS).map(([value, label]) => ({ value, label }));

  readonly statutLabels = STATUT_LOT_LABELS;
  readonly typeMouvementLabels = TYPE_MOUVEMENT_LABELS;
  readonly tone = lotStatusTone;
  readonly verifyUrl = (uuid: string) => `${window.location.origin}/verifier/${uuid}`;
  readonly appApiOrigin = environment.apiUrl.replace(/\/api$/, '');

  readonly canChangeStatus = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );
  readonly canAddMouvement = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.get(this.id).subscribe({
      next: (lot) => {
        this.lot.set(lot);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/lots']);
      },
    });
  }

  nextStatusOptions(): StatutLot[] {
    const current = this.lot()?.statut;
    if (!current) return [];
    const idx = STATUT_LOT_ORDRE.indexOf(current as StatutLot);
    return idx >= 0 ? STATUT_LOT_ORDRE.slice(idx + 1) : [];
  }

  changerStatut(): void {
    if (!this.nextStatut()) return;
    this.changingStatus.set(true);
    this.service.changerStatut(this.id, this.nextStatut()).subscribe({
      next: (lot) => {
        this.lot.set(lot);
        this.changingStatus.set(false);
        this.nextStatut.set('');
        this.toast.success('Statut mis à jour', `Le lot est désormais "${this.statutLabels[lot.statut]}".`);
      },
      error: () => {
        this.changingStatus.set(false);
        this.toast.error('Échec de la mise à jour du statut');
      },
    });
  }

  onPhotosSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    input.value = '';
    const lot = this.lot();
    if (!files.length || !lot) return;

    const disponibles = 2 - lot.photos_urls.length;
    const aEnvoyer = files.slice(0, Math.max(disponibles, 0));
    if (!aEnvoyer.length) {
      this.toast.info('2 photos maximum par lot. Supprimez-en une avant d\'en ajouter une nouvelle.');
      return;
    }

    this.uploadingPhotos.set(true);
    this.service.uploadPhotos(lot.id, aEnvoyer).subscribe({
      next: (updated) => {
        this.lot.set(updated);
        this.uploadingPhotos.set(false);
        this.toast.success('Photo(s) ajoutée(s) avec succès');
      },
      error: () => {
        this.uploadingPhotos.set(false);
        this.toast.error('Échec de l\'envoi de la photo');
      },
    });
  }

  removePhoto(url: string): void {
    const lot = this.lot();
    if (!lot) return;
    this.service.deletePhoto(lot.id, url).subscribe({
      next: (updated) => {
        this.lot.set(updated);
        this.toast.info('Photo retirée');
      },
      error: () => this.toast.error('Échec de la suppression de la photo'),
    });
  }

  copyVerifyLink(uuid: string): void {
    navigator.clipboard?.writeText(this.verifyUrl(uuid));
    this.toast.info('Lien copié', "Le lien de vérification publique a été copié.");
  }

  enregistrerMouvement(): void {
    const lot = this.lot();
    if (!lot) return;
    this.savingMouvement.set(true);
    this.service
      .ajouterMouvement(lot.id, {
        type_mouvement: this.mouvementType() as TypeMouvement,
        date_mouvement: this.mouvementDate() ? new Date(this.mouvementDate()).toISOString() : undefined,
        lieu_libelle: this.mouvementLieu() || null,
        quantite: this.mouvementQuantite() ? Number(this.mouvementQuantite()) : null,
        commentaire: this.mouvementCommentaire() || null,
      })
      .subscribe({
        next: () => {
          this.savingMouvement.set(false);
          this.showMouvementForm.set(false);
          this.mouvementLieu.set('');
          this.mouvementQuantite.set('');
          this.mouvementCommentaire.set('');
          this.toast.success('Étape de traçabilité enregistrée');
          this.load();
        },
        error: () => {
          this.savingMouvement.set(false);
          this.toast.error("Impossible d'enregistrer cette étape.");
        },
      });
  }

  downloadQr(): void {
    const lot = this.lot();
    if (!lot) return;
    this.http.get(this.service.qrDownloadUrl(lot.id), { responseType: 'blob' }).subscribe((blob) => {
      triggerBrowserDownload(blob, `${lot.code_lot}-qr.png`);
    });
  }
}

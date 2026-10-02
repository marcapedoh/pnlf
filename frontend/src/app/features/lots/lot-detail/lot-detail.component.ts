import { formatDate } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { APP_LOCALE } from '../../../core/format/format.util';
import { toApiError } from '../../../core/http/api-error.util';
import { environment } from '../../../../environments/environment';
import {
  Lot,
  STATUT_LOT_LABELS,
  STATUTS_LOT_MODIFIABLES,
  STATUTS_LOT_SANS_MOUVEMENT,
  StatutLot,
  TRANSITIONS_MANUELLES_LOT,
  TypeMouvement,
  TYPE_MOUVEMENT_LABELS,
  TYPES_MOUVEMENT_PAR_ROLE,
} from '../../../core/models/lot.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { LotsService } from '../../../core/services/lots.service';
import { lotStatusTone } from '../../../core/ui/status-tone.util';
import { triggerBrowserDownload } from '../../../core/http/download-file.util';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { PnlfDatePipe, PnlfMontantPipe, PnlfQuantitePipe, PnlfUnitePipe } from '../../../shared/pipes/format.pipes';

const PHOTO_MAX_BYTES = 5 * 1024 * 1024;

function maintenantLocal(): string {
  return formatDate(new Date(), "yyyy-MM-dd'T'HH:mm", APP_LOCALE);
}

@Component({
  selector: 'app-lot-detail',
  imports: [
    RouterLink,
    FormsModule,
    PnlfDatePipe,
    PnlfQuantitePipe,
    PnlfMontantPipe,
    PnlfUnitePipe,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    IconComponent,
    ConfirmDialogComponent,
    AlertBannerComponent,
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
  private readonly title = inject(Title);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly lot = signal<Lot | null>(null);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly changingStatus = signal(false);
  readonly nextStatut = signal('');
  readonly confirmStatut = signal(false);
  readonly photoToRemove = signal<string | null>(null);
  readonly removingPhoto = signal(false);
  readonly uploadingPhotos = signal(false);
  readonly downloadingQr = signal(false);
  readonly showMouvementForm = signal(false);
  readonly savingMouvement = signal(false);
  readonly mouvementError = signal('');
  readonly mouvementType = signal<string>(TypeMouvement.TRANSFERT);
  readonly mouvementDate = signal(maintenantLocal());
  readonly mouvementMax = signal(maintenantLocal());
  readonly mouvementLieu = signal('');
  readonly mouvementQuantite = signal('');
  readonly mouvementCommentaire = signal('');
  readonly mouvementTypes = (TYPES_MOUVEMENT_PAR_ROLE[this.auth.currentUser()?.role ?? ''] ?? []).map((value) => ({
    value,
    label: TYPE_MOUVEMENT_LABELS[value],
  }));
  readonly confirmPublier = signal(false);
  readonly publishing = signal(false);
  readonly confirmSuppression = signal(false);
  readonly deleting = signal(false);

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
  /**
   * L'API n'expose aux producteurs et coopératives que leurs propres lots : la photo est donc
   * modifiable par les agents et par le producteur ou la coopérative titulaire du lot.
   */
  readonly canEditPhotos = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );

  private readonly isAgent = this.canChangeStatus;

  /** Statuts proposés : uniquement les transitions acceptées par le serveur. */
  readonly nextStatusOptions = computed<StatutLot[]>(() => {
    const current = this.lot()?.statut as StatutLot | undefined;
    return current ? (TRANSITIONS_MANUELLES_LOT[current] ?? []) : [];
  });

  /** Le serveur refuse toute étape sur un brouillon, un lot annulé ou archivé. */
  readonly peutAjouterEtape = computed(() => {
    const lot = this.lot();
    return (
      this.canAddMouvement &&
      this.mouvementTypes.length > 0 &&
      !!lot &&
      !STATUTS_LOT_SANS_MOUVEMENT.includes(lot.statut)
    );
  });

  readonly peutPublier = computed(() => this.canAddMouvement && this.lot()?.statut === StatutLot.BROUILLON);

  /** Producteurs et coopératives ne suppriment que les lots en brouillon ou déclarés. */
  readonly peutSupprimer = computed(() => {
    const statut = this.lot()?.statut;
    if (!statut || !this.canAddMouvement) return false;
    if (statut === StatutLot.ANNULE || statut === StatutLot.ARCHIVE) return false;
    return this.isAgent || STATUTS_LOT_MODIFIABLES.includes(statut);
  });

  readonly confirmStatutMessage = computed(() => {
    const lot = this.lot();
    const cible = this.nextStatut() as StatutLot;
    if (!lot || !cible) return '';
    const base = `Le lot ${lot.code_lot} passera de « ${this.statutLabels[lot.statut]} » à « ${this.statutLabels[cible]} ».`;
    if (cible === StatutLot.ANNULE) return `${base} Un lot annulé ne peut plus évoluer, sauf vers « Archivé ».`;
    return `${base} Ce changement ne pourra pas être annulé.`;
  });

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.get(this.id).subscribe({
      next: (lot) => {
        this.lot.set(lot);
        this.title.setTitle(`Lot ${lot.code_lot} | PFNL`);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.lot.set(null);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  demanderChangementStatut(): void {
    if (this.nextStatut()) this.confirmStatut.set(true);
  }

  publier(): void {
    this.publishing.set(true);
    this.service.publier(this.id).subscribe({
      next: (lot) => {
        this.lot.set(lot);
        this.publishing.set(false);
        this.confirmPublier.set(false);
        this.toast.success('Lot publié', 'Le lot est désormais « Déclaré » et visible des agents.');
      },
      error: (err) => {
        this.publishing.set(false);
        this.confirmPublier.set(false);
        const apiError = toApiError(err);
        this.toast.error('Publication impossible', Object.values(apiError.fieldErrors ?? {}).flat()[0] ?? apiError.message);
      },
    });
  }

  supprimer(): void {
    this.deleting.set(true);
    this.service.remove(this.id).subscribe({
      next: () => {
        this.deleting.set(false);
        this.confirmSuppression.set(false);
        this.toast.success('Lot supprimé');
        this.router.navigate(['/app/lots']);
      },
      error: (err) => {
        this.deleting.set(false);
        this.confirmSuppression.set(false);
        this.toast.error('Suppression impossible', toApiError(err).message);
      },
    });
  }

  changerStatut(): void {
    if (!this.nextStatut()) return;
    this.changingStatus.set(true);
    this.service.changerStatut(this.id, this.nextStatut()).subscribe({
      next: (lot) => {
        this.lot.set(lot);
        this.changingStatus.set(false);
        this.confirmStatut.set(false);
        this.nextStatut.set('');
        this.toast.success('Statut mis à jour', `Le lot est désormais « ${this.statutLabels[lot.statut]} ».`);
      },
      error: (err) => {
        this.changingStatus.set(false);
        this.confirmStatut.set(false);
        const apiError = toApiError(err);
        this.toast.error('Échec de la mise à jour du statut', apiError.fieldErrors?.['statut']?.[0] ?? apiError.message);
      },
    });
  }

  onPhotosSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    input.value = '';
    const lot = this.lot();
    if (!files.length || !lot) return;

    const invalide = files.find((f) => !['image/jpeg', 'image/png', 'image/webp'].includes(f.type) || f.size > PHOTO_MAX_BYTES);
    if (invalide) {
      this.toast.error('Photo refusée', `« ${invalide.name} » doit être une image JPEG, PNG ou WEBP de 5 Mo maximum.`);
      return;
    }
    const disponibles = 2 - lot.photos_urls.length;
    const aEnvoyer = files.slice(0, Math.max(disponibles, 0));
    if (!aEnvoyer.length) {
      this.toast.info('2 photos maximum par lot', 'Supprimez-en une avant d’en ajouter une nouvelle.');
      return;
    }

    this.uploadingPhotos.set(true);
    this.service.uploadPhotos(lot.id, aEnvoyer).subscribe({
      next: (updated) => {
        this.lot.set(updated);
        this.uploadingPhotos.set(false);
        this.toast.success(aEnvoyer.length > 1 ? 'Photos ajoutées' : 'Photo ajoutée');
      },
      error: (err) => {
        this.uploadingPhotos.set(false);
        const apiError = toApiError(err);
        this.toast.error('Échec de l’envoi de la photo', apiError.fieldErrors?.['photos']?.[0] ?? apiError.message);
      },
    });
  }

  confirmerSuppressionPhoto(): void {
    const lot = this.lot();
    const url = this.photoToRemove();
    if (!lot || !url) return;
    this.removingPhoto.set(true);
    this.service.deletePhoto(lot.id, url).subscribe({
      next: (updated) => {
        this.lot.set(updated);
        this.removingPhoto.set(false);
        this.photoToRemove.set(null);
        this.toast.success('Photo retirée');
      },
      error: (err) => {
        this.removingPhoto.set(false);
        this.photoToRemove.set(null);
        this.toast.error('Échec de la suppression de la photo', toApiError(err).message);
      },
    });
  }

  copyVerifyLink(uuid: string): void {
    const url = this.verifyUrl(uuid);
    if (!navigator.clipboard) {
      this.toast.warning('Copie impossible', `Copiez ce lien manuellement : ${url}`);
      return;
    }
    navigator.clipboard.writeText(url).then(
      () => this.toast.success('Lien copié', 'Le lien de vérification publique a été copié.'),
      () => this.toast.warning('Copie impossible', `Copiez ce lien manuellement : ${url}`),
    );
  }

  ouvrirMouvementForm(): void {
    const ouvert = !this.showMouvementForm();
    this.showMouvementForm.set(ouvert);
    this.mouvementError.set('');
    if (ouvert) {
      const now = maintenantLocal();
      this.mouvementDate.set(now);
      this.mouvementMax.set(now);
    }
  }

  enregistrerMouvement(): void {
    const lot = this.lot();
    if (!lot) return;
    this.mouvementError.set('');
    const quantite = this.mouvementQuantite() ? Number(String(this.mouvementQuantite()).replace(',', '.')) : null;
    if (quantite !== null && !(quantite > 0)) {
      this.mouvementError.set('La quantité doit être supérieure à 0.');
      return;
    }
    if (this.mouvementDate() && this.mouvementDate() > maintenantLocal()) {
      this.mouvementError.set('La date de l’étape ne peut pas être dans le futur.');
      return;
    }
    this.savingMouvement.set(true);
    this.service
      .ajouterMouvement(lot.id, {
        type_mouvement: this.mouvementType() as TypeMouvement,
        // La saisie datetime-local est en heure locale : conversion explicite en ISO UTC.
        date_mouvement: this.mouvementDate() ? new Date(this.mouvementDate()).toISOString() : undefined,
        lieu_libelle: this.mouvementLieu() || null,
        quantite,
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
        error: (err) => {
          this.savingMouvement.set(false);
          const apiError = toApiError(err);
          const champs = Object.values(apiError.fieldErrors ?? {}).flat();
          this.mouvementError.set(champs[0] ?? apiError.message);
        },
      });
  }

  downloadQr(): void {
    const lot = this.lot();
    if (!lot) return;
    this.downloadingQr.set(true);
    this.http.get(this.service.qrDownloadUrl(lot.id), { responseType: 'blob' }).subscribe({
      next: (blob) => {
        this.downloadingQr.set(false);
        triggerBrowserDownload(blob, `${lot.code_lot}-qr.png`);
      },
      error: (err) => {
        this.downloadingQr.set(false);
        this.toast.error('Téléchargement du QR code impossible', toApiError(err).message);
      },
    });
  }
}

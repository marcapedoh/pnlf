import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { toApiError } from '../../../core/http/api-error.util';
import { unwrapCount, unwrapList } from '../../../core/models/common.model';
import { Lot, STATUT_LOT_LABELS } from '../../../core/models/lot.model';
import {
  DOCUMENTS_FICHE_PRODUCTEUR,
  DocumentInscription,
  Producteur,
  STATUT_PRODUCTEUR_LABELS,
  StatutProducteur,
} from '../../../core/models/producteur.model';
import { MessagePublic } from '../../../core/models/public.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { LotsService } from '../../../core/services/lots.service';
import { PdfPreviewService } from '../../../core/services/pdf-preview.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { lotStatusTone, producteurStatusTone } from '../../../core/ui/status-tone.util';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { PnlfDatePipe, PnlfQuantitePipe, PnlfTelephonePipe } from '../../../shared/pipes/format.pipes';
import { InvitationsRecuesComponent } from '../../cooperatives/invitations-recues/invitations-recues.component';

type DialogKind = 'valider' | 'rejeter' | 'desactiver' | 'activer';

const DIALOG_MESSAGES: Record<DialogKind, { ok: string; ko: string }> = {
  valider: { ok: 'Fiche validée', ko: 'Échec de la validation' },
  rejeter: { ok: 'Fiche rejetée', ko: 'Échec du rejet' },
  desactiver: { ok: 'Fiche désactivée', ko: 'Échec de la désactivation' },
  activer: { ok: 'Fiche réactivée', ko: 'Échec de la réactivation' },
};

@Component({
  selector: 'app-producteur-detail',
  imports: [
    RouterLink,
    PnlfDatePipe,
    PnlfQuantitePipe,
    PnlfTelephonePipe,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    ConfirmDialogComponent,
    AlertBannerComponent,
    InvitationsRecuesComponent,
  ],
  templateUrl: './producteur-detail.component.html',
  styleUrl: './producteur-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProducteurDetailComponent {
  private readonly service = inject(ProducteursService);
  private readonly lotsService = inject(LotsService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly toast = inject(ToastService);
  private readonly title = inject(Title);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly producteur = signal<Producteur | null>(null);
  readonly lots = signal<Lot[]>([]);
  readonly lotsTotal = signal(0);
  readonly lotsError = signal('');
  readonly messages = signal<MessagePublic[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
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
  /** Photo modifiable par l'administration, le titulaire et la coopérative de rattachement (refusée aux acheteurs). */
  readonly canEditPhoto = this.auth.hasRole(
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
  readonly isProducteurRole = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);
  readonly uploadingPhoto = signal(false);
  readonly dialog = signal<{ kind: DialogKind } | null>(null);
  readonly dialogLoading = signal(false);
  private readonly pdfPreview = inject(PdfPreviewService);

  /** Documents administratifs attendus (même liste que le formulaire de fiche). */
  readonly typesDocumentsAttendus = DOCUMENTS_FICHE_PRODUCTEUR.map((d) => ({
    type: d.type,
    label: d.libelle,
    requis: d.type === 'CNI',
  }));

  /** Fiche du producteur connecté : il peut y répondre aux invitations des coopératives. */
  estMaFiche(p: Producteur): boolean {
    return this.isProducteurRole && !!p.utilisateur_id && p.utilisateur_id === this.auth.currentUser()?.id;
  }

  constructor() {
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.get(this.id).subscribe({
      next: (p) => {
        this.producteur.set(p);
        this.title.setTitle(`${p.prenoms} ${p.nom} (${p.code_producteur}) | PFNL`);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.producteur.set(null);
        this.loadError.set(toApiError(err).message);
      },
    });
    this.lotsError.set('');
    this.lotsService.list({ producteur: this.id, page_size: 10 }).subscribe({
      next: (res) => {
        this.lots.set(unwrapList(res));
        this.lotsTotal.set(unwrapCount(res));
      },
      error: (err) => this.lotsError.set(toApiError(err).message),
    });
    this.service.messagesPublics(this.id).subscribe({
      next: (res) => this.messages.set(unwrapList(res)),
      error: () => this.messages.set([]),
    });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    const req$ =
      d.kind === 'rejeter'
        ? this.service.rejeter(this.id, value.trim())
        : d.kind === 'valider'
          ? this.service.valider(this.id)
          : d.kind === 'activer'
            ? this.service.activer(this.id)
            : this.service.desactiver(this.id);
    req$.subscribe({
      next: () => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        this.toast.success(DIALOG_MESSAGES[d.kind].ok);
        this.load();
      },
      error: (err) => {
        this.dialogLoading.set(false);
        this.toast.error(DIALOG_MESSAGES[d.kind].ko, toApiError(err).message);
      },
    });
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    this.uploadingPhoto.set(true);
    this.service.uploadPhoto(this.id, file).subscribe({
      next: (p) => {
        this.producteur.set(p);
        this.uploadingPhoto.set(false);
        this.toast.success('Photo mise à jour');
        input.value = '';
      },
      error: (err) => {
        this.uploadingPhoto.set(false);
        const apiError = toApiError(err);
        this.toast.error('Échec du téléversement', apiError.fieldErrors?.['photo']?.[0] ?? apiError.message);
        input.value = '';
      },
    });
  }

  initials(p: Producteur): string {
    return `${p.prenoms.charAt(0)}${p.nom.charAt(0)}`.toUpperCase();
  }

  /** Un champ est considéré manquant s'il est vide/nul : mis en évidence dans la fiche. */
  estManquant(valeur: unknown): boolean {
    return valeur === null || valeur === undefined || valeur === '';
  }

  /** Les champs privés sont absents de la réponse quand l'utilisateur n'a pas le droit de les lire. */
  aLaCle(p: Producteur, champ: keyof Producteur): boolean {
    return champ in p;
  }

  documentPour(type: DocumentInscription['type_document']): DocumentInscription | null {
    return this.producteur()?.documents?.find((d) => d.type_document === type) ?? null;
  }

  exporterPdf(): void {
    const p = this.producteur();
    const filename = `fiche-${p?.code_producteur ?? this.id}.pdf`;
    this.pdfPreview.open('Fiche producteur/collecteur', filename, () => this.service.fichePdfBlob(this.id));
  }

  marquerTraite(m: MessagePublic): void {
    this.service.marquerMessageTraite(m.id).subscribe({
      next: (updated) => {
        this.messages.set(this.messages().map((x) => (x.id === updated.id ? updated : x)));
        this.toast.success('Message marqué comme traité');
      },
      error: (err) => this.toast.error('Impossible de marquer ce message', toApiError(err).message),
    });
  }
}

import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, WritableSignal, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { of } from 'rxjs';

import { toApiError } from '../../core/http/api-error.util';
import { AuthService } from '../../core/auth/auth.service';
import { controlError, handleFormApiError, revealFormErrors } from '../../core/forms/form-errors.util';
import { unwrapList } from '../../core/models/common.model';
import {
  Certification,
  PIECES_ACCEPT,
  PIECES_CERTIFICATION_MAX,
  PIECES_EXTENSIONS,
  PIECE_INTITULE_MAX,
  PIECE_TAILLE_MAX_OCTETS,
  PieceCertification,
  STATUT_CERTIFICATION_LABELS,
  StatutCertification,
} from '../../core/models/certification.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { CertificationsService } from '../../core/services/certifications.service';
import { PdfPreviewService } from '../../core/services/pdf-preview.service';
import { IconComponent } from '../../design-system/icon/icon.component';
import { LotsService } from '../../core/services/lots.service';
import { ProducteursService } from '../../core/services/producteurs.service';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
import { ModalA11yDirective } from '../../design-system/modal/modal-a11y.directive';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { certificationStatusTone } from '../../core/ui/status-tone.util';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { SelectFieldComponent, SelectOption } from '../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { unwrapCount } from '../../core/models/common.model';
import { PnlfDatePipe } from '../../shared/pipes/format.pipes';

type FormKey = 'type_certification' | 'producteur';

/** Pièce choisie localement, pas encore envoyée. */
interface PieceBrouillon {
  cle: number;
  fichier: File;
  intitule: string;
  estImage: boolean;
  apercuUrl: string | null;
}

@Component({
  selector: 'app-certifications-list',
  imports: [
    ReactiveFormsModule,
    PnlfDatePipe,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    EmptyStateComponent,
    SelectFieldComponent,
    AlertBannerComponent,
    PaginationComponent,
    ConfirmDialogComponent,
    ModalA11yDirective,
    TextFieldComponent,
    SkeletonComponent,
    IconComponent,
  ],
  templateUrl: './certifications-list.component.html',
  styleUrl: './certifications-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CertificationsListComponent {
  private readonly service = inject(CertificationsService);
  private readonly producteursService = inject(ProducteursService);
  private readonly lotsService = inject(LotsService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly http = inject(HttpClient);
  private readonly pdfPreview = inject(PdfPreviewService);

  readonly items = signal<Certification[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly types = signal<SelectOption[]>([]);
  readonly producteurs = signal<SelectOption[]>([]);
  readonly lots = signal<SelectOption[]>([]);
  readonly loadingLots = signal(false);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly statutLabels = STATUT_CERTIFICATION_LABELS;
  readonly tone = certificationStatusTone;
  readonly StatutCertification = StatutCertification;

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 10;

  readonly canRequest = this.auth.hasRole(
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );
  /** Seul l'administrateur accorde ou refuse une certification. */
  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR);
  readonly isAdmin = this.canValidate;
  readonly isAgent = this.auth.hasRole(RoleUtilisateur.AGENT_MINISTERE, RoleUtilisateur.AGENT_FORESTIER);

  readonly piecesMax = PIECES_CERTIFICATION_MAX;
  readonly piecesAccept = PIECES_ACCEPT;
  readonly intituleMax = PIECE_INTITULE_MAX;
  /** Pièces du formulaire de demande. */
  readonly brouillons = signal<PieceBrouillon[]>([]);
  /** Pièces à ajouter à un dossier existant (fenêtre de détail). */
  readonly ajouts = signal<PieceBrouillon[]>([]);
  readonly piecesErreur = signal('');
  readonly ajoutErreur = signal('');
  readonly envoiAjouts = signal(false);
  readonly pieceASupprimer = signal<PieceCertification | null>(null);
  readonly suppressionPiece = signal(false);
  readonly apercuImage = signal<{ url: string; titre: string } | null>(null);
  private cleSuivante = 1;
  readonly actionId = signal<string | null>(null);
  readonly needsProducteurChoice = this.auth.hasRole(
    RoleUtilisateur.COOPERATIVE,
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );

  readonly form = this.fb.nonNullable.group({
    type_certification: ['', Validators.required],
    producteur: ['', this.needsProducteurChoice ? Validators.required : []],
    lot: [''],
    observations: [''],
  });

  readonly err = (name: FormKey, required?: string) => controlError(this.form.controls[name], required);

  readonly dialog = signal<{ kind: 'valider' | 'refuser'; id: string } | null>(null);
  readonly dialogLoading = signal(false);

  readonly detail = signal<Certification | null>(null);

  constructor() {
    this.service.types().subscribe((res) => {
      this.types.set(unwrapList(res).map((t) => ({ value: t.id, label: t.libelle })));
    });
    if (this.needsProducteurChoice) {
      this.producteursService.list({ page_size: 200, statut: 'ACTIF' }).subscribe((res) => {
        this.producteurs.set(
          unwrapList(res).map((p) => ({
            value: p.id,
            label: `${p.prenoms} ${p.nom} (${p.code_producteur})`,
          })),
        );
      });
      // Les lots proposés sont ceux du producteur choisi.
      this.form.controls.producteur.valueChanges.pipe(takeUntilDestroyed()).subscribe((id) => {
        this.form.patchValue({ lot: '' }, { emitEvent: false });
        this.loadLots(id || null);
      });
    } else {
      this.loadLots(null);
    }
    this.load();
    inject(DestroyRef).onDestroy(() => {
      this.viderBrouillons(this.brouillons);
      this.viderBrouillons(this.ajouts);
    });
  }

  private loadLots(producteurId: string | null): void {
    if (this.needsProducteurChoice && !producteurId) {
      this.lots.set([]);
      return;
    }
    this.loadingLots.set(true);
    this.lotsService.list({ page_size: 100, ...(producteurId ? { producteur: producteurId } : {}) }).subscribe({
      next: (res) => {
        this.loadingLots.set(false);
        this.lots.set(unwrapList(res).map((l) => ({ value: l.id, label: `${l.code_lot} : ${l.produit_nom}` })));
      },
      error: () => {
        this.loadingLots.set(false);
        this.lots.set([]);
      },
    });
  }

  get lotPlaceholder(): string {
    if (this.needsProducteurChoice && !this.form.controls.producteur.value) return 'Choisissez d’abord le producteur';
    if (this.loadingLots()) return 'Chargement des lots…';
    return this.lots().length ? 'Aucun lot spécifique' : 'Aucun lot pour ce producteur';
  }

  ouvrirFormulaire(): void {
    this.errorMessage.set('');
    this.form.reset();
    this.viderBrouillons(this.brouillons);
    this.piecesErreur.set('');
    this.showForm.set(true);
  }

  fermerFormulaire(): void {
    this.viderBrouillons(this.brouillons);
    this.showForm.set(false);
  }

  /* ---------- Pièces justificatives ---------- */

  tailleLisible(octets: number | null | undefined): string {
    if (!octets) return '';
    if (octets < 1024 * 1024) return `${Math.max(1, Math.round(octets / 1024))} Ko`;
    return `${(octets / (1024 * 1024)).toFixed(1).replace('.', ',')} Mo`;
  }

  estImagePiece(p: PieceCertification): boolean {
    return (p.type_mime ?? '').startsWith('image/');
  }

  /** Ajoute les fichiers choisis à une liste de brouillons, avec contrôles identiques à ceux de l'API. */
  choisirPieces(event: Event, cible: 'demande' | 'ajout'): void {
    const input = event.target as HTMLInputElement;
    const fichiers = Array.from(input.files ?? []);
    input.value = '';
    if (!fichiers.length) return;
    const liste = cible === 'demande' ? this.brouillons : this.ajouts;
    const erreur = cible === 'demande' ? this.piecesErreur : this.ajoutErreur;
    const dejaEnregistrees = cible === 'ajout' ? (this.detail()?.pieces?.length ?? 0) : 0;
    const refus: string[] = [];
    const nouveaux: PieceBrouillon[] = [];
    for (const fichier of fichiers) {
      if (dejaEnregistrees + liste().length + nouveaux.length >= this.piecesMax) {
        refus.push(`${this.piecesMax} documents au maximum par demande.`);
        break;
      }
      const nom = fichier.name.toLowerCase();
      const ext = nom.includes('.') ? nom.slice(nom.lastIndexOf('.')) : '';
      if (!PIECES_EXTENSIONS.includes(ext)) {
        refus.push(`« ${fichier.name} » n’est pas un PDF, JPG ou PNG.`);
        continue;
      }
      if (fichier.size > PIECE_TAILLE_MAX_OCTETS) {
        refus.push(`« ${fichier.name} » dépasse 8 Mo.`);
        continue;
      }
      if (fichier.size === 0) {
        refus.push(`« ${fichier.name} » est vide.`);
        continue;
      }
      const estImage = ext !== '.pdf';
      nouveaux.push({
        cle: this.cleSuivante++,
        fichier,
        intitule: fichier.name.replace(/\.[^.]+$/, '').replace(/[_-]+/g, ' ').slice(0, this.intituleMax),
        estImage,
        apercuUrl: estImage ? URL.createObjectURL(fichier) : null,
      });
    }
    liste.update((l) => [...l, ...nouveaux]);
    erreur.set(refus.join(' '));
  }

  renommerBrouillon(cible: 'demande' | 'ajout', cle: number, intitule: string): void {
    (cible === 'demande' ? this.brouillons : this.ajouts).update((l) =>
      l.map((p) => (p.cle === cle ? { ...p, intitule } : p)),
    );
  }

  retirerBrouillon(cible: 'demande' | 'ajout', cle: number): void {
    const liste = cible === 'demande' ? this.brouillons : this.ajouts;
    const piece = liste().find((p) => p.cle === cle);
    if (piece?.apercuUrl) URL.revokeObjectURL(piece.apercuUrl);
    liste.update((l) => l.filter((p) => p.cle !== cle));
  }

  apercuBrouillon(p: PieceBrouillon): void {
    if (p.estImage && p.apercuUrl) {
      this.apercuImage.set({ url: p.apercuUrl, titre: p.intitule || p.fichier.name });
      return;
    }
    this.pdfPreview.open(p.intitule || 'Aperçu du document', p.fichier.name, () => of(p.fichier));
  }

  apercuPiece(p: PieceCertification): void {
    if (!p.url) return;
    if (this.estImagePiece(p)) {
      this.apercuImage.set({ url: p.url, titre: p.intitule });
      return;
    }
    const url = p.url;
    this.pdfPreview.open(p.intitule, p.nom_original || 'document.pdf', () => this.http.get(url, { responseType: 'blob' }));
  }

  /** Message bloquant si une pièce n'a pas d'intitulé exploitable. */
  private intitulesInvalides(liste: PieceBrouillon[]): string {
    const sansTitre = liste.filter((p) => !p.intitule.trim()).length;
    if (sansTitre) return sansTitre > 1 ? `Donnez un titre à chacun des ${sansTitre} documents.` : 'Donnez un titre à chaque document.';
    if (liste.some((p) => p.intitule.trim().length > this.intituleMax)) {
      return `Le titre d’un document ne doit pas dépasser ${this.intituleMax} caractères.`;
    }
    return '';
  }

  envoyerAjouts(): void {
    const cert = this.detail();
    const liste = this.ajouts();
    if (!cert || !liste.length) return;
    const invalide = this.intitulesInvalides(liste);
    if (invalide) {
      this.ajoutErreur.set(invalide);
      return;
    }
    this.envoiAjouts.set(true);
    this.ajoutErreur.set('');
    this.service.ajouterPieces(cert.id, liste.map((p) => ({ fichier: p.fichier, intitule: p.intitule }))).subscribe({
      next: (maj) => {
        this.envoiAjouts.set(false);
        this.viderBrouillons(this.ajouts);
        this.majCertification(maj);
        this.toast.success(liste.length > 1 ? 'Documents ajoutés au dossier' : 'Document ajouté au dossier');
      },
      error: (err) => {
        this.envoiAjouts.set(false);
        const apiError = toApiError(err);
        this.ajoutErreur.set(Object.values(apiError.fieldErrors ?? {}).flat()[0] ?? apiError.message);
      },
    });
  }

  confirmerRetraitPiece(): void {
    const cert = this.detail();
    const piece = this.pieceASupprimer();
    if (!cert || !piece) return;
    this.suppressionPiece.set(true);
    this.service.retirerPiece(cert.id, piece.id).subscribe({
      next: (maj) => {
        this.suppressionPiece.set(false);
        this.pieceASupprimer.set(null);
        this.majCertification(maj);
        this.toast.success('Document retiré du dossier');
      },
      error: (err) => {
        this.suppressionPiece.set(false);
        this.pieceASupprimer.set(null);
        this.toast.error('Impossible de retirer ce document', toApiError(err).message);
      },
    });
  }

  /** Le demandeur (ou l'administrateur) complète le dossier tant qu'il n'est pas traité. */
  peutGererPieces(c: Certification): boolean {
    const enAttente = c.statut === StatutCertification.DEMANDEE || c.statut === StatutCertification.EN_COURS;
    return enAttente && !this.isAgent;
  }

  private majCertification(maj: Certification): void {
    this.detail.set(maj);
    this.items.update((list) => list.map((c) => (c.id === maj.id ? maj : c)));
  }

  private viderBrouillons(liste: WritableSignal<PieceBrouillon[]>): void {
    for (const p of liste()) {
      if (p.apercuUrl) URL.revokeObjectURL(p.apercuUrl);
    }
    liste.set([]);
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.list({ page: String(this.page()), page_size: String(this.pageSize) }).subscribe({
      next: (res) => {
        this.items.set(unwrapList(res));
        this.total.set(unwrapCount(res));
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  submit(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }
    const pieces = this.brouillons();
    const intitulesKo = this.intitulesInvalides(pieces);
    if (intitulesKo) {
      this.piecesErreur.set(intitulesKo);
      this.errorMessage.set(intitulesKo);
      return;
    }
    this.saving.set(true);
    const raw = this.form.getRawValue();
    const payload: Record<string, string> = {
      type_certification: raw.type_certification,
      observations: raw.observations,
    };
    if (raw.producteur) {
      payload['producteur'] = raw.producteur;
    }
    if (raw.lot) {
      payload['lot'] = raw.lot;
    }
    const req$ = pieces.length
      ? this.service.createAvecPieces(payload, pieces.map((p) => ({ fichier: p.fichier, intitule: p.intitule })))
      : this.service.create(payload);
    req$.subscribe({
      next: () => {
        this.saving.set(false);
        this.fermerFormulaire();
        this.toast.success(
          'Demande de certification envoyée',
          pieces.length ? `${pieces.length} document(s) joint(s) au dossier.` : undefined,
        );
        this.load();
      },
      error: (err) => {
        this.saving.set(false);
        const apiError = toApiError(err);
        const erreurPieces = apiError.fieldErrors?.['pieces'];
        if (erreurPieces?.length) this.piecesErreur.set(erreurPieces.join(' '));
        this.errorMessage.set(handleFormApiError(this.form, apiError, this.host));
      },
    });
  }

  verDetail(c: Certification): void {
    this.detail.set(c);
    // Rafraîchit depuis le serveur pour disposer du document_url à jour.
    this.service.get(c.id).subscribe({ next: (full) => this.detail.set(full) });
  }

  fermerDetail(): void {
    this.viderBrouillons(this.ajouts);
    this.ajoutErreur.set('');
    this.detail.set(null);
  }

  valider(c: Certification): void {
    this.dialog.set({ kind: 'valider', id: c.id });
  }

  refuser(c: Certification): void {
    this.dialog.set({ kind: 'refuser', id: c.id });
  }

  onDialogConfirm(value: string): void {
    const d = this.dialog();
    if (!d) return;
    this.dialogLoading.set(true);
    this.actionId.set(d.id);
    const req$ =
      d.kind === 'valider'
        ? this.service.valider(d.id, value)
        : this.service.refuser(d.id, value);
    req$.subscribe({
      next: () => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        this.actionId.set(null);
        this.toast.success(d.kind === 'valider' ? 'Certification validée' : 'Demande rejetée');
        this.load();
      },
      error: (err) => {
        this.dialogLoading.set(false);
        this.dialog.set(null);
        this.actionId.set(null);
        this.toast.error(d.kind === 'valider' ? 'Échec de la validation' : 'Échec du rejet', toApiError(err).message);
      },
    });
  }
}

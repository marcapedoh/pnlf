import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { toApiError } from '../../core/http/api-error.util';
import { AuthService } from '../../core/auth/auth.service';
import { todayIso } from '../../core/format/format.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../core/forms/form-errors.util';
import { unwrapList } from '../../core/models/common.model';
import { Certification, STATUT_CERTIFICATION_LABELS, StatutCertification } from '../../core/models/certification.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { CertificationsService } from '../../core/services/certifications.service';
import { LotsService } from '../../core/services/lots.service';
import { ProducteursService } from '../../core/services/producteurs.service';
import { dateNotFutureValidator } from '../../core/validators/pnlf.validators';
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

type FormKey = 'type_certification' | 'producteur' | 'date_demande';

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

  readonly today = todayIso();
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
  readonly canValidate = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
  );
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
    date_demande: [this.today, [Validators.required, dateNotFutureValidator]],
    observations: [''],
  });

  readonly err = (name: FormKey, required?: string) => controlError(this.form.controls[name], required);

  readonly dialog = signal<{ kind: 'valider' | 'refuser'; id: string } | null>(null);
  readonly dialogLoading = signal(false);

  readonly detail = signal<Certification | null>(null);
  readonly uploadingDoc = signal(false);

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
    this.showForm.set(true);
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
    this.saving.set(true);
    const raw = this.form.getRawValue();
    const payload: Record<string, string> = {
      type_certification: raw.type_certification,
      date_demande: raw.date_demande,
      observations: raw.observations,
    };
    if (raw.producteur) {
      payload['producteur'] = raw.producteur;
    }
    if (raw.lot) {
      payload['lot'] = raw.lot;
    }
    this.service.create(payload).subscribe({
      next: () => {
        this.saving.set(false);
        this.showForm.set(false);
        this.toast.success('Demande de certification envoyée');
        this.load();
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
      },
    });
  }

  verDetail(c: Certification): void {
    this.detail.set(c);
    // Rafraîchit depuis le serveur pour disposer du document_url à jour.
    this.service.get(c.id).subscribe({ next: (full) => this.detail.set(full) });
  }

  fermerDetail(): void {
    this.detail.set(null);
  }

  onDocumentSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    const cert = this.detail();
    if (!file || !cert) return;
    this.uploadingDoc.set(true);
    this.service.uploadDocument(cert.id, file).subscribe({
      next: (updated) => {
        this.uploadingDoc.set(false);
        this.detail.set(updated);
        this.items.update((list) => list.map((c) => (c.id === updated.id ? updated : c)));
        this.toast.success('Document ajouté à la certification');
        input.value = '';
      },
      error: (err) => {
        this.uploadingDoc.set(false);
        const apiError = toApiError(err);
        this.toast.error('Échec de l’envoi du document', Object.values(apiError.fieldErrors ?? {}).flat()[0] ?? apiError.message);
        input.value = '';
      },
    });
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

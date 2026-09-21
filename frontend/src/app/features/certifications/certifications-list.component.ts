import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { toApiError } from '../../core/http/api-error.util';
import { AuthService } from '../../core/auth/auth.service';
import { unwrapList } from '../../core/models/common.model';
import { Certification, STATUT_CERTIFICATION_LABELS, StatutCertification } from '../../core/models/certification.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { CertificationsService } from '../../core/services/certifications.service';
import { LotsService } from '../../core/services/lots.service';
import { ProducteursService } from '../../core/services/producteurs.service';
import { ConfirmDialogComponent } from '../../design-system/confirm-dialog/confirm-dialog.component';
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

@Component({
  selector: 'app-certifications-list',
  imports: [
    ReactiveFormsModule,
    DatePipe,
    CardComponent,
    StatusBadgeComponent,
    ButtonComponent,
    EmptyStateComponent,
    SelectFieldComponent,
    AlertBannerComponent,
    PaginationComponent,
    ConfirmDialogComponent,
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

  readonly items = signal<Certification[]>([]);
  readonly loading = signal(true);
  readonly types = signal<SelectOption[]>([]);
  readonly producteurs = signal<SelectOption[]>([]);
  readonly lots = signal<SelectOption[]>([]);
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
    producteur: [''],
    lot: [''],
    date_demande: [new Date().toISOString().slice(0, 10), Validators.required],
    observations: [''],
  });

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
            label: `${p.prenoms} ${p.nom} — ${p.code_producteur}`,
          })),
        );
      });
    }
    this.lotsService.list({ page_size: 50 }).subscribe((res) => {
      this.lots.set(
        unwrapList(res).map((l) => ({
          value: l.id,
          label: `${l.code_lot} — ${l.produit_nom}`,
        })),
      );
    });
    this.load();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.list({ page: String(this.page()), page_size: String(this.pageSize) }).subscribe({
      next: (res) => {
        this.items.set(unwrapList(res));
        this.total.set(unwrapCount(res));
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  submit(): void {
    if (this.form.invalid) return;
    if (this.needsProducteurChoice && !this.form.controls.producteur.value) {
      this.errorMessage.set('Veuillez sélectionner le producteur concerné.');
      return;
    }
    this.saving.set(true);
    this.errorMessage.set('');
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
        this.errorMessage.set(toApiError(err).message);
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
        this.toast.error(toApiError(err).message);
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
        this.toast.success(d.kind === 'valider' ? 'Demande de certification acceptée' : 'Demande refusée');
        this.load();
      },
      error: (err) => {
        this.dialogLoading.set(false);
        this.actionId.set(null);
        this.toast.error(toApiError(err).message);
      },
    });
  }
}

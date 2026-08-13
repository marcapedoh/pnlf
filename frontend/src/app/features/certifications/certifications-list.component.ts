import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { toApiError } from '../../core/http/api-error.util';
import { AuthService } from '../../core/auth/auth.service';
import { unwrapList } from '../../core/models/common.model';
import { Certification, STATUT_CERTIFICATION_LABELS } from '../../core/models/certification.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { CertificationsService } from '../../core/services/certifications.service';
import { certificationStatusTone } from '../../core/ui/status-tone.util';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { SelectFieldComponent, SelectOption } from '../../design-system/select-field/select-field.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { ToastService } from '../../design-system/toast/toast.service';

@Component({
  selector: 'app-certifications-list',
  imports: [ReactiveFormsModule, DatePipe, CardComponent, StatusBadgeComponent, ButtonComponent, EmptyStateComponent, SelectFieldComponent, AlertBannerComponent],
  templateUrl: './certifications-list.component.html',
  styleUrl: './certifications-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CertificationsListComponent {
  private readonly service = inject(CertificationsService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);

  readonly items = signal<Certification[]>([]);
  readonly loading = signal(true);
  readonly types = signal<SelectOption[]>([]);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly statutLabels = STATUT_CERTIFICATION_LABELS;
  readonly tone = certificationStatusTone;

  readonly canRequest = this.auth.hasRole(
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
  );

  readonly form = this.fb.nonNullable.group({
    type_certification: ['', Validators.required],
    date_demande: [new Date().toISOString().slice(0, 10), Validators.required],
    observations: [''],
  });

  constructor() {
    this.service.types().subscribe((res) => {
      this.types.set(unwrapList(res).map((t) => ({ value: t.id, label: t.libelle })));
    });
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.list().subscribe({
      next: (res) => {
        this.items.set(unwrapList(res));
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  submit(): void {
    if (this.form.invalid) return;
    this.saving.set(true);
    this.errorMessage.set('');
    this.service.create(this.form.getRawValue()).subscribe({
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
}

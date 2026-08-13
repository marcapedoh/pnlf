import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { AuthService } from '../../core/auth/auth.service';
import { unwrapList } from '../../core/models/common.model';
import { Cooperative } from '../../core/models/producteur.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { CooperativesService } from '../../core/services/cooperatives.service';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { toApiError } from '../../core/http/api-error.util';

@Component({
  selector: 'app-cooperatives-list',
  imports: [ReactiveFormsModule, CardComponent, StatusBadgeComponent, ButtonComponent, EmptyStateComponent, TextFieldComponent, AlertBannerComponent],
  templateUrl: './cooperatives-list.component.html',
  styleUrl: './cooperatives-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CooperativesListComponent {
  private readonly service = inject(CooperativesService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);

  readonly items = signal<Cooperative[]>([]);
  readonly loading = signal(true);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');

  readonly canManage = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.COOPERATIVE,
  );

  readonly form = this.fb.nonNullable.group({
    code: ['', Validators.required],
    nom: ['', Validators.required],
    numero_agrement: [''],
    telephone: [''],
    email: [''],
    adresse: [''],
  });

  constructor() {
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
        this.form.reset();
        this.toast.success('Coopérative créée avec succès');
        this.load();
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }
}

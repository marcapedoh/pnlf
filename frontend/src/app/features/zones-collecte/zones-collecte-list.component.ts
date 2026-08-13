import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';

import { toApiError } from '../../core/http/api-error.util';
import { AuthService } from '../../core/auth/auth.service';
import { unwrapList } from '../../core/models/common.model';
import { ZoneCollecte } from '../../core/models/reference.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { ReferenceService } from '../../core/services/reference.service';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { SelectFieldComponent, SelectOption } from '../../design-system/select-field/select-field.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-zones-collecte-list',
  imports: [ReactiveFormsModule, CardComponent, ButtonComponent, EmptyStateComponent, TextFieldComponent, SelectFieldComponent, AlertBannerComponent],
  templateUrl: './zones-collecte-list.component.html',
  styleUrl: './zones-collecte-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ZonesCollecteListComponent {
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly http = inject(HttpClient);

  readonly items = signal<ZoneCollecte[]>([]);
  readonly loading = signal(true);
  readonly provinces = signal<SelectOption[]>([]);
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');

  readonly canManage = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );

  readonly form = this.fb.nonNullable.group({
    code: ['', Validators.required],
    libelle: ['', Validators.required],
    province: ['', Validators.required],
    description: [''],
  });

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.referenceService.zonesCollecte().subscribe({
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
    this.http.post(`${environment.apiUrl}/zones-collecte/`, this.form.getRawValue()).subscribe({
      next: () => {
        this.saving.set(false);
        this.showForm.set(false);
        this.form.reset();
        this.toast.success('Zone de collecte créée');
        this.load();
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }
}

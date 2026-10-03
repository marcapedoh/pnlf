import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import { ZoneCollecte } from '../../../core/models/reference.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { ReferenceService } from '../../../core/services/reference.service';
import { latitudeGabonValidator, longitudeGabonValidator } from '../../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { PnlfDatePipe } from '../../../shared/pipes/format.pipes';

@Component({
  selector: 'app-zone-collecte-detail',
  imports: [
    RouterLink,
    PnlfDatePipe,
    ReactiveFormsModule,
    CardComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    TextFieldComponent,
    SelectFieldComponent,
    AlertBannerComponent,
    ConfirmDialogComponent,
  ],
  templateUrl: './zone-collecte-detail.component.html',
  styleUrl: './zone-collecte-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ZoneCollecteDetailComponent {
  private readonly service = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly toast = inject(ToastService);
  private readonly fb = inject(FormBuilder);
  private readonly title = inject(Title);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly zone = signal<ZoneCollecte | null>(null);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly editing = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly provinces = signal<SelectOption[]>([]);
  readonly confirmToggle = signal(false);
  readonly toggling = signal(false);

  /** Modification et activation : administrateur uniquement. */
  readonly canManage = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR);

  readonly form = this.fb.nonNullable.group({
    libelle: ['', Validators.required],
    province: ['', Validators.required],
    description: [''],
    latitude: ['', latitudeGabonValidator],
    longitude: ['', longitudeGabonValidator],
  });

  readonly err = (name: 'libelle' | 'province' | 'latitude' | 'longitude', required?: string) =>
    controlError(this.form.controls[name], required);

  constructor() {
    this.service.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.zoneCollecte(this.id).subscribe({
      next: (z) => {
        this.zone.set(z);
        this.title.setTitle(`Zone ${z.libelle} | PFNL`);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.zone.set(null);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  startEdit(): void {
    const z = this.zone();
    if (!z) return;
    this.form.reset({
      libelle: z.libelle,
      province: z.province,
      description: z.description ?? '',
      latitude: z.latitude?.toString() ?? '',
      longitude: z.longitude?.toString() ?? '',
    });
    this.errorMessage.set('');
    this.editing.set(true);
  }

  cancelEdit(): void {
    this.editing.set(false);
    this.errorMessage.set('');
  }

  save(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }
    this.saving.set(true);
    const raw = this.form.getRawValue();
    const nombre = (v: string) => (v.trim() ? Number(v.trim().replace(',', '.')) : null);
    const payload = {
      ...raw,
      latitude: nombre(raw.latitude),
      longitude: nombre(raw.longitude),
    };
    this.service.modifierZoneCollecte(this.id, payload).subscribe({
      next: (z) => {
        this.zone.set(z);
        this.saving.set(false);
        this.editing.set(false);
        this.toast.success('Zone de collecte mise à jour');
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
      },
    });
  }

  basculerActif(): void {
    const z = this.zone();
    if (!z) return;
    this.toggling.set(true);
    this.service.modifierZoneCollecte(this.id, { actif: !z.actif }).subscribe({
      next: (maj) => {
        this.zone.set(maj);
        this.toggling.set(false);
        this.confirmToggle.set(false);
        this.toast.success(maj.actif ? 'Zone réactivée' : 'Zone désactivée');
      },
      error: (err) => {
        this.toggling.set(false);
        this.confirmToggle.set(false);
        this.toast.error('Modification impossible', toApiError(err).message);
      },
    });
  }

  mapsUrl(lat: number, lon: number): string {
    return `https://www.google.com/maps?q=${lat},${lon}`;
  }
}

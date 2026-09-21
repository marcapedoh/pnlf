import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import { ZoneCollecte } from '../../../core/models/reference.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { ReferenceService } from '../../../core/services/reference.service';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-zone-collecte-detail',
  imports: [
    RouterLink,
    DatePipe,
    ReactiveFormsModule,
    CardComponent,
    ButtonComponent,
    SkeletonComponent,
    EmptyStateComponent,
    TextFieldComponent,
    SelectFieldComponent,
  ],
  templateUrl: './zone-collecte-detail.component.html',
  styleUrl: './zone-collecte-detail.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ZoneCollecteDetailComponent {
  private readonly service = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);
  private readonly fb = inject(FormBuilder);

  readonly id = this.route.snapshot.paramMap.get('id')!;
  readonly zone = signal<ZoneCollecte | null>(null);
  readonly loading = signal(true);
  readonly editing = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly provinces = signal<SelectOption[]>([]);

  readonly canManage = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );

  readonly form = this.fb.nonNullable.group({
    libelle: ['', Validators.required],
    province: ['', Validators.required],
    description: [''],
    latitude: [''],
    longitude: [''],
  });

  constructor() {
    this.service.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.service.zoneCollecte(this.id).subscribe({
      next: (z) => {
        this.zone.set(z);
        this.loading.set(false);
      },
      error: () => {
        this.loading.set(false);
        this.router.navigate(['/app/zones-collecte']);
      },
    });
  }

  startEdit(): void {
    const z = this.zone();
    if (!z) return;
    this.form.setValue({
      libelle: z.libelle,
      province: z.province,
      description: z.description ?? '',
      latitude: z.latitude?.toString() ?? '',
      longitude: z.longitude?.toString() ?? '',
    });
    this.editing.set(true);
  }

  cancelEdit(): void {
    this.editing.set(false);
    this.errorMessage.set('');
  }

  save(): void {
    if (this.form.invalid) return;
    this.saving.set(true);
    this.errorMessage.set('');
    const raw = this.form.getRawValue();
    const payload = {
      ...raw,
      latitude: raw.latitude ? Number(raw.latitude) : null,
      longitude: raw.longitude ? Number(raw.longitude) : null,
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
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }

  mapsUrl(lat: number, lon: number): string {
    return `https://www.google.com/maps?q=${lat},${lon}`;
  }
}

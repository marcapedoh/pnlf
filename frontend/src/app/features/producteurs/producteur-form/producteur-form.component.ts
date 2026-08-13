import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import { Cooperative, Producteur, TypeActeur } from '../../../core/models/producteur.model';
import { CooperativesService } from '../../../core/services/cooperatives.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

@Component({
  selector: 'app-producteur-form',
  imports: [
    ReactiveFormsModule,
    RouterLink,
    CardComponent,
    TextFieldComponent,
    SelectFieldComponent,
    ButtonComponent,
    AlertBannerComponent,
  ],
  templateUrl: './producteur-form.component.html',
  styleUrl: './producteur-form.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ProducteurFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly service = inject(ProducteursService);
  private readonly referenceService = inject(ReferenceService);
  private readonly cooperativesService = inject(CooperativesService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);

  readonly producteurId = this.route.snapshot.paramMap.get('id');
  readonly isEdit = !!this.producteurId;

  readonly loading = signal(false);
  readonly submitted = signal(false);
  readonly errorMessage = signal('');

  readonly provinces = signal<SelectOption[]>([]);
  readonly departements = signal<SelectOption[]>([]);
  readonly villages = signal<SelectOption[]>([]);
  readonly cooperatives = signal<SelectOption[]>([]);

  readonly typeActeurOptions: SelectOption[] = [
    { value: 'PRODUCTEUR', label: 'Producteur' },
    { value: 'COLLECTEUR', label: 'Collecteur' },
  ];

  readonly form = this.fb.nonNullable.group({
    nom: ['', Validators.required],
    prenoms: ['', Validators.required],
    type_acteur: ['PRODUCTEUR', Validators.required],
    date_naissance: [''],
    telephone: [''],
    email: [''],
    communaute: [''],
    province: ['', Validators.required],
    departement: [''],
    village: [''],
    cooperative: [''],
    latitude: [''],
    longitude: [''],
    notes: [''],
  });

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.cooperativesService.list().subscribe((res) => {
      this.cooperatives.set(unwrapList(res).map((c: Cooperative) => ({ value: c.id, label: c.nom })));
    });

    this.form.controls.province.valueChanges.subscribe((provinceId) => {
      this.departements.set([]);
      this.villages.set([]);
      this.form.patchValue({ departement: '', village: '' }, { emitEvent: false });
      if (provinceId) {
        this.referenceService.departements(provinceId).subscribe((res) => {
          this.departements.set(unwrapList(res).map((d) => ({ value: d.id, label: d.nom })));
        });
      }
    });

    this.form.controls.departement.valueChanges.subscribe((departementId) => {
      this.villages.set([]);
      this.form.patchValue({ village: '' }, { emitEvent: false });
      if (departementId) {
        this.referenceService.villages(departementId).subscribe((res) => {
          this.villages.set(unwrapList(res).map((v) => ({ value: v.id, label: v.nom })));
        });
      }
    });

    if (this.isEdit && this.producteurId) {
      this.loading.set(true);
      this.service.get(this.producteurId).subscribe((p) => {
        this.form.patchValue({
          nom: p.nom,
          prenoms: p.prenoms,
          type_acteur: p.type_acteur,
          date_naissance: p.date_naissance ?? '',
          telephone: p.telephone ?? '',
          email: p.email ?? '',
          communaute: p.communaute ?? '',
          province: p.province,
          departement: p.departement ?? '',
          village: p.village ?? '',
          cooperative: p.cooperative ?? '',
          latitude: p.latitude != null ? String(p.latitude) : '',
          longitude: p.longitude != null ? String(p.longitude) : '',
          notes: p.notes ?? '',
        });
        this.loading.set(false);
      });
    }
  }

  submit(): void {
    this.submitted.set(true);
    this.errorMessage.set('');
    if (this.form.invalid) return;

    const raw = this.form.getRawValue();
    const payload: Partial<Producteur> = {
      ...raw,
      type_acteur: raw.type_acteur as TypeActeur,
      departement: raw.departement || null,
      village: raw.village || null,
      cooperative: raw.cooperative || null,
      date_naissance: raw.date_naissance || null,
      latitude: raw.latitude ? Number(raw.latitude) : null,
      longitude: raw.longitude ? Number(raw.longitude) : null,
    };

    this.loading.set(true);
    const request$ = this.isEdit
      ? this.service.update(this.producteurId!, payload)
      : this.service.create(payload);

    request$.subscribe({
      next: (res) => {
        this.loading.set(false);
        this.toast.success(this.isEdit ? 'Fiche mise à jour' : 'Fiche enregistrée');
        this.router.navigate(['/app/producteurs', res.id]);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }
}

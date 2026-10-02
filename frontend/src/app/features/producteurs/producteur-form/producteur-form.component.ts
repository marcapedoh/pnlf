import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { todayIso } from '../../../core/format/format.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import { Cooperative, Producteur, TypeActeur } from '../../../core/models/producteur.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { CooperativesService } from '../../../core/services/cooperatives.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { ReferenceService } from '../../../core/services/reference.service';
import {
  datePastValidator,
  latitudeGabonValidator,
  longitudeGabonValidator,
  normaliserTelephone,
  telephoneValidator,
} from '../../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { SpinnerComponent } from '../../../design-system/spinner/spinner.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

const R = RoleUtilisateur;
/** Champs privés que l'API n'envoie qu'aux agents et au titulaire de la fiche. */
const CHAMPS_PRIVES = ['telephone', 'email', 'date_naissance'] as const;

type FormKey = 'nom' | 'prenoms' | 'type_acteur' | 'date_naissance' | 'telephone' | 'email' | 'communaute'
  | 'province' | 'departement' | 'village' | 'cooperative' | 'latitude' | 'longitude' | 'notes';

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
    SpinnerComponent,
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
  private readonly auth = inject(AuthService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);
  private readonly title = inject(Title);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly producteurId = this.route.snapshot.paramMap.get('id');
  readonly isEdit = !!this.producteurId;
  readonly today = todayIso();

  readonly loading = signal(false);
  readonly loadingFiche = signal(this.isEdit);
  readonly loadError = signal('');
  readonly errorMessage = signal('');

  /** Rattachement à une coopérative : modifiable uniquement par l'administration. */
  readonly canEditCooperative = this.auth.hasRole(R.ADMINISTRATEUR, R.AGENT_MINISTERE);
  readonly isCooperativeRole = this.auth.hasRole(R.COOPERATIVE);
  readonly isAgent = this.auth.hasRole(R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER);
  /** Champs privés effectivement renvoyés par l'API pour cette fiche (tous en création). */
  readonly champsLisibles = signal<Set<string>>(new Set(CHAMPS_PRIVES));
  readonly cooperativeNom = signal<string | null>(null);

  readonly provinces = signal<SelectOption[]>([]);
  readonly departements = signal<SelectOption[]>([]);
  readonly villages = signal<SelectOption[]>([]);
  readonly cooperatives = signal<SelectOption[]>([]);
  readonly locatingGps = signal(false);
  readonly gpsError = signal('');

  readonly typeActeurOptions: SelectOption[] = [
    { value: 'PRODUCTEUR', label: 'Producteur' },
    { value: 'COLLECTEUR', label: 'Collecteur' },
  ];

  readonly form = this.fb.nonNullable.group({
    nom: ['', Validators.required],
    prenoms: ['', Validators.required],
    type_acteur: ['PRODUCTEUR', Validators.required],
    date_naissance: ['', datePastValidator],
    telephone: ['', telephoneValidator],
    email: ['', Validators.email],
    communaute: [''],
    province: ['', Validators.required],
    departement: [''],
    village: [''],
    cooperative: [''],
    latitude: ['', latitudeGabonValidator],
    longitude: ['', longitudeGabonValidator],
    notes: [''],
  });

  readonly err = (name: FormKey, required?: string) => controlError(this.form.controls[name], required);

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    if (this.canEditCooperative || (this.isCooperativeRole && !this.isEdit)) {
      this.cooperativesService.list({ page_size: 200 }).subscribe((res) => {
        const coops = unwrapList(res);
        this.cooperatives.set(coops.map((c: Cooperative) => ({ value: c.id, label: c.nom })));
        if (this.isCooperativeRole && coops[0]) {
          this.form.patchValue({ cooperative: coops[0].id });
          this.cooperativeNom.set(coops[0].nom);
        }
      });
    }

    this.form.controls.province.valueChanges.pipe(takeUntilDestroyed()).subscribe((provinceId) => {
      this.departements.set([]);
      this.villages.set([]);
      this.form.patchValue({ departement: '', village: '' }, { emitEvent: false });
      if (this.form.controls.province.dirty) {
        this.form.controls.departement.markAsDirty();
        this.form.controls.village.markAsDirty();
      }
      if (provinceId) {
        this.referenceService.departements(provinceId).subscribe((res) => {
          this.departements.set(unwrapList(res).map((d) => ({ value: d.id, label: d.nom })));
        });
      }
    });

    this.form.controls.departement.valueChanges.pipe(takeUntilDestroyed()).subscribe((departementId) => {
      this.villages.set([]);
      this.form.patchValue({ village: '' }, { emitEvent: false });
      if (this.form.controls.departement.dirty) this.form.controls.village.markAsDirty();
      if (departementId) {
        this.referenceService.villages(departementId).subscribe((res) => {
          this.villages.set(unwrapList(res).map((v) => ({ value: v.id, label: v.nom })));
        });
      }
    });

    if (this.isEdit && this.producteurId) {
      this.loadFiche(this.producteurId);
    }
  }

  isLisible(champ: string): boolean {
    return this.champsLisibles().has(champ);
  }

  /** Les notes d'instruction ne sont modifiables que par les agents (ou saisies à la création). */
  get showNotes(): boolean {
    return !this.isEdit || this.isAgent;
  }

  loadFiche(id: string): void {
    this.loadingFiche.set(true);
    this.loadError.set('');
    this.service.get(id).subscribe({
      next: (p) => {
        this.champsLisibles.set(new Set(CHAMPS_PRIVES.filter((c) => c in p)));
        this.cooperativeNom.set(p.cooperative_nom ?? null);
        this.title.setTitle(`Modifier la fiche de ${p.prenoms} ${p.nom} | PFNL`);
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
        this.form.markAsPristine();
        this.loadingFiche.set(false);
      },
      error: (err) => {
        this.loadingFiche.set(false);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  useCurrentPosition(): void {
    if (!('geolocation' in navigator)) {
      this.gpsError.set("La géolocalisation n'est pas disponible sur cet appareil.");
      return;
    }
    this.gpsError.set('');
    this.locatingGps.set(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.form.patchValue({
          latitude: position.coords.latitude.toFixed(7),
          longitude: position.coords.longitude.toFixed(7),
        });
        this.form.controls.latitude.markAsDirty();
        this.form.controls.longitude.markAsDirty();
        this.form.controls.latitude.markAsTouched();
        this.form.controls.longitude.markAsTouched();
        this.locatingGps.set(false);
      },
      () => {
        this.gpsError.set('Impossible de récupérer votre position. Vérifiez les autorisations de localisation.');
        this.locatingGps.set(false);
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  private valeurApi(key: FormKey, raw: ReturnType<typeof this.form.getRawValue>): unknown {
    switch (key) {
      case 'type_acteur':
        return raw.type_acteur as TypeActeur;
      case 'departement':
      case 'village':
      case 'cooperative':
      case 'date_naissance':
        return raw[key] || null;
      case 'latitude':
      case 'longitude':
        return raw[key] ? Number(String(raw[key]).replace(',', '.')) : null;
      case 'telephone':
        return raw.telephone ? normaliserTelephone(raw.telephone) : null;
      case 'email':
        return raw.email.trim() || null;
      default:
        return raw[key];
    }
  }

  /** Clés envoyées : toutes en création, uniquement les champs modifiés en édition. */
  private clesAEnvoyer(): FormKey[] {
    const keys = Object.keys(this.form.controls) as FormKey[];
    return keys.filter((key) => {
      if (key === 'cooperative' && !this.canEditCooperative && !(this.isCooperativeRole && !this.isEdit)) return false;
      if (key === 'notes' && !this.showNotes) return false;
      if ((CHAMPS_PRIVES as readonly string[]).includes(key) && !this.isLisible(key)) return false;
      return !this.isEdit || this.form.controls[key].dirty;
    });
  }

  submit(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }

    const raw = this.form.getRawValue();
    const keys = this.clesAEnvoyer();
    if (this.isEdit && keys.length === 0) {
      this.toast.info('Aucune modification à enregistrer');
      this.router.navigate(['/app/producteurs', this.producteurId]);
      return;
    }
    const payload: Record<string, unknown> = {};
    keys.forEach((key) => (payload[key] = this.valeurApi(key, raw)));

    this.loading.set(true);
    const request$ = this.isEdit
      ? this.service.update(this.producteurId!, payload as Partial<Producteur>)
      : this.service.create(payload as Partial<Producteur>);

    request$.subscribe({
      next: (res) => {
        this.loading.set(false);
        this.form.markAsPristine();
        this.toast.success(this.isEdit ? 'Fiche mise à jour' : 'Fiche enregistrée');
        this.router.navigate(['/app/producteurs', res.id]);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
      },
    });
  }
}

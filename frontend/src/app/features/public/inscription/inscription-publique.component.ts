import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { toApiError } from '../../../core/http/api-error.util';
import { TypeDemandeInscription } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';

const TYPES_VALIDES: TypeDemandeInscription[] = ['PRODUCTEUR', 'COLLECTEUR', 'COOPERATIVE', 'ACHETEUR'];

function motsDePasseIdentiques(group: AbstractControl): ValidationErrors | null {
  const password = group.get('password')?.value;
  const confirmation = group.get('password_confirmation')?.value;
  if (password && confirmation && password !== confirmation) {
    return { mismatch: true };
  }
  return null;
}

@Component({
  selector: 'app-inscription-publique',
  imports: [
    ReactiveFormsModule,
    RouterLink,
    CardComponent,
    TextFieldComponent,
    SelectFieldComponent,
    ButtonComponent,
    AlertBannerComponent,
    IconComponent,
  ],
  templateUrl: './inscription-publique.component.html',
  styleUrl: './inscription-publique.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class InscriptionPubliqueComponent {
  private readonly fb = inject(FormBuilder);
  private readonly publicService = inject(PublicService);
  private readonly route = inject(ActivatedRoute);

  readonly types: { value: TypeDemandeInscription; label: string; description: string; icon: 'leaf' | 'map-pin' | 'users' | 'shopping-bag' }[] = [
    { value: 'PRODUCTEUR', label: 'Producteur', description: 'Vous cultivez ou exploitez des PFNL de façon régulière.', icon: 'leaf' },
    { value: 'COLLECTEUR', label: 'Collecteur / récolteur', description: 'Vous collectez des PFNL en forêt.', icon: 'map-pin' },
    { value: 'COOPERATIVE', label: 'Coopérative', description: 'Vous représentez un groupement de producteurs.', icon: 'users' },
    { value: 'ACHETEUR', label: 'Acheteur', description: 'Vous achetez des PFNL et souhaitez discuter avec les acteurs.', icon: 'shopping-bag' },
  ];

  readonly provinces = signal<SelectOption[]>([]);
  readonly departements = signal<SelectOption[]>([]);
  readonly villages = signal<SelectOption[]>([]);

  readonly photoPreview = signal<string | null>(null);
  private photoFile: File | null = null;

  readonly documentCniName = signal<string | null>(null);
  readonly documentFicheCircuitName = signal<string | null>(null);
  readonly documentAgrementName = signal<string | null>(null);
  private documentCniFile: File | null = null;
  private documentFicheCircuitFile: File | null = null;
  private documentAgrementFile: File | null = null;

  readonly loading = signal(false);
  readonly submitted = signal(false);
  readonly errorMessage = signal('');
  readonly photoError = signal('');
  readonly documentCniError = signal('');
  readonly success = signal<{ email: string; numero_dossier?: string } | null>(null);
  readonly step = signal(1);
  readonly loginQuery: Record<string, string> = {};

  readonly gpsLoading = signal(false);
  readonly gpsError = signal('');
  readonly gpsCaptured = signal(false);
  readonly today = new Date().toISOString().slice(0, 10);

  readonly form = this.fb.nonNullable.group(
    {
      type_demande: this.fb.nonNullable.control<TypeDemandeInscription>('PRODUCTEUR', Validators.required),
      nom: ['', Validators.required],
      prenoms: [''],
      email: ['', [Validators.required, Validators.email]],
      telephone: ['', [Validators.required, Validators.minLength(6)]],
      date_naissance: [''],
      password: ['', [Validators.required, Validators.minLength(8)]],
      password_confirmation: ['', Validators.required],
      province: [''],
      departement: [''],
      village: [''],
      communaute: [''],
      latitude: [''],
      longitude: [''],
      adresse: [''],
      numero_agrement: [''],
      message: [''],
      accepte_conditions: [false, Validators.requiredTrue],
      site_web: [''],
    },
    { validators: motsDePasseIdentiques },
  );

  constructor() {
    const typeParam = this.route.snapshot.queryParamMap.get('type');
    const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl');
    if (returnUrl) this.loginQuery['returnUrl'] = returnUrl;
    if (typeParam && TYPES_VALIDES.includes(typeParam as TypeDemandeInscription)) {
      this.selectType(typeParam as TypeDemandeInscription);
    }

    this.publicService.provinces().subscribe((res) => {
      this.provinces.set(res.map((p) => ({ value: p.id, label: p.nom })));
    });

    this.form.controls.province.valueChanges.subscribe((provinceId) => {
      this.departements.set([]);
      this.villages.set([]);
      this.form.patchValue({ departement: '', village: '' }, { emitEvent: false });
      if (provinceId) {
        this.publicService.departements(provinceId).subscribe((res) => {
          this.departements.set(res.map((d) => ({ value: d.id, label: d.nom })));
        });
      }
    });

    this.form.controls.departement.valueChanges.subscribe((departementId) => {
      this.villages.set([]);
      this.form.patchValue({ village: '' }, { emitEvent: false });
      if (departementId) {
        this.publicService.villages(departementId).subscribe((res) => {
          this.villages.set(res.map((v) => ({ value: v.id, label: v.nom })));
        });
      }
    });
  }

  get isCooperative(): boolean {
    return this.form.controls.type_demande.value === 'COOPERATIVE';
  }

  get isAcheteur(): boolean {
    return this.form.controls.type_demande.value === 'ACHETEUR';
  }

  /** Producteur/collecteur : seuls ces profils portent une fiche avec date de naissance et GPS. */
  get isPersonne(): boolean {
    const t = this.form.controls.type_demande.value;
    return t === 'PRODUCTEUR' || t === 'COLLECTEUR';
  }

  selectType(type: TypeDemandeInscription): void {
    this.form.patchValue({ type_demande: type });
    const province = this.form.controls.province;
    if (type === 'ACHETEUR') {
      province.clearValidators();
    } else {
      province.setValidators(Validators.required);
    }
    province.updateValueAndValidity({ emitEvent: false });

    const dateNaissance = this.form.controls.date_naissance;
    if (type === 'PRODUCTEUR' || type === 'COLLECTEUR') {
      dateNaissance.setValidators(Validators.required);
    } else {
      dateNaissance.clearValidators();
    }
    dateNaissance.updateValueAndValidity({ emitEvent: false });
  }

  nextStep(): void {
    this.submitted.set(true);
    this.errorMessage.set('');
    if (this.step() === 1) {
      if (!this.isAcheteur && !this.photoFile) this.photoError.set('Merci d’ajouter une photo.');
      if (!this.isAcheteur && !this.documentCniFile) {
        this.documentCniError.set("La copie de votre pièce d'identité (CNI) est requise.");
      }
      const identityOk =
        this.form.controls.nom.valid &&
        this.form.controls.email.valid &&
        this.form.controls.telephone.valid &&
        this.form.controls.password.valid &&
        !this.form.errors?.['mismatch'] &&
        (this.isCooperative || !!this.form.controls.prenoms.value) &&
        (!this.isPersonne || this.form.controls.date_naissance.valid);
      if (
        !identityOk ||
        (!this.isAcheteur && (!this.photoFile || !this.documentCniFile))
      ) {
        this.errorMessage.set(
          this.isAcheteur
            ? 'Complétez l’identité et le mot de passe avant de continuer.'
            : "Complétez l’identité, la photo, la pièce d'identité et le mot de passe avant de continuer.",
        );
        return;
      }
      this.submitted.set(false);
      this.step.set(2);
      return;
    }
    if (this.step() === 2) {
      if (!this.isAcheteur && this.form.controls.province.invalid) {
        this.errorMessage.set('Indiquez votre province.');
        return;
      }
      this.submitted.set(false);
      this.step.set(3);
    }
  }

  prevStep(): void {
    this.errorMessage.set('');
    this.step.update((s) => Math.max(1, s - 1));
  }

  obtenirPosition(): void {
    this.gpsError.set('');
    if (!('geolocation' in navigator)) {
      this.gpsError.set("La géolocalisation n'est pas disponible sur cet appareil.");
      return;
    }
    this.gpsLoading.set(true);
    navigator.geolocation.getCurrentPosition(
      (position) => {
        this.form.patchValue({
          latitude: position.coords.latitude.toFixed(7),
          longitude: position.coords.longitude.toFixed(7),
        });
        this.gpsCaptured.set(true);
        this.gpsLoading.set(false);
      },
      (error) => {
        this.gpsLoading.set(false);
        this.gpsCaptured.set(false);
        this.gpsError.set(
          error.code === error.PERMISSION_DENIED
            ? 'Localisation refusée. Vous pouvez continuer sans cette information.'
            : 'Impossible de récupérer votre position pour le moment.',
        );
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  onPhotoSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) {
      this.photoError.set('Image trop volumineuse (5 Mo maximum).');
      this.photoFile = null;
      this.photoPreview.set(null);
      input.value = '';
      return;
    }
    if (!file.type.startsWith('image/')) {
      this.photoError.set('Fichier image invalide (JPEG/PNG/WEBP attendu).');
      this.photoFile = null;
      this.photoPreview.set(null);
      input.value = '';
      return;
    }
    this.photoError.set('');
    this.photoFile = file;
    const reader = new FileReader();
    reader.onload = () => this.photoPreview.set(reader.result as string);
    reader.readAsDataURL(file);
  }

  private validerFichierDocument(file: File): string {
    const TYPES = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];
    if (file.size > 8 * 1024 * 1024) return 'Fichier trop volumineux (8 Mo maximum).';
    if (!TYPES.includes(file.type)) return 'Formats acceptés : PDF, JPEG, PNG.';
    return '';
  }

  onDocumentCniSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    const err = this.validerFichierDocument(file);
    if (err) {
      this.documentCniError.set(err);
      this.documentCniFile = null;
      this.documentCniName.set(null);
      input.value = '';
      return;
    }
    this.documentCniError.set('');
    this.documentCniFile = file;
    this.documentCniName.set(file.name);
  }

  onDocumentFicheCircuitSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    const err = this.validerFichierDocument(file);
    if (err) {
      this.errorMessage.set(err);
      input.value = '';
      return;
    }
    this.documentFicheCircuitFile = file;
    this.documentFicheCircuitName.set(file.name);
  }

  onDocumentAgrementSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    const err = this.validerFichierDocument(file);
    if (err) {
      this.errorMessage.set(err);
      input.value = '';
      return;
    }
    this.documentAgrementFile = file;
    this.documentAgrementName.set(file.name);
  }

  submit(): void {
    this.submitted.set(true);
    this.errorMessage.set('');

    if (!this.isAcheteur && !this.photoFile) {
      this.photoError.set('Merci d’ajouter une photo.');
    }
    if (!this.isAcheteur && !this.documentCniFile) {
      this.documentCniError.set("La copie de votre pièce d'identité (CNI) est requise.");
    }
    if (
      this.form.invalid ||
      (!this.isAcheteur && (!this.photoFile || !this.documentCniFile))
    ) {
      this.errorMessage.set('Merci de vérifier les champs signalés en rouge ci-dessous.');
      return;
    }

    const raw = this.form.getRawValue();
    this.loading.set(true);
    this.publicService
      .inscrire({
        type_demande: raw.type_demande,
        nom: raw.nom,
        prenoms: raw.prenoms || undefined,
        email: raw.email,
        telephone: raw.telephone,
        date_naissance: raw.date_naissance || undefined,
        latitude: raw.latitude ? Number(raw.latitude) : undefined,
        longitude: raw.longitude ? Number(raw.longitude) : undefined,
        password: raw.password,
        password_confirmation: raw.password_confirmation,
        photo: this.photoFile || undefined,
        document_cni: this.documentCniFile || undefined,
        document_fiche_circuit: this.documentFicheCircuitFile || undefined,
        document_agrement_nagoya: this.documentAgrementFile || undefined,
        province: raw.province || undefined,
        departement: raw.departement || undefined,
        village: raw.village || undefined,
        communaute: raw.communaute || undefined,
        adresse: raw.adresse || undefined,
        numero_agrement: raw.numero_agrement || undefined,
        message: raw.message || undefined,
        accepte_conditions: raw.accepte_conditions,
        site_web: raw.site_web || undefined,
      })
      .subscribe({
        next: (res) => {
          this.loading.set(false);
          this.success.set({ email: res.email, numero_dossier: res.numero_dossier });
        },
        error: (err) => {
          this.loading.set(false);
          this.errorMessage.set(toApiError(err).message);
        },
      });
  }
}

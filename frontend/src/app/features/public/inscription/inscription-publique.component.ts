import { ChangeDetectionStrategy, Component, ElementRef, ViewChild, inject, signal } from '@angular/core';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { applyServerErrors, controlError, focusFirstInvalid } from '../../../core/forms/form-errors.util';
import { todayIso } from '../../../core/format/format.util';
import { toApiError } from '../../../core/http/api-error.util';
import { datePastValidator, normaliserTelephone, telephoneValidator } from '../../../core/validators/pnlf.validators';
import { TypeDemandeInscription } from '../../../core/models/public.model';
import { PublicService } from '../../../core/services/public.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';

const TYPES_VALIDES: TypeDemandeInscription[] = ['PRODUCTEUR', 'COLLECTEUR', 'COOPERATIVE', 'ACHETEUR'];

/** Étape du parcours où se trouve chaque champ (pour y revenir quand l'API le signale en erreur). */
const ETAPE_DU_CHAMP: Record<string, number> = {
  type_demande: 1,
  nom: 1,
  prenoms: 1,
  email: 1,
  telephone: 1,
  date_naissance: 1,
  password: 1,
  password_confirmation: 1,
  numero_agrement: 1,
  photo: 1,
  document_cni: 1,
  province: 2,
  departement: 2,
  village: 2,
  communaute: 2,
  latitude: 2,
  longitude: 2,
  adresse: 2,
};

const CHAMPS_ETAPE_1 = ['nom', 'prenoms', 'email', 'telephone', 'date_naissance', 'password', 'password_confirmation'];

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
  private readonly host = inject(ElementRef<HTMLElement>);

  @ViewChild('stepTitle') private stepTitle?: ElementRef<HTMLElement>;

  readonly types: { value: TypeDemandeInscription; label: string; description: string; icon: 'leaf' | 'map-pin' | 'users' | 'shopping-bag' }[] = [
    { value: 'PRODUCTEUR', label: 'Producteur', description: 'Vous cultivez ou exploitez des PFNL de façon régulière.', icon: 'leaf' },
    { value: 'COLLECTEUR', label: 'Collecteur', description: 'Vous collectez des PFNL en forêt.', icon: 'map-pin' },
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
  readonly today = todayIso();
  readonly stepTitles = ['Identité', 'Localisation', 'Confirmation'];

  readonly form = this.fb.nonNullable.group(
    {
      type_demande: this.fb.nonNullable.control<TypeDemandeInscription>('PRODUCTEUR', Validators.required),
      nom: ['', Validators.required],
      prenoms: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      telephone: ['', [Validators.required, telephoneValidator]],
      date_naissance: ['', [Validators.required, datePastValidator]],
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
    this.selectType(
      typeParam && TYPES_VALIDES.includes(typeParam as TypeDemandeInscription)
        ? (typeParam as TypeDemandeInscription)
        : 'PRODUCTEUR',
    );

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
      dateNaissance.setValidators([Validators.required, datePastValidator]);
    } else {
      dateNaissance.setValidators([datePastValidator]);
    }
    dateNaissance.updateValueAndValidity({ emitEvent: false });

    const prenoms = this.form.controls.prenoms;
    prenoms.setValidators(type === 'COOPERATIVE' ? [] : [Validators.required]);
    prenoms.updateValueAndValidity({ emitEvent: false });
  }

  err(champ: string): string {
    const requis: Record<string, string> = {
      nom: this.isCooperative ? 'Le nom de la coopérative est requis.' : 'Le nom est requis.',
      prenoms: 'Les prénoms sont requis.',
      email: 'L’adresse e-mail est requise.',
      telephone: 'Le numéro de téléphone est requis.',
      date_naissance: 'La date de naissance est requise.',
      password: 'Le mot de passe est requis.',
      password_confirmation: 'Confirmez votre mot de passe.',
      province: 'La province est requise.',
    };
    const control = this.form.get(champ);
    if (champ === 'password' && control?.errors?.['minlength'] && control.touched) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    return controlError(control, requis[champ]);
  }

  confirmationError(): string {
    const own = this.err('password_confirmation');
    if (own) return own;
    const c = this.form.controls.password_confirmation;
    return c.touched && this.form.errors?.['mismatch'] ? 'Les mots de passe ne correspondent pas.' : '';
  }

  private allerAEtape(n: number): void {
    this.step.set(n);
    setTimeout(() => this.stepTitle?.nativeElement.focus());
  }

  nextStep(): void {
    this.submitted.set(true);
    this.errorMessage.set('');
    if (this.step() === 1) {
      for (const champ of CHAMPS_ETAPE_1) this.form.get(champ)?.markAsTouched();
      if (!this.isAcheteur && !this.photoFile) this.photoError.set('Ajoutez une photo.');
      if (!this.isAcheteur && !this.documentCniFile) {
        this.documentCniError.set("La copie de votre pièce d'identité (CNI) est requise.");
      }
      const identityOk = CHAMPS_ETAPE_1.every((champ) => this.form.get(champ)?.valid) && !this.form.errors?.['mismatch'];
      if (!identityOk || (!this.isAcheteur && (!this.photoFile || !this.documentCniFile))) {
        this.errorMessage.set(
          this.isAcheteur
            ? 'Complétez les champs signalés avant de continuer.'
            : "Complétez les champs signalés, la photo et la pièce d'identité avant de continuer.",
        );
        focusFirstInvalid(this.host);
        return;
      }
      this.submitted.set(false);
      this.allerAEtape(2);
      return;
    }
    if (this.step() === 2) {
      this.form.controls.province.markAsTouched();
      if (!this.isAcheteur && this.form.controls.province.invalid) {
        this.errorMessage.set('Indiquez votre province.');
        focusFirstInvalid(this.host);
        return;
      }
      this.submitted.set(false);
      this.allerAEtape(3);
    }
  }

  prevStep(): void {
    this.errorMessage.set('');
    this.allerAEtape(Math.max(1, this.step() - 1));
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

    this.form.markAllAsTouched();
    if (!this.isAcheteur && !this.photoFile) {
      this.photoError.set('Ajoutez une photo.');
    }
    if (!this.isAcheteur && !this.documentCniFile) {
      this.documentCniError.set("La copie de votre pièce d'identité (CNI) est requise.");
    }
    if (this.form.invalid || (!this.isAcheteur && (!this.photoFile || !this.documentCniFile))) {
      const champEnErreur = Object.keys(this.form.controls).find((k) => this.form.get(k)?.invalid);
      const etape = Math.min(
        champEnErreur ? (ETAPE_DU_CHAMP[champEnErreur] ?? 3) : 3,
        !this.isAcheteur && (!this.photoFile || !this.documentCniFile) ? 1 : 3,
        this.form.errors?.['mismatch'] ? 1 : 3,
      );
      this.errorMessage.set('Vérifiez les champs signalés en rouge.');
      if (etape !== this.step()) this.allerAEtape(etape);
      else focusFirstInvalid(this.host);
      return;
    }

    const raw = this.form.getRawValue();
    this.loading.set(true);
    this.publicService
      .inscrire({
        type_demande: raw.type_demande,
        nom: raw.nom,
        prenoms: raw.prenoms || undefined,
        email: raw.email.trim(),
        telephone: normaliserTelephone(raw.telephone),
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
          this.afficherErreursServeur(toApiError(err));
        },
      });
  }

  /** Rattache les erreurs de l'API aux champs et revient à l'étape du premier champ concerné. */
  private afficherErreursServeur(apiError: ReturnType<typeof toApiError>): void {
    const champs = Object.keys(apiError.fieldErrors ?? {});
    const fichiers: Record<string, (m: string) => void> = {
      photo: (m) => this.photoError.set(m),
      document_cni: (m) => this.documentCniError.set(m),
    };
    for (const champ of champs) {
      const message = apiError.fieldErrors![champ].join(' ');
      fichiers[champ]?.(message);
    }
    const restants = applyServerErrors(this.form, apiError).filter(
      (m) => !champs.some((c) => fichiers[c] && apiError.fieldErrors![c].join(' ') === m),
    );
    const etapes = champs.map((c) => ETAPE_DU_CHAMP[c]).filter((e): e is number => !!e);
    this.submitted.set(true);
    if (etapes.length) {
      this.errorMessage.set(restants[0] ?? 'Certaines informations sont invalides. Corrigez les champs signalés.');
      const etape = Math.min(...etapes);
      if (etape !== this.step()) this.allerAEtape(etape);
      else focusFirstInvalid(this.host);
      return;
    }
    this.errorMessage.set(restants[0] ?? apiError.message);
  }
}

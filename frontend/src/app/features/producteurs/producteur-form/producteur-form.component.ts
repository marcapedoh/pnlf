import { ChangeDetectionStrategy, Component, DestroyRef, ElementRef, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Title } from '@angular/platform-browser';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { todayIso } from '../../../core/format/format.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { toApiError } from '../../../core/http/api-error.util';
import { unwrapList } from '../../../core/models/common.model';
import {
  Cooperative,
  DOCUMENTS_FICHE_PRODUCTEUR,
  DocumentInscription,
  TYPES_PIECE_IDENTITE,
  TypeActeur,
  TypeDocumentInscription,
} from '../../../core/models/producteur.model';
import { Produit } from '../../../core/models/reference.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { CooperativesService } from '../../../core/services/cooperatives.service';
import { ErreurGeolocalisation, GeolocalisationService } from '../../../core/services/geolocalisation.service';
import { ProducteurPayload, ProducteursService } from '../../../core/services/producteurs.service';
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
import { ConfirmDialogComponent } from '../../../design-system/confirm-dialog/confirm-dialog.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { SpinnerComponent } from '../../../design-system/spinner/spinner.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

const R = RoleUtilisateur;
/** Champs privés que l'API n'envoie qu'aux agents, au titulaire et à la coopérative de rattachement. */
const CHAMPS_PRIVES = ['telephone', 'email', 'date_naissance', 'type_piece_identite', 'numero_piece'] as const;

const PHOTO_MAX_OCTETS = 5 * 1024 * 1024;
const DOCUMENT_MAX_OCTETS = 8 * 1024 * 1024;
const PHOTO_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const DOCUMENT_TYPES = ['application/pdf', 'image/jpeg', 'image/png'];
const DOCUMENT_EXTENSIONS = ['pdf', 'jpg', 'jpeg', 'png'];

type FormKey = 'nom' | 'prenoms' | 'type_acteur' | 'date_naissance' | 'telephone' | 'email' | 'communaute'
  | 'province' | 'departement' | 'village' | 'cooperative' | 'latitude' | 'longitude' | 'notes'
  | 'type_piece_identite' | 'numero_piece' | 'produits';

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
    ConfirmDialogComponent,
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
  private readonly geolocalisation = inject(GeolocalisationService);
  private readonly destroyRef = inject(DestroyRef);

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
  readonly gpsPrecision = signal<number | null>(null);

  readonly typeActeurOptions: SelectOption[] = [
    { value: 'PRODUCTEUR', label: 'Producteur' },
    { value: 'COLLECTEUR', label: 'Collecteur' },
  ];
  readonly typePieceOptions: SelectOption[] = TYPES_PIECE_IDENTITE;

  /** Référentiel des produits et filtre de recherche de la liste à cocher. */
  readonly produitsReferentiel = signal<Produit[]>([]);
  readonly filtreProduits = signal('');
  readonly produitsFiltres = computed(() => {
    const terme = this.filtreProduits().trim().toLowerCase();
    const liste = this.produitsReferentiel();
    return terme ? liste.filter((p) => p.nom.toLowerCase().includes(terme)) : liste;
  });
  readonly produitsSelectionnes = signal<string[]>([]);
  private readonly produitsFiche = signal<{ id: string; nom: string }[]>([]);
  readonly nomsProduits = computed(() => {
    const noms = new Map([...this.produitsFiche(), ...this.produitsReferentiel()].map((p) => [p.id, p.nom]));
    return this.produitsSelectionnes().map((id) => ({ id, nom: noms.get(id) ?? 'Produit retiré du référentiel' }));
  });

  /** Photo d'identité et justificatifs : envoyés après l'enregistrement de la fiche. */
  readonly photoActuelle = signal<string | null>(null);
  readonly photoFichier = signal<File | null>(null);
  readonly photoApercu = signal<string | null>(null);
  readonly photoErreur = signal('');
  readonly documentsTypes = DOCUMENTS_FICHE_PRODUCTEUR;
  readonly documentsExistants = signal<DocumentInscription[]>([]);
  readonly documentsAEnvoyer = signal<Partial<Record<TypeDocumentInscription, File>>>({});
  readonly documentErreurs = signal<Partial<Record<TypeDocumentInscription, string>>>({});
  readonly documentASupprimer = signal<TypeDocumentInscription | null>(null);
  readonly suppressionEnCours = signal(false);
  /** Les justificatifs suivent la même règle de lecture que la pièce d'identité. */
  readonly peutGererDocuments = computed(() => this.champsLisibles().has('type_piece_identite'));
  readonly etapeEnvoi = signal('');

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
    type_piece_identite: [''],
    numero_piece: ['', Validators.maxLength(80)],
    produits: this.fb.nonNullable.control<string[]>([]),
  });

  readonly err = (name: FormKey, required?: string) => controlError(this.form.controls[name], required);

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.referenceService.produits().subscribe({
      next: (res) => this.produitsReferentiel.set(unwrapList(res)),
      error: () => this.produitsReferentiel.set([]),
    });
    this.destroyRef.onDestroy(() => this.libererApercu());
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
          type_piece_identite: p.type_piece_identite ?? '',
          numero_piece: p.numero_piece ?? '',
          produits: (p.produits ?? []).map((pr) => pr.id),
        });
        this.produitsFiche.set(p.produits ?? []);
        this.produitsSelectionnes.set((p.produits ?? []).map((pr) => pr.id));
        this.photoActuelle.set(p.photo_url ?? null);
        this.documentsExistants.set(p.documents ?? []);
        this.form.markAsPristine();
        this.loadingFiche.set(false);
      },
      error: (err) => {
        this.loadingFiche.set(false);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  async useCurrentPosition(): Promise<void> {
    this.gpsError.set('');
    this.gpsPrecision.set(null);
    this.locatingGps.set(true);
    try {
      const position = await this.geolocalisation.positionActuelle();
      this.form.patchValue({
        latitude: position.latitude.toFixed(7),
        longitude: position.longitude.toFixed(7),
      });
      for (const control of [this.form.controls.latitude, this.form.controls.longitude]) {
        control.markAsDirty();
        control.markAsTouched();
      }
      this.gpsPrecision.set(position.precisionMetres);
      if (this.form.controls.latitude.invalid || this.form.controls.longitude.invalid) {
        this.gpsError.set(
          'La position obtenue se situe hors du Gabon. Vérifiez la localisation de l’appareil ou saisissez les coordonnées manuellement.',
        );
      }
    } catch (err) {
      this.gpsError.set(
        err instanceof ErreurGeolocalisation
          ? err.message
          : 'Votre position est indisponible pour le moment. Saisissez les coordonnées manuellement.',
      );
    } finally {
      this.locatingGps.set(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Produits exploités
  // ---------------------------------------------------------------------------

  estProduitSelectionne(id: string): boolean {
    return this.produitsSelectionnes().includes(id);
  }

  basculerProduit(id: string): void {
    const actuels = this.produitsSelectionnes();
    const suivants = actuels.includes(id) ? actuels.filter((x) => x !== id) : [...actuels, id];
    if (suivants.length > 20) {
      this.toast.warning('Sélectionnez au plus 20 produits.');
      return;
    }
    this.produitsSelectionnes.set(suivants);
    this.form.controls.produits.setValue(suivants);
    this.form.controls.produits.markAsDirty();
  }

  definirPrincipal(id: string): void {
    const suivants = [id, ...this.produitsSelectionnes().filter((x) => x !== id)];
    this.produitsSelectionnes.set(suivants);
    this.form.controls.produits.setValue(suivants);
    this.form.controls.produits.markAsDirty();
  }

  // ---------------------------------------------------------------------------
  // Photo et justificatifs
  // ---------------------------------------------------------------------------

  choisirPhoto(event: Event): void {
    const input = event.target as HTMLInputElement;
    const fichier = input.files?.[0] ?? null;
    input.value = '';
    this.photoErreur.set('');
    if (!fichier) return;
    if (!PHOTO_TYPES.includes(fichier.type)) {
      this.photoErreur.set('Format non pris en charge : choisissez une image JPG, PNG ou WebP.');
      return;
    }
    if (fichier.size > PHOTO_MAX_OCTETS) {
      this.photoErreur.set('Image trop volumineuse : 5 Mo maximum.');
      return;
    }
    this.libererApercu();
    this.photoFichier.set(fichier);
    this.photoApercu.set(URL.createObjectURL(fichier));
  }

  retirerPhotoChoisie(): void {
    this.libererApercu();
    this.photoFichier.set(null);
  }

  private libererApercu(): void {
    const apercu = this.photoApercu();
    if (apercu) URL.revokeObjectURL(apercu);
    this.photoApercu.set(null);
  }

  documentExistant(type: TypeDocumentInscription): DocumentInscription | undefined {
    return this.documentsExistants().find((d) => d.type_document === type);
  }

  fichierChoisi(type: TypeDocumentInscription): File | undefined {
    return this.documentsAEnvoyer()[type];
  }

  peutSupprimerDocument(type: TypeDocumentInscription): boolean {
    return type !== 'CNI' || this.isAgent;
  }

  choisirDocument(type: TypeDocumentInscription, event: Event): void {
    const input = event.target as HTMLInputElement;
    const fichier = input.files?.[0] ?? null;
    input.value = '';
    if (!fichier) return;
    const extension = fichier.name.split('.').pop()?.toLowerCase() ?? '';
    let erreur = '';
    if (!DOCUMENT_EXTENSIONS.includes(extension) || (fichier.type && !DOCUMENT_TYPES.includes(fichier.type))) {
      erreur = 'Format non pris en charge : PDF, JPG ou PNG uniquement.';
    } else if (fichier.size > DOCUMENT_MAX_OCTETS) {
      erreur = 'Fichier trop volumineux : 8 Mo maximum.';
    }
    this.documentErreurs.update((e) => ({ ...e, [type]: erreur }));
    if (erreur) return;
    this.documentsAEnvoyer.update((d) => ({ ...d, [type]: fichier }));
  }

  annulerDocument(type: TypeDocumentInscription): void {
    this.documentsAEnvoyer.update((d) => {
      const copie = { ...d };
      delete copie[type];
      return copie;
    });
  }

  libelleDocument(type: TypeDocumentInscription | null): string {
    return this.documentsTypes.find((d) => d.type === type)?.libelle ?? 'ce document';
  }

  confirmerSuppressionDocument(): void {
    const type = this.documentASupprimer();
    if (!type || !this.producteurId) return;
    this.suppressionEnCours.set(true);
    this.service.supprimerDocument(this.producteurId, type).subscribe({
      next: (docs) => {
        this.documentsExistants.set(docs);
        this.suppressionEnCours.set(false);
        this.documentASupprimer.set(null);
        this.toast.success('Document supprimé');
      },
      error: (err) => {
        this.suppressionEnCours.set(false);
        this.documentASupprimer.set(null);
        this.toast.error(toApiError(err).message);
      },
    });
  }

  tailleLisible(octets: number): string {
    return octets >= 1024 * 1024 ? `${(octets / 1024 / 1024).toFixed(1).replace('.', ',')} Mo` : `${Math.ceil(octets / 1024)} Ko`;
  }

  /** Envoie la photo puis chaque justificatif ; renvoie la liste des échecs (messages en français). */
  private async envoyerPiecesJointes(id: string): Promise<string[]> {
    const echecs: string[] = [];
    const photo = this.photoFichier();
    if (photo) {
      this.etapeEnvoi.set('Envoi de la photo…');
      try {
        await firstValueFrom(this.service.uploadPhoto(id, photo));
        this.retirerPhotoChoisie();
      } catch (err) {
        echecs.push(`Photo : ${toApiError(err).message}`);
      }
    }
    for (const doc of this.documentsTypes) {
      const fichier = this.documentsAEnvoyer()[doc.type];
      if (!fichier) continue;
      this.etapeEnvoi.set(`Envoi du document « ${doc.libelle} »…`);
      try {
        const docs = await firstValueFrom(this.service.uploadDocument(id, doc.type, fichier));
        this.documentsExistants.set(docs);
        this.annulerDocument(doc.type);
      } catch (err) {
        echecs.push(`${doc.libelle} : ${toApiError(err).message}`);
      }
    }
    this.etapeEnvoi.set('');
    return echecs;
  }

  private get piecesJointesEnAttente(): boolean {
    return !!this.photoFichier() || Object.keys(this.documentsAEnvoyer()).length > 0;
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
      case 'type_piece_identite':
        return raw.type_piece_identite || null;
      case 'numero_piece':
        return raw.numero_piece.trim() || null;
      case 'produits':
        return this.produitsSelectionnes();
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
    if (this.isEdit && keys.length === 0 && !this.piecesJointesEnAttente) {
      this.toast.info('Aucune modification à enregistrer');
      this.router.navigate(['/app/producteurs', this.producteurId]);
      return;
    }
    const payload: Record<string, unknown> = {};
    keys.forEach((key) => (payload[key] = this.valeurApi(key, raw)));

    this.loading.set(true);
    const request$ = this.isEdit
      ? this.service.update(this.producteurId!, payload as ProducteurPayload)
      : this.service.create(payload as ProducteurPayload);

    request$.subscribe({
      next: async (res) => {
        this.form.markAsPristine();
        const echecs = await this.envoyerPiecesJointes(res.id);
        this.loading.set(false);
        if (echecs.length) {
          this.toast.warning(
            this.isEdit ? 'Fiche mise à jour, mais certaines pièces n’ont pas été enregistrées' : 'Fiche enregistrée, mais certaines pièces n’ont pas été enregistrées',
            `${echecs.join(' ')} Vous pouvez les déposer à nouveau en modifiant la fiche.`,
          );
        } else {
          this.toast.success(this.isEdit ? 'Fiche mise à jour' : 'Fiche enregistrée');
        }
        this.router.navigate(['/app/producteurs', res.id]);
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
      },
    });
  }
}

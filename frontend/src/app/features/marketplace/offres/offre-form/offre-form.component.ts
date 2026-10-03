import { ChangeDetectionStrategy, Component, ElementRef, computed, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Observable, of } from 'rxjs';

import { UNITE_OPTIONS } from '../../../../core/format/format.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../../core/forms/form-errors.util';
import { toApiError } from '../../../../core/http/api-error.util';
import { MODES_REMISE, MOYENS_PAIEMENT, MoyenPaiement } from '../../../../core/models/annonce.model';
import { unwrapList } from '../../../../core/models/common.model';
import { OffreDemande } from '../../../../core/models/notification.model';
import { CategorieProduit, Produit } from '../../../../core/models/reference.model';
import { MarketplaceService } from '../../../../core/services/marketplace.service';
import { ReferenceService } from '../../../../core/services/reference.service';
import { AlertBannerComponent } from '../../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../../design-system/button/button.component';
import { CardComponent } from '../../../../design-system/card/card.component';
import { ConfirmDialogComponent } from '../../../../design-system/confirm-dialog/confirm-dialog.component';
import { IconComponent } from '../../../../design-system/icon/icon.component';
import { SelectFieldComponent, SelectOption } from '../../../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../../../design-system/skeleton/skeleton.component';
import { TextFieldComponent } from '../../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../../design-system/toast/toast.service';
import { PnlfUnitePipe } from '../../../../shared/pipes/format.pipes';

const PHOTOS_MAX_DEFAUT = 4;
const PHOTO_MAX_BYTES = 5 * 1024 * 1024;
const TYPES_PHOTO = ['image/jpeg', 'image/png', 'image/webp'];
const STATUTS_FIGES = ['CLOTUREE', 'ANNULEE'];

interface PhotoExistante {
  url: string;
  numero: number;
}

function aujourdhui(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function nombre(valeur: string | number | null | undefined): number | null {
  const texte = String(valeur ?? '').trim().replace(',', '.');
  return texte ? Number(texte) : null;
}

/** Création et modification d'une annonce (offre ou demande), photos comprises. */
@Component({
  selector: 'app-offre-form',
  imports: [
    ReactiveFormsModule,
    RouterLink,
    PnlfUnitePipe,
    AlertBannerComponent,
    ButtonComponent,
    CardComponent,
    ConfirmDialogComponent,
    IconComponent,
    SelectFieldComponent,
    SkeletonComponent,
    TextFieldComponent,
  ],
  templateUrl: './offre-form.component.html',
  styleUrl: './offre-form.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffreFormComponent {
  private readonly service = inject(MarketplaceService);
  private readonly reference = inject(ReferenceService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);
  private readonly fb = inject(FormBuilder);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);

  readonly id = this.route.snapshot.paramMap.get('id');
  readonly edition = !!this.id;
  readonly loading = signal(this.edition);
  readonly loadError = signal('');
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly offre = signal<OffreDemande | null>(null);

  readonly categories = signal<CategorieProduit[]>([]);
  readonly produitsTous = signal<Produit[]>([]);
  readonly provinces = signal<SelectOption[]>([]);
  readonly unites = UNITE_OPTIONS;
  readonly modesRemise: SelectOption[] = MODES_REMISE.map((m) => ({ value: m.value, label: m.label }));
  readonly moyensPaiement = MOYENS_PAIEMENT;
  readonly dateMin = aujourdhui();

  readonly photosMax = signal(PHOTOS_MAX_DEFAUT);
  readonly photosExistantes = signal<PhotoExistante[]>([]);
  readonly nouvellesPhotos = signal<{ fichier: File; apercu: string }[]>([]);
  readonly photoError = signal('');
  readonly photoASupprimer = signal<PhotoExistante | null>(null);
  readonly suppressionPhoto = signal(false);
  readonly placesPhotos = computed(
    () => this.photosMax() - this.photosExistantes().length - this.nouvellesPhotos().length,
  );

  private expireInitiale = '';

  readonly form = this.fb.nonNullable.group({
    type_annonce: ['OFFRE' as 'OFFRE' | 'DEMANDE', Validators.required],
    titre: ['', [Validators.required, Validators.minLength(5), Validators.maxLength(200)]],
    categorie_id: [''],
    produit_id: ['', Validators.required],
    description: ['', Validators.maxLength(4000)],
    quantite: ['', Validators.min(0.001)],
    unite: ['KG'],
    prix_unitaire: ['', Validators.min(0)],
    prix_total: ['', Validators.min(0)],
    negociable: [false],
    conditionnement: ['', Validators.maxLength(150)],
    qualite: ['', Validators.maxLength(200)],
    certification_requise: [false],
    province_id: [''],
    localite: ['', Validators.maxLength(150)],
    disponible_du: [''],
    expire_at: [''],
    mode_remise: [''],
    modalites_livraison: ['', Validators.maxLength(1000)],
    moyens_paiement: [[] as MoyenPaiement[]],
    conditions_paiement: ['', Validators.maxLength(1000)],
    afficher_telephone: [false],
    afficher_email: [false],
  });

  private readonly categorieChoisie = toSignal(this.form.controls.categorie_id.valueChanges, { initialValue: '' });
  readonly typeAnnonce = toSignal(this.form.controls.type_annonce.valueChanges, { initialValue: 'OFFRE' as const });

  readonly categoriesOptions = computed<SelectOption[]>(() => {
    const libelles = new Map(this.categories().map((c) => [c.id, c.libelle]));
    return this.categories()
      .map((c) => ({ value: c.id, label: c.parent && libelles.has(c.parent) ? `${libelles.get(c.parent)} › ${c.libelle}` : c.libelle }))
      .sort((a, b) => a.label.localeCompare(b.label, 'fr'));
  });

  readonly produitsOptions = computed<SelectOption[]>(() => {
    const cat = this.categorieChoisie();
    const parents = new Map(this.categories().map((c) => [c.id, c.parent]));
    return this.produitsTous()
      .filter((p) => !cat || p.categorie === cat || parents.get(p.categorie) === cat)
      .map((p) => ({ value: p.id, label: p.nom }));
  });

  readonly err = (nom: keyof typeof this.form.controls, requis?: string) => controlError(this.form.controls[nom], requis);

  constructor() {
    this.reference.categories().subscribe({ next: (r) => this.categories.set(unwrapList(r).filter((c) => c.actif)) });
    this.reference.produits().subscribe({ next: (r) => this.produitsTous.set(unwrapList(r)) });
    this.reference.provinces().subscribe({
      next: (r) => this.provinces.set(unwrapList(r).map((p) => ({ value: p.id, label: p.nom }))),
    });
    this.form.controls.produit_id.valueChanges.subscribe((id) => {
      const produit = this.produitsTous().find((p) => p.id === id);
      if (produit?.unite_defaut && !this.form.controls.unite.dirty && !this.edition) {
        this.form.controls.unite.setValue(produit.unite_defaut);
      }
    });
    if (this.edition) this.charger();
  }

  charger(): void {
    this.loading.set(true);
    this.loadError.set('');
    this.service.get(this.id!).subscribe({
      next: (o) => {
        this.offre.set(o);
        this.remplir(o);
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  get figee(): boolean {
    return STATUTS_FIGES.includes(this.offre()?.statut ?? '');
  }

  private remplir(o: OffreDemande): void {
    this.expireInitiale = o.expire_at ? o.expire_at.slice(0, 10) : '';
    this.form.reset({
      type_annonce: o.type_annonce,
      titre: o.titre,
      categorie_id: o.categorie_id ?? '',
      produit_id: o.produit_id,
      description: o.description ?? '',
      quantite: o.quantite != null ? String(o.quantite) : '',
      unite: o.unite ?? 'KG',
      prix_unitaire: o.prix_unitaire != null ? String(o.prix_unitaire) : '',
      prix_total: o.prix_total != null ? String(o.prix_total) : '',
      negociable: !!o.negociable,
      conditionnement: o.conditionnement ?? '',
      qualite: o.qualite ?? '',
      certification_requise: o.certification_requise,
      province_id: o.province_id ?? '',
      localite: o.localite ?? '',
      disponible_du: o.disponible_du ?? '',
      expire_at: this.expireInitiale,
      mode_remise: o.mode_remise ?? '',
      modalites_livraison: o.modalites_livraison ?? '',
      moyens_paiement: o.moyens_paiement ?? [],
      conditions_paiement: o.conditions_paiement ?? '',
      afficher_telephone: !!o.afficher_telephone,
      afficher_email: !!o.afficher_email,
    });
    this.photosMax.set(o.photos_max ?? PHOTOS_MAX_DEFAUT);
    this.photosExistantes.set(this.lirePhotos(o));
  }

  private lirePhotos(o: OffreDemande): PhotoExistante[] {
    return (o.photos_urls ?? []).map((url, i) => {
      const numero = Number(/_(\d+)\.jpg/i.exec(url)?.[1] ?? i + 1);
      return { url, numero };
    });
  }

  moyenCoche(moyen: MoyenPaiement): boolean {
    return this.form.controls.moyens_paiement.value.includes(moyen);
  }

  basculerMoyen(moyen: MoyenPaiement, event: Event): void {
    const coche = (event.target as HTMLInputElement).checked;
    const actuels = this.form.controls.moyens_paiement.value;
    this.form.controls.moyens_paiement.setValue(
      coche ? [...actuels, moyen] : actuels.filter((m) => m !== moyen),
    );
    this.form.controls.moyens_paiement.markAsDirty();
  }

  choisirType(type: 'OFFRE' | 'DEMANDE'): void {
    this.form.controls.type_annonce.setValue(type);
  }

  dateError(): string {
    const dispo = this.form.controls.disponible_du.value;
    const limite = this.form.controls.expire_at.value;
    if (limite && limite !== this.expireInitiale && limite < this.dateMin) {
      return 'La date limite doit être postérieure à aujourd’hui.';
    }
    if (dispo && limite && dispo > limite) return 'La date de disponibilité doit précéder la date limite.';
    return this.err('expire_at');
  }

  ajouterPhotos(event: Event): void {
    const input = event.target as HTMLInputElement;
    const fichiers = Array.from(input.files ?? []);
    input.value = '';
    this.photoError.set('');
    for (const fichier of fichiers) {
      if (this.placesPhotos() <= 0) {
        this.photoError.set(`${this.photosMax()} photos maximum par annonce.`);
        break;
      }
      if (!TYPES_PHOTO.includes(fichier.type)) {
        this.photoError.set(`« ${fichier.name} » n’est pas une image JPEG, PNG ou WEBP.`);
        continue;
      }
      if (fichier.size > PHOTO_MAX_BYTES) {
        this.photoError.set(`« ${fichier.name} » est trop volumineuse (5 Mo maximum).`);
        continue;
      }
      const apercu = URL.createObjectURL(fichier);
      this.nouvellesPhotos.update((liste) => [...liste, { fichier, apercu }]);
    }
  }

  retirerNouvellePhoto(index: number): void {
    const cible = this.nouvellesPhotos()[index];
    if (cible) URL.revokeObjectURL(cible.apercu);
    this.nouvellesPhotos.update((liste) => liste.filter((_, i) => i !== index));
  }

  confirmerSuppressionPhoto(): void {
    const photo = this.photoASupprimer();
    if (!photo || !this.id) return;
    this.suppressionPhoto.set(true);
    this.service.supprimerPhoto(this.id, photo.numero).subscribe({
      next: (o) => {
        this.suppressionPhoto.set(false);
        this.photoASupprimer.set(null);
        this.offre.set(o);
        this.photosExistantes.set(this.lirePhotos(o));
        this.toast.success('Photo retirée');
      },
      error: (err) => {
        this.suppressionPhoto.set(false);
        this.photoASupprimer.set(null);
        this.toast.error('La photo n’a pas pu être retirée', toApiError(err).message);
      },
    });
  }

  private payload(): Partial<OffreDemande> {
    const v = this.form.getRawValue();
    const texte = (s: string) => s.trim() || null;
    const donnees: Partial<OffreDemande> = {
      type_annonce: v.type_annonce,
      titre: v.titre.trim(),
      categorie_id: v.categorie_id || null,
      produit_id: v.produit_id,
      description: texte(v.description),
      quantite: nombre(v.quantite),
      unite: v.unite || null,
      prix_unitaire: nombre(v.prix_unitaire),
      prix_total: nombre(v.prix_total),
      negociable: v.negociable,
      conditionnement: texte(v.conditionnement),
      qualite: texte(v.qualite),
      certification_requise: v.certification_requise,
      province_id: v.province_id || null,
      localite: texte(v.localite),
      disponible_du: v.disponible_du || null,
      mode_remise: (v.mode_remise || null) as OffreDemande['mode_remise'],
      modalites_livraison: texte(v.modalites_livraison),
      moyens_paiement: v.moyens_paiement,
      conditions_paiement: texte(v.conditions_paiement),
      afficher_telephone: v.afficher_telephone,
      afficher_email: v.afficher_email,
    };
    if (!this.edition || v.expire_at !== this.expireInitiale) {
      donnees.expire_at = v.expire_at ? `${v.expire_at}T23:59:00` : null;
    }
    return donnees;
  }

  enregistrer(): void {
    this.errorMessage.set('');
    const erreurDate = this.dateError();
    if (this.form.invalid || erreurDate) {
      this.errorMessage.set(
        this.form.invalid ? revealFormErrors(this.form, this.host) : erreurDate,
      );
      return;
    }
    this.saving.set(true);
    const requete$: Observable<OffreDemande> = this.edition
      ? this.service.modifierOffre(this.id!, this.payload())
      : this.service.creerOffre(this.payload());
    requete$.subscribe({
      next: (offre) => this.envoyerPhotos(offre),
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
      },
    });
  }

  private envoyerPhotos(offre: OffreDemande): void {
    const fichiers = this.nouvellesPhotos().map((p) => p.fichier);
    const envoi$ = fichiers.length ? this.service.uploadPhotos(offre.id, fichiers) : of(offre);
    envoi$.subscribe({
      next: (resultat) => this.terminer(resultat),
      error: (err) => {
        this.saving.set(false);
        this.toast.warning(
          'Annonce enregistrée, mais les photos n’ont pas été envoyées',
          `${toApiError(err).message} Vous pouvez réessayer depuis la modification de l’annonce.`,
        );
        this.router.navigate(['/app/marketplace/offres', offre.id]);
      },
    });
  }

  private terminer(offre: OffreDemande): void {
    this.saving.set(false);
    this.nouvellesPhotos().forEach((p) => URL.revokeObjectURL(p.apercu));
    this.nouvellesPhotos.set([]);
    if (offre.statut === 'EN_VALIDATION') {
      this.toast.success(
        this.edition ? 'Modifications enregistrées' : 'Annonce soumise',
        'Elle sera publiée après vérification par un modérateur.',
      );
    } else {
      this.toast.success(this.edition ? 'Modifications enregistrées' : 'Annonce publiée');
    }
    this.router.navigate(['/app/marketplace/offres', offre.id]);
  }
}

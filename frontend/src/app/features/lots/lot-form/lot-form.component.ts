import { ChangeDetectionStrategy, Component, ElementRef, inject, signal, viewChild } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { Subject, catchError, debounceTime, distinctUntilChanged, map, of, switchMap, tap } from 'rxjs';

import { AuthService } from '../../../core/auth/auth.service';
import { todayIso } from '../../../core/format/format.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { toApiError } from '../../../core/http/api-error.util';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { unwrapList } from '../../../core/models/common.model';
import { UNITE_LOT_OPTIONS } from '../../../core/models/lot.model';
import { Producteur } from '../../../core/models/producteur.model';
import { ZoneCollecte } from '../../../core/models/reference.model';
import { ErreurGeolocalisation, GeolocalisationService } from '../../../core/services/geolocalisation.service';
import { LotsService } from '../../../core/services/lots.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { ReferenceService } from '../../../core/services/reference.service';
import {
  dateNotFutureValidator,
  latitudeGabonValidator,
  longitudeGabonValidator,
} from '../../../core/validators/pnlf.validators';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';

const PHOTO_MAX_BYTES = 5 * 1024 * 1024;
const PHOTOS_MAX = 2;
const NOUVELLE_ZONE = '__nouvelle__';

type FormKey = 'produit' | 'date_collecte' | 'quantite' | 'unite' | 'prix_indicatif' | 'latitude' | 'longitude'
  | 'zone_collecte' | 'nouvelle_zone_libelle' | 'nouvelle_zone_province';

@Component({
  selector: 'app-lot-form',
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
  templateUrl: './lot-form.component.html',
  styleUrl: './lot-form.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LotFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly service = inject(LotsService);
  private readonly referenceService = inject(ReferenceService);
  private readonly producteursService = inject(ProducteursService);
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly toast = inject(ToastService);
  private readonly geolocalisation = inject(GeolocalisationService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly producteurInput = viewChild<ElementRef<HTMLInputElement>>('producteurInput');

  readonly today = todayIso();
  readonly loading = signal(false);
  readonly errorMessage = signal('');
  readonly unites = UNITE_LOT_OPTIONS;
  readonly produits = signal<SelectOption[]>([]);
  readonly zones = signal<SelectOption[]>([]);
  readonly provinces = signal<SelectOption[]>([]);
  readonly nouvelleZone = signal(false);
  private zonesRaw: ZoneCollecte[] = [];

  readonly producteurQuery = signal('');
  readonly producteurResults = signal<Producteur[]>([]);
  readonly selectedProducteur = signal<Producteur | null>(null);
  readonly searchingProducteur = signal(false);
  readonly producteurSearchDone = signal(false);
  readonly producteurSearchError = signal('');
  readonly producteurError = signal('');
  readonly activeIndex = signal(-1);
  readonly isProducteurRole = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);
  /** Seul l'administrateur crée des zones de collecte ; les autres rôles choisissent une zone existante. */
  readonly peutCreerZone = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR);
  private readonly producteurSearch$ = new Subject<string>();

  readonly photosMax = PHOTOS_MAX;
  readonly photoPreviews = signal<string[]>([]);
  readonly photoError = signal('');
  private photoFiles: File[] = [];

  readonly locatingGps = signal(false);
  readonly gpsError = signal('');
  readonly gpsPrecision = signal<number | null>(null);

  readonly form = this.fb.nonNullable.group({
    produit: ['', Validators.required],
    date_collecte: [this.today, [Validators.required, dateNotFutureValidator]],
    quantite: ['', [Validators.required, Validators.min(0.001)]],
    unite: ['KG', Validators.required],
    qualite_indicateur: [''],
    prix_indicatif: ['', Validators.min(0)],
    devise: ['XAF'],
    latitude: ['', latitudeGabonValidator],
    longitude: ['', longitudeGabonValidator],
    observations: [''],
    zone_collecte: ['', Validators.required],
    nouvelle_zone_libelle: [''],
    nouvelle_zone_province: [''],
  });

  readonly err = (name: FormKey, required?: string) => controlError(this.form.controls[name], required);

  quantiteError(): string {
    const msg = this.err('quantite', 'Saisissez la quantité collectée.');
    return msg && this.form.controls.quantite.hasError('min') ? 'La quantité doit être supérieure à 0.' : msg;
  }

  prixError(): string {
    const msg = this.err('prix_indicatif');
    return msg && this.form.controls.prix_indicatif.hasError('min') ? 'Le prix indicatif ne peut pas être négatif.' : msg;
  }

  constructor() {
    this.referenceService.produits().subscribe((res) => {
      this.produits.set(unwrapList(res).map((p) => ({ value: p.id, label: `${p.nom} (${p.code})` })));
    });
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.referenceService.zonesCollecte({ page_size: '200', actif: 'true' }).subscribe((res) => {
      this.zonesRaw = unwrapList(res);
      this.refreshZoneOptions();
    });
    this.form.controls.zone_collecte.valueChanges.pipe(takeUntilDestroyed()).subscribe((value) => {
      const nouvelle = value === NOUVELLE_ZONE;
      this.nouvelleZone.set(nouvelle);
      const libelle = this.form.controls.nouvelle_zone_libelle;
      const province = this.form.controls.nouvelle_zone_province;
      libelle.setValidators(nouvelle ? Validators.required : null);
      province.setValidators(nouvelle ? Validators.required : null);
      libelle.updateValueAndValidity({ emitEvent: false });
      province.updateValueAndValidity({ emitEvent: false });
      this.applyZoneGps(value);
      if (nouvelle) {
        const prod = this.selectedProducteur();
        if (prod?.province && !province.value) {
          this.form.patchValue({ nouvelle_zone_province: prod.province });
        }
      }
    });

    this.producteurSearch$
      .pipe(
        map((q) => q.trim()),
        debounceTime(250),
        distinctUntilChanged(),
        tap((q) => {
          this.producteurSearchError.set('');
          this.producteurSearchDone.set(false);
          this.searchingProducteur.set(q.length >= 2);
          if (q.length < 2) this.producteurResults.set([]);
        }),
        switchMap((q) =>
          q.length < 2
            ? of(null)
            : this.producteursService.list({ search: q, page_size: 6, statut: 'ACTIF' }).pipe(
                map((res) => unwrapList(res)),
                catchError((err) => {
                  this.producteurSearchError.set(toApiError(err).message);
                  return of([] as Producteur[]);
                }),
              ),
        ),
        takeUntilDestroyed(),
      )
      .subscribe((results) => {
        this.searchingProducteur.set(false);
        if (results === null) return;
        this.producteurResults.set(results);
        this.activeIndex.set(results.length ? 0 : -1);
        this.producteurSearchDone.set(true);
      });

    if (this.isProducteurRole) {
      this.producteursService.list({ page_size: 5 }).subscribe((res) => {
        const own = unwrapList(res)[0];
        if (own) {
          this.selectProducteur(own);
        }
      });
    }
  }

  private refreshZoneOptions(): void {
    this.zones.set([
      ...this.zonesRaw.map((z) => ({
        value: z.id,
        label: `${z.libelle}${z.province_nom ? ' (' + z.province_nom + ')' : ''}`,
      })),
      ...(this.peutCreerZone ? [{ value: NOUVELLE_ZONE, label: '+ Nouvelle zone de collecte…' }] : []),
    ]);
  }

  get comboOpen(): boolean {
    return (
      !this.selectedProducteur() &&
      this.producteurQuery().trim().length >= 2 &&
      (this.searchingProducteur() || this.producteurSearchDone() || !!this.producteurSearchError())
    );
  }

  onProducteurQueryChange(value: string): void {
    this.producteurQuery.set(value);
    this.selectedProducteur.set(null);
    this.producteurError.set('');
    this.producteurSearch$.next(value);
  }

  onProducteurKeydown(event: KeyboardEvent): void {
    const results = this.producteurResults();
    if (event.key === 'Escape') {
      this.producteurResults.set([]);
      this.producteurSearchDone.set(false);
      return;
    }
    if (!results.length) return;
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      this.activeIndex.set((this.activeIndex() + 1) % results.length);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      this.activeIndex.set((this.activeIndex() - 1 + results.length) % results.length);
    } else if (event.key === 'Enter' && this.activeIndex() >= 0) {
      event.preventDefault();
      this.selectProducteur(results[this.activeIndex()]);
    }
  }

  selectProducteur(p: Producteur): void {
    this.selectedProducteur.set(p);
    this.producteurResults.set([]);
    this.producteurSearchDone.set(false);
    this.producteurError.set('');
    this.producteurQuery.set(`${p.prenoms} ${p.nom} (${p.code_producteur})`);
    if (this.nouvelleZone() && p.province && !this.form.controls.nouvelle_zone_province.value) {
      this.form.patchValue({ nouvelle_zone_province: p.province });
    }
  }

  private applyZoneGps(zoneId: string): void {
    if (!zoneId || zoneId === NOUVELLE_ZONE) return;
    const zone = this.zonesRaw.find((z) => z.id === zoneId);
    if (!zone?.latitude || !zone?.longitude) return;
    if (this.form.controls.latitude.value || this.form.controls.longitude.value) return;
    this.form.patchValue({
      latitude: String(zone.latitude),
      longitude: String(zone.longitude),
    });
  }

  onPhotosSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    input.value = '';
    if (!files.length) return;

    this.photoError.set('');
    for (const file of files) {
      if (this.photoFiles.length >= this.photosMax) {
        this.photoError.set(`Vous ne pouvez ajouter que ${this.photosMax} photos maximum.`);
        break;
      }
      if (file.size > PHOTO_MAX_BYTES) {
        this.photoError.set(`« ${file.name} » est trop volumineuse (5 Mo maximum).`);
        continue;
      }
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
        this.photoError.set(`« ${file.name} » n'est pas une image JPEG, PNG ou WEBP.`);
        continue;
      }
      this.photoFiles.push(file);
      const reader = new FileReader();
      reader.onload = () => this.photoPreviews.update((list) => [...list, reader.result as string]);
      reader.onerror = () => this.photoError.set(`Impossible de lire « ${file.name} ».`);
      reader.readAsDataURL(file);
    }
  }

  removePhoto(index: number): void {
    this.photoFiles.splice(index, 1);
    this.photoPreviews.update((list) => list.filter((_, i) => i !== index));
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

  private nombre(value: string): number | null {
    const v = String(value ?? '').trim().replace(',', '.');
    return v ? Number(v) : null;
  }

  submit(): void {
    this.errorMessage.set('');

    if (!this.selectedProducteur()) {
      this.producteurError.set('Sélectionnez un producteur ou collecteur dans la liste de résultats.');
    }
    if (!this.selectedProducteur() || this.form.invalid) {
      const message = revealFormErrors(this.form, this.host);
      if (!this.selectedProducteur()) {
        this.producteurInput()?.nativeElement.focus();
        this.errorMessage.set(this.form.invalid ? message : 'Sélectionnez un producteur ou collecteur avant d’enregistrer.');
      } else {
        this.errorMessage.set(message);
      }
      return;
    }

    const raw = this.form.getRawValue();
    this.loading.set(true);
    if (raw.zone_collecte === NOUVELLE_ZONE && this.peutCreerZone) {
      this.referenceService
        .creerZoneCollecte({
          libelle: raw.nouvelle_zone_libelle.trim(),
          province: raw.nouvelle_zone_province,
          latitude: this.nombre(raw.latitude),
          longitude: this.nombre(raw.longitude),
        })
        .subscribe({
          next: (zone) => {
            // La zone créée devient une zone existante : un nouvel essai ne la recrée pas.
            this.zonesRaw = [...this.zonesRaw, zone];
            this.refreshZoneOptions();
            this.form.patchValue({ zone_collecte: zone.id, nouvelle_zone_libelle: '' });
            this.createLot(zone.id);
          },
          error: (err) => {
            this.loading.set(false);
            this.errorMessage.set(
              handleFormApiError(this.form, toApiError(err), this.host, {
                libelle: 'nouvelle_zone_libelle',
                province: 'nouvelle_zone_province',
              }),
            );
          },
        });
      return;
    }
    this.createLot(raw.zone_collecte);
  }

  private createLot(zoneCollecteId: string): void {
    const raw = this.form.getRawValue();
    const payload = {
      produit: raw.produit,
      date_collecte: raw.date_collecte || todayIso(),
      quantite: this.nombre(raw.quantite) ?? 0,
      unite: raw.unite,
      qualite_indicateur: raw.qualite_indicateur,
      prix_indicatif: this.nombre(raw.prix_indicatif),
      devise: raw.devise,
      latitude: this.nombre(raw.latitude),
      longitude: this.nombre(raw.longitude),
      observations: raw.observations,
      producteur: this.selectedProducteur()!.id,
      zone_collecte: zoneCollecteId,
    };

    this.service.create(payload).subscribe({
      next: (lot) => {
        const done = () => {
          this.loading.set(false);
          this.toast.success(
            'Lot déclaré en brouillon',
            `Code lot : ${lot.code_lot}. Il devient vérifiable publiquement après sa validation.`,
          );
          this.router.navigate(['/app/lots', lot.id]);
        };
        if (!this.photoFiles.length) {
          done();
          return;
        }
        this.service.uploadPhotos(lot.id, this.photoFiles).subscribe({
          next: () => done(),
          error: (err) => {
            this.loading.set(false);
            this.toast.warning(
              `Lot ${lot.code_lot} enregistré, mais l'envoi des photos a échoué`,
              `${toApiError(err).message} Vous pourrez les ajouter depuis la fiche du lot.`,
            );
            this.router.navigate(['/app/lots', lot.id]);
          },
        });
      },
      error: (err) => {
        this.loading.set(false);
        const apiError = toApiError(err);
        const producteurMsg = apiError.fieldErrors?.['producteur'];
        if (producteurMsg) this.producteurError.set(producteurMsg.join(' '));
        this.errorMessage.set(handleFormApiError(this.form, apiError, this.host));
      },
    });
  }
}

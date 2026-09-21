import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';

import { AuthService } from '../../../core/auth/auth.service';
import { toApiError } from '../../../core/http/api-error.util';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { unwrapList } from '../../../core/models/common.model';
import { Producteur } from '../../../core/models/producteur.model';
import { ZoneCollecte } from '../../../core/models/reference.model';
import { LotsService } from '../../../core/services/lots.service';
import { ProducteursService } from '../../../core/services/producteurs.service';
import { ReferenceService } from '../../../core/services/reference.service';
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

const UNITES: SelectOption[] = [
  { value: 'KG', label: 'Kilogramme (kg)' },
  { value: 'TONNE', label: 'Tonne' },
  { value: 'LITRE', label: 'Litre' },
  { value: 'SAC', label: 'Sac' },
  { value: 'UNITE', label: 'Unité' },
  { value: 'BOTTE', label: 'Botte' },
];

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

  readonly loading = signal(false);
  readonly submitted = signal(false);
  readonly errorMessage = signal('');
  readonly unites = UNITES;
  readonly produits = signal<SelectOption[]>([]);
  readonly zones = signal<SelectOption[]>([]);
  readonly provinces = signal<SelectOption[]>([]);
  readonly nouvelleZone = signal(false);
  private zonesRaw: ZoneCollecte[] = [];

  readonly producteurQuery = signal('');
  readonly producteurResults = signal<Producteur[]>([]);
  readonly selectedProducteur = signal<Producteur | null>(null);
  readonly searchingProducteur = signal(false);
  readonly isProducteurRole = this.auth.hasRole(RoleUtilisateur.PRODUCTEUR);

  readonly photosMax = PHOTOS_MAX;
  readonly photoPreviews = signal<string[]>([]);
  readonly photoError = signal('');
  private photoFiles: File[] = [];

  readonly locatingGps = signal(false);
  readonly gpsError = signal('');

  readonly form = this.fb.nonNullable.group({
    produit: ['', Validators.required],
    date_collecte: [new Date().toISOString().slice(0, 10), Validators.required],
    quantite: ['', [Validators.required, Validators.min(0.001)]],
    unite: ['KG', Validators.required],
    qualite_indicateur: [''],
    prix_indicatif: [''],
    devise: ['XAF'],
    latitude: [''],
    longitude: [''],
    observations: [''],
    zone_collecte: ['', Validators.required],
    nouvelle_zone_libelle: [''],
    nouvelle_zone_province: [''],
  });

  constructor() {
    this.referenceService.produits().subscribe((res) => {
      this.produits.set(unwrapList(res).map((p) => ({ value: p.id, label: `${p.nom} (${p.code})` })));
    });
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.referenceService.zonesCollecte({ page_size: '200', actif: 'true' }).subscribe((res) => {
      this.zonesRaw = unwrapList(res);
      this.zones.set([
        ...this.zonesRaw.map((z) => ({
          value: z.id,
          label: `${z.libelle}${z.province_nom ? ' — ' + z.province_nom : ''}`,
        })),
        { value: NOUVELLE_ZONE, label: '+ Nouvelle zone de collecte…' },
      ]);
    });
    this.form.controls.zone_collecte.valueChanges.pipe(takeUntilDestroyed()).subscribe((value) => {
      this.nouvelleZone.set(value === NOUVELLE_ZONE);
      this.applyZoneGps(value);
      if (value === NOUVELLE_ZONE) {
        const prod = this.selectedProducteur();
        if (prod?.province && !this.form.controls.nouvelle_zone_province.value) {
          this.form.patchValue({ nouvelle_zone_province: prod.province });
        }
      }
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

  onProducteurQueryChange(value: string): void {
    this.producteurQuery.set(value);
    this.selectedProducteur.set(null);
    if (value.trim().length < 2) {
      this.producteurResults.set([]);
      return;
    }
    this.searchingProducteur.set(true);
    this.producteursService.list({ search: value, page_size: 6 }).subscribe((res) => {
      this.producteurResults.set(unwrapList(res));
      this.searchingProducteur.set(false);
    });
  }

  selectProducteur(p: Producteur): void {
    this.selectedProducteur.set(p);
    this.producteurResults.set([]);
    this.producteurQuery.set(`${p.prenoms} ${p.nom} — ${p.code_producteur}`);
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
        this.photoError.set('Image trop volumineuse (5 Mo maximum).');
        continue;
      }
      if (!file.type.startsWith('image/')) {
        this.photoError.set('Fichier image invalide (JPEG/PNG/WEBP attendu).');
        continue;
      }
      this.photoFiles.push(file);
      const reader = new FileReader();
      reader.onload = () => this.photoPreviews.update((list) => [...list, reader.result as string]);
      reader.readAsDataURL(file);
    }
  }

  removePhoto(index: number): void {
    this.photoFiles.splice(index, 1);
    this.photoPreviews.update((list) => list.filter((_, i) => i !== index));
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
        this.locatingGps.set(false);
      },
      () => {
        this.gpsError.set('Impossible de récupérer votre position. Vérifiez les autorisations de localisation.');
        this.locatingGps.set(false);
      },
      { enableHighAccuracy: true, timeout: 10000 },
    );
  }

  submit(brouillon = false): void {
    this.submitted.set(true);
    this.errorMessage.set('');

    if (!this.selectedProducteur()) {
      this.errorMessage.set('Veuillez sélectionner un producteur ou collecteur dans la liste.');
      return;
    }
    if (!brouillon && this.form.invalid) return;
    const raw = this.form.getRawValue();
    if (!raw.produit || !raw.quantite || !raw.zone_collecte) {
      this.errorMessage.set('Pour un brouillon, renseignez au minimum le produit, la quantité et la zone.');
      return;
    }
    if (!brouillon && this.form.invalid) return;

    if (!raw.zone_collecte) {
      this.errorMessage.set('Indiquez la zone de collecte où le lot a été produit ou récolté.');
      return;
    }
    if (raw.zone_collecte === NOUVELLE_ZONE) {
      if (!raw.nouvelle_zone_libelle.trim() || !raw.nouvelle_zone_province) {
        this.errorMessage.set('Renseignez le nom et la province de la nouvelle zone de collecte.');
        return;
      }
    }

    this.loading.set(true);
    if (raw.zone_collecte === NOUVELLE_ZONE) {
      this.referenceService
        .creerZoneCollecte({
          libelle: raw.nouvelle_zone_libelle.trim(),
          province: raw.nouvelle_zone_province,
          latitude: raw.latitude ? Number(raw.latitude) : null,
          longitude: raw.longitude ? Number(raw.longitude) : null,
        })
        .subscribe({
          next: (zone) => this.createLot(zone.id, brouillon),
          error: (err) => {
            this.loading.set(false);
            this.errorMessage.set(toApiError(err).message);
          },
        });
      return;
    }
    this.createLot(raw.zone_collecte, brouillon);
  }

  private createLot(zoneCollecteId: string, brouillon = false): void {
    const raw = this.form.getRawValue();
    const payload = {
      produit: raw.produit,
      date_collecte: raw.date_collecte || new Date().toISOString().slice(0, 10),
      quantite: Number(raw.quantite),
      unite: raw.unite,
      qualite_indicateur: raw.qualite_indicateur,
      prix_indicatif: raw.prix_indicatif ? Number(raw.prix_indicatif) : null,
      devise: raw.devise,
      latitude: raw.latitude ? Number(raw.latitude) : null,
      longitude: raw.longitude ? Number(raw.longitude) : null,
      observations: raw.observations,
      producteur: this.selectedProducteur()!.id,
      zone_collecte: zoneCollecteId,
      brouillon,
    };

    this.service.create(payload).subscribe({
      next: (lot) => {
        const done = () => {
          this.loading.set(false);
          this.toast.success(
            brouillon ? 'Brouillon enregistré' : 'Lot déclaré avec succès',
            `Code lot : ${lot.code_lot}`,
          );
          this.router.navigate(['/app/lots', lot.id]);
        };
        if (!this.photoFiles.length) {
          done();
          return;
        }
        this.service.uploadPhotos(lot.id, this.photoFiles).subscribe({
          next: () => done(),
          error: () => {
            this.loading.set(false);
            this.toast.info('Lot enregistré, mais l\'envoi des photos a échoué. Vous pourrez les ajouter depuis la fiche du lot.');
            this.router.navigate(['/app/lots', lot.id]);
          },
        });
      },
      error: (err) => {
        this.loading.set(false);
        this.errorMessage.set(toApiError(err).message);
      },
    });
  }
}

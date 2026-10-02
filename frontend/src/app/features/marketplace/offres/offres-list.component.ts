import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { toApiError } from '../../../core/http/api-error.util';
import { AuthService } from '../../../core/auth/auth.service';
import { UNITE_OPTIONS } from '../../../core/format/format.util';
import { controlError, handleFormApiError, revealFormErrors } from '../../../core/forms/form-errors.util';
import { unwrapCount, unwrapList } from '../../../core/models/common.model';
import { OffreDemande, STATUT_OFFRE_DEMANDE_LABELS } from '../../../core/models/notification.model';
import { RoleUtilisateur } from '../../../core/models/user.model';
import { MarketplaceService } from '../../../core/services/marketplace.service';
import { ReferenceService } from '../../../core/services/reference.service';
import { AlertBannerComponent } from '../../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { CardComponent } from '../../../design-system/card/card.component';
import { EmptyStateComponent } from '../../../design-system/empty-state/empty-state.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { PaginationComponent } from '../../../design-system/pagination/pagination.component';
import { SelectFieldComponent, SelectOption } from '../../../design-system/select-field/select-field.component';
import { StatusBadgeComponent } from '../../../design-system/badge/status-badge.component';
import { SkeletonComponent } from '../../../design-system/skeleton/skeleton.component';
import { TextFieldComponent } from '../../../design-system/text-field/text-field.component';
import { ToastService } from '../../../design-system/toast/toast.service';
import { PnlfDatePipe, PnlfMontantPipe, PnlfQuantitePipe, PnlfUnitePipe } from '../../../shared/pipes/format.pipes';

const PHOTOS_MAX = 2;
const PHOTO_MAX_BYTES = 5 * 1024 * 1024;
const TYPES_PHOTO = ['image/jpeg', 'image/png', 'image/webp'];

type FormKey = 'type_annonce' | 'titre' | 'produit_id' | 'quantite' | 'prix_unitaire';

@Component({
  selector: 'app-offres-list',
  imports: [
    ReactiveFormsModule,
    FormsModule,
    RouterLink,
    PnlfDatePipe,
    PnlfMontantPipe,
    PnlfQuantitePipe,
    PnlfUnitePipe,
    CardComponent,
    ButtonComponent,
    EmptyStateComponent,
    StatusBadgeComponent,
    SelectFieldComponent,
    TextFieldComponent,
    AlertBannerComponent,
    IconComponent,
    SkeletonComponent,
    PaginationComponent,
  ],
  templateUrl: './offres-list.component.html',
  styleUrl: './offres-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OffresListComponent {
  private readonly service = inject(MarketplaceService);
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly search$ = new Subject<void>();

  readonly items = signal<OffreDemande[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly showForm = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');
  readonly produits = signal<SelectOption[]>([]);
  readonly statutLabels = STATUT_OFFRE_DEMANDE_LABELS;
  readonly filtre = signal<'TOUTES' | 'EN_VALIDATION' | 'OUVERTE'>('TOUTES');
  readonly typeFiltre = signal<'TOUS' | 'OFFRE' | 'DEMANDE'>('TOUS');
  readonly search = signal('');

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 12;

  readonly photosMax = PHOTOS_MAX;
  readonly photoPreviews = signal<string[]>([]);
  readonly photoError = signal('');
  private photoFiles: File[] = [];

  readonly unites = UNITE_OPTIONS;
  readonly typeOptions: SelectOption[] = [
    { value: 'OFFRE', label: 'Offre (je vends)' },
    { value: 'DEMANDE', label: 'Demande (je recherche)' },
  ];

  readonly canPost = this.auth.hasRole(
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
    RoleUtilisateur.ACHETEUR,
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
  );

  readonly canValidate = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE);

  readonly form = this.fb.nonNullable.group({
    type_annonce: ['OFFRE', Validators.required],
    titre: ['', Validators.required],
    produit_id: ['', Validators.required],
    quantite: ['', Validators.min(0.001)],
    unite: ['KG'],
    prix_unitaire: ['', Validators.min(0)],
    description: [''],
  });

  readonly err = (name: FormKey, required?: string) => controlError(this.form.controls[name], required);

  constructor() {
    this.referenceService.produits().subscribe((res) => {
      this.produits.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.search$.pipe(debounceTime(350), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });
    this.load();
  }

  quantiteError(): string {
    const msg = this.err('quantite');
    return msg && this.form.controls.quantite.hasError('min') ? 'La quantité doit être supérieure à 0.' : msg;
  }

  prixError(): string {
    const msg = this.err('prix_unitaire');
    return msg && this.form.controls.prix_unitaire.hasError('min') ? 'Le prix unitaire ne peut pas être négatif.' : msg;
  }

  ouvrirFormulaire(): void {
    this.errorMessage.set('');
    this.photoError.set('');
    this.showForm.set(true);
  }

  setFiltre(f: 'TOUTES' | 'EN_VALIDATION' | 'OUVERTE'): void {
    this.filtre.set(f);
    this.page.set(1);
    this.load();
  }

  setTypeFiltre(t: 'TOUS' | 'OFFRE' | 'DEMANDE'): void {
    this.typeFiltre.set(t);
    this.page.set(1);
    this.load();
  }

  onSearchInput(value: string): void {
    this.search.set(value);
    this.search$.next();
  }

  goToPage(page: number): void {
    this.page.set(page);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    const params: Record<string, string> = { page: String(this.page()), page_size: String(this.pageSize) };
    if (this.filtre() !== 'TOUTES') params['statut'] = this.filtre();
    if (this.typeFiltre() !== 'TOUS') params['type_annonce'] = this.typeFiltre();
    if (this.search().trim()) params['search'] = this.search().trim();
    this.service.offres(params).subscribe({
      next: (res) => {
        this.items.set(unwrapList(res));
        this.total.set(unwrapCount(res));
        this.loading.set(false);
      },
      error: (err) => {
        this.loading.set(false);
        this.loadError.set(toApiError(err).message);
      },
    });
  }

  tone(statut: string): 'success' | 'warning' | 'danger' | 'neutral' {
    if (statut === 'OUVERTE') return 'success';
    if (statut === 'EN_VALIDATION') return 'warning';
    if (statut === 'REJETEE') return 'danger';
    return 'neutral';
  }

  onPhotosSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    input.value = '';
    this.photoError.set('');
    for (const file of files) {
      if (this.photoFiles.length >= this.photosMax) {
        this.photoError.set(`Vous ne pouvez ajouter que ${this.photosMax} photos maximum.`);
        break;
      }
      if (!TYPES_PHOTO.includes(file.type)) {
        this.photoError.set(`« ${file.name} » n'est pas une image JPEG, PNG ou WEBP.`);
        continue;
      }
      if (file.size > PHOTO_MAX_BYTES) {
        this.photoError.set(`« ${file.name} » est trop volumineuse (5 Mo maximum).`);
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

  submit(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }
    this.saving.set(true);
    const raw = this.form.getRawValue();
    const nombre = (v: string) => (String(v ?? '').trim() ? Number(String(v).trim().replace(',', '.')) : null);
    this.service
      .creerOffre({
        ...raw,
        type_annonce: raw.type_annonce as OffreDemande['type_annonce'],
        quantite: nombre(raw.quantite),
        prix_unitaire: nombre(raw.prix_unitaire),
      })
      .subscribe({
        next: (offre) => {
          const finish = (photoErreur?: string) => {
            this.saving.set(false);
            this.showForm.set(false);
            this.form.reset({ type_annonce: 'OFFRE', unite: 'KG' });
            this.photoFiles = [];
            this.photoPreviews.set([]);
            if (photoErreur) {
              this.toast.warning(
                'Annonce soumise, mais les photos n’ont pas pu être envoyées',
                `${photoErreur} Vous pourrez les ajouter depuis la fiche de l’annonce.`,
              );
            } else {
              this.toast.success('Annonce soumise', 'Elle sera publiée après validation par un administrateur.');
            }
            this.load();
          };
          if (this.photoFiles.length) {
            this.service.uploadPhotos(offre.id, this.photoFiles).subscribe({
              next: () => finish(),
              error: (err) => finish(toApiError(err).message),
            });
          } else {
            finish();
          }
        },
        error: (err) => {
          this.saving.set(false);
          this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
        },
      });
  }
}

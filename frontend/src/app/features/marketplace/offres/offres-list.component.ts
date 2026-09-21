import { DatePipe, DecimalPipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { toApiError } from '../../../core/http/api-error.util';
import { AuthService } from '../../../core/auth/auth.service';
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

const PHOTOS_MAX = 2;

@Component({
  selector: 'app-offres-list',
  imports: [
    ReactiveFormsModule,
    FormsModule,
    DatePipe,
    DecimalPipe,
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
  private readonly router = inject(Router);
  private readonly search$ = new Subject<void>();

  readonly items = signal<OffreDemande[]>([]);
  readonly loading = signal(true);
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
  private photoFiles: File[] = [];

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
    quantite: [''],
    unite: ['KG'],
    prix_unitaire: [''],
    description: [''],
  });

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
      error: () => this.loading.set(false),
    });
  }

  openDetail(o: OffreDemande): void {
    this.router.navigate(['/app/marketplace/offres', o.id]);
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
    for (const file of files) {
      if (this.photoFiles.length >= this.photosMax) break;
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
    if (this.form.invalid) return;
    this.saving.set(true);
    this.errorMessage.set('');
    const raw = this.form.getRawValue();
    this.service
      .creerOffre({
        ...raw,
        type_annonce: raw.type_annonce as OffreDemande['type_annonce'],
        quantite: raw.quantite ? Number(raw.quantite) : null,
        prix_unitaire: raw.prix_unitaire ? Number(raw.prix_unitaire) : null,
      })
      .subscribe({
        next: (offre) => {
          const finish = () => {
            this.saving.set(false);
            this.showForm.set(false);
            this.form.reset({ type_annonce: 'OFFRE', unite: 'KG' });
            this.photoFiles = [];
            this.photoPreviews.set([]);
            this.toast.success('Annonce soumise avec succès, en attente de validation.');
            this.load();
          };
          if (this.photoFiles.length) {
            this.service.uploadPhotos(offre.id, this.photoFiles).subscribe({ next: finish, error: finish });
          } else {
            finish();
          }
        },
        error: (err) => {
          this.saving.set(false);
          this.errorMessage.set(toApiError(err).message);
        },
      });
  }
}

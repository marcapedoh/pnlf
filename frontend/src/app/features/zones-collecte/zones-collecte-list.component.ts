import { ChangeDetectionStrategy, Component, ElementRef, inject, signal } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router, RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { toApiError } from '../../core/http/api-error.util';
import { AuthService } from '../../core/auth/auth.service';
import { controlError, handleFormApiError, revealFormErrors } from '../../core/forms/form-errors.util';
import { latitudeGabonValidator, longitudeGabonValidator } from '../../core/validators/pnlf.validators';
import { unwrapCount, unwrapList } from '../../core/models/common.model';
import { ZoneCollecte } from '../../core/models/reference.model';
import { RoleUtilisateur } from '../../core/models/user.model';
import { ReferenceService, ZoneImportResult } from '../../core/services/reference.service';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { SelectFieldComponent, SelectOption } from '../../design-system/select-field/select-field.component';
import { SkeletonComponent } from '../../design-system/skeleton/skeleton.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ToastService } from '../../design-system/toast/toast.service';
import { triggerBrowserDownload } from '../../core/http/download-file.util';

@Component({
  selector: 'app-zones-collecte-list',
  imports: [
    ReactiveFormsModule,
    FormsModule,
    RouterLink,
    CardComponent,
    ButtonComponent,
    EmptyStateComponent,
    TextFieldComponent,
    SelectFieldComponent,
    AlertBannerComponent,
    PaginationComponent,
    SkeletonComponent,
    StatusBadgeComponent,
  ],
  templateUrl: './zones-collecte-list.component.html',
  styleUrl: './zones-collecte-list.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ZonesCollecteListComponent {
  private readonly referenceService = inject(ReferenceService);
  private readonly auth = inject(AuthService);
  private readonly fb = inject(FormBuilder);
  private readonly toast = inject(ToastService);
  private readonly router = inject(Router);
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly search$ = new Subject<void>();
  readonly modeleUrl = '#';

  readonly items = signal<ZoneCollecte[]>([]);
  readonly loading = signal(true);
  readonly loadError = signal('');
  readonly provinces = signal<SelectOption[]>([]);
  readonly showForm = signal(false);
  readonly showImport = signal(false);
  readonly saving = signal(false);
  readonly errorMessage = signal('');

  readonly page = signal(1);
  readonly total = signal(0);
  readonly pageSize = 10;
  readonly search = signal('');

  readonly importing = signal(false);
  readonly importResult = signal<ZoneImportResult | null>(null);
  readonly importError = signal('');
  private importFile: File | null = null;
  readonly importFileName = signal('');

  /** Création, modification, activation et import : administrateur uniquement (lecture pour les autres rôles). */
  readonly canManage = this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR);
  readonly canDeclareLot = this.auth.hasRole(
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
    RoleUtilisateur.PRODUCTEUR,
    RoleUtilisateur.COOPERATIVE,
  );

  readonly actifFilter = signal<'' | 'true' | 'false'>('true');
  readonly actifOptions: SelectOption[] = [
    { value: 'true', label: 'Zones actives' },
    { value: 'false', label: 'Zones désactivées' },
    { value: '', label: 'Toutes les zones' },
  ];

  readonly form = this.fb.nonNullable.group({
    code: [''],
    libelle: ['', Validators.required],
    province: ['', Validators.required],
    description: [''],
    latitude: ['', latitudeGabonValidator],
    longitude: ['', longitudeGabonValidator],
  });

  readonly err = (name: 'code' | 'libelle' | 'province' | 'latitude' | 'longitude', required?: string) =>
    controlError(this.form.controls[name], required);

  constructor() {
    this.referenceService.provinces().subscribe((res) => {
      this.provinces.set(unwrapList(res).map((p) => ({ value: p.id, label: p.nom })));
    });
    this.search$.pipe(debounceTime(350), takeUntilDestroyed()).subscribe(() => {
      this.page.set(1);
      this.load();
    });
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

  onActifFilterChange(value: string): void {
    this.actifFilter.set(value === 'true' || value === 'false' ? value : '');
    this.page.set(1);
    this.load();
  }

  load(): void {
    this.loading.set(true);
    this.loadError.set('');
    const params: Record<string, string> = {
      page: String(this.page()),
      page_size: String(this.pageSize),
      search: this.search(),
    };
    if (this.canManage && this.actifFilter()) params['actif'] = this.actifFilter();
    this.referenceService
      .zonesCollecte(params)
      .subscribe({
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

  openDetail(zone: ZoneCollecte): void {
    this.router.navigate(['/app/zones-collecte', zone.id]);
  }

  ouvrirFormulaire(): void {
    this.errorMessage.set('');
    this.form.reset();
    this.showImport.set(false);
    this.showForm.set(true);
  }

  submit(): void {
    this.errorMessage.set('');
    if (this.form.invalid) {
      this.errorMessage.set(revealFormErrors(this.form, this.host));
      return;
    }
    this.saving.set(true);
    const raw = this.form.getRawValue();
    const nombre = (v: string) => (v.trim() ? Number(v.trim().replace(',', '.')) : null);
    const payload = {
      ...raw,
      code: raw.code.trim(),
      latitude: nombre(raw.latitude),
      longitude: nombre(raw.longitude),
    };
    this.referenceService.creerZoneCollecte(payload).subscribe({
      next: () => {
        this.saving.set(false);
        this.showForm.set(false);
        this.form.reset();
        this.toast.success('Zone de collecte créée');
        this.load();
      },
      error: (err) => {
        this.saving.set(false);
        this.errorMessage.set(handleFormApiError(this.form, toApiError(err), this.host));
      },
    });
  }

  onImportFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    this.importFile = file;
    this.importFileName.set(file?.name ?? '');
    this.importResult.set(null);
    this.importError.set('');
  }

  telechargerModele(event: Event): void {
    event.preventDefault();
    this.referenceService.telechargerModeleImport().subscribe({
      next: (blob) => {
        triggerBrowserDownload(blob, 'modele-zones-collecte.csv');
      },
      error: (err) => this.toast.error('Impossible de télécharger le modèle', toApiError(err).message),
    });
  }

  importer(): void {
    if (!this.importFile) {
      this.importError.set('Veuillez sélectionner un fichier CSV ou XLSX.');
      return;
    }
    this.importing.set(true);
    this.importError.set('');
    this.importResult.set(null);
    this.referenceService.importerZonesCollecte(this.importFile).subscribe({
      next: (res) => {
        this.importing.set(false);
        this.importResult.set(res);
        this.importFile = null;
        this.importFileName.set('');
        this.toast.success(
          'Import terminé',
          `${res.crees} ${res.crees > 1 ? 'zones créées' : 'zone créée'}, ${res.mis_a_jour} ${res.mis_a_jour > 1 ? 'zones mises à jour' : 'zone mise à jour'}.`,
        );
        this.load();
      },
      error: (err) => {
        this.importing.set(false);
        this.importError.set(toApiError(err).message);
      },
    });
  }
}

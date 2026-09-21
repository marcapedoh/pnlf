import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Router, RouterLink } from '@angular/router';
import { Subject, debounceTime } from 'rxjs';

import { toApiError } from '../../core/http/api-error.util';
import { AuthService } from '../../core/auth/auth.service';
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
  private readonly search$ = new Subject<void>();
  readonly modeleUrl = '#';

  readonly items = signal<ZoneCollecte[]>([]);
  readonly loading = signal(true);
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

  readonly canManage = this.auth.hasRole(
    RoleUtilisateur.ADMINISTRATEUR,
    RoleUtilisateur.AGENT_MINISTERE,
    RoleUtilisateur.AGENT_FORESTIER,
  );

  readonly form = this.fb.nonNullable.group({
    code: ['', Validators.required],
    libelle: ['', Validators.required],
    province: ['', Validators.required],
    description: [''],
    latitude: [''],
    longitude: [''],
  });

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

  load(): void {
    this.loading.set(true);
    this.referenceService
      .zonesCollecte({ page: String(this.page()), page_size: String(this.pageSize), search: this.search() })
      .subscribe({
        next: (res) => {
          this.items.set(unwrapList(res));
          this.total.set(unwrapCount(res));
          this.loading.set(false);
        },
        error: () => this.loading.set(false),
      });
  }

  openDetail(zone: ZoneCollecte): void {
    this.router.navigate(['/app/zones-collecte', zone.id]);
  }

  submit(): void {
    if (this.form.invalid) return;
    this.saving.set(true);
    this.errorMessage.set('');
    const raw = this.form.getRawValue();
    const payload = {
      ...raw,
      latitude: raw.latitude ? Number(raw.latitude) : null,
      longitude: raw.longitude ? Number(raw.longitude) : null,
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
        this.errorMessage.set(toApiError(err).message);
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
      error: () => this.toast.error('Impossible de télécharger le modèle.'),
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
        this.toast.success(`Import terminé : ${res.crees} créée(s), ${res.mis_a_jour} mise(s) à jour.`);
        this.load();
      },
      error: (err) => {
        this.importing.set(false);
        this.importError.set(toApiError(err).message);
      },
    });
  }
}

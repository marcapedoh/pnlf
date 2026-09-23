import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Subject, debounceTime, distinctUntilChanged } from 'rxjs';

import {
  DashboardService,
  ExportFormat,
  JournalEvent,
  JournalFiltres,
  JournalGranularite,
  JournalPeriode,
} from '../../core/services/dashboard.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { TextFieldComponent } from '../../design-system/text-field/text-field.component';
import { ProducteursService } from '../../core/services/producteurs.service';
import { CertificationsService } from '../../core/services/certifications.service';
import { unwrapList } from '../../core/models/common.model';
import { ToastService } from '../../design-system/toast/toast.service';
import { FileDownloadService, messageFromDownloadError, triggerBrowserDownload } from '../../core/http/download-file.util';
import { AuthService } from '../../core/auth/auth.service';
import { RoleUtilisateur } from '../../core/models/user.model';
import { PdfPreviewService } from '../../core/services/pdf-preview.service';

@Component({
  selector: 'app-rapports',
  imports: [
    DatePipe,
    FormsModule,
    CardComponent,
    ButtonComponent,
    EmptyStateComponent,
    PaginationComponent,
    TextFieldComponent,
  ],
  templateUrl: './rapports.component.html',
  styleUrl: './rapports.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RapportsComponent {
  private readonly dashboardService = inject(DashboardService);
  private readonly downloads = inject(FileDownloadService);
  private readonly toast = inject(ToastService);
  private readonly producteurs = inject(ProducteursService);
  private readonly certifications = inject(CertificationsService);
  private readonly pdfPreview = inject(PdfPreviewService);
  private readonly auth = inject(AuthService);

  /** Export journal réservé admin / ministère (SEC-15). */
  readonly canExportJournal = computed(() =>
    this.auth.hasRole(RoleUtilisateur.ADMINISTRATEUR, RoleUtilisateur.AGENT_MINISTERE),
  );

  readonly downloading = signal<string | null>(null);
  readonly granularite = signal<JournalGranularite>('jour');
  readonly periodes = signal<JournalPeriode[]>([]);
  readonly loadingPeriodes = signal(true);
  readonly selected = signal<JournalPeriode | null>(null);
  readonly events = signal<JournalEvent[]>([]);
  readonly eventsTotal = signal(0);
  readonly eventsPage = signal(1);
  readonly eventsPageSize = 25;
  readonly loadingEvents = signal(false);
  readonly selectedLibelle = signal('');

  /** Une seule date pour aller à une période précise. */
  periodeDate = '';

  /** Recherche utilisateur dans le détail (filtre la liste en direct). */
  userSearch = '';

  private readonly filterReload$ = new Subject<string>();

  constructor() {
    this.loadPeriodes();
    this.filterReload$
      .pipe(debounceTime(250), distinctUntilChanged())
      .subscribe(() => {
        this.eventsPage.set(1);
        this.loadEvents();
      });
  }

  setGranularite(g: JournalGranularite): void {
    this.granularite.set(g);
    this.selected.set(null);
    this.events.set([]);
    this.userSearch = '';
    this.loadPeriodes();
  }

  loadPeriodes(): void {
    this.loadingPeriodes.set(true);
    this.dashboardService.journalPeriodes(this.granularite()).subscribe({
      next: (res) => {
        this.periodes.set(res.results);
        this.loadingPeriodes.set(false);
        // Affiche par défaut le détail de la première période (liste complète).
        if (res.results.length > 0 && !this.selected()) {
          this.openPeriode(res.results[0]);
        }
      },
      error: () => {
        this.periodes.set([]);
        this.loadingPeriodes.set(false);
        this.toast.error('Impossible de charger le journal d’activité.');
      },
    });
  }

  /** Ouvre la période correspondant à la date saisie. */
  allerAPeriode(): void {
    const d = this.periodeDate.trim();
    if (!/^\d{4}-\d{2}-\d{2}$/.test(d)) {
      this.toast.info('Choisissez une date pour afficher la période.');
      return;
    }
    this.userSearch = '';
    this.openPeriode({ date: d, libelle: d, nb_evenements: 0, nb_utilisateurs: 0 });
  }

  openPeriode(p: JournalPeriode): void {
    this.selected.set(p);
    this.userSearch = '';
    this.eventsPage.set(1);
    this.loadEvents();
  }

  goToEventsPage(page: number): void {
    this.eventsPage.set(page);
    this.loadEvents();
  }

  private currentFiltres(): JournalFiltres {
    const q = this.userSearch.trim();
    return q ? { q } : {};
  }

  loadEvents(): void {
    const p = this.selected();
    if (!p) return;

    this.loadingEvents.set(true);
    this.dashboardService
      .journalDetail(
        this.granularite(),
        p.date,
        this.eventsPage(),
        this.eventsPageSize,
        this.currentFiltres(),
      )
      .subscribe({
        next: (res) => {
          this.events.set(res.results);
          this.eventsTotal.set(res.count);
          this.selectedLibelle.set(res.libelle);
          this.loadingEvents.set(false);
        },
        error: () => {
          this.loadingEvents.set(false);
          this.toast.error('Impossible de charger le détail du journal.');
        },
      });
  }

  onUserSearch(value: string): void {
    this.userSearch = value;
    // Met à jour la liste au fur et à mesure de la saisie (vide = tout le monde).
    this.filterReload$.next(value.trim());
  }

  clearUtilisateur(): void {
    this.userSearch = '';
    this.eventsPage.set(1);
    this.loadEvents();
  }

  downloadLots(format: ExportFormat): void {
    if (format === 'pdf') {
      this._openPdf('lots');
      return;
    }
    this._download(this.dashboardService.exportUrl(format), `pfnl-lots.${format}`, format, `lots-${format}`);
  }

  downloadProducteurs(): void {
    this.downloading.set('prod-csv');
    this.producteurs.list({ page_size: 500 }).subscribe({
      next: (res) => {
        const rows = unwrapList(res);
        const csv = [
          'code;nom;prenoms;province;statut;telephone',
          ...rows.map((p) =>
            [p.code_producteur, p.nom, p.prenoms, p.province_nom, p.statut, p.telephone || ''].join(';'),
          ),
        ].join('\n');
        this._saveBlob(csv, 'pfnl-producteurs.csv', 'text/csv');
        this.downloading.set(null);
        this.toast.success('Export producteurs téléchargé');
      },
      error: () => {
        this.downloading.set(null);
        this.toast.error("Échec de l'export");
      },
    });
  }

  downloadCertifications(): void {
    this.downloading.set('cert-csv');
    this.certifications.list({ page_size: '500' }).subscribe({
      next: (res) => {
        const rows = unwrapList(res);
        const csv = [
          'type;producteur;numero;statut;date_demande',
          ...rows.map((c) =>
            [c.type_libelle, c.producteur_nom || '', c.numero_certificat || '', c.statut, c.date_demande].join(';'),
          ),
        ].join('\n');
        this._saveBlob(csv, 'pfnl-certifications.csv', 'text/csv');
        this.downloading.set(null);
        this.toast.success('Export certifications téléchargé');
      },
      error: () => {
        this.downloading.set(null);
        this.toast.error("Échec de l'export");
      },
    });
  }

  private _saveBlob(content: string, filename: string, mime: string): void {
    triggerBrowserDownload(new Blob([content], { type: mime }), filename);
  }

  downloadJournal(format: ExportFormat): void {
    const p = this.selected();
    if (!p) {
      this.toast.info("Sélectionnez d'abord une période.");
      return;
    }
    if (format === 'pdf') {
      this._openPdf('journal');
      return;
    }
    const filtres = this.currentFiltres();
    const url = this.dashboardService.journalExportUrl(this.granularite(), p.date, format, filtres);
    const slug = filtres.q
      ? `journal-${this.granularite()}-${p.date}-filtre`
      : `journal-${this.granularite()}-${p.date}`;
    this._download(url, `${slug}.${format}`, format, `journal-${format}`);
  }

  private _openPdf(kind: 'lots' | 'journal'): void {
    if (kind === 'lots') {
      this.pdfPreview.open('Export des lots (PDF)', 'pfnl-lots.pdf', () => this.dashboardService.lotsPdfBlob());
      return;
    }
    const p = this.selected();
    if (!p) return;
    const filtres = this.currentFiltres();
    const title = filtres.q
      ? `Journal d’audit — recherche « ${filtres.q} »`
      : 'Journal d’audit (PDF)';
    const filename = `pfnl-journal-${this.granularite()}-${p.date}.pdf`;
    this.pdfPreview.open(title, filename, () =>
      this.dashboardService.journalPdfBlob(this.granularite(), p.date, filtres),
    );
  }

  private _download(url: string, filename: string, format: ExportFormat, key: string): void {
    this.downloading.set(key);
    const mime = {
      csv: 'text/csv;charset=utf-8',
      xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      pdf: 'application/pdf',
    }[format];
    this.downloads.download(url, filename, mime).subscribe({
      next: () => {
        this.downloading.set(null);
        this.toast.success('Export téléchargé');
      },
      error: (err: unknown) => {
        this.downloading.set(null);
        this.toast.error(messageFromDownloadError(err));
      },
    });
  }
}

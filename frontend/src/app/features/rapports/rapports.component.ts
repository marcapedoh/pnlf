import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';

import {
  DashboardService,
  ExportFormat,
  JournalEvent,
  JournalGranularite,
  JournalPeriode,
} from '../../core/services/dashboard.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { EmptyStateComponent } from '../../design-system/empty-state/empty-state.component';
import { PaginationComponent } from '../../design-system/pagination/pagination.component';
import { ProducteursService } from '../../core/services/producteurs.service';
import { CertificationsService } from '../../core/services/certifications.service';
import { unwrapList } from '../../core/models/common.model';
import { ToastService } from '../../design-system/toast/toast.service';
import { FileDownloadService, messageFromDownloadError, navigateOpenedTab, toSameOriginUrl, triggerBrowserDownload } from '../../core/http/download-file.util';

@Component({
  selector: 'app-rapports',
  imports: [DatePipe, CardComponent, ButtonComponent, EmptyStateComponent, PaginationComponent],
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
  readonly pdfReadyUrl = signal<string | null>(null);

  constructor() {
    this.loadPeriodes();
  }

  setGranularite(g: JournalGranularite): void {
    this.granularite.set(g);
    this.selected.set(null);
    this.events.set([]);
    this.loadPeriodes();
  }

  loadPeriodes(): void {
    this.loadingPeriodes.set(true);
    this.dashboardService.journalPeriodes(this.granularite()).subscribe({
      next: (res) => {
        this.periodes.set(res.results);
        this.loadingPeriodes.set(false);
      },
      error: () => this.loadingPeriodes.set(false),
    });
  }

  openPeriode(p: JournalPeriode): void {
    this.selected.set(p);
    this.eventsPage.set(1);
    this.loadEvents();
  }

  goToEventsPage(page: number): void {
    this.eventsPage.set(page);
    this.loadEvents();
  }

  loadEvents(): void {
    const p = this.selected();
    if (!p) return;
    this.loadingEvents.set(true);
    this.dashboardService.journalDetail(this.granularite(), p.date, this.eventsPage(), this.eventsPageSize).subscribe({
      next: (res) => {
        this.events.set(res.results);
        this.eventsTotal.set(res.count);
        this.selectedLibelle.set(res.libelle);
        this.loadingEvents.set(false);
      },
      error: () => this.loadingEvents.set(false),
    });
  }

  downloadLots(format: ExportFormat): void {
    if (format === 'pdf') {
      this._openPdf('lots');
      return;
    }
    this._download(this.dashboardService.exportUrl(format), `pnlf-lots.${format}`, format, `lots-${format}`);
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
        this._saveBlob(csv, 'pnlf-producteurs.csv', 'text/csv');
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
        this._saveBlob(csv, 'pnlf-certifications.csv', 'text/csv');
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
      this.toast.info("Sélectionnez d'abord une période dans l'historique.");
      return;
    }
    if (format === 'pdf') {
      this._openPdf('journal');
      return;
    }
    const url = this.dashboardService.journalExportUrl(this.granularite(), p.date, format);
    this._download(url, `journal-${this.granularite()}-${p.date}.${format}`, format, `journal-${format}`);
  }

  private _openPdf(kind: 'lots' | 'journal'): void {
    this.pdfReadyUrl.set(null);
    const tab = window.open('', `pnlf-pdf-${kind}`);
    if (tab) {
      try {
        tab.document.open();
        tab.document.write(
          '<!doctype html><html><head><meta charset="utf-8"><title>PNLF-PFNL</title></head><body style="font-family:sans-serif;padding:2rem;color:#146b3f">Préparation du PDF…</body></html>',
        );
        tab.document.close();
      } catch {
        /* certains navigateurs verrouillent document.write */
      }
    }
    const key = `${kind}-pdf`;
    this.downloading.set(key);
    const req$ =
      kind === 'lots'
        ? this.dashboardService.createLotsPdfTicket()
        : this.dashboardService.createJournalPdfTicket(this.granularite(), this.selected()!.date);
    req$.subscribe({
      next: ({ url }) => {
        this.downloading.set(null);
        if (navigateOpenedTab(tab, url)) {
          this.toast.success('Le PDF s’ouvre dans un nouvel onglet.');
          return;
        }
        this.pdfReadyUrl.set(toSameOriginUrl(url));
        this.toast.info('Cliquez sur « Ouvrir le PDF » — le navigateur a bloqué la nouvelle fenêtre.');
      },
      error: (err: unknown) => {
        this.downloading.set(null);
        try {
          tab?.close();
        } catch {
          /* ignore */
        }
        this.toast.error(messageFromDownloadError(err));
      },
    });
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

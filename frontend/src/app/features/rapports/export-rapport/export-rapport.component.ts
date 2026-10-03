import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';

import { FileDownloadService, messageFromDownloadError } from '../../../core/http/download-file.util';
import { RapportExportable } from '../../../core/models/rapports.model';
import { FormatExport, RapportsService } from '../../../core/services/rapports.service';
import { PdfPreviewService } from '../../../core/services/pdf-preview.service';
import { ButtonComponent } from '../../../design-system/button/button.component';
import { IconComponent } from '../../../design-system/icon/icon.component';
import { ToastService } from '../../../design-system/toast/toast.service';

const MIME: Record<Exclude<FormatExport, 'pdf'>, string> = {
  csv: 'text/csv;charset=utf-8',
  xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};

/** Exports CSV, Excel et PDF (aperçu) d'un rapport avec les filtres affichés à l'écran. */
@Component({
  selector: 'app-export-rapport',
  imports: [ButtonComponent, IconComponent],
  template: `
    <div class="export-rapport" role="group" [attr.aria-label]="'Exporter : ' + titre()">
      <button pnlfButton type="button" variant="outline" size="sm" [loading]="encours() === 'csv'" [disabled]="!!encours()" (click)="telecharger('csv')">
        <pnlf-icon name="download" [size]="14" /> CSV
      </button>
      <button pnlfButton type="button" variant="outline" size="sm" [loading]="encours() === 'xlsx'" [disabled]="!!encours()" (click)="telecharger('xlsx')">
        <pnlf-icon name="download" [size]="14" /> Excel
      </button>
      <button pnlfButton type="button" variant="primary" size="sm" [disabled]="!!encours()" (click)="apercu()">
        <pnlf-icon name="file-text" [size]="14" /> PDF
      </button>
    </div>
  `,
  styles: `
    .export-rapport {
      display: flex;
      flex-wrap: wrap;
      gap: var(--space-2);
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ExportRapportComponent {
  private readonly rapports = inject(RapportsService);
  private readonly fichiers = inject(FileDownloadService);
  private readonly pdf = inject(PdfPreviewService);
  private readonly toast = inject(ToastService);

  readonly rapport = input.required<RapportExportable | 'lots'>();
  readonly filtres = input<object>({});
  readonly titre = input.required<string>();
  readonly nomFichier = input.required<string>();

  readonly encours = signal<FormatExport | null>(null);

  telecharger(format: Exclude<FormatExport, 'pdf'>): void {
    const rapport = this.rapport();
    const url =
      rapport === 'lots'
        ? this.rapports.lotsExportUrl(format, this.filtres())
        : this.rapports.exportUrl(rapport, format, this.filtres());
    this.encours.set(format);
    this.fichiers.download(url, `${this.nomFichier()}.${format}`, MIME[format]).subscribe({
      next: () => {
        this.encours.set(null);
        this.toast.success('Export téléchargé', `${this.titre()} au format ${format === 'csv' ? 'CSV' : 'Excel'}.`);
      },
      error: (err: unknown) => {
        this.encours.set(null);
        this.toast.error('Export impossible', messageFromDownloadError(err));
      },
    });
  }

  apercu(): void {
    const rapport = this.rapport();
    const filtres = this.filtres();
    this.pdf.open(`${this.titre()} (PDF)`, `${this.nomFichier()}.pdf`, () =>
      rapport === 'lots' ? this.rapports.lotsPdf(filtres) : this.rapports.pdf(rapport, filtres),
    );
  }
}

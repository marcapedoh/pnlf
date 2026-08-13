import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';

import { DashboardService } from '../../core/services/dashboard.service';
import { ButtonComponent } from '../../design-system/button/button.component';
import { CardComponent } from '../../design-system/card/card.component';
import { ToastService } from '../../design-system/toast/toast.service';

@Component({
  selector: 'app-rapports',
  imports: [CardComponent, ButtonComponent],
  templateUrl: './rapports.component.html',
  styleUrl: './rapports.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class RapportsComponent {
  private readonly dashboardService = inject(DashboardService);
  private readonly http = inject(HttpClient);
  private readonly toast = inject(ToastService);

  readonly downloading = signal<string | null>(null);

  download(format: 'csv' | 'xlsx' | 'pdf'): void {
    this.downloading.set(format);
    const mime = { csv: 'text/csv', xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', pdf: 'application/pdf' }[format];
    this.http.get(this.dashboardService.exportUrl(format), { responseType: 'blob' }).subscribe({
      next: (blob) => {
        const url = URL.createObjectURL(new Blob([blob], { type: mime }));
        const a = document.createElement('a');
        a.href = url;
        a.download = `pnlf-lots.${format}`;
        a.click();
        URL.revokeObjectURL(url);
        this.downloading.set(null);
      },
      error: () => {
        this.downloading.set(null);
        this.toast.error("Échec de l'export");
      },
    });
  }
}

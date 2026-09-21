import { ChangeDetectionStrategy, Component, computed, inject } from '@angular/core';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';

import { PdfPreviewService } from '../../core/services/pdf-preview.service';
import { ButtonComponent } from '../button/button.component';
import { IconComponent } from '../icon/icon.component';
import { SpinnerComponent } from '../spinner/spinner.component';

/**
 * Fenêtre modale globale d'aperçu PDF, montée une seule fois dans `AppComponent`.
 * Pilotée entièrement par `PdfPreviewService` : n'importe quel écran peut appeler
 * `pdfPreviewService.open(...)` pour afficher un PDF (Blob authentifié) en aperçu,
 * avec un bouton de téléchargement natif — fiable sur tous les navigateurs.
 */
@Component({
  selector: 'pnlf-pdf-preview-modal',
  standalone: true,
  imports: [ButtonComponent, SpinnerComponent, IconComponent],
  templateUrl: './pdf-preview-modal.component.html',
  styleUrl: './pdf-preview-modal.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PdfPreviewModalComponent {
  private readonly sanitizer = inject(DomSanitizer);
  readonly service = inject(PdfPreviewService);

  readonly state = this.service.state;

  readonly safeUrl = computed<SafeResourceUrl | null>(() => {
    const url = this.state().objectUrl;
    return url ? this.sanitizer.bypassSecurityTrustResourceUrl(url) : null;
  });

  download(): void {
    this.service.download();
  }

  close(): void {
    this.service.close();
  }

  onBackdropClick(event: MouseEvent): void {
    if (event.target === event.currentTarget) {
      this.close();
    }
  }
}

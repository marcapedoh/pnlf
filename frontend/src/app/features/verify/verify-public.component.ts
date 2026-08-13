import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, ElementRef, OnDestroy, ViewChild, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { LotVerification, STATUT_LOT_LABELS } from '../../core/models/lot.model';
import { LotsService } from '../../core/services/lots.service';
import { lotStatusTone } from '../../core/ui/status-tone.util';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { SpinnerComponent } from '../../design-system/spinner/spinner.component';
import { StatusBadgeComponent } from '../../design-system/badge/status-badge.component';

@Component({
  selector: 'app-verify-public',
  imports: [RouterLink, FormsModule, DatePipe, AlertBannerComponent, ButtonComponent, SpinnerComponent, StatusBadgeComponent],
  templateUrl: './verify-public.component.html',
  styleUrl: './verify-public.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class VerifyPublicComponent implements OnDestroy {
  private readonly lotsService = inject(LotsService);
  private readonly route = inject(ActivatedRoute);

  @ViewChild('qrReader') qrReaderRef?: ElementRef<HTMLDivElement>;

  readonly code = signal('');
  readonly loading = signal(false);
  readonly searched = signal(false);
  readonly result = signal<LotVerification | null>(null);
  readonly errorMessage = signal('');
  readonly scannerActive = signal(false);

  readonly statutLabels = STATUT_LOT_LABELS;
  readonly tone = lotStatusTone;

  private scanner: any = null;

  constructor() {
    const uuidFromRoute = this.route.snapshot.paramMap.get('uuid');
    if (uuidFromRoute) {
      this.code.set(uuidFromRoute);
      this.verify(uuidFromRoute);
    }
  }

  ngOnDestroy(): void {
    this.stopScanner();
  }

  extractUuid(raw: string): string {
    const trimmed = raw.trim();
    const parts = trimmed.split('/').filter(Boolean);
    return parts[parts.length - 1] || trimmed;
  }

  submit(): void {
    const uuid = this.extractUuid(this.code());
    if (!uuid) return;
    this.verify(uuid);
  }

  private verify(uuid: string): void {
    this.loading.set(true);
    this.searched.set(true);
    this.errorMessage.set('');
    this.result.set(null);

    this.lotsService.verifyPublic(uuid).subscribe({
      next: (res) => {
        this.result.set(res);
        this.loading.set(false);
      },
      error: () => {
        this.errorMessage.set(
          "Aucun lot correspondant n'a été trouvé. Vérifiez le code saisi ou l'intégrité du QR scanné.",
        );
        this.loading.set(false);
      },
    });
  }

  async toggleScanner(): Promise<void> {
    if (this.scannerActive()) {
      this.stopScanner();
      return;
    }
    this.scannerActive.set(true);
    setTimeout(async () => {
      try {
        const { Html5Qrcode } = await import('html5-qrcode');
        this.scanner = new Html5Qrcode('qr-reader');
        await this.scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: 240 },
          (decodedText: string) => {
            this.code.set(decodedText);
            this.stopScanner();
            this.verify(this.extractUuid(decodedText));
          },
          () => {},
        );
      } catch {
        this.scannerActive.set(false);
        this.errorMessage.set(
          "Impossible d'accéder à la caméra. Vérifiez les autorisations de votre navigateur.",
        );
      }
    }, 50);
  }

  private stopScanner(): void {
    if (this.scanner) {
      this.scanner.stop().catch(() => {});
      this.scanner.clear();
      this.scanner = null;
    }
    this.scannerActive.set(false);
  }

  reset(): void {
    this.code.set('');
    this.result.set(null);
    this.searched.set(false);
    this.errorMessage.set('');
  }
}

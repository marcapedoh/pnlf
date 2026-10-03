import { ChangeDetectionStrategy, Component, ElementRef, OnDestroy, ViewChild, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';

import { HttpErrorResponse } from '@angular/common/http';

import { LotPublicComplet, LotPublicIndisponible } from '../../core/models/lot.model';
import { LotsService } from '../../core/services/lots.service';
import { AlertBannerComponent } from '../../design-system/alert/alert-banner.component';
import { ButtonComponent } from '../../design-system/button/button.component';
import { IconComponent } from '../../design-system/icon/icon.component';
import { SpinnerComponent } from '../../design-system/spinner/spinner.component';
import { LotPublicFicheComponent } from '../lots/lot-public-fiche/lot-public-fiche.component';

@Component({
  selector: 'app-verify-public',
  imports: [
    FormsModule,
    RouterLink,
    AlertBannerComponent,
    ButtonComponent,
    SpinnerComponent,
    IconComponent,
    LotPublicFicheComponent,
  ],
  templateUrl: './verify-public.component.html',
  styleUrl: './verify-public.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class VerifyPublicComponent implements OnDestroy {
  private readonly lotsService = inject(LotsService);
  private readonly route = inject(ActivatedRoute);

  @ViewChild('qrReader') qrReaderRef?: ElementRef<HTMLDivElement>;
  @ViewChild('fileInput') fileInputRef?: ElementRef<HTMLInputElement>;

  readonly code = signal('');
  readonly loading = signal(false);
  readonly searched = signal(false);
  readonly result = signal<LotPublicComplet | null>(null);
  readonly errorMessage = signal('');
  /** Lot connu mais encore en brouillon : non vérifiable publiquement. */
  readonly lotNonValide = signal<string | null>(null);
  readonly scannerActive = signal(false);
  readonly fileScanning = signal(false);
  readonly dragActive = signal(false);

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

  /** Accepte le contenu brut du QR (« PNLF:<uuid> »), un lien de vérification ou l'identifiant seul. */
  extractUuid(raw: string): string {
    const trimmed = raw.trim();
    const uuid = trimmed.match(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i);
    if (uuid) return uuid[0].toLowerCase();
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
    this.lotNonValide.set(null);
    this.result.set(null);

    this.lotsService.verifyPublic(uuid).subscribe({
      next: (res) => {
        this.result.set(res);
        this.loading.set(false);
      },
      error: (err: unknown) => {
        const corps = err instanceof HttpErrorResponse ? (err.error as LotPublicIndisponible | null) : null;
        if (corps?.code === 'LOT_NON_VALIDE') {
          this.lotNonValide.set(corps.code_lot ?? '');
          this.errorMessage.set(corps.detail);
        } else if (err instanceof HttpErrorResponse && (err.status === 0 || err.status >= 500)) {
          this.errorMessage.set('La vérification est momentanément indisponible. Vérifiez votre connexion puis réessayez.');
        } else {
          this.errorMessage.set(
            "Aucun lot correspondant n'a été trouvé. Vérifiez le code saisi ou l'intégrité du QR scanné.",
          );
        }
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

  // --- Import d'une photo contenant un QR code (drag & drop ou sélection) ---

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.dragActive.set(true);
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.dragActive.set(false);
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.dragActive.set(false);
    const file = event.dataTransfer?.files?.[0];
    if (file) this.scanImageFile(file);
  }

  openFilePicker(): void {
    this.fileInputRef?.nativeElement.click();
  }

  onFileInputChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (file) this.scanImageFile(file);
    input.value = '';
  }

  private async scanImageFile(file: File): Promise<void> {
    if (!file.type.startsWith('image/')) {
      this.errorMessage.set('Le fichier sélectionné doit être une image (JPEG, PNG…).');
      this.searched.set(true);
      return;
    }
    this.fileScanning.set(true);
    this.errorMessage.set('');
    try {
      const { Html5Qrcode } = await import('html5-qrcode');
      const reader = new Html5Qrcode('qr-reader-file');
      const decodedText = await reader.scanFile(file, false);
      reader.clear();
      this.fileScanning.set(false);
      this.code.set(decodedText);
      this.verify(this.extractUuid(decodedText));
    } catch {
      this.fileScanning.set(false);
      this.searched.set(true);
      this.errorMessage.set(
        "Aucun QR code détecté sur cette image. Essayez une photo plus nette et bien cadrée, ou saisissez le code manuellement.",
      );
    }
  }

  reset(): void {
    this.code.set('');
    this.result.set(null);
    this.searched.set(false);
    this.errorMessage.set('');
    this.lotNonValide.set(null);
  }

  partager(r: LotPublicComplet): void {
    const url = `${window.location.origin}/verifier/${r.uuid_public}`;
    if (navigator.share) {
      navigator.share({ title: `Lot ${r.code_lot}`, url }).catch(() => {});
      return;
    }
    navigator.clipboard?.writeText(url);
  }

  imprimer(): void {
    window.print();
  }
}

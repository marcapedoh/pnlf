import { HttpErrorResponse } from '@angular/common/http';
import { Injectable, signal } from '@angular/core';
import { Observable } from 'rxjs';

import { messageFromDownloadError, triggerBrowserDownload } from '../http/download-file.util';

export interface PdfPreviewState {
  open: boolean;
  loading: boolean;
  objectUrl: string | null;
  filename: string;
  title: string;
  error: string | null;
}

const INITIAL_STATE: PdfPreviewState = {
  open: false,
  loading: false,
  objectUrl: null,
  filename: 'document.pdf',
  title: 'Aperçu du document',
  error: null,
};

/**
 * Aperçu PDF fiable et universel : le PDF est récupéré en Blob via une requête HTTP
 * authentifiée classique (le token JWT est déjà attaché par l'intercepteur HTTP), puis
 * affiché dans une fenêtre modale via une URL objet (`URL.createObjectURL`).
 *
 * Cette approche évite complètement l'ouverture d'un onglet via `window.open()` suivie
 * d'une navigation asynchrone : ce mécanisme est bloqué/annulé par les navigateurs
 * modernes (Chrome renvoie `net::ERR_ABORTED`) car il n'est pas rattaché à un geste
 * utilisateur direct. L'aperçu intégré fonctionne sur Chrome, Firefox, Edge et Safari,
 * en local comme en production, et permet à l'utilisateur de visualiser le document
 * avant de le télécharger.
 */
@Injectable({ providedIn: 'root' })
export class PdfPreviewService {
  private readonly _state = signal<PdfPreviewState>(INITIAL_STATE);
  readonly state = this._state.asReadonly();

  private currentBlob: Blob | null = null;
  private currentRequest: { unsubscribe(): void } | null = null;

  /**
   * Lance la génération du PDF (via `fetcher`) et affiche l'aperçu dans la modale.
   * @param title Titre affiché en haut de la modale.
   * @param filename Nom de fichier proposé lors du téléchargement.
   * @param fetcher Fonction renvoyant un Observable<Blob> (résultat de l'appel API).
   */
  open(title: string, filename: string, fetcher: () => Observable<Blob>): void {
    this.reset();
    this._state.set({ ...INITIAL_STATE, open: true, loading: true, title, filename });
    this.currentRequest = fetcher().subscribe({
      next: (blob) => {
        if (!blob || blob.size < 8) {
          this._state.update((s) => ({ ...s, loading: false, error: 'Le document PDF généré est vide.' }));
          return;
        }
        this.currentBlob = blob;
        const objectUrl = URL.createObjectURL(blob);
        this._state.update((s) => ({ ...s, loading: false, objectUrl }));
      },
      error: (err) => {
        this._state.update((s) => ({ ...s, loading: false, error: this.resolveError(err) }));
      },
    });
  }

  /** Déclenche le téléchargement natif du PDF déjà affiché en aperçu. */
  download(): void {
    if (this.currentBlob) {
      triggerBrowserDownload(this.currentBlob, this._state().filename);
    }
  }

  close(): void {
    this.currentRequest?.unsubscribe();
    this.reset();
  }

  private resolveError(err: unknown): string {
    if (err instanceof HttpErrorResponse && err.error instanceof Blob) {
      // Le backend a répondu avec un Blob JSON d'erreur (ex: 403/500) au lieu d'un PDF.
      return messageFromDownloadError(err);
    }
    return messageFromDownloadError(err);
  }

  private reset(): void {
    const s = this._state();
    if (s.objectUrl) URL.revokeObjectURL(s.objectUrl);
    this.currentBlob = null;
    this.currentRequest = null;
    this._state.set(INITIAL_STATE);
  }
}

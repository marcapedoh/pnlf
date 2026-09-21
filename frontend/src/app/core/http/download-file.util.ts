import { HttpClient, HttpContext, HttpErrorResponse } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { map, Observable } from 'rxjs';

import { SKIP_GLOBAL_ERROR_TOAST, SKIP_LOADING_BAR } from './http-context-tokens';

/**
 * En-tête standard signalant un appel AJAX (et non une navigation/téléchargement natif).
 * De nombreux gestionnaires de téléchargement tiers installés dans le navigateur
 * (Internet Download Manager, EagleGet, Free Download Manager...) excluent les requêtes
 * portant cet en-tête de leur interception — utile en complément de la suppression des
 * en-têtes `Content-Disposition` côté serveur pour ces mêmes endpoints.
 */
export const AJAX_EXPORT_HEADERS = { 'X-Requested-With': 'XMLHttpRequest' };

/**
 * Déclenche le téléchargement natif d'un Blob déjà en mémoire (CSV, Excel, PDF...).
 * Fonctionne sur tous les navigateurs modernes ; utilisé notamment par
 * `PdfPreviewService` après affichage de l'aperçu.
 */
export function triggerBrowserDownload(data: Blob, filename: string): void {
  const nav = window.navigator as Navigator & {
    msSaveOrOpenBlob?: (blob: Blob, name: string) => void;
  };
  if (typeof nav.msSaveOrOpenBlob === 'function') {
    nav.msSaveOrOpenBlob(data, filename);
    return;
  }
  const href = URL.createObjectURL(data);
  const link = document.createElement('a');
  link.href = href;
  link.download = filename;
  link.rel = 'noopener';
  link.style.display = 'none';
  document.body.appendChild(link);
  link.click();
  link.remove();
  window.setTimeout(() => URL.revokeObjectURL(href), 60_000);
}

function looksLikeJsonError(buffer: ArrayBuffer): string | null {
  if (buffer.byteLength < 2) return null;
  const head = new TextDecoder('latin1').decode(new Uint8Array(buffer, 0, Math.min(8, buffer.byteLength)));
  if (head.startsWith('%PDF') || head.startsWith('PK')) return null;
  if (!head.startsWith('{') && !head.startsWith('[')) return null;
  try {
    const parsed = JSON.parse(new TextDecoder().decode(buffer)) as { detail?: string; message?: string };
    return parsed.detail || parsed.message || "Le serveur n'a pas renvoyé le fichier demandé.";
  } catch {
    return "Le serveur n'a pas renvoyé le fichier demandé.";
  }
}

export function messageFromDownloadError(error: unknown): string {
  if (error instanceof HttpErrorResponse) {
    if (error.status === 403) return "Vous n'avez pas les droits pour exporter ce document.";
    if (error.status === 401) return 'Session expirée, veuillez vous reconnecter.';
    if (error.status === 0) return 'Impossible de joindre le serveur. Vérifiez que Django tourne sur le port 8000.';
    if (error.status === 406) return 'Le serveur a refusé le type de fichier. Rechargez la page puis réessayez.';
    if (error.status >= 500) return 'Erreur serveur pendant la génération du document.';
  }
  if (error instanceof Error && error.message) {
    if (/failed to fetch/i.test(error.message)) {
      return 'Impossible de joindre le serveur. Vérifiez que Django tourne sur le port 8000, puis rechargez la page.';
    }
    return error.message;
  }
  return "Échec de l'export. Réessayez dans un instant.";
}

@Injectable({ providedIn: 'root' })
export class FileDownloadService {
  private readonly http = inject(HttpClient);

  download(url: string, filename: string, mime: string): Observable<void> {
    const context = new HttpContext()
      .set(SKIP_LOADING_BAR, true)
      .set(SKIP_GLOBAL_ERROR_TOAST, true);
    return this.http
      .get(url, {
        responseType: 'arraybuffer',
        context,
        headers: { Accept: '*/*', ...AJAX_EXPORT_HEADERS },
      })
      .pipe(
        map((buffer) => {
          if (!buffer || buffer.byteLength < 8) {
            throw new Error("Le fichier d'export est vide.");
          }
          const jsonError = looksLikeJsonError(buffer);
          if (jsonError) throw new Error(jsonError);
          triggerBrowserDownload(new Blob([buffer], { type: mime }), filename);
        }),
      );
  }
}

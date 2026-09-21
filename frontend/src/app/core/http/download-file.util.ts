import { HttpClient, HttpContext, HttpErrorResponse } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { map, Observable } from 'rxjs';

import { SKIP_GLOBAL_ERROR_TOAST, SKIP_LOADING_BAR } from './http-context-tokens';

/**
 * CSV / Excel (XHR + Blob) — OK pour ces formats.
 * PDF : ne pas utiliser cette voie (Chrome interrompt le XHR). Voir triggerNativeGet.
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

/** URL même origine (proxy Angular /api). */
export function toSameOriginUrl(url: string): string {
  if (/^https?:\/\//i.test(url)) return url;
  const path = url.startsWith('/') ? url : `/${url}`;
  return `${window.location.origin}${path}`;
}

/**
 * Ouvre le PDF dans un onglet déjà ouvert pendant le clic utilisateur.
 * Les iframes cachées sont bloquées par Chrome/Brave (X-Frame-Options + politique de téléchargement).
 */
export function navigateOpenedTab(tab: Window | null, url: string): boolean {
  const href = toSameOriginUrl(url);
  if (!tab || tab.closed) return false;
  try {
    tab.location.replace(href);
    return true;
  } catch {
    return false;
  }
}

/**
 * Ouvre un onglet immédiatement (pendant le clic utilisateur, pour éviter le blocage
 * de pop-up), puis le fait naviguer vers l'URL du ticket PDF une fois généré côté
 * serveur. Retourne l'onglet (ou null si bloqué) pour permettre un repli affichage
 * d'un lien cliquable si le navigateur a quand même bloqué l'ouverture.
 */
export function openPdfTicketTab(): Window | null {
  return window.open('', '_blank');
}

export function writePdfLoadingPlaceholder(tab: Window | null): void {
  if (!tab) return;
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
        headers: { Accept: '*/*' },
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

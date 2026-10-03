import { HttpErrorResponse } from '@angular/common/http';

import { ApiError } from '../models/common.model';

const GENERIC_MESSAGE =
  'Votre demande n’a pas pu être traitée. Vérifiez les informations saisies puis réessayez.';
const GLOBAL_KEYS = new Set(['detail', 'message', 'non_field_errors', 'code', 'attente_secondes']);

export const MESSAGES_HTTP: Record<number, string> = {
  400: GENERIC_MESSAGE,
  401: 'Votre session a expiré ou n’est plus valide. Reconnectez-vous pour continuer.',
  403: 'Vous n’avez pas les droits nécessaires pour effectuer cette action avec votre profil.',
  404: 'L’élément demandé est introuvable : il a peut-être été supprimé ou l’adresse est erronée.',
  405: 'Cette action n’est pas autorisée sur cet élément.',
  408: 'Le serveur a mis trop de temps à répondre. Vérifiez votre connexion puis réessayez.',
  409: 'Cet élément a été modifié entre-temps. Rechargez la page pour voir la version à jour.',
  413: 'Le fichier envoyé est trop volumineux. Réduisez sa taille (photo compressée, PDF allégé) puis réessayez.',
  415: 'Le format du fichier ou des données envoyées n’est pas pris en charge.',
  429: 'Trop de requêtes en peu de temps : patientez un instant avant de réessayer.',
  500: 'Le serveur a rencontré une erreur inattendue. Réessayez dans quelques instants ; si le problème persiste, contactez l’assistance.',
  502: 'Le serveur démarre ou est momentanément indisponible (cela peut prendre jusqu’à une minute après une période d’inactivité). Patientez puis réessayez.',
  503: 'Le service est momentanément indisponible, probablement en cours de démarrage. Patientez une minute puis réessayez.',
  504: 'Le serveur met trop de temps à répondre, il est peut-être en cours de démarrage. Patientez une minute puis réessayez.',
};

const MESSAGE_HORS_LIGNE =
  'Vous semblez hors ligne : vérifiez votre connexion internet (Wi-Fi ou données mobiles), puis réessayez.';
const MESSAGE_INJOIGNABLE =
  'Le serveur ne répond pas. Il redémarre peut-être après une période d’inactivité (jusqu’à une minute) : patientez un instant puis réessayez. Si le problème persiste, vérifiez votre connexion internet.';
const MESSAGE_DELAI_DEPASSE =
  'Le serveur a mis trop de temps à répondre. Il est peut-être en cours de démarrage : réessayez dans un instant.';

function asMessages(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.flatMap((v) =>
      typeof v === 'string' || typeof v === 'number' ? [String(v)] : v && typeof v === 'object' ? flattenObject(v) : [],
    );
  }
  if (typeof value === 'string') return [value];
  if (value && typeof value === 'object') return flattenObject(value);
  return [];
}

function flattenObject(value: object): string[] {
  return Object.values(value).flatMap((v) => asMessages(v));
}

/** Délai d'attente en secondes indiqué par le serveur (corps `attente_secondes` ou en-tête Retry-After). */
export function delaiAttenteSecondes(error: HttpErrorResponse): number | null {
  const body = error.error as { attente_secondes?: unknown } | null;
  const depuisCorps = body && typeof body === 'object' ? Number(body.attente_secondes) : NaN;
  if (Number.isFinite(depuisCorps) && depuisCorps > 0) return Math.ceil(depuisCorps);
  const entete = Number(error.headers?.get('Retry-After'));
  return Number.isFinite(entete) && entete > 0 ? Math.ceil(entete) : null;
}

function libelleDelai(secondes: number): string {
  if (secondes < 60) return `${secondes} seconde${secondes > 1 ? 's' : ''}`;
  const minutes = Math.ceil(secondes / 60);
  return `${minutes} minute${minutes > 1 ? 's' : ''}`;
}

function messageReseau(): string {
  return typeof navigator !== 'undefined' && navigator.onLine === false ? MESSAGE_HORS_LIGNE : MESSAGE_INJOIGNABLE;
}

/** Traduit une erreur HTTP DRF en structure exploitable par les formulaires et l'UI. */
export function toApiError(error: unknown): ApiError {
  if (!(error instanceof HttpErrorResponse)) {
    if (error instanceof Error && error.name === 'TimeoutError') {
      return { status: 408, message: MESSAGE_DELAI_DEPASSE, code: 'timeout' };
    }
    return {
      status: 0,
      message: 'Une erreur inattendue est survenue dans l’application. Rechargez la page puis réessayez.',
    };
  }

  if (error.status === 0) {
    return { status: 0, message: messageReseau(), code: 'network_error' };
  }
  if (error.status === 502 || error.status === 503 || error.status === 504) {
    return { status: error.status, message: MESSAGES_HTTP[error.status], code: 'server_unavailable' };
  }

  const body = error.error;
  let message = '';
  const fieldErrors: Record<string, string[]> = {};
  let code: string | undefined;

  if (typeof body === 'string' && body.trim() && !body.trim().startsWith('<') && body.length < 500) {
    message = body;
  } else if (body && typeof body === 'object' && !(body instanceof Blob) && !(body instanceof ArrayBuffer)) {
    if (typeof body.detail === 'string') {
      message = body.detail;
    } else if (typeof body.message === 'string') {
      message = body.message;
    }
    if (typeof body.code === 'string') code = body.code;
    const globales = asMessages(body.non_field_errors);
    if (!message && globales.length) message = globales.join(' ');
    for (const [key, val] of Object.entries(body)) {
      if (GLOBAL_KEYS.has(key)) continue;
      const messages = asMessages(val);
      if (messages.length) fieldErrors[key] = messages;
    }
    if (!message && Object.keys(fieldErrors).length) {
      const nb = Object.keys(fieldErrors).length;
      message = nb > 1
        ? `${nb} champs sont à corriger : ${Object.values(fieldErrors)[0][0]}`
        : Object.values(fieldErrors)[0][0];
    }
  }

  if (error.status === 429) {
    const delai = delaiAttenteSecondes(error);
    if (!message || !/\d/.test(message)) {
      message = delai
        ? `Trop de requêtes en peu de temps : par sécurité, réessayez dans ${libelleDelai(delai)}.`
        : MESSAGES_HTTP[429];
    }
  }
  if (!message) {
    message = MESSAGES_HTTP[error.status] ?? (error.status >= 500 ? MESSAGES_HTTP[500] : GENERIC_MESSAGE);
  }

  return { status: error.status, message, fieldErrors, raw: body, code };
}

/** Variante asynchrone pour les réponses binaires (exports en Blob/ArrayBuffer) dont le corps d'erreur est du JSON. */
export async function toApiErrorAsync(error: unknown): Promise<ApiError> {
  if (error instanceof HttpErrorResponse && (error.error instanceof Blob || error.error instanceof ArrayBuffer)) {
    try {
      const texte = error.error instanceof Blob ? await error.error.text() : new TextDecoder().decode(error.error);
      const corps = JSON.parse(texte);
      return toApiError(
        new HttpErrorResponse({
          error: corps, status: error.status, statusText: error.statusText, headers: error.headers, url: error.url ?? undefined,
        }),
      );
    } catch {
      return toApiError(new HttpErrorResponse({ status: error.status, headers: error.headers }));
    }
  }
  return toApiError(error);
}

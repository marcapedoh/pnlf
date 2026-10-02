import { HttpErrorResponse } from '@angular/common/http';

import { ApiError } from '../models/common.model';

const GENERIC_MESSAGE = 'Une erreur est survenue lors du traitement de votre demande.';
const GLOBAL_KEYS = new Set(['detail', 'message', 'non_field_errors', 'code']);

function asMessages(value: unknown): string[] {
  if (Array.isArray(value)) return value.filter((v) => typeof v === 'string' || typeof v === 'number').map(String);
  if (typeof value === 'string') return [value];
  return [];
}

/** Traduit une erreur HTTP DRF en structure exploitable par les formulaires et l'UI. */
export function toApiError(error: unknown): ApiError {
  if (!(error instanceof HttpErrorResponse)) {
    return { status: 0, message: 'Une erreur inattendue est survenue.' };
  }

  if (error.status === 0) {
    return {
      status: 0,
      message: 'Impossible de joindre le serveur. Vérifiez votre connexion internet, puis réessayez.',
    };
  }

  const body = error.error;
  let message = '';
  const fieldErrors: Record<string, string[]> = {};
  let code: string | undefined;

  if (typeof body === 'string' && body.trim() && !body.trim().startsWith('<')) {
    message = body;
  } else if (body && typeof body === 'object' && !(body instanceof Blob)) {
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
      message = Object.values(fieldErrors)[0][0];
    }
  }

  if (!message) {
    if (error.status === 401) message = 'Votre session a expiré. Veuillez vous reconnecter.';
    else if (error.status === 403) message = "Vous n'avez pas les droits nécessaires pour cette action.";
    else if (error.status === 404) message = 'Élément introuvable. Il a peut-être été supprimé.';
    else if (error.status === 413) message = 'Fichier trop volumineux.';
    else if (error.status === 429) message = 'Trop de tentatives. Patientez une minute avant de réessayer.';
    else message = GENERIC_MESSAGE;
  }
  if (error.status >= 500) {
    message = 'Le serveur a rencontré une erreur. Veuillez réessayer dans quelques instants.';
  }

  return { status: error.status, message, fieldErrors, raw: body, code };
}

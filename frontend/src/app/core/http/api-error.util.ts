import { HttpErrorResponse } from '@angular/common/http';

import { ApiError } from '../models/common.model';

/** Traduit une erreur HTTP DRF en structure exploitable par les formulaires et l'UI. */
export function toApiError(error: unknown): ApiError {
  if (!(error instanceof HttpErrorResponse)) {
    return { status: 0, message: 'Une erreur inattendue est survenue.' };
  }

  if (error.status === 0) {
    return {
      status: 0,
      message:
        "Impossible de joindre le serveur. Vérifiez votre connexion, puis réessayez d’enregistrer.",
    };
  }

  const body = error.error;
  let message = "Une erreur est survenue lors du traitement de votre demande.";
  const fieldErrors: Record<string, string[]> = {};

  if (typeof body === 'string') {
    message = body;
  } else if (body && typeof body === 'object') {
    if (typeof body.detail === 'string') {
      message = body.detail;
    } else if (typeof body.message === 'string') {
      message = body.message;
    }
    for (const [key, val] of Object.entries(body)) {
      if (key === 'detail' || key === 'message') continue;
      if (Array.isArray(val)) {
        fieldErrors[key] = val.map(String);
      } else if (typeof val === 'string') {
        fieldErrors[key] = [val];
      }
    }
    if (message === "Une erreur est survenue lors du traitement de votre demande." && Object.keys(fieldErrors).length) {
      message = Object.values(fieldErrors)[0][0];
    }
  }

  if (error.status === 401) message = message || 'Session expirée, veuillez vous reconnecter.';
  if (error.status === 403) message = message || "Vous n'avez pas les droits nécessaires pour cette action.";
  if (error.status === 404) message = message || "Ressource introuvable.";
  if (error.status >= 500) message = "Le serveur a rencontré une erreur. Veuillez réessayer dans quelques instants.";

  return { status: error.status, message, fieldErrors, raw: body };
}

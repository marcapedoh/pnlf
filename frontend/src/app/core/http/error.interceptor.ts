import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { catchError, throwError } from 'rxjs';

import { ToastService } from '../../design-system/toast/toast.service';
import { toApiError } from './api-error.util';
import { SKIP_GLOBAL_ERROR_TOAST } from './http-context-tokens';

/**
 * Filet de sécurité global : affiche un toast pour les erreurs réseau/serveur
 * non gérées explicitement par un composant. Les erreurs 400/401/403 sont
 * laissées à la charge des composants (formulaires, guards) pour un traitement fin.
 */
export const errorInterceptor: HttpInterceptorFn = (req, next) => {
  const toast = inject(ToastService);

  return next(req).pipe(
    catchError((error: unknown) => {
      if (req.context.get(SKIP_GLOBAL_ERROR_TOAST)) {
        return throwError(() => error);
      }
      if (error instanceof HttpErrorResponse && (error.status === 0 || error.status >= 500)) {
        const apiError = toApiError(error);
        toast.error('Problème de connexion', apiError.message);
      }
      return throwError(() => error);
    }),
  );
};

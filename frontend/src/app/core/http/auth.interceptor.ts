import {
  HttpErrorResponse,
  HttpEvent,
  HttpHandlerFn,
  HttpInterceptorFn,
  HttpRequest,
} from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { BehaviorSubject, catchError, filter, Observable, switchMap, take, throwError } from 'rxjs';

import { environment } from '../../../environments/environment';
import { AuthService } from '../auth/auth.service';
import { TokenStorageService } from '../auth/token-storage.service';
import { SKIP_AUTH_REDIRECT } from './http-context-tokens';

const PUBLIC_PATHS = [
  '/auth/login/',
  '/auth/refresh/',
  '/verify/',
  '/public/',
  '/accounts/password-reset',
];

/** Code renvoyé par l'API tant que le mot de passe provisoire n'a pas été changé. */
const PASSWORD_CHANGE_REQUIRED = 'password_change_required';

let isRefreshing = false;
const refreshedToken$ = new BehaviorSubject<string | null>(null);

/** Comparaison sur le début du chemin : « /rapports/inscriptions/ » n'est pas public. */
function isPublicPath(url: string): boolean {
  const chemin = url.startsWith(environment.apiUrl) ? url.slice(environment.apiUrl.length) : url;
  return PUBLIC_PATHS.some((p) => chemin.startsWith(p));
}

function isApiRequest(url: string): boolean {
  return url.startsWith(environment.apiUrl);
}

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const tokens = inject(TokenStorageService);
  const auth = inject(AuthService);
  const router = inject(Router);

  const isApi = isApiRequest(req.url);
  const accessToken = tokens.getAccessToken();

  const authorizedReq =
    isApi && accessToken && !isPublicPath(req.url)
      ? req.clone({ setHeaders: { Authorization: `Bearer ${accessToken}` } })
      : req;

  return next(authorizedReq).pipe(
    catchError((error: unknown) => {
      if (
        error instanceof HttpErrorResponse &&
        error.status === 403 &&
        isApi &&
        error.error?.code === PASSWORD_CHANGE_REQUIRED
      ) {
        auth.updateCurrentUser({ doit_changer_mdp: true });
        if (!router.url.startsWith('/changer-mot-de-passe')) {
          router.navigate(['/changer-mot-de-passe']);
        }
        return throwError(() => error);
      }
      if (
        error instanceof HttpErrorResponse &&
        error.status === 401 &&
        isApi &&
        !isPublicPath(req.url)
      ) {
        if (req.context.get(SKIP_AUTH_REDIRECT)) {
          return throwError(() => error);
        }
        return handle401(req, next, auth, router);
      }
      return throwError(() => error);
    }),
  );
};

function handle401(
  req: HttpRequest<unknown>,
  next: HttpHandlerFn,
  auth: AuthService,
  router: Router,
): Observable<HttpEvent<unknown>> {
  if (!isRefreshing) {
    isRefreshing = true;
    refreshedToken$.next(null);

    return auth.refresh().pipe(
      switchMap((newToken) => {
        isRefreshing = false;
        if (!newToken) {
          router.navigate(['/connexion']);
          return throwError(() => new Error('Session expirée'));
        }
        refreshedToken$.next(newToken);
        return next(req.clone({ setHeaders: { Authorization: `Bearer ${newToken}` } }));
      }),
      catchError((err) => {
        isRefreshing = false;
        router.navigate(['/connexion']);
        return throwError(() => err);
      }),
    );
  }

  return refreshedToken$.pipe(
    filter((token): token is string => token !== null),
    take(1),
    switchMap((token) => next(req.clone({ setHeaders: { Authorization: `Bearer ${token}` } }))),
  );
}

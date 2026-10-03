import { provideHttpClient, withInterceptors } from '@angular/common/http';
import {
  ApplicationConfig,
  LOCALE_ID,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
  isDevMode,
  inject,
} from '@angular/core';
import {
  provideRouter,
  withComponentInputBinding,
  withInMemoryScrolling,
  withViewTransitions,
} from '@angular/router';
import { provideServiceWorker } from '@angular/service-worker';
import { firstValueFrom } from 'rxjs';

import { routes } from './app.routes';
import { AuthService } from './core/auth/auth.service';
import { authInterceptor } from './core/http/auth.interceptor';
import { errorInterceptor } from './core/http/error.interceptor';
import { loadingInterceptor } from './core/http/loading.interceptor';
import { moderationInterceptor } from './core/http/moderation.interceptor';
import { registerLocaleFr } from './core/i18n/register-locale-fr';

registerLocaleFr();

export const appConfig: ApplicationConfig = {
  providers: [
    { provide: LOCALE_ID, useValue: 'fr' },
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withComponentInputBinding(),
      withViewTransitions(),
      // Permet aux liens de sommaire (ex. pages légales, href="#section") de faire défiler
      // vers l'ancre ciblée au lieu de déclencher une navigation complète vers l'accueil —
      // voir RouterLink + [fragment] dans confidentialite/conditions-utilisation.
      withInMemoryScrolling({ anchorScrolling: 'enabled', scrollPositionRestoration: 'enabled' }),
    ),
    provideHttpClient(withInterceptors([authInterceptor, loadingInterceptor, errorInterceptor, moderationInterceptor])),
    provideAppInitializer(() => {
      const auth = inject(AuthService);
      return firstValueFrom(auth.bootstrap());
    }),
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      // Vérifie immédiatement une nouvelle version (évite CSS/HTML périmés en prod)
      registrationStrategy: 'registerImmediately',
    }),
  ],
};

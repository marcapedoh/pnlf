import { HttpInterceptorFn, HttpResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { tap } from 'rxjs';

import { ToastService } from '../../design-system/toast/toast.service';

/** En-tête posé par l'API quand une image envoyée est mise en attente de vérification (modération IA). */
export const EN_TETE_MODERATION_IMAGE = 'X-Moderation-Image';

export const moderationInterceptor: HttpInterceptorFn = (req, next) => {
  if (req.method === 'GET' || req.method === 'HEAD') return next(req);
  const toast = inject(ToastService);
  return next(req).pipe(
    tap((event) => {
      if (event instanceof HttpResponse && event.headers.get(EN_TETE_MODERATION_IMAGE) === 'EN_ATTENTE') {
        toast.show(
          'info',
          'Image en cours de vérification',
          'Votre image a bien été enregistrée. Elle sera visible par les autres utilisateurs après vérification par un administrateur.',
          9000,
        );
      }
    }),
  );
};

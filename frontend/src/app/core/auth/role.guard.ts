import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { RoleUtilisateur } from '../models/user.model';
import { AuthService } from './auth.service';

export function roleGuard(...roles: RoleUtilisateur[]): CanActivateFn {
  return () => {
    const auth = inject(AuthService);
    const router = inject(Router);

    if (auth.hasRole(...roles)) {
      return true;
    }

    return router.createUrlTree(['/app/acces-refuse']);
  };
}

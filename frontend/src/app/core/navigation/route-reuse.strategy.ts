import { Injectable } from '@angular/core';
import { ActivatedRouteSnapshot, BaseRouteReuseStrategy } from '@angular/router';

/**
 * Les fiches de détail lisent leur identifiant une seule fois (snapshot) : ouvrir une autre fiche
 * du même type (cloche de notifications, lien interne) doit recréer le composant.
 */
@Injectable()
export class ParamsRouteReuseStrategy extends BaseRouteReuseStrategy {
  override shouldReuseRoute(future: ActivatedRouteSnapshot, curr: ActivatedRouteSnapshot): boolean {
    if (future.routeConfig !== curr.routeConfig) {
      return false;
    }
    const a = future.params;
    const b = curr.params;
    const cles = Object.keys(a);
    return cles.length === Object.keys(b).length && cles.every((cle) => a[cle] === b[cle]);
  }
}

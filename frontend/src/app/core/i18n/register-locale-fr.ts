import { registerLocaleData } from '@angular/common';
import localeFr from '@angular/common/locales/fr';
import localeFrExtra from '@angular/common/locales/extra/fr';

export function registerLocaleFr(): void {
  registerLocaleData(localeFr, 'fr-FR', localeFrExtra);
}

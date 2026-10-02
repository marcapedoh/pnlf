import { Pipe, PipeTransform } from '@angular/core';

import {
  DateFormat,
  formatDateFr,
  formatMontant,
  formatQuantite,
  formatTelephone,
  libelleDevise,
  libelleUnite,
} from '../../core/format/format.util';

/** `{{ lot.date_collecte | pnlfDate }}` -> 27/09/2026 ; `| pnlfDate: 'datetime'` -> 27/09/2026 à 14:05. */
@Pipe({ name: 'pnlfDate' })
export class PnlfDatePipe implements PipeTransform {
  transform(value: string | Date | null | undefined, format: DateFormat = 'date'): string {
    return formatDateFr(value, format);
  }
}

/** `{{ lot.quantite | pnlfQuantite: lot.unite }}` -> 150 bottes. */
@Pipe({ name: 'pnlfQuantite' })
export class PnlfQuantitePipe implements PipeTransform {
  transform(value: number | string | null | undefined, unite?: string | null): string {
    return formatQuantite(value, unite);
  }
}

/** `{{ lot.prix_indicatif | pnlfMontant: lot.devise }}` -> 500 FCFA. */
@Pipe({ name: 'pnlfMontant' })
export class PnlfMontantPipe implements PipeTransform {
  transform(value: number | string | null | undefined, devise?: string | null): string {
    return formatMontant(value, devise);
  }
}

/** `{{ p.telephone | pnlfTelephone }}` -> +241 077 00 02 06. */
@Pipe({ name: 'pnlfTelephone' })
export class PnlfTelephonePipe implements PipeTransform {
  transform(value: string | null | undefined): string {
    return formatTelephone(value);
  }
}

/** `{{ 'BOTTE' | pnlfUnite: 2 }}` -> bottes. */
@Pipe({ name: 'pnlfUnite' })
export class PnlfUnitePipe implements PipeTransform {
  transform(value: string | null | undefined, quantite?: number | string | null): string {
    return libelleUnite(value, quantite);
  }
}

/** `{{ 'XAF' | pnlfDevise }}` -> FCFA. */
@Pipe({ name: 'pnlfDevise' })
export class PnlfDevisePipe implements PipeTransform {
  transform(value: string | null | undefined): string {
    return libelleDevise(value);
  }
}

export const PNLF_FORMAT_PIPES = [
  PnlfDatePipe,
  PnlfQuantitePipe,
  PnlfMontantPipe,
  PnlfTelephonePipe,
  PnlfUnitePipe,
  PnlfDevisePipe,
] as const;

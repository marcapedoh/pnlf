import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

import { todayIso } from '../format/format.util';

export const TELEPHONE_MESSAGE = 'Format attendu : +241 77 00 01 02';

/** Même règle que le serveur : espaces . - ( ) ignorés, puis 8 à 20 chiffres avec + facultatif. */
export function normaliserTelephone(value: string | null | undefined): string {
  return (value ?? '').replace(/[\s.\-()]/g, '');
}

export const telephoneValidator: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
  const value = (control.value ?? '').toString().trim();
  if (!value) return null;
  return /^\+?\d{8,20}$/.test(normaliserTelephone(value)) ? null : { telephone: true };
};

/** Refuse une date (yyyy-MM-dd) postérieure à aujourd'hui (fuseau du navigateur). */
export const dateNotFutureValidator: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
  const value = (control.value ?? '').toString();
  if (!value) return null;
  return value.slice(0, 10) > todayIso() ? { dateFuture: true } : null;
};

/** Refuse une date égale ou postérieure à aujourd'hui (date de naissance). */
export const datePastValidator: ValidatorFn = (control: AbstractControl): ValidationErrors | null => {
  const value = (control.value ?? '').toString();
  if (!value) return null;
  return value.slice(0, 10) >= todayIso() ? { datePast: true } : null;
};

function rangeValidator(min: number, max: number, key: string): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const raw = (control.value ?? '').toString().trim().replace(',', '.');
    if (!raw) return null;
    const n = Number(raw);
    if (!Number.isFinite(n)) return { [key]: { min, max } };
    return n < min || n > max ? { [key]: { min, max } } : null;
  };
}

/** Bornes du territoire gabonais (alignées sur config/validators.py côté serveur). */
export const latitudeGabonValidator = rangeValidator(-4, 2.5, 'latitudeGabon');
export const longitudeGabonValidator = rangeValidator(8.5, 14.6, 'longitudeGabon');

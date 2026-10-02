import { ElementRef } from '@angular/core';
import { AbstractControl, FormArray, FormGroup } from '@angular/forms';

import { ApiError } from '../models/common.model';
import { TELEPHONE_MESSAGE } from '../validators/pnlf.validators';

/** Message lisible pour la première erreur d'un contrôle (affiché après interaction ou soumission). */
export function controlError(control: AbstractControl | null | undefined, requiredMessage = 'Ce champ est requis.'): string {
  if (!control || !control.errors || !(control.touched || control.dirty)) return '';
  const e = control.errors;
  if (e['server']) return String(e['server']);
  if (e['required']) return requiredMessage;
  if (e['email']) return 'Adresse e-mail invalide (exemple : nom@domaine.ga).';
  if (e['telephone']) return TELEPHONE_MESSAGE;
  if (e['minlength']) return `Saisissez au moins ${e['minlength'].requiredLength} caractères.`;
  if (e['maxlength']) return `Saisissez au maximum ${e['maxlength'].requiredLength} caractères.`;
  if (e['min']) return `La valeur doit être supérieure ou égale à ${e['min'].min}.`;
  if (e['max']) return `La valeur doit être inférieure ou égale à ${e['max'].max}.`;
  if (e['dateFuture']) return 'La date ne peut pas être postérieure à aujourd’hui.';
  if (e['datePast']) return 'La date doit être antérieure à aujourd’hui.';
  if (e['latitudeGabon']) return 'La latitude doit être comprise entre -4 et 2,5 (territoire gabonais).';
  if (e['longitudeGabon']) return 'La longitude doit être comprise entre 8,5 et 14,6 (territoire gabonais).';
  if (e['pattern']) return 'Format invalide.';
  return 'Valeur invalide.';
}

function countInvalid(control: AbstractControl): number {
  if (control instanceof FormGroup || control instanceof FormArray) {
    return Object.values(control.controls).reduce((n, c) => n + countInvalid(c), 0);
  }
  return control.invalid && !control.disabled ? 1 : 0;
}

function hostElement(host: ElementRef<HTMLElement> | HTMLElement | null | undefined): HTMLElement | null {
  if (!host) return null;
  return host instanceof ElementRef ? host.nativeElement : host;
}

/** Donne le focus au premier champ invalide (dans l'ordre du DOM) du conteneur. */
export function focusFirstInvalid(host: ElementRef<HTMLElement> | HTMLElement | null | undefined): void {
  const root = hostElement(host);
  if (!root) return;
  setTimeout(() => {
    const invalid = root.querySelector<HTMLElement>(
      '[formcontrolname].ng-invalid, [aria-invalid="true"], input.ng-invalid, select.ng-invalid, textarea.ng-invalid',
    );
    if (!invalid) return;
    const focusable = invalid.matches('input, select, textarea, button')
      ? invalid
      : invalid.querySelector<HTMLElement>('input, select, textarea, button');
    (focusable ?? invalid).scrollIntoView({ block: 'center', behavior: 'smooth' });
    focusable?.focus({ preventScroll: true });
  });
}

/**
 * Révèle les erreurs d'un formulaire soumis invalide : marque tous les champs comme touchés,
 * place le focus sur le premier champ en erreur et renvoie un message global à afficher.
 */
export function revealFormErrors(
  form: AbstractControl,
  host?: ElementRef<HTMLElement> | HTMLElement | null,
): string {
  form.markAllAsTouched();
  focusFirstInvalid(host);
  const n = countInvalid(form);
  if (n <= 1) return 'Le formulaire contient une erreur. Corrigez le champ signalé.';
  return `Le formulaire contient ${n} erreurs. Corrigez les champs signalés.`;
}

/**
 * Rattache les erreurs de validation renvoyées par l'API aux champs du formulaire
 * (`setErrors({ server })`). `aliases` traduit un nom de champ API vers un nom de contrôle.
 * Renvoie les messages qui n'ont pu être rattachés à aucun champ.
 */
export function applyServerErrors(
  form: AbstractControl,
  error: ApiError,
  aliases: Record<string, string> = {},
): string[] {
  const restants: string[] = [];
  for (const [champ, messages] of Object.entries(error.fieldErrors ?? {})) {
    const control = form.get(aliases[champ] ?? champ);
    const message = messages.join(' ');
    if (control) {
      control.setErrors({ ...(control.errors ?? {}), server: message });
      control.markAsTouched();
    } else {
      restants.push(message);
    }
  }
  return restants;
}

/**
 * Traite une erreur API sur un formulaire : rattache les erreurs aux champs, met le focus sur
 * le premier et renvoie le message global le plus utile.
 */
export function handleFormApiError(
  form: AbstractControl,
  error: ApiError,
  host?: ElementRef<HTMLElement> | HTMLElement | null,
  aliases: Record<string, string> = {},
): string {
  const restants = applyServerErrors(form, error, aliases);
  const attaches = Object.keys(error.fieldErrors ?? {}).length - restants.length;
  if (attaches > 0) {
    focusFirstInvalid(host);
    return restants[0] ?? 'Certaines informations sont invalides. Corrigez les champs signalés.';
  }
  return restants[0] ?? error.message;
}

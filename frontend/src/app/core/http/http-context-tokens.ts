import { HttpContextToken } from '@angular/common/http';

/** Empêche l'affichage de la barre de progression globale pour une requête (ex: polling). */
export const SKIP_LOADING_BAR = new HttpContextToken<boolean>(() => false);

/** Empêche le toast global « Problème de connexion » (polling, téléchargements). */
export const SKIP_GLOBAL_ERROR_TOAST = new HttpContextToken<boolean>(() => false);

/** Empêche la redirection automatique vers /login en cas de 401 (ex: vérification silencieuse). */
export const SKIP_AUTH_REDIRECT = new HttpContextToken<boolean>(() => false);

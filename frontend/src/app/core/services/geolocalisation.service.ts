import { Injectable } from '@angular/core';

export interface PositionGps {
  latitude: number;
  longitude: number;
  precisionMetres: number;
}

export type EtatAutorisation = 'granted' | 'denied' | 'prompt' | 'unsupported';

/** Erreur de géolocalisation portant un message français destiné à l'utilisateur. */
export class ErreurGeolocalisation extends Error {
  constructor(
    readonly code: 'non_supporte' | 'contexte_non_securise' | 'refus' | 'indisponible' | 'delai',
    message: string,
  ) {
    super(message);
  }
}

/**
 * Accès à la position de l'appareil avec demande d'autorisation explicite du navigateur.
 * Compatible Chrome, Edge, Firefox, Safari (macOS et iOS) et navigateurs Android récents.
 */
@Injectable({ providedIn: 'root' })
export class GeolocalisationService {
  get estDisponible(): boolean {
    return typeof navigator !== 'undefined' && 'geolocation' in navigator;
  }

  async etatAutorisation(): Promise<EtatAutorisation> {
    if (!this.estDisponible) return 'unsupported';
    try {
      const statut = await navigator.permissions?.query({ name: 'geolocation' as PermissionName });
      return (statut?.state as EtatAutorisation) ?? 'prompt';
    } catch {
      return 'prompt';
    }
  }

  /**
   * Demande la position courante. Le navigateur affiche sa fenêtre d'autorisation si
   * l'utilisateur ne l'a pas encore accordée.
   */
  positionActuelle(options: { hautePrecision?: boolean; delaiMs?: number } = {}): Promise<PositionGps> {
    if (!this.estDisponible) {
      return Promise.reject(
        new ErreurGeolocalisation(
          'non_supporte',
          "Votre navigateur ne permet pas la géolocalisation. Saisissez les coordonnées manuellement.",
        ),
      );
    }
    if (typeof window !== 'undefined' && window.isSecureContext === false) {
      return Promise.reject(
        new ErreurGeolocalisation(
          'contexte_non_securise',
          'La géolocalisation exige une connexion sécurisée (https). Saisissez les coordonnées manuellement.',
        ),
      );
    }
    const tenter = (hautePrecision: boolean, delai: number) =>
      new Promise<GeolocationPosition>((resolve, reject) =>
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: hautePrecision,
          timeout: delai,
          maximumAge: 60_000,
        }),
      );
    const delai = options.delaiMs ?? 15_000;
    return tenter(options.hautePrecision ?? true, delai)
      .catch((err: GeolocationPositionError) => {
        if (err.code === err.PERMISSION_DENIED) throw err;
        return tenter(false, delai);
      })
      .then((pos) => ({
        latitude: pos.coords.latitude,
        longitude: pos.coords.longitude,
        precisionMetres: Math.round(pos.coords.accuracy),
      }))
      .catch((err: GeolocationPositionError | ErreurGeolocalisation) => {
        if (err instanceof ErreurGeolocalisation) throw err;
        throw this.traduire(err);
      });
  }

  private traduire(err: GeolocationPositionError): ErreurGeolocalisation {
    switch (err.code) {
      case err.PERMISSION_DENIED:
        return new ErreurGeolocalisation(
          'refus',
          "L'accès à votre position a été refusé. Autorisez la localisation pour ce site dans les réglages du navigateur (icône à gauche de l'adresse), puis réessayez.",
        );
      case err.TIMEOUT:
        return new ErreurGeolocalisation(
          'delai',
          'La position n’a pas pu être obtenue à temps. Rapprochez-vous d’une fenêtre ou activez le GPS, puis réessayez.',
        );
      default:
        return new ErreurGeolocalisation(
          'indisponible',
          'Votre position est indisponible pour le moment. Vérifiez que la localisation de l’appareil est activée.',
        );
    }
  }
}

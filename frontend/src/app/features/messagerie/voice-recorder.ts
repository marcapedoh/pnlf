/** État de l'autorisation micro selon la Permissions API (« inconnu » si le navigateur ne l'expose pas). */
export type EtatAutorisationMicro = 'granted' | 'denied' | 'prompt' | 'inconnu';

export class ErreurMicro extends Error {}

/**
 * Ordre de préférence : AAC dans MP4 se lit partout (Safari compris) ; Opus dans WebM ou Ogg
 * couvre Chrome, Edge, Firefox, Chrome Android et Samsung Internet.
 */
const TYPES_PREFERES = [
  'audio/mp4;codecs=mp4a.40.2',
  'audio/webm;codecs=opus',
  'audio/ogg;codecs=opus',
  'audio/mp4',
  'audio/aac',
  'audio/webm',
  'audio/ogg',
];

const DUREE_MINIMALE_MS = 800;

export function typeEnregistrementSupporte(): string {
  if (typeof MediaRecorder === 'undefined' || typeof MediaRecorder.isTypeSupported !== 'function') return '';
  return TYPES_PREFERES.find((t) => MediaRecorder.isTypeSupported(t)) ?? '';
}

export function extensionPourType(mime: string): string {
  const t = mime.toLowerCase();
  if (t.includes('webm')) return 'webm';
  if (t.includes('ogg')) return 'ogg';
  if (t.startsWith('audio/aac')) return 'aac';
  if (t.includes('mp4') || t.includes('m4a')) return 'm4a';
  return 'webm';
}

/** Message français si l'enregistrement est impossible dans ce contexte, sinon null. */
export function incompatibiliteMicro(): string | null {
  if (typeof window === 'undefined') return 'Enregistrement vocal indisponible.';
  if (!window.isSecureContext) {
    return 'Le micro n’est accessible que sur une connexion sécurisée (adresse en https). Ouvrez la plateforme via son adresse https pour enregistrer un message vocal.';
  }
  if (!navigator.mediaDevices?.getUserMedia) {
    return 'Votre navigateur ne donne pas accès au micro. Mettez-le à jour ou utilisez une version récente de Chrome, Edge, Firefox, Safari ou Samsung Internet.';
  }
  if (typeof MediaRecorder === 'undefined') {
    return 'Votre navigateur ne sait pas enregistrer de l’audio. Mettez-le à jour (Safari 14.5 ou plus récent, Chrome, Edge, Firefox).';
  }
  return null;
}

export async function etatAutorisationMicro(): Promise<EtatAutorisationMicro> {
  try {
    if (!navigator.permissions?.query) return 'inconnu';
    const statut = await navigator.permissions.query({ name: 'microphone' as PermissionName });
    return statut.state;
  } catch {
    return 'inconnu';
  }
}

export function messageErreurMicro(err: unknown): string {
  const nom = (err as { name?: string } | null)?.name ?? '';
  switch (nom) {
    case 'NotAllowedError':
    case 'PermissionDeniedError':
    case 'SecurityError':
      return 'Accès au micro refusé. Autorisez le micro pour ce site dans les réglages du navigateur (icône à gauche de l’adresse, ou Réglages > Safari > Micro sur iPhone), puis réessayez.';
    case 'NotFoundError':
    case 'DevicesNotFoundError':
    case 'OverconstrainedError':
      return 'Aucun micro détecté. Branchez ou activez un micro, puis réessayez.';
    case 'NotReadableError':
    case 'TrackStartError':
    case 'AbortError':
      return 'Le micro est déjà utilisé par une autre application (appel, visioconférence, dictaphone). Fermez-la, puis réessayez.';
    case 'TypeError':
      return 'Le micro n’est accessible que sur une connexion sécurisée (adresse en https).';
    default:
      return 'Impossible d’accéder au micro. Vérifiez les réglages de votre navigateur, puis réessayez.';
  }
}

/** Enregistrement d'un message vocal : démarrage, arrêt avec fichier prêt à l'envoi, annulation. */
export class EnregistreurVocal {
  private stream: MediaStream | null = null;
  private recorder: MediaRecorder | null = null;
  private chunks: Blob[] = [];
  private debut = 0;
  private garder = false;
  private resoudre: ((fichier: File | null) => void) | null = null;

  /** Appelé si l'enregistrement s'interrompt de lui-même (micro débranché, piste coupée). */
  onInterruption: (() => void) | null = null;

  get actif(): boolean {
    return !!this.recorder && this.recorder.state !== 'inactive';
  }

  dureeMs(): number {
    return this.debut ? Date.now() - this.debut : 0;
  }

  async demarrer(): Promise<void> {
    const incompatible = incompatibiliteMicro();
    if (incompatible) throw new ErreurMicro(incompatible);
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true },
      });
    } catch (err) {
      throw new ErreurMicro(messageErreurMicro(err));
    }
    const mime = typeEnregistrementSupporte();
    try {
      this.recorder = mime ? new MediaRecorder(this.stream, { mimeType: mime }) : new MediaRecorder(this.stream);
    } catch {
      this.couperPistes();
      throw new ErreurMicro('Votre navigateur ne parvient pas à démarrer l’enregistrement audio. Mettez-le à jour, puis réessayez.');
    }
    this.chunks = [];
    this.garder = false;
    this.recorder.ondataavailable = (e) => {
      if (e.data && e.data.size) this.chunks.push(e.data);
    };
    this.recorder.onstop = () => this.finaliser(mime);
    this.stream.getAudioTracks().forEach((piste) => {
      piste.onended = () => {
        if (this.actif) this.onInterruption?.();
      };
    });
    this.recorder.start();
    this.debut = Date.now();
  }

  /** Arrête et renvoie le fichier audio (null si trop court ou vide). */
  arreter(): Promise<File | null> {
    if (!this.recorder || this.recorder.state === 'inactive') {
      this.couperPistes();
      return Promise.resolve(null);
    }
    this.garder = this.dureeMs() >= DUREE_MINIMALE_MS;
    return new Promise((resolve) => {
      this.resoudre = resolve;
      this.recorder!.stop();
    });
  }

  annuler(): void {
    this.garder = false;
    this.resoudre = null;
    if (this.recorder && this.recorder.state !== 'inactive') {
      this.recorder.stop();
    } else {
      this.couperPistes();
    }
  }

  private finaliser(mimeDemande: string): void {
    const type = (this.recorder?.mimeType || mimeDemande || this.chunks[0]?.type || 'audio/webm').split(';')[0].trim();
    const blob = new Blob(this.chunks, { type });
    this.couperPistes();
    this.recorder = null;
    this.debut = 0;
    this.chunks = [];
    const resoudre = this.resoudre;
    this.resoudre = null;
    if (!resoudre) return;
    if (!this.garder || blob.size === 0) {
      resoudre(null);
      return;
    }
    resoudre(new File([blob], `message-vocal.${extensionPourType(type)}`, { type }));
  }

  private couperPistes(): void {
    this.stream?.getTracks().forEach((piste) => {
      piste.onended = null;
      piste.stop();
    });
    this.stream = null;
  }
}

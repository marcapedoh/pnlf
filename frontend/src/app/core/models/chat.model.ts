export interface ChatParticipant {
  id: string;
  nom: string;
  role: string;
  role_libelle?: string | null;
  organisation?: string | null;
  photo_url?: string | null;
}

export interface Conversation {
  id: string;
  sujet: string | null;
  offre_id: string | null;
  producteur_id: string | null;
  cooperative_id: string | null;
  est_groupe?: boolean;
  created_at: string;
  participants: ChatParticipant[];
  interlocuteur_nom: string;
  interlocuteur_photo_url?: string | null;
  dernier_message: string | null;
  dernier_at: string | null;
  non_lus?: number;
  lecture_seule?: boolean;
}

export type MessageStatut = 'ENVOYE' | 'RECU' | 'LU';

export interface ChatMessage {
  id: string;
  conversation: string;
  expediteur_id: string;
  expediteur_nom: string | null;
  expediteur_photo_url?: string | null;
  contenu: string | null;
  piece_type: 'IMAGE' | 'AUDIO' | null;
  piece_url: string | null;
  /** Type MIME réel de la pièce (ex. audio/webm, audio/mp4), pour vérifier la lecture côté navigateur. */
  piece_mime?: string | null;
  statut?: MessageStatut | null;
  lu_at: string | null;
  created_at: string;
}

export interface ChatContact {
  id: string;
  nom: string;
  prenoms: string;
  role: string;
  /** Rôle en français ; pour un producteur : Producteur, Collecteur ou Récolteur. */
  role_libelle?: string | null;
  organisation?: string | null;
  libelle: string;
  photo_url?: string | null;
}

/** Filtres rapides du panneau « Nouvelle discussion » (paramètre `role` de l'API contacts). */
export type ContactFiltreRole = '' | 'PRODUCTEUR' | 'COOPERATIVE' | 'ACHETEUR' | 'AGENT';

export const CONTACT_FILTRES: { value: ContactFiltreRole; label: string }[] = [
  { value: '', label: 'Tous' },
  { value: 'PRODUCTEUR', label: 'Producteurs' },
  { value: 'COOPERATIVE', label: 'Coopératives' },
  { value: 'ACHETEUR', label: 'Acheteurs' },
  { value: 'AGENT', label: 'Agents' },
];

export interface CoopMembreOption {
  id: string;
  nom: string;
  prenoms: string;
  role: string;
  libelle: string;
  photo_url?: string | null;
}

export interface CoopGroupeOption {
  id: string;
  nom: string;
  membres: CoopMembreOption[];
}

export interface ChatParticipant {
  id: string;
  nom: string;
  role: string;
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
  statut?: MessageStatut | null;
  lu_at: string | null;
  created_at: string;
}

export interface ChatContact {
  id: string;
  nom: string;
  prenoms: string;
  role: string;
  libelle: string;
  photo_url?: string | null;
}

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

import { AnnonceDetails } from './annonce.model';

export interface PnlfNotification {
  id: string;
  type_notif: string;
  titre: string;
  corps: string;
  lue: boolean;
  envoyee_at: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

export type StatutOffreDemande = 'EN_VALIDATION' | 'OUVERTE' | 'REJETEE' | 'CLOTUREE';

export const STATUT_OFFRE_DEMANDE_LABELS: Record<StatutOffreDemande, string> = {
  EN_VALIDATION: 'En attente de validation',
  OUVERTE: 'Publiée',
  REJETEE: 'Rejetée',
  CLOTUREE: 'Clôturée',
};

export interface OffreDemande extends AnnonceDetails {
  id: string;
  type_annonce: 'OFFRE' | 'DEMANDE';
  auteur_id: string;
  auteur_nom?: string | null;
  produit_id: string;
  produit_nom?: string | null;
  province_id: string | null;
  province_nom?: string | null;
  quantite: number | null;
  unite: string | null;
  prix_unitaire: number | null;
  devise: string;
  titre: string;
  description: string | null;
  certification_requise: boolean;
  statut: StatutOffreDemande;
  expire_at: string | null;
  uuid_public?: string | null;
  photos_urls?: string[];
  qr_image_url?: string | null;
  created_at: string;
  updated_at: string;
}

export interface Conversation {
  id: string;
  sujet: string | null;
  offre_id: string | null;
  created_at: string;
}

export interface Message {
  id: string;
  conversation: string;
  expediteur_id: string;
  contenu: string;
  lu_at: string | null;
  created_at: string;
}

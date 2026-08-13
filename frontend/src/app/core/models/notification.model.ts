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

export interface OffreDemande {
  id: string;
  type_annonce: 'OFFRE' | 'DEMANDE';
  auteur_id: string;
  produit_id: string;
  province_id: string | null;
  quantite: number | null;
  unite: string | null;
  prix_unitaire: number | null;
  devise: string;
  titre: string;
  description: string | null;
  certification_requise: boolean;
  statut: 'OUVERTE' | 'CLOTUREE' | 'ANNULEE';
  expire_at: string | null;
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

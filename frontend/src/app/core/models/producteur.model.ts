export enum StatutProducteur {
  ACTIF = 'ACTIF',
  INACTIF = 'INACTIF',
  EN_VALIDATION = 'EN_VALIDATION',
  REJETE = 'REJETE',
}

export enum TypeActeur {
  PRODUCTEUR = 'PRODUCTEUR',
  COLLECTEUR = 'COLLECTEUR',
}

export interface DocumentInscription {
  type_document: 'CNI' | 'FICHE_CIRCUIT' | 'AGREMENT_NAGOYA' | 'AUTRE';
  nom_original: string | null;
  url: string | null;
  created_at: string;
}

export interface Producteur {
  id: string;
  code_producteur: string;
  nom: string;
  prenoms: string;
  date_naissance: string | null;
  type_acteur: TypeActeur;
  type_piece_identite: string | null;
  numero_piece: string | null;
  telephone: string | null;
  email: string | null;
  communaute: string | null;
  province: string;
  province_nom: string;
  departement: string | null;
  village: string | null;
  latitude: number | null;
  longitude: number | null;
  cooperative: string | null;
  cooperative_nom?: string | null;
  utilisateur_id: string | null;
  statut: StatutProducteur;
  valide_par_id: string | null;
  valide_at: string | null;
  notes: string | null;
  visible_public?: boolean;
  photo_url?: string | null;
  documents?: DocumentInscription[];
  client_uuid: string | null;
  created_at: string;
  updated_at: string;
}

export const STATUT_PRODUCTEUR_LABELS: Record<StatutProducteur, string> = {
  [StatutProducteur.ACTIF]: 'Actif',
  [StatutProducteur.INACTIF]: 'Inactif',
  [StatutProducteur.EN_VALIDATION]: 'En attente de validation',
  [StatutProducteur.REJETE]: 'Rejeté',
};

export enum StatutCooperative {
  ACTIF = 'ACTIF',
  INACTIF = 'INACTIF',
  EN_VALIDATION = 'EN_VALIDATION',
  REJETE = 'REJETE',
}

export const STATUT_COOPERATIVE_LABELS: Record<StatutCooperative, string> = {
  [StatutCooperative.ACTIF]: 'Active',
  [StatutCooperative.INACTIF]: 'Inactive',
  [StatutCooperative.EN_VALIDATION]: 'En attente de validation',
  [StatutCooperative.REJETE]: 'Rejetée',
};

export interface Cooperative {
  id: string;
  code: string;
  nom: string;
  numero_agrement: string | null;
  telephone: string | null;
  email: string | null;
  adresse: string | null;
  province: string | null;
  province_nom: string | null;
  utilisateur_id: string | null;
  actif: boolean;
  statut: StatutCooperative;
  photo_url?: string | null;
  created_at: string;
  updated_at: string;
}

export interface CooperativeMembre {
  cooperative: string;
  producteur: string;
  producteur_nom: string;
  date_adhesion: string;
  actif: boolean;
  created_at: string;
}

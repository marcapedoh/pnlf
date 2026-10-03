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

export type TypeDocumentInscription = 'CNI' | 'FICHE_CIRCUIT' | 'AGREMENT_NAGOYA' | 'AUTRE';

export interface DocumentInscription {
  id?: string;
  type_document: TypeDocumentInscription;
  type_libelle?: string;
  nom_original: string | null;
  format?: string | null;
  url: string | null;
  created_at: string;
}

/** Justificatifs gérés depuis la fiche producteur/collecteur (même stockage que l'inscription publique). */
export const DOCUMENTS_FICHE_PRODUCTEUR: { type: TypeDocumentInscription; libelle: string; aide: string }[] = [
  { type: 'CNI', libelle: "Pièce d'identité", aide: "Copie lisible de la pièce d'identité déclarée." },
  { type: 'FICHE_CIRCUIT', libelle: 'Fiche circuit', aide: 'Fiche décrivant le circuit de collecte ou de vente.' },
  { type: 'AGREMENT_NAGOYA', libelle: 'Agrément CITES / Nagoya', aide: 'Agrément ou autorisation délivrée par l’administration.' },
];

export const TYPES_PIECE_IDENTITE: { value: string; label: string }[] = [
  { value: 'CNI', label: "Carte nationale d'identité" },
  { value: 'PASSEPORT', label: 'Passeport' },
  { value: 'CARTE_SEJOUR', label: 'Carte de séjour' },
  { value: 'CARTE_CONSULAIRE', label: 'Carte consulaire' },
  { value: 'PERMIS_CONDUIRE', label: 'Permis de conduire' },
  { value: 'ACTE_NAISSANCE', label: 'Acte de naissance' },
  { value: 'AUTRE', label: 'Autre pièce officielle' },
];

export interface ProduitExploite {
  id: string;
  nom: string;
}

export interface Producteur {
  id: string;
  code_producteur: string;
  nom: string;
  prenoms: string;
  date_naissance: string | null;
  type_acteur: TypeActeur;
  type_piece_identite: string | null;
  type_piece_identite_libelle?: string | null;
  numero_piece: string | null;
  telephone: string | null;
  email: string | null;
  communaute: string | null;
  province: string;
  province_nom: string;
  departement: string | null;
  departement_nom?: string | null;
  village: string | null;
  village_nom?: string | null;
  /** Produits exploités (lecture). À l'écriture, envoyer la liste des identifiants. */
  produits?: ProduitExploite[];
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
  /** Situation du producteur connecté vis-à-vis de cette coopérative (null pour les autres profils). */
  mon_adhesion?: MonAdhesion | null;
  /** Invitation en attente adressée par cette coopérative au producteur connecté. */
  mon_invitation?: { id: string; message: string | null; created_at: string } | null;
  documents?: DocumentInscription[];
  created_at: string;
  updated_at: string;
}

export type MonAdhesion = 'MEMBRE' | 'EN_ATTENTE' | 'AUTRE_COOPERATIVE' | 'INVITE' | 'DEMANDE_AILLEURS';

export type StatutInvitation = 'EN_ATTENTE' | 'ACCEPTEE' | 'REFUSEE' | 'ANNULEE' | 'CADUQUE';

export interface InvitationCooperative {
  id: string;
  cooperative: string;
  cooperative_nom: string;
  cooperative_code: string;
  cooperative_province: string | null;
  cooperative_photo_url: string | null;
  producteur: string;
  producteur_nom: string;
  producteur_code: string;
  producteur_type_acteur: TypeActeur;
  statut: StatutInvitation;
  statut_libelle: string;
  message: string | null;
  motif_reponse: string | null;
  created_at: string;
  repondu_at: string | null;
}

export interface CandidatInvitation {
  id: string;
  nom: string;
  prenoms: string;
  code_producteur: string;
  type_acteur: TypeActeur;
  province_nom: string | null;
  communaute: string | null;
  photo_url: string | null;
  a_un_compte: boolean;
  invitation_en_attente: boolean;
  demande_en_attente: boolean;
}

export interface CooperativeMembre {
  cooperative: string;
  producteur: string;
  producteur_nom: string;
  date_adhesion: string;
  actif: boolean;
  created_at: string;
}

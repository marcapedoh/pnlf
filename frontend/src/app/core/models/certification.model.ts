export enum StatutCertification {
  DEMANDEE = 'DEMANDEE',
  EN_COURS = 'EN_COURS',
  OBTENUE = 'OBTENUE',
  EXPIREE = 'EXPIREE',
  REFUSEE = 'REFUSEE',
  REVOQUEE = 'REVOQUEE',
}

export const STATUT_CERTIFICATION_LABELS: Record<StatutCertification, string> = {
  [StatutCertification.DEMANDEE]: 'Demandée',
  [StatutCertification.EN_COURS]: 'En cours',
  [StatutCertification.OBTENUE]: 'Obtenue',
  [StatutCertification.EXPIREE]: 'Expirée',
  [StatutCertification.REFUSEE]: 'Refusée',
  [StatutCertification.REVOQUEE]: 'Révoquée',
};

export interface TypeCertification {
  id: string;
  code: string;
  libelle: string;
  organisme: string | null;
  description: string | null;
  duree_mois: number | null;
  actif: boolean;
  created_at: string;
}

export interface Certification {
  id: string;
  type_certification: string;
  type_libelle: string;
  type_organisme?: string | null;
  type_description?: string | null;
  type_duree_mois?: number | null;
  lot: string | null;
  lot_code?: string | null;
  producteur: string | null;
  producteur_nom?: string | null;
  numero_certificat: string | null;
  statut: StatutCertification;
  date_demande: string;
  date_obtention: string | null;
  date_expiration: string | null;
  document_path: string | null;
  document_url?: string | null;
  valide_par_id: string | null;
  observations: string | null;
  /** Pièces justificatives du dossier (url nulle pour les profils qui ne peuvent pas les consulter). */
  pieces?: PieceCertification[];
  created_at: string;
  updated_at: string;
}

export interface PieceCertification {
  id: string;
  intitule: string;
  nom_original: string | null;
  type_mime: string | null;
  taille_octets: number | null;
  url: string | null;
  created_at: string;
}

/** Contraintes des pièces justificatives, identiques à celles contrôlées par l'API. */
export const PIECES_CERTIFICATION_MAX = 10;
export const PIECE_TAILLE_MAX_OCTETS = 8 * 1024 * 1024;
export const PIECE_INTITULE_MAX = 150;
export const PIECES_EXTENSIONS = ['.pdf', '.jpg', '.jpeg', '.png'];
export const PIECES_ACCEPT = '.pdf,.jpg,.jpeg,.png,application/pdf,image/jpeg,image/png';

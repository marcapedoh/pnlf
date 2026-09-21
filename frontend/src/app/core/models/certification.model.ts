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
  created_at: string;
  updated_at: string;
}

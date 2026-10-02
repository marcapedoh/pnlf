import { TypeActeur } from './producteur.model';

export interface PublicStats {
  nb_producteurs_actifs: number;
  nb_collecteurs: number;
  nb_lots_traces: number;
  nb_produits: number;
  nb_provinces: number;
  nb_cooperatives: number;
}

export interface PublicProvince {
  id: string;
  nom: string;
  code: string;
}

export interface PublicLotInfo {
  id: string;
  code_lot: string;
  produit_nom: string;
  quantite: number;
  unite: string;
  qualite_indicateur: string | null;
  prix_indicatif: number | null;
  devise: string;
  date_collecte: string;
  statut: string;
  statut_libelle?: string;
  uuid_public?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  photos_urls: string[];
  mouvements?: { type_libelle: string; date_mouvement: string; lieu_libelle: string | null }[];
}

export interface PublicLotProducteurSummary {
  id: string;
  nom: string;
  prenoms: string;
  type_acteur: TypeActeur | null;
  communaute: string | null;
  province_nom: string | null;
  cooperative_nom: string | null;
  photo_url: string | null;
}

export interface PublicLotDetail extends PublicLotInfo {
  producteur: PublicLotProducteurSummary;
}

export interface PublicOffreDemande {
  id: string;
  type_annonce: 'OFFRE' | 'DEMANDE';
  auteur_nom?: string | null;
  produit_nom?: string | null;
  province_nom?: string | null;
  quantite: number | null;
  unite: string | null;
  prix_unitaire: number | null;
  devise: string;
  titre: string;
  description: string | null;
  certification_requise: boolean;
  statut: string;
  photos_urls?: string[];
  qr_image_url?: string | null;
  created_at: string;
}

export interface PublicOffresResponse {
  count: number;
  results: PublicOffreDemande[];
}

export interface PublicProducteur {
  id: string;
  nom: string;
  prenoms: string;
  type_acteur: TypeActeur;
  communaute: string | null;
  province: string;
  province_nom: string;
  cooperative_nom: string | null;
  photo_url: string | null;
  produits: string[];
  nb_lots: number;
  certifications: string[];
  lots?: PublicLotInfo[];
  compte_connecte?: boolean;
}

export interface PublicProduit {
  id: string;
  code: string;
  nom: string;
  nom_scientifique: string | null;
  categorie_libelle: string;
  description: string | null;
  image_url: string | null;
}

export interface PublicProducteursResponse {
  count: number;
  results: PublicProducteur[];
}

export interface ContactPublicPayload {
  nom_visiteur: string;
  email_visiteur: string;
  telephone_visiteur?: string;
  message: string;
  site_web?: string;
}

export interface MessagePublic {
  id: string;
  producteur: string;
  nom_visiteur: string;
  email_visiteur: string;
  telephone_visiteur: string | null;
  message: string;
  statut: 'NOUVEAU' | 'TRAITE';
  created_at: string;
  traite_at: string | null;
}

export const TYPE_ACTEUR_PUBLIC_LABELS: Record<TypeActeur, string> = {
  [TypeActeur.PRODUCTEUR]: 'Producteur',
  [TypeActeur.COLLECTEUR]: 'Collecteur',
};

export interface PublicDepartement {
  id: string;
  nom: string;
  code: string;
  province_id: string;
}

export interface PublicVillage {
  id: string;
  nom: string;
  departement_id: string;
}

export type TypeDemandeInscription = 'PRODUCTEUR' | 'COLLECTEUR' | 'COOPERATIVE' | 'ACHETEUR';

export interface InscriptionPubliquePayload {
  type_demande: TypeDemandeInscription;
  nom: string;
  prenoms?: string;
  email: string;
  telephone: string;
  date_naissance?: string;
  latitude?: number;
  longitude?: number;
  password: string;
  password_confirmation: string;
  photo?: File;
  document_cni?: File;
  document_fiche_circuit?: File;
  document_agrement_nagoya?: File;
  province?: string;
  departement?: string;
  village?: string;
  communaute?: string;
  adresse?: string;
  numero_agrement?: string;
  message?: string;
  accepte_conditions: boolean;
  site_web?: string;
}

export interface InscriptionPubliqueResponse {
  detail: string;
  email: string;
  numero_dossier?: string;
  fiche_id?: string;
}

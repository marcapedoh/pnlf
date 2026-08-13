export enum StatutLot {
  BROUILLON = 'BROUILLON',
  DECLARE = 'DECLARE',
  VALIDE = 'VALIDE',
  EN_TRANSIT = 'EN_TRANSIT',
  TRANSFORME = 'TRANSFORME',
  COMMERCIALISE = 'COMMERCIALISE',
  ARCHIVE = 'ARCHIVE',
  ANNULE = 'ANNULE',
}

export const STATUT_LOT_LABELS: Record<StatutLot, string> = {
  [StatutLot.BROUILLON]: 'Brouillon',
  [StatutLot.DECLARE]: 'Déclaré',
  [StatutLot.VALIDE]: 'Validé',
  [StatutLot.EN_TRANSIT]: 'En transit',
  [StatutLot.TRANSFORME]: 'Transformé',
  [StatutLot.COMMERCIALISE]: 'Commercialisé',
  [StatutLot.ARCHIVE]: 'Archivé',
  [StatutLot.ANNULE]: 'Annulé',
};

export const STATUT_LOT_ORDRE: StatutLot[] = [
  StatutLot.DECLARE,
  StatutLot.VALIDE,
  StatutLot.EN_TRANSIT,
  StatutLot.TRANSFORME,
  StatutLot.COMMERCIALISE,
];

export enum TypeMouvement {
  COLLECTE = 'COLLECTE',
  RECEPTION_COOPERATIVE = 'RECEPTION_COOPERATIVE',
  TRANSFERT = 'TRANSFERT',
  TRANSFORMATION = 'TRANSFORMATION',
  CONTROLE = 'CONTROLE',
  VENTE = 'VENTE',
  EXPORT = 'EXPORT',
  AUTRE = 'AUTRE',
}

export const TYPE_MOUVEMENT_LABELS: Record<TypeMouvement, string> = {
  [TypeMouvement.COLLECTE]: 'Collecte',
  [TypeMouvement.RECEPTION_COOPERATIVE]: 'Réception coopérative',
  [TypeMouvement.TRANSFERT]: 'Transfert',
  [TypeMouvement.TRANSFORMATION]: 'Transformation',
  [TypeMouvement.CONTROLE]: 'Contrôle',
  [TypeMouvement.VENTE]: 'Vente',
  [TypeMouvement.EXPORT]: 'Export',
  [TypeMouvement.AUTRE]: 'Autre',
};

export interface Mouvement {
  id: string;
  lot: string;
  type_mouvement: TypeMouvement;
  date_mouvement: string;
  lieu_libelle: string | null;
  latitude: number | null;
  longitude: number | null;
  quantite: number | null;
  unite: string | null;
  acteur_utilisateur_id: string | null;
  acteur_producteur_id: string | null;
  acteur_cooperative_id: string | null;
  destinataire_libelle: string | null;
  commentaire: string | null;
  created_at: string;
}

export interface Lot {
  id: string;
  code_lot: string;
  uuid_public: string;
  produit: string;
  produit_nom: string;
  producteur: string;
  producteur_nom: string;
  cooperative: string | null;
  zone_collecte: string | null;
  date_collecte: string;
  quantite: number;
  unite: string;
  qualite_indicateur: string | null;
  prix_indicatif: number | null;
  devise: string;
  latitude: number | null;
  longitude: number | null;
  statut: StatutLot;
  qr_payload: string | null;
  qr_image_path: string | null;
  qr_image_url: string | null;
  declare_par_id: string | null;
  observations: string | null;
  client_uuid: string | null;
  mouvements: Mouvement[];
  created_at: string;
  updated_at: string;
}

export interface LotVerification {
  code_lot: string;
  uuid_public: string;
  produit_nom: string;
  producteur_nom: string;
  province_nom: string;
  date_collecte: string;
  quantite: number;
  unite: string;
  statut: StatutLot;
  qr_payload: string;
  authenticite: string;
  mouvements_count: number;
}

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
  StatutLot.BROUILLON,
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

/** Transitions manuelles acceptées par le serveur (traceability/services.py, TRANSITIONS_MANUELLES_LOT). */
export const TRANSITIONS_MANUELLES_LOT: Record<StatutLot, StatutLot[]> = {
  [StatutLot.BROUILLON]: [StatutLot.DECLARE, StatutLot.ANNULE],
  [StatutLot.DECLARE]: [StatutLot.VALIDE, StatutLot.ANNULE, StatutLot.ARCHIVE],
  [StatutLot.VALIDE]: [StatutLot.EN_TRANSIT, StatutLot.TRANSFORME, StatutLot.COMMERCIALISE, StatutLot.ANNULE, StatutLot.ARCHIVE],
  [StatutLot.EN_TRANSIT]: [StatutLot.TRANSFORME, StatutLot.COMMERCIALISE, StatutLot.ANNULE, StatutLot.ARCHIVE],
  [StatutLot.TRANSFORME]: [StatutLot.EN_TRANSIT, StatutLot.COMMERCIALISE, StatutLot.ANNULE, StatutLot.ARCHIVE],
  [StatutLot.COMMERCIALISE]: [StatutLot.ARCHIVE],
  [StatutLot.ANNULE]: [StatutLot.ARCHIVE],
  [StatutLot.ARCHIVE]: [],
};

/** Statuts pour lesquels un producteur ou une coopérative peut encore modifier ou supprimer le lot. */
export const STATUTS_LOT_MODIFIABLES: StatutLot[] = [StatutLot.BROUILLON, StatutLot.DECLARE];

/** Statuts sur lesquels aucune étape de traçabilité ne peut être ajoutée. */
export const STATUTS_LOT_SANS_MOUVEMENT: StatutLot[] = [StatutLot.BROUILLON, StatutLot.ANNULE, StatutLot.ARCHIVE];

const TOUS_TYPES_MOUVEMENT = Object.values(TypeMouvement);

/** Types d'étape autorisés par profil (traceability/services.py, TYPES_MOUVEMENT_PAR_ROLE). */
export const TYPES_MOUVEMENT_PAR_ROLE: Record<string, TypeMouvement[]> = {
  ADMINISTRATEUR: TOUS_TYPES_MOUVEMENT,
  AGENT_MINISTERE: TOUS_TYPES_MOUVEMENT,
  AGENT_FORESTIER: TOUS_TYPES_MOUVEMENT,
  COOPERATIVE: [
    TypeMouvement.RECEPTION_COOPERATIVE,
    TypeMouvement.TRANSFERT,
    TypeMouvement.TRANSFORMATION,
    TypeMouvement.VENTE,
    TypeMouvement.EXPORT,
    TypeMouvement.AUTRE,
  ],
  PRODUCTEUR: [
    TypeMouvement.TRANSFERT,
    TypeMouvement.TRANSFORMATION,
    TypeMouvement.VENTE,
    TypeMouvement.EXPORT,
    TypeMouvement.AUTRE,
  ],
};

/** Unités de mesure acceptées par la base (type SQL unite_mesure). */
export const UNITE_LOT_OPTIONS = [
  { value: 'KG', label: 'Kilogramme (kg)' },
  { value: 'G', label: 'Gramme (g)' },
  { value: 'LITRE', label: 'Litre (L)' },
  { value: 'ML', label: 'Millilitre (mL)' },
  { value: 'SAC', label: 'Sac' },
  { value: 'UNITE', label: 'Unité' },
  { value: 'BOTTE', label: 'Botte' },
  { value: 'M3', label: 'Mètre cube (m³)' },
  { value: 'METRE', label: 'Mètre (m)' },
];

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
  zone_collecte_nom?: string | null;
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
  photos_urls: string[];
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
  statut_libelle?: string;
  qr_payload: string;
  photos_urls: string[];
  authenticite: string;
  mouvements_count: number;
  mouvements?: { type_libelle: string; date_mouvement: string; lieu_libelle: string | null }[];
}

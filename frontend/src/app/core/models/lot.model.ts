/** Cycle de vie d'un lot : brouillon, puis validé (vérifiable par QR), puis commercialisé. */
export enum StatutLot {
  BROUILLON = 'BROUILLON',
  VALIDE = 'VALIDE',
  COMMERCIALISE = 'COMMERCIALISE',
}

export const STATUT_LOT_LABELS: Record<StatutLot, string> = {
  [StatutLot.BROUILLON]: 'Brouillon',
  [StatutLot.VALIDE]: 'Validé',
  [StatutLot.COMMERCIALISE]: 'Commercialisé',
};

/** Explication courte de chaque statut (aide contextuelle des listes et fiches). */
export const STATUT_LOT_AIDES: Record<StatutLot, string> = {
  [StatutLot.BROUILLON]: 'Déclaré, en attente de validation. Pas encore vérifiable publiquement.',
  [StatutLot.VALIDE]: 'Contrôlé : visible dans l’annuaire et vérifiable par son QR code.',
  [StatutLot.COMMERCIALISE]: 'Vendu : retiré des listes publiques, son QR code reste vérifiable.',
};

export const STATUT_LOT_ORDRE: StatutLot[] = [StatutLot.BROUILLON, StatutLot.VALIDE, StatutLot.COMMERCIALISE];

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
  [TypeMouvement.RECEPTION_COOPERATIVE]: 'Réception par la coopérative',
  [TypeMouvement.TRANSFERT]: 'Transport',
  [TypeMouvement.TRANSFORMATION]: 'Transformation',
  [TypeMouvement.CONTROLE]: 'Contrôle',
  [TypeMouvement.VENTE]: 'Vente',
  [TypeMouvement.EXPORT]: 'Exportation',
  [TypeMouvement.AUTRE]: 'Autre étape',
};

/** Étapes qui commercialisent un lot validé (refusées tant que le lot est en brouillon). */
export const TYPES_MOUVEMENT_COMMERCIALISATION: TypeMouvement[] = [TypeMouvement.VENTE, TypeMouvement.EXPORT];

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
  statut_libelle?: string;
  province_nom?: string | null;
  qr_payload: string | null;
  qr_image_path: string | null;
  qr_image_url: string | null;
  photos_urls: string[];
  declare_par_id: string | null;
  valide_at?: string | null;
  observations: string | null;
  client_uuid: string | null;
  mouvements: Mouvement[];
  /** Présents sur une fiche (pas dans les listes). */
  droits?: DroitsLot | null;
  validation?: ValidationLot | null;
  frise?: EvenementFrise[] | null;
  created_at: string;
  updated_at: string;
}

/** Actions permises à l'utilisateur courant, calculées par le serveur. */
export interface DroitsLot {
  peut_valider: boolean;
  /** AGENT : autorité habilitée ; AUTO : titulaire disposant d'une certification active. */
  mode_validation: 'AGENT' | 'AUTO' | null;
  /** Explication affichée au titulaire qui ne peut pas valider lui-même. */
  motif_validation: string | null;
  peut_commercialiser: boolean;
  peut_modifier: boolean;
  peut_supprimer: boolean;
  peut_ajouter_etape: boolean;
}

export interface ValidationLot {
  date: string | null;
  mode: 'AGENT' | 'AUTO' | null;
  role?: string | null;
  /** Ex. « Validé par un agent du ministère », « Auto-validé (producteur certifié) ». */
  libelle: string;
}

export type TypeEvenementFrise = 'COLLECTE' | 'DECLARATION' | 'MOUVEMENT' | 'VALIDATION' | 'COMMERCIALISATION';

/** Événement de la frise chronologique d'un lot (fiche interne ou page publique). */
export interface EvenementFrise {
  type: TypeEvenementFrise;
  /** Type d'étape pour un MOUVEMENT. */
  code?: TypeMouvement;
  libelle: string;
  date: string;
  /** Vrai si seule la date (sans heure) est connue. */
  date_seule: boolean;
  lieu: string | null;
  quantite: number | string | null;
  unite: string | null;
  /** Rôle générique (Producteur, Coopérative, Agent forestier...), jamais une identité. */
  acteur: string | null;
  latitude?: number | string | null;
  longitude?: number | string | null;
  /** Fiche interne uniquement. */
  destinataire?: string | null;
  commentaire?: string | null;
}

export interface CertificationPublique {
  libelle: string;
  organisme: string | null;
  numero_certificat: string | null;
  date_obtention: string | null;
  date_expiration: string | null;
  portee: 'LOT' | 'PRODUCTEUR';
}

/** Fiche publique complète d'un lot : vérification QR (/verifier) et page lot de l'annuaire. */
export interface LotPublicComplet {
  id: string;
  code_lot: string;
  uuid_public: string | null;
  produit_nom: string;
  produit: { nom: string; nom_scientifique: string | null; categorie: string | null };
  quantite: number | string;
  unite: string;
  qualite_indicateur: string | null;
  prix_indicatif: number | string | null;
  devise: string;
  date_collecte: string;
  lieu: { zone: string | null; province: string | null; latitude: number | string | null; longitude: number | string | null };
  latitude: number | string | null;
  longitude: number | string | null;
  province_nom: string | null;
  producteur_nom: string;
  producteur: {
    /** Renseigné seulement si la fiche du producteur est publique. */
    id: string | null;
    nom: string;
    prenoms: string;
    type_acteur: string;
    type_acteur_libelle: string;
    communaute: string | null;
    province_nom: string | null;
    cooperative_nom: string | null;
    photo_url: string | null;
    fiche_publique: boolean;
  };
  certifications: CertificationPublique[];
  statut: StatutLot;
  statut_libelle: string;
  validation: { date: string | null; mode: 'AGENT' | 'AUTO' | null; libelle: string } | null;
  commercialisation: { date: string } | null;
  photos_urls: string[];
  qr_payload: string | null;
  authenticite: 'VERIFIE';
  frise: EvenementFrise[];
  mouvements_count: number;
}

/** Réponse 404 explicite de la vérification publique ou de la page lot. */
export interface LotPublicIndisponible {
  detail: string;
  code?: 'LOT_INTROUVABLE' | 'LOT_NON_VALIDE' | 'LOT_COMMERCIALISE';
  code_lot?: string;
  uuid_public?: string | null;
}

export enum RoleUtilisateur {
  ADMINISTRATEUR = 'ADMINISTRATEUR',
  AGENT_MINISTERE = 'AGENT_MINISTERE',
  AGENT_FORESTIER = 'AGENT_FORESTIER',
  PRODUCTEUR = 'PRODUCTEUR',
  COOPERATIVE = 'COOPERATIVE',
  ACHETEUR = 'ACHETEUR',
}

export enum StatutCompte {
  ACTIF = 'ACTIF',
  INACTIF = 'INACTIF',
  SUSPENDU = 'SUSPENDU',
  EN_ATTENTE = 'EN_ATTENTE',
}

export interface Utilisateur {
  id: string;
  email: string;
  telephone: string | null;
  role: RoleUtilisateur;
  statut: StatutCompte;
  nom: string;
  prenoms: string;
  photo_url?: string | null;
  doit_changer_mdp: boolean;
  preferences_notif: string;
  derniere_connexion: string | null;
  created_at: string;
  updated_at?: string;
}

export const ROLE_LABELS: Record<RoleUtilisateur, string> = {
  [RoleUtilisateur.ADMINISTRATEUR]: 'Administrateur système',
  [RoleUtilisateur.AGENT_MINISTERE]: 'Agent du Ministère',
  [RoleUtilisateur.AGENT_FORESTIER]: 'Agent forestier',
  [RoleUtilisateur.PRODUCTEUR]: 'Producteur / Collecteur',
  [RoleUtilisateur.COOPERATIVE]: 'Coopérative',
  [RoleUtilisateur.ACHETEUR]: 'Acheteur',
};

export const ROLE_SHORT_LABELS: Record<RoleUtilisateur, string> = {
  [RoleUtilisateur.ADMINISTRATEUR]: 'Administrateur',
  [RoleUtilisateur.AGENT_MINISTERE]: 'Ministère',
  [RoleUtilisateur.AGENT_FORESTIER]: 'Agent forestier',
  [RoleUtilisateur.PRODUCTEUR]: 'Producteur',
  [RoleUtilisateur.COOPERATIVE]: 'Coopérative',
  [RoleUtilisateur.ACHETEUR]: 'Acheteur',
};

export const STATUT_COMPTE_LABELS: Record<StatutCompte, string> = {
  [StatutCompte.ACTIF]: 'Actif',
  [StatutCompte.INACTIF]: 'Inactif',
  [StatutCompte.SUSPENDU]: 'Suspendu',
  [StatutCompte.EN_ATTENTE]: 'En attente de validation',
};

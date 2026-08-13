import { IconName } from '../../design-system/icon/icon.component';
import { RoleUtilisateur } from '../models/user.model';

export interface NavItem {
  label: string;
  route: string;
  icon: IconName;
  roles?: RoleUtilisateur[];
  exact?: boolean;
}

export interface NavSection {
  title: string;
  items: NavItem[];
}

const R = RoleUtilisateur;

export const NAV_SECTIONS: NavSection[] = [
  {
    title: 'Vue d’ensemble',
    items: [{ label: 'Tableau de bord', route: '/app/tableau-de-bord', icon: 'home', exact: true }],
  },
  {
    title: 'Traçabilité',
    items: [
      {
        label: 'Producteurs & collecteurs',
        route: '/app/producteurs',
        icon: 'users',
        roles: [R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.COOPERATIVE],
      },
      {
        label: 'Lots de produits',
        route: '/app/lots',
        icon: 'package',
        roles: [
          R.ADMINISTRATEUR,
          R.AGENT_MINISTERE,
          R.AGENT_FORESTIER,
          R.PRODUCTEUR,
          R.COOPERATIVE,
          R.ACHETEUR,
        ],
      },
      {
        label: 'Zones de collecte',
        route: '/app/zones-collecte',
        icon: 'map-pin',
        roles: [R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER],
      },
      {
        label: 'Certifications',
        route: '/app/certifications',
        icon: 'shield-check',
      },
    ],
  },
  {
    title: 'Filière & partenaires',
    items: [
      {
        label: 'Coopératives',
        route: '/app/cooperatives',
        icon: 'building',
        roles: [R.ADMINISTRATEUR, R.AGENT_MINISTERE, R.AGENT_FORESTIER, R.COOPERATIVE],
      },
      { label: 'Annuaire', route: '/app/marketplace/annuaire', icon: 'globe' },
      {
        label: 'Offres & demandes',
        route: '/app/marketplace/offres',
        icon: 'shopping-bag',
        roles: [R.PRODUCTEUR, R.COOPERATIVE, R.ACHETEUR, R.ADMINISTRATEUR, R.AGENT_MINISTERE],
      },
    ],
  },
  {
    title: 'Administration',
    items: [
      {
        label: 'Comptes utilisateurs',
        route: '/app/utilisateurs',
        icon: 'lock',
        roles: [R.ADMINISTRATEUR, R.AGENT_MINISTERE],
      },
      {
        label: 'Rapports & exports',
        route: '/app/rapports',
        icon: 'file-text',
        roles: [R.ADMINISTRATEUR, R.AGENT_MINISTERE],
      },
      {
        label: 'Synchronisation terrain',
        route: '/app/synchronisation',
        icon: 'refresh-cw',
        roles: [R.ADMINISTRATEUR, R.AGENT_FORESTIER],
      },
    ],
  },
];

export function navSectionsForRole(role: RoleUtilisateur | undefined): NavSection[] {
  if (!role) return [];
  return NAV_SECTIONS.map((section) => ({
    ...section,
    items: section.items.filter((item) => !item.roles || item.roles.includes(role)),
  })).filter((section) => section.items.length > 0);
}

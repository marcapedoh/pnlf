import { PnlfNotification } from '../models/notification.model';

/** Route interne vers la fiche liée à une notification, si les métadonnées le permettent. */
export function notificationTargetRoute(n: PnlfNotification): string[] | null {
  const table = n.metadata?.['table_cible'];
  const id = n.metadata?.['enregistrement_id'];
  if (typeof table !== 'string') return null;

  if (table === 'producteurs' && typeof id === 'string') return ['/app/producteurs', id];
  if (table === 'cooperatives' && typeof id === 'string') return ['/app/cooperatives', id];
  if (table === 'cooperatives') return ['/app/cooperatives'];
  if (table === 'offres_demandes' && typeof id === 'string') return ['/app/marketplace/offres', id];
  if (table === 'lots' && typeof id === 'string') return ['/app/lots', id];
  if (table === 'zones_collecte' && typeof id === 'string') return ['/app/zones-collecte', id];
  if (table === 'utilisateurs' && typeof id === 'string') return ['/app/utilisateurs', id];
  if (table === 'conversations' && typeof id === 'string') return ['/app/messagerie'];
  return null;
}

export function notificationTargetLabel(n: PnlfNotification): string {
  const table = n.metadata?.['table_cible'];
  switch (table) {
    case 'producteurs':
      return 'Voir la fiche producteur';
    case 'cooperatives':
      return 'Voir la fiche coopérative';
    case 'offres_demandes':
      return "Voir l'annonce";
    case 'lots':
      return 'Voir le lot';
    case 'zones_collecte':
      return 'Voir la zone de collecte';
    case 'utilisateurs':
      return "Voir le compte utilisateur";
    case 'conversations':
      return 'Ouvrir la discussion';
    default:
      return 'Ouvrir la fiche liée';
  }
}

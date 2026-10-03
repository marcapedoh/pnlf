import { BadgeTone } from '../../design-system/badge/status-badge.component';
import { StatutCertification } from '../models/certification.model';
import { StatutLot } from '../models/lot.model';
import { StatutCooperative, StatutProducteur } from '../models/producteur.model';

export function lotStatusTone(statut: StatutLot): BadgeTone {
  switch (statut) {
    case StatutLot.VALIDE:
      return 'success';
    case StatutLot.COMMERCIALISE:
      return 'gold';
    case StatutLot.BROUILLON:
      return 'warning';
    default:
      return 'neutral';
  }
}

export function producteurStatusTone(statut: StatutProducteur): BadgeTone {
  switch (statut) {
    case StatutProducteur.ACTIF:
      return 'success';
    case StatutProducteur.EN_VALIDATION:
      return 'warning';
    case StatutProducteur.REJETE:
      return 'danger';
    default:
      return 'neutral';
  }
}

export function cooperativeStatusTone(statut: StatutCooperative): BadgeTone {
  switch (statut) {
    case StatutCooperative.ACTIF:
      return 'success';
    case StatutCooperative.EN_VALIDATION:
      return 'warning';
    case StatutCooperative.REJETE:
      return 'danger';
    default:
      return 'neutral';
  }
}

export function certificationStatusTone(statut: StatutCertification): BadgeTone {
  switch (statut) {
    case StatutCertification.OBTENUE:
      return 'success';
    case StatutCertification.EN_COURS:
    case StatutCertification.DEMANDEE:
      return 'info';
    case StatutCertification.EXPIREE:
      return 'warning';
    case StatutCertification.REFUSEE:
    case StatutCertification.REVOQUEE:
      return 'danger';
    default:
      return 'neutral';
  }
}

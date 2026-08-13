import { BadgeTone } from '../../design-system/badge/status-badge.component';
import { StatutCertification } from '../models/certification.model';
import { StatutLot } from '../models/lot.model';
import { StatutProducteur } from '../models/producteur.model';

export function lotStatusTone(statut: StatutLot): BadgeTone {
  switch (statut) {
    case StatutLot.VALIDE:
    case StatutLot.COMMERCIALISE:
      return 'success';
    case StatutLot.DECLARE:
    case StatutLot.EN_TRANSIT:
      return 'info';
    case StatutLot.TRANSFORME:
      return 'gold';
    case StatutLot.ANNULE:
      return 'danger';
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

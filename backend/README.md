# Backend PFNL

## Prérequis
1. Base PostgreSQL `pnlf` + scripts `database/01` à `04`
2. **Migration cadrage** (pgAdmin, compte **postgres**) :
   `database/05_evolutions_cadrage_superuser.sql`
   → ajoute `type_acteur`, vues dashboard, index
3. `database/02_grants_app.sql` + `03_harden_grants.sql`
4. `backend/.env` renseigné

## Installation
```bash
pip install -r backend/requirements.txt
python backend/scripts/apply_migration_05.py   # tente en pnlf_app (sinon voir étape 2)
```

## Démarrage
```bash
cd backend
..\.venv\Scripts\python.exe manage.py runserver
```

## Tests
```bash
python backend/scripts/test_rbac_matrix.py      # 74 cas RBAC
python backend/scripts/test_cadrage_modules.py  # modules 6.1–6.9
```

## API — Auth & comptes (6.1)
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/login/` | JWT |
| POST | `/api/auth/refresh/` | Refresh token |
| GET | `/api/accounts/me/` | Profil courant |
| GET/POST/PATCH/DELETE | `/api/accounts/utilisateurs/` | CRUD admin |
| POST | `/api/accounts/change-password/` | Changement MDP |
| POST | `/api/accounts/password-reset/` | Demande reset |
| POST | `/api/accounts/password-reset/confirm/` | Confirmer reset |

## API — Référentiel & géo (6.3, 6.5)
| GET | `/api/provinces/`, `/api/departements/`, `/api/villages/` |
| GET/POST | `/api/produits/`, `/api/categories-produits/` |
| GET/POST | `/api/zones-collecte/` |

## API — Producteurs & coopératives (6.2)
| GET/POST/PATCH | `/api/producteurs/` |
| POST | `/api/producteurs/{id}/valider/` | Agent / admin |
| POST | `/api/producteurs/{id}/rejeter/` | Agent / admin |
| GET/POST | `/api/cooperatives/` |
| GET/POST | `/api/cooperatives/{id}/membres/` |

Champ **`type_acteur`** : `PRODUCTEUR` | `COLLECTEUR` (même rôle RBAC).

## API — Traçabilité (6.4)
| GET/POST | `/api/lots/`, `/api/mouvements/` |
| GET | `/api/lots/{id}/tracabilite/` |
| GET | `/api/lots/{id}/qr/` | Image PNG QR |
| POST | `/api/lots/{id}/changer-statut/` | Workflow lot |
| GET | `/api/verify/{uuid_public}/` | **Public** — vérification QR |

Workflow mouvements → statut lot : COLLECTE→DECLARE, RECEPTION/CONTROLE→VALIDE, TRANSFERT→EN_TRANSIT, etc.

## API — Certifications
| GET | `/api/types-certification/` |
| GET/POST/PATCH | `/api/certifications/` |

## API — Dashboard & exports (6.6, 6.7)
| GET | `/api/dashboard/stats/` | Admin / agents |
| GET | `/api/exports/lots/?export_format=csv\|xlsx\|pdf` |

## API — Notifications, marketplace, messagerie (6.8, 6.9)
| GET/PATCH | `/api/notifications/` |
| GET/POST | `/api/offres-demandes/` |
| GET/POST | `/api/conversations/`, `.../messages/` |
| GET | `/api/annuaire/` | Recherche producteurs/coop |

## API — Sync offline (PWA)
| POST | `/api/sync/push/` |
| GET | `/api/sync/pull/` |
| GET/POST | `/api/appareils-sync/` |
| GET | `/api/sync-conflicts/` |

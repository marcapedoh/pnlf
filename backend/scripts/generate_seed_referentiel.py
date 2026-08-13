"""Génère database/04_seed_referentiel_gabon.sql à partir des données OCHA + chefs-lieux."""
import json
from pathlib import Path

src = Path(
    r'C:\Users\DELL\.cursor\projects\c-Users-DELL-Desktop-Projet-PNLF'
    r'\agent-tools\a87265dd-6578-45af-898a-38aca0de3c3d.txt'
)
data = json.loads(src.read_text(encoding='utf-8'))

PROV_MAP = {
    'Estuaire': 'EST',
    'Haut-Ogooue': 'HAO',
    'Moyen-Ogooue': 'MOY',
    'Ngounie': 'NGO',
    'Nyanga': 'NYA',
    'Ogooue-Ivindo': 'OGO',
    'Ogooue-Lolo': 'OLR',
    'Ogooue-Maritime': 'OMR',
    'Woleu-Ntem': 'WOL',
}

# id OCHA -> (nom officiel, chef-lieu, lat, lon)
DEPT_META = {
    'GAB001001': ('Komo', 'Kango', 0.1667, 10.1167),
    'GAB001002': ('Komo-Mondah', 'Ntoum', 0.3833, 9.7667),
    'GAB001003': ('Noya', 'Cocobeach', 1.0000, 9.5833),
    'GAB001004': ('Libreville', 'Libreville', 0.3901, 9.4544),
    'GAB002001': ('Djoué', 'Onga', -0.8500, 14.1500),
    'GAB002002': ('Djouori-Agnili', 'Bongoville', -1.6500, 13.8667),
    'GAB002003': ('Lébombi-Léyou', 'Moanda', -1.5667, 13.2000),
    'GAB002004': ('Lékabi-Léwolo', 'Ngouoni', -1.3500, 13.7500),
    'GAB002005': ('Lékoko', 'Bakoumba', -1.8000, 13.0167),
    'GAB002006': ('Lékoni-Lékori', 'Akiéni', -1.1833, 13.9167),
    'GAB002007': ('Ogooué-Létili', 'Boumango', -2.1500, 13.6500),
    'GAB002008': ('Mpassa', 'Franceville', -1.6333, 13.5833),
    'GAB002009': ('Plateaux', 'Lékoni', -1.5833, 14.2667),
    'GAB002010': ('Sébé-Brikolo', 'Okondja', -0.6833, 13.7833),
    'GAB002011': ('Bayi-Brikolo', 'Aboumi', -0.5167, 14.0833),
    'GAB003001': ('Abanga-Bigné', 'Ndjolé', -0.1833, 10.7667),
    'GAB003002': ('Ogooué et des Lacs', 'Lambaréné', -0.7000, 10.2167),
    'GAB004001': ('Boumi-Louetsi', 'Mbigou', -1.9000, 11.9000),
    'GAB004002': ('Dola', 'Ndendé', -2.3000, 11.3833),
    'GAB004003': ('Douya-Onoye', 'Mouila', -1.8667, 11.0556),
    'GAB004004': ('Louetsi-Bibaka', 'Malinga', -2.2000, 12.2500),
    'GAB004005': ('Louetsi-Wano', 'Lébamba', -2.2000, 11.5000),
    'GAB004006': ('Ndolou', 'Mandji', -1.5833, 10.4000),
    'GAB004007': ('Ogoulou', 'Mimongo', -1.6167, 11.6000),
    'GAB004008': ('Tsamba-Magotsi', 'Fougamou', -1.2167, 10.6000),
    'GAB004009': ('Mougalaba', 'Guietsou', -2.0500, 10.8000),
    'GAB005001': ('Basse-Banio', 'Mayumba', -3.4167, 10.6500),
    'GAB005002': ('Douigny', 'Moabi', -2.4333, 10.9833),
    'GAB005003': ('Doutsila', 'Mabanda', -2.7500, 11.4000),
    'GAB005004': ('Haute-Banio', 'Ndindi', -3.7000, 11.0000),
    'GAB005005': ('Mougoutsi', 'Tchibanga', -2.8500, 11.0167),
    'GAB005006': ('Mongo', 'Moulengui-Binza', -3.2500, 11.5833),
    'GAB006001': ('Ivindo', 'Makokou', 0.5667, 12.8500),
    'GAB006002': ('Lopé', 'Booué', -0.1000, 11.9333),
    'GAB006003': ('Mvoung', 'Ovan', 0.3500, 12.1667),
    'GAB006004': ('Zadié', 'Mékambo', 1.0167, 13.9333),
    'GAB007001': ('Lolo-Bouenguidi', 'Koulamoutou', -1.1333, 12.4667),
    'GAB007002': ('Lombo-Bouenguidi', 'Pana', -1.4500, 12.6167),
    'GAB007003': ('Mulundu', 'Lastoursville', -0.8167, 12.7167),
    'GAB007004': ('Offoué-Onoye', 'Iboundji', -1.1000, 11.9167),
    'GAB008001': ('Bendjé', 'Port-Gentil', -0.7167, 8.7833),
    'GAB008002': ('Etimboué', 'Omboué', -1.5667, 9.2667),
    'GAB008003': ('Ndougou', 'Gamba', -2.6500, 10.0000),
    'GAB009001': ('Haut-Komo', 'Médouneu', 0.9500, 10.7833),
    'GAB009002': ('Haut-Ntem', 'Minvoul', 2.1500, 12.1333),
    'GAB009003': ('Ntem', 'Bitam', 2.0833, 11.5000),
    'GAB009004': ('Okano', 'Mitzic', 0.7833, 11.5500),
    'GAB009005': ('Woleu', 'Oyem', 1.6000, 11.5833),
}


def esc(s: str) -> str:
    return s.replace("'", "''")


assert len(DEPT_META) == 48
assert set(DEPT_META) == {d['id'] for d in data['data']['department']}

lines: list[str] = []
lines += [
    '-- =============================================================================',
    '-- PNLF — Seed référentiel Gabon (idempotent)',
    '-- Sources:',
    '--   - Découpage admin: OCHA COD-AB (HDX) via openadmindata.org (48 départements)',
    '--   - Chefs-lieux: Statoids / geo-ref / nomenclatures administratives gabonaises',
    '--   - PFNL: Stratégie nationale PFNL Gabon (2012), COMIFAC, FAO',
    '-- Prérequis: database/01_schema_pnlf.sql (provinces + catégories déjà créées)',
    '-- =============================================================================',
    '',
    'BEGIN;',
    'SET search_path TO pnlf, public;',
    '',
    '-- -----------------------------------------------------------------------------',
    '-- 1. Départements (48)',
    '-- -----------------------------------------------------------------------------',
]

for d in sorted(data['data']['department'], key=lambda x: x['id']):
    pid = d['id']
    pcode = PROV_MAP[d['parent_name_en']]
    nom, _chef, _lat, _lon = DEPT_META[pid]
    lines.append(
        "INSERT INTO departements (province_id, code, nom) "
        f"SELECT p.id, '{pid}', '{esc(nom)}' FROM provinces p WHERE p.code = '{pcode}' "
        'ON CONFLICT (code) DO UPDATE SET nom = EXCLUDED.nom, updated_at = CURRENT_TIMESTAMP;'
    )

lines += [
    '',
    '-- -----------------------------------------------------------------------------',
    '-- 2. Chefs-lieux (1 village / département) + Point PostGIS',
    '-- -----------------------------------------------------------------------------',
]
for pid, (nom, chef, lat, lon) in sorted(DEPT_META.items()):
    lines.append(
        'INSERT INTO villages (departement_id, nom, latitude, longitude, geom) '
        f"SELECT d.id, '{esc(chef)}', {lat}, {lon}, "
        f'ST_SetSRID(ST_MakePoint({lon}, {lat}), 4326) '
        f"FROM departements d WHERE d.code = '{pid}' "
        'ON CONFLICT ON CONSTRAINT uq_villages_nom_dept DO UPDATE SET '
        'latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, '
        'geom = EXCLUDED.geom, updated_at = CURRENT_TIMESTAMP;'
    )

lines += [
    '',
    '-- -----------------------------------------------------------------------------',
    '-- 3. Zones de collecte / parcs nationaux (référence terrain)',
    '-- -----------------------------------------------------------------------------',
]

zones = [
    ('ZC-LOPE', 'Parc national de la Lopé', 'OGO', -0.2000, 11.6000),
    ('ZC-IVINDO', "Parc national d'Ivindo", 'OGO', 0.5000, 12.8000),
    ('ZC-MOUKALABA', 'Parc national de Moukalaba-Doudou', 'NYA', -2.5000, 10.5000),
    ('ZC-WAKA', 'Parc national de Waka', 'NGO', -1.1000, 11.1000),
    ('ZC-CRISTAL', 'Parc national des Monts de Cristal', 'EST', 0.6000, 10.4000),
    ('ZC-BATEKE', 'Parc national des Plateaux Batéké', 'HAO', -2.1000, 14.0000),
    ('ZC-MWAGNE', 'Parc national de Mwagne', 'OGO', 0.8000, 13.5000),
    ('ZC-MAYUMBA', 'Parc national de Mayumba', 'NYA', -3.4000, 10.7000),
    ('ZC-AKANDA', "Parc national d'Akanda", 'EST', 0.6000, 9.4000),
    ('ZC-PONGARA', 'Parc national de Pongara', 'EST', 0.1000, 9.4000),
]
for code, lib, pcode, lat, lon in zones:
    lines.append(
        'INSERT INTO zones_collecte (code, libelle, province_id, description, latitude, longitude, geom) '
        f"SELECT '{code}', '{esc(lib)}', p.id, 'Zone forestière de référence PNLF', {lat}, {lon}, "
        f'ST_SetSRID(ST_MakePoint({lon}, {lat}), 4326) '
        f"FROM provinces p WHERE p.code = '{pcode}' "
        'ON CONFLICT (code) DO UPDATE SET libelle = EXCLUDED.libelle, '
        'latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, '
        'geom = EXCLUDED.geom, updated_at = CURRENT_TIMESTAMP;'
    )

lines += [
    '',
    '-- -----------------------------------------------------------------------------',
    '-- 4. Produits PFNL gabonais (référentiel initial extensible)',
    '-- -----------------------------------------------------------------------------',
]

produits = [
    ('PFNL-MIEL-SAUV', 'Miel sauvage / miel de forêt', 'Apis mellifera adansonii', 'MIEL', 'KG',
     'Miel issu de la forêt équatoriale gabonaise'),
    ('PFNL-CIRE', "Cire d'abeille", None, 'MIEL', 'KG', 'Sous-produit apicole'),
    ('PFNL-PROPOLIS', 'Propolis', None, 'MIEL', 'KG', 'Résine apicole'),
    ('PFNL-MOABI-NOIX', 'Noix / amandes de moabi', 'Baillonella toxisperma', 'NOIX', 'KG',
     'Amandes pour huile comestible — espèce emblématique du Gabon'),
    ('PFNL-MOABI-HUILE', 'Huile de moabi', 'Baillonella toxisperma', 'NOIX', 'LITRE',
     'Huile extraite des amandes de moabi'),
    ('PFNL-COULA', "Noisettes d'Afrique (owala)", 'Coula edulis', 'NOIX', 'KG',
     'Noisettes forestières'),
    ('PFNL-KOLA', 'Noix de kola', 'Cola nitida / Cola acuminata', 'NOIX', 'KG',
     'Stimulant traditionnel'),
    ('PFNL-ODIKA', 'Odika / mangue sauvage', 'Irvingia gabonensis', 'FRUITS', 'KG',
     'Fruits et amandes (andok)'),
    ('PFNL-SAFOU', 'Safou', 'Dacryodes edulis', 'FRUITS', 'KG',
     'Fruit oléagineux très consommé'),
    ('PFNL-ATANGA', 'Atanga', 'Pachylobus edulis', 'FRUITS', 'KG',
     'Fruit forestier / agroforestier'),
    ('PFNL-NKUMU', 'Nkumu (feuilles)', 'Gnetum africanum', 'PLANTES', 'KG',
     'Légume-feuille forestier'),
    ('PFNL-IBOGA', 'Iboga (racine / écorce)', 'Tabernanthe iboga', 'PLANTES', 'KG',
     'Plante médicinale réglementée — usage contrôlé'),
    ('PFNL-GARCIA-KOLA', 'Bois amer (Garcinia)', 'Garcinia kola', 'PLANTES', 'KG',
     'Graines / écorces médicinales'),
    ('PFNL-POIVRE-G', 'Poivre de Guinée', 'Piper guineense', 'PLANTES', 'KG',
     'Épice forestière'),
    ('PFNL-AFRAMOMUM', 'Maniguette / Aframomum', 'Aframomum spp.', 'PLANTES', 'KG',
     'Fruits aromatiques'),
    ('PFNL-MARANTACEES', "Feuilles d'emballage (Marantacées)",
     'Megaphrynium / Marantochloa spp.', 'PLANTES', 'BOTTE',
     'Feuilles pour emballage alimentaire'),
    ('PFNL-ECORCE-MED', 'Écorces médicinales diverses', None, 'ECORCES', 'KG',
     'Écorces à usage pharmacopée traditionnelle'),
    ('PFNL-ALSTONIA', "Écorce d'Alstonia", 'Alstonia boonei', 'ECORCES', 'KG',
     'Usage médicinal'),
    ('PFNL-ROTIN', 'Rotin', 'Laccosperma / Eremospatha spp.', 'ROTIN', 'METRE',
     'Lianes pour artisanat et construction'),
    ('PFNL-BAMBOU', 'Bambou', 'Bambusa / Oxytenanthera spp.', 'ROTIN', 'METRE',
     'Tiges pour construction et artisanat'),
    ('PFNL-RAPHIA', 'Raphia', 'Raphia spp.', 'ROTIN', 'KG',
     'Fibres, feuilles, vin de palme'),
    ('PFNL-CHAMP', 'Champignons comestibles forestiers', None, 'CHAMP', 'KG',
     'Champignons saisonniers de sous-bois'),
    ('PFNL-CHENILLES', 'Chenilles comestibles', None, 'FAUNE', 'KG',
     'Protéines forestières — conformité réglementaire requise'),
    ('PFNL-ESCARGOTS', 'Escargots de forêt', 'Archachatina spp.', 'FAUNE', 'KG',
     'Mollusques comestibles'),
]

for code, nom, sci, cat, unite, desc in produits:
    sci_sql = f"'{esc(sci)}'" if sci else 'NULL'
    lines.append(
        'INSERT INTO produits (code, nom, nom_scientifique, categorie_id, description, '
        'unite_defaut, soumis_cites, code_cites, actif) '
        f"SELECT '{code}', '{esc(nom)}', {sci_sql}, c.id, '{esc(desc)}', "
        f"'{unite}'::unite_mesure, FALSE, NULL, TRUE "
        f"FROM categories_produit c WHERE c.code = '{cat}' "
        'ON CONFLICT (code) DO UPDATE SET '
        'nom = EXCLUDED.nom, nom_scientifique = EXCLUDED.nom_scientifique, '
        'description = EXCLUDED.description, unite_defaut = EXCLUDED.unite_defaut, '
        'updated_at = CURRENT_TIMESTAMP;'
    )

# Nettoyage éventuel du produit de test
lines += [
    '',
    "-- Désactiver éventuels produits de test",
    "UPDATE produits SET actif = FALSE, updated_at = CURRENT_TIMESTAMP WHERE code LIKE 'TST-%';",
    '',
    '-- -----------------------------------------------------------------------------',
    '-- 5. Contrôles de cohérence relationnelle',
    '-- -----------------------------------------------------------------------------',
    """
DO $$
DECLARE
  n_prov INT;
  n_dept INT;
  n_vil INT;
  n_prod INT;
  n_zone INT;
  bad INT;
BEGIN
  SELECT COUNT(*) INTO n_prov FROM provinces WHERE actif;
  SELECT COUNT(*) INTO n_dept FROM departements WHERE actif;
  SELECT COUNT(*) INTO n_vil FROM villages WHERE actif;
  SELECT COUNT(*) INTO n_prod FROM produits WHERE actif AND code LIKE 'PFNL-%';
  SELECT COUNT(*) INTO n_zone FROM zones_collecte WHERE actif;

  IF n_prov <> 9 THEN RAISE EXCEPTION 'Attendu 9 provinces, trouvé %', n_prov; END IF;
  IF n_dept < 48 THEN RAISE EXCEPTION 'Attendu >= 48 départements, trouvé %', n_dept; END IF;
  IF n_vil < 48 THEN RAISE EXCEPTION 'Attendu >= 48 chefs-lieux, trouvé %', n_vil; END IF;
  IF n_prod < 20 THEN RAISE EXCEPTION 'Référentiel produits insuffisant: %', n_prod; END IF;
  IF n_zone < 8 THEN RAISE EXCEPTION 'Zones de collecte insuffisantes: %', n_zone; END IF;

  SELECT COUNT(*) INTO bad FROM departements d
    LEFT JOIN provinces p ON p.id = d.province_id WHERE p.id IS NULL;
  IF bad > 0 THEN RAISE EXCEPTION 'Départements orphelins: %', bad; END IF;

  SELECT COUNT(*) INTO bad FROM villages v
    LEFT JOIN departements d ON d.id = v.departement_id WHERE d.id IS NULL;
  IF bad > 0 THEN RAISE EXCEPTION 'Villages orphelins: %', bad; END IF;

  SELECT COUNT(*) INTO bad FROM produits pr
    LEFT JOIN categories_produit c ON c.id = pr.categorie_id WHERE c.id IS NULL;
  IF bad > 0 THEN RAISE EXCEPTION 'Produits sans catégorie: %', bad; END IF;

  SELECT COUNT(*) INTO bad FROM zones_collecte z
    LEFT JOIN provinces p ON p.id = z.province_id WHERE p.id IS NULL;
  IF bad > 0 THEN RAISE EXCEPTION 'Zones orphelines: %', bad; END IF;

  -- Chaque province doit avoir au moins 1 département
  SELECT COUNT(*) INTO bad FROM provinces p
    WHERE p.actif AND NOT EXISTS (
      SELECT 1 FROM departements d WHERE d.province_id = p.id AND d.actif
    );
  IF bad > 0 THEN RAISE EXCEPTION 'Provinces sans département: %', bad; END IF;

  RAISE NOTICE 'Seed OK — provinces=%, departements=%, villages=%, produits_pfnl=%, zones=%',
    n_prov, n_dept, n_vil, n_prod, n_zone;
END $$;
""",
    'COMMIT;',
    '',
]

out = Path(r'c:\Users\DELL\Desktop\Projet PNLF\database\04_seed_referentiel_gabon.sql')
out.write_text('\n'.join(lines), encoding='utf-8')
print(f'Wrote {out} ({len(lines)} lines)')

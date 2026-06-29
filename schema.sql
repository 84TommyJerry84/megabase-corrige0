-- Géographie en 3 niveaux (région > département > commune), reliés par clés étrangères.
-- Les typologies sont reliées à la commune par le code INSEE.
-- Tables conservées d'un run à l'autre : un chargement interrompu peut reprendre.

CREATE TABLE IF NOT EXISTS region (
    code_region TEXT PRIMARY KEY,
    name        TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS departement (
    code_departement TEXT PRIMARY KEY,
    name             TEXT NOT NULL,
    code_region      TEXT REFERENCES region (code_region)
);

CREATE TABLE IF NOT EXISTS commune (
    insee_code       TEXT PRIMARY KEY,
    name             TEXT NOT NULL,
    population       INTEGER,
    code_departement TEXT REFERENCES departement (code_departement)
);

CREATE TABLE IF NOT EXISTS lycee (
    uai          TEXT PRIMARY KEY,
    name         TEXT,
    status       TEXT,
    nature       TEXT,
    address      TEXT,
    postal_code  TEXT,
    commune_name TEXT,
    phone        TEXT,
    email        TEXT,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    insee_code   TEXT REFERENCES commune (insee_code)
);

CREATE TABLE IF NOT EXISTS college (
    uai          TEXT PRIMARY KEY,
    name         TEXT,
    status       TEXT,
    nature       TEXT,
    address      TEXT,
    postal_code  TEXT,
    commune_name TEXT,
    phone        TEXT,
    email        TEXT,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    insee_code   TEXT REFERENCES commune (insee_code)
);

CREATE TABLE IF NOT EXISTS pharmacie (
    finess       TEXT PRIMARY KEY,
    name         TEXT,
    category     TEXT,
    address      TEXT,
    postal_line  TEXT,
    commune_name TEXT,
    phone        TEXT,
    siret        TEXT,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    insee_code   TEXT REFERENCES commune (insee_code)
);

-- Les gares sont rapatriées en un seul passage global (script gares.py), pas par
-- département : le dataset SNCF n'a NI code commune NI coordonnées, et son code
-- postal ne permet pas de filtrer proprement les départements 01-09. On stocke
-- donc le brut, SANS lien vers commune (pas de clé étrangère insee_code ici).
-- La liaison (géocodage via la BAN) sera une étape séparée, faite plus tard.
CREATE TABLE IF NOT EXISTS gare (
    code_uic       TEXT PRIMARY KEY,
    name           TEXT,
    postal_code    TEXT,
    region_sncf    TEXT,
    travelers_2024 BIGINT,
    travelers_2023 BIGINT
);

-- EHPAD : même base FINESS que les pharmacies, autre catégorie. Mêmes colonnes.
CREATE TABLE IF NOT EXISTS ehpad (
    finess       TEXT PRIMARY KEY,
    name         TEXT,
    category     TEXT,
    address      TEXT,
    postal_line  TEXT,
    commune_name TEXT,
    phone        TEXT,
    siret        TEXT,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    insee_code   TEXT REFERENCES commune (insee_code)
);

-- Bibliothèques (data.culture). On garde aussi quelques mesures (emprunteurs, prêts).
CREATE TABLE IF NOT EXISTS bibliotheque (
    code_bib     TEXT PRIMARY KEY,
    name         TEXT,
    status       TEXT,
    address      TEXT,
    postal_code  TEXT,
    commune_name TEXT,
    phone        TEXT,
    population   INTEGER,
    borrowers    INTEGER,
    loans        INTEGER,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    insee_code   TEXT REFERENCES commune (insee_code)
);

-- Mairies : une par commune, dérivée du référentiel (pas d'API en plus).
CREATE TABLE IF NOT EXISTS mairie (
    insee_code TEXT PRIMARY KEY REFERENCES commune (insee_code),
    name       TEXT
);

-- Entreprises du BTP (recherche-entreprises, voir btp.py). La commune est fournie.
CREATE TABLE IF NOT EXISTS entreprise_btp (
    siret            TEXT PRIMARY KEY,
    name             TEXT,
    commune_name     TEXT,
    tranche_effectif TEXT,
    latitude         DOUBLE PRECISION,
    longitude        DOUBLE PRECISION,
    insee_code       TEXT REFERENCES commune (insee_code)
);

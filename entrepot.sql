-- Le grain de la table de faits=> un ligne repésente le nombre d'etablissements d'un type(pharmacie, collége) dans une commune
-- schema entrepot

CREATE SCHEMA IF NOT EXISTS entrepot;

--création des tables

CREATE TABLE IF NOT EXISTS entrepot.dim_commune (
    insee_code TEXT PRIMARY KEY,
    commune TEXT,
    departement TEXT,
    region TEXT,
    population INTEGER
);

CREATE TABLE IF NOT EXISTS entrepot.dim_type (
    type TEXT PRIMARY KEY,
    libelle TEXT    
);

CREATE TABLE IF NOT EXISTS entrepot.fait_etablissement (
    insee_code TEXT NOT NULL,
    type TEXT NOT NULL ,
    nb INTEGER NOT NULL,

    PRIMARY KEY (insee_code, type),

    CONSTRAINT fk_fait_commune
        FOREIGN KEY (insee_code)
        REFERENCES entrepot.dim_commune(insee_code),

    CONSTRAINT fk_fait_type
        FOREIGN KEY (type)
        REFERENCES entrepot.dim_type(type)
);

-- néttoyer les tables

TRUNCATE TABLE

    entrepot.fait_etablissement,
    entrepot.dim_commune,
    entrepot.dim_type;

-- peupler les tables avec les données

INSERT INTO entrepot.dim_commune(
    insee_code,
    commune,
    departement,
    region,
    population
)
SELECT
    c.insee_code,
    c.name AS nom_commune,
    d.name AS nom_departement,
    r.name AS nom_region,
    c.population
FROM commune AS c
JOIN departement AS d
    ON d.code_departement=c.code_departement
JOIN region AS r
    ON r.code_region=d.code_region;

INSERT INTO entrepot.dim_type(
    type,
    libelle
)
VALUES
    ('lycee','lycée'),
    ('college','collège'),
    ('pharmacie','pharmacie'),
    ('ehpad','EHPAD'),
    ('bibliotheque','Bibliothèque');

INSERT INTO entrepot.fait_etablissement (
    insee_code,
    type,
    nb
)
SELECT 
    insee_code,
    'lycee' AS code_type,
    COUNT(*) AS nombre_etablissements
FROM lycee
WHERE insee_code IS NOT NULL
GROUP BY insee_code

UNION ALL

SELECT 
    insee_code,
    'college' AS code_type,
    COUNT(*) AS nombre_etablissements
FROM college
WHERE insee_code IS NOT NULL
GROUP BY insee_code

UNION ALL

SELECT 
    insee_code,
    'pharmacie' AS code_type,
    COUNT(*) AS nombre_etablissements
FROM pharmacie
WHERE insee_code IS NOT NULL
GROUP BY insee_code

UNION ALL

SELECT 
    insee_code,
    'ehpad' AS code_type,
    COUNT(*) AS nombre_etablissements
FROM ehpad
WHERE insee_code IS NOT NULL
GROUP BY insee_code

UNION ALL

SELECT 
    insee_code,
    'bibliotheque' AS code_type,
    COUNT(*) AS nombre_etablissements
FROM bibliotheque
WHERE insee_code IS NOT NULL
GROUP BY insee_code;

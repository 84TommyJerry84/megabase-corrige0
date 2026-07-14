-- 1. Lire un plan d'exécution

--Expliquez en une phrase pourquoi l'index de la clé primaire sert au premier cas et pas au second:
-- avec une clé primaire l'execution est plus optimisé et rapide la clé primaire agit comme un index par defaut

EXPLAIN ANALYSE
SELECT sum(nb)
FROM entrepot.fait_etablissement
WHERE insee_code = '69123';

EXPLAIN ANALYSE
SELECT sum(nb)
FROM entrepot.fait_etablissement
WHERE type = 'lycee';

--2. Créer un index

CREATE INDEX IF NOT EXISTS indexfe ON entrepot.fait_etablissement (type);

EXPLAIN ANALYSE
SELECT sum(nb)
FROM entrepot.fait_etablissement
WHERE type = 'lycee';

--Répondez en une/deux phrase(s) : 
--pourquoi ne pas indexer toutes les colonnes de toutes les tables ? Tenez compte du fait que l'entrepôt
--parce que l'index accélere la lecture mais ralenti l'écriture, 
--si n index c'est n mise à jour d'index => ralentissement en écriture

--3. Encapsuler dans des fonctions

--fonction 1 top

CREATE OR REPLACE FUNCTION entrepot.top_communes(p_type TEXT, p_n INTEGER)
RETURNS TABLE(
    commune TEXT,
    type TEXT,
    nb INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fe.insee_code,
        fe.type,
        fe.nb 
    FROM entrepot.fait_etablissement AS fe
    WHERE fe.type=p_type
    ORDER BY fe.nb DESC
    LIMIT p_n;
END;
$$;

SELECT * FROM entrepot.top_communes('lycee',5);


DROP FUNCTION IF EXISTS entrepot.habitants_par(TEXT);
--fonction 2

CREATE OR REPLACE FUNCTION entrepot.habitants_par(p_type TEXT)
RETURNS TABLE(
    departement TEXT,
    population NUMERIC,
    nb_etablissement NUMERIC,
    ratio NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dc.departement,
        SUM(dc.population::NUMERIC) AS population,
        COALESCE(SUM(fe.nb::NUMERIC),0) AS nb_lycees,
        ROUND(
            SUM(dc.population::NUMERIC) / NULLIF(SUM(fe.nb::NUMERIC), 0),
            2
        ) AS ratio
    FROM entrepot.dim_commune AS dc
    LEFT JOIN entrepot.fait_etablissement AS fe 
        ON dc.insee_code = fe.insee_code
        AND fe.type = p_type
    GROUP BY dc.departement
    ORDER BY ratio DESC;
END;
$$;

SELECT * FROM entrepot.habitants_par('lycee');

-- 4. Deux triggers
-- 1. Protection
CREATE OR REPLACE FUNCTION entrepot.alerte()
RETURNS trigger AS $alerte$
BEGIN
    
    RAISE EXCEPTION 
        'Attention : Un salopard essaye de supprimer la commune %',
        OLD.commune;

    RETURN OLD;
END;
$alerte$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trigger_supp
ON entrepot.dim_commune;

CREATE TRIGGER trigger_supp
BEFORE DELETE ON entrepot.dim_commune
FOR EACH ROW
EXECUTE FUNCTION entrepot.alerte();

--test du trigger

-- BEGIN;

-- DELETE FROM entrepot.dim_commune
-- WHERE commune = 'Lyon';

-- ROLLBACK;

-- 2. Maintenance au fil de l'eau.

CREATE OR REPLACE FUNCTION entrepot.inkrement_phar()
RETURNS trigger AS $inkrement_phar$
BEGIN
    INSERT INTO entrepot.fait_etablissement (
        insee_code,
        type,
        nb
    )
    VALUES (
        NEW.insee_code,
        'pharmacie',
        1
    )
    ON CONFLICT (insee_code, type)
    DO UPDATE
    SET nb = entrepot.fait_etablissement.nb + 1;

    RETURN NEW;
END;
$inkrement_phar$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigg_inkrement_phar 
ON pharmacie;

CREATE TRIGGER trigg_inkrement_phar 
AFTER INSERT ON pharmacie
    FOR EACH ROW
        EXECUTE FUNCTION entrepot.inkrement_phar();

--test trigger
-- BEGIN;

-- SELECT *
-- FROM entrepot.fait_etablissement
-- WHERE type = 'pharmacie'
-- ORDER BY insee_code;

-- INSERT INTO pharmacie (
--     finess,
--     name,
--     category,
--     insee_code
-- )
-- SELECT
--     'TEST-PHARMA-001',
--     'Pharmacie de test',
--     'Pharmacie d''Officine',
--     insee_code
-- FROM entrepot.dim_commune
-- LIMIT 1;

-- SELECT *
-- FROM pharmacie
-- WHERE finess = 'TEST-PHARMA-001';

-- SELECT fe.*
-- FROM entrepot.fait_etablissement AS fe
-- JOIN pharmacie AS p
--     ON p.insee_code = fe.insee_code
-- WHERE p.finess = 'TEST-PHARMA-001'
--   AND fe.type = 'pharmacie';

-- ROLLBACK;

-- Quand la maintenance par trigger se justifie-t-elle,
-- et quand la reconstruction suffit-elle ? Raisonnez 
-- sur le rythme d'arrivée des données : flux continu 
-- ou campagnes de chargement.

-- Réponse :
-- pour un flux continu le trigger est plus adapté, des insertions unitaires par des humains type (ERP).
-- la reconstruction est plus adapté pour un chargement de masse.

-- Combien faudrait-il de triggers pour maintenir l'entrepôt complet ? Comptez : une typologie
-- par table de collecte, trois opérations à couvrir (INSERT, UPDATE, DELETE).
-- C'est ce nombre qui explique pourquoi la reconstruction reste la méthode de référence ici.

-- Réponse :
-- un trigger par type d'action pour chaque table qui alimente la table de fait (3*5=15)
-- (plus les tables d'audits ou de logs (si celle-ci existent))
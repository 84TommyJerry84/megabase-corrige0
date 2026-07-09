-- 1. État des lieux (volumétrie)

--1.1 le nombre de lignes de chaque table (count(*)) 
SELECT 
  (
    SELECT 
      COUNT(*) 
    FROM 
      commune
  ) AS communes, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      mairie
  ) AS mairies, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      lycee
  ) AS lycees, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      college
  ) AS colleges, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      pharmacie
  ) AS pharmacies, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      ehpad
  ) AS ehpads, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      bibliotheque
  ) AS bibliotheques, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      gare
  ) AS gares, 
  (
    SELECT 
      COUNT(*) 
    FROM 
      entreprise_btp
  ) AS entreprises_btp;

  
--1.2 lle nombre de communes par région et par département (jointures commune -> departement -> region, GROUP BY) ;
SELECT
    r.name AS region,
    d.name AS departement,
    COUNT(c.insee_code) AS nb_communes
FROM commune AS c
JOIN departement AS d
    ON c.code_departement = d.code_departement
JOIN region AS r
    ON d.code_region = r.code_region
GROUP BY
    r.name,
    d.name
ORDER BY
    r.name,
    nb_communes DESC;


--correction de 1.3 le nombre d'établissements d'un type (pharmacies, lycées...) par département.
SELECT d.name AS departement,
       coalesce(ly.n, 0) AS lycees,
       coalesce(co.n, 0) AS colleges,
       coalesce(ph.n, 0) AS pharmacies,
       coalesce(eh.n, 0) AS ehpad,
       coalesce(bi.n, 0) AS biblios
FROM departement d
LEFT JOIN (SELECT c.code_departement, count(*) n FROM lycee        x JOIN commune c ON c.insee_code = x.insee_code GROUP BY c.code_departement) ly ON ly.code_departement = d.code_departement
LEFT JOIN (SELECT c.code_departement, count(*) n FROM college      x JOIN commune c ON c.insee_code = x.insee_code GROUP BY c.code_departement) co ON co.code_departement = d.code_departement
LEFT JOIN (SELECT c.code_departement, count(*) n FROM pharmacie    x JOIN commune c ON c.insee_code = x.insee_code GROUP BY c.code_departement) ph ON ph.code_departement = d.code_departement
LEFT JOIN (SELECT c.code_departement, count(*) n FROM ehpad        x JOIN commune c ON c.insee_code = x.insee_code GROUP BY c.code_departement) eh ON eh.code_departement = d.code_departement
LEFT JOIN (SELECT c.code_departement, count(*) n FROM bibliotheque x JOIN commune c ON c.insee_code = x.insee_code GROUP BY c.code_departement) bi ON bi.code_departement = d.code_departement
ORDER BY pharmacies DESC
LIMIT 15;

--2. Agréger par territoire

--2.1 la population totale par région et par département ;
SELECT 
    r.code_region,
    r.name AS region,
    d.code_departement,
    d.name AS departement,
    COALESCE(SUM(c.population), 0) AS population_totale
FROM region AS r
LEFT JOIN departement AS d 
    ON d.code_region = r.code_region
LEFT JOIN commune AS c 
    ON c.code_departement = d.code_departement
GROUP BY 
    r.code_region,
    r.name,
    d.code_departement,
    d.name
ORDER BY 
    r.code_region ASC,
    d.code_departement ASC;

--2.2 le classement des départements par nombre de pharmacies (ou de lycées) ;
SELECT 
    d.code_departement,
    d.name AS departement,
    COUNT(p.finess) AS nb_pharmacies
FROM departement AS d
LEFT JOIN commune AS c
    ON d.code_departement = c.code_departement
LEFT JOIN pharmacie AS p
    ON c.insee_code = p.insee_code
GROUP BY 
    d.code_departement,
    d.name
ORDER BY 
    nb_pharmacies DESC;

--2.3 la moyenne d'établissements par commune dans un département.
--pour lycée => le faire pour tous
--https://www.postgresql.org/docs/current/datatype-numeric.html utilisation de numeric sinon ça arrondi trop => on obtient 0
SELECT
    d.code_departement,
    d.name AS departement,
    ROUND(COUNT(l.uai)::numeric / COUNT(DISTINCT c.insee_code), 2) AS moyenne_lycees_par_commune
FROM departement AS d
JOIN commune AS c
    ON c.code_departement = d.code_departement
LEFT JOIN lycee AS l
    ON l.insee_code = c.insee_code
GROUP BY 
    d.code_departement,
    d.name
ORDER BY 
    moyenne_lycees_par_commune DESC;

--3 Croiser les sources

--3.1 les communes qui ont un lycée mais aucune pharmacie (LEFT JOIN ... IS NULL ou NOT EXISTS) ;

--version avec left join et is null :
SELECT DISTINCT
    c.insee_code,
    c.name AS commune,
    d.code_departement,
    d.name AS departement
FROM commune AS c
JOIN departement AS d
    ON d.code_departement = c.code_departement
JOIN lycee AS l
    ON l.insee_code = c.insee_code
LEFT JOIN pharmacie AS p
    ON p.insee_code = c.insee_code
WHERE p.finess IS NULL
ORDER BY 
    d.code_departement,
    c.name;

-- version avec exist et not exist
SELECT
    c.insee_code,
    c.name AS commune,
    d.code_departement,
    d.name AS departement
FROM commune AS c
JOIN departement AS d
    ON d.code_departement = c.code_departement
WHERE EXISTS (
    SELECT 1
    FROM lycee AS l
    WHERE l.insee_code = c.insee_code
)
AND NOT EXISTS (
    SELECT 1
    FROM pharmacie AS p
    WHERE p.insee_code = c.insee_code
)
ORDER BY 
    d.code_departement,
    c.name;

-- 3.2 le profil de service d'une commune : combien de chaque type d'établissement, une colonne par typologie ;

SELECT
    c.insee_code,
    c.name AS commune,
    d.name AS departement,
    r.name AS region,

    COUNT(*) FILTER (WHERE e.typologie = 'lycee') AS nb_lycees,
    COUNT(*) FILTER (WHERE e.typologie = 'college') AS nb_colleges,
    COUNT(*) FILTER (WHERE e.typologie = 'pharmacie') AS nb_pharmacies,
    COUNT(*) FILTER (WHERE e.typologie = 'ehpad') AS nb_ehpad,
    COUNT(*) FILTER (WHERE e.typologie = 'bibliotheque') AS nb_bibliotheques,
    COUNT(*) FILTER (WHERE e.typologie = 'mairie') AS nb_mairies,
    COUNT(*) FILTER (WHERE e.typologie = 'entreprise_btp') AS nb_entreprises_btp,
    COUNT(*) FILTER (WHERE e.typologie = 'gendarmerie') AS nb_gendarmeries,

    COUNT(e.typologie) AS total_etablissements

FROM commune AS c
JOIN departement AS d
    ON d.code_departement = c.code_departement
JOIN region AS r
    ON r.code_region = d.code_region

LEFT JOIN (
    SELECT insee_code, 'lycee' AS typologie FROM lycee
    UNION ALL
    SELECT insee_code, 'college' AS typologie FROM college
    UNION ALL
    SELECT insee_code, 'pharmacie' AS typologie FROM pharmacie
    UNION ALL
    SELECT insee_code, 'ehpad' AS typologie FROM ehpad
    UNION ALL
    SELECT insee_code, 'bibliotheque' AS typologie FROM bibliotheque
    UNION ALL
    SELECT insee_code, 'mairie' AS typologie FROM mairie
    UNION ALL
    SELECT insee_code, 'entreprise_btp' AS typologie FROM entreprise_btp
    UNION ALL
    SELECT insee_code, 'gendarmerie' AS typologie FROM gendarmerie
) AS e
    ON e.insee_code = c.insee_code

GROUP BY
    c.insee_code,
    c.name,
    d.name,
    r.name

ORDER BY
    total_etablissements DESC;

-- 3.3 les communes qui cumulent beaucoup d'habitants et peu de services.
SELECT
    c.insee_code,
    c.name AS commune,
    d.name AS departement,
    r.name AS region,
    c.population,

    COUNT(e.typologie) AS total_services,

    c.population::float / NULLIF(COUNT(e.typologie), 0) AS habitants_par_service

FROM commune AS c
JOIN departement AS d
    ON d.code_departement = c.code_departement
JOIN region AS r
    ON r.code_region = d.code_region

LEFT JOIN (
    SELECT insee_code, 'lycee' AS typologie FROM lycee
    UNION ALL
    SELECT insee_code, 'college' AS typologie FROM college
    UNION ALL
    SELECT insee_code, 'pharmacie' AS typologie FROM pharmacie
    UNION ALL
    SELECT insee_code, 'ehpad' AS typologie FROM ehpad
    UNION ALL
    SELECT insee_code, 'bibliotheque' AS typologie FROM bibliotheque
    UNION ALL
    SELECT insee_code, 'mairie' AS typologie FROM mairie
    UNION ALL
    SELECT insee_code, 'entreprise_btp' AS typologie FROM entreprise_btp
    UNION ALL
    SELECT insee_code, 'gendarmerie' AS typologie FROM gendarmerie
) AS e
    ON e.insee_code = c.insee_code

WHERE c.population IS NOT NULL
  AND c.population > 5000

GROUP BY
    c.insee_code,
    c.name,
    d.name,
    r.name,
    c.population

ORDER BY
    habitants_par_service DESC NULLS FIRST,
    c.population DESC;

-- 4. Des indicateurs

-- 4.1 le nombre d'habitants par pharmacie, par département (population / count) : un repère des zones sous-dotées ;

SELECT
    d.code_departement,
    d.name AS departement,

    (   -- faire plutot un join pour optimiser cette requete et eviter la redonnance
        SELECT SUM(c.population)
        FROM commune c
        WHERE c.code_departement = d.code_departement
    )   AS population_totale,

    (
        SELECT COUNT(DISTINCT p.finess)
        FROM pharmacie p
        JOIN commune c 
            ON c.insee_code = p.insee_code
        WHERE c.code_departement = d.code_departement
    ) AS nombre_pharmacies,

    ROUND(
        (
            SELECT SUM(c.population)
            FROM commune c
            WHERE c.code_departement = d.code_departement
        )::numeric
        /
        NULLIF(
            (
                SELECT COUNT(DISTINCT p.finess)
                FROM pharmacie p
                JOIN commune c 
                    ON c.insee_code = p.insee_code
                WHERE c.code_departement = d.code_departement
            ),
            0
        ),
        2
    ) AS habitants_par_pharmacie

FROM departement d
ORDER BY habitants_par_pharmacie DESC NULLS LAST;


-- 4.2 le taux d'inscription des bibliothèques (emprunteurs rapporté à la population), là où la donnée existe ;

SELECT
    c.insee_code,
    c.name AS commune,
    d.name AS departement,
    b.name AS bibliotheque,
    b.borrowers AS emprunteurs,
    c.population AS population_commune,

    ROUND(
        b.borrowers::numeric / NULLIF(c.population, 0) * 100,
        2
    ) AS taux_inscription_pourcent

FROM bibliotheque b

JOIN commune c
    ON c.insee_code = b.insee_code

JOIN departement d
    ON d.code_departement = c.code_departement

WHERE
    b.borrowers IS NOT NULL
    AND c.population IS NOT NULL
    AND c.population > 0

ORDER BY taux_inscription_pourcent DESC;


-- 4.3 les communes qui cumulent beaucoup d'habitants et peu de services.
SELECT
    code_departement,
    departement,
    SUM(population) AS population_totale,
    SUM(nb_pharmacies) AS nombre_pharmacies,
    ROUND(
        SUM(nb_pharmacies)::numeric / NULLIF(SUM(population), 0) * 10000,
        2
    ) AS pharmacies_pour_10000_habitants
FROM (
    SELECT
        d.code_departement,
        d.name AS departement,
        c.insee_code,
        c.population,
        COUNT(DISTINCT p.finess) AS nb_pharmacies
    FROM departement d
    JOIN commune c
        ON c.code_departement = d.code_departement
    LEFT JOIN pharmacie p
        ON p.insee_code = c.insee_code
    GROUP BY
        d.code_departement,
        d.name,
        c.insee_code,
        c.population
) t
GROUP BY
    code_departement,
    departement
ORDER BY pharmacies_pour_10000_habitants DESC;
-- requete Selim

SELECT d.name AS departement, pop.habitants, ph.pharmacies,
       round(pop.habitants::numeric / ph.pharmacies, 0) AS habitants_par_pharmacie
FROM departement d
JOIN (SELECT code_departement, sum(population) AS habitants
      FROM commune GROUP BY code_departement) pop ON pop.code_departement = d.code_departement
JOIN (SELECT c.code_departement, count(*) AS pharmacies
      FROM pharmacie p JOIN commune c ON c.insee_code = p.insee_code
      GROUP BY c.code_departement) ph ON ph.code_departement = d.code_departement
ORDER BY habitants_par_pharmacie DESC
LIMIT 15;
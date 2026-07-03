-- 1. État des lieux (volumétrie)

--1.1 le nombre de lignes de chaque table (count(*)) 
SELECT
    (SELECT COUNT(*) FROM commune) AS communes,
    (SELECT COUNT(*) FROM mairie) AS mairies,
    (SELECT COUNT(*) FROM lycee) AS lycees,
    (SELECT COUNT(*) FROM college) AS colleges,
    (SELECT COUNT(*) FROM pharmacie) AS pharmacies,
    (SELECT COUNT(*) FROM ehpad) AS ehpads,
    (SELECT COUNT(*) FROM bibliotheque) AS bibliotheques,
    (SELECT COUNT(*) FROM gare) AS gares,
    (SELECT COUNT(*) FROM entreprise_btp) AS entreprises_btp;
  
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
    ROUND(
        COUNT(l.uai)::numeric / COUNT(DISTINCT c.insee_code),
        2
    ) AS moyenne_lycees_par_commune
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
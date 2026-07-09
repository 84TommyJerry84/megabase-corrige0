--requete 1 : le classement des départements par nombre de pharmacies
SELECT
    dc.departement,
    SUM(fe.nb) AS nb_pharmacies
FROM entrepot.fait_etablissement AS fe
JOIN entrepot.dim_commune AS dc
    ON dc.insee_code = fe.insee_code
WHERE fe.type = 'pharmacie'
GROUP BY
    dc.departement
ORDER BY
    nb_pharmacies DESC;

--requet 2 : la population par région et par département
SELECT
    dc.region,
    dc.departement,
    SUM(dc.population) AS population_totale
FROM entrepot.dim_commune AS dc
GROUP BY
    dc.region,
    dc.departement
ORDER BY
    dc.region,
    dc.departement;

SELECT
    dc.region,
    dc.departement,
    SUM(dc.population) AS population_departement,
    SUM(SUM(dc.population)) OVER (PARTITION BY dc.region) AS population_totale_region
FROM entrepot.dim_commune AS dc
GROUP BY
    dc.region,
    dc.departement
ORDER BY
    dc.region,
    dc.departement;

-- requete 2 : la population par region et par département bis
SELECT
    dc.region,
    dc.departement,
    SUM(dc.population) AS population_totale
FROM entrepot.dim_commune AS dc
GROUP BY GROUPING SETS
    ((dc.region),
    (dc.departement))
ORDER BY
    dc.region,
    dc.departement;

--requete 3 : habitants par pharmacie, par département=> brief 4
SELECT
    dc.region,
    dc.departement,
    SUM(dc.population) AS population_totale,
    COALESCE(SUM(fe.nb), 0) AS nb_pharmacies,
    ROUND(SUM(dc.population)::numeric / NULLIF(SUM(fe.nb), 0),2) AS habitants_par_pharmacie
FROM entrepot.dim_commune AS dc
LEFT JOIN entrepot.fait_etablissement AS fe
    ON fe.insee_code = dc.insee_code
    AND fe.type = 'pharmacie'
GROUP BY
    dc.region,
    dc.departement
ORDER BY
    habitants_par_pharmacie DESC;
    
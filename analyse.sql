-- 1. État des lieux (volumétrie)

--1.1 le nombre de lignes de chaque tableSELECT

  (SELECT count(*) FROM commune) communes, (SELECT count(*) FROM mairie) mairies,
  (SELECT count(*) FROM lycee) lycees, (SELECT count(*) FROM college) colleges,
  (SELECT count(*) FROM pharmacie) pharmacies, (SELECT count(*) FROM ehpad) ehpad,
  (SELECT count(*) FROM bibliotheque) biblios, (SELECT count(*) FROM gare) gares,
  (SELECT count(*) FROM entreprise_btp) btp;
  
--1.2 le nombre de commune par région et par département 
select r.name AS region,count(c.insee_code) AS nb_communes
from
commune as c
join
departement as d on c.code_departement=d.code_departement
join
region as r on r.code_region=d.code_region
GROUP BY r.name
ORDER BY nb_communes DESC;

--nombre de communes : 34875
--correction de 1.3
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
--2.1
select d.code_departement, sum(c.population) as Population
from region as r
left join
departement as d on r.code_region=d.code_region
left join
commune as c on  c.code_departement= d.code_departement
group by d.code_departement
order by d.code_departement asc;

select r.code_region, sum(c.population) as Population
from region as r
left join
departement as d on r.code_region=d.code_region
left join
commune as c on  c.code_departement= d.code_departement
group by r.code_region
order by r.code_region asc;
--2.2 
SELECT d.code_departement, COUNT(p.finess) AS nb_pharmacie
FROM departement as d
LEFT JOIN commune as c
ON d.code_departement = c.code_departement
LEFT JOIN pharmacie as p
ON c.insee_code=p.insee_code
GROUP BY d.code_departement
ORDER BY nb_pharmacie;
--
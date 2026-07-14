
SELECT *
FROM entrepot.dim_commune
WHERE commune='Lyon'
LIMIT 5;

BEGIN;

DELETE FROM entrepot.dim_commune
WHERE commune = 'Lyon';

ROLLBACK;

SELECT 
*
FROM information_schema.triggers
WHERE event_object_schema = 'entrepot'
AND event_object_table = 'dim_commune';

--test trigger 

BEGIN;

SELECT *
FROM entrepot.fait_etablissement
WHERE type = 'pharmacie'
ORDER BY insee_code;

INSERT INTO pharmacie (
    finess,
    name,
    category,
    insee_code
)
SELECT
    'TEST-PHARMA-001',
    'Pharmacie de test',
    'Pharmacie d''Officine',
    insee_code
FROM entrepot.dim_commune
LIMIT 1;

DELETE FROM entrepot.fait_etablissement WHERE insee_code=(
SELECT insee_code
FROM pharmacie
WHERE finess = 'TEST-PHARMA-001');

SELECT fe.*
FROM entrepot.fait_etablissement AS fe
JOIN pharmacie AS p
    ON p.insee_code = fe.insee_code
WHERE p.finess = 'TEST-PHARMA-001'
  AND fe.type = 'pharmacie';


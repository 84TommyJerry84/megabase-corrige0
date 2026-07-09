 -- Modèle témoin : vérifie que dbt lit la base et écrit dans le schema dbt
-- "dbt run" crée la table dbt.exemple à partir de ce SELECT
-- 🔴 À supprimer une fois les vrais modèles écrits
SELECT count(*) AS nb_communes
FROM {{ source('megabase0', 'commune') }}

  
    

  create  table "megabase0"."dbt"."exemple__dbt_tmp"
  
  
    as
  
  (
    -- Modèle témoin : vérifie que dbt lit la base et écrit dans le schema dbt
-- "dbt run" crée la table dbt.exemple à partir de ce SELECT
-- 🔴 À supprimer une fois les vrais modèles écrits
SELECT count(*) AS nb_communes
FROM "megabase0"."public"."commune"
  );
  
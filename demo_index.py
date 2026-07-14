"""Démo : les indexs + subtilité avec les index composite.

Le script :
- construit une table de demo (2 millions de lignes) ;
- puis mesure les mêmes trois requêtes à chaque étape :

    Q1  une commune et une année   WHERE insee_code = '69123' AND annee = 2020
    Q2  une commune                WHERE insee_code = '69123'
    Q3  une année                  WHERE annee = 2020

Les étapes sont :
- sans index
- index composite (insee_code, annee)
- index sur (annee) (qui restera lente)

Usage :

    python3 demo_index.py
"""
from dotenv import load_dotenv
import os
import time
import psycopg2

load_dotenv()

def chrono(label,sql):
    """Exécute la requête et affiche son temps et son plan d'exécution
    ⚠️ Une première exécution non mesurée cache (au sens du caching!) les pages :
    il faut donc éviter que la toute première requête paie seule la lecture disque et fausse la comparaison.
    """
    debut = time.perf_counter()
    cur.execute(sql)
    cur.fetchall()
    ms = (time.perf_counter() - debut) * 1000
    print(f"  {label:24s} {ms:8.2f} ms")

Q1 = "SELECT sum(nb) FROM demo_index.fait_etablissement WHERE type = '17'"

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)
conn.autocommit = True
cur = conn.cursor()

#reinitialiser le schema demo
cur.execute("DROP SCHEMA IF EXISTS demo_index CASCADE")
cur.execute("CREATE SCHEMA demo_index")

cur.execute("""
    CREATE TABLE demo_index.fait_etablissement AS
    SELECT lpad(c::text, 5, '0') AS insee_code,
           a::text AS type,
           (random() * 1000)::int AS nb
    FROM generate_series(1, 36000) c,
         generate_series(1, 55) a
""")

# cur.execute("select * from demo_index.fait_etablissement")

# resultat=cur.fetchall()

# for ligne in resultat:
#     print(ligne)

chrono("Q1 sans index",Q1)

cur.execute("""
    CREATE INDEX idx_fe_type
    ON demo_index.fait_etablissement(type)
""")

chrono("Q3 avec index",Q1)



# def plan(sql):
#     """Le noeud de lecture choisi par PostgreSQL : Seq Scan, Index Scan..."""
#     cur.execute("EXPLAIN " + sql)
#     for (ligne,) in cur.fetchall():
#         if "Scan" in ligne:
#             return ligne.strip().split(" (cost")[0].removeprefix("->  ")
#     return "?"


# def chrono(label, sql):
#     """Exécute la requête et affiche son temps et son plan d'exécution

#     ⚠️ Une première exécution non mesurée cache (au sens du caching!) les pages :
#     il faut donc éviter que la toute première requête paie seule la lecture disque et fausse la comparaison.
#     """
#     cur.execute(sql)
#     cur.fetchall()
#     debut = time.perf_counter()
#     cur.execute(sql)
#     cur.fetchall()
#     ms = (time.perf_counter() - debut) * 1000
#     print(f"  {label:24s} {ms:8.2f} ms   {plan(sql)}")


# def titre(texte):
#     print(f"\n--- {texte}")


# Q1 = "SELECT nb FROM demo_index.frequentation WHERE insee_code = '69123' AND annee = 2020"
# Q2 = "SELECT sum(nb) FROM demo_index.frequentation WHERE insee_code = '69123'"
# Q3 = "SELECT sum(nb) FROM demo_index.frequentation WHERE annee = 2020"


# titre("construction de la table de démo (~2 millions de lignes)")
# debut = time.perf_counter()
# cur.execute("DROP SCHEMA IF EXISTS demo_index CASCADE")
# cur.execute("CREATE SCHEMA demo_index")
# # 36 000 communes fictives x 55 années : aucun index, pas même de clé
# # primaire, pour partir d'une table nue.
# cur.execute("""
#     CREATE TABLE demo_index.frequentation AS
#     SELECT lpad(c::text, 5, '0') AS insee_code,
#            a                     AS annee,
#            (random() * 1000)::int AS nb
#     FROM generate_series(1, 36000) c,
#          generate_series(1970, 2024) a
# """)
# # ANALYZE donne au planificateur les statistiques de la table
# cur.execute("ANALYZE demo_index.frequentation")
# cur.execute("SELECT count(*) FROM demo_index.frequentation")
# print(f"  {cur.fetchone()[0]} lignes en {time.perf_counter() - debut:.1f} s")


# titre("étape 1 : sans index, tout est un Seq Scan (lecture complète)")
# chrono("Q1 commune + année", Q1)
# chrono("Q2 commune seule", Q2)
# chrono("Q3 année seule", Q3)

# titre("étape 2 : index composite sur (insee_code, annee)")
# debut = time.perf_counter()
# cur.execute("""
#     CREATE INDEX idx_commune_annee
#     ON demo_index.frequentation (insee_code, annee)
# """)
# print(
#     f"  création : {time.perf_counter() - debut:.1f} s (ce temps se repaie à chaque TRUNCATE + INSERT)"
# )
# # L'index est trié par insee_code, puis par annee à insee_code fixé!
# #  Comme un annuaire trié par (nom, prénom) :
# #   - chercher (Dupont, Marie)  : direct                         -> Q1
# #   - chercher tous les Dupont  : direct, ils sont contigus      -> Q2
# #   - chercher toutes les Marie : éparpillées, il faut tout lire -> Q3
# # ⚠️ aspect commun aux tris (annuaires ou indexes SQL) :
# # c'est la règle du préfixe gauche : l'index sert si la requête filtre sur
# # le début de la liste de colonnes!! (i.e. le nom ici et pas le prénom)
# chrono("Q1 commune + année", Q1)
# # Q2 peut afficher « Bitmap Heap Scan » : c'est aussi (plus ou moins) une lecture par
# # l'index.
# # Pour en savoir plus :
# # Explications dans la réponse de Denis de Bernardy https://stackoverflow.com/questions/6592626/what-is-a-bitmap-heap-scan-in-a-query-plan
# # Explication détaillée (mais plus compliqué) https://pganalyze.com/docs/explain/scan-nodes/bitmap-heap-scan
# chrono("Q2 commune seule", Q2)
# chrono("Q3 année seule", Q3)
# print("  -> Q3 n'a pas bougé : annee est dans l'index, mais pas en préfixe.")

# titre("étape 3 : un index où annee est en tête")
# cur.execute("CREATE INDEX idx_annee ON demo_index.frequentation (annee)")
# chrono("Q3 année seule", Q3)
# print("  -> (annee, insee_code) aurait marché aussi : annee y est en préfixe.")

# titre("prix des index")
# # Un index occupe de l'espace.
# cur.execute("""
#     SELECT pg_size_pretty(pg_relation_size('demo_index.frequentation')),
#            pg_size_pretty(pg_indexes_size('demo_index.frequentation'))
# """)
# table, index = cur.fetchone()
# print(f"  table : {table}, index : {index}")

# print("EXPLAIN ANALYZE dans psql ou pgAdmin. DROP SCHEMA demo_index CASCADE pour nettoyer.")

# conn.close()
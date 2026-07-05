"""Executer un fichier .sql sans psql (utile sur Windows, et pour Scalingo).

Base locale (megabase0 par defaut) :

    python3 run_sql.py entrepot.sql
    python run_sql.py entrepot.sql          # Windows

Base distante (Scalingo) : definir DATABASE_URL avant de lancer.

    export DATABASE_URL="postgres://..."    # macOS / Linux
    $env:DATABASE_URL = "postgres://..."    # Windows PowerShell
    python run_sql.py entrepot.sql
"""

import os
import pathlib
import sys

import psycopg2

DB_URL = "postgresql://postgres:toto@localhost:5432/megabase0"

if len(sys.argv) < 2:
    sys.exit("usage : python run_sql.py fichier.sql")
path = pathlib.Path(sys.argv[1])

conn = psycopg2.connect(DB_URL)
conn.autocommit = True  # comme psql : chaque instruction est validee
cur = conn.cursor()
cur.execute(path.read_text(encoding="utf-8"))

for notice in conn.notices:
    print(notice.strip())

if cur.description:  # la derniere instruction renvoiedes lignes
    print(" | ".join(c.name for c in cur.description))
    for row in cur.fetchall():
        print(" | ".join(str(v) for v in row))

conn.close()
# On n'affiche jamais DB_URL en entier: elle peut contenir un mot de passe.
cible = DB_URL.rsplit("@", 1)[-1] if "@" in DB_URL else DB_URL
print(f"OK : {path.name} execute sur {cible}")
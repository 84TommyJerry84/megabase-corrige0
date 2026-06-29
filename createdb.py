"""Créer la base megabase0 (équivalent Windows de `createdb megabase0`).

Usage :
    python createdb.py

Réglages via variables d'environnement (sinon valeurs par défaut) :
    PGHOST     (defaut localhost)
    PGPORT     (defaut 5432)
    PGUSER     (defaut postgres)
    PGPASSWORD (demandé si absent)
    DBNAME     (defaut megabase0)
"""

import os

import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

DBNAME = os.environ.get("DBNAME", "megabase0")

conn = psycopg2.connect(
    host=os.environ.get("PGHOST", "localhost"),
    port=os.environ.get("PGPORT", "5432"),
    user=os.environ.get("PGUSER", "postgres"),
    password=os.environ.get("PGPASSWORD", "to"),
    dbname="postgres",
)
conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)

with conn.cursor() as cur:
    cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (DBNAME,))
    if cur.fetchone():
        print(f"La base {DBNAME} existe déjà, rien à faire.")
    else:
        cur.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(DBNAME)))
        print(f"Base {DBNAME} créée.")

conn.close()

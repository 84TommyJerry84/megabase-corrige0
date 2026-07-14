from dotenv import load_dotenv
from sqlalchemy import create_engine
import os
import psycopg2
import pandas as pd

load_dotenv()

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)

engine = create_engine(
    "postgresql+psycopg2://postgres:toto@localhost:5432/megabase0"
)

df_fe= pd.read_sql("select * from entrepot.fait_etablissement",engine)

df_dc=pd.read_sql("select * from entrepot.dim_commune",engine)

df_merge= df_fe.merge(df_dc,on="insee_code", how="left")

mart_pandas = (
    df_merge
    .groupby(["departement", "type"], as_index=False)["nb"]
    .sum()
    .rename(columns={"nb": "n"})
)

mart_sql = pd.read_sql(
    """
    SELECT
        d.departement,
        f.type,
        SUM(f.nb) AS n
    FROM entrepot.fait_etablissement AS f
    JOIN entrepot.dim_commune AS d
        ON d.insee_code = f.insee_code
    GROUP BY
        d.departement,
        f.type
    """,
    engine
)

colonnes_triees = ["departement", "type"]

mart_pandas = (
    mart_pandas
    .sort_values(colonnes_triees)
    .reset_index(drop=True)
)

mart_sql = (
    mart_sql
    .sort_values(colonnes_triees)
    .reset_index(drop=True)
)

pd.testing.assert_frame_equal(
    mart_pandas,
    mart_sql,    
)

print(f"Comparaison faite : avec {len(mart_pandas)} lignes comparées.")
print("==============================================================")
print(mart_pandas)
print("==============================================================")
print(mart_sql)

conn.close()
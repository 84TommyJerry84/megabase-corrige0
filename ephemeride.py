import requests
import psycopg2
import time

#parametres de la connection postgres
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="megabase0",
    user="postgres",
    password="toto"
)


cur = conn.cursor()

cur.execute("""
    SELECT insee_code, name
    FROM commune
    LIMIT 500;
    
""")

rows = cur.fetchall()

code_insee=[]

for row in rows:
    code_insee.append(row[0])

#print(code_insee)

TOKEN="d4c55fb08eb4e53d262963b8a49513e7324ecb59143a49355fa9028cb71d5c67"
url = 'https://api.meteo-concept.com/api/ephemeride/1'

for insee in code_insee:

    params = {
        "token": TOKEN,
        "insee": insee
    }

    response = requests.get(url, params=params)

    if response.status_code == 200:
        data = response.json()

        ephemeride = data["ephemeride"]        

        insee_code=ephemeride["insee"]
        ephemeride_date=ephemeride["datetime"]
        sunrise = ephemeride["sunrise"]
        sunset = ephemeride["sunset"]
        day_duration = ephemeride["duration_day"]

        cur.execute("""
            INSERT INTO ephemeride(
                insee_code,
                ephemeride_date,
                sunrise,
                sunset,
                day_duration
            )
            VALUES (%s, %s, %s, %s, %s)
        """,
        (
            insee_code,
            ephemeride_date,
            sunrise,
            sunset,
            day_duration
        ))

        #print("Inséré :", insee)

    else:
        print("Requête ne passe pas :", insee, response.status_code, response.text)

    time.sleep(0.2)


print("ephemerides ont bien ajoutées")

conn.commit()

cur.close()
conn.close()

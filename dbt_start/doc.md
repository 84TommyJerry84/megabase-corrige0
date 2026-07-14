# commandes :

## environnement virtuel dédié
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt

## la connexion fonctionne ?
dbt debug          # attendu : "All checks passed"

## construire le modèle témoin
dbt run            # attendu : "1 of 1 OK created sql table model dbt.exemple"

psql -d megabase0 -c "SELECT * FROM dbt.exemple"
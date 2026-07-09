# dbt_start : squelette pour le brief 08

Un projet dbt minimal, prêt à lancer sur `megabase0`.

| Fichier | Rôle |
|---|---|
| `dbt_project.yml` | le projet : nom, dossier des modèles, matérialisation |
| `profiles.yml` | la connexion à la base (dbt le lit dans le dossier du projet) |
| `requirements.txt` | la dépendance à installer (`dbt-postgres`) |
| `models/sources.yml` | les tables de la base de collecte, à compléter |
| `models/exemple.sql` | un modèle témoin, à supprimer ensuite |

## Lancer 

```bash
# environnement virtuel dédié
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt

# la connexion fonctionne ?
dbt debug          # attendu : "All checks passed"

# construire le modèle témoin
dbt run            # attendu : "1 of 1 OK created sql table model dbt.exemple"
```

Vérification dans psql :

```bash
psql -d megabase0 -c "SELECT * FROM dbt.exemple"

```
ou quand le psql n'est pas dans le path bien prendre la bonne version ici c'est la 18

```bash
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -U postgres -d megabase0 -c "SELECT * FROM dbt.exemple;"

```
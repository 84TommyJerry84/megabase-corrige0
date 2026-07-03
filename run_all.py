"""Enchaîner main.py sur les 101 départements (corrigé du brief 05).

    python3 run_all.py

Sur Scalingo : Procfile "worker: python3 run_all.py". Si le worker est
interrompu ou relancé, la reprise de main.py (count_rows) repart de l'état de
la base : rien n'est perdu, rien n'est dupliqué. Une fois tout chargé, passer
le worker à 0 conteneur.
"""

import pathlib
import subprocess
import sys

# La liste du README : pas de 20 (c'est 2A/2B), DOM 971-974 et 976.
DEPTS = (
    "01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 2A 2B "
    "21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 "
    "41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 "
    "61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 "
    "81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 971 972 973 974 976"
).split()

MAIN = pathlib.Path(__file__).resolve().parent / "main.py"

echecs = []
for i, dept in enumerate(DEPTS, 1):
    print(f"--- {dept} ({i}/{len(DEPTS)}) ---", flush=True)
    # Un run par département. Si l'un échoue (API en panne, coupure), on passe
    # au suivant : le prochain passage de run_all.py reprendra où c'était.
    result = subprocess.run([sys.executable, str(MAIN), dept])
    if result.returncode != 0:
        echecs.append(dept)

if echecs:
    print(f"terminé, à relancer pour reprendre : {' '.join(echecs)}")
else:
    print("terminé : les 101 départements sont passés")


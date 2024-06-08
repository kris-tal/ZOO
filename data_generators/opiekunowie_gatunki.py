import random
import re

def generuj_opiekunowie_gatunki(plik, liczba_gatunkow):
    opiekunowie = []
    opiekun_wybrany = {}
    queries = []

    with open(plik, 'r') as f:
        for line in f:
            match = re.search(r'\((\d+), (\d+)\)', line)
            if match:
                id_pracownika, id_stanowiska = match.groups()
                if id_stanowiska == '4':
                    opiekunowie.append(id_pracownika)
                    opiekun_wybrany[id_pracownika] = False

    for id_gatunku in range(1, liczba_gatunkow + 1):
        id_pracownika = random.choice(opiekunowie)
        queries.append(f"({id_pracownika}, {id_gatunku})")
        opiekunowie.remove(id_pracownika)
        opiekun_wybrany[id_pracownika] = True

    for id_pracownika, wybrany in opiekun_wybrany.items():
        if not wybrany:
            id_gatunku = random.randint(1, liczba_gatunkow)
            queries.append(f"({id_pracownika}, {id_gatunku})")

    with open('opiekunowie_gatunki.sql', 'w') as f:
        f.write("INSERT INTO opiekunowie_gatunki (id_pracownika, id_gatunku) VALUES\n")
        f.write(",\n".join(queries) + ";")


generuj_opiekunowie_gatunki('pracownicy_stanowiska.sql', 100)
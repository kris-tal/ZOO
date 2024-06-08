import random
import re

def generuj_sprzatacze_wybiegi(plik, liczba_wybiegow):
    sprzatacze = []
    sprzatacz_wybrany = {}
    queries = []

    with open(plik, 'r') as f:
        for line in f:
            match = re.search(r'\((\d+), (\d+)\)', line)
            if match:
                id_pracownika, id_stanowiska = match.groups()
                if id_stanowiska == '2':
                    sprzatacze.append(id_pracownika)
                    sprzatacz_wybrany[id_pracownika] = False

    for id_wybiegu in range(1, liczba_wybiegow + 1):
        id_pracownika = random.choice(sprzatacze)
        queries.append(f"({id_pracownika}, {id_wybiegu})")
        sprzatacze.remove(id_pracownika)
        sprzatacz_wybrany[id_pracownika] = True

    for id_pracownika, wybrany in sprzatacz_wybrany.items():
        if not wybrany:
            id_wybiegu = random.randint(1, liczba_wybiegow)
            queries.append(f"({id_pracownika}, {id_wybiegu})")

    with open('sprzatacze_wybiegi.sql', 'w') as f:
        f.write("INSERT INTO sprzatacze_wybiegi (id_pracownika, id_wybiegu) VALUES\n")
        f.write(",\n".join(queries) + ";\n")

generuj_sprzatacze_wybiegi('pracownicy_stanowiska.sql', 200)
import random
import re

def generuj_trenerzy_gatunki(plik_pracownik_stanowisko, liczba_gatunkow):
    trenerzy = []

    with open(plik_pracownik_stanowisko, 'r') as f:
        for line in f:
            match = re.search(r'\((\d+), (\d+), (.+)\)', line)
            if match:
                id_pracownika, id_stanowiska, _ = match.groups()
                if id_stanowiska == '3':
                    trenerzy.append(id_pracownika)

    with open('trenerzy_gatunki.sql', 'w') as f:
        f.write("INSERT INTO trenerzy_gatunki (id_pracownika, id_gatunku) VALUES\n")
        for i, id_trenera in enumerate(trenerzy):
            id_gatunku = random.randint(1, liczba_gatunkow)
            if i != len(trenerzy) - 1:
                f.write(f"({id_trenera}, {id_gatunku}),\n")
            else:
                f.write(f"({id_trenera}, {id_gatunku});\n")

generuj_trenerzy_gatunki('pracownicy_stanowiska.sql', 100)
import random
import re

def generuj_trenerzy_gatunki(plik_pracownik_stanowisko, liczba_gatunkow):
    trenerzy = []

    with open(plik_pracownik_stanowisko, 'r') as f:
        for line in f:
            match = re.search(r'\((\d+), (\d+)\)', line)
            if match:
                id_pracownika, id_stanowiska = match.groups()
                if id_stanowiska == '3':
                    trenerzy.append(id_pracownika)

    print("INSERT INTO trenerzy_gatunki (id_trenera, id_gatunku) VALUES")
    for i, id_trenera in enumerate(trenerzy):
        id_gatunku = random.randint(1, liczba_gatunkow)
        if i != len(trenerzy) - 1:
            print(f"({id_trenera}, {id_gatunku}),")
        else:
            print(f"({id_trenera}, {id_gatunku});")

generuj_trenerzy_gatunki('pracownik_stanowisko.sql', 100)
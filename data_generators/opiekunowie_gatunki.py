import random
import re

def generuj_opiekunowie_gatunki(plik, liczba_gatunkow):
    opiekunowie = []

    with open(plik, 'r') as f:
        for line in f:
            match = re.search(r'\((\d+), (\d+)\)', line)
            if match:
                id_pracownika, id_stanowiska = match.groups()
                if id_stanowiska == '4':
                    opiekunowie.append(id_pracownika)

    print("INSERT INTO opiekunowie_gatunki (id_pracownika, id_gatunku) VALUES")
    
    for i, id_pracownika in enumerate(opiekunowie):
        print(f"({id_pracownika}, {i+1}),")

    for id_gatunku in range(len(opiekunowie) + 1, liczba_gatunkow + 1):
        id_pracownika = random.choice(opiekunowie)
        print(f"({id_pracownika}, {id_gatunku}),")

generuj_opiekunowie_gatunki('pracownik-stanowisko.sql', 100)
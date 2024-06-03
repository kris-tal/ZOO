import random
import re

def generuj_sprzatacze_wybiegi(plik, liczba_wybiegow):
    sprzatacze = []

    with open(plik, 'r') as f:
        for line in f:
            match = re.search(r'\((\d+), (\d+)\)', line)
            if match:
                id_pracownika, id_stanowiska = match.groups()
                if id_stanowiska == '2':
                    sprzatacze.append(id_pracownika)

    print("INSERT INTO sprzatacze_wybiegi (id_pracownika, id_wybiegu) VALUES")
    
    for i, id_pracownika in enumerate(sprzatacze):
        print(f"({id_pracownika}, {i+1}),")

    for id_wybiegu in range(len(sprzatacze) + 1, liczba_wybiegow + 1):
        id_pracownika = random.choice(sprzatacze)
        print(f"({id_pracownika}, {id_wybiegu}),")

generuj_sprzatacze_wybiegi('pracownik_stanowisko.sql', 200)
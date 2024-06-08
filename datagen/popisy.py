import random
import re

trenerzy = []
with open('pracownicy_stanowiska.sql', 'r') as f:
    for line in f:
        match = re.search(r'\((\d+),\s*(\d+)', line)
        if match:
            id_pracownika, id_stanowiska = match.groups()
            if id_stanowiska == '3':
                trenerzy.append(id_pracownika)

f = open('gatunki.sql').read().split('\n')
ile_zwierzat = len(f) - 2
nazwy = open('popisy.txt').read().split('\n')

gatunki = open('gatunki.sql').read().split("\n")
for i in range(len(gatunki)):
    gatunki[i] = gatunki[i][2:gatunki[i].find(',')-1]
gatunki = gatunki[1:]
print(gatunki)

w = open('popisy.sql', 'w')
w.write('INSERT INTO popisy (trener, gatunek, min_ilosc, min_poziom_umiejetnosci, nazwa) VALUES\n')

for i in range(401):
    gat = random.randint(1, ile_zwierzat)
    nazwa = random.choice(nazwy)
    nazwa = nazwa[nazwa.find(" "):]
    w.write(f'({random.choice(trenerzy)}, {gat}, {random.randint(1, 7)}, '
            f'{random.randint(0, 10)}, \'{gatunki[gat-1] + nazwa}\')')
    if i < 400: w.write(',\n')
    else: w.write(';\n')

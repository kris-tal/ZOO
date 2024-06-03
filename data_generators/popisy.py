import random

f = open('pracownicy_stanowiska.sql').read().split('\n')

trenerzy = []
for line in f:
    if line[line.find(',') + 2:line.find(')')] == '3':
        trenerzy.append(line[1:line.find(',')])

f = open('zwierzeta.sql').read().split('\n')
ile_zwierzat = len(f) - 2

w = open('popisy.sql', 'w')
w.write('INSERT INTO popisy (trener, gatunek, min_ilosc, min_poziom_umiejetnosci) VALUES\n')

for i in range(401):
    w.write(f'({random.choice(trenerzy)}, {random.randint(1, ile_zwierzat)}, {random.randint(1, 7)}, '
            f'{random.randint(0, 10)})')
    if i < 400: w.write(',\n')
    else: w.write(';\n')

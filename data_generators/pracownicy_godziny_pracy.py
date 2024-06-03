import random

f = open('pracownicy.sql').read().split('\n')
ile = len(f) - 1
w = open('pracownicy_godziny_pracy.sql', 'w')
w.write('INSERT INTO pracownicy_godziny_pracy (id_pracownika, dzien_tygodnia, godzina_od, godzina_do) VALUES\n')

for emp in range(1, ile):
    for dow in range(1, 8):
        godzina_od = max(2, int(random.gauss(9, 3)))
        godzina_do = min(23, max(godzina_od + 4, int(random.gauss(18, 3))))
        godzina_do = str(godzina_do)
        godzina_od = str(godzina_od)

        if len(godzina_od) == 1: godzina_od = '0' + godzina_od
        if len(godzina_do) == 1: godzina_do = '0' + godzina_do

        if godzina_od > godzina_do: print(0)
        w.write(f'({emp}, {dow}, \'{godzina_od}:00\', \'{godzina_do}:00\')')

        if emp + dow == ile + 6:
            w.write(',\n')
        else:
            w.write(';\n')

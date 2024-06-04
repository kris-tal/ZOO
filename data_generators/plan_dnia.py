from random import random, randint, gauss
import datetime
with open('wybiegi.sql') as f:
    wybiegi = len(f.readlines()) - 2

with open('gatunki.sql') as f:
    gatunki = len(f.readlines()) - 2

with open('popisy.sql') as f:
    popisy = len(f.readlines()) - 2

w = open('plan_dnia.sql', 'w')
w.write('INSERT INTO plan_dnia (data, godzina_od, godzina_do, id_sprzatacza, id_karmienia, id_popisu) VALUES\n')

godziny = [] # godziny popisow
for h in range(10, 19):
    for m in range(0, 60, 15):
        if m == 5 or m == 0:
            a = '0' + str(m)
        else:
            a = str(m)
        godziny.append(str(h) + ':' + a)
godziny.append('19:00')

# popisy
plan = []
for dayofweek in range(1, 8):
    for i in range(1000):
        data = datetime.date.today() + datetime.timedelta(days=(dayofweek+1))
        rozp = int(round(random() * 32, 0))
        zako = int(round(min(random() * min(38 - rozp, 10) + rozp, 36), 0))
        r = godziny[rozp]
        z = godziny[zako]
        w.write(f'(\'{data}\', \'{r}\',\'{z}\', NULL, NULL, {randint(1, popisy)}),\n')


godziny = []
for h in range(24):
    for m in range(0, 60, 15):
        if m == 5 or m == 0:
            a = '0' + str(m)
        else:
            a = str(m)
        godziny.append(str(h) + ':' + a)

# karmienie
for gatunek in range(1, gatunki+1):
    for razydziennie in range(int(random()*2 + 1)):
        godz = max(min(int(gauss(52, 15)), 85), 0)
        rozp = godziny[godz]
        godz = godz + int(round(random()*5, 0) + 1)
        zako = godziny[godz]
        for dayofweek in range(1, 8):
            data = datetime.date.today() + datetime.timedelta(days=(dayofweek+1))
            w.write(f'(\'{data}\', \'{rozp}\',\'{zako}\', NULL, {gatunek}, NULL),\n')

# sprzatanie
for wybieg in range(1, wybiegi):
    days = []
    days.append(int(round(random()*6 + 1)))
    days.append((days[0] + 3) % 7 + 1)
    godz = max(min(int(gauss(52, 15)), 85), 0)
    rozp = godziny[godz]
    godz = godz + int(round(random()*7, 0) + 3)
    zako = godziny[godz]
    for dayofweek in days:
        data = datetime.date.today() + datetime.timedelta(days=(dayofweek+1))
        w.write(f'(\'{data}\', \'{rozp}\',\'{zako}\', {wybieg}, NULL, NULL)')
        if wybieg == wybiegi - 1 and dayofweek == days[1]: w.write(';\n')
        else: w.write(',\n')
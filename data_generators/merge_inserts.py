import subprocess
w = open('all_inserts.sql', 'w')

scripts = [
    'pracownicy.py',
    'strefy.py',
    'wybiegi.py',
    'gatunki.py',
    'pracownicy_stanowiska.py',
    'zwierzeta.py',
    #'nieobecnosci_pracownikow.py',
    'niedyspozycja_zwierzat.py',
    'opiekunowie_gatunki.py',
    'popisy.py',
    'pracownicy_godziny_pracy.py',
    'sprzatacze_wybiegi.py',
    'trenerzy_gatunki.py',
    'plan_dnia.py'
]

for script in scripts:
    subprocess.call(['python3', script])

data = [
    open('godziny_otwarcia.sql').read(),
    open('pracownicy.sql').read(),
    open('strefy.sql').read(),
    open('wybiegi.sql').read(),
    open('gatunki.sql').read(),
    open('stanowiska.sql').read(),
    open('pracownicy_stanowiska.sql').read(),
    open('zwierzeta.sql').read(),
    open('nieobecnosci_pracownikow.sql').read(),
    open('niedyspozycja_zwierzat.sql').read(),
    open('opiekunowie_gatunki.sql').read(),
    open('popisy.sql').read(),
    open('pracownicy_godziny_pracy.sql').read(),
    open('sprzatacze_wybiegi.sql').read(),
    open('trenerzy_gatunki.sql').read(),
    open('plan_dnia.sql').read()
]

with open('all_inserts.sql', 'w') as w:
    w.write('BEGIN;\n\n')
    for insert in data:
        w.write(insert)
        w.write('\n\n')
    w.write('COMMIT;\n')
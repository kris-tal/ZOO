w = open('all_inserts.sql', 'w')

data = [
    open('gatunki.sql').read(),
    open('godziny_otwarcia.sql').read(),
    open('nieobecnosci_pracownikow.sql').read(),
    open('niedyspozycja_zwierzat.sql').read(),
    open('opiekunowie_gatunki.sql').read(),
    open('pracownicy.sql').read(),
    open('pracownicy_godziny_pracy.sql').read(),
    open('pracownicy_stanowiska.sql').read(),
    open('sprzatacze_wybiegi.sql').read(),
    open('stanowiska.sql').read(),
    open('strefy.sql').read(),
    open('trenerzy_gatunki.sql').read(),
    open('wybiegi.sql').read(),
    open('zwierzeta.sql').read()
]

for insert in data:
    w.write(insert)
    w.write('\n\n')

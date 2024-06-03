w = open('all_inserts.sql', 'w')

data = [
    open('godziny_otwarcia.sql').read(),
    open('pracownicy.sql').read(),
    open('pracownicy_godziny_pracy.sql'),
    open('pracownik-stanowisko.sql').read(),
    open('stanowiska.sql').read(),
    open('strefy.sql').read(),
    open('wybiegi.sql').read()
]

for insert in data:
    w.write(insert)
    w.write('\n\n')

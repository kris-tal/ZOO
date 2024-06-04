import random

names = [
'Lew', 'Tygrys', 'Słoń', 'Żyrafa', 'Hipopotam', 'Krokodyl', 'Panda wielka', 'Koala', 'Pawian', 'Flaming', 'Nosorożec', 'Zebra', 'Kangur', 'Orangutan', 'Goryl', 'Żółw olbrzymi',
'Niedźwiedź polarny', 'Wilk szary', 'Lis polarny', 'Jeleń', 'Królik', 'Wiewiórka', 'Szop pracz', 'Skunks', 'Bóbr', 'Wydra europejska', 'Delfin', 'Opos', 'Mysz', 'Szczur',
'Nietoperz', 'Łasica', 'Kret', 'Jeżozwierz', 'Pancernik', 'Fretka', 'Jeż europejski', 'Motyl', 'Świstak', 'Burunduk', 'Kuna domowa', 'Łoś', 'Piżmak', 'Ryjówka',
'Nornik', 'Piesek preriowy', 'Kojot', 'Dingo', 'Hiena cętkowana', 'Szakal', 'Południowy wombat', 'Gepard', 'Lampart', 'Jaguar', 'Pantera', 'Puma', 'Ryś', 'Ryś rudy', 'Kuguar', 'Ocelot',
'Serwal', 'Karakal', 'Cyweta', 'Genet', 'Mangusta', 'Surykatka', 'Gronostaj', 'Rosomak', 'Foka szara', 'Mors', 'Lew morski', 'Mrównik', 'Mrówkojad wielki', 'Łuskowiec', 'Kolczatka',
'Dziobak', 'Szpak', 'Walabia', 'Wombat', 'Diabeł tasmański', 'Aksolotl', 'Bilbi', 'Kuoka', 'Dinozaur', 'Lotopałanka', 'Wilk workowaty', 'Kuśkus', 'Rekin', 'Pingwin',
'Wąż', 'Surykatka', 'Kanguroszczur', 'Siteks ruczajowy', 'Aligator', 'Północny wombat', 'Dziki kot', 'Meduza', 'Szynszyla', 'Armadillo', 'Świnia rzeczna', 'Manat'
]

def generate_species(n):
    print("INSERT INTO gatunki (nazwa, id_wybiegu) VALUES")
    for i in range(n):
        nazwa = names[i]
        id_wybiegu = random.randint(1, 16)
        if i != n - 1:
            print(f"('{nazwa}', {id_wybiegu}),")
        else:
            print(f"('{nazwa}', {id_wybiegu});")

generate_species(100)
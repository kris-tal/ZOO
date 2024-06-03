from faker import Faker

fake = Faker()
from faker import Faker

fake = Faker()
names = ['Afryka', 'Sawanna', 'Ocean', 'Pustynia', 'Jungla', 'Tundra', 'Góry', 'Równina', 'Step', 'Bagna', 'Półwysep', 'Wyspa', 'Terrarium', 'Biegun', 'Las', 'Wyry']

def generate_zones(n):
    print("INSERT INTO strefy (nazwa) VALUES")
    for i in range(n):
        nazwa = names[i]
        if i != n - 1:
            print(f"('{nazwa}'),")
        else:
            print(f"('{nazwa}');")

generate_zones(16)
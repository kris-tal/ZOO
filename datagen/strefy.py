from faker import Faker

fake = Faker()
zone_names = ['Afryka', 'Sawanna', 'Ocean', 'Pustynia', 'Jungla', 'Tundra', 'Góry', 'Równina', 'Step', 'Bagna', 'Półwysep', 'Wyspa', 'Terrarium', 'Biegun', 'Las', 'Wyry']

def generate_zones(n):
    with open('strefy.sql', 'w') as f:
        f.write("INSERT INTO strefy (nazwa) VALUES\n")
        for i in range(n):
            nazwa = zone_names[i]
            if i != n - 1:
                f.write(f"('{nazwa}'),\n")
            else:
                f.write(f"('{nazwa}');\n")

generate_zones(16)
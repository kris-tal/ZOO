from faker import Faker
import random

fake = Faker('pl_PL')

def generuj_zwierzeta(n):
    with open('zwierzeta.sql', 'w') as f:
        f.write("INSERT INTO zwierzeta (gatunek, imie, poziom_umiejetnosci) VALUES\n")
        for i in range(1, n+1):
            gatunek = random.randint(1, 100)
            imie = f"'{fake.first_name()}'" if i % 10 == 0 else "NULL"
            poziom_umiejetnosci = random.randint(1, 10)
            if i != n:
                f.write(f"({gatunek}, {imie}, {poziom_umiejetnosci}),\n")
            else:
                f.write(f"({gatunek}, {imie}, {poziom_umiejetnosci});\n")

generuj_zwierzeta(5000)
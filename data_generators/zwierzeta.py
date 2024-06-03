from faker import Faker
import random

fake = Faker('pl_PL')

def generuj_zwierzeta(n):
    print("INSERT INTO zwierzeta (gatunek, imie, poziom_umiejetnosci) VALUES")
    for i in range(1, n+1):
        gatunek = random.randint(1, 100)
        imie = f"'{fake.first_name()}'" if i % 10 == 0 else "NULL"
        poziom_umiejetnosci = random.randint(1, 10)
        if i != n:
            print(f"({gatunek}, {imie}, {poziom_umiejetnosci}),")
        else:
            print(f"({gatunek}, {imie}, {poziom_umiejetnosci});")

generuj_zwierzeta(5000)
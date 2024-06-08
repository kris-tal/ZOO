from faker import Faker
import random
from datetime import datetime, timedelta

fake = Faker('pl_PL')

def generate_random_date():
    days_in_past = random.randint(0, 20*365)
    random_date = datetime.now() - timedelta(days=days_in_past)
    return random_date.strftime('%Y-%m-%d')

def generuj_zwierzeta(n):
    with open('zwierzeta.sql', 'w') as f:
        f.write("INSERT INTO zwierzeta (gatunek, imie, poziom_umiejetnosci, data_dodania) VALUES\n")
        for i in range(1, n+1):
            gatunek = random.randint(1, 100)
            imie = f"'{fake.first_name()}'" if i % 10 == 0 else "NULL"
            poziom_umiejetnosci = random.randint(1, 10)
            data_dodania = generate_random_date()
            if i != n:
                f.write(f"({gatunek}, {imie}, {poziom_umiejetnosci}, \'{data_dodania}\'),\n")
            else:
                f.write(f"({gatunek}, {imie}, {poziom_umiejetnosci}, \'{data_dodania}\');\n")

generuj_zwierzeta(5000)
import random
from faker import Faker
import datetime

fake = Faker('pl_PL')
f = open('zwierzeta.sql').read().split('\n')
ile = len(f) - 2


w = open('niedyspozycja_zwierzat.sql', 'w')
w.write('INSERT INTO niedyspozycja_zwierzat(id_zwierzecia, data_od, data_do, powod) VALUES\n')

nieobecnosci_id = []
for i in range(1001):
    id = random.randint(1, ile - 1)
    data_od = datetime.date.today() + datetime.timedelta(days=random.randint(3, 365))
    data_do = data_od + datetime.timedelta(days = random.randint(0, 14))
    powod = fake.text(12)
    w.write(f'({id}, \'{data_od}\', \'{data_do}\', NULL)')
    if i == 1000: w.write(";\n")
    else: w.write(",\n")

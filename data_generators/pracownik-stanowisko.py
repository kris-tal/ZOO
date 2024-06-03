from faker import Faker
import random
import string
import hashlib

fake = Faker('pl_PL')

def generate_position_tuples():
    with open('pracownicy.sql', 'r') as f:
        employees = [line.strip() for line in f]

    for i, employee in enumerate(employees, start=1):
        if i <= 20:
            position_ids = random.sample(range(1, 5), 2)
            for position_id in position_ids:
                yield (i, position_id)
        else:
            position_id = random.randint(1, 4)
            yield (i, position_id)


for employee in generate_position_tuples():
    print(employee)

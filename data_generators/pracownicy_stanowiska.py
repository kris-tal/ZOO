from faker import Faker
import random
import string
import hashlib

fake = Faker('pl_PL')

w = open('pracownicy_stanowiska.sql', 'w')

def generate_position_tuples():
    w.write("INSERT INTO pracownicy_stanowiska (id_pracownika, id_stanowiska) VALUES\n")
    with open('pracownicy.sql', 'r') as f:
        employees = [line.strip() for line in f]

    employee_tuples = []
    for i, employee in enumerate(employees, start=1):
        if i <= 10:
            position_ids = random.sample(range(1, 5), 2)
            for position_id in position_ids:
                employee_tuples.append((i, position_id))
        else:
            position_id = random.randint(1, 4)
            employee_tuples.append((i, position_id))

    for i, employee_tuple in enumerate(employee_tuples):
        if i != len(employee_tuples) - 1:
            w.write(f"{employee_tuple},\n")
        else:
            w.write(f"{employee_tuple};\n")

generate_position_tuples()

from faker import Faker
import random
import string
import hashlib

fake = Faker('pl_PL')

def generate_position_tuples():
    print("INSERT INTO praconicy-stanowiska (id_pracownika, id_stanowiska) VALUES")
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
            print(f"{employee_tuple},")
        else:
            print(f"{employee_tuple};")

generate_position_tuples()

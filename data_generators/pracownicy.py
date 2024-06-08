from faker import Faker
import random
import string
import hashlib

fake = Faker('pl_PL')

def generate_pesel():
    pesel = [random.randint(0, 9) for _ in range(10)]
    weights = [1, 3, 7, 9, 1, 3, 7, 9, 1, 3]
    checksum = sum(p*w for p, w in zip(pesel, weights)) % 10
    check_digit = (10 - checksum) % 10
    pesel.append(check_digit)

    pesel_str = ''.join(str(d) for d in pesel)

    return pesel_str

def generate_employee_tuples(n):
    with open('pracownicy.sql', 'w') as f:
        f.write("INSERT INTO pracownicy (imie, nazwisko, pesel, haslo) VALUES\n")
        id_counter = 1
        employee_tuples = []
        with open('passwords.txt', 'w') as pwf:
            for _ in range(n):
                imie = fake.first_name()
                nazwisko = fake.last_name()
                pesel = generate_pesel()
                haslo = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(8)) + random.choice('.!?')
                pwf.write(f'{id_counter} : {haslo}\n')
                employee_tuples.append((imie, nazwisko, pesel, haslo))
                id_counter += 1

        for i, employee_tuple in enumerate(employee_tuples):
            if i != len(employee_tuples) - 1:
                f.write(f"{employee_tuple},\n")
            else:
                f.write(f"{employee_tuple};\n")

generate_employee_tuples(1000)
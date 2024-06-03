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
    print("INSERT INTO pracownicy (imie, nazwisko, pesel, haslo) VALUES")
    id_counter = 1
    employee_tuples = []
    with open('passwords.txt', 'w') as f:
        for _ in range(n):
            imie = fake.first_name()
            nazwisko = fake.last_name()
            pesel = generate_pesel()
            password = ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(8)) + random.choice('.!?')
            f.write(f'ID: {id_counter}, Password: {password}\n')
            haslo = int(hashlib.sha256(password.encode('utf-8')).hexdigest(), 16) % 10**8
            employee_tuples.append((imie, nazwisko, pesel, haslo))
            id_counter += 1

    for i, employee_tuple in enumerate(employee_tuples):
        if i != len(employee_tuples) - 1:
            print(f"{employee_tuple},")
        else:
            print(f"{employee_tuple};")

generate_employee_tuples(1000)
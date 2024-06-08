import random
from datetime import datetime, timedelta

def generate_random_date():
    days_in_past = random.randint(0, 20*365)
    random_date = datetime.now() - timedelta(days=days_in_past)
    return random_date.strftime('%Y-%m-%d')

def generate_position_tuples():
    with open('pracownicy_stanowiska.sql', 'w') as w:
        w.write("INSERT INTO pracownicy_stanowiska (id_pracownika, id_stanowiska, data_dodania) VALUES\n")

        employee_tuples = []
        for i in range(1, 1001):
            if i <= 10:
                position_ids = random.sample(range(1, 5), 2)
                for position_id in position_ids:
                    employee_tuples.append((i, position_id, generate_random_date()))
            else:
                position_id = random.randint(1, 4)
                employee_tuples.append((i, position_id, generate_random_date()))

        for i, employee_tuple in enumerate(employee_tuples):
            if i != len(employee_tuples) - 1:
                w.write(f"{employee_tuple},\n")
            else:
                w.write(f"{employee_tuple};\n")

generate_position_tuples()

generate_position_tuples()
import random

def generate_enclosures(n):
    print("INSERT INTO wybiegi (strefa) VALUES")
    for i in range(n):
        strefa = random.randint(1, 16)
        if i != n - 1:
            print(f"({strefa}),")
        else:
            print(f"({strefa});")

generate_enclosures(200)
import random

def generate_enclosures(n):
    with open('wybiegi.sql', 'w') as f:
        f.write("INSERT INTO wybiegi (strefa) VALUES\n")
        for i in range(n):
            strefa = random.randint(1, 16)
            if i != n - 1:
                f.write(f"({strefa}),\n")
            else:
                f.write(f"({strefa});\n")

generate_enclosures(200)
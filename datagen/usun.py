import hashlib

password = "slayer123"
print(int(hashlib.sha256(password.encode('utf-8')).hexdigest(), 16) % 10**8)
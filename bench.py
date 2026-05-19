import time
import os

def bench_exists_open(filename, iterations=100000):
    start = time.time()
    for _ in range(iterations):
        if not os.path.exists(filename):
            pass
        else:
            with open(filename, 'r') as f:
                pass
    return time.time() - start

def bench_try_open(filename, iterations=100000):
    start = time.time()
    for _ in range(iterations):
        try:
            with open(filename, 'r') as f:
                pass
        except FileNotFoundError:
            pass
    return time.time() - start

with open('dummy.json', 'w') as f:
    f.write('{}')

print("With file:")
print("exists + open:", bench_exists_open('dummy.json'))
print("try open:", bench_try_open('dummy.json'))

print("Without file:")
print("exists + open:", bench_exists_open('missing.json'))
print("try open:", bench_try_open('missing.json'))

os.remove('dummy.json')

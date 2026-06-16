import math
import time
import random

def length(dx, dy):
    return math.hypot(dx, dy)

def length_squared(dx, dy):
    return dx*dx + dy*dy

points = [(random.uniform(-10, 10), random.uniform(-10, 10)) for _ in range(1000)]
target = (10.0, 10.0)

start = time.time()
for _ in range(10000):
    min_dist = 1e9
    for p in points:
        d = length(target[0] - p[0], target[1] - p[1])
        if d < min_dist:
            min_dist = d
t1 = time.time() - start

start = time.time()
for _ in range(10000):
    min_dist_sq = 1e18
    for p in points:
        d = length_squared(target[0] - p[0], target[1] - p[1])
        if d < min_dist_sq:
            min_dist_sq = d
t2 = time.time() - start

print(f"Length: {t1:.4f}s")
print(f"Length squared: {t2:.4f}s")
print(f"Improvement: {(t1-t2)/t1*100:.2f}%")

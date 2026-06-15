import re

with open("tests/test_complex_field.gd", "r") as f:
    content = f.read()

# Original failed assertions:
# 2.24564933776855468750] expected to equal [-0.207886] +/- [0.015]
# 0.99988269805908203125] expected to equal [1.0] +/- [0.0001]
# 0.00010671735071809962] expected to equal [0.0] +/- [0.0001]

print("Done")

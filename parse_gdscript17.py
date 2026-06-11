import re

with open("tests/test_complex_field.gd", "r") as f:
    code = f.read()

# Let's check test_log_zeta_continuation_with_derivatives.
print("-2.0" in code)

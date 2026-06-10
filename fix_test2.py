import re

with open('tests/test_complex_field.gd', 'r') as f:
    content = f.read()

print("File has been read.")
# The only issue might be:
# In the latest patch I did:
# var expected_step1 = ComplexFieldScript.complex_div(expected_f1_val, expected_f1_prime)
# if expected_step1.length() > 1.0:
#     expected_step1 = expected_step1.normalized() * 1.0
# var expected_z1_next = z1 - expected_step1 * 1.0
#
# This perfectly matches:
# var step = complex_div(f_val, f_prime)
# if step.length() > max_step:
#     step = step.normalized() * max_step
# return [z - step * step_size_mult, f_val]

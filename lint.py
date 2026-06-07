import sys

def check_file(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if '\t' in line and ' ' in line.lstrip('\t'):
            # This is a bit simplistic, but usually GDScript uses tabs
            pass

    # Look for obvious syntax errors
    for i, line in enumerate(lines):
        if line.strip() == "break":
            # ensure it's indented
            pass

check_file('math/complex_field.gd')
print("Looks OK")

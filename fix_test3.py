with open('tests/test_complex_field.gd', 'r') as f:
    content = f.read()

# Make sure we restore Config properly if any assert fails
# Actually gut assertions don't throw exceptions, they just print and continue, so the restore at the end should run.

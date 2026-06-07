import subprocess
result = subprocess.run(["godot", "--check-only", "math/complex_field.gd"], capture_output=True, text=True)
print(result.stdout)
print(result.stderr)

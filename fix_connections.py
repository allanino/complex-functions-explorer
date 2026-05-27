import subprocess
out = subprocess.check_output("git show 94b02df:scenes/hud.tscn", shell=True).decode()
connections = [line for line in out.split('\n') if '[connection' in line]
for c in connections:
    print(c)

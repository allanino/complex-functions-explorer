import re

with open("terrain/terrain.gdshader", "r") as f:
    content = f.read()

print("compute_position_marker" in content)

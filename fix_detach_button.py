import re
from pathlib import Path

content = Path("scenes/hud.tscn").read_text()
# I deleted the ExitDetachButton! Wait!
# The pattern for orphaned DetachButtons:
# `\[node name="[^"]+DetachButton" type="Button" parent="[^"]+"\]\n(?:.*?\n)*?(?=\n\[node|\Z)`
# It deleted `ExitDetachButton` because it ends with `DetachButton`!
# Ah!

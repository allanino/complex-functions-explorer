import sys

filepath = 'core/game_state.gd'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace(
    'var total_zeros_found: int = 0',
    'var total_zeros_found: int = 0\nvar accented_zero_index: int = -1\n'
)

with open(filepath, 'w') as f:
    f.write(content)

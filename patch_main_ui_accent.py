import sys

filepath = 'ui/main_ui.gd'
with open(filepath, 'r') as f:
    content = f.read()

search_str = """
		if total_count != _last_zeros_count:
			_last_zeros_count = total_count
			zeros_count_label.text = str(total_count)

			var current_size = GameState.visited_zeros.size()
			if GameState.accented_zero_index == -1 or GameState.accented_zero_index >= current_size:
				GameState.accented_zero_index = current_size - 1

			# Clear existing items
"""

replace_str = """
		if total_count != _last_zeros_count:
			_last_zeros_count = total_count
			zeros_count_label.text = str(total_count)

			var current_size = GameState.visited_zeros.size()
			GameState.accented_zero_index = current_size - 1

			# Clear existing items
"""

content = content.replace(search_str, replace_str)

with open(filepath, 'w') as f:
    f.write(content)

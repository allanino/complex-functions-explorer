import sys

filepath = 'ui/minimap.gd'
with open(filepath, 'r') as f:
    content = f.read()

search_str = """
		if Config.show_hud_zeros:
			var visited = PackedVector2Array()
			for val in GameState.visited_zeros:
				visited.append(val)
			var v_size = min(visited.size(), 10)
			while visited.size() < 10:
				visited.append(Vector2.ZERO)

			if visited.size() > 10:
				var truncated = PackedVector2Array()
				for i in range(10):
					truncated.append(visited[i])
				visited = truncated

			mat.set_shader_parameter("visited_zeros_size", v_size)
			mat.set_shader_parameter("visited_zeros", visited)
"""

replace_str = """
		if Config.show_hud_zeros:
			var visited = PackedVector2Array()
			for val in GameState.visited_zeros:
				visited.append(val)
			var v_size = min(visited.size(), 10)
			var shader_accented_index = GameState.accented_zero_index
			if visited.size() > 10:
				shader_accented_index = GameState.accented_zero_index - (visited.size() - 10)

			while visited.size() < 10:
				visited.append(Vector2.ZERO)

			if visited.size() > 10:
				var truncated = PackedVector2Array()
				for i in range(visited.size() - 10, visited.size()):
					truncated.append(visited[i])
				visited = truncated

			mat.set_shader_parameter("visited_zeros_size", v_size)
			mat.set_shader_parameter("visited_zeros", visited)
			mat.set_shader_parameter("accented_zero_index", shader_accented_index)
"""

content = content.replace(search_str, replace_str)

with open(filepath, 'w') as f:
    f.write(content)

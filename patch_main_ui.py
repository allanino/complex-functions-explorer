import sys

filepath = 'ui/main_ui.gd'
with open(filepath, 'r') as f:
    content = f.read()

search_str = """
		var total_count = GameState.total_zeros_found
		if total_count != _last_zeros_count:
			_last_zeros_count = total_count
			zeros_count_label.text = str(total_count)

			# Clear existing items
			for child in zeros_list_label.get_children():
				zeros_list_label.remove_child(child)
				child.queue_free()

			var current_size = GameState.visited_zeros.size()
			var actual_hud_scale = Config.hud_scale
			for i in range(current_size - 1, max(-1, current_size - 11), -1):
				var zero = GameState.visited_zeros[i]
				var re_str = _format_float_3(zero[0])
				var im_str = _format_float_3(zero[1])
				var item = ZERO_LIST_ITEM_SCENE.instantiate()
				zeros_list_label.add_child(item)
				item.set_values(re_str, im_str)
				_rescale_card(item, actual_hud_scale)
				if i == current_size - 1:
					item.is_active = true
"""

replace_str = """
		var total_count = GameState.total_zeros_found
		if total_count != _last_zeros_count:
			_last_zeros_count = total_count
			zeros_count_label.text = str(total_count)

			var current_size = GameState.visited_zeros.size()
			if GameState.accented_zero_index == -1 or GameState.accented_zero_index >= current_size:
				GameState.accented_zero_index = current_size - 1

			# Clear existing items
			for child in zeros_list_label.get_children():
				zeros_list_label.remove_child(child)
				child.queue_free()

			var actual_hud_scale = Config.hud_scale
			for i in range(current_size - 1, max(-1, current_size - 11), -1):
				var zero = GameState.visited_zeros[i]
				var re_str = _format_float_3(zero[0])
				var im_str = _format_float_3(zero[1])
				var item = ZERO_LIST_ITEM_SCENE.instantiate()
				zeros_list_label.add_child(item)
				item.zero_index = i
				item.clicked.connect(_on_zero_item_clicked)
				item.set_values(re_str, im_str)
				_rescale_card(item, actual_hud_scale)
				if i == GameState.accented_zero_index:
					item.is_active = true
"""

content = content.replace(search_str, replace_str)

new_func = """
func _on_zero_item_clicked(index: int):
	GameState.accented_zero_index = index
	for item in zeros_list_label.get_children():
		item.is_active = (item.zero_index == index)
"""

content += new_func

with open(filepath, 'w') as f:
    f.write(content)

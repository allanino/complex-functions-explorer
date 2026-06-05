import sys

with open('ui/main_ui.gd', 'r') as f:
    content = f.read()

old_logic = """		if total_count != _last_zeros_count:
			_last_zeros_count = total_count
			var last_zeros_text = ""
			var current_size = GameState.visited_zeros.size()
			for i in range(current_size - 1, -1, -1):
				var zero = GameState.visited_zeros[i]
				last_zeros_text += "(%s, %s)\\n" % [_format_float_3(zero[0]), _format_float_3(zero[1])]

			if total_count > 10:
				last_zeros_text += "•••\\n"

			zeros_count_label.text = "Count: %d" % total_count
			zeros_list_label.text = last_zeros_text"""

new_logic = """		if total_count != _last_zeros_count:
			_last_zeros_count = total_count
			zeros_count_label.text = "Count: [color=#e8e4dc]" + str(total_count) + "[/color]"

			# Clear existing items
			for child in zeros_list_label.get_children():
				child.queue_free()

			var current_size = GameState.visited_zeros.size()
			for i in range(current_size - 1, max(-1, current_size - 11), -1):
				var zero = GameState.visited_zeros[i]
				var re_str = _format_float_3(zero[0])
				var im_str = _format_float_3(zero[1])
				var item = ZERO_LIST_ITEM_SCENE.instantiate()
				zeros_list_label.add_child(item)
				item.set_values(re_str, im_str)
				if i == current_size - 1:
					item.is_active = true"""

if old_logic in content:
    content = content.replace(old_logic, new_logic)
    with open('ui/main_ui.gd', 'w') as f:
        f.write(content)
    print("Replaced!")
else:
    print("Old logic not found!")

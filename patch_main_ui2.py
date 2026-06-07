import sys

filepath = 'ui/main_ui.gd'
with open(filepath, 'r') as f:
    content = f.read()

search_str = """
				item.zero_index = i
				item.clicked.connect(_on_zero_item_clicked)
				item.set_values(re_str, im_str)
"""

replace_str = """
				item.zero_index = i
				item.clicked.connect(_on_zero_item_clicked)
				item.set_values(re_str, im_str, f_data.get("is_dirichlect", false))
"""

content = content.replace(search_str, replace_str)

with open(filepath, 'w') as f:
    f.write(content)

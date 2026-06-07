import sys

filepath = 'ui/components/zero_list_item.gd'
with open(filepath, 'r') as f:
    content = f.read()

content = content.replace(
    'extends PanelContainer',
    'extends PanelContainer\n\nsignal clicked(index: int)\nvar zero_index: int = -1\n'
)

new_func = """
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(zero_index)
"""

content += new_func

with open(filepath, 'w') as f:
    f.write(content)

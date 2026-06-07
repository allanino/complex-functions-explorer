import sys

filepath = 'ui/components/zero_list_item.gd'
with open(filepath, 'r') as f:
    content = f.read()

search_str = """
func set_values(re: String, im: String):
	real_label.text = "1/2" if re == "0.500" else re
	imag_label.text = " + " + im + " i"
"""

replace_str = """
func set_values(re: String, im: String, is_dirichlet: bool):
	if is_dirichlet and re == "0.500":
		real_label.text = "1/2"
		real_label.add_theme_color_override("font_color", Color(0.784314, 0.662745, 0.431373, 1)) # Gold
	else:
		real_label.text = re
		real_label.add_theme_color_override("font_color", Color(0.3647, 0.847, 0.7843, 1)) # Cyan

	imag_label.text = " + " + im + " i"
"""

content = content.replace(search_str, replace_str)

with open(filepath, 'w') as f:
    f.write(content)

import sys

with open('ui/main_ui.gd', 'r') as f:
    content = f.read()

old_logic = """	domain_label.text = "Re = %s\\nIm = %s" % [_format_float_3(val_re), _format_float_3(val_im)]
	var target_text = "Re = %s\\nIm = %s\\n|f| = %s" % [_format_float_3(val_fx), _format_float_3(val_fy), _format_float_3(f.length())]"""

new_logic = """	domain_label.text = "[color=#5dd8c8]Re[/color] = %s\\n[color=#d45fa0]Im[/color] = %s" % [_format_float_3(val_re), _format_float_3(val_im)]
	var target_text = "[color=#5dd8c8]Re[/color] = %s\\n[color=#d45fa0]Im[/color] = %s\\n[color=#c8a96e]|f|[/color] = %s" % [_format_float_3(val_fx), _format_float_3(val_fy), _format_float_3(f.length())]"""


if old_logic in content:
    content = content.replace(old_logic, new_logic)
    with open('ui/main_ui.gd', 'w') as f:
        f.write(content)
    print("Replaced BBCode labels!")
else:
    print("Old logic not found!")

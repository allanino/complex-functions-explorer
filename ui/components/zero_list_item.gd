extends PanelContainer

signal clicked(index: int)
var zero_index: int = -1


@onready var real_label = %RealLabel
@onready var imag_label = %ImagLabel

var is_active: bool = false: set = set_active

func set_active(val: bool):
	is_active = val
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if is_active:
		style.border_color = Color("#c8a96e")
		style.bg_color = Color(200.0 / 255.0, 169.0 / 255.0, 110.0 / 255.0, 0.07)
	else:
		style.border_color = Color(1, 1, 1, 0)
		style.bg_color = Color(0.909804, 0.894118, 0.862745, 0.08)
	add_theme_stylebox_override("panel", style)

func set_values(re: String, im: String, is_dirichlet: bool):
	if is_dirichlet and re == "0.500":
		real_label.text = "1/2"
		real_label.add_theme_color_override("font_color", Color(0.784314, 0.662745, 0.431373, 1)) # Gold
	else:
		real_label.text = re
		real_label.add_theme_color_override("font_color", Color(0.3647, 0.847, 0.7843, 1)) # Cyan

	# ink_dim = Color(0.909804, 0.894118, 0.862745, 0.5) → #e7e4dc80
	if im.begins_with("-"):
		imag_label.text = "[color=#e7e4dc80] - [/color][color=#d45fa0]" + im.substr(1) + " i[/color]"
	else:
		imag_label.text = "[color=#e7e4dc80] + [/color][color=#d45fa0]" + im + " i[/color]"

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(zero_index)

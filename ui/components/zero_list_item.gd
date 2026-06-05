extends PanelContainer

@onready var real_label = %RealLabel
@onready var imag_label = %ImagLabel

var is_active: bool = false : set = set_active

func set_active(val: bool):
	is_active = val
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if is_active:
		style.border_color = Color("#c8a96e")
		style.bg_color = Color(200.0/255.0, 169.0/255.0, 110.0/255.0, 0.07)
	else:
		style.border_color = Color(1, 1, 1, 0)
		style.bg_color = Color(0.909804, 0.894118, 0.862745, 0.08)
	add_theme_stylebox_override("panel", style)

func set_values(re: String, im: String):
	real_label.text = "1/2" if re == "0.500" else re
	imag_label.text = "+ " + im + " i"

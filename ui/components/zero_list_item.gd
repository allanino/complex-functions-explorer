extends PanelContainer

signal clicked(index: int)
var zero_index: int = -1

@onready var real_label = %RealLabel
@onready var imag_label = %ImagLabel

var is_active: bool = false: set = set_active

# Theme color constants (BBCode hex)
const CLR_DIM = "#e7e4dc80" # ink_dim (50% alpha)
const CLR_GOLD = "#c8a96e" # theme gold
const CLR_CYAN = "#5dd8c8" # cyan
const CLR_MAGENTA = "#d45fa0" # magenta
const CLR_MAGENTA_DIM = "#d45fa0b3"

# Wraps a numeric string in BBCode: dims a leading '-' sign, colors the rest.
func _bb_re(value: String, color: String) -> String:
	if value.begins_with("-"):
		return "[color=%s]-[/color][color=%s]%s[/color]" % [CLR_DIM, color, value.substr(1)]
	return "[color=%s]%s[/color]" % [color, value]

# Formats an imaginary value as "± number i" with a dim operator separator.
func _bb_im(im: String) -> String:
	if im.begins_with("-"):
		return "[color=%s] - [/color][color=%s]%s[/color][color=%s]i[/color]" % [CLR_DIM, CLR_MAGENTA, im.substr(1), CLR_MAGENTA_DIM]
	return "[color=%s] + [/color][color=%s]%s[/color][color=%s]i[/color]" % [CLR_DIM, CLR_MAGENTA, im, CLR_MAGENTA_DIM]

func set_active(val: bool):
	if is_active == val:
		return
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
		real_label.text = "[color=%s]1/2[/color]" % CLR_GOLD
	else:
		real_label.text = _bb_re(re, CLR_CYAN)
	imag_label.text = _bb_im(im)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(zero_index)

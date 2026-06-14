extends AspectRatioContainer

@onready var color_rect = %ColorRect
@onready var angle_label = %AngleLabel
@onready var formula_label = %FormulaLabel

var target_f := Vector2.RIGHT
var display_f := Vector2.RIGHT

const ROT_SPEED := 360.0
const CRAZY_THRESHOLD := 1e-20
const CRAZY_SPIN := 5.0 # rotations/sec at exact zero

var crazy_angle := 0.0

func _ready():
	Config.config_changed.connect(_on_config_changed)
	_update_formula_label()
	_update_material_config()
	# Performance: Only run _process loop when PhaseWheel is visible in the UI
	set_process(is_visible_in_tree())

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		# Performance: Dynamically disable/enable _process to save CPU cycles when hidden
		set_process(is_visible_in_tree())

func _on_config_changed(key: String):
	if key == "function_type":
		_update_formula_label()
	elif key in ["color_scheme", "terrain_brightness", "terrain_saturation", "terrain_albedo", "terrain_emission"]:
		_update_material_config()

func _update_material_config():
	# Performance: Extracted static shader uniform assignments out of _process to prevent redundant GPU calls every frame
	if color_rect.material:
		var mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("color_scheme", Config.color_scheme)
		mat.set_shader_parameter("brightness", Config.terrain_brightness)
		mat.set_shader_parameter("saturation", Config.terrain_saturation)
		mat.set_shader_parameter("albedo", Config.terrain_albedo)
		mat.set_shader_parameter("emission", Config.terrain_emission)

func _update_formula_label():
	var symbol = Config.function.get("symbol", "f")
	if symbol.length() > 0:
		symbol = symbol[0]
	else:
		symbol = "f"
	formula_label.text = "arg(" + symbol + ")"

func update_data(f: Vector2) -> void:
	if not is_finite(f.x) or not is_finite(f.y):
		return
	target_f = f

func _apply_phase(f: Vector2) -> void:
	if color_rect.material:
		var mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("current_f", f)

	var angle_rad: float

	# This crazy computation is just to match shader's precision limits
	var f_dir = Vector2(0.0, 0.0)
	if f.length() > 0:
		f_dir = f.normalized()

	if f_dir.length() > 1e-12:
		angle_rad = atan2(f_dir.y, f_dir.x)
	else:
		var ry = round(f.y * 1e20) / 1e20
		var rx = round(f.x * 1e20) / 1e20
		if rx == 0.0 && ry == 0.0:
			angle_rad = 0.0
		else:
			angle_rad = atan2(ry, rx)

	var angle_deg = rad_to_deg(angle_rad)
	if angle_deg < 0:
		angle_deg += 360.0

	# Update text
	angle_label.text = "%.1f°" % angle_deg

	# Compute matching color
	var hue = (angle_rad + PI) / (2.0 * PI)
	if Config.color_scheme == 1:
		hue = wrapf(hue + 0.5, 0.0, 1.0)

	var saturation = clamp(Config.terrain_saturation, 0.3, 1.0) * 0.5
	var brightness = Config.terrain_brightness

	var hsv_color = Color.from_hsv(hue, saturation, min(brightness, 1.0))
	if Config.color_scheme == 2:
		var v = 0.5 + 0.5 * cos(angle_rad)
		hsv_color = Color(v, v, v) * brightness

	var final_color = hsv_color * (Config.terrain_albedo + Config.terrain_emission) * 2.0
	# Clamp to valid 0-1 range for UI text
	final_color.r = clamp(final_color.r, 0.0, 1.0)
	final_color.g = clamp(final_color.g, 0.0, 1.0)
	final_color.b = clamp(final_color.b, 0.0, 1.0)
	final_color.a = 1.0

	angle_label.add_theme_color_override("font_color", final_color)

func _process(delta: float) -> void:
	if not is_finite(display_f.x) or not is_finite(display_f.y):
		display_f = Vector2.RIGHT
		crazy_angle = 0.0

	var mag = target_f.length()

	# Enter chaos mode near zero
	if mag < CRAZY_THRESHOLD:
		var strength = 1.0 - clamp(mag / CRAZY_THRESHOLD, 0.0, 1.0)

		# quadratic ramp → gets insane close to zero
		var spin_speed = TAU * CRAZY_SPIN * strength * strength

		crazy_angle += spin_speed * delta

		display_f = Vector2.from_angle(crazy_angle)

		_apply_phase(display_f)
		return

	# reset chaos so normal tracking resumes cleanly
	crazy_angle = target_f.angle()

	var current_angle = display_f.angle()
	var target_angle = target_f.angle()

	var diff = wrapf(target_angle - current_angle, -PI, PI)

	var t = 1.0 - exp(-ROT_SPEED * delta)

	var new_angle = current_angle + diff * t

	display_f = Vector2.from_angle(new_angle)

	_apply_phase(display_f)
extends HBoxContainer

signal toggled(toggled_on: bool)

@export var text: String = "":
	set(value):
		text = value
		if is_inside_tree():
			$Label.text = text

@export var button_pressed: bool = false:
	set(value):
		button_pressed = value
		if is_inside_tree():
			$Control/CheckBox.button_pressed = button_pressed

static var _checkbox_icons_initialized: bool = false

func _ready():
	$Label.text = text
	$Control/CheckBox.button_pressed = button_pressed
	_update_text_and_color(button_pressed)
	$Control/CheckBox.toggled.connect(func(toggled_on):
		button_pressed = toggled_on
		_update_text_and_color(toggled_on)
		toggled.emit(toggled_on)
	)

	if not _checkbox_icons_initialized:
		_checkbox_icons_initialized = true
		# Generate custom CheckBox checked and unchecked indicator square box textures
		var cb_size = 17
		var bg_col = Color(0.028, 0.045, 0.090, 0.94) # Dark panel background
		var border_col = Color(0.890, 0.875, 0.845, 0.22) # Dropdown border color
		
		# Unchecked indicator: dark panel bg and subtle border
		var img_uncheck = Image.create(cb_size, cb_size, false, Image.FORMAT_RGBA8)
		for y in range(cb_size):
			for x in range(cb_size):
				if x == 0 or x == cb_size - 1 or y == 0 or y == cb_size - 1:
					if (x == 0 or x == cb_size - 1) and (y == 0 or y == cb_size - 1):
						img_uncheck.set_pixel(x, y, Color(border_col.r, border_col.g, border_col.b, 0.1))
					else:
						img_uncheck.set_pixel(x, y, border_col)
				else:
					img_uncheck.set_pixel(x, y, bg_col)
		var uncheck_tex = ImageTexture.create_from_image(img_uncheck)
		
		# Checked indicator: gold background fill with a dark checkmark inside
		var img_check = Image.create(cb_size, cb_size, false, Image.FORMAT_RGBA8)
		var check_bg_col = Color(0.784314, 0.662745, 0.431373, 1.0) # Gold background
		var check_mark_col = Color(0.015686, 0.031372, 0.070588, 1.0) # Dark checkmark color
		for y in range(cb_size):
			for x in range(cb_size):
				if x == 0 or x == cb_size - 1 or y == 0 or y == cb_size - 1:
					if (x == 0 or x == cb_size - 1) and (y == 0 or y == cb_size - 1):
						img_check.set_pixel(x, y, Color(check_bg_col.r, check_bg_col.g, check_bg_col.b, 0.1))
					else:
						img_check.set_pixel(x, y, check_bg_col)
				else:
					img_check.set_pixel(x, y, check_bg_col)
		
		# Draw dark checkmark on the gold background with antialiasing and centered alignment
		var s = float(cb_size)

		# Normalized coordinates (works for any size)
		var p1 = Vector2(0.24 * s, 0.50 * s)
		var p2 = Vector2(0.41 * s, 0.69 * s)
		var p3 = Vector2(0.73 * s, 0.32 * s)

		# Scale thickness with checkbox size
		var inner = max(0.75, s * 0.045)
		var outer = max(1.75, s * 0.10)

		for y in range(cb_size):
			for x in range(cb_size):
				if x == 0 or x == cb_size - 1 or y == 0 or y == cb_size - 1:
					continue

				var p_center = Vector2(x + 0.5, y + 0.5)

				var d1 = _dist_to_segment(p_center, p1, p2)
				var d2 = _dist_to_segment(p_center, p2, p3)

				var d = min(d1, d2)

				if d <= inner:
					img_check.set_pixel(x, y, check_mark_col)
				elif d < outer:
					var alpha = 1.0 - ((d - inner) / (outer - inner))
					img_check.set_pixel(
						x,
						y,
						check_bg_col.lerp(check_mark_col, alpha)
					)

		var check_tex = ImageTexture.create_from_image(img_check)
		
		# Disabled unchecked image
		var img_uncheck_disabled = Image.create(cb_size, cb_size, false, Image.FORMAT_RGBA8)
		for y in range(cb_size):
			for x in range(cb_size):
				var c = img_uncheck.get_pixel(x, y)
				img_uncheck_disabled.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * 0.4))
		var uncheck_disabled_tex = ImageTexture.create_from_image(img_uncheck_disabled)

		# Disabled checked image
		var img_check_disabled = Image.create(cb_size, cb_size, false, Image.FORMAT_RGBA8)
		for y in range(cb_size):
			for x in range(cb_size):
				var c = img_check.get_pixel(x, y)
				img_check_disabled.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * 0.4))
		var check_disabled_tex = ImageTexture.create_from_image(img_check_disabled)
		
		var global_theme = preload("res://ui/theme/theme.tres")
		global_theme.set_icon("checked", "CheckBox", check_tex)
		global_theme.set_icon("unchecked", "CheckBox", uncheck_tex)
		global_theme.set_icon("checked_disabled", "CheckBox", check_disabled_tex)
		global_theme.set_icon("unchecked_disabled", "CheckBox", uncheck_disabled_tex)

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var ap = p - a
	var l2 = ab.length_squared()
	if l2 == 0.0:
		return p.distance_to(a)
	var t = ap.dot(ab) / l2
	t = clamp(t, 0.0, 1.0)
	var closest = a + t * ab
	return p.distance_to(closest)

func set_pressed_no_signal(pressed: bool):
	button_pressed = pressed
	$Control/CheckBox.set_pressed_no_signal(pressed)
	_update_text_and_color(pressed)

func _update_text_and_color(is_on: bool):
	$Control/CheckBox.text = "On" if is_on else "Off"
	if is_on:
		$Control/CheckBox.remove_theme_color_override("font_color")
		$Control/CheckBox.remove_theme_color_override("font_hover_color")
		$Control/CheckBox.remove_theme_color_override("font_focus_color")
		$Control/CheckBox.remove_theme_color_override("font_hover_pressed_color")
	else:
		var ink_dim = Color(0.909804, 0.894118, 0.862745, 0.5)
		$Control/CheckBox.add_theme_color_override("font_color", ink_dim)
		$Control/CheckBox.add_theme_color_override("font_hover_color", ink_dim)
		$Control/CheckBox.add_theme_color_override("font_focus_color", ink_dim)
		$Control/CheckBox.add_theme_color_override("font_hover_pressed_color", ink_dim)

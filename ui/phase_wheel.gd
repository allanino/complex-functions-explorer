extends AspectRatioContainer

@onready var color_rect = %ColorRect
@onready var angle_label = %AngleLabel
@onready var label_top = %LabelTop
@onready var label_bottom = %LabelBottom
@onready var label_left = %LabelLeft
@onready var label_right = %LabelRight

func _ready() -> void:
	resized.connect(_on_resized)

func _on_resized() -> void:
	if not is_inside_tree() or not label_top:
		return

	# The track radius in the shader is 0.75 in UV space (where UV is -1 to 1, meaning diameter is 1.5 * scale)
	# The wheel is rendered centered on this AspectRatioContainer.
	# We want a consistent visual margin from the edge of the track to the text.
	var center = size * 0.5
	var track_pixel_radius = size.x * 0.5 * 0.75
	var margin = 5.0 # Constant gap between wheel edge and label edge

	# Top: pi/2
	label_top.position = Vector2(center.x - label_top.size.x * 0.5, center.y - track_pixel_radius - label_top.size.y - margin)
	# Bottom: -pi/2
	label_bottom.position = Vector2(center.x - label_bottom.size.x * 0.5, center.y + track_pixel_radius + margin)
	# Left: pi
	label_left.position = Vector2(center.x - track_pixel_radius - label_left.size.x - margin, center.y - label_left.size.y * 0.5)
	# Right: 0
	label_right.position = Vector2(center.x + track_pixel_radius + margin, center.y - label_right.size.y * 0.5)

func update_data(f: Vector2) -> void:
	if color_rect and color_rect.material:
		var mat = color_rect.material as ShaderMaterial
		mat.set_shader_parameter("current_f", f)
		mat.set_shader_parameter("color_scheme", Config.color_scheme)
		mat.set_shader_parameter("brightness", Config.terrain_brightness)
		mat.set_shader_parameter("saturation", Config.terrain_saturation)
		mat.set_shader_parameter("albedo", Config.terrain_albedo)
		mat.set_shader_parameter("emission", Config.terrain_emission)

	if angle_label:
		var angle_rad = atan2(f.y, f.x)
		var angle_deg = rad_to_deg(angle_rad)
		if angle_deg < 0:
			angle_deg += 360.0

		# Update text
		angle_label.text = "%.1f°" % angle_deg

		# Compute matching color
		var hue = (angle_rad + PI) / (2.0 * PI)
		if Config.color_scheme == 1:
			hue = wrapf(hue + 0.5, 0.0, 1.0)

		var saturation = clamp(Config.terrain_saturation, 0.3, 1.0)
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

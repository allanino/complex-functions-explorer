extends AspectRatioContainer

@onready var map_rect = %MapRect
@onready var fov_overlay = %FOVOverlay

@onready var player: Node3D = get_tree().get_first_node_in_group("player")
@onready var camera: Camera3D = player.get_node("Camera3D") if player else null
var view_radius: float = 80.0

# Tracking state for optimization
var _last_camera_yaw: float = 999.0
var _last_fov_size: Vector2 = Vector2.ZERO

# Range Labels
var range_labels_overlay: Control
var top_label: Label
var bottom_label: Label
var left_label: Label
var right_label: Label


func _ready():
	_setup_range_labels()
	fov_overlay.draw.connect(_on_fov_overlay_draw)

	resized.connect(_on_resized)
	Config.config_changed.connect(_on_config_changed)
	GameState.state_changed.connect(_on_state_changed)
	_sync_all_uniforms()
	# Performance: Only calculate camera FOV overlay in _process when Minimap is visible
	set_process(is_visible_in_tree())

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		# Performance: Dynamically disable/enable _process to save CPU cycles when hidden
		set_process(is_visible_in_tree())

func _on_resized():
	if custom_minimum_size.y != size.x:
		custom_minimum_size.y = size.x


func _setup_range_labels():
	range_labels_overlay = Control.new()
	range_labels_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	range_labels_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(range_labels_overlay)

	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.028, 0.045, 0.09, 0.6)
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5

	var left_right_style = stylebox.duplicate() as StyleBoxFlat
	left_right_style.border_width_left = 1
	left_right_style.border_width_top = 1
	left_right_style.border_width_right = 1
	left_right_style.border_width_bottom = 1
	left_right_style.border_color = Color(ThemeColors.real, 0.4)

	var top_bottom_style = stylebox.duplicate() as StyleBoxFlat
	top_bottom_style.border_width_left = 1
	top_bottom_style.border_width_top = 1
	top_bottom_style.border_width_right = 1
	top_bottom_style.border_width_bottom = 1
	top_bottom_style.border_color = Color(ThemeColors.imaginary, 0.4)

	var font = ThemeDB.fallback_font
	if ThemeColors.theme and ThemeColors.theme.has_font("font", "Label"):
		font = ThemeColors.theme.get_font("font", "Label")

	var create_label = func(sbox: StyleBoxFlat, t_color: Color) -> Label:
		var lbl = Label.new()
		lbl.add_theme_stylebox_override("normal", sbox)
		lbl.add_theme_color_override("font_color", t_color)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_font_override("font", font)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		range_labels_overlay.add_child(lbl)
		return lbl

	top_label = create_label.call(top_bottom_style, ThemeColors.imaginary)
	bottom_label = create_label.call(top_bottom_style, ThemeColors.imaginary)
	left_label = create_label.call(left_right_style, ThemeColors.real)
	right_label = create_label.call(left_right_style, ThemeColors.real)

	top_label.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	top_label.position.y += 8

	bottom_label.set_anchors_and_offsets_preset(PRESET_CENTER_BOTTOM)
	bottom_label.position.y -= 8

	left_label.set_anchors_and_offsets_preset(PRESET_CENTER_LEFT)
	left_label.position.x += 8

	right_label.set_anchors_and_offsets_preset(PRESET_CENTER_RIGHT)
	right_label.position.x -= 8

func _format_coordinate(val: float) -> String:
	var abs_val = abs(val)
	if abs_val >= 1e4 or (abs_val > 0.0 and abs_val < 1e-3):
		var exp_val = int(floor(log(abs_val) / log(10.0)))
		var mantissa = val / pow(10.0, float(exp_val))
		return "%.1f" % mantissa + "e" + ("+" if exp_val >= 0 else "") + str(exp_val)
	return "%.1f" % val

func _sync_all_uniforms():
	if map_rect.material:
		var mat = map_rect.material as ShaderMaterial
		mat.set_shader_parameter("view_radius", view_radius)
		mat.set_shader_parameter("iterations", Config.iterations)
		mat.set_shader_parameter("zoom_factor", GameState.effective_zoom)
		mat.set_shader_parameter("function_type", Config.function_type)
		mat.set_shader_parameter("input_function_type", Config.input_function_type)
		mat.set_shader_parameter("color_scheme", Config.color_scheme)
		mat.set_shader_parameter("is_dirichlet", Config.function.get("is_dirichlet", false))
		mat.set_shader_parameter("is_multivalued", Config.function.get("is_multivalued", false))
		mat.set_shader_parameter("rational_num_coeffs", Config.rational_num_coeffs)
		mat.set_shader_parameter("rational_den_coeffs", Config.rational_den_coeffs)
		mat.set_shader_parameter("input_rational_num_coeffs", Config.input_rational_num_coeffs)
		mat.set_shader_parameter("input_rational_den_coeffs", Config.input_rational_den_coeffs)
		mat.set_shader_parameter("multivalued_n", Config.multivalued_n)
		mat.set_shader_parameter("current_branch", GameState.current_branch)
		mat.set_shader_parameter("show_curves", Config.show_curves)
		mat.set_shader_parameter("show_critical_stripe", Config.show_critical_stripe)
		mat.set_shader_parameter("eta_patch_count", min(64, ComplexField.eta_patches.size()))
		mat.set_shader_parameter("eta_patch_centers", ComplexField.get_shader_patch_centers())
		mat.set_shader_parameter("eta_patch_coeffs", ComplexField.get_shader_patch_coeffs())
		mat.set_shader_parameter("morph", GameState.morph_value)
		mat.set_shader_parameter("morph_style", Config.morph_style)
		mat.set_shader_parameter("height_type", Config.height_type)
		mat.set_shader_parameter("height_a", Config.height_a)
		mat.set_shader_parameter("height_epsilon", Config.height_epsilon)
		mat.set_shader_parameter("height_theta", Config.height_theta)

		mat.set_shader_parameter("max_world_height", GameState.MAX_WORLD_HEIGHT)

		_update_zeros_shader()

		var real_shaded = GameState.get_padded_level_curves(GameState.real_level_curves_highlighted)
		mat.set_shader_parameter("real_level_curves_highlighted", real_shaded)

		var imag_shaded = GameState.get_padded_level_curves(GameState.imag_level_curves_highlighted)
		mat.set_shader_parameter("imag_level_curves_highlighted", imag_shaded)

		var newton_path_size = GameState.newton_path.size()
		var newton_path = GameState.get_padded_newton_path()

		mat.set_shader_parameter("newton_path_size", newton_path_size)
		mat.set_shader_parameter("newton_path", newton_path)
		mat.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)


func _update_zeros_shader():
	if not map_rect.material: return
	var mat = map_rect.material as ShaderMaterial
	mat.set_shader_parameter("show_hud_zeros", Config.show_hud_zeros)
	if Config.show_hud_zeros:
		var visited = PackedVector2Array(GameState.visited_zeros)
		var v_size = min(visited.size(), 10)
		var shader_accented_index = GameState.accented_zero_index
		if visited.size() > 10:
			shader_accented_index = GameState.accented_zero_index - (visited.size() - 10)

		while visited.size() < 10:
			visited.append(Vector2.ZERO)

		if visited.size() > 10:
			visited = visited.slice(-10)

		mat.set_shader_parameter("visited_zeros_size", v_size)
		mat.set_shader_parameter("visited_zeros", visited)
		mat.set_shader_parameter("accented_zero_index", shader_accented_index)

func _on_config_changed(key: String):
	var mat = map_rect.material as ShaderMaterial
	if not mat: return
	if key == "show_hud_zeros":
		_update_zeros_shader()
	elif key in ["iterations", "zoom_factor", "function_type", "input_function_type", "color_scheme", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "show_curves", "show_critical_stripe", "height_type", "height_a", "height_epsilon", "height_theta", "morph_style"]:
		_sync_all_uniforms()

func _on_state_changed(key: String):
	var mat = map_rect.material as ShaderMaterial
	if not mat: return
	if key == "current_branch" or key == "effective_zoom" or key == "morph_value":
		mat.set_shader_parameter("current_branch", GameState.current_branch)
		mat.set_shader_parameter("show_curves", Config.show_curves)
		mat.set_shader_parameter("show_critical_stripe", Config.show_critical_stripe)
		mat.set_shader_parameter("morph", GameState.morph_value)
		mat.set_shader_parameter("morph_style", Config.morph_style)
		if key == "effective_zoom":
			mat.set_shader_parameter("zoom_factor", GameState.effective_zoom)

	if key == "eta_patches":
		mat.set_shader_parameter("eta_patch_count", min(64, ComplexField.eta_patches.size()))
		mat.set_shader_parameter("eta_patch_centers", ComplexField.get_shader_patch_centers())
		mat.set_shader_parameter("eta_patch_coeffs", ComplexField.get_shader_patch_coeffs())

	if key == "real_level_curves_highlighted":
		var real_shaded = GameState.get_padded_level_curves(GameState.real_level_curves_highlighted)
		mat.set_shader_parameter("real_level_curves_highlighted", real_shaded)

	if key == "imag_level_curves_highlighted":
		var imag_shaded = GameState.get_padded_level_curves(GameState.imag_level_curves_highlighted)
		mat.set_shader_parameter("imag_level_curves_highlighted", imag_shaded)

	if key == "newton_path_bbox":
		mat.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)

	if key == "visited_zeros" or key == "accented_zero_index":
		_update_zeros_shader()

	if key == "newton_path":
		if GameState.newton_path.size() > 0:
			var newton_path_size = GameState.newton_path.size()
			var newton_path = GameState.get_padded_newton_path()

			mat.set_shader_parameter("newton_path_size", newton_path_size)
			mat.set_shader_parameter("newton_path", newton_path)
			mat.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)
		else:
			mat.set_shader_parameter("newton_path_size", 0)


func _process(_delta):
	if not player or not camera:
		return

	var mat = map_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("player_pos_world", Vector2(player.global_position.x, player.global_position.z))

	# Only redraw FOV overlay if camera yaw or overlay size changed
	var current_yaw = camera.global_rotation.y
	var current_size = fov_overlay.size

	if Config.show_minimap_range:
		if not range_labels_overlay.visible:
			range_labels_overlay.visible = true

		top_label.text = _format_coordinate(Config.world_to_complex(0.0, player.global_position.z - view_radius).y)
		bottom_label.text = _format_coordinate(Config.world_to_complex(0.0, player.global_position.z + view_radius).y)
		left_label.text = _format_coordinate(Config.world_to_complex(player.global_position.x - view_radius, 0.0).x)
		right_label.text = _format_coordinate(Config.world_to_complex(player.global_position.x + view_radius, 0.0).x)

		# Anchor offsets update automatically since we set PRESET on creation,
		# but if text size changes drastically we might need to queue_sort/force layout.
		# Instead of re-setting preset every frame, rely on Godot Control layout engine.
		# We'll just reset positions after text update to ensure they stay pinned.
		top_label.position.y = 8
		bottom_label.position.y = range_labels_overlay.size.y - bottom_label.size.y - 8
		left_label.position.x = 8
		right_label.position.x = range_labels_overlay.size.x - right_label.size.x - 8
	else:
		if range_labels_overlay.visible:
			range_labels_overlay.visible = false

	if abs(current_yaw - _last_camera_yaw) > 0.001 or current_size != _last_fov_size:
		_last_camera_yaw = current_yaw
		_last_fov_size = current_size
		fov_overlay.queue_redraw()

func _on_fov_overlay_draw():
	if not player or not camera: return

	var center = fov_overlay.size / 2.0
	var r = min(center.x, center.y) * 0.8

	# Draw player indicator: white core with black outline of same scale as zero marker
	var r_core_px = 0.018 * fov_overlay.size.x
	var border_px = 0.009 * fov_overlay.size.x
	fov_overlay.draw_circle(center, r_core_px + border_px, Color(0.2, 0.2, 0.2, 0.8), true, -1.0, true)
	fov_overlay.draw_circle(center, r_core_px, Color(1, 1, 1, 1.0), true, -1.0, true)

	var yaw = camera.global_rotation.y
	var fov_rad = deg_to_rad(camera.fov)

	var forward = Vector2(-sin(yaw), -cos(yaw))

	var left_angle = atan2(forward.y, forward.x) - fov_rad / 2.0
	var right_angle = atan2(forward.y, forward.x) + fov_rad / 2.0

	var p1 = center + Vector2(cos(left_angle), sin(left_angle)) * r
	var p2 = center + Vector2(cos(right_angle), sin(right_angle)) * r

	var points = PackedVector2Array([center, p1, p2])
	var colors = PackedColorArray([Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])

	fov_overlay.draw_polygon(points, colors)
	fov_overlay.draw_line(center, p1, Color(1, 1, 1, 0.5), 1.0, true)
	fov_overlay.draw_line(center, p2, Color(1, 1, 1, 0.5), 1.0, true)

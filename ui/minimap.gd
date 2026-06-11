extends AspectRatioContainer

@onready var map_rect = %MapRect
@onready var fov_overlay = %FOVOverlay

var player: Node3D = null
var camera: Camera3D = null
var view_radius: float = 80.0

# Tracking state for optimization
var _last_camera_yaw: float = 999.0
var _last_fov_size: Vector2 = Vector2.ZERO

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node_or_null("Camera3D")

	fov_overlay.draw.connect(_on_fov_overlay_draw)

	resized.connect(_on_resized)
	Config.config_changed.connect(_on_config_changed)
	GameState.state_changed.connect(_on_state_changed)
	_sync_all_uniforms()

func _on_resized():
	if custom_minimum_size.y != size.x:
		custom_minimum_size.y = size.x

func _sync_all_uniforms():
	if map_rect and map_rect.material:
		var mat = map_rect.material as ShaderMaterial
		mat.set_shader_parameter("view_radius", view_radius)
		mat.set_shader_parameter("iterations", Config.iterations)
		mat.set_shader_parameter("zoom_factor", GameState.effective_zoom)
		mat.set_shader_parameter("function_type", Config.function_type)
		mat.set_shader_parameter("input_function_type", Config.input_function_type)
		mat.set_shader_parameter("color_scheme", Config.color_scheme)
		mat.set_shader_parameter("is_dirichlect", Config.function.get("is_dirichlect", false))
		mat.set_shader_parameter("is_multivalued", Config.function.get("is_multivalued", false))
		mat.set_shader_parameter("rational_num_coeffs", Config.rational_num_coeffs)
		mat.set_shader_parameter("rational_den_coeffs", Config.rational_den_coeffs)
		mat.set_shader_parameter("input_rational_num_coeffs", Config.input_rational_num_coeffs)
		mat.set_shader_parameter("input_rational_den_coeffs", Config.input_rational_den_coeffs)
		mat.set_shader_parameter("multivalued_n", Config.multivalued_n)
		mat.set_shader_parameter("current_branch", GameState.current_branch)
		mat.set_shader_parameter("show_curves", Config.show_curves)
		mat.set_shader_parameter("show_critical_stripe", Config.show_critical_stripe)

		mat.set_shader_parameter("morph", GameState.morph_value)
		mat.set_shader_parameter("height_type", Config.height_type)
		mat.set_shader_parameter("height_a", Config.height_a)
		mat.set_shader_parameter("height_epsilon", Config.height_epsilon)
		mat.set_shader_parameter("height_theta", Config.height_theta)

		var PlayerController = load("res://player/player_controller.gd")
		mat.set_shader_parameter("max_world_height", PlayerController.MAX_WORLD_HEIGHT)

		_update_zeros_shader()

		var real_shaded = PackedFloat32Array()
		for val in GameState.real_level_curves_highlighted:
			real_shaded.append(val)
		while real_shaded.size() < 10:
			real_shaded.append(99999.0)
		mat.set_shader_parameter("real_level_curves_highlighted", real_shaded)

		var imag_shaded = PackedFloat32Array()
		for val in GameState.imag_level_curves_highlighted:
			imag_shaded.append(val)
		while imag_shaded.size() < 10:
			imag_shaded.append(99999.0)
		mat.set_shader_parameter("imag_level_curves_highlighted", imag_shaded)

		var newton_path = PackedVector2Array()
		if GameState.newton_path.size() > 0:
			for val in GameState.newton_path:
				newton_path.append(val)
		var newton_path_size = newton_path.size()
		while newton_path.size() < 50:
			newton_path.append(Vector2.ZERO)

		mat.set_shader_parameter("newton_path_size", newton_path_size)
		mat.set_shader_parameter("newton_path", newton_path)
		mat.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)


func _update_zeros_shader():
	if not map_rect or not map_rect.material: return
	var mat = map_rect.material as ShaderMaterial
	mat.set_shader_parameter("show_hud_zeros", Config.show_hud_zeros)
	if Config.show_hud_zeros:
		var visited = PackedVector2Array()
		for val in GameState.visited_zeros:
			visited.append(val)
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
	elif key in ["iterations", "zoom_factor", "function_type", "input_function_type", "color_scheme", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "show_curves", "show_critical_stripe", "height_type", "height_a", "height_epsilon", "height_theta"]:
		_sync_all_uniforms()

func _on_state_changed(key: String):
	var mat = map_rect.material as ShaderMaterial
	if not mat: return
	if key == "current_branch" or key == "effective_zoom" or key == "morph_value":
		mat.set_shader_parameter("current_branch", GameState.current_branch)
		mat.set_shader_parameter("show_curves", Config.show_curves)
		mat.set_shader_parameter("show_critical_stripe", Config.show_critical_stripe)
		mat.set_shader_parameter("morph", GameState.morph_value)
		if key == "effective_zoom":
			mat.set_shader_parameter("zoom_factor", GameState.effective_zoom)

	if key == "real_level_curves_highlighted":
		var real_shaded = PackedFloat32Array()
		for val in GameState.real_level_curves_highlighted:
			real_shaded.append(val)
		while real_shaded.size() < 10:
			real_shaded.append(99999.0)
		mat.set_shader_parameter("real_level_curves_highlighted", real_shaded)

	if key == "imag_level_curves_highlighted":
		var imag_shaded = PackedFloat32Array()
		for val in GameState.imag_level_curves_highlighted:
			imag_shaded.append(val)
		while imag_shaded.size() < 10:
			imag_shaded.append(99999.0)
		mat.set_shader_parameter("imag_level_curves_highlighted", imag_shaded)

	if key == "newton_path_bbox":
		mat.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)

	if key == "visited_zeros" or key == "accented_zero_index":
		_update_zeros_shader()

	if key == "newton_path":
		if GameState.newton_path.size() > 0:
			var newton_path = PackedVector2Array()
			for val in GameState.newton_path:
				newton_path.append(val)
			var newton_path_size = newton_path.size()
			while newton_path.size() < 50:
				newton_path.append(Vector2.ZERO)

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

extends Node3D

@export var terrain_chunk_scene: PackedScene = preload("res://terrain/terrain_chunk.tscn")
@export var terrain_material: ShaderMaterial
@export var player: Node3D
@export var chunk_size: float = 16.0

var chunks = {}
var chunk_leeway = 0.01
var LOD_SUBS = [] # This will be set in code
var _lod_mesh_cache = {}
var _last_player_chunk = Vector2i(9999, 9999)
var slow_frame_counter: int = 0
var _shaders_stopped: bool = false

@onready var environment_node = get_node("../Environment")
@onready var audio = get_node_or_null("../Audio")

func _ready():
	Config.config_changed.connect(_on_config_changed)
	GameState.state_changed.connect(_on_state_changed)
	_update_lod_subs()
	_update_all_terrain_material_uniforms()
	# Uncomment this to debug the mesh wireframe
	# get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME


func _process(delta):
	if not player:
		return

	# --- PERFORMANCE GUARD ---
	var frame_time_ms = delta * 1000.0
	if frame_time_ms > 100.0:
		slow_frame_counter += 1
		if slow_frame_counter >= 5:
			GameState.performance_protection_active = true
	else:
		slow_frame_counter = 0

	if GameState.performance_protection_active:
		if not _shaders_stopped:
			_apply_performance_protection(true)
		return

	if _shaders_stopped:
		_apply_performance_protection(false)

	var player_pos = player.global_position
	var player_chunk_x = floor(player_pos.x / chunk_size)
	var player_chunk_z = floor(player_pos.z / chunk_size)

	if terrain_material:
		terrain_material.set_shader_parameter("player_position_world", player_pos)


	# Chunk and LOD Dynamic Update
	if player_chunk_x != _last_player_chunk.x or player_chunk_z != _last_player_chunk.y:
		_update_chunks(player_chunk_x, player_chunk_z)


func _update_chunks(p_x: int, p_z: int):
	var old_min_x = _last_player_chunk.x - Config.view_distance
	var old_max_x = _last_player_chunk.x + Config.view_distance
	var old_min_z = _last_player_chunk.y - Config.view_distance
	var old_max_z = _last_player_chunk.y + Config.view_distance

	var is_first_update = chunks.is_empty()

	_last_player_chunk = Vector2i(p_x, p_z)

	# Load new chunks
	for x in range(p_x - Config.view_distance, p_x + Config.view_distance + 1):
		for z in range(p_z - Config.view_distance, p_z + Config.view_distance + 1):
			# Optimization: skip chunks that were already within the previous view distance bounds.
			# This drastically reduces redundant dictionary lookups when the player moves by a small amount.
			if not is_first_update and x >= old_min_x and x <= old_max_x and z >= old_min_z and z <= old_max_z:
				continue

			var chunk_coord = Vector2i(x, z)
			if not chunks.has(chunk_coord):
				_load_chunk(chunk_coord)

	# Unload distant chunks
	var chunks_to_remove = []
	for chunk_coord in chunks.keys():
		if abs(chunk_coord.x - p_x) > Config.view_distance or abs(chunk_coord.y - p_z) > Config.view_distance:
			chunks_to_remove.append(chunk_coord)

	for chunk_coord in chunks_to_remove:
		_unload_chunk(chunk_coord)

	_update_all_chunks_lod()

func _update_all_chunks_lod(force: bool = false):
	var player_chunk_coord = _last_player_chunk
	for coord in chunks.keys():
		var chunk = chunks[coord]
		var desired_lod = _get_lod_level(coord, player_chunk_coord)
		if force or chunk.get_meta("lod_level", -1) != desired_lod:
			_update_chunk_lod(chunk, desired_lod, coord)

func _update_lod_subs():
	match Config.terrain_detail:
		0: # High
			LOD_SUBS = [255, 255, 127, 127, 127, 63, 31]
		1: # Medium
			LOD_SUBS = [127, 63, 31, 15, 7, 3, 1]
		2: # Low
			LOD_SUBS = [63, 31, 15, 7, 3, 1, 1]

func _get_lod_level(coord: Vector2i, player_coord: Vector2i) -> int:
	var dx = abs(coord.x - player_coord.x)
	var dz = abs(coord.y - player_coord.y)
	var dist = max(dx, dz)

	if dist <= 2:
		return 0
	elif dist <= 4:
		return 1
	elif dist <= 8:
		return 2
	elif dist <= 16:
		return 3
	elif dist <= 24:
		return 4
	elif dist <= 48:
		return 5
	else:
		return 6

func _create_lod_mesh(size: float, subdivisions: int) -> Mesh:
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	return plane

func _apply_performance_protection(active: bool):
	_shaders_stopped = active
	for chunk in chunks.values():
		chunk.visible = !active

	if terrain_material:
		terrain_material.set_shader_parameter("performance_protection_active", active)

	if environment_node and environment_node.has_method("set_performance_protection"):
		environment_node.set_performance_protection(active)

	if audio and audio.has_method("set_performance_protection"):
		audio.set_performance_protection(active)

func _update_all_terrain_material_uniforms():
	var init_keys = [
		"function_type",
		"iterations", "show_curves", "show_critical_stripe", "show_flow",
		"show_position_marker", "color_scheme", "input_function_type",
		"height_type", "height_a", "height_epsilon", "height_theta",
		"zoom_factor", "rational_num_coeffs", "rational_den_coeffs",
		"input_rational_num_coeffs", "input_rational_den_coeffs",
		"multivalued_n", "self_illumination", "fog_density",
		"terrain_brightness", "terrain_saturation", "terrain_albedo",
		"terrain_emission", "terrain_metallic", "terrain_roughness",
		"terrain_surface_texture",
		"performance_protection_active", "current_branch", "morph_value",
		"real_level_curves_highlighted", "imag_level_curves_highlighted",
		"newton_path"
	]
	for k in init_keys:
		_update_terrain_material_uniforms(k)

	terrain_material.set_shader_parameter("chunk_size", chunk_size)
	var segments = []
	for sub in LOD_SUBS:
		segments.append(float(sub + 1))
	terrain_material.set_shader_parameter("lod_segments", segments)


func _update_terrain_material_uniforms(key: String):
	if not terrain_material:
		return

	if key == "function_type":
		var f_data = Config.function
		terrain_material.set_shader_parameter("function_type", Config.function_type)
		terrain_material.set_shader_parameter("is_dirichlect", f_data.get("is_dirichlect", false))
		terrain_material.set_shader_parameter("is_multivalued", f_data.get("is_multivalued", false))
		return

	if key == "real_level_curves_highlighted":
		var real_shaded = PackedFloat32Array()
		for val in GameState.real_level_curves_highlighted:
			real_shaded.append(val)
		while real_shaded.size() < 10:
			real_shaded.append(99999.0)
		terrain_material.set_shader_parameter("real_level_curves_highlighted", real_shaded)
		return

	if key == "imag_level_curves_highlighted":
		var imag_shaded = PackedFloat32Array()
		for val in GameState.imag_level_curves_highlighted:
			imag_shaded.append(val)
		while imag_shaded.size() < 10:
			imag_shaded.append(99999.0)
		terrain_material.set_shader_parameter("imag_level_curves_highlighted", imag_shaded)
		return


	if key == "newton_path_bbox":
		terrain_material.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)
		return

	if key == "newton_path":
		if GameState.newton_path.size() > 0:
			var newton_path = PackedVector2Array()
			for val in GameState.newton_path:
				newton_path.append(val)
			var newton_path_size = newton_path.size()
			while newton_path.size() < 50:
				newton_path.append(Vector2.ZERO)

			terrain_material.set_shader_parameter("newton_path_size", newton_path_size)
			terrain_material.set_shader_parameter("newton_path", newton_path)
			terrain_material.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)
		else:
			terrain_material.set_shader_parameter("newton_path_size", 0)
		return

	var mapped_key = key
	if key.begins_with("terrain_"):
		mapped_key = key.replace("terrain_", "")
	if mapped_key in ["iterations", "show_curves", "show_critical_stripe", "show_flow", "show_position_marker", "color_scheme", "input_function_type", "height_type", "height_a", "height_epsilon", "height_theta", "zoom_factor", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "self_illumination", "fog_density", "brightness", "saturation", "albedo", "emission", "metallic", "roughness", "surface_texture"]:
		terrain_material.set_shader_parameter(mapped_key, Config.get(key))
		return
	if key in ["performance_protection_active", "current_branch", "morph_value", "effective_zoom"]:
		var param_name = key
		if key == "effective_zoom":
			param_name = "zoom_factor"
		terrain_material.set_shader_parameter(param_name, GameState.get(key))
		if key == "morph_value":
			terrain_material.set_shader_parameter("morph", GameState.get(key))
		return


func _update_chunk_uniforms(chunk: MeshInstance3D):
	var lod = chunk.get_meta("lod_level", 0)
	chunk.set_instance_shader_parameter("lod_level", lod)

func _update_neighbor_lods(coord: Vector2i):
	_update_neighbor_lod_uniforms(coord)
	_update_neighbor_lod_uniforms(Vector2i(coord.x - 1, coord.y))
	_update_neighbor_lod_uniforms(Vector2i(coord.x + 1, coord.y))
	_update_neighbor_lod_uniforms(Vector2i(coord.x, coord.y - 1))
	_update_neighbor_lod_uniforms(Vector2i(coord.x, coord.y + 1))

func _update_neighbor_lod_uniforms(coord: Vector2i):
	var chunk = chunks.get(coord)
	if not chunk: return

	var lod = chunk.get_meta("lod_level", 0)

	var left_lod = chunks[Vector2i(coord.x - 1, coord.y)].get_meta("lod_level", lod) if chunks.has(Vector2i(coord.x - 1, coord.y)) else lod
	var right_lod = chunks[Vector2i(coord.x + 1, coord.y)].get_meta("lod_level", lod) if chunks.has(Vector2i(coord.x + 1, coord.y)) else lod
	var top_lod = chunks[Vector2i(coord.x, coord.y - 1)].get_meta("lod_level", lod) if chunks.has(Vector2i(coord.x, coord.y - 1)) else lod
	var bottom_lod = chunks[Vector2i(coord.x, coord.y + 1)].get_meta("lod_level", lod) if chunks.has(Vector2i(coord.x, coord.y + 1)) else lod

	chunk.set_instance_shader_parameter("neighbor_lod_left", left_lod)
	chunk.set_instance_shader_parameter("neighbor_lod_right", right_lod)
	chunk.set_instance_shader_parameter("neighbor_lod_top", top_lod)
	chunk.set_instance_shader_parameter("neighbor_lod_bottom", bottom_lod)

func _load_chunk(coord: Vector2i):
	var chunk = terrain_chunk_scene.instantiate()
	add_child(chunk)
	chunk.visible = !GameState.performance_protection_active

	chunk.material_override = terrain_material

	var player_pos = player.global_position
	var player_chunk_coord = Vector2i(floor(player_pos.x / chunk_size), floor(player_pos.z / chunk_size))
	var lod = _get_lod_level(coord, player_chunk_coord)

	chunks[coord] = chunk
	_update_chunk_lod(chunk, lod, coord)

	chunk.global_position = Vector3(
		coord.x * chunk_size + chunk_size * 0.5,
		0,
		coord.y * chunk_size + chunk_size * 0.5
	)

	chunk.custom_aabb = AABB(
		Vector3(- (chunk_size + chunk_leeway) * 0.5, -50, - (chunk_size + chunk_leeway) * 0.5),
		Vector3(chunk_size + chunk_leeway, 1400, chunk_size + chunk_leeway)
	)

func _update_chunk_lod(chunk: MeshInstance3D, lod: int, coord: Vector2i):
	var subdivisions = LOD_SUBS[lod]

	if not _lod_mesh_cache.has(subdivisions):
		_lod_mesh_cache[subdivisions] = _create_lod_mesh(chunk_size + chunk_leeway, subdivisions)

	chunk.mesh = _lod_mesh_cache[subdivisions]
	chunk.set_meta("lod_level", lod)

	if Config.shadows_enabled:
		if lod >= 3:
			chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	_update_chunk_uniforms(chunk)

	_update_neighbor_lods(coord)

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)
	_update_neighbor_lods(coord)

func _on_config_changed(key: String):
	if key in ["iterations", "terrain_detail", "view_distance", "show_curves", "show_critical_stripe", "show_flow", "show_position_marker", "color_scheme", "function_type", "height_type", "height_a", "height_epsilon", "height_theta", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "self_illumination", "terrain_brightness", "terrain_saturation", "terrain_albedo", "terrain_emission", "terrain_metallic", "terrain_roughness", "terrain_surface_texture", "morph_value", "fog_density"]:
		_update_terrain_material_uniforms(key)
		if key == "terrain_detail":
			_update_lod_subs()
			_lod_mesh_cache.clear()
			_update_all_chunks_lod(true)
		if key == "view_distance" or key == "terrain_detail" or key == "function_type":
			if player:
				_update_chunks(floor(player.global_position.x / chunk_size), floor(player.global_position.z / chunk_size))

func _on_state_changed(key: String):
	if key in ["current_branch", "morph_value", "newton_path", "newton_path_bbox", "real_level_curves_highlighted", "imag_level_curves_highlighted", "effective_zoom"]:
		_update_terrain_material_uniforms(key)

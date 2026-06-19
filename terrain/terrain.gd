extends Node3D

@export var terrain_chunk_scene: PackedScene = preload("res://terrain/terrain_chunk.tscn")
@export var terrain_material: ShaderMaterial
@export var player: Node3D
@export var chunk_size: float = 16.0

var chunks = {}
var _chunk_lods = {}
var _dirty_neighbor_coords = {}
var chunk_leeway = 0.01
var LOD_SUBS = [] # This will be set in code
var _lod_mesh_cache = {}
var _last_player_chunk = Vector2i(9999, 9999)
var _last_view_distance: int = -1
var slow_frame_counter: int = 0
var _shaders_stopped: bool = false
var _last_lod_player_chunk = Vector2i(9999, 9999)
var _lod_speed_bias: float = 1.0
var _last_applied_speed_bias: float = 1.0


# Work queues for spreading the load across multiple frames
var _chunks_to_load: Array[Vector2i] = []
var _queued_chunks_to_load = {}
var _chunks_to_unload: Array[Vector2i] = []
var _queued_chunks_to_unload = {}
var _lod_updates_pending: Array[Vector2i] = []
var _queued_lod_updates = {}
var _loaded_chunk_list: Array[Vector2i] = []
var _lod_check_index: int = 0
var _sorted_view_offsets: Array[Vector2i] = []

const FRAME_TIME_BUDGET_MS = 4.0

@onready var environment_node = get_node("../Environment")
@onready var audio = get_node_or_null("../Audio")

func _ready():
	Config.config_changed.connect(_on_config_changed)
	GameState.state_changed.connect(_on_state_changed)
	_update_lod_subs()
	_update_view_offsets()
	_update_all_terrain_material_uniforms()
	# Uncomment this to debug the mesh wireframe
	# get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

func _update_view_offsets():
	_sorted_view_offsets.clear()
	var d = Config.view_distance
	for x in range(-d, d + 1):
		for z in range(-d, d + 1):
			_sorted_view_offsets.append(Vector2i(x, z))
	_sorted_view_offsets.sort_custom(func(a, b):
		return max(abs(a.x), abs(a.y)) < max(abs(b.x), abs(b.y))
	)

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


	var current = Vector2i(player_chunk_x, player_chunk_z)

	# Dynamic LOD bias calculation
	var current_speed = player.velocity.length()
	# Scale relative to a baseline reference speed of 10.0
	var target_bias = 1.0 + clamp((current_speed - 10.0) / 15.0, 0.0, 4.0)
	_lod_speed_bias = lerp(_lod_speed_bias, target_bias, delta * 2.0)

	# If bias has shifted significantly, force an update scan of LOD transitions
	if abs(_lod_speed_bias - _last_applied_speed_bias) > 0.2:
		_update_all_chunks_lod(true)
		_last_applied_speed_bias = _lod_speed_bias

	if current != _last_lod_player_chunk:
		_update_all_chunks_lod()
		_last_lod_player_chunk = current


	_process_work_queues()


func _update_chunks(p_x: int, p_z: int, force: bool = false):
	var old_p = _last_player_chunk
	var new_p = Vector2i(p_x, p_z)

	var is_first_update = chunks.is_empty()
	var view_distance_changed = _last_view_distance != -1 and _last_view_distance != Config.view_distance

	_last_player_chunk = new_p
	_last_view_distance = Config.view_distance

	if force or is_first_update or view_distance_changed or old_p == Vector2i(9999, 9999) or max(abs(new_p.x - old_p.x), abs(new_p.y - old_p.y)) > 2:
		_chunks_to_load.clear()
		_queued_chunks_to_load.clear()
		_chunks_to_unload.clear()
		_queued_chunks_to_unload.clear()
		_lod_updates_pending.clear()
		_queued_lod_updates.clear()

		# Load all immediate
		for offset in _sorted_view_offsets:
			var chunk_coord = Vector2i(p_x + offset.x, p_z + offset.y)
			if not chunks.has(chunk_coord):
				_load_chunk(chunk_coord)

		# Unload all immediate
		var chunks_to_remove = []
		for chunk_coord in chunks:
			if abs(chunk_coord.x - p_x) > Config.view_distance or abs(chunk_coord.y - p_z) > Config.view_distance:
				chunks_to_remove.append(chunk_coord)
		for chunk_coord in chunks_to_remove:
			_unload_chunk(chunk_coord)

		_flush_dirty_neighbors()
		_update_all_chunks_lod(true)
		return

	# Clean up queued loads that are now out of view distance (O(N) filtering)
	var new_chunks_to_load: Array[Vector2i] = []
	for coord in _chunks_to_load:
		if abs(coord.x - p_x) <= Config.view_distance and abs(coord.y - p_z) <= Config.view_distance:
			new_chunks_to_load.append(coord)
		else:
			_queued_chunks_to_load.erase(coord)
	_chunks_to_load = new_chunks_to_load

	# Incremental/Edge-based update
	var dx = new_p.x - old_p.x
	var dz = new_p.y - old_p.y
	
	var old_min_x = old_p.x - Config.view_distance
	var old_max_x = old_p.x + Config.view_distance
	var old_min_z = old_p.y - Config.view_distance
	var old_max_z = old_p.y + Config.view_distance

	var new_min_x = new_p.x - Config.view_distance
	var new_max_x = new_p.x + Config.view_distance
	var new_min_z = new_p.y - Config.view_distance
	var new_max_z = new_p.y + Config.view_distance

	# 1. New chunks to load
	if dx > 0:
		for x in range(old_max_x + 1, new_max_x + 1):
			for z in range(new_min_z, new_max_z + 1):
				_queue_chunk_load_if_needed(Vector2i(x, z))
	elif dx < 0:
		for x in range(new_min_x, old_min_x):
			for z in range(new_min_z, new_max_z + 1):
				_queue_chunk_load_if_needed(Vector2i(x, z))

	if dz > 0:
		var x_start = new_min_x
		var x_end = new_max_x
		if dx > 0:
			x_end = old_max_x
		elif dx < 0:
			x_start = old_min_x
		for z in range(old_max_z + 1, new_max_z + 1):
			for x in range(x_start, x_end + 1):
				_queue_chunk_load_if_needed(Vector2i(x, z))
	elif dz < 0:
		var x_start = new_min_x
		var x_end = new_max_x
		if dx > 0:
			x_end = old_max_x
		elif dx < 0:
			x_start = old_min_x
		for z in range(new_min_z, old_min_z):
			for x in range(x_start, x_end + 1):
				_queue_chunk_load_if_needed(Vector2i(x, z))

	# 2. Distant chunks to unload
	if dx > 0:
		for x in range(old_min_x, new_min_x):
			for z in range(old_min_z, old_max_z + 1):
				_queue_chunk_unload_if_needed(Vector2i(x, z))
	elif dx < 0:
		for x in range(new_max_x + 1, old_max_x + 1):
			for z in range(old_min_z, old_max_z + 1):
				_queue_chunk_unload_if_needed(Vector2i(x, z))

	if dz > 0:
		var x_start = old_min_x
		var x_end = old_max_x
		if dx > 0:
			x_start = new_min_x
		elif dx < 0:
			x_end = new_max_x
		for z in range(old_min_z, new_min_z):
			for x in range(x_start, x_end + 1):
				_queue_chunk_unload_if_needed(Vector2i(x, z))
	elif dz < 0:
		var x_start = old_min_x
		var x_end = old_max_x
		if dx > 0:
			x_start = new_min_x
		elif dx < 0:
			x_end = new_max_x
		for z in range(new_max_z + 1, old_max_z + 1):
			for x in range(x_start, x_end + 1):
				_queue_chunk_unload_if_needed(Vector2i(x, z))


func _queue_chunk_load_if_needed(coord: Vector2i):
	if not chunks.has(coord) and not _queued_chunks_to_load.has(coord):
		_chunks_to_load.append(coord)
		_queued_chunks_to_load[coord] = true


func _queue_chunk_unload_if_needed(coord: Vector2i):
	if chunks.has(coord) and not _queued_chunks_to_unload.has(coord):
		_chunks_to_unload.append(coord)
		_queued_chunks_to_unload[coord] = true


func _update_all_chunks_lod(force: bool = false):
	var player_chunk_coord = _last_player_chunk
	if force:
		for coord in chunks:
			var chunk = chunks[coord]
			var desired_lod = _get_lod_level(coord, player_chunk_coord)
			_update_chunk_lod(chunk, desired_lod, coord, true)
		_flush_dirty_neighbors()
		return

func _process_work_queues():
	var start_time = Time.get_ticks_usec()
	var budget_usec = int(FRAME_TIME_BUDGET_MS * 1000.0)
	
	# Background LOD scanner (distributed check)
	if not _loaded_chunk_list.is_empty():
		var checks_this_frame = min(30, _loaded_chunk_list.size())
		for k in range(checks_this_frame):
			if _lod_check_index >= _loaded_chunk_list.size():
				_lod_check_index = 0
			var coord = _loaded_chunk_list[_lod_check_index]
			_lod_check_index += 1
			
			var desired_lod = _get_lod_level(coord, _last_player_chunk)
			if _chunk_lods.get(coord, -1) != desired_lod:
				if not _queued_lod_updates.has(coord):
					_lod_updates_pending.append(coord)
					_queued_lod_updates[coord] = true
	
	# Process unloads first (fast, frees memory)
	while not _chunks_to_unload.is_empty():
		var coord = _chunks_to_unload.pop_front()
		_queued_chunks_to_unload.erase(coord)
		if chunks.has(coord):
			_unload_chunk(coord)
		
		if Time.get_ticks_usec() - start_time >= budget_usec:
			_flush_dirty_neighbors()
			return

	# Process loads next (heavy)
	while not _chunks_to_load.is_empty():
		var coord = _chunks_to_load.pop_front()
		_queued_chunks_to_load.erase(coord)
		if not chunks.has(coord):
			_load_chunk(coord)
		
		if Time.get_ticks_usec() - start_time >= budget_usec:
			_flush_dirty_neighbors()
			return

	# Process LOD updates
	var lod_updated_any = false
	while not _lod_updates_pending.is_empty():
		var coord = _lod_updates_pending.pop_front()
		_queued_lod_updates.erase(coord)
		if chunks.has(coord):
			var chunk = chunks[coord]
			var desired_lod = _get_lod_level(coord, _last_player_chunk)
			_update_chunk_lod(chunk, desired_lod, coord)
			lod_updated_any = true
		
		if Time.get_ticks_usec() - start_time >= budget_usec:
			_flush_dirty_neighbors()
			return

	if lod_updated_any or not _dirty_neighbor_coords.is_empty():
		_flush_dirty_neighbors()


func _flush_dirty_neighbors():
	for coord in _dirty_neighbor_coords.keys():
		_update_neighbor_lod_uniforms(coord)
	_dirty_neighbor_coords.clear()

func _update_lod_subs():
	match Config.terrain_detail:
		0: # High
			LOD_SUBS = [255, 255, 127, 127, 127, 63, 31]
		1: # Medium
			LOD_SUBS = [127, 63, 31, 15, 7, 3, 3]
		2: # Low
			LOD_SUBS = [63, 31, 15, 7, 3, 1, 1]

func _get_lod_level(coord: Vector2i, player_coord: Vector2i) -> int:
	var dx = abs(coord.x - player_coord.x)
	var dz = abs(coord.y - player_coord.y)
	var dist = max(dx, dz)

	if dist <= int(round(2.0 * _lod_speed_bias)):
		return 0
	elif dist <= int(round(4.0 * _lod_speed_bias)):
		return 1
	elif dist <= int(round(8.0 * _lod_speed_bias)):
		return 2
	elif dist <= int(round(16.0 * _lod_speed_bias)):
		return 3
	elif dist <= int(round(32.0 * _lod_speed_bias)):
		return 4
	elif dist <= int(round(48.0 * _lod_speed_bias)):
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

	if environment_node.has_method("set_performance_protection"):
		environment_node.set_performance_protection(active)

	if audio.has_method("set_performance_protection"):
		audio.set_performance_protection(active)

func _update_all_terrain_material_uniforms():
	if terrain_material:
		terrain_material.set_shader_parameter("eta_patch_count", min(64, ComplexField.eta_patches.size()))
		terrain_material.set_shader_parameter("eta_patch_centers", ComplexField.get_shader_patch_centers())
		terrain_material.set_shader_parameter("eta_patch_coeffs", ComplexField.get_shader_patch_coeffs())
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
		"terrain_ao", "terrain_rim", "terrain_rim_tint", "morph_style",
		"performance_protection_active", "current_branch", "morph_value",
		"real_level_curves_highlighted", "imag_level_curves_highlighted",
		"newton_path"
	]
	terrain_material.set_shader_parameter("max_world_height", GameState.MAX_WORLD_HEIGHT)
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

	if key in ["function_type", "input_function_type"]:
		var f_data = Config.function
		terrain_material.set_shader_parameter("function_type", Config.function_type)
		terrain_material.set_shader_parameter("input_function_type", Config.input_function_type)
		terrain_material.set_shader_parameter("is_dirichlet", f_data.get("is_dirichlet", false))
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
	if mapped_key in ["iterations", "show_curves", "show_critical_stripe", "show_flow", "show_position_marker", "color_scheme", "height_type", "height_a", "height_epsilon", "height_theta", "zoom_factor", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "self_illumination", "fog_density", "brightness", "saturation", "albedo", "emission", "metallic", "roughness", "ao", "rim", "rim_tint", "morph_style"]:
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


func _update_chunk_uniforms(chunk: MeshInstance3D, coord: Vector2i):
	var lod = _chunk_lods.get(coord, 0)
	chunk.set_instance_shader_parameter("lod_level", lod)


func _update_neighbor_lod_uniforms(coord: Vector2i):
	var chunk = chunks.get(coord)
	if not chunk: return

	var lod = _chunk_lods.get(coord, 0)
	var left_coord = Vector2i(coord.x - 1, coord.y)
	var right_coord = Vector2i(coord.x + 1, coord.y)
	var top_coord = Vector2i(coord.x, coord.y - 1)
	var bottom_coord = Vector2i(coord.x, coord.y + 1)

	var left_lod = _chunk_lods.get(left_coord, lod)
	var right_lod = _chunk_lods.get(right_coord, lod)
	var top_lod = _chunk_lods.get(top_coord, lod)
	var bottom_lod = _chunk_lods.get(bottom_coord, lod)

	chunk.set_instance_shader_parameter("neighbor_lods", Vector4i(left_lod, right_lod, top_lod, bottom_lod))

func _load_chunk(coord: Vector2i):
	var chunk = terrain_chunk_scene.instantiate()
	add_child(chunk)
	chunk.visible = !GameState.performance_protection_active

	chunk.material_override = terrain_material

	var player_pos = player.global_position
	var player_chunk_coord = Vector2i(floor(player_pos.x / chunk_size), floor(player_pos.z / chunk_size))
	var lod = _get_lod_level(coord, player_chunk_coord)

	chunks[coord] = chunk
	_loaded_chunk_list.append(coord)
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

func _update_chunk_lod(chunk: MeshInstance3D, lod: int, coord: Vector2i, force: bool = false):
	var old_lod = _chunk_lods.get(coord, -1)
	if not force and old_lod == lod:
		return

	var subdivisions = LOD_SUBS[lod]

	if not _lod_mesh_cache.has(subdivisions):
		_lod_mesh_cache[subdivisions] = _create_lod_mesh(chunk_size + chunk_leeway, subdivisions)

	chunk.mesh = _lod_mesh_cache[subdivisions]
	_chunk_lods[coord] = lod

	if Config.shadows_enabled:
		if lod >= 3:
			chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	_update_chunk_uniforms(chunk, coord)

	_dirty_neighbor_coords[coord] = true
	_dirty_neighbor_coords[Vector2i(coord.x - 1, coord.y)] = true
	_dirty_neighbor_coords[Vector2i(coord.x + 1, coord.y)] = true
	_dirty_neighbor_coords[Vector2i(coord.x, coord.y - 1)] = true
	_dirty_neighbor_coords[Vector2i(coord.x, coord.y + 1)] = true

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)
	_loaded_chunk_list.erase(coord)
	_chunk_lods.erase(coord)
	_dirty_neighbor_coords[Vector2i(coord.x - 1, coord.y)] = true
	_dirty_neighbor_coords[Vector2i(coord.x + 1, coord.y)] = true
	_dirty_neighbor_coords[Vector2i(coord.x, coord.y - 1)] = true
	_dirty_neighbor_coords[Vector2i(coord.x, coord.y + 1)] = true

func _on_config_changed(key: String):
	if key in ["iterations", "terrain_detail", "view_distance", "show_curves", "show_critical_stripe", "show_flow", "show_position_marker", "color_scheme", "function_type", "input_function_type", "height_type", "height_a", "height_epsilon", "height_theta", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "self_illumination", "terrain_brightness", "terrain_saturation", "terrain_albedo", "terrain_emission", "terrain_metallic", "terrain_roughness", "terrain_ao", "terrain_rim", "terrain_rim_tint", "morph_style", "morph_value", "fog_density", "morph_style"]:
		_update_terrain_material_uniforms(key)
		if key == "terrain_detail":
			_update_lod_subs()
			_lod_mesh_cache.clear()
			_update_all_chunks_lod(true)
		if key in ["view_distance", "terrain_detail", "function_type", "input_function_type"]:
			if key == "view_distance":
				_update_view_offsets()
			if player:
				_update_chunks(floor(player.global_position.x / chunk_size), floor(player.global_position.z / chunk_size), true)

func _on_state_changed(key: String):
	if key in ["current_branch", "morph_value", "newton_path", "newton_path_bbox", "real_level_curves_highlighted", "imag_level_curves_highlighted", "effective_zoom"]:
		_update_terrain_material_uniforms(key)
	elif key == "eta_patches":
		if terrain_material:
			terrain_material.set_shader_parameter("eta_patch_count", min(64, ComplexField.eta_patches.size()))
			terrain_material.set_shader_parameter("eta_patch_centers", ComplexField.get_shader_patch_centers())
			terrain_material.set_shader_parameter("eta_patch_coeffs", ComplexField.get_shader_patch_coeffs())

extends Node3D

@export var terrain_chunk_scene: PackedScene = preload("res://terrain/terrain_chunk.tscn")
@export var terrain_material: ShaderMaterial
@export var player: Node3D
@export var chunk_size: float = 32.0

var chunks = {}
var chunk_leeway = 0.01
var _last_field_state = {}
var LOD_SUBS = [] # This will be set in code
var _lod_mesh_cache = {}
var _last_player_chunk = Vector2i(9999, 9999)
var slow_frame_counter: int = 0
var _shaders_stopped: bool = false

@onready var sky = get_node("../Sky")
@onready var audio = get_node_or_null("../Audio")

func _ready():
	_update_lod_subs()
	_update_terrain_material_uniforms()
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
			Config.performance_protection_active = true
	else:
		slow_frame_counter = 0

	if Config.performance_protection_active:
		if not _shaders_stopped:
			_apply_performance_protection(true)
		return

	if _shaders_stopped:
		_apply_performance_protection(false)

	var player_pos = player.global_position
	var player_chunk_x = floor(player_pos.x / chunk_size)
	var player_chunk_z = floor(player_pos.z / chunk_size)

	if terrain_material:
		terrain_material.set_shader_parameter("zoom_factor", Config.effective_zoom)
		terrain_material.set_shader_parameter("player_position_world", player_pos)

	# Check if any field properties have changed
	var current_field_state = {
		"iterations": Config.iterations,
		"terrain_detail": Config.terrain_detail,
		"view_distance": Config.view_distance,
		"show_curves": Config.show_curves,
		"show_curves_labels": Config.show_curves_labels,
		"show_critical_stripe": Config.show_critical_stripe,
		"show_flow": Config.show_flow,
		"show_position_marker": Config.show_position_marker,
		"color_scheme": Config.color_scheme,
		"function_type": Config.function_type,
		"height_type": Config.height_type,
		"height_a": Config.height_a,
		"height_epsilon": Config.height_epsilon,
		"zoom_factor": Config.zoom_factor,
		"rational_num_coeffs": Config.rational_num_coeffs,
		"rational_den_coeffs": Config.rational_den_coeffs,
		"input_rational_num_coeffs": Config.input_rational_num_coeffs,
		"input_rational_den_coeffs": Config.input_rational_den_coeffs,
		"multivalued_n": Config.multivalued_n,
		"self_illumination": Config.self_illumination,
		"current_branch": Config.current_branch,
		"terrain_brightness": Config.terrain_brightness,
		"terrain_saturation": Config.terrain_saturation,
		"terrain_albedo": Config.terrain_albedo,
		"terrain_emission": Config.terrain_emission,
		"terrain_metallic": Config.terrain_metallic,
		"terrain_roughness": Config.terrain_roughness,
		"terrain_surface_texture": Config.terrain_surface_texture,
		"morph_value": Config.morph_value,
		"fog_density": Config.fog_density,
	}

	var state_changed = current_field_state != _last_field_state
	var view_dist_changed = false

	if state_changed:
		var lod_changed = _last_field_state.get("terrain_detail", -1) != Config.terrain_detail
		view_dist_changed = _last_field_state.get("view_distance", -1) != Config.view_distance
		_last_field_state = current_field_state

		if lod_changed:
			_update_lod_subs()
			_lod_mesh_cache.clear()
			_update_all_chunks_lod(true)

		_update_terrain_material_uniforms()

	# Chunk and LOD Dynamic Update
	if player_chunk_x != _last_player_chunk.x or player_chunk_z != _last_player_chunk.y or view_dist_changed:
		_update_chunks(player_chunk_x, player_chunk_z)


func _update_chunks(p_x: int, p_z: int):
	_last_player_chunk = Vector2i(p_x, p_z)

	# Load new chunks
	for x in range(p_x - Config.view_distance, p_x + Config.view_distance + 1):
		for z in range(p_z - Config.view_distance, p_z + Config.view_distance + 1):
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
			LOD_SUBS = [1023, 511, 255, 127, 63, 31]
		1: # Medium
			LOD_SUBS = [511, 255, 127, 63, 31, 15]
		2: # Low
			LOD_SUBS = [255, 127, 63, 31, 15, 7]
		3: # Lowest
			LOD_SUBS = [127, 63, 31, 15, 7, 3]

func _get_lod_level(coord: Vector2i, player_coord: Vector2i) -> int:
	var dx = abs(coord.x - player_coord.x)
	var dz = abs(coord.y - player_coord.y)
	var dist = max(dx, dz)


	if dist <= 0:
		return 0
	if dist <= 1:
		return 1
	elif dist <= 2:
		return 2
	elif dist <= 4:
		return 3
	elif dist <= 6:
		return 4
	else:
		return 5

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

	if sky and sky.has_method("set_performance_protection"):
		sky.set_performance_protection(active)

	if audio and audio.has_method("set_performance_protection"):
		audio.set_performance_protection(active)

func _update_terrain_material_uniforms():
	if not terrain_material:
		return

	var f_data = Config.function
	terrain_material.set_shader_parameter("performance_protection_active", Config.performance_protection_active)
	terrain_material.set_shader_parameter("is_dirichlect", f_data.get("is_dirichlect", false))
	terrain_material.set_shader_parameter("is_multivalued", f_data.get("is_multivalued", false))
	terrain_material.set_shader_parameter("color_scheme", Config.color_scheme)
	terrain_material.set_shader_parameter("iterations", Config.iterations)
	terrain_material.set_shader_parameter("show_curves", Config.show_curves)
	terrain_material.set_shader_parameter("show_curves_labels", Config.show_curves_labels)
	terrain_material.set_shader_parameter("show_critical_stripe", Config.show_critical_stripe)
	terrain_material.set_shader_parameter("show_flow", Config.show_flow)
	terrain_material.set_shader_parameter("show_position_marker", Config.show_position_marker)
	terrain_material.set_shader_parameter("function_type", Config.function_type)
	terrain_material.set_shader_parameter("input_function_type", Config.input_function_type)
	terrain_material.set_shader_parameter("height_type", Config.height_type)
	terrain_material.set_shader_parameter("height_a", Config.height_a)
	terrain_material.set_shader_parameter("height_epsilon", Config.height_epsilon)
	terrain_material.set_shader_parameter("height_theta", Config.height_theta)
	terrain_material.set_shader_parameter("zoom_factor", Config.effective_zoom)
	terrain_material.set_shader_parameter("rational_num_coeffs", Config.rational_num_coeffs)
	terrain_material.set_shader_parameter("rational_den_coeffs", Config.rational_den_coeffs)
	terrain_material.set_shader_parameter("input_rational_num_coeffs", Config.input_rational_num_coeffs)
	terrain_material.set_shader_parameter("input_rational_den_coeffs", Config.input_rational_den_coeffs)
	terrain_material.set_shader_parameter("multivalued_n", Config.multivalued_n)
	terrain_material.set_shader_parameter("self_illumination", Config.self_illumination)
	terrain_material.set_shader_parameter("fog_density", Config.fog_density)
	terrain_material.set_shader_parameter("brightness", Config.terrain_brightness)
	terrain_material.set_shader_parameter("saturation", Config.terrain_saturation)
	terrain_material.set_shader_parameter("albedo", Config.terrain_albedo)
	terrain_material.set_shader_parameter("emission", Config.terrain_emission)
	terrain_material.set_shader_parameter("metallic", Config.terrain_metallic)
	terrain_material.set_shader_parameter("roughness", Config.terrain_roughness)
	terrain_material.set_shader_parameter("surface_texture", Config.terrain_surface_texture)
	terrain_material.set_shader_parameter("current_branch", Config.current_branch)

	terrain_material.set_shader_parameter("chunk_size", chunk_size)
	var segments = []
	for sub in LOD_SUBS:
		segments.append(float(sub + 1))
	terrain_material.set_shader_parameter("lod_segments", segments)

	var morph_param = Config.morph_value
	terrain_material.set_shader_parameter("morph", morph_param)

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
	chunk.visible = !Config.performance_protection_active

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
		Vector3(-chunk_size * 0.5, -50, -chunk_size * 0.5),
		Vector3(chunk_size, 1000, chunk_size)
	)

func _update_chunk_lod(chunk: MeshInstance3D, lod: int, coord: Vector2i):
	var subdivisions = LOD_SUBS[lod]

	if not _lod_mesh_cache.has(subdivisions):
		_lod_mesh_cache[subdivisions] = _create_lod_mesh(chunk_size + chunk_leeway, subdivisions)

	chunk.mesh = _lod_mesh_cache[subdivisions]
	chunk.set_meta("lod_level", lod)
	_update_chunk_uniforms(chunk)

	_update_neighbor_lods(coord)

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)
	_update_neighbor_lods(coord)

extends Node3D

@export var chunk_scene: PackedScene = preload("res://scenes/chunk.tscn")
@export var player: Node3D
@export var chunk_size: float = 32.0
@export var view_distance: int = 6

var chunks = {}
var _last_field_state = {}
var day_night_cycle_duration = 500.0;

var LOD_SUBS = [256, 128, 64, 32]
var _lod_mesh_cache = {}
var _last_player_chunk = Vector2i(9999, 9999)

# We increase our chunks by this to make junctions more seamless
# To test this, look at the right of zeta, the pole has a junction
# along t = 0.00.
const chunk_leeway = 0.3;

@onready var sun = get_node("../DirectionalLight3D")
@onready var moon = get_node("../MoonLight")
@onready var world_environment = get_node("../WorldEnvironment")

var _golden_hour_transition: float = 0.0
var _day_night_time: float = 0.0
var _sun_color = Color("#fc9500")

func _ready():
	_register_global_shader_parameters()
	_update_lod_subs()
	_update_global_shader_parameters()
	# Uncomment this to debug the mesh wireframe
	# get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

func _register_global_shader_parameters():
	# Field parameters
	RenderingServer.global_shader_parameter_add("iterations", RenderingServer.GLOBAL_VAR_TYPE_INT, 120)
	RenderingServer.global_shader_parameter_add("function_type", RenderingServer.GLOBAL_VAR_TYPE_INT, 0)
	RenderingServer.global_shader_parameter_add("height_type", RenderingServer.GLOBAL_VAR_TYPE_INT, 0)
	RenderingServer.global_shader_parameter_add("height_a", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 3.0)
	RenderingServer.global_shader_parameter_add("height_epsilon", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.0)
	RenderingServer.global_shader_parameter_add("rational_num_mat", RenderingServer.GLOBAL_VAR_TYPE_MAT4, Projection())
	RenderingServer.global_shader_parameter_add("rational_den_mat", RenderingServer.GLOBAL_VAR_TYPE_MAT4, Projection())

	# Terrain specific
	RenderingServer.global_shader_parameter_add("show_curves", RenderingServer.GLOBAL_VAR_TYPE_BOOL, true)
	RenderingServer.global_shader_parameter_add("show_critical_stripe", RenderingServer.GLOBAL_VAR_TYPE_BOOL, true)

	# Sky specific
	RenderingServer.global_shader_parameter_add("golden_hour_factor", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)
	RenderingServer.global_shader_parameter_add("night_factor", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)

	# HUD specific
	RenderingServer.global_shader_parameter_add("current_f", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2.ZERO)
	RenderingServer.global_shader_parameter_add("complex_scale", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 2.0)

func _update_global_shader_parameters():
	RenderingServer.global_shader_parameter_set("iterations", Field.iterations)
	RenderingServer.global_shader_parameter_set("function_type", Field.function_type)
	RenderingServer.global_shader_parameter_set("height_type", Field.height_type)
	RenderingServer.global_shader_parameter_set("height_a", Field.height_a)
	RenderingServer.global_shader_parameter_set("height_epsilon", Field.height_epsilon)
	RenderingServer.global_shader_parameter_set("show_curves", Field.show_curves)
	RenderingServer.global_shader_parameter_set("show_critical_stripe", Field.show_critical_stripe)

	# Pack rational coefficients into mat4
	var num_mat = Projection()
	var den_mat = Projection()

	# Godot 4 Projection is 4x4 matrix, column-major access.
	# num_mat[i / 4] returns a copy of the column Vector4.
	for i in range(10):
		var col_idx = i / 4
		var row_idx = i % 4

		var num_col = num_mat[col_idx]
		num_col[row_idx] = Field.rational_num_coeffs[i]
		num_mat[col_idx] = num_col

		var den_col = den_mat[col_idx]
		den_col[row_idx] = Field.rational_den_coeffs[i]
		den_mat[col_idx] = den_col

	RenderingServer.global_shader_parameter_set("rational_num_mat", num_mat)
	RenderingServer.global_shader_parameter_set("rational_den_mat", den_mat)

func _process(delta):
	if not player:
		return

	var player_pos = player.global_position
	var player_chunk_x = floor(player_pos.x / chunk_size)
	var player_chunk_z = floor(player_pos.z / chunk_size)

	# Load new chunks
	for x in range(player_chunk_x - view_distance, player_chunk_x + view_distance + 1):
		for z in range(player_chunk_z - view_distance, player_chunk_z + view_distance + 1):
			var chunk_coord = Vector2i(x, z)
			if not chunks.has(chunk_coord):
				_load_chunk(chunk_coord)

	# Unload distant chunks
	var chunks_to_remove = []
	for chunk_coord in chunks.keys():
		if abs(chunk_coord.x - player_chunk_x) > view_distance or abs(chunk_coord.y - player_chunk_z) > view_distance:
			chunks_to_remove.append(chunk_coord)

	for chunk_coord in chunks_to_remove:
		_unload_chunk(chunk_coord)

	# Day/Night Cycle vs Manual Golden Hour
	var night_factor = 0.0
	if Field.day_night_cycle:
		_day_night_time += delta
		if _day_night_time >= day_night_cycle_duration:
			_day_night_time -= day_night_cycle_duration

		var progress = _day_night_time / day_night_cycle_duration
		var angle = progress * TAU

		# Rotate in YX plane
		var east_west_dir = Vector3(sin(angle), -cos(angle), 0).normalized()

		var sun_dir = east_west_dir
		var moon_dir = -sun_dir

		var sun_elevation = -sun_dir.y # Positive when above horizon
		# Golden hour peaks at horizon (elevation 0)
		# Starts at 30 deg (0.5 elevation)
		_golden_hour_transition = clamp((0.5 - sun_elevation) / 0.5, 0.0, 1.0)

		# Night factor:
		# 0.0 at horizon (0.0 elevation)
		# 0.5 at blue hour peak (-0.1 elevation)
		# 1.0 at full night (-0.3 elevation)
		if sun_elevation < 0.0:
			night_factor = clamp(-sun_elevation / 0.3, 0.0, 1.0)
		else:
			night_factor = 0.0

		if sun:
			sun.basis = Basis.looking_at(sun_dir, Vector3.UP if abs(sun_dir.y) < 0.99 else Vector3.FORWARD)
			# Keep energy at 1.0 until sun is half-submerged, then fade quickly
			sun.light_energy = smoothstep(-0.02, 0.02, sun_elevation)
			sun.light_color = lerp(_sun_color, Color(1.0, 0.5, 0.2), _golden_hour_transition)
			sun.shadow_enabled = Field.shadows_enabled and sun_elevation > 0.01

		if moon:
			moon.basis = Basis.looking_at(moon_dir, Vector3.UP if abs(moon_dir.y) < 0.99 else Vector3.FORWARD)
			var moon_elevation = -moon_dir.y
			moon.light_energy = smoothstep(-0.02, 0.02, moon_elevation) * 0.4
			moon.shadow_enabled = Field.shadows_enabled and moon_elevation > 0.01
	else:
		if moon:
			moon.light_energy = 0.0

		if Field.golden_hour:
			_golden_hour_transition = min(_golden_hour_transition + delta * 0.5, 1.0)
		else:
			_golden_hour_transition = max(_golden_hour_transition - delta * 0.5, 0.0)

		if sun:
			var target_dir = lerp(Vector3.DOWN, Vector3(-1.0, -0.1, 0.0).normalized(), _golden_hour_transition)
			sun.basis = Basis.looking_at(target_dir, Vector3.UP if abs(target_dir.normalized().y) < 0.5 else Vector3.FORWARD)
			sun.light_color = lerp(_sun_color, Color(1.0, 0.5, 0.2), _golden_hour_transition)
			sun.light_energy = lerp(1.0, 1.5, _golden_hour_transition)
			sun.shadow_enabled = Field.shadows_enabled

		night_factor = 0.0

	# Update sky factors globally
	RenderingServer.global_shader_parameter_set("golden_hour_factor", _golden_hour_transition)
	RenderingServer.global_shader_parameter_set("night_factor", night_factor)

	# Check if any field properties have changed
	var current_field_state = {
		"iterations": Field.iterations,
		"terrain_detail": Field.terrain_detail,
		"show_curves": Field.show_curves,
		"show_critical_stripe": Field.show_critical_stripe,
		"function_type": Field.function_type,
		"height_type": Field.height_type,
		"height_a": Field.height_a,
		"height_epsilon": Field.height_epsilon,
		"rational_num_coeffs": Field.rational_num_coeffs,
		"rational_den_coeffs": Field.rational_den_coeffs
	}

	var state_changed = current_field_state != _last_field_state

	if state_changed:
		var lod_changed = _last_field_state.get("terrain_detail", -1) != Field.terrain_detail
		_last_field_state = current_field_state

		if lod_changed:
			_update_lod_subs()
			_lod_mesh_cache.clear()
			_update_all_chunks_lod(true)

		_update_global_shader_parameters()

	# LOD Dynamic Update
	if player_chunk_x != _last_player_chunk.x or player_chunk_z != _last_player_chunk.y:
		_last_player_chunk = Vector2i(player_chunk_x, player_chunk_z)
		_update_all_chunks_lod()

func _update_all_chunks_lod(force: bool = false):
	var player_chunk_coord = _last_player_chunk
	for coord in chunks.keys():
		var chunk = chunks[coord]
		var desired_lod = _get_lod_level(coord, player_chunk_coord)
		if force or chunk.get_meta("lod_level", -1) != desired_lod:
			_update_chunk_lod(chunk, desired_lod)

func _update_lod_subs():
	match Field.terrain_detail:
		0: # High
			LOD_SUBS = [512, 256, 128, 64]
		1: # Medium
			LOD_SUBS = [256, 128, 64, 32]
		2: # Low
			LOD_SUBS = [128, 64, 32, 16]
		3: # Lowest
			LOD_SUBS = [64, 32, 16, 8]

func _get_lod_level(coord: Vector2i, player_coord: Vector2i) -> int:
	var dx = abs(coord.x - player_coord.x)
	var dz = abs(coord.y - player_coord.y)
	var dist = max(dx, dz)

	if dist <= 0:
		return 0
	elif dist <= 1:
		return 1
	elif dist <= 2:
		return 2
	else:
		return 3

func _create_lod_mesh(size: float, subdivisions: int) -> Mesh:
	var plane = PlaneMesh.new()
	plane.size = Vector2(size + chunk_leeway, size + chunk_leeway)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	return plane

func _load_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	add_child(chunk)

	var player_pos = player.global_position
	var player_chunk_coord = Vector2i(floor(player_pos.x / chunk_size), floor(player_pos.z / chunk_size))
	var lod = _get_lod_level(coord, player_chunk_coord)

	_update_chunk_lod(chunk, lod)

	chunk.global_position = Vector3(
		coord.x * chunk_size + chunk_size * 0.5,
		0,
		coord.y * chunk_size + chunk_size * 0.5
	)

	chunk.custom_aabb = AABB(
		Vector3(-chunk_size * 0.5, -50, -chunk_size * 0.5),
		Vector3(chunk_size, 100, chunk_size)
	)

	chunks[coord] = chunk

func _update_chunk_lod(chunk: MeshInstance3D, lod: int):
	var subdivisions = LOD_SUBS[lod]

	if not _lod_mesh_cache.has(subdivisions):
		_lod_mesh_cache[subdivisions] = _create_lod_mesh(chunk_size, subdivisions)

	chunk.mesh = _lod_mesh_cache[subdivisions]
	chunk.set_meta("lod_level", lod)

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)

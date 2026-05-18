extends Node3D

@export var chunk_scene: PackedScene = preload("res://scenes/chunk.tscn")
@export var player: Node3D
@export var chunk_size: float = 32.0

var chunks = {}
var _last_field_state = {}

var LOD_SUBS = [] # This will be set in code
var _lod_mesh_cache = {}
var _last_player_chunk = Vector2i(9999, 9999)

var _bake_queue = []
var _is_baking = false
var _current_bake_coord = Vector2i(0, 0)
var _current_bake_image: Image
var _current_bake_y = 0
const BAKE_RES = 128
const BAKE_LINES_PER_FRAME = 4

# We increase our chunks by this to make junctions more seamless
const chunk_leeway = 0.3;

@onready var sun = get_node("../DirectionalLight3D")
@onready var moon = get_node("../MoonLight")
@onready var world_environment = get_node("../WorldEnvironment")

# Day night cycle variables
var day_night_cycle_duration = 500.0;
var _golden_hour_transition: float = 0.0
var _day_night_time: float = 360.0
var _sun_color = Color("#fc9500")

func _ready():
	_update_lod_subs()

func _process(delta):
	if not player:
		return

	var player_pos = player.global_position
	var player_chunk_x = floor(player_pos.x / chunk_size)
	var player_chunk_z = floor(player_pos.z / chunk_size)

	# Load new chunks
	for x in range(player_chunk_x - Field.view_distance, player_chunk_x + Field.view_distance + 1):
		for z in range(player_chunk_z - Field.view_distance, player_chunk_z + Field.view_distance + 1):
			var chunk_coord = Vector2i(x, z)
			if not chunks.has(chunk_coord):
				_load_chunk(chunk_coord)

	# Unload distant chunks
	var chunks_to_remove = []
	for chunk_coord in chunks.keys():
		if abs(chunk_coord.x - player_chunk_x) > Field.view_distance or abs(chunk_coord.y - player_chunk_z) > Field.view_distance:
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
		var east_west_dir = Vector3(sin(angle), -cos(angle), 0).normalized()
		var sun_dir = east_west_dir
		var moon_dir = -sun_dir
		var sun_elevation = -sun_dir.y
		_golden_hour_transition = clamp((0.5 - sun_elevation) / 0.5, 0.0, 1.0)

		if sun_elevation < 0.0:
			night_factor = clamp(-sun_elevation / 0.3, 0.0, 1.0)
		else:
			night_factor = 0.0

		if sun:
			sun.basis = Basis.looking_at(sun_dir, Vector3.UP if abs(sun_dir.y) < 0.99 else Vector3.FORWARD)
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

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("golden_hour_factor", _golden_hour_transition)
			sky_mat.set_shader_parameter("night_factor", night_factor)

	var current_field_state = {
		"iterations": Field.iterations,
		"terrain_detail": Field.terrain_detail,
		"function_type": Field.function_type,
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

		_bake_queue.clear()
		_is_baking = false
		for coord in chunks.keys():
			var chunk = chunks[coord]
			chunk.set_meta("is_baked", false)
			if chunk.material_override:
				chunk.material_override.set_shader_parameter("use_texture", false)
				_update_chunk_uniforms(chunk)
			if not coord in _bake_queue:
				_bake_queue.append(coord)

	if player_chunk_x != _last_player_chunk.x or player_chunk_z != _last_player_chunk.y:
		_last_player_chunk = Vector2i(player_chunk_x, player_chunk_z)
		_update_all_chunks_lod()

	_process_bake_queue(player_chunk_x, player_chunk_z)

func _process_bake_queue(px: int, pz: int):
	if _bake_queue.is_empty() and not _is_baking:
		return

	if not _is_baking:
		var p_coord = Vector2i(px, pz)
		_bake_queue.sort_custom(func(a, b):
			return p_coord.distance_squared_to(a) < p_coord.distance_squared_to(b)
		)

		_current_bake_coord = _bake_queue.pop_front()
		if not chunks.has(_current_bake_coord):
			return

		_current_bake_image = Image.create(BAKE_RES, BAKE_RES, false, Image.FORMAT_RGBAF)
		_current_bake_y = 0
		_is_baking = true
	else:
		# Bake some lines
		var center = Vector2(_current_bake_coord.x * chunk_size + chunk_size * 0.5, _current_bake_coord.y * chunk_size + chunk_size * 0.5)
		var half_size = (chunk_size + chunk_leeway) * 0.5
		var chunk_min = center - Vector2(half_size, half_size)
		var chunk_max = center + Vector2(half_size, half_size)

		var end_y = min(_current_bake_y + BAKE_LINES_PER_FRAME, BAKE_RES)
		for py in range(_current_bake_y, end_y):
			var uv_y = float(py) / float(BAKE_RES - 1)
			var world_z = lerp(chunk_min.y, chunk_max.y, uv_y)
			for px_img in range(BAKE_RES):
				var uv_x = float(px_img) / float(BAKE_RES - 1)
				var world_x = lerp(chunk_min.x, chunk_max.x, uv_x)

				var f = Field.get_field(world_x, world_z)

				# Finite differences for derivatives
				var eps = 0.0001
				var f_dx = Field.get_field(world_x + eps, world_z)
				var d_sigma = (f_dx - f) * (10.0 / eps)

				_current_bake_image.set_pixel(px_img, py, Color(f.x, f.y, d_sigma.x, d_sigma.y))

		_current_bake_y = end_y
		if _current_bake_y >= BAKE_RES:
			var tex = ImageTexture.create_from_image(_current_bake_image)
			if chunks.has(_current_bake_coord):
				var chunk = chunks[_current_bake_coord]
				if chunk.material_override:
					chunk.material_override.set_shader_parameter("field_texture", tex)
					chunk.material_override.set_shader_parameter("use_texture", true)
					chunk.set_meta("is_baked", true)
					_update_chunk_uniforms(chunk)
			_is_baking = false

func _update_all_chunks_lod(force: bool = false):
	var player_chunk_coord = _last_player_chunk
	for coord in chunks.keys():
		var chunk = chunks[coord]
		var desired_lod = _get_lod_level(coord, player_chunk_coord)
		if force or chunk.get_meta("lod_level", -1) != desired_lod:
			_update_chunk_lod(chunk, desired_lod)

func _update_lod_subs():
	match Field.terrain_detail:
		0: LOD_SUBS = [512, 256, 128, 64]
		1: LOD_SUBS = [256, 128, 64, 32]
		2: LOD_SUBS = [128, 64, 32, 16]
		3: LOD_SUBS = [64, 32, 16, 8]

func _get_lod_level(coord: Vector2i, player_coord: Vector2i) -> int:
	var dist = max(abs(coord.x - player_coord.x), abs(coord.y - player_coord.y))
	if dist <= 0: return 0
	elif dist <= 1: return 1
	elif dist <= 2: return 2
	else: return 3

func _create_lod_mesh(size: float, subdivisions: int) -> Mesh:
	var plane = PlaneMesh.new()
	plane.size = Vector2(size + chunk_leeway, size + chunk_leeway)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	return plane

func _update_chunk_uniforms(chunk: MeshInstance3D):
	if chunk.material_override:
		var lod = chunk.get_meta("lod_level", 0)
		var is_baked = chunk.get_meta("is_baked", false)
		chunk.material_override.set_shader_parameter("use_texture", is_baked)
		chunk.material_override.set_shader_parameter("lod_level", lod)
		chunk.material_override.set_shader_parameter("iterations", Field.iterations)
		chunk.material_override.set_shader_parameter("show_curves", Field.show_curves)
		chunk.material_override.set_shader_parameter("show_critical_stripe", Field.show_critical_stripe)
		chunk.material_override.set_shader_parameter("debug_view_texture", Field.debug_view_texture)
		chunk.material_override.set_shader_parameter("function_type", Field.function_type)
		chunk.material_override.set_shader_parameter("height_type", Field.height_type)
		chunk.material_override.set_shader_parameter("height_a", Field.height_a)
		chunk.material_override.set_shader_parameter("height_epsilon", Field.height_epsilon)
		chunk.material_override.set_shader_parameter("rational_num_coeffs", Field.rational_num_coeffs)
		chunk.material_override.set_shader_parameter("rational_den_coeffs", Field.rational_den_coeffs)

func _load_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	add_child(chunk)
	chunk.material_override = chunk.material_override.duplicate()
	var player_pos = player.global_position
	var player_chunk_coord = Vector2i(floor(player_pos.x / chunk_size), floor(player_pos.z / chunk_size))
	var lod = _get_lod_level(coord, player_chunk_coord)
	_update_chunk_lod(chunk, lod)
	chunk.global_position = Vector3(coord.x * chunk_size + chunk_size * 0.5, 0, coord.y * chunk_size + chunk_size * 0.5)
	chunk.custom_aabb = AABB(Vector3(-chunk_size * 0.5, -150, -chunk_size * 0.5), Vector3(chunk_size, 300, chunk_size))
	chunks[coord] = chunk
	chunk.set_meta("is_baked", false)
	if not coord in _bake_queue:
		_bake_queue.append(coord)

func _update_chunk_lod(chunk: MeshInstance3D, lod: int):
	var subdivisions = LOD_SUBS[lod]
	if not _lod_mesh_cache.has(subdivisions):
		_lod_mesh_cache[subdivisions] = _create_lod_mesh(chunk_size, subdivisions)
	chunk.mesh = _lod_mesh_cache[subdivisions]
	chunk.set_meta("lod_level", lod)
	_update_chunk_uniforms(chunk)

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)
	var idx = _bake_queue.find(coord)
	if idx != -1: _bake_queue.remove_at(idx)

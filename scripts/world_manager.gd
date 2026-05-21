extends Node3D

@export var chunk_scene: PackedScene = preload("res://scenes/chunk.tscn")
@export var terrain_material: ShaderMaterial
@export var player: Node3D
@export var chunk_size: float = 32.0

var chunks = {}
var _last_field_state = {}

var LOD_SUBS = [] # This will be set in code
var _lod_mesh_cache = {}
var _last_player_chunk = Vector2i(9999, 9999)
var slow_frame_counter: int = 0
var _shaders_stopped: bool = false

# We increase our chunks by this to make junctions more seamless
# To test this, look at the right of zeta, the pole has a junction
# along t = 0.00.
const chunk_leeway = 0.3

@onready var sun = get_node("../DirectionalLight3D")
@onready var moon = get_node("../MoonLight")
@onready var world_environment = get_node("../WorldEnvironment")

# Day night cycle variables
var day_night_cycle_duration = 500.0
var _golden_hour_transition: float = 0.0
var _day_night_time: float = 0.0
var _sun_color = Color("#fc9500")

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

	# Load new chunks
	for x in range(player_chunk_x - Config.view_distance, player_chunk_x + Config.view_distance + 1):
		for z in range(player_chunk_z - Config.view_distance, player_chunk_z + Config.view_distance + 1):
			var chunk_coord = Vector2i(x, z)
			if not chunks.has(chunk_coord):
				_load_chunk(chunk_coord)

	# Unload distant chunks
	var chunks_to_remove = []
	for chunk_coord in chunks.keys():
		if abs(chunk_coord.x - player_chunk_x) > Config.view_distance or abs(chunk_coord.y - player_chunk_z) > Config.view_distance:
			chunks_to_remove.append(chunk_coord)

	for chunk_coord in chunks_to_remove:
		_unload_chunk(chunk_coord)

	# Environment logic
	var night_factor = 0.0
	var sunrise_rad = deg_to_rad(Config.sunrise_direction)
	# Orbit axis is perpendicular to sunrise vector (cos, 0, sin) and zenith (0, 1, 0)
	var orbit_axis = Vector3(sin(sunrise_rad), 0, -cos(sunrise_rad))

	if Config.environment_type == 2: # Dynamic sun and moon
		_day_night_time += delta
		if _day_night_time >= day_night_cycle_duration:
			_day_night_time -= day_night_cycle_duration

		var progress = _day_night_time / day_night_cycle_duration
		var angle = progress * TAU

		# Sun direction: rotate Noon (0, -1, 0) around orbit axis
		var sun_dir = Quaternion(orbit_axis, angle) * Vector3.DOWN
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
			sun.shadow_enabled = Config.shadows_enabled and sun_elevation > 0.01

		if moon:
			moon.basis = Basis.looking_at(moon_dir, Vector3.UP if abs(moon_dir.y) < 0.99 else Vector3.FORWARD)
			var moon_elevation = -moon_dir.y
			moon.light_energy = smoothstep(-0.02, 0.02, moon_elevation) * 0.4
			moon.shadow_enabled = Config.shadows_enabled and moon_elevation > 0.01
	else:
		if moon:
			moon.light_energy = 0.0

		var target_transition = 1.0 if Config.environment_type == 1 else 0.0
		_golden_hour_transition = move_toward(_golden_hour_transition, target_transition, delta * 0.5)

		if sun:
			# Target direction for golden hour: 0.1 radians above horizon at Sunrise
			# Angle -PI/2 is Sunrise, so we use -(PI/2 - 0.1)
			var sunrise_angle = -(PI/2 - 0.1) * _golden_hour_transition
			var target_dir = Quaternion(orbit_axis, sunrise_angle) * Vector3.DOWN

			sun.basis = Basis.looking_at(target_dir, Vector3.UP if abs(target_dir.y) < 0.99 else Vector3.FORWARD)
			sun.light_color = lerp(_sun_color, Color(1.0, 0.5, 0.2), _golden_hour_transition)
			sun.light_energy = lerp(1.0, 1.5, _golden_hour_transition)
			sun.shadow_enabled = Config.shadows_enabled

		night_factor = 0.0

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("golden_hour_factor", _golden_hour_transition)
			sky_mat.set_shader_parameter("night_factor", night_factor)

	# Only update branch time on branch functions
	if Config.function_type >= 14 and Config.function_type <= 17:
		Config.branch_time = Time.get_ticks_msec() / 1000.0

	# Check if any field properties have changed
	var current_field_state = {
		"iterations": Config.iterations,
		"terrain_detail": Config.terrain_detail,
		"show_curves": Config.show_curves,
		"show_critical_stripe": Config.show_critical_stripe,
		"color_scheme": Config.color_scheme,
		"function_type": Config.function_type,
		"height_type": Config.height_type,
		"height_a": Config.height_a,
		"height_epsilon": Config.height_epsilon,
		"zoom_factor": Config.zoom_factor,
		"effective_zoom": Config.effective_zoom,
		"rational_num_coeffs": Config.rational_num_coeffs,
		"rational_den_coeffs": Config.rational_den_coeffs,
		"multivalued_n": Config.multivalued_n,
		"branch_cycle_speed": Config.branch_cycle_speed,
		"multivalued_morph_time": Config.multivalued_morph_time,
		"branch_time": Config.branch_time,
		"terrain_brightness": Config.terrain_brightness,
		"terrain_saturation": Config.terrain_saturation,
		"terrain_albedo": Config.terrain_albedo,
		"terrain_emission": Config.terrain_emission,
		"terrain_metallic": Config.terrain_metallic,
		"terrain_roughness": Config.terrain_roughness
	}

	var state_changed = current_field_state != _last_field_state

	if state_changed:
		var lod_changed = _last_field_state.get("terrain_detail", -1) != Config.terrain_detail
		_last_field_state = current_field_state

		if lod_changed:
			_update_lod_subs()
			_lod_mesh_cache.clear()
			_update_all_chunks_lod(true)

		_update_terrain_material_uniforms()

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
	match Config.terrain_detail:
		0: # High
			LOD_SUBS = [512, 256, 128, 64]
		1: # Medium
			LOD_SUBS = [256, 128, 32, 16]
		2: # Low
			LOD_SUBS = [128, 64, 32, 16]
		3: # Lowest
			LOD_SUBS = [64, 32, 16, 8]

func _get_lod_level(coord: Vector2i, player_coord: Vector2i) -> int:
	var dx = abs(coord.x - player_coord.x)
	var dz = abs(coord.y - player_coord.y)
	var dist = max(dx, dz)

	if dist <= 1:
		return 0
	elif dist <= 2:
		return 1
	elif dist <= 4:
		return 2
	else:
		return 3

func _create_lod_mesh(size: float, subdivisions: int) -> Mesh:
	var plane = PlaneMesh.new()
	plane.size = Vector2(size + chunk_leeway, size + chunk_leeway)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	return plane

func _apply_performance_protection(active: bool):
	_shaders_stopped = active
	for chunk in chunks.values():
		chunk.visible = !active

	if terrain_material:
		terrain_material.set_shader_parameter("performance_protection_active", active)

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("performance_protection_active", active)

func _update_terrain_material_uniforms():
	if not terrain_material:
		return

	terrain_material.set_shader_parameter("performance_protection_active", Config.performance_protection_active)
	terrain_material.set_shader_parameter("color_scheme", Config.color_scheme)
	terrain_material.set_shader_parameter("iterations", Config.iterations)
	terrain_material.set_shader_parameter("show_curves", Config.show_curves)
	terrain_material.set_shader_parameter("show_critical_stripe", Config.show_critical_stripe)
	terrain_material.set_shader_parameter("function_type", Config.function_type)
	terrain_material.set_shader_parameter("height_type", Config.height_type)
	terrain_material.set_shader_parameter("height_a", Config.height_a)
	terrain_material.set_shader_parameter("height_epsilon", Config.height_epsilon)
	terrain_material.set_shader_parameter("zoom_factor", Config.effective_zoom)
	terrain_material.set_shader_parameter("rational_num_coeffs", Config.rational_num_coeffs)
	terrain_material.set_shader_parameter("rational_den_coeffs", Config.rational_den_coeffs)
	terrain_material.set_shader_parameter("multivalued_n", Config.multivalued_n)
	terrain_material.set_shader_parameter("branch_cycle_speed", Config.branch_cycle_speed)
	terrain_material.set_shader_parameter("multivalued_morph_time", Config.multivalued_morph_time)
	terrain_material.set_shader_parameter("brightness", Config.terrain_brightness)
	terrain_material.set_shader_parameter("saturation", Config.terrain_saturation)
	terrain_material.set_shader_parameter("albedo", Config.terrain_albedo)
	terrain_material.set_shader_parameter("emission", Config.terrain_emission)
	terrain_material.set_shader_parameter("metallic", Config.terrain_metallic)
	terrain_material.set_shader_parameter("roughness", Config.terrain_roughness)
	terrain_material.set_shader_parameter("branch_time", Config.branch_time)

func _update_chunk_uniforms(chunk: MeshInstance3D):
	var lod = chunk.get_meta("lod_level", 0)
	chunk.set_instance_shader_parameter("lod_level", lod)

func _load_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	add_child(chunk)
	chunk.visible = !Config.performance_protection_active

	chunk.material_override = terrain_material

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
	_update_chunk_uniforms(chunk)

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)

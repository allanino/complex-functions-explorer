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
var portal_frame: Node3D
var portal_ground_bar: MeshInstance3D
var portal_vert_bar: MeshInstance3D
var portal_top_bar: MeshInstance3D
var portal_end_bar: MeshInstance3D

@onready var sun = get_node("../DirectionalLight3D")
@onready var moon = get_node("../MoonLight")
@onready var world_environment = get_node("../WorldEnvironment")

# Day night cycle variables
var _golden_hour_transition: float = 0.0
var _sun_color = Color("#fc9500")

func _ready():
	_update_lod_subs()
	_update_terrain_material_uniforms()
	_setup_portal_frame()
	# Uncomment this to debug the mesh wireframe
	# get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

func _setup_portal_frame():
	portal_frame = Node3D.new()
	portal_frame.name = "PortalFrame"
	add_child(portal_frame)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.0, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.8, 1.0)
	mat.emission_energy_multiplier = 2.0

	# Ground line
	portal_ground_bar = MeshInstance3D.new()
	portal_ground_bar.mesh = BoxMesh.new()
	portal_ground_bar.mesh.size = Vector3(1.0, 0.2, 0.2)
	portal_ground_bar.material_override = mat
	portal_frame.add_child(portal_ground_bar)
	portal_ground_bar.position = Vector3(5000.0, 0.0, 0.0)

	# Vertical bar at origin
	portal_vert_bar = MeshInstance3D.new()
	portal_vert_bar.mesh = BoxMesh.new()
	portal_vert_bar.mesh.size = Vector3(0.2, 1.0, 0.2) # Initial, will scale
	portal_vert_bar.material_override = mat
	portal_frame.add_child(portal_vert_bar)

	# Top bar
	portal_top_bar = MeshInstance3D.new()
	portal_top_bar.mesh = BoxMesh.new()
	portal_top_bar.mesh.size = Vector3(1.0, 0.2, 0.2) # Scaled dynamically
	portal_top_bar.material_override = mat
	portal_frame.add_child(portal_top_bar)

	# End vertical bar
	portal_end_bar = MeshInstance3D.new()
	portal_end_bar.mesh = BoxMesh.new()
	portal_end_bar.mesh.size = Vector3(0.2, 1.0, 0.2)
	portal_end_bar.material_override = mat
	portal_frame.add_child(portal_end_bar)

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

	# Environment logic
	var night_factor = 0.0
	var sunrise_rad = deg_to_rad(Config.sunrise_direction)
	# Orbit axis is perpendicular to sunrise vector (cos, 0, sin) and zenith (0, 1, 0)
	var orbit_axis = Vector3(sin(sunrise_rad), 0, -cos(sunrise_rad))

	var progress = 0.0
	if Config.environment_type == 0: # Dynamic
		# Increment static time based on day duration
		# 86400 seconds in a day / day_duration = speed multiplier
		Config.static_time += delta * (86400.0 / Config.day_duration)
		if Config.static_time >= 86400.0:
			Config.static_time -= 86400.0
		progress = Config.static_time / 86400.0
	else: # Static or presets
		match Config.environment_type:
			1: Config.static_time = 43200.0 # Noon
			2: Config.static_time = 21600.0 # Sunrise (6 AM)
			3: Config.static_time = 0.0 # Midnight

		progress = Config.static_time / 86400.0

	# angle = PI is Midnight (progress 0.0), angle = 0.0 is Noon (progress 0.5)
	var angle = (progress + 0.5) * TAU

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
		sun.light_energy = smoothstep(-0.02, 0.02, sun_elevation) * Config.sun_luminosity
		sun.light_color = lerp(_sun_color, Color(1.0, 0.5, 0.2), _golden_hour_transition)
		sun.shadow_enabled = Config.shadows_enabled and sun_elevation > 0.01

	if moon:
		moon.basis = Basis.looking_at(moon_dir, Vector3.UP if abs(moon_dir.y) < 0.99 else Vector3.FORWARD)
		var moon_elevation = -moon_dir.y
		moon.light_energy = smoothstep(-0.02, 0.02, moon_elevation) * 0.4 * Config.sun_luminosity
		moon.shadow_enabled = Config.shadows_enabled and moon_elevation > 0.01

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("golden_hour_factor", _golden_hour_transition)
			sky_mat.set_shader_parameter("night_factor", night_factor)
			sky_mat.set_shader_parameter("sky_luminosity", Config.sky_luminosity)


		#Setup fog	
		var env = world_environment.environment
	
		var fog_color = lerp(Color(0.6, 0.8, 1.0), Color(1.0, 0.4, 0.1), _golden_hour_transition)
		fog_color = lerp(fog_color, Color(0.01, 0.02, 0.05), night_factor)

		env.fog_enabled = Config.fog_enabled
		env.fog_mode = Environment.FOG_MODE_DEPTH
		env.fog_light_color = fog_color
		env.fog_density = 1.0
		env.fog_depth_begin = Config.fog_distance
		env.fog_depth_end = Config.fog_distance * 3.0
		env.fog_depth_curve = 0.2
		env.fog_aerial_perspective = (1.0 - Config.fog_density)

	# Only update branch time on branch functions
	if Config.function.get("is_multivalued", false):
		Config.branch_time = Time.get_ticks_msec() / 1000.0

	if terrain_material:
		terrain_material.set_shader_parameter("branch_time", Config.branch_time)
		terrain_material.set_shader_parameter("zoom_factor", Config.effective_zoom)

	# Check if any field properties have changed
	var current_field_state = {
		"iterations": Config.iterations,
		"terrain_detail": Config.terrain_detail,
		"view_distance": Config.view_distance,
		"show_curves": Config.show_curves,
		"show_critical_stripe": Config.show_critical_stripe,
		"show_flow": Config.show_flow,
		"color_scheme": Config.color_scheme,
		"function_type": Config.function_type,
		"height_type": Config.height_type,
		"height_a": Config.height_a,
		"height_epsilon": Config.height_epsilon,
		"zoom_factor": Config.zoom_factor,
		"rational_num_coeffs": Config.rational_num_coeffs,
		"rational_den_coeffs": Config.rational_den_coeffs,
		"multivalued_n": Config.multivalued_n,
		"multivalued_mode": Config.multivalued_mode,
		"branch_cycle_speed": Config.branch_cycle_speed,
		"multivalued_morph_time": Config.multivalued_morph_time,
		"branch_time": Config.branch_time,
		"current_branch": Config.current_branch,
		"terrain_brightness": Config.terrain_brightness,
		"terrain_saturation": Config.terrain_saturation,
		"terrain_albedo": Config.terrain_albedo,
		"terrain_emission": Config.terrain_emission,
		"terrain_metallic": Config.terrain_metallic,
		"terrain_roughness": Config.terrain_roughness,
		"morph_type": Config.morph_type,
		"morph_value": Config.morph_value,
		"sky_luminosity": Config.sky_luminosity,
		"sun_luminosity": Config.sun_luminosity,
		"fog_enabled": Config.fog_enabled,
		"fog_density": Config.fog_density,
		"fog_distance": Config.fog_distance
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

	# Chunk and LOD Dynamic Update
	if player_chunk_x != _last_player_chunk.x or player_chunk_z != _last_player_chunk.y:
		_last_player_chunk = Vector2i(player_chunk_x, player_chunk_z)

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

		_update_all_chunks_lod()

	if portal_frame:
		var is_portal_mode = (Config.function.get("is_multivalued", false) and Config.multivalued_mode == 1)
		portal_frame.visible = is_portal_mode
		if is_portal_mode:
			var zoom = Config.effective_zoom
			var cam_h = player.global_position.y
			var p_height = max(50.0 * zoom, cam_h + 50.0 * zoom)

			var player_x = player.global_position.x
			var p_width = max(100.0 * zoom, player_x + float(Config.view_distance + 1) * chunk_size)

			portal_frame.scale = Vector3.ONE # We handle scaling manually on bars

			portal_ground_bar.scale = Vector3(p_width, zoom, zoom)
			portal_ground_bar.position = Vector3(p_width * 0.5, 0.0, 0.0)

			portal_vert_bar.scale = Vector3(zoom, p_height, zoom)
			portal_vert_bar.position = Vector3(0.0, p_height * 0.5, 0.0)

			portal_top_bar.scale = Vector3(p_width, zoom, zoom)
			portal_top_bar.position = Vector3(p_width * 0.5, p_height, 0.0)

			portal_end_bar.scale = Vector3(zoom, p_height, zoom)
			portal_end_bar.position = Vector3(p_width, p_height * 0.5, 0.0)

			if terrain_material:
				terrain_material.set_shader_parameter("portal_height", p_height)
				terrain_material.set_shader_parameter("portal_width", p_width)

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
			LOD_SUBS = [511, 255, 127, 63, 31]
		1: # Medium
			LOD_SUBS = [255, 127, 63, 31, 15]
		2: # Low
			LOD_SUBS = [127, 63, 31, 15, 7]
		3: # Lowest
			LOD_SUBS = [63, 31, 15, 7, 3]

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
	elif dist <= 6:
		return 3
	else:
		return 4

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

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("performance_protection_active", active)

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
	terrain_material.set_shader_parameter("show_critical_stripe", Config.show_critical_stripe)
	terrain_material.set_shader_parameter("show_flow", Config.show_flow)
	terrain_material.set_shader_parameter("function_type", Config.function_type)
	terrain_material.set_shader_parameter("height_type", Config.height_type)
	terrain_material.set_shader_parameter("height_a", Config.height_a)
	terrain_material.set_shader_parameter("height_epsilon", Config.height_epsilon)
	terrain_material.set_shader_parameter("zoom_factor", Config.effective_zoom)
	terrain_material.set_shader_parameter("rational_num_coeffs", Config.rational_num_coeffs)
	terrain_material.set_shader_parameter("rational_den_coeffs", Config.rational_den_coeffs)
	terrain_material.set_shader_parameter("multivalued_n", Config.multivalued_n)
	terrain_material.set_shader_parameter("multivalued_mode", Config.multivalued_mode)
	terrain_material.set_shader_parameter("branch_cycle_speed", Config.branch_cycle_speed)
	terrain_material.set_shader_parameter("multivalued_morph_time", Config.multivalued_morph_time)
	terrain_material.set_shader_parameter("brightness", Config.terrain_brightness)
	terrain_material.set_shader_parameter("saturation", Config.terrain_saturation)
	terrain_material.set_shader_parameter("albedo", Config.terrain_albedo)
	terrain_material.set_shader_parameter("emission", Config.terrain_emission)
	terrain_material.set_shader_parameter("metallic", Config.terrain_metallic)
	terrain_material.set_shader_parameter("roughness", Config.terrain_roughness)
	terrain_material.set_shader_parameter("branch_time", Config.branch_time)
	terrain_material.set_shader_parameter("current_branch", Config.current_branch)

	terrain_material.set_shader_parameter("chunk_size", chunk_size)
	var segments = []
	for sub in LOD_SUBS:
		segments.append(float(sub + 1))
	terrain_material.set_shader_parameter("lod_segments", segments)

	var morph_param = 1.0
	if Config.morph_type == 1:
		morph_param = Config.morph_value
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
	var chunk = chunk_scene.instantiate()
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
		_lod_mesh_cache[subdivisions] = _create_lod_mesh(chunk_size, subdivisions)

	chunk.mesh = _lod_mesh_cache[subdivisions]
	chunk.set_meta("lod_level", lod)
	_update_chunk_uniforms(chunk)

	_update_neighbor_lods(coord)

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)
	_update_neighbor_lods(coord)

extends Node3D

@export var terrain_chunk_scene: PackedScene = preload("res://terrain/terrain_chunk.tscn")
@export var terrain_material: ShaderMaterial
@export var player: Node3D
@export var chunk_size: float = 16.0

var chunks = {}
var _chunk_lods = {}
var _chunk_per_pixel = {}
var _chunk_min_lambda = {}
var _chunk_max_lambda = {}
var _chunk_unit_dir = {}
var _chunk_beyond_antipode = {}
var _sphere_chunks_dirty: bool = false
var _sphere_geom_dirty: bool = false
var _last_geom_radius: float = -1.0
var _last_flag_pole: Vector3 = Vector3.ZERO
var _dirty_neighbor_coords = {}
var chunk_leeway = 0.01
var LOD_SUBS = [] # This will be set in code
var _lod_mesh_cache = {}
var _last_player_chunk = Vector2i(9999, 9999)
var _chunk_pool: Array[MeshInstance3D] = []
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
	_update_sphere_uniforms()
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
	var target_bias = 1.0 + clamp((current_speed - 20.0) / 25.0, 0.0, 4.0)
	_lod_speed_bias = lerp(_lod_speed_bias, target_bias, delta * 2.0)

	# If bias has shifted significantly, force an update scan of LOD transitions
	if abs(_lod_speed_bias - _last_applied_speed_bias) > 0.2:
		_update_all_chunks_lod(true)
		_last_applied_speed_bias = _lod_speed_bias

	if current != _last_lod_player_chunk:
		_update_all_chunks_lod()
		_last_lod_player_chunk = current

	if _sphere_geom_dirty:
		_sphere_geom_dirty = false
		_sphere_chunks_dirty = false
		_refresh_sphere_chunk_geometry()
		_update_sphere_chunk_flags(true)
	elif _sphere_chunks_dirty:
		_sphere_chunks_dirty = false
		_update_sphere_chunk_flags()

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

	var lod: int
	if dist <= int(round(2.0 * _lod_speed_bias)):
		lod = 0
	elif dist <= int(round(4.0 * _lod_speed_bias)):
		lod = 1
	elif dist <= int(round(8.0 * _lod_speed_bias)):
		lod = 2
	elif dist <= int(round(16.0 * _lod_speed_bias)):
		lod = 3
	elif dist <= int(round(32.0 * _lod_speed_bias)):
		lod = 4
	elif dist <= int(round(48.0 * _lod_speed_bias)):
		lod = 5
	else:
		lod = 6

	if Config.riemann_sphere_mode:
		if _chunk_per_pixel.get(coord, false):
			if not Config.riemann_sphere_height or _chunk_min_lambda.get(coord, 0.0) >= RiemannSphere.HEIGHT_FADE_END:
				lod = max(lod, 3)
				while lod < LOD_SUBS.size() - 1 and LOD_SUBS[lod] > 31:
					lod += 1
		else:
			# Avoid over-sampling near z = 0 where stereographic lambda << plane scale (0.1).
			var max_lam = _chunk_max_lambda.get(coord, 0.1)
			var plane_ref = 0.1 / maxf(GameState.effective_zoom, 1e-5)
			var target_step = plane_ref * (chunk_size / float(LOD_SUBS[lod] + 1))
			while lod < LOD_SUBS.size() - 1 and LOD_SUBS[lod + 1] >= 31 and max_lam * (chunk_size / float(LOD_SUBS[lod + 1] + 1)) <= target_step:
				lod += 1

	return lod

func _create_lod_mesh(size: float, subdivisions: int) -> Mesh:
	var plane = PlaneMesh.new()
	plane.size = Vector2(size, size)
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions
	return plane

func _apply_performance_protection(active: bool):
	_shaders_stopped = active
	for coord in chunks:
		chunks[coord].visible = (not active) and (not _chunk_beyond_antipode.get(coord, false))

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


func _update_sphere_uniforms():
	if not terrain_material:
		return
	terrain_material.set_shader_parameter("sphere_mode", Config.riemann_sphere_mode)
	terrain_material.set_shader_parameter("clamp_exp_overflow", Config.riemann_sphere_mode)
	terrain_material.set_shader_parameter("sphere_radius", Config.get_sphere_radius())
	terrain_material.set_shader_parameter("sphere_height", Config.riemann_sphere_height)
	terrain_material.set_shader_parameter("sphere_basis", GameState.sphere_basis)


# True when every corner of chunk `coord` lies past the antipode (distance > PI * R), where the
# sphere shader collapses all vertices onto a single point on the far side of the sphere.
func _is_chunk_beyond_antipode(coord: Vector2i, r_sphere: float) -> bool:
	var min_x = coord.x * chunk_size
	var min_z = coord.y * chunk_size
	var nx = clampf(0.0, min_x, min_x + chunk_size)
	var nz = clampf(0.0, min_z, min_z + chunk_size)
	var max_r = PI * r_sphere
	return (nx * nx + nz * nz) > (max_r * max_r)


func _compute_chunk_unit_dir(coord: Vector2i, r_sphere: float) -> Vector3:
	var center = Vector2(coord.x * chunk_size + chunk_size * 0.5, coord.y * chunk_size + chunk_size * 0.5)
	return RiemannSphere.chart_to_local_unit(center, r_sphere)


func _should_resolve_per_pixel(coord: Vector2i, max_lambda: float) -> bool:
	if not Config.riemann_sphere_mode or LOD_SUBS.is_empty():
		return false
	var spacing_lod0 = chunk_size / float(LOD_SUBS[0] + 1)
	var c_per_vert = max_lambda * spacing_lod0
	if _chunk_per_pixel.get(coord, false):
		return c_per_vert >= RiemannSphere.PER_PIXEL_THRESHOLD * RiemannSphere.PER_PIXEL_HYSTERESIS
	return c_per_vert > RiemannSphere.PER_PIXEL_THRESHOLD


const CHUNK_HALF_DIAG_RATIO = 0.70710678 # sqrt(2) / 2

func _compute_chunk_lambda_range(l_center: Vector3, pole_local: Vector3, r_sphere: float, cos_ang: float, sin_ang: float) -> Vector2:
	return RiemannSphere.chunk_lambda_range(l_center, pole_local, r_sphere, cos_ang, sin_ang)


func _update_sphere_chunk_flags(force: bool = false):
	if not player:
		return
	var player_pos = player.global_position
	var player_chunk = Vector2i(floor(player_pos.x / chunk_size), floor(player_pos.z / chunk_size))
	var lod_changed = false

	if not Config.riemann_sphere_mode:
		for coord in chunks:
			if _chunk_per_pixel.get(coord, false):
				_chunk_per_pixel[coord] = false
				chunks[coord].set_instance_shader_parameter("resolve_per_pixel", false)
			_chunk_min_lambda[coord] = 0.0
			_chunk_max_lambda.erase(coord)
			var target_lod = _get_lod_level(coord, player_chunk)
			if target_lod != _chunk_lods.get(coord, -1):
				_update_chunk_lod(chunks[coord], target_lod, coord)
				lod_changed = true
		if lod_changed:
			_flush_dirty_neighbors()
		return

	var r_sphere = maxf(Config.get_sphere_radius(), 1.0)
	# South pole (z = infinity) expressed in the player's local frame.
	var pole_local = GameState.sphere_basis.transposed() * Vector3(0.0, -1.0, 0.0)
	# Skip redundant scans during tiny sub-degree rotations unless forced.
	if not force and _last_flag_pole.length_squared() > 0.5 and pole_local.dot(_last_flag_pole) > 0.99995:
		return
	_last_flag_pole = pole_local

	var chunk_ang = minf((chunk_size * CHUNK_HALF_DIAG_RATIO) / r_sphere, PI)
	var cos_ang = cos(chunk_ang)
	var sin_ang = sin(chunk_ang)

	for coord in chunks:
		if _chunk_beyond_antipode.get(coord, false):
			continue
		var l_center: Vector3 = _chunk_unit_dir.get(coord, _compute_chunk_unit_dir(coord, r_sphere))
		var lam_range = _compute_chunk_lambda_range(l_center, pole_local, r_sphere, cos_ang, sin_ang)
		var min_lam = lam_range.x
		var max_lam = lam_range.y
		_chunk_min_lambda[coord] = min_lam
		_chunk_max_lambda[coord] = max_lam

		var old_flag = _chunk_per_pixel.get(coord, false)
		var new_flag = _should_resolve_per_pixel(coord, max_lam)

		var chunk = chunks[coord]
		if new_flag != old_flag:
			_chunk_per_pixel[coord] = new_flag
			chunk.set_instance_shader_parameter("resolve_per_pixel", new_flag)

		var target_lod = _get_lod_level(coord, player_chunk)
		if target_lod != _chunk_lods.get(coord, -1):
			_update_chunk_lod(chunk, target_lod, coord)
			lod_changed = true

	if lod_changed:
		_flush_dirty_neighbors()


# Tight local AABB for frustum culling in both flat and Riemann Sphere modes.
# In sphere mode, every vertex on a chunk lies on the outward ray l * (R + h) - (0, R, 0),
# which depends only on chart offset and radius (independent of sphere_basis), so chunks behind
# the camera remain frustum-culled even with radial height displacement enabled.
func _make_chunk_aabb(coord: Vector2i) -> AABB:
	if not Config.riemann_sphere_mode:
		return AABB(
			Vector3(- (chunk_size + chunk_leeway) * 0.5, -50, - (chunk_size + chunk_leeway) * 0.5),
			Vector3(chunk_size + chunk_leeway, 1400, chunk_size + chunk_leeway)
		)

	var r_sphere = maxf(Config.get_sphere_radius(), 1.0)
	var r_min = (1.0 - RiemannSphere.MAX_HEIGHT_RATIO) * r_sphere if Config.riemann_sphere_height else r_sphere
	var r_max = (1.0 + RiemannSphere.MAX_HEIGHT_RATIO) * r_sphere if Config.riemann_sphere_height else r_sphere
	var origin = Vector3(coord.x * chunk_size + chunk_size * 0.5, 0.0, coord.y * chunk_size + chunk_size * 0.5)
	var sphere_center_offset = Vector3(0.0, r_sphere, 0.0) + origin
	var hs = chunk_size * 0.5
	var min_v = Vector3(INF, INF, INF)
	var max_v = Vector3(-INF, -INF, -INF)
	var min_dist = INF
	var max_dist = 0.0
	for ox in [-hs, hs]:
		for oz in [-hs, hs]:
			var c = Vector2(origin.x + ox, origin.z + oz)
			var dist = c.length()
			min_dist = minf(min_dist, dist)
			max_dist = maxf(max_dist, dist)
			var l = RiemannSphere.chart_to_local_unit(c, r_sphere)
			var p_min = l * r_min - sphere_center_offset
			min_v = min_v.min(p_min)
			max_v = max_v.max(p_min)
			if r_max != r_min:
				var p_max = l * r_max - sphere_center_offset
				min_v = min_v.min(p_max)
				max_v = max_v.max(p_max)
	# If the chunk straddles the equator (d = PI/2), include the equator radial peak so tall
	# mountains on small spheres (e.g. R = 10) aren't clipped by the 4-corner chord.
	var eq_dist = PI * 0.5 * r_sphere
	if r_max != r_min and min_dist < eq_dist and max_dist > eq_dist:
		var c_dir = Vector2(origin.x, origin.z)
		if c_dir.length_squared() > 1e-6:
			c_dir = c_dir.normalized()
			var l_eq = Vector3(c_dir.x, 0.0, c_dir.y)
			var p_eq = l_eq * r_max - sphere_center_offset
			min_v = min_v.min(p_eq)
			max_v = max_v.max(p_eq)
	var pad = Vector3.ONE * maxf(4.0, chunk_size * 0.35)
	return AABB(min_v - pad, (max_v - min_v) + pad * 2.0)


func _refresh_sphere_chunk_geometry():
	var r_sphere = maxf(Config.get_sphere_radius(), 1.0)
	_last_geom_radius = r_sphere
	for coord in chunks:
		var chunk = chunks[coord]
		if Config.riemann_sphere_mode:
			_chunk_unit_dir[coord] = _compute_chunk_unit_dir(coord, r_sphere)
			var beyond = _is_chunk_beyond_antipode(coord, r_sphere)
			_chunk_beyond_antipode[coord] = beyond
			chunk.visible = (not GameState.performance_protection_active) and (not beyond)
			if not beyond:
				chunk.custom_aabb = _make_chunk_aabb(coord)
		else:
			_chunk_beyond_antipode[coord] = false
			chunk.visible = not GameState.performance_protection_active
			chunk.custom_aabb = _make_chunk_aabb(coord)


func _update_terrain_material_uniforms(key: String):
	if not terrain_material:
		return

	if key in ["function_type", "input_function_type"]:
		var f_data = Config.function
		terrain_material.set_shader_parameter("function_type", Config.function_type)
		terrain_material.set_shader_parameter("input_function_type", Config.input_function_type)
		terrain_material.set_shader_parameter("is_dirichlet", f_data.get("is_dirichlet", false))
		terrain_material.set_shader_parameter("is_multivalued", Config.is_multivalued_active())
		return

	if key == "real_level_curves_highlighted":
		var real_shaded = GameState.get_padded_level_curves(GameState.real_level_curves_highlighted)
		terrain_material.set_shader_parameter("real_level_curves_highlighted", real_shaded)
		return

	if key == "imag_level_curves_highlighted":
		var imag_shaded = GameState.get_padded_level_curves(GameState.imag_level_curves_highlighted)
		terrain_material.set_shader_parameter("imag_level_curves_highlighted", imag_shaded)
		return


	if key == "newton_path_bbox":
		terrain_material.set_shader_parameter("newton_path_bbox", GameState.newton_path_bbox)
		return

	if key == "newton_path":
		if GameState.newton_path.size() > 0:
			var newton_path_size = GameState.newton_path.size()
			var newton_path = GameState.get_padded_newton_path()

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
	chunk.set_instance_shader_parameter("resolve_per_pixel", _chunk_per_pixel.get(coord, false))


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
	var chunk: MeshInstance3D
	if _chunk_pool.is_empty():
		chunk = terrain_chunk_scene.instantiate()
		add_child(chunk)
	else:
		chunk = _chunk_pool.pop_back()
		chunk.process_mode = Node.PROCESS_MODE_INHERIT

	chunk.visible = !GameState.performance_protection_active

	chunk.material_override = terrain_material

	var player_pos = player.global_position
	var player_chunk_coord = Vector2i(floor(player_pos.x / chunk_size), floor(player_pos.z / chunk_size))
	if Config.riemann_sphere_mode:
		var r_sphere = maxf(Config.get_sphere_radius(), 1.0)
		var l_center = _compute_chunk_unit_dir(coord, r_sphere)
		_chunk_unit_dir[coord] = l_center
		var beyond = _is_chunk_beyond_antipode(coord, r_sphere)
		_chunk_beyond_antipode[coord] = beyond
		chunk.visible = (not GameState.performance_protection_active) and (not beyond)
		var pole_local = GameState.sphere_basis.transposed() * Vector3(0.0, -1.0, 0.0)
		var chunk_ang = minf((chunk_size * CHUNK_HALF_DIAG_RATIO) / r_sphere, PI)
		var lam_range = _compute_chunk_lambda_range(l_center, pole_local, r_sphere, cos(chunk_ang), sin(chunk_ang))
		_chunk_min_lambda[coord] = lam_range.x
		_chunk_max_lambda[coord] = lam_range.y
		_chunk_per_pixel[coord] = _should_resolve_per_pixel(coord, lam_range.y)
	else:
		_chunk_beyond_antipode[coord] = false
		_chunk_min_lambda.erase(coord)
		_chunk_max_lambda.erase(coord)
		_chunk_per_pixel[coord] = false
	var lod = _get_lod_level(coord, player_chunk_coord)

	chunks[coord] = chunk
	_loaded_chunk_list.append(coord)
	_update_chunk_lod(chunk, lod, coord)

	chunk.global_position = Vector3(
		coord.x * chunk_size + chunk_size * 0.5,
		0,
		coord.y * chunk_size + chunk_size * 0.5
	)

	chunk.custom_aabb = _make_chunk_aabb(coord)

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
	chunk.visible = false
	chunk.process_mode = Node.PROCESS_MODE_DISABLED
	chunk.mesh = null
	chunk.set_instance_shader_parameter("resolve_per_pixel", false)

	_chunk_pool.append(chunk)
	chunks.erase(coord)
	_loaded_chunk_list.erase(coord)
	_chunk_lods.erase(coord)
	_chunk_per_pixel.erase(coord)
	_chunk_min_lambda.erase(coord)
	_chunk_max_lambda.erase(coord)
	_chunk_unit_dir.erase(coord)
	_chunk_beyond_antipode.erase(coord)
	_dirty_neighbor_coords[Vector2i(coord.x - 1, coord.y)] = true
	_dirty_neighbor_coords[Vector2i(coord.x + 1, coord.y)] = true
	_dirty_neighbor_coords[Vector2i(coord.x, coord.y - 1)] = true
	_dirty_neighbor_coords[Vector2i(coord.x, coord.y + 1)] = true

func _on_config_changed(key: String):
	if key in ["riemann_sphere_mode", "riemann_sphere_radius", "riemann_sphere_height"]:
		_update_terrain_material_uniforms("function_type")
		_update_sphere_uniforms()
		if key == "riemann_sphere_mode" and player:
			_update_chunks(floor(player.global_position.x / chunk_size), floor(player.global_position.z / chunk_size), true)
		_refresh_sphere_chunk_geometry()
		_update_sphere_chunk_flags(true)
		return
	if key in ["iterations", "terrain_detail", "view_distance", "show_curves", "show_critical_stripe", "show_flow", "show_position_marker", "color_scheme", "function_type", "input_function_type", "height_type", "height_a", "height_epsilon", "height_theta", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "self_illumination", "terrain_brightness", "terrain_saturation", "terrain_albedo", "terrain_emission", "terrain_metallic", "terrain_roughness", "terrain_ao", "terrain_rim", "terrain_rim_tint", "morph_style", "morph_value", "fog_density", "morph_style"]:
		_update_terrain_material_uniforms(key)
		if key == "terrain_detail":
			_update_lod_subs()
			_lod_mesh_cache.clear()
			if Config.riemann_sphere_mode:
				_update_sphere_chunk_flags(true)
			_update_all_chunks_lod(true)
		if key in ["view_distance", "terrain_detail", "function_type", "input_function_type"]:
			if key == "view_distance":
				_update_view_offsets()
			if player:
				_update_chunks(floor(player.global_position.x / chunk_size), floor(player.global_position.z / chunk_size), true)

func _on_state_changed(key: String):
	if key == "sphere_basis":
		if terrain_material:
			terrain_material.set_shader_parameter("sphere_basis", GameState.sphere_basis)
		if Config.riemann_sphere_mode:
			_sphere_chunks_dirty = true
		return
	if key == "effective_zoom" and Config.riemann_sphere_mode:
		var r_sphere = maxf(Config.get_sphere_radius(), 1.0)
		terrain_material.set_shader_parameter("sphere_radius", r_sphere)
		var zoom_done = is_equal_approx(GameState.effective_zoom, float(Config.zoom_factor))
		if zoom_done or _last_geom_radius <= 0.0 or abs(r_sphere - _last_geom_radius) / _last_geom_radius >= 0.2:
			_sphere_geom_dirty = true
	if key in ["current_branch", "morph_value", "newton_path", "newton_path_bbox", "real_level_curves_highlighted", "imag_level_curves_highlighted", "effective_zoom"]:
		_update_terrain_material_uniforms(key)
	elif key == "eta_patches":
		if terrain_material:
			terrain_material.set_shader_parameter("eta_patch_count", min(64, ComplexField.eta_patches.size()))
			terrain_material.set_shader_parameter("eta_patch_centers", ComplexField.get_shader_patch_centers())
			terrain_material.set_shader_parameter("eta_patch_coeffs", ComplexField.get_shader_patch_coeffs())

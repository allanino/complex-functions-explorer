extends Node3D

@export var chunk_scene: PackedScene = preload("res://scenes/chunk.tscn")
@export var player: Node3D
@export var chunk_size: float = 32.0
@export var view_distance: int = 3

var chunks = {}
var _last_field_state = {}

@onready var sun = get_node("../DirectionalLight3D")
@onready var world_environment = get_node("../WorldEnvironment")

var _golden_hour_transition: float = 0.0

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

	# Update sun and sky for golden hour
	if Field.golden_hour:
		_golden_hour_transition = min(_golden_hour_transition + delta * 0.5, 1.0)
	else:
		_golden_hour_transition = max(_golden_hour_transition - delta * 0.5, 0.0)

	if sun:
		var target_dir = lerp(Vector3.DOWN, Vector3(-1.0, -0.1, 0.0).normalized(), _golden_hour_transition)
		sun.basis = Basis.looking_at(target_dir, Vector3.UP if abs(target_dir.normalized().y) < 0.5 else Vector3.FORWARD)
		sun.light_color = lerp(Color.WHITE, Color(1.0, 0.5, 0.2), _golden_hour_transition)
		sun.light_energy = lerp(1.0, 1.5, _golden_hour_transition)
		sun.shadow_enabled = Field.shadows_enabled

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("golden_hour_factor", _golden_hour_transition)

	# Check if any field properties have changed
	var current_field_state = {
		"iterations": Field.iterations,
		"surface_shading_mode": Field.surface_shading_mode,
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
		_last_field_state = current_field_state
		# Update uniforms in all existing chunks
		for chunk in chunks.values():
			_update_chunk_uniforms(chunk)

func _update_chunk_uniforms(chunk: MeshInstance3D):
	if chunk.material_override:
		chunk.material_override.set_shader_parameter("iterations", Field.iterations)
		chunk.material_override.set_shader_parameter("surface_shading_mode", Field.surface_shading_mode)
		chunk.material_override.set_shader_parameter("show_curves", Field.show_curves)
		chunk.material_override.set_shader_parameter("show_critical_stripe", Field.show_critical_stripe)
		chunk.material_override.set_shader_parameter("function_type", Field.function_type)
		chunk.material_override.set_shader_parameter("height_type", Field.height_type)
		chunk.material_override.set_shader_parameter("height_a", Field.height_a)
		chunk.material_override.set_shader_parameter("height_epsilon", Field.height_epsilon)
		chunk.material_override.set_shader_parameter("rational_num_coeffs", Field.rational_num_coeffs)
		chunk.material_override.set_shader_parameter("rational_den_coeffs", Field.rational_den_coeffs)

func _load_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	chunk.global_position = Vector3(coord.x * chunk_size, 0, coord.y * chunk_size)

	# Increase AABB to prevent shadow culling of displaced vertices
	# Height can go up to ~20-30 in extreme cases (Rational/Zeta spikes)
	chunk.custom_aabb = AABB(Vector3(0, -50, 0), Vector3(chunk_size, 100, chunk_size))

	# Initialize uniforms for the new chunk
	_update_chunk_uniforms(chunk)

	add_child(chunk)
	chunks[coord] = chunk

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)

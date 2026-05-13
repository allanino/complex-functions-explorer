extends Node3D

@export var chunk_scene: PackedScene = preload("res://scenes/chunk.tscn")
@export var player: Node3D
@export var chunk_size: float = 32.0
@export var view_distance: int = 4

var chunks = {}

@onready var sun = get_node("../DirectionalLight3D")
@onready var world_environment = get_node("../WorldEnvironment")

var _sunset_transition: float = 0.0

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

	# Update sun and sky for sunset
	if Field.sunset:
		_sunset_transition = min(_sunset_transition + delta * 0.5, 1.0)
	else:
		_sunset_transition = max(_sunset_transition - delta * 0.5, 0.0)

	if sun:
		var target_dir = lerp(Vector3.DOWN, Vector3(-1.0, -0.1, 0.0).normalized(), _sunset_transition)
		sun.basis = Basis.looking_at(target_dir, Vector3.FORWARD if abs(target_dir.y) < 0.99 else Vector3.UP)
		sun.light_color = lerp(Color.WHITE, Color(1.0, 0.5, 0.2), _sunset_transition)
		sun.light_energy = lerp(1.0, 1.5, _sunset_transition)

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("sunset_factor", _sunset_transition)

	# Update iterations and normal computation uniforms in all chunks
	for chunk in chunks.values():
		if chunk.material_override:
			chunk.material_override.set_shader_parameter("iterations", Field.iterations)
			chunk.material_override.set_shader_parameter("compute_normals", Field.compute_normals)
			chunk.material_override.set_shader_parameter("show_curves", Field.show_curves)
			chunk.material_override.set_shader_parameter("show_critical_stripe", Field.show_critical_stripe)
			chunk.material_override.set_shader_parameter("function_type", Field.function_type)
			chunk.material_override.set_shader_parameter("height_type", Field.height_type)
			chunk.material_override.set_shader_parameter("rational_num_coeffs", Field.rational_num_coeffs)
			chunk.material_override.set_shader_parameter("rational_den_coeffs", Field.rational_den_coeffs)

func _load_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	chunk.global_position = Vector3(coord.x * chunk_size, 0, coord.y * chunk_size)

	# Increase AABB to prevent shadow culling of displaced vertices
	# Height can go up to ~20-30 in extreme cases (Rational/Zeta spikes)
	chunk.custom_aabb = AABB(Vector3(0, -50, 0), Vector3(chunk_size, 100, chunk_size))

	add_child(chunk)
	chunks[coord] = chunk

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)

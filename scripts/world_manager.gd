extends Node3D

@export var chunk_scene: PackedScene = preload("res://scenes/chunk.tscn")
@export var player: Node3D
@export var chunk_size: float = 32.0
@export var view_distance: int = 4

var chunks = {}
var fog_volume: FogVolume

func _ready():
	fog_volume = get_node_or_null("../FogVolume")

func _process(_delta):
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

	# Update player position uniform in all chunks
	var p_pos_2d = Vector2(player_pos.x, player_pos.z)
	for chunk in chunks.values():
		if chunk.material_override:
			chunk.material_override.set_shader_parameter("player_pos", p_pos_2d)

	# Update global fog volume player position
	if fog_volume and fog_volume.material:
		fog_volume.material.set_shader_parameter("player_pos", player_pos)

func _load_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	chunk.global_position = Vector3(coord.x * chunk_size, 0, coord.y * chunk_size)
	add_child(chunk)
	chunks[coord] = chunk

func _unload_chunk(coord: Vector2i):
	var chunk = chunks[coord]
	chunk.queue_free()
	chunks.erase(coord)

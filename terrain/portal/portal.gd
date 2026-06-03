extends Node3D

var portal_frame: Node3D
var portal_ground_bar: MeshInstance3D
var portal_vert_bar: MeshInstance3D
var portal_top_bar: MeshInstance3D
var portal_end_bar: MeshInstance3D
var portal_membrane: MeshInstance3D

var portal_frame_left: Node3D
var portal_ground_bar_left: MeshInstance3D
var portal_vert_bar_left: MeshInstance3D
var portal_top_bar_left: MeshInstance3D
var portal_end_bar_left: MeshInstance3D
var portal_membrane_left: MeshInstance3D

@onready var world_manager = get_parent()

func _ready():
	_setup_portal_frame()

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

	# Membrane
	portal_membrane = MeshInstance3D.new()
	portal_membrane.mesh = QuadMesh.new()
	var membrane_mat = ShaderMaterial.new()
	membrane_mat.shader = load("res://terrain/portal/portal_membrane.gdshader")
	portal_membrane.material_override = membrane_mat
	portal_frame.add_child(portal_membrane)

	# Left portal frame for functions with cuts at x <= -1
	portal_frame_left = Node3D.new()
	portal_frame_left.name = "PortalFrameLeft"
	add_child(portal_frame_left)

	portal_ground_bar_left = MeshInstance3D.new()
	portal_ground_bar_left.mesh = BoxMesh.new()
	portal_ground_bar_left.mesh.size = Vector3(1.0, 0.2, 0.2)
	portal_ground_bar_left.material_override = mat
	portal_frame_left.add_child(portal_ground_bar_left)

	portal_vert_bar_left = MeshInstance3D.new()
	portal_vert_bar_left.mesh = BoxMesh.new()
	portal_vert_bar_left.mesh.size = Vector3(0.2, 1.0, 0.2)
	portal_vert_bar_left.material_override = mat
	portal_frame_left.add_child(portal_vert_bar_left)

	portal_top_bar_left = MeshInstance3D.new()
	portal_top_bar_left.mesh = BoxMesh.new()
	portal_top_bar_left.mesh.size = Vector3(1.0, 0.2, 0.2)
	portal_top_bar_left.material_override = mat
	portal_frame_left.add_child(portal_top_bar_left)

	portal_end_bar_left = MeshInstance3D.new()
	portal_end_bar_left.mesh = BoxMesh.new()
	portal_end_bar_left.mesh.size = Vector3(0.2, 1.0, 0.2)
	portal_end_bar_left.material_override = mat
	portal_frame_left.add_child(portal_end_bar_left)

	# Left Membrane
	portal_membrane_left = MeshInstance3D.new()
	portal_membrane_left.mesh = QuadMesh.new()
	portal_membrane_left.material_override = membrane_mat
	portal_frame_left.add_child(portal_membrane_left)

func _process(_delta):
	if not world_manager or not world_manager.player:
		return

	var player = world_manager.player
	var chunk_size = world_manager.chunk_size
	var terrain_material = world_manager.terrain_material

	var is_portal_mode = Config.function.get("is_multivalued", false)
	visible = is_portal_mode
	if portal_frame_left:
		portal_frame_left.visible = false

	if is_portal_mode:
		var zoom = GameState.effective_zoom
		var cam_h = player.global_position.y
		var p_height = max(50.0 * zoom, cam_h + 50.0 * zoom)
		var p_min_height = min(-50.0 * zoom, cam_h - 50.0 * zoom)

		var is_asin_acos = Config.function_type == Config.ComplexFunc.MULTIVALUED_ASIN or Config.function_type == Config.ComplexFunc.MULTIVALUED_ACOS

		var player_x = player.global_position.x
		var p_width = max(100.0 * zoom, abs(player_x) + float(Config.view_distance + 1) * chunk_size)

		portal_frame.scale = Vector3.ONE # We handle scaling manually on bars

		if is_asin_acos:
			var offset_x = 10.0 * zoom
			portal_frame.position = Vector3(offset_x, 0.0, 0.0)
			portal_ground_bar.scale = Vector3(p_width, zoom, zoom)
			portal_ground_bar.position = Vector3(p_width * 0.5, p_min_height, 0.0)
			portal_vert_bar.scale = Vector3(zoom, p_height - p_min_height, zoom)
			portal_vert_bar.position = Vector3(0.0, (p_height + p_min_height) * 0.5, 0.0)
			portal_top_bar.scale = Vector3(p_width, zoom, zoom)
			portal_top_bar.position = Vector3(p_width * 0.5, p_height, 0.0)
			portal_end_bar.scale = Vector3(zoom, p_height - p_min_height, zoom)
			portal_end_bar.position = Vector3(p_width, (p_height + p_min_height) * 0.5, 0.0)
			portal_membrane.scale = Vector3(p_width, p_height - p_min_height, 1.0)
			portal_membrane.position = Vector3(p_width * 0.5, (p_height + p_min_height) * 0.5, 0.0)

			if portal_frame_left:
				portal_frame_left.visible = true
				portal_frame_left.scale = Vector3.ONE
				portal_frame_left.position = Vector3(-offset_x, 0.0, 0.0)
				portal_ground_bar_left.scale = Vector3(p_width, zoom, zoom)
				portal_ground_bar_left.position = Vector3(-p_width * 0.5, p_min_height, 0.0)
				portal_vert_bar_left.scale = Vector3(zoom, p_height - p_min_height, zoom)
				portal_vert_bar_left.position = Vector3(0.0, (p_height + p_min_height) * 0.5, 0.0)
				portal_top_bar_left.scale = Vector3(p_width, zoom, zoom)
				portal_top_bar_left.position = Vector3(-p_width * 0.5, p_height, 0.0)
				portal_end_bar_left.scale = Vector3(zoom, p_height - p_min_height, zoom)
				portal_end_bar_left.position = Vector3(-p_width, (p_height + p_min_height) * 0.5, 0.0)
				portal_membrane_left.scale = Vector3(p_width, p_height - p_min_height, 1.0)
				portal_membrane_left.position = Vector3(-p_width * 0.5, (p_height + p_min_height) * 0.5, 0.0)
		else:
			portal_frame.position = Vector3(0.0, 0.0, 0.0)
			portal_ground_bar.scale = Vector3(p_width, zoom, zoom)
			portal_ground_bar.position = Vector3(-p_width * 0.5, p_min_height, 0.0)
			portal_vert_bar.scale = Vector3(zoom, p_height - p_min_height, zoom)
			portal_vert_bar.position = Vector3(0.0, (p_height + p_min_height) * 0.5, 0.0)
			portal_top_bar.scale = Vector3(p_width, zoom, zoom)
			portal_top_bar.position = Vector3(-p_width * 0.5, p_height, 0.0)
			portal_end_bar.scale = Vector3(zoom, p_height - p_min_height, zoom)
			portal_end_bar.position = Vector3(-p_width, (p_height + p_min_height) * 0.5, 0.0)
			portal_membrane.scale = Vector3(p_width, p_height - p_min_height, 1.0)
			portal_membrane.position = Vector3(-p_width * 0.5, (p_height + p_min_height) * 0.5, 0.0)

		if terrain_material:
			terrain_material.set_shader_parameter("portal_height", p_height)
			terrain_material.set_shader_parameter("portal_width", p_width)
			terrain_material.set_shader_parameter("portal_min_height", p_min_height)

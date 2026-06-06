extends AspectRatioContainer

@onready var sub_viewport = %SubViewport
@onready var minimap_camera = %MinimapCamera
@onready var fov_overlay = %FOVOverlay

var player: Node3D = null
var main_camera: Camera3D = null

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		main_camera = player.get_node_or_null("Camera3D")

	var main_viewport = get_viewport()
	sub_viewport.world_3d = main_viewport.world_3d

	fov_overlay.draw.connect(_on_fov_overlay_draw)

func _process(_delta):
	if not player or not main_camera:
		return

	var zoom = GameState.effective_zoom
	var dist = 100.0
	minimap_camera.global_position = Vector3(
		player.global_position.x,
		dist,
		player.global_position.z + dist
	)
	minimap_camera.size = 80.0 * zoom

	fov_overlay.queue_redraw()

func _on_fov_overlay_draw():
	if not player or not main_camera: return

	var center = fov_overlay.size / 2.0
	var r = min(center.x, center.y) * 0.8

	fov_overlay.draw_circle(center, 3.0, Color(1, 1, 1, 0.9))
	fov_overlay.draw_circle(center, 4.0, Color(0, 0, 0, 0.5), false, 1.0)

	var yaw = main_camera.global_rotation.y
	var fov_rad = deg_to_rad(main_camera.fov)

	var forward = Vector2(-sin(yaw), -cos(yaw))

	var left_angle = atan2(forward.y, forward.x) - fov_rad / 2.0
	var right_angle = atan2(forward.y, forward.x) + fov_rad / 2.0

	# Apply 0.7071 scale to Y to account for 45-degree orthographic foreshortening
	var p1 = center + Vector2(cos(left_angle), sin(left_angle) * 0.707106) * r
	var p2 = center + Vector2(cos(right_angle), sin(right_angle) * 0.707106) * r

	var points = PackedVector2Array([center, p1, p2])
	var colors = PackedColorArray([Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)])

	fov_overlay.draw_polygon(points, colors)
	fov_overlay.draw_line(center, p1, Color(1, 1, 1, 0.5), 1.0)
	fov_overlay.draw_line(center, p2, Color(1, 1, 1, 0.5), 1.0)

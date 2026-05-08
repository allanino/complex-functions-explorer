extends CharacterBody3D

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.002
const PLAYER_HEIGHT = 1.8

var rotation_x = 0.0

@onready var camera = $Camera3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotation_x -= event.relative.y * MOUSE_SENSITIVITY
		rotation_x = clamp(rotation_x, -PI/2, PI/2)
		camera.rotation.x = rotation_x

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func get_terrain_height(x: float, z: float) -> float:
	var theta1 = 0.15 * x + 0.12 * z
	var theta2 = 0.31 * x - 0.27 * z

	var re = cos(theta1) + 0.5 * cos(theta2)
	var im = sin(theta1) + 0.5 * sin(theta2)

	var mag = sqrt(re * re + im * im)
	return log(1.0 + mag)

func _physics_process(_delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Calculate current terrain height
	var terrain_h = get_terrain_height(global_position.x, global_position.z)

	# Snap player to terrain height
	# We use global_position for height directly to stay "attached"
	global_position.y = terrain_h

	move_and_slide()

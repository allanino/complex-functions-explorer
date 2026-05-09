extends CharacterBody3D

const SPEED = 5.0
const MOUSE_SENSITIVITY = 0.002
const PLAYER_HEIGHT = 1.8
const DOUBLE_PRESS_TIME = 0.3

var rotation_x = 0.0
var height_offset = 0.0
var last_space_time = 0.0

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

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and not event.echo:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_space_time < DOUBLE_PRESS_TIME:
			height_offset = 0.0
		last_space_time = current_time

func get_terrain_height(x: float, z: float) -> float:
	return Field.get_height(x, z)

func _physics_process(delta):
	var current_speed = SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= 2.0
	elif Input.is_key_pressed(KEY_CTRL):
		current_speed *= 0.25

	if Input.is_key_pressed(KEY_SPACE):
		height_offset += 10.0 * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Calculate current terrain height
	var terrain_h = get_terrain_height(global_position.x, global_position.z)

	# Snap player to terrain height + offset
	global_position.y = terrain_h + height_offset

	move_and_slide()

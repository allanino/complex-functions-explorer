extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.002
const DOUBLE_PRESS_TIME = 0.3
const CRITICAL_LINE_X = 5.0

enum AutoWalkState { NONE, MOVING_TO_LINE, ALIGNING, WALKING }

var rotation_x = 0.0
var auto_walk_state = AutoWalkState.NONE
var height_offset = 0.0
var last_space_time = 0.0
var space_held_time = 0.0
var is_resetting_height = false

# Zero detection history
var mag_history: Array[float] = [1.0, 1.0, 1.0]
var last_detected_t = -1.0

@onready var camera = $Camera3D

func _ready():
	# Set the global position directly using a Vector3(x, y, z)
	global_position = Vector3(5.0, 0.0, 0.0)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if auto_walk_state == AutoWalkState.NONE or auto_walk_state == AutoWalkState.WALKING:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			rotation_x -= event.relative.y * MOUSE_SENSITIVITY
			rotation_x = clamp(rotation_x, -PI/2, PI/2)
			camera.rotation.x = rotation_x

	if event.is_action_pressed("ui_cancel"):
		var hud = get_node_or_null("/root/Main/HUD")
		if hud:
			hud.toggle_menu()
		else:
			# Fallback if HUD is not found
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and not event.echo:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_space_time < DOUBLE_PRESS_TIME:
			is_resetting_height = true
		last_space_time = current_time

	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_G:
			Field.golden_hour = !Field.golden_hour
		elif event.keycode == KEY_C:
			if auto_walk_state == AutoWalkState.NONE:
				auto_walk_state = AutoWalkState.MOVING_TO_LINE
				# Reset zero counter when starting auto-walk
				Field.visited_zeros.clear()
				last_detected_t = -1.0
			else:
				auto_walk_state = AutoWalkState.NONE

func get_terrain_height(x: float, z: float) -> float:
	return Field.get_height(x, z)

func _physics_process(delta):
	if auto_walk_state != AutoWalkState.NONE:
		var manual_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if manual_input != Vector2.ZERO or Input.is_key_pressed(KEY_SPACE):
			auto_walk_state = AutoWalkState.NONE

	var current_speed = Field.movement_speed
	if auto_walk_state == AutoWalkState.NONE:
		if Input.is_key_pressed(KEY_SHIFT):
			current_speed *= 2.0
		elif Input.is_key_pressed(KEY_CTRL):
			current_speed *= 0.05

	if Input.is_key_pressed(KEY_SPACE):
		space_held_time += delta
		if space_held_time > DOUBLE_PRESS_TIME:
			is_resetting_height = false
			height_offset += 10.0 * delta
	else:
		space_held_time = 0.0

	if is_resetting_height:
		height_offset = move_toward(height_offset, 0.0, 20.0 * delta)
		if height_offset <= 0.0:
			is_resetting_height = false

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if auto_walk_state == AutoWalkState.MOVING_TO_LINE:
		var target_x = CRITICAL_LINE_X
		var diff_x = target_x - global_position.x

		if abs(diff_x) < 0.1:
			auto_walk_state = AutoWalkState.ALIGNING
			direction = Vector3.ZERO
		else:
			var walk_dir = Vector3(sign(diff_x), 0, 0)
			# Face the walk direction
			var target_angle = atan2(-walk_dir.x, -walk_dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)

			# Face camera forward (relative to player)
			rotation_x = lerp(rotation_x, 0.0, 5.0 * delta)
			camera.rotation.x = rotation_x

			direction = walk_dir

	elif auto_walk_state == AutoWalkState.ALIGNING:
		# Target is facing forward (-Z)
		var target_angle = 0.0
		rotation.y = lerp_angle(rotation.y, target_angle, 5.0 * delta)
		rotation_x = lerp(rotation_x, 0.0, 5.0 * delta)
		camera.rotation.x = rotation_x

		direction = Vector3.ZERO

		if abs(angle_difference(rotation.y, target_angle)) < 0.01 and abs(rotation_x) < 0.01:
			auto_walk_state = AutoWalkState.WALKING

	elif auto_walk_state == AutoWalkState.WALKING:
		direction = Vector3(0, 0, -1)
		global_position.x = move_toward(global_position.x, CRITICAL_LINE_X, 2.0 * delta)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Calculate current terrain height
	var terrain_h = get_terrain_height(global_position.x, global_position.z)

	# Snap player to terrain height + offset
	global_position.y = terrain_h + Field.camera_height + height_offset

	# Zeta zero detection during auto-walk
	if auto_walk_state == AutoWalkState.WALKING and Field.function_type == 0:
		var current_mag = Field.get_field(global_position.x, global_position.z).length()

		mag_history.push_back(current_mag)
		mag_history.pop_front()

		# Check for local minimum: f[1] < f[0] and f[1] < f[2]
		# We use the 3-frame approach suggested by the user.
		if mag_history[1] < mag_history[0] and mag_history[1] < mag_history[2]:
			var t = -global_position.z * 0.1 # Current t-value

			# Check if this zero is far enough from the last detected one to avoid duplicates
			# also check if the magnitude is reasonably low (e.g. < 0.5) to avoid false positives
			# from tiny oscillations far from zeros
			if abs(t - last_detected_t) > 0.1 and mag_history[1] < 0.5:
				Field.visited_zeros.push_back(t)
				last_detected_t = t

	move_and_slide()
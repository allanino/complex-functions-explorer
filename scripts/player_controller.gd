extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.002
const DOUBLE_PRESS_TIME = 0.3
const CRITICAL_LINE_X = 5.0
const AUTO_WALK_PITCH = -0.523598776 # -30 degrees in radians

enum AutoWalkState { NONE, MOVING_TO_LINE, WALKING }

var rotation_x = 0.0
var auto_walk_state = AutoWalkState.NONE
var height_offset = 0.0
var last_space_time = 0.0
var space_held_time = 0.0
var is_resetting_height = false

# Zero detection history
var mag_history: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]
var t_history: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
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
			if Config.environment_type == 1:
				Config.environment_type = 0
			else:
				Config.environment_type = 1
			Config.save_settings()
		elif event.keycode == KEY_N:
			if Config.environment_type == 2:
				Config.environment_type = 0
			else:
				Config.environment_type = 2
			Config.save_settings()
		elif event.keycode == KEY_C:
			if auto_walk_state == AutoWalkState.NONE:
				auto_walk_state = AutoWalkState.MOVING_TO_LINE
				# Reset zero counter when starting auto-walk
				Config.visited_zeros.clear()
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

	var current_speed = Config.movement_speed * Config.zoom_factor

	# Speed reduction near zeros
	var current_f = Field.get_field(global_position.x, global_position.z)
	if current_f.length() < Config.zero_threshold:
		current_speed *= (Config.speed_near_zeros / 100.0)

	if auto_walk_state != AutoWalkState.NONE:
		current_speed = min(current_speed, 50.0)

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
		var target_x = CRITICAL_LINE_X * float(Config.zoom_factor)

		var target_yaw = 0.0
		if global_position.x > 10.0 * float(Config.zoom_factor):
			target_yaw = PI/2
		elif global_position.x < 0.0:
			target_yaw = -PI/2

		# Smoothly rotate to the target yaw
		rotation.y = lerp_angle(rotation.y, target_yaw, 5.0 * delta)

		# Smoothly transition camera to horizontal
		rotation_x = lerp(rotation_x, 0.0, 5.0 * delta)
		camera.rotation.x = rotation_x

		# Smoothly move to the critical line X
		global_position.x = move_toward(global_position.x, target_x, current_speed * delta)

		direction = Vector3.ZERO

		if abs(global_position.x - target_x) < 0.01 and abs(angle_difference(rotation.y, 0.0)) < 0.01 and abs(rotation_x) < 0.01:
			auto_walk_state = AutoWalkState.WALKING

	elif auto_walk_state == AutoWalkState.WALKING:
		direction = Vector3(0, 0, -1)
		global_position.x = move_toward(global_position.x, CRITICAL_LINE_X * float(Config.zoom_factor), 2.0 * delta)

		# Smoothly transition to downward tilt only after positioning
		rotation_x = lerp(rotation_x, AUTO_WALK_PITCH, 5.0 * delta)
		camera.rotation.x = rotation_x

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Calculate current terrain height
	var terrain_h = get_terrain_height(global_position.x, global_position.z)

	# Snap player to terrain height + offset
	global_position.y = terrain_h + Config.camera_height + height_offset

	# Zeta zero detection during auto-walk
	if auto_walk_state == AutoWalkState.WALKING and (Config.function_type >= 0 and Config.function_type <= 3):
		var f = Field.get_field(global_position.x, global_position.z)
		var current_mag = f.length()

		var scale_factor = 1.0 / float(Config.zoom_factor)
		t_history.push_back(-global_position.z * 0.1 * scale_factor)
		t_history.pop_front()

		mag_history.push_back(current_mag)
		mag_history.pop_front()

		# Check for local minimum: f[0] > f[1] > f[2] < f[3] < f[4]
		if mag_history[0] > mag_history[1] and mag_history[1] > mag_history[2] and \
		   mag_history[2] < mag_history[3] and mag_history[3] < mag_history[4]:
			var t = t_history[2] # Middle value is the reported zero

			# Check if the magnitude is reasonably low (e.g. < zero_threshold) to avoid false positives
			# from tiny oscillations far from zeros
			if mag_history[2] < Config.zero_threshold:
				Config.visited_zeros.push_back(t)
				last_detected_t = t

	move_and_slide()
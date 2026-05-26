extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.002
const DOUBLE_PRESS_TIME = 0.3
const CRITICAL_LINE_X = 5.0

enum AutoWalkState { NONE, MOVING_TO_LINE, WALKING }

var rotation_x = 0.0
var auto_walk_state = AutoWalkState.NONE
var height_offset = 0.0
var last_space_time = 0.0
var space_held_time = 0.0
var is_resetting_height = false
var last_t = 0.0
var last_z: Vector2 = Vector2(0.0, 0.0)

# Zero detection history
var mag_history: Array[float] = [1.0, 1.0, 1.0]
var z_history: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.0, 0.0), Vector2(0.0, 0.0)]
var last_detected_z = Vector2(0.0, 0.0)
var current_f: Vector2 = Vector2.ZERO
var current_sigma: float = 0.0
var current_t: float = 0.0
var current_mag: float = 0.0
var current_z: Vector2 = Vector2(0.0, 0.0)

@onready var camera = $Camera3D

func _ready():
	add_to_group("player")
	# Set the global position directly using a Vector3(x, y, z)
	global_position = Vector3(5.0, 0.0, 0.0)
	var scale_factor = 1.0 / Config.effective_zoom
	last_t = -global_position.z * 0.1 * scale_factor
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# demo_actions()

func _unhandled_input(event):
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
		return

	var is_detached = false
	var hud_node = get_node_or_null("/root/Main/HUD")
	if hud_node and hud_node.detach_overlay and hud_node.detach_overlay.visible:
		is_detached = true

	if Config.morph_type != 0 or is_detached:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if auto_walk_state == AutoWalkState.NONE or auto_walk_state == AutoWalkState.WALKING:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			rotation_x -= event.relative.y * MOUSE_SENSITIVITY
			rotation_x = clamp(rotation_x, -PI/2, PI/2)
			camera.rotation.x = rotation_x

	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			Config.zoom_factor = clampf(Config.zoom_factor * 1.1, 0.01, 200.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			Config.zoom_factor = clampf(Config.zoom_factor / 1.1, 0.01, 200.0)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			Config.zoom_factor = 1.0
			Config.save_settings()


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
				last_detected_z = Vector2(0.0, 0.0)
				Config.show_hud_zeros = true
				Config.rvm_start_t = abs(global_position.z * 0.1 / Config.effective_zoom)
			else:
				auto_walk_state = AutoWalkState.NONE
		elif event.keycode == KEY_R:
			global_position.x = 0.0
			global_position.z = 0.0
			velocity = Vector3.ZERO
			auto_walk_state = AutoWalkState.NONE
			height_offset = 0.0
			is_resetting_height = false

func get_terrain_height(x: float, z: float, field_val: Vector2 = Vector2.INF) -> float:
	if field_val != Vector2.INF:
		return Field.get_height_from_field(field_val)
	return Field.get_height(x, z)

func _physics_process(delta):
	var is_detached = false
	var hud_node = get_node_or_null("/root/Main/HUD")
	if hud_node and hud_node.detach_overlay and hud_node.detach_overlay.visible:
		is_detached = true

	if Config.morph_type != 0 or is_detached:
		velocity = Vector3.ZERO
		return

	# Smooth zoom interpolation
	var old_ez = Config.effective_zoom
	Config.effective_zoom = lerp(Config.effective_zoom, float(Config.zoom_factor), delta * 8.0)
	if abs(Config.effective_zoom - Config.zoom_factor) < 0.001:
		Config.effective_zoom = float(Config.zoom_factor)

	if Config.effective_zoom != old_ez:
		var zoom_ratio = Config.effective_zoom / old_ez
		global_position.x *= zoom_ratio
		global_position.z *= zoom_ratio

		# Scale camera height and movement speed using damping power formula
		Config.camera_height = Config.camera_height * pow(zoom_ratio, Config.zoom_damping - 1.0)
		Config.movement_speed = Config.movement_speed * pow(zoom_ratio, 1.0 - Config.zoom_damping)

	# Cache current field value and mathematical coordinates for reuse
	var scale_factor = 1.0 / Config.effective_zoom
	current_sigma = global_position.x * 0.1 * scale_factor
	current_t = -global_position.z * 0.1 * scale_factor
	current_z = Vector2(current_sigma, current_t)
	current_f = Field.get_field(global_position.x, global_position.z)
	current_mag = current_f.length()

	if auto_walk_state != AutoWalkState.NONE:
		var manual_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if manual_input != Vector2.ZERO or Input.is_key_pressed(KEY_SPACE):
			auto_walk_state = AutoWalkState.NONE

	var current_speed = Config.movement_speed

	# Speed reduction near zeros
	if current_mag < Config.zero_proximity_nav:
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
			height_offset += delta * current_speed
	else:
		space_held_time = 0.0

	if is_resetting_height:
		height_offset = move_toward(height_offset, 0.0, delta * current_speed)
		if height_offset <= 0.0:
			is_resetting_height = false

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if auto_walk_state == AutoWalkState.MOVING_TO_LINE:
		var target_x = CRITICAL_LINE_X * Config.effective_zoom

		var target_yaw = 0.0
		if global_position.x > 10.0 * Config.effective_zoom:
			target_yaw = PI/2
		elif global_position.x < 0.0:
			target_yaw = -PI/2

		# Smoothly rotate to the target yaw
		rotation.y = lerp_angle(rotation.y, target_yaw, 5.0 * delta)

		# Smoothly move to the critical line X
		global_position.x = move_toward(global_position.x, target_x, current_speed * delta)

		direction = Vector3.ZERO

		if abs(global_position.x - target_x) < 0.01 and abs(angle_difference(rotation.y, 0.0)) < 0.01:
			auto_walk_state = AutoWalkState.WALKING

	elif auto_walk_state == AutoWalkState.WALKING:
		direction = Vector3(0, 0, -1)
		global_position.x = move_toward(global_position.x, CRITICAL_LINE_X * Config.effective_zoom, 2.0 * delta)

	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Calculate current terrain height using cached field
	var terrain_h = get_terrain_height(global_position.x, global_position.z, current_f)

	# Snap player to terrain height + offset
	global_position.y = terrain_h + Config.camera_height + height_offset

	# Multivalued branch crossing detection
	if Config.function.get("is_multivalued", false) and Config.multivalued_mode == 1:
		# Detect crossing of the positive real axis (sigma > 0, t=0)
		if current_sigma > 0.0:
			var branch_changed = false
			if last_z.y < 0.0 and current_z.y >= 0.0:
				# Crossed from -t to +t (counter-clockwise around origin)
				if Config.function_type == Config.ComplexFunc.MULTIVALUED_LOG:
					Config.current_branch += 1
				else:
					Config.current_branch = (Config.current_branch + 1) % Config.multivalued_n
				branch_changed = true
			elif last_z.y > 0.0 and current_z.y <= 0.0:
				# Crossed from +t to -t (clockwise around origin)
				if Config.function_type == Config.ComplexFunc.MULTIVALUED_LOG:
					Config.current_branch -= 1
				else:
					Config.current_branch = (Config.current_branch + Config.multivalued_n - 1) % Config.multivalued_n
				branch_changed = true

			if branch_changed:
				var spatial_audio = get_node_or_null("/root/Main/SpatialAudio")
				if spatial_audio and spatial_audio.has_method("play_portal_crossing"):
					spatial_audio.play_portal_crossing()

	last_z = current_z

	# Zeta zero detection during auto-walk
	if Config.show_hud_zeros:
		z_history.push_back(current_z)
		z_history.pop_front()

		mag_history.push_back(current_mag)
		mag_history.pop_front()


		# 1. First, find a basic local minimum using the 3 center points
		if mag_history[0] > mag_history[1] and mag_history[1] < mag_history[2]:
			if mag_history[1] < Config.zero_proximity_nav:

				# 2. Extract magnitudes for the parabola
				var y0 = mag_history[0]
				var y1 = mag_history[1]
				var y2 = mag_history[2]

				# Avoid division by zero if the curve is perfectly flat
				var denominator = y0 - (2.0 * y1) + y2
				if abs(denominator) > 0.0001:
					# 3. Calculate how far between points the true zero lies (-0.5 to 0.5)
					var offset_fraction = 0.5 * (y0 - y2) / denominator

					# 4. Interpolate the actual 'z' position along your path
					var z_left = z_history[0]
					var z_mid = z_history[1]
					var z_right = z_history[2]

					var true_z: Vector2
					if offset_fraction < 0:
						# True zero is between left and mid
						true_z = z_mid.lerp(z_left, -offset_fraction)
					else:
						# True zero is between mid and right
						true_z = z_mid.lerp(z_right, offset_fraction)

					if true_z.distance_to(last_detected_z) > 0.01:
						Config.visited_zeros.push_back(true_z)
						last_detected_z = true_z

	move_and_slide()


func demo_actions():
	Config.static_time = 19860
	Config.day_duration = 600.0
	Config.environment_type = 0
	Config.show_critical_stripe = 0
	Config.show_hud_zeros = false
	Config.show_hud_monitor_fps = false
	Config.show_hud_monitor_chunks = false
	Config.shadows_enabled = false
	Config.show_curves = true


	auto_walk_state = AutoWalkState.NONE
	is_resetting_height = false

	var ez = Config.effective_zoom
	global_position.x = -30.0 * ez
	global_position.z = 0.0

	rotation.y = -PI / 2.0
	rotation_x = 0.0
	camera.rotation.x = rotation_x
	height_offset = 0.0

	var tween = create_tween()

	# Wait a moment before start
	tween.tween_interval(2.0)

	var tween_duration = 5.0

	# Phase 1: go up to 50.0 while camera slowly turns downwards
	tween.tween_property(self, "height_offset", 50.0 * ez, tween_duration)
	tween.parallel().tween_property(camera, "rotation:x", -PI / 2.0, tween_duration)

	# Phase 2: rotate CCW while tilting upwards to face zeta wall towards -sigma
	tween.tween_property(self, "rotation:y", PI / 2.0, tween_duration)
	tween.parallel().tween_property(camera, "rotation:x", 0.0, tween_duration)

	# Phase 3: height decrease to 3.5 while rotating towards +sigma
	tween.tween_property(self, "height_offset", 3.5 * ez, tween_duration)

	# Phase 4: walk backwards to see the trivial zero at (-2, 0)
	tween.tween_property(camera, "rotation:x", -PI / 2.0, tween_duration * 0.6)
	tween.parallel().tween_property(self, "global_position:x", -20.0 * ez, tween_duration * 0.6)

	# Wait a moment to contemplate the trivial zero
	tween.tween_interval(2.0)

	# Phase 5: rotate towards the pole and walk slightly to its side
	# Math coordinates (1, 1) -> x = 10.0 * ez, z = -10.0 * ez
	tween.tween_property(camera, "rotation:x", PI / 8.0, tween_duration)
	tween.parallel().tween_property(self, "rotation:y", - PI / 2.0, tween_duration)

	tween.tween_property(self, "global_position:x", 5.0 * ez, tween_duration)
	tween.parallel().tween_property(self, "global_position:z", -10.0 * ez, tween_duration)

	tween.parallel().tween_property(camera, "rotation:x", - PI / 8.0, tween_duration)

	# Wait a moment to contemplate the sunrise
	tween.tween_interval(2.0)

	# Phase 6: rotate back to horizontal and start auto-walk
	tween.tween_property(self, "rotation:y", 0.0, tween_duration * 0.5)
	tween.parallel().tween_property(camera, "rotation:x",  - PI / 8.0, tween_duration)

	tween.tween_interval(1.0)

	tween.tween_callback(self._start_auto_walk_from_demo)

func _start_auto_walk_from_demo():
	auto_walk_state = AutoWalkState.MOVING_TO_LINE
	Config.visited_zeros.clear()
	last_detected_z = Vector2(0.0, 0.0)
	Config.show_hud_zeros = true
	Config.show_critical_stripe = true
	Config.rvm_start_t = abs(global_position.z * 0.1 / Config.effective_zoom)

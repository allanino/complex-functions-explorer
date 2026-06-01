extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.002
const DOUBLE_PRESS_TIME = 0.3
const CRITICAL_LINE_X = 5.0

enum AutoWalkState {NONE, MOVING_TO_LINE, WALKING}

var rotation_x = 0.0
var auto_walk_state = AutoWalkState.NONE
var re_label: Label3D
var im_label: Label3D
var _curve_label_update_timer = 0.1
const CURVE_LABEL_UPDATE_INTERVAL = 0.1
var _re_label_target_pos: Vector3 = Vector3.ZERO
var _im_label_target_pos: Vector3 = Vector3.ZERO

var height_offset = 0.0
var last_space_time = 0.0
var space_held_time = 0.0
var is_resetting_height = false
var last_t = 0.0
var last_z: Vector2 = Vector2(0.0, 0.0)
var last_valid_terrain_height: float = 0.0
var is_detached_interactive: bool = false
var is_menu_open: bool = false

# Zero detection history
var mag_history: Array[float] = [1.0, 1.0, 1.0]
var z_history: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(0.0, 0.0), Vector2(0.0, 0.0)]
var last_detected_z = Vector2(0.0, 0.0)
var current_f: Vector2 = Vector2.ZERO
var current_mag: float = 0.0
var current_z: Vector2 = Vector2(0.0, 0.0)

@onready var camera = $Camera3D

@onready var main_ui = get_node_or_null("/root/Main/MainUI")
@onready var world_manager = get_node_or_null("/root/Main/WorldManager")
@onready var audio_system = get_node_or_null("/root/Main/Audio")

func _ready():
	add_to_group("player")
	# Set the global position directly using a Vector3(x, y, z)
	global_position = Vector3(5.0, 0.0, 0.0)
	var scale_factor = 1.0 / Config.effective_zoom
	last_t = - global_position.z * 0.1 * scale_factor
	last_z = Vector2(global_position.x * 0.1 * scale_factor, -global_position.z * 0.1 * scale_factor)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_f = ComplexField.get_field(global_position.x, global_position.z)
	current_mag = current_f.length()
	
	re_label = Label3D.new()
	re_label.text = "Re"
	re_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	re_label.no_depth_test = true
	re_label.fixed_size = true
	re_label.pixel_size = 0.0025
	re_label.font_size = 36
	re_label.outline_size = 2
	re_label.modulate = Color(0.12, 0.12, 0.12, 1.0)
	re_label.outline_modulate = Color(0.12, 0.12, 0.12, 1.0)
	re_label.outline_render_priority = 0
	re_label.top_level = true
	re_label.visible = false
	add_child(re_label)

	im_label = Label3D.new()
	im_label.text = "Im"
	im_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	im_label.no_depth_test = true
	im_label.fixed_size = true
	im_label.pixel_size = 0.0025
	im_label.font_size = 36
	im_label.outline_size = 2
	im_label.modulate = Color(0.9, 0.9, 0.9, 1.0)
	im_label.outline_modulate = Color(0.9, 0.9, 0.9, 1.0)
	im_label.outline_render_priority = 0
	im_label.top_level = true
	im_label.visible = false
	add_child(im_label)


	# demo_actions()

func _update_ui_states():
	if main_ui:
		if main_ui.detach_controller and main_ui.detach_controller.visible and main_ui.detach_controller.interaction_active:
			is_detached_interactive = true
		else:
			is_detached_interactive = false
		if main_ui.menu_overlay and main_ui.menu_overlay.visible:
			is_menu_open = true
		else:
			is_menu_open = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if main_ui:
			main_ui.toggle_menu()
		else:
			# Fallback if MainUI is not found
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	
	_update_ui_states()

	if is_detached_interactive or is_menu_open:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if auto_walk_state == AutoWalkState.NONE or auto_walk_state == AutoWalkState.WALKING:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			rotation_x -= event.relative.y * MOUSE_SENSITIVITY
			rotation_x = clamp(rotation_x, -PI / 2, PI / 2)
			camera.rotation.x = rotation_x

	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			Config.zoom_factor = clampf(Config.zoom_factor * 1.1, 0.01, 200.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			Config.zoom_factor = clampf(Config.zoom_factor / 1.1, 0.01, 200.0)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			Config.zoom_factor = 1.0
			Config.save_settings()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Config.show_curves:
				# If close to a real curve level, push or toggle it in the list capped at 10
				var closest_curve_real = round(current_f.x)
				if abs(current_f.x - closest_curve_real) < 0.1:
					if closest_curve_real in Config.real_level_curves_highlighted:
						Config.real_level_curves_highlighted.erase(closest_curve_real)
					else:
						Config.real_level_curves_highlighted.append(closest_curve_real)
						if Config.real_level_curves_highlighted.size() > 10:
							Config.real_level_curves_highlighted.pop_front()
					# Set shader parameter to highlight this curve
					if world_manager and world_manager.has_method("_update_terrain_material_uniforms"):
						world_manager._update_terrain_material_uniforms()

					print(Config.real_level_curves_highlighted)

				var closest_curve_imag = round(current_f.y)
				if abs(current_f.y - closest_curve_imag) < 0.1:
					if closest_curve_imag in Config.imag_level_curves_highlighted:
						Config.imag_level_curves_highlighted.erase(closest_curve_imag)
					else:
						Config.imag_level_curves_highlighted.append(closest_curve_imag)
						if Config.imag_level_curves_highlighted.size() > 10:
							Config.imag_level_curves_highlighted.pop_front()
					# Set shader parameter to highlight this curve
					if world_manager and world_manager.has_method("_update_terrain_material_uniforms"):
						world_manager._update_terrain_material_uniforms()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if Config.show_curves:
				Config.real_level_curves_highlighted.clear()
				Config.imag_level_curves_highlighted.clear()
				if world_manager and world_manager.has_method("_update_terrain_material_uniforms"):
					world_manager._update_terrain_material_uniforms()
					

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and not event.echo:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_space_time < DOUBLE_PRESS_TIME:
			is_resetting_height = true
		last_space_time = current_time

	if event is InputEventKey and event.pressed and event.ctrl_pressed:
		if event.keycode == KEY_G:
			Config.freeze_time = true
			Config.day_time = 22740
			Config.save_settings()
		elif event.keycode == KEY_N:
			Config.freeze_time = false
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
			Config.current_branch = 0
			current_f = ComplexField.get_field(global_position.x, global_position.z)
			current_mag = current_f.length()
			
			# Immediately update the shader's branch uniform
			if world_manager and world_manager.has_method("_update_terrain_material_uniforms"):
				world_manager._update_terrain_material_uniforms()

func get_terrain_height(x: float, z: float, field_val: Vector2 = Vector2.INF) -> float:
	if field_val != Vector2.INF:
		return ComplexField.get_height_from_field(field_val)
	return ComplexField.get_height(x, z)

func _physics_process(delta):
	_update_ui_states()

	if is_detached_interactive or is_menu_open:
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
	var current_x = global_position.x * 0.1 * scale_factor
	var current_y = - global_position.z * 0.1 * scale_factor
	current_z = Vector2(current_x, current_y)
	current_f = ComplexField.get_field(global_position.x, global_position.z)
	current_mag = current_f.length()

	if auto_walk_state != AutoWalkState.NONE:
		var manual_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if manual_input != Vector2.ZERO or Input.is_key_pressed(KEY_SPACE):
			auto_walk_state = AutoWalkState.NONE

	var current_speed = Config.movement_speed

	# Speed reduction near zeros
	if current_mag <= Config.zero_proximity_nav and Config.zero_proximity_nav > 0.0:
		# The multiplicative factor goes from 1.0 to speed_near_zeros back to 1.0 if walking in line
		current_speed = Config.movement_speed * max(current_mag / Config.zero_proximity_nav, Config.speed_near_zeros / 100.0)

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
			target_yaw = PI / 2
		elif global_position.x < 0.0:
			target_yaw = - PI / 2

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

	var is_field_valid = is_finite(current_f.x) and is_finite(current_f.y) and is_finite(current_mag)
	if not is_field_valid or not is_finite(terrain_h):
		terrain_h = last_valid_terrain_height
	else:
		last_valid_terrain_height = terrain_h

	# Snap player to terrain height + offset
	global_position.y = terrain_h + Config.camera_height + height_offset


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
	Config.day_time = 19860
	Config.day_duration = 600.0
	Config.freeze_time = false
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

	rotation.y = - PI / 2.0
	rotation_x = 0.0
	camera.rotation.x = rotation_x
	height_offset = 0.0

	var tween = create_tween()

	# Wait a moment before start
	tween.tween_interval(2.0)

	var tween_duration = 5.0

	# Phase 1: go up to 50.0 while camera slowly turns downwards
	tween.tween_property(self , "height_offset", 50.0 * ez, tween_duration)
	tween.parallel().tween_property(camera, "rotation:x", -PI / 2.0, tween_duration)

	# Phase 2: rotate CCW while tilting upwards to face zeta wall towards -x
	tween.tween_property(self , "rotation:y", PI / 2.0, tween_duration)
	tween.parallel().tween_property(camera, "rotation:x", 0.0, tween_duration)

	# Phase 3: height decrease to 3.5 while rotating towards +x
	tween.tween_property(self , "height_offset", 3.5 * ez, tween_duration)

	# Phase 4: walk backwards to see the trivial zero at (-2, 0)
	tween.tween_property(camera, "rotation:x", -PI / 2.0, tween_duration * 0.6)
	tween.parallel().tween_property(self , "global_position:x", -20.0 * ez, tween_duration * 0.6)

	# Wait a moment to contemplate the trivial zero
	tween.tween_interval(2.0)

	# Phase 5: rotate towards the pole and walk slightly to its side
	# Math coordinates (1, 1) -> x = 10.0 * ez, z = -10.0 * ez
	tween.tween_property(camera, "rotation:x", PI / 8.0, tween_duration)
	tween.parallel().tween_property(self , "rotation:y", -PI / 2.0, tween_duration)

	tween.tween_property(self , "global_position:x", 5.0 * ez, tween_duration)
	tween.parallel().tween_property(self , "global_position:z", -10.0 * ez, tween_duration)

	tween.parallel().tween_property(camera, "rotation:x", -PI / 8.0, tween_duration)

	# Wait a moment to contemplate the sunrise
	tween.tween_interval(2.0)

	# Phase 6: rotate back to horizontal and start auto-walk
	tween.tween_property(self , "rotation:y", 0.0, tween_duration * 0.5)
	tween.parallel().tween_property(camera, "rotation:x", -PI / 8.0, tween_duration)

	tween.tween_interval(1.0)

	tween.tween_callback(self._start_auto_walk_from_demo)

func _start_auto_walk_from_demo():
	auto_walk_state = AutoWalkState.MOVING_TO_LINE
	Config.visited_zeros.clear()
	last_detected_z = Vector2(0.0, 0.0)
	Config.show_hud_zeros = true
	Config.show_critical_stripe = true
	Config.rvm_start_t = abs(global_position.z * 0.1 / Config.effective_zoom)

func _process(_delta):
	if is_menu_open or is_detached_interactive:
		current_f = ComplexField.get_field(global_position.x, global_position.z)
		current_mag = current_f.length()

	var scale_factor = 1.0 / Config.effective_zoom
	var current_x = global_position.x * 0.1 * scale_factor
	var current_y = - global_position.z * 0.1 * scale_factor
	var frame_z = Vector2(current_x, current_y)

	# If player teleported (e.g. reset, demo actions, or function change),
	# bypass crossing detection to prevent false branch jumping.
	if last_z.distance_to(frame_z) > 2.0:
		last_z = frame_z

	if Config.function.get("is_multivalued", false):
		var branch_changed = false
		if Config.function_type == Config.ComplexFunc.MULTIVALUED_ASIN or Config.function_type == Config.ComplexFunc.MULTIVALUED_ACOS:
			# Portals at x >= 1.0 and x <= -1.0
			if (last_z.y < 0.0 and frame_z.y >= 0.0) or (last_z.y > 0.0 and frame_z.y <= 0.0): # crossing the real axis
				if frame_z.x >= 1.0:
					var is_even = (Config.current_branch % 2 == 0)
					Config.current_branch += 1 if is_even else -1
					branch_changed = true
				elif frame_z.x <= -1.0:
					var is_even = (Config.current_branch % 2 == 0)
					Config.current_branch += -1 if is_even else 1
					branch_changed = true
		else:
			# Detect crossing of the negative real axis (x < 0, t=0)
			if frame_z.x < 0.0:
				if last_z.y < 0.0 and frame_z.y >= 0.0:
					# Crossed from -t to +t (counter-clockwise around origin)
					# Under negative cut, this DECREASES the branch index.
					if Config.function_type == Config.ComplexFunc.MULTIVALUED_LOG:
						Config.current_branch -= 1
					else:
						Config.current_branch = (Config.current_branch + Config.multivalued_n - 1) % Config.multivalued_n
					branch_changed = true
				elif last_z.y > 0.0 and frame_z.y <= 0.0:
					# Crossed from +t to -t (clockwise around origin)
					# Under negative cut, this INCREASES the branch index.
					if Config.function_type == Config.ComplexFunc.MULTIVALUED_LOG:
						Config.current_branch += 1
					else:
						Config.current_branch = (Config.current_branch + 1) % Config.multivalued_n
					branch_changed = true

		if branch_changed:
			if audio_system and audio_system.has_method("play_portal_crossing"):
				audio_system.play_portal_crossing()


			# Play the screen-space flash transition effect
			if main_ui and main_ui.has_method("play_portal_flash"):
				main_ui.play_portal_flash()

			# Immediately update the shader's branch uniform to prevent 1-frame rendering lag
			if world_manager and world_manager.has_method("_update_terrain_material_uniforms"):
				world_manager._update_terrain_material_uniforms()

	last_z = frame_z

	# Always snap player height to the terrain in _process to prevent camera judder/shaking,
	# especially when crossing branches.
	var terrain_h = get_terrain_height(global_position.x, global_position.z, current_f)

	# if the function result is not finite, the player will fall into the void
	# use the last valid height to keep the player in the air
	var is_field_valid = is_finite(current_f.x) and is_finite(current_f.y) and is_finite(current_mag)
	if not is_field_valid or not is_finite(terrain_h):
		terrain_h = last_valid_terrain_height
	else:
		last_valid_terrain_height = terrain_h

	global_position.y = terrain_h + Config.camera_height + height_offset


	if Config.show_curves and Config.show_curves_labels:
		_curve_label_update_timer += _delta
		if _curve_label_update_timer >= CURVE_LABEL_UPDATE_INTERVAL:
			_curve_label_update_timer = 0.0
			
			# Find the closest real and imaginary integer curves in the direction we are facing
			var cam_dir = - camera.global_transform.basis.z
			var step_size = 1.0 * Config.effective_zoom
			var max_steps = 30
			var re_found = false
			var im_found = false

			var last_val = current_f
			var last_p_x = global_position.x
			var last_p_z = global_position.z

			var re_was_visible = re_label.visible
			var im_was_visible = im_label.visible

			re_label.visible = false
			im_label.visible = false

			for i in range(1, max_steps):
				var dist = i * step_size
				var p_x = global_position.x + cam_dir.x * dist
				var p_z = global_position.z + cam_dir.z * dist
				var f_val = ComplexField.get_field(p_x, p_z)

				if not re_found:
					if floor(last_val.x) != floor(f_val.x):
						var target_int = floor(f_val.x) if f_val.x > last_val.x else ceil(f_val.x)
						var denominator = f_val.x - last_val.x
						var t = 0.5
						if abs(denominator) > 0.0001:
							t = (target_int - last_val.x) / denominator
						t = clamp(t, 0.0, 1.0)
						
						var cross_x = lerp(last_p_x, p_x, t)
						var cross_z = lerp(last_p_z, p_z, t)
						var cross_f = lerp(last_val, f_val, t)
						var h = get_terrain_height(cross_x, cross_z, cross_f)
						
						var target_pos = Vector3(cross_x, h + 1.0, cross_z)
						if not re_was_visible:
							re_label.global_position = target_pos
						_re_label_target_pos = target_pos
						
						re_label.text = str(int(target_int))
						re_label.visible = true
						re_found = true

				if not im_found:
					if floor(last_val.y) != floor(f_val.y):
						var target_int = floor(f_val.y) if f_val.y > last_val.y else ceil(f_val.y)
						var denominator = f_val.y - last_val.y
						var t = 0.5
						if abs(denominator) > 0.0001:
							t = (target_int - last_val.y) / denominator
						t = clamp(t, 0.0, 1.0)
						
						var cross_x = lerp(last_p_x, p_x, t)
						var cross_z = lerp(last_p_z, p_z, t)
						var cross_f = lerp(last_val, f_val, t)
						var h = get_terrain_height(cross_x, cross_z, cross_f)
						
						var target_pos = Vector3(cross_x, h + 1.0, cross_z)
						if not im_was_visible:
							im_label.global_position = target_pos
						_im_label_target_pos = target_pos
						
						im_label.text = str(int(target_int)) + "𝑖"
						im_label.visible = true
						im_found = true

				if re_found and im_found:
					break
				last_val = f_val
				last_p_x = p_x
				last_p_z = p_z

		# Smoothly slide labels towards target positions
		if re_label.visible:
			re_label.global_position = re_label.global_position.lerp(_re_label_target_pos, _delta * 10.0)
		if im_label.visible:
			im_label.global_position = im_label.global_position.lerp(_im_label_target_pos, _delta * 10.0)
	else:
		if re_label:
			re_label.visible = false
		if im_label:
			im_label.visible = false

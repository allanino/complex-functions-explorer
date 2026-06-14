extends BaseTest

var player_scene = preload("res://player/player.tscn")
var ui_scene = preload("res://ui/main_ui.tscn")

func before_all():
	super.before_all()

	Config.zoom_factor = 1.0
	Config.zoom_damping = 0.5

func before_each():
	super.before_each()
	GameState.is_menu_open = false
	GameState.is_detached_interactive = false

func test_player_loads_and_physics_process_runs():
	var player = player_scene.instantiate()
	player.set("run_demo", false)
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)
	
	# Manually link main_ui to player for the test
	player.set("main_ui", main_ui)
	main_ui.player = player
	
	# Trigger physics process to verify it doesn't crash
	player._physics_process(0.016)
	
	# Also trigger unhandled input event handler to verify no crash there
	var event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	player._unhandled_input(event)
	
	assert_not_null(player)

func test_player_movement_disabled_when_menu_open():
	var player = player_scene.instantiate()
	player.set("run_demo", false)
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)
	
	player.set("main_ui", main_ui)
	main_ui.player = player
	
	# Open menu
	main_ui.menu_overlay.visible = true
	GameState.is_menu_open = true
	player.velocity = Vector3(10, 0, 10)
	
	# Run physics process
	player._physics_process(0.016)
	
	# Velocity should be reset to zero and physics process should return early
	assert_eq(player.velocity, Vector3.ZERO)

func test_detached_slider_esc_toggle():
	var player = player_scene.instantiate()
	player.set("run_demo", false)
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)
	
	player.set("main_ui", main_ui)
	main_ui.player = player
	
	# Enter detached mode
	main_ui.detach_controller.visible = true
	main_ui.detach_controller.interaction_active = true
	GameState.is_detached_interactive = true
	
	# 1. While in Interaction mode, movement should be disabled
	player.velocity = Vector3(10, 0, 10)
	player._physics_process(0.016)
	assert_eq(player.velocity, Vector3.ZERO)
	
	# 2. Toggle to Movement mode via ESC simulation
	main_ui.toggle_menu()
	
	assert_false(main_ui.detach_controller.interaction_active)
	
	# 3. While in Movement mode, movement should be enabled (physics process executes and updates current_f)
	player.current_f = Vector2.ZERO
	player._physics_process(0.016)
	assert_ne(player.current_f, Vector2.ZERO)
	
	# 4. Toggle back to Interaction mode
	main_ui.toggle_menu()
	assert_true(main_ui.detach_controller.interaction_active)
	
	# 5. Verify movement is disabled again
	player.velocity = Vector3(10, 0, 10)
	player._physics_process(0.016)
	assert_eq(player.velocity, Vector3.ZERO)

func test_curve_labels_throttled_update():
	# 1. Enable curve and label settings
	var original_show_curves = Config.show_curves
	var original_show_curves_labels = Config.show_curves_labels
	var original_function_type = Config.function_type
	Config.show_curves = true
	Config.show_curves_labels = true
	Config.function_type = Config.ComplexFunc.IDENTITY

	var player = player_scene.instantiate()
	player.set("run_demo", false)
	add_child_autoqfree(player)
		
	# Verify labels start visible is false (until updated)
	assert_false(player.re_label.visible)
	assert_false(player.im_label.visible)
	
	# Set player position and orientation (facing -Z)
	player.global_position = Vector3(0.0, 0.0, 0.0)
	player.rotation = Vector3.ZERO
	player._physics_process(0.016)

	# 2. Call _physics_process once. Force update by setting timer to interval.
	player._curve_label_update_timer = player.CURVE_LABEL_UPDATE_INTERVAL
	player._physics_process(0.016)
	
	# Since we are at origin and facing -Z under identity:
	# Real part is x, Imaginary part is y.
	# Marching along -Z means x remains 0, while z goes negative (imaginary part y goes positive).
	# So we should find imaginary crossings (since y = -z/10 goes up) but no real crossings (since x = 0).
	assert_true(player.im_label.visible)
	assert_false(player.re_label.visible)
	assert_almost_eq(player._curve_label_update_timer, 0.0, 0.001)
	
	# 3. Call _physics_process again with small delta. It should not update the labels (timer goes up but doesn't reach threshold)
	player.im_label.visible = false # Manually hide to verify it's not set to true
	player._physics_process(0.016)
	assert_false(player.im_label.visible)
	assert_almost_eq(player._curve_label_update_timer, 0.016, 0.001)
	
	# 4. Call _physics_process with a delta large enough to cross the threshold, and verify it snaps on first visible transition
	player._curve_label_update_timer = player.CURVE_LABEL_UPDATE_INTERVAL
	player._physics_process(0.016)
	assert_true(player.im_label.visible)
	assert_almost_eq(player._curve_label_update_timer, 0.0, 0.001)
	var start_pos = player.im_label.global_position
 
	# 5. Move player past the first curve (to z = -11.0) and verify it slides smoothly (lerps) instead of snapping
	player.global_position = Vector3(0.0, 0.0, -11.0)
	player._physics_process(0.016)
	player._curve_label_update_timer = player.CURVE_LABEL_UPDATE_INTERVAL # Force throttled update to run on next frame
	player._physics_process(0.016) # Run update to find new target
	player._process(0.016) # Run lerp with 0.016 delta
	
	var target_pos = player._im_label_target_pos
	assert_true(start_pos.distance_to(target_pos) > 0.001) # Target should have shifted to next curve (e.g. z = -20)
	assert_true(player.im_label.global_position.distance_to(target_pos) > 0.001) # It should not have snapped instantly
	assert_true(player.im_label.global_position.distance_to(target_pos) < start_pos.distance_to(target_pos)) # It should be moving towards the target

	# Restore Config settings
	Config.show_curves = original_show_curves
	Config.show_curves_labels = original_show_curves_labels
	Config.function_type = original_function_type

func test_player_max_world_height_limit():
	var player = player_scene.instantiate()
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)
	
	player.set("main_ui", main_ui)
	main_ui.player = player

	var original_show_curves = Config.show_curves
	var original_show_curves_labels = Config.show_curves_labels
	var original_function_type = Config.function_type
	var original_height_type = Config.height_type
	Config.show_curves = false
	Config.show_curves_labels = false
	Config.function_type = Config.ComplexFunc.IDENTITY
	Config.height_type = 0 # absolute magnitude

	# Set morph value and zoom to 1.0 so that height is exactly complex position magnitude
	GameState.morph_value = 1.0
	GameState.effective_zoom = 1.0

	# 1. Below limit: height is 990 (< 1000)
	player.global_position = Vector3(9900.0, 0.0, 0.0)
	player.last_player_pos = Vector3(9800.0, 0.0, 0.0)
	# Set a high velocity (higher than current_speed of 25.0) to prevent it from decaying to 0
	player.velocity = Vector3(100.0, 0.0, 0.0)
	
	player._physics_process(0.016)

	# Should decay but NOT be zeroed
	assert_gt(player.velocity.x, 0.0)

	# 2. Above limit: height is 1005 (>= 1000)
	player.global_position = Vector3(10050.0, 0.0, 0.0)
	player.last_terrain_h = 999.0 # lower than terrain height to simulate moving uphill
	player.last_player_pos = Vector3(9950.0, 0.0, 0.0)

	# Try to move uphill (velocity in positive X)
	player.velocity = Vector3(100.0, 0.0, 0.0)
	player._physics_process(0.016)

	# Velocity should be zeroed
	assert_eq(player.velocity.x, 0.0)
	assert_eq(player.velocity.z, 0.0)

	# Try to move downhill (velocity in negative X)
	player.global_position = Vector3(10050.0, 0.0, 0.0)
	player.last_terrain_h = 1010.0 # higher than terrain height to simulate moving downhill
	player.last_player_pos = Vector3(10150.0, 0.0, 0.0)
	player.velocity = Vector3(-100.0, 0.0, 0.0)
	player._physics_process(0.016)

	# Velocity should decay but not be zeroed (negative velocity allowed)
	assert_lt(player.velocity.x, 0.0)

	# Restore Config settings
	Config.show_curves = original_show_curves
	Config.show_curves_labels = original_show_curves_labels
	Config.function_type = original_function_type
	Config.height_type = original_height_type


func test_player_zoom_scaling():
	var player = player_scene.instantiate()
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)

	player.set("main_ui", main_ui)
	main_ui.player = player

	var original_zoom_factor = Config.zoom_factor
	var original_zoom_damping = Config.zoom_damping
	var original_ez = GameState.effective_zoom

	Config.zoom_factor = 1.0
	Config.zoom_damping = 0.5
	GameState.effective_zoom = 1.0

	GameState.is_menu_open = false
	GameState.is_detached_interactive = false
	player.global_position = Vector3(10.0, 0.0, 10.0)
	player._physics_process(0.016)

	var initial_height_scale = player.zoom_height_scale
	var initial_speed_scale = player.zoom_speed_scale

	Config.zoom_factor = 2.0
	for i in range(10):
		player._physics_process(0.016)

	var new_complex = Config.world_to_complex(player.global_position.x, player.global_position.z)
	assert_almost_eq(1.0, new_complex.x, 0.001)
	assert_almost_eq(-1.0, new_complex.y, 0.001)

	assert_almost_eq(player.zoom_height_scale, initial_height_scale * pow(GameState.effective_zoom, Config.zoom_damping - 1.0), 0.001)
	assert_almost_eq(player.zoom_speed_scale, initial_speed_scale * pow(GameState.effective_zoom, 1.0 - Config.zoom_damping), 0.001)

	Config.zoom_factor = original_zoom_factor
	Config.zoom_damping = original_zoom_damping
	GameState.effective_zoom = original_ez

func test_start_newton_walk():
	var player = player_scene.instantiate()
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)

	player.set("main_ui", main_ui)
	main_ui.player = player

	var original_function_type = Config.function_type
	Config.function_type = Config.ComplexFunc.IDENTITY

	player.global_position = Vector3(10.0, 0.0, 10.0)
	player.auto_walk_state = player.AutoWalkState.NONE

	GameState.newton_path.clear()

	player.start_newton_walk()

	assert_eq(player.auto_walk_state, player.AutoWalkState.NEWTON_WALK)
	assert_true(Config.show_hud_zeros)
	assert_false(player.newton_converged)
	assert_gt(GameState.newton_path.size(), 1)

	# The identity function f(z) = z has root at 0. Newton step goes exactly to 0 in one step.
	var final_z = GameState.newton_path[GameState.newton_path.size() - 1]
	assert_almost_eq(final_z.x, 0.0, 0.001)
	assert_almost_eq(final_z.y, 0.0, 0.001)

	# Verify it does nothing if not in NONE state
	player.auto_walk_state = player.AutoWalkState.WALKING
	GameState.newton_path.clear()
	player.start_newton_walk()
	assert_eq(player.auto_walk_state, player.AutoWalkState.WALKING)
	assert_eq(GameState.newton_path.size(), 0)

	Config.function_type = original_function_type

func test_zeta_stability_check():
	var player = player_scene.instantiate()
	add_child_autoqfree(player)

	var original_function_type = Config.function_type
	Config.function_type = Config.ComplexFunc.ZETA

	# With 10 iterations at y=100.0, the calculation is unstable
	Config.iterations = 10
	GameState.unstable_zeta_computation = true
	player._check_zeta_stability(100.0)
	assert_true(GameState.unstable_zeta_computation)

	#  With 1000 iterations at y=100.0, the calculation is stable
	Config.iterations = 1000
	GameState.unstable_zeta_computation = false
	player._check_zeta_stability(100.0)
	assert_false(GameState.unstable_zeta_computation)

	#  With 1000 iterations at y=5000.0, the calculation is unstable
	Config.iterations = 1000
	GameState.unstable_zeta_computation = true
	player._check_zeta_stability(5000.0)
	assert_true(GameState.unstable_zeta_computation)

	# At high y and iters, it is unstable.
	Config.iterations = 10000
	GameState.unstable_zeta_computation = false
	player._check_zeta_stability(40000.0)
	assert_true(GameState.unstable_zeta_computation)

	Config.function_type = original_function_type

extends GutTest

var player_scene = preload("res://player/player.tscn")
var ui_scene = preload("res://ui/main_ui.tscn")

func test_player_loads_and_physics_process_runs():
	var player = player_scene.instantiate()
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)
	
	# Manually link main_ui to player for the test
	player.main_ui = main_ui
	
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
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)
	
	player.main_ui = main_ui
	
	# Open menu
	main_ui.menu_overlay.visible = true
	player.velocity = Vector3(10, 0, 10)
	
	# Run physics process
	player._physics_process(0.016)
	
	# Velocity should be reset to zero and physics process should return early
	assert_eq(player.velocity, Vector3.ZERO)

func test_detached_slider_esc_toggle():
	var player = player_scene.instantiate()
	var main_ui = ui_scene.instantiate()
	add_child_autoqfree(player)
	add_child_autoqfree(main_ui)
	
	player.main_ui = main_ui
	
	# Enter detached mode
	main_ui.detach_controller.visible = true
	main_ui.detach_controller.interaction_active = true
	
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
	add_child_autoqfree(player)
	
	# Set player position and orientation (facing -Z)
	player.global_position = Vector3(0.0, 0.0, 0.0)
	player.rotation = Vector3.ZERO
	player._physics_process(0.016)
	
	# Verify labels start visible is false (until updated)
	assert_false(player.re_label.visible)
	assert_false(player.im_label.visible)
	
	# 2. Call _process once. Force update by setting timer to interval.
	player._curve_label_update_timer = player.CURVE_LABEL_UPDATE_INTERVAL
	player._process(0.016)
	
	# Since we are at origin and facing -Z under identity:
	# Real part is x, Imaginary part is y.
	# Marching along -Z means x remains 0, while z goes negative (imaginary part y goes positive).
	# So we should find imaginary crossings (since y = -z/10 goes up) but no real crossings (since x = 0).
	assert_true(player.im_label.visible)
	assert_false(player.re_label.visible)
	assert_eq(player._curve_label_update_timer, 0.0)
	
	# 3. Call _process again with small delta. It should not update the labels (timer goes up but doesn't reach threshold)
	player.im_label.visible = false # Manually hide to verify it's not set to true
	player._process(0.016)
	assert_false(player.im_label.visible)
	assert_eq(player._curve_label_update_timer, 0.016)
	
	# 4. Call _process with a delta large enough to cross the threshold, and verify it snaps on first visible transition
	player._curve_label_update_timer = player.CURVE_LABEL_UPDATE_INTERVAL
	player._process(0.016)
	assert_true(player.im_label.visible)
	assert_eq(player._curve_label_update_timer, 0.0)
	var start_pos = player.im_label.global_position
 
	# 5. Move player past the first curve (to z = -11.0) and verify it slides smoothly (lerps) instead of snapping
	player.global_position = Vector3(0.0, 0.0, -11.0)
	player._physics_process(0.016)
	player._curve_label_update_timer = player.CURVE_LABEL_UPDATE_INTERVAL # Force throttled update to run on next frame
	player._process(0.016) # Run update and lerp with 0.016 delta
	
	var target_pos = player._im_label_target_pos
	assert_ne(start_pos, target_pos) # Target should have shifted to next curve (e.g. z = -20)
	assert_ne(player.im_label.global_position, target_pos) # It should not have snapped instantly
	assert_true(player.im_label.global_position.distance_to(target_pos) < start_pos.distance_to(target_pos)) # It should be moving towards the target

	# Restore Config settings
	Config.show_curves = original_show_curves
	Config.show_curves_labels = original_show_curves_labels
	Config.function_type = original_function_type

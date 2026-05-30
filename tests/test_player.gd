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

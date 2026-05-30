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

extends BaseTest

var main_ui_scene = preload("res://ui/main_ui.tscn")
var main_ui_instance

func before_all():
	super.before_all()

func after_all():
	super.after_all()

func before_each():
	# Reset Config singleton to a known clean state before every test
	Config._edited_presets.clear()
	Config.current_preset = "Default"
	Config.apply_preset("Default")
	main_ui_instance = main_ui_scene.instantiate()
	add_child_autoqfree(main_ui_instance)

func test_parse_complex():
	assert_eq(FormulaParser.parse_complex(""), Vector2.ZERO)
	assert_eq(FormulaParser.parse_complex("1"), Vector2(1, 0))
	assert_eq(FormulaParser.parse_complex("-1"), Vector2(-1, 0))
	assert_eq(FormulaParser.parse_complex("i"), Vector2(0, 1))
	assert_eq(FormulaParser.parse_complex("-i"), Vector2(0, -1))
	assert_eq(FormulaParser.parse_complex("1+i"), Vector2(1, 1))
	assert_eq(FormulaParser.parse_complex("1-i"), Vector2(1, -1))
	assert_eq(FormulaParser.parse_complex("-1+i"), Vector2(-1, 1))
	assert_eq(FormulaParser.parse_complex("-1-i"), Vector2(-1, -1))
	assert_eq(FormulaParser.parse_complex("2+3i"), Vector2(2, 3))
	assert_eq(FormulaParser.parse_complex("2 - 3i"), Vector2(2, -3)) # handles spaces
	assert_eq(FormulaParser.parse_complex("4.5+1.2i"), Vector2(4.5, 1.2))
	assert_eq(FormulaParser.parse_complex("2i"), Vector2(0, 2))
	assert_eq(FormulaParser.parse_complex("-2i"), Vector2(0, -2))

func test_parse_poly():
	var res1 = FormulaParser.parse_poly("1")
	assert_eq(res1[0], Vector2(1, 0))
	assert_eq(res1[1], Vector2(0, 0))

	var res2 = FormulaParser.parse_poly("z")
	assert_eq(res2[0], Vector2(0, 0))
	assert_eq(res2[1], Vector2(1, 0))

	var res3 = FormulaParser.parse_poly("2z")
	assert_eq(res3[0], Vector2(0, 0))
	assert_eq(res3[1], Vector2(2, 0))

	var res4 = FormulaParser.parse_poly("z^2 + 2z + 1")
	assert_eq(res4[0], Vector2(1, 0))
	assert_eq(res4[1], Vector2(2, 0))
	assert_eq(res4[2], Vector2(1, 0))

	var res5 = FormulaParser.parse_poly("(1+i)z^2 - iz + 2-i")
	assert_eq(res5[0], Vector2(2, -1))

	var res7 = FormulaParser.parse_poly("(1+i)z^2 - iz + 2-i")
	assert_eq(res7[0], Vector2(2, -1))
	assert_eq(res7[1], Vector2(0, -1))
	assert_eq(res7[2], Vector2(1, 1))
	assert_eq(res5[1], Vector2(0, -1))
	assert_eq(res5[2], Vector2(1, 1))

	var res6 = FormulaParser.parse_poly("z^3 - z^3")
	assert_eq(res6[3], Vector2(0, 0))

func test_format_time():
	assert_eq(main_ui_instance._format_time(0.0), "00:00:00")
	assert_eq(main_ui_instance._format_time(60.0), "00:01:00")
	assert_eq(main_ui_instance._format_time(3600.0), "01:00:00")
	assert_eq(main_ui_instance._format_time(3661.0), "01:01:01")
	assert_eq(main_ui_instance._format_time(86399.0), "23:59:59")
	assert_eq(main_ui_instance._format_time(86400.0), "24:00:00")

func test_zoom_to_slider_and_back():
	var test_zooms = [0.01, 1.0, 10.0, 100.0, 200.0]
	for z in test_zooms:
		var slider_val = main_ui_instance._zoom_to_slider(z)
		var back_z = main_ui_instance._slider_to_zoom(slider_val)
		assert_almost_eq(back_z, z, 0.001)

	var test_sliders = [0.0, 25.0, 50.0, 75.0, 100.0]
	for s in test_sliders:
		var z_val = main_ui_instance._slider_to_zoom(s)
		var back_s = main_ui_instance._zoom_to_slider(z_val)
		assert_almost_eq(back_s, s, 0.001)

func test_get_rvm_n():
	var orig_func = Config.function_type

	# Test T <= 0.1
	assert_eq(main_ui_instance._get_rvm_n(0.05), 0.0)

	# Test Zeta function
	Config.function_type = Config.ComplexFunc.ZETA_CONTINUATION
	var T_zeta = 14.134725
	var rvm_zeta = main_ui_instance._get_rvm_n(T_zeta)
	var expected_zeta = (T_zeta / (2.0 * PI)) * (log(T_zeta / (2.0 * PI)) - 1.0) + 7.0 / 8.0
	assert_almost_eq(rvm_zeta, expected_zeta, 0.001)

	# Test Dirichlet Beta function
	Config.function_type = Config.ComplexFunc.DIRICHLET_BETA
	var T_beta = 10.0
	var rvm_beta = main_ui_instance._get_rvm_n(T_beta)
	var expected_beta = (T_beta / (2.0 * PI)) * (log((4.0 * T_beta) / (2.0 * PI)) - 1.0)
	assert_almost_eq(rvm_beta, expected_beta, 0.001)

	Config.function_type = orig_func

func test_preset_ui_asterisk_workflow():
	var orig_preset = Config.current_preset
	
	# Ensure starting clean
	Config.apply_preset("Default")
	main_ui_instance.preset_controller.update_preset_button_text()
	assert_false(Config.is_preset_dirty())
	assert_false(main_ui_instance.preset_controller.preset_button.get_item_text(main_ui_instance.preset_controller.preset_button.selected).ends_with("*"))

	# Change a slider value to make it dirty
	main_ui_instance.menu_overlay.brightness_slider.value = 100.0
	main_ui_instance.menu_overlay._on_generic_slider_changed(main_ui_instance.menu_overlay.brightness_slider, 100.0)
	main_ui_instance.preset_controller.update_preset_button_text()
	
	assert_true(Config.is_preset_dirty())
	assert_true(main_ui_instance.preset_controller.preset_button.get_item_text(main_ui_instance.preset_controller.preset_button.selected).ends_with("*"))

	# Create a new preset
	main_ui_instance.preset_controller.new_preset_input.text = "MyNewUI_Preset"
	main_ui_instance.preset_controller._on_new_preset_save_pressed()
	
	# Verify that the new preset is active and has no asterisk
	assert_eq(Config.current_preset, "MyNewUI_Preset")
	assert_false(Config.is_preset_dirty())
	var selected_text = main_ui_instance.preset_controller.preset_button.get_item_text(main_ui_instance.preset_controller.preset_button.selected)
	assert_eq(selected_text, "MyNewUI_Preset")
	assert_false(selected_text.ends_with("*"))
	
	# Modify setting to 50.0
	main_ui_instance.menu_overlay.brightness_slider.value = 50.0
	main_ui_instance.menu_overlay._on_generic_slider_changed(main_ui_instance.menu_overlay.brightness_slider, 50.0)
	main_ui_instance.preset_controller.update_preset_button_text()
	
	assert_true(Config.is_preset_dirty())
	assert_true(main_ui_instance.preset_controller.preset_button.get_item_text(main_ui_instance.preset_controller.preset_button.selected).ends_with("*"))
	
	# Switch to Mysterious, making MyNewUI_Preset a dirty cached preset
	Config.apply_preset("Mysterious")
	main_ui_instance.preset_controller.update_preset_button_text()
	
	# Verify that Mysterious is selected and not dirty
	assert_eq(Config.current_preset, "Mysterious")
	assert_false(Config.is_preset_dirty())
	assert_false(main_ui_instance.preset_controller.preset_button.get_item_text(main_ui_instance.preset_controller.preset_button.selected).ends_with("*"))
	
	# Verify that MyNewUI_Preset in the dropdown list STILL has the asterisk
	var idx = -1
	for i in range(main_ui_instance.preset_controller.preset_button.item_count):
		if main_ui_instance.preset_controller.preset_button.get_item_text(i).trim_suffix("*") == "MyNewUI_Preset":
			idx = i
			break
	assert_ne(idx, -1)
	assert_true(main_ui_instance.preset_controller.preset_button.get_item_text(idx).ends_with("*"))
	
	# Switch back to MyNewUI_Preset
	Config.apply_preset("MyNewUI_Preset")
	main_ui_instance.preset_controller.update_preset_button_text()
	assert_true(Config.is_preset_dirty())
	assert_true(main_ui_instance.preset_controller.preset_button.get_item_text(main_ui_instance.preset_controller.preset_button.selected).ends_with("*"))
	
	# Save it
	main_ui_instance.preset_controller._on_preset_update_pressed()
	assert_false(Config.is_preset_dirty())
	var saved_text = main_ui_instance.preset_controller.preset_button.get_item_text(main_ui_instance.preset_controller.preset_button.selected)
	assert_eq(saved_text, "MyNewUI_Preset")
	assert_false(saved_text.ends_with("*"))

	# Cleanup
	Config.delete_preset("MyNewUI_Preset")
	Config.apply_preset(orig_preset)

func test_preset_ui_close_without_apply():
	Config.apply_preset("Default")
	main_ui_instance.preset_controller.update_preset_button_text()

	# Open menu (saves initial preset state)
	main_ui_instance.menu_overlay.toggle_menu(false)
	assert_true(main_ui_instance.menu_overlay.visible)

	# Change preset to Mysterious in the UI
	var mysterious_idx = -1
	for i in range(main_ui_instance.preset_controller.preset_button.item_count):
		if main_ui_instance.preset_controller.preset_button.get_item_text(i).trim_suffix("*") == "Mysterious":
			mysterious_idx = i
			break

	assert_ne(mysterious_idx, -1)
	main_ui_instance.preset_controller._on_preset_selected(mysterious_idx)

	assert_eq(Config.current_preset, "Mysterious")

	# Close menu without applying
	main_ui_instance.menu_overlay.toggle_menu(false)
	assert_false(main_ui_instance.menu_overlay.visible)

	# Assert it's reverted
	assert_eq(Config.current_preset, "Default")

func test_menu_scale():
	# 1. Verify parent hierarchy remains CenterContainer
	var parent = main_ui_instance.menu_overlay.main_menu_panel.get_parent()
	assert_not_null(parent)
	assert_true(parent is CenterContainer)

	# 2. Verify main_menu_panel.scale is always Vector2.ONE
	assert_eq(main_ui_instance.menu_overlay.main_menu_panel.scale, Vector2.ONE)
	
	# 3. Verify initial scaled layout size matches config menu_scale * base scale factor (130/150)
	var expected_scale = Config.menu_scale
	var base_panel_min_size = Vector2(1000, 500)
	assert_eq(main_ui_instance.menu_overlay.main_menu_panel.custom_minimum_size, base_panel_min_size * expected_scale)
	
	# 4. Simulate dragging:
	var hslider = main_ui_instance.menu_overlay.menu_scale_slider.get_slider()
	assert_not_null(hslider)
	
	# Start drag
	hslider.drag_started.emit()
	assert_true(main_ui_instance.menu_overlay._menu_scale_dragging)
	
	# Set value to something new
	var target_scale = 120.0 / 100.0
	main_ui_instance.menu_overlay.menu_scale_slider.value = 120.0

	# Config value should be updated, but layout size should not change while dragging
	assert_eq(Config.menu_scale, target_scale)
	assert_eq(main_ui_instance.menu_overlay.main_menu_panel.custom_minimum_size, base_panel_min_size * expected_scale)
	
	# End drag
	hslider.drag_ended.emit(true)
	assert_false(main_ui_instance.menu_overlay._menu_scale_dragging)
	var target_menu_scale = target_scale
	assert_eq(main_ui_instance.menu_overlay.main_menu_panel.custom_minimum_size, base_panel_min_size * target_menu_scale)
	
	# Verify font size override was applied
	var title_label = main_ui_instance.menu_overlay.main_menu_panel.get_node("%TitleLabel")
	assert_not_null(title_label)
	var base_font_size = title_label.get_meta("base_font_size")
	assert_eq(title_label.get_theme_font_size("font_size"), int(round(base_font_size * target_menu_scale)))

func test_detached_slider_play_loop():
	var source_slider = HSlider.new()
	source_slider.min_value = 0.0
	source_slider.max_value = 10.0
	source_slider.value = 0.0
	source_slider.step = 0.1
	add_child_autoqfree(source_slider)

	var source_label = Label.new()
	source_label.text = "0.0"
	add_child_autoqfree(source_label)

	var dc = main_ui_instance.detach_controller
	dc.detach_slider_control(source_slider, source_label, "Test Slider")

	assert_false(dc.is_playing)
	assert_eq(dc.play_button.text, "▶")

	# Press play
	dc.play_button.pressed.emit()
	assert_true(dc.is_playing)
	assert_eq(dc.play_button.text, "■")
	assert_eq(dc.play_direction, 1.0)

	# Simulate process for 1 second.
	# speed = range / 5.0 = 10.0 / 5.0 = 2.0 units per second.
	# value starts at 0.0. After 1 second, it should be 2.0.
	dc._process(1.0)
	assert_almost_eq(dc.detach_slider.value, 2.0, 0.001)
	assert_almost_eq(source_slider.value, 2.0, 0.001)

	# Simulating enough seconds to go past max_value (e.g. 4 more seconds -> 10.0 total, clamped and reversed).
	dc._process(4.0)
	assert_eq(dc.detach_slider.value, 10.0)
	assert_eq(dc.play_direction, -1.0)

	# Moving backwards. 1 second of -1.0 * 2.0 speed = -2.0.
	dc._process(1.0)
	assert_almost_eq(dc.detach_slider.value, 8.0, 0.001)

	# Move all the way back to min
	dc._process(4.0)
	assert_eq(dc.detach_slider.value, 0.0)
	assert_eq(dc.play_direction, 1.0)

	# Press play to stop
	dc.play_button.pressed.emit()
	assert_false(dc.is_playing)
	assert_eq(dc.play_button.text, "▶")

	# If playing is true and we exit detach, it should stop
	dc.play_button.pressed.emit()
	assert_true(dc.is_playing)
	
	# Simulate gamepad X button (Play/Stop toggle)
	var ev_x = InputEventJoypadButton.new()
	ev_x.button_index = JOY_BUTTON_X
	ev_x.pressed = true
	dc._input(ev_x)
	assert_false(dc.is_playing) # Toggled off
	
	# Simulate gamepad B button (Close/Exit detach)
	var ev_b = InputEventJoypadButton.new()
	ev_b.button_index = JOY_BUTTON_B
	ev_b.pressed = true
	dc._input(ev_b)
	assert_false(dc.visible)

	# Simulate gamepad R3 button (Right Stick Click) to toggle interaction mode
	var ev_r3 = InputEventJoypadButton.new()
	ev_r3.button_index = JOY_BUTTON_RIGHT_STICK
	ev_r3.pressed = true

	# Open detach slider back up
	dc.detach_slider_control(source_slider, source_label, "Test Slider")
	assert_true(dc.interaction_active)
	assert_true(GameState.is_detached_interactive)

	# Press R3 -> Interaction should turn OFF (camera move mode enabled)
	dc._input(ev_r3)
	assert_false(dc.interaction_active)
	assert_false(GameState.is_detached_interactive)

	# Press R3 again -> Interaction should turn ON (pointer control mode enabled)
	dc._input(ev_r3)
	assert_true(dc.interaction_active)
	assert_true(GameState.is_detached_interactive)


	# Clean up
	dc.visible = false
	GameState.is_detached_interactive = false


func test_branch_k_slider_ranges():
	# Test MULTIVALUED_Z_POW (range 0 to n-1)
	Config.multivalued_n = 3
	main_ui_instance.menu_overlay._on_func_selected(Config.ComplexFunc.MULTIVALUED_Z_POW)
	assert_true(main_ui_instance.menu_overlay.branch_k_slider.visible)
	assert_eq(main_ui_instance.menu_overlay.branch_k_slider.min_value, 0.0)
	assert_eq(main_ui_instance.menu_overlay.branch_k_slider.max_value, 2.0)
	
	# Test MULTIVALUED_LOG (range -5 to 5)
	main_ui_instance.menu_overlay._on_func_selected(Config.ComplexFunc.MULTIVALUED_LOG)
	assert_true(main_ui_instance.menu_overlay.branch_k_slider.visible)
	assert_eq(main_ui_instance.menu_overlay.branch_k_slider.min_value, -5.0)
	assert_eq(main_ui_instance.menu_overlay.branch_k_slider.max_value, 5.0)
	
	# Test non-multivalued function (hidden)
	main_ui_instance.menu_overlay._on_func_selected(Config.ComplexFunc.ZETA_CONTINUATION)
	assert_false(main_ui_instance.menu_overlay.branch_k_slider.visible)

func test_line_edit_dead_key_circumflex_handling():
	var text_input = main_ui_instance.menu_overlay.func_rational_container
	var line_edit = main_ui_instance.menu_overlay.func_rational_input
	assert_not_null(line_edit)
	
	# Verify that the _process method runs without throwing
	text_input._process(0.016)

func test_menu_gamepad_navigation():
	var menu = main_ui_instance.menu_overlay
	# Test opening menu
	menu.toggle_menu(false)
	assert_true(menu.visible)
	assert_true(menu.is_processing())
	
	# Verify that HSliders and CheckBoxes have FOCUS_NONE by default (D-pad focus disabled)
	assert_eq(menu.iter_slider.get_slider().focus_mode, Control.FOCUS_NONE)
	assert_eq(menu.curves_checkbox.get_node("Control/CheckBox").focus_mode, Control.FOCUS_NONE)
	# Verify that tab buttons are FOCUS_NONE
	assert_eq(menu.func_tab_button.focus_mode, Control.FOCUS_NONE)

	# Simulate joypad A button press (which clicks at current mouse position)
	var ev = InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_A
	ev.pressed = true
	menu._input(ev)
	
	# Simulate joypad L1/R1 shoulder button tab switching
	# Start at tab 0. Press R1 (Right shoulder) -> switches to tab 1.
	var ev_r1 = InputEventJoypadButton.new()
	ev_r1.button_index = JOY_BUTTON_RIGHT_SHOULDER
	ev_r1.pressed = true
	menu._input(ev_r1)
	assert_eq(menu.tab_container.current_tab, 1)
	
	# Press L1 (Left shoulder) -> switches back to tab 0.
	var ev_l1 = InputEventJoypadButton.new()
	ev_l1.button_index = JOY_BUTTON_LEFT_SHOULDER
	ev_l1.pressed = true
	menu._input(ev_l1)
	assert_eq(menu.tab_container.current_tab, 0)

	# Simulate joypad B button press (Cancel without saving)
	var ev_cancel = InputEventJoypadButton.new()
	ev_cancel.button_index = JOY_BUTTON_B
	ev_cancel.pressed = true
	menu._input(ev_cancel)

	assert_false(menu.visible)
	assert_false(menu.is_processing())

func test_menu_dropdown_popup_input_handling():
	var menu = main_ui_instance.menu_overlay
	menu.toggle_menu(false)
	assert_true(menu.visible)

	# Simulate opening a popup on func_button
	var popup = menu.func_button.get_popup()
	popup.visible = true
	assert_eq(menu._get_open_popup(), popup)

	# Pressing JOY_BUTTON_B (Circle) should close the popup, not the main menu overlay
	var ev_cancel = InputEventJoypadButton.new()
	ev_cancel.button_index = JOY_BUTTON_B
	ev_cancel.pressed = true
	popup.emit_signal("window_input", ev_cancel)
	
	assert_false(popup.visible)
	assert_true(menu.visible) # Main menu is still open!

	# Open it again
	popup.visible = true
	
	# Set a focused item index
	popup.set_focused_item(1)
	
	# Connect to item_selected to verify OptionButton gets updated
	var context = {"selected_index": - 1}
	var on_selected = func(idx): context["selected_index"] = idx
	menu.func_button.item_selected.connect(on_selected)

	# Pressing JOY_BUTTON_A (Cross) should activate index 1 and close the popup
	var ev_select = InputEventJoypadButton.new()
	ev_select.button_index = JOY_BUTTON_A
	ev_select.pressed = true
	popup.emit_signal("window_input", ev_select)

	assert_eq(context["selected_index"], 1)
	assert_false(popup.visible)
	assert_true(menu.visible)
	
	# Clean up signal
	menu.func_button.item_selected.disconnect(on_selected)

	# Now pressing JOY_BUTTON_B should close the main menu overlay
	menu._input(ev_cancel)
	assert_false(menu.visible)

func test_menu_hovered_slider_gamepad_adjustments():
	var menu = main_ui_instance.menu_overlay
	menu.toggle_menu(false)
	assert_true(menu.visible)

	var slider = menu.iter_slider.get_slider()
	slider.value = 1000.0

	# Simulate hover
	menu._hovered_slider = slider
	assert_eq(menu._hovered_slider, slider)

	# Simulate D-pad Right (dpad_right)
	var ev_right = InputEventAction.new()
	ev_right.action = "dpad_right"
	ev_right.pressed = true
	menu._input(ev_right)
	assert_eq(slider.value, 1100.0) # step is 100.0

	# Simulate D-pad Left (dpad_left)
	var ev_left = InputEventAction.new()
	ev_left.action = "dpad_left"
	ev_left.pressed = true
	menu._input(ev_left)
	assert_eq(slider.value, 1000.0)

	# Simulate Left Analog/D-pad action (dpad_right) to verify it increments step-by-step
	var ev_analog_right = InputEventAction.new()
	ev_analog_right.action = "dpad_right"
	ev_analog_right.pressed = true
	menu._input(ev_analog_right)
	assert_eq(slider.value, 1100.0)

	# Simulate Joypad Motion (JOY_AXIS_LEFT_X = 0.6)
	var ev_motion_right = InputEventJoypadMotion.new()
	ev_motion_right.axis = JOY_AXIS_LEFT_X
	ev_motion_right.axis_value = 0.6
	menu._input(ev_motion_right)
	assert_eq(slider.value, 1200.0)

	# Simulate holding Joypad Motion (JOY_AXIS_LEFT_X = 0.7) - value should NOT change
	var ev_motion_right_hold = InputEventJoypadMotion.new()
	ev_motion_right_hold.axis = JOY_AXIS_LEFT_X
	ev_motion_right_hold.axis_value = 0.7
	menu._input(ev_motion_right_hold)
	assert_eq(slider.value, 1200.0)

	# Simulate returning to neutral (JOY_AXIS_LEFT_X = 0.1) - value should NOT change
	var ev_motion_neutral = InputEventJoypadMotion.new()
	ev_motion_neutral.axis = JOY_AXIS_LEFT_X
	ev_motion_neutral.axis_value = 0.1
	menu._input(ev_motion_neutral)
	assert_eq(slider.value, 1200.0)

	# Simulate pushing right again (JOY_AXIS_LEFT_X = 0.6) - value should change
	menu._input(ev_motion_right)
	assert_eq(slider.value, 1300.0)

	# Clean up hover
	menu._hovered_slider = null

func test_menu_unhovered_slider_preset_toggle():
	var menu = main_ui_instance.menu_overlay
	menu.toggle_menu(false)
	assert_true(menu.visible)

	menu._hovered_slider = null
	menu.last_submitted_func = Config.ComplexFunc.ZETA_CONTINUATION
	menu.current_submitted_func = Config.ComplexFunc.DIRICHLET_ETA_CONTINUATION
	Config.function_type = Config.ComplexFunc.DIRICHLET_ETA_CONTINUATION

	# Simulate dpad_left action while not hovering a slider
	var ev_left = InputEventAction.new()
	ev_left.action = "dpad_left"
	ev_left.pressed = true
	menu._input(ev_left)

	# It should toggle Config.function_type to last_submitted_func (ZETA_CONTINUATION)
	assert_eq(Config.function_type, Config.ComplexFunc.ZETA_CONTINUATION)

	# Simulate dpad_right action while not hovering a slider
	var ev_right = InputEventAction.new()
	ev_right.action = "dpad_right"
	ev_right.pressed = true
	menu._input(ev_right)

	# It should toggle Config.function_type back to DIRICHLET_ETA_CONTINUATION
	assert_eq(Config.function_type, Config.ComplexFunc.DIRICHLET_ETA_CONTINUATION)

func test_menu_closed_preset_toggle():
	var menu = main_ui_instance.menu_overlay
	if menu.visible:
		menu.toggle_menu(false)
	assert_false(menu.visible)

	menu.last_submitted_func = Config.ComplexFunc.ZETA_CONTINUATION
	menu.current_submitted_func = Config.ComplexFunc.DIRICHLET_ETA_CONTINUATION
	Config.function_type = Config.ComplexFunc.DIRICHLET_ETA_CONTINUATION

	# Simulate dpad_left action when menu is closed
	var ev_left = InputEventAction.new()
	ev_left.action = "dpad_left"
	ev_left.pressed = true
	menu._input(ev_left)

	assert_eq(Config.function_type, Config.ComplexFunc.ZETA_CONTINUATION)

	# Simulate dpad_right action when menu is closed
	var ev_right = InputEventAction.new()
	ev_right.action = "dpad_right"
	ev_right.pressed = true
	menu._input(ev_right)

	assert_eq(Config.function_type, Config.ComplexFunc.DIRICHLET_ETA_CONTINUATION)



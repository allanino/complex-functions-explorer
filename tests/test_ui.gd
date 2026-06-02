extends GutTest

var hud_scene = preload("res://ui/main_ui.tscn")
var hud_instance
var _original_save_path: String
var _has_backup: bool = false

func before_all():
	_original_save_path = Config.save_path
	Config.save_path = "user://test_ui_settings.cfg"
	
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("test_ui_settings.cfg"):
			dir.remove("test_ui_settings.cfg")
		
		# Back up production settings.cfg if it exists
		if dir.file_exists("settings.cfg"):
			var err = dir.copy("user://settings.cfg", "user://settings.cfg.bak")
			if err == OK:
				_has_backup = true
				
	# Load clean/empty test settings so the singleton starts fresh
	Config.load_settings()
	# Restore PRESETS to built-ins only (in case previous session saved custom presets)
	Config.PRESETS = Config.PRESET_DEFAULTS.PRESETS.duplicate(true)

func after_all():
	# Remove the temporary test settings file
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("test_ui_settings.cfg"):
			dir.remove("test_ui_settings.cfg")
			
		# Restore original settings.cfg
		if _has_backup:
			if dir.file_exists("settings.cfg"):
				dir.remove("settings.cfg")
			dir.rename("user://settings.cfg.bak", "user://settings.cfg")
			
	# Restore path and reload production settings
	Config.save_path = _original_save_path
	Config.load_settings()

func before_each():
	# Reset Config singleton to a known clean state before every test
	Config._edited_presets.clear()
	Config.current_preset = "Default"
	Config.apply_preset("Default")
	hud_instance = hud_scene.instantiate()
	add_child_autoqfree(hud_instance)

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
	assert_eq(hud_instance._format_time(0.0), "00:00:00")
	assert_eq(hud_instance._format_time(60.0), "00:01:00")
	assert_eq(hud_instance._format_time(3600.0), "01:00:00")
	assert_eq(hud_instance._format_time(3661.0), "01:01:01")
	assert_eq(hud_instance._format_time(86399.0), "23:59:59")
	assert_eq(hud_instance._format_time(86400.0), "24:00:00")

func test_zoom_to_slider_and_back():
	var test_zooms = [0.01, 1.0, 10.0, 100.0, 200.0]
	for z in test_zooms:
		var slider_val = hud_instance._zoom_to_slider(z)
		var back_z = hud_instance._slider_to_zoom(slider_val)
		assert_almost_eq(back_z, z, 0.001)

	var test_sliders = [0.0, 25.0, 50.0, 75.0, 100.0]
	for s in test_sliders:
		var z_val = hud_instance._slider_to_zoom(s)
		var back_s = hud_instance._zoom_to_slider(z_val)
		assert_almost_eq(back_s, s, 0.001)

func test_get_rvm_n():
	var orig_func = Config.function_type

	# Test T <= 0.1
	assert_eq(hud_instance._get_rvm_n(0.05), 0.0)

	# Test Zeta function
	Config.function_type = Config.ComplexFunc.ZETA
	var T_zeta = 14.134725
	var rvm_zeta = hud_instance._get_rvm_n(T_zeta)
	var expected_zeta = (T_zeta / (2.0 * PI)) * (log(T_zeta / (2.0 * PI)) - 1.0) + 7.0 / 8.0
	assert_almost_eq(rvm_zeta, expected_zeta, 0.001)

	# Test Dirichlet Beta function
	Config.function_type = Config.ComplexFunc.DIRICHLET_BETA
	var T_beta = 10.0
	var rvm_beta = hud_instance._get_rvm_n(T_beta)
	var expected_beta = (T_beta / (2.0 * PI)) * (log((4.0 * T_beta) / (2.0 * PI)) - 1.0)
	assert_almost_eq(rvm_beta, expected_beta, 0.001)

	Config.function_type = orig_func

func test_preset_ui_asterisk_workflow():
	var orig_preset = Config.current_preset
	
	# Ensure starting clean
	Config.apply_preset("Default")
	hud_instance.preset_controller.update_preset_button_text()
	assert_false(Config.is_preset_dirty())
	assert_false(hud_instance.preset_controller.preset_button.get_item_text(hud_instance.preset_controller.preset_button.selected).ends_with("*"))

	# Change a slider value to make it dirty
	hud_instance.menu_overlay.brightness_slider.value = 100.0
	hud_instance.menu_overlay._on_generic_slider_changed(hud_instance.menu_overlay.brightness_slider, 100.0)
	hud_instance.preset_controller.update_preset_button_text()
	
	assert_true(Config.is_preset_dirty())
	assert_true(hud_instance.preset_controller.preset_button.get_item_text(hud_instance.preset_controller.preset_button.selected).ends_with("*"))

	# Create a new preset
	hud_instance.preset_controller.new_preset_input.text = "MyNewUI_Preset"
	hud_instance.preset_controller._on_new_preset_save_pressed()
	
	# Verify that the new preset is active and has no asterisk
	assert_eq(Config.current_preset, "MyNewUI_Preset")
	assert_false(Config.is_preset_dirty())
	var selected_text = hud_instance.preset_controller.preset_button.get_item_text(hud_instance.preset_controller.preset_button.selected)
	assert_eq(selected_text, "MyNewUI_Preset")
	assert_false(selected_text.ends_with("*"))
	
	# Modify setting to 50.0
	hud_instance.menu_overlay.brightness_slider.value = 50.0
	hud_instance.menu_overlay._on_generic_slider_changed(hud_instance.menu_overlay.brightness_slider, 50.0)
	hud_instance.preset_controller.update_preset_button_text()
	
	assert_true(Config.is_preset_dirty())
	assert_true(hud_instance.preset_controller.preset_button.get_item_text(hud_instance.preset_controller.preset_button.selected).ends_with("*"))
	
	# Switch to Mysterious, making MyNewUI_Preset a dirty cached preset
	Config.apply_preset("Mysterious")
	hud_instance.preset_controller.update_preset_button_text()
	
	# Verify that Mysterious is selected and not dirty
	assert_eq(Config.current_preset, "Mysterious")
	assert_false(Config.is_preset_dirty())
	assert_false(hud_instance.preset_controller.preset_button.get_item_text(hud_instance.preset_controller.preset_button.selected).ends_with("*"))
	
	# Verify that MyNewUI_Preset in the dropdown list STILL has the asterisk
	var idx = -1
	for i in range(hud_instance.preset_controller.preset_button.item_count):
		if hud_instance.preset_controller.preset_button.get_item_text(i).trim_suffix("*") == "MyNewUI_Preset":
			idx = i
			break
	assert_ne(idx, -1)
	assert_true(hud_instance.preset_controller.preset_button.get_item_text(idx).ends_with("*"))
	
	# Switch back to MyNewUI_Preset
	Config.apply_preset("MyNewUI_Preset")
	hud_instance.preset_controller.update_preset_button_text()
	assert_true(Config.is_preset_dirty())
	assert_true(hud_instance.preset_controller.preset_button.get_item_text(hud_instance.preset_controller.preset_button.selected).ends_with("*"))
	
	# Save it
	hud_instance.preset_controller._on_preset_update_pressed()
	assert_false(Config.is_preset_dirty())
	var saved_text = hud_instance.preset_controller.preset_button.get_item_text(hud_instance.preset_controller.preset_button.selected)
	assert_eq(saved_text, "MyNewUI_Preset")
	assert_false(saved_text.ends_with("*"))

	# Cleanup
	Config.delete_preset("MyNewUI_Preset")
	Config.apply_preset(orig_preset)

func test_menu_scale():
	# 1. Verify parent hierarchy remains CenterContainer
	var parent = hud_instance.menu_overlay.main_menu_panel.get_parent()
	assert_not_null(parent)
	assert_true(parent is CenterContainer)

	# 2. Verify main_menu_panel.scale is always Vector2.ONE
	assert_eq(hud_instance.menu_overlay.main_menu_panel.scale, Vector2.ONE)
	
	# 3. Verify initial scaled layout size matches config menu_scale * base scale factor (130/150)
	var expected_scale = Config.menu_scale * (130.0 / 150.0)
	var base_panel_min_size = Vector2(1000, 780)
	assert_eq(hud_instance.menu_overlay.main_menu_panel.custom_minimum_size, base_panel_min_size * expected_scale)
	
	# 4. Simulate dragging:
	var hslider = hud_instance.menu_overlay.menu_scale_slider.get_slider()
	assert_not_null(hslider)
	
	# Start drag
	hslider.drag_started.emit()
	assert_true(hud_instance.menu_overlay._menu_scale_dragging)
	
	# Set value to something new
	var target_scale = 120.0 / 100.0
	hud_instance.menu_overlay.menu_scale_slider.value = 120.0

	# Config value should be updated, but layout size should not change while dragging
	assert_eq(Config.menu_scale, target_scale)
	assert_eq(hud_instance.menu_overlay.main_menu_panel.custom_minimum_size, base_panel_min_size * expected_scale)
	
	# End drag
	hslider.drag_ended.emit(true)
	assert_false(hud_instance.menu_overlay._menu_scale_dragging)
	var target_menu_scale = target_scale * (130.0 / 150.0)
	assert_eq(hud_instance.menu_overlay.main_menu_panel.custom_minimum_size, base_panel_min_size * target_menu_scale)
	
	# Verify font size override was applied
	var title_label = hud_instance.menu_overlay.main_menu_panel.get_node("MarginContainer/ContentVBox/TitleHBox/TitleLabel")
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

	var dc = hud_instance.detach_controller
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
	dc._on_exit_detach_pressed()
	assert_false(dc.is_playing)
	assert_eq(dc.play_button.text, "▶")

func test_branch_k_slider_ranges():
	# Test MULTIVALUED_Z_POW (range 0 to n-1)
	Config.multivalued_n = 3
	hud_instance.menu_overlay._on_func_selected(Config.ComplexFunc.MULTIVALUED_Z_POW)
	assert_true(hud_instance.menu_overlay.branch_k_slider.visible)
	assert_eq(hud_instance.menu_overlay.branch_k_slider.min_value, 0.0)
	assert_eq(hud_instance.menu_overlay.branch_k_slider.max_value, 2.0)
	
	# Test MULTIVALUED_LOG (range -5 to 5)
	hud_instance.menu_overlay._on_func_selected(Config.ComplexFunc.MULTIVALUED_LOG)
	assert_true(hud_instance.menu_overlay.branch_k_slider.visible)
	assert_eq(hud_instance.menu_overlay.branch_k_slider.min_value, -5.0)
	assert_eq(hud_instance.menu_overlay.branch_k_slider.max_value, 5.0)
	
	# Test non-multivalued function (hidden)
	hud_instance.menu_overlay._on_func_selected(Config.ComplexFunc.ZETA)
	assert_false(hud_instance.menu_overlay.branch_k_slider.visible)

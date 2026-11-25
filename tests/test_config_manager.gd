extends GutTest

const ConfigManager = preload("res://core/config_manager.gd")
var config_manager

func before_each():
	config_manager = ConfigManager.new()
	config_manager.save_path = "user://test_settings.cfg"

func after_each():
	if is_instance_valid(config_manager):
		config_manager.free()
	var dir = DirAccess.open("user://")
	if dir != null and dir.file_exists("test_settings.cfg"):
		dir.remove("test_settings.cfg")


func test_presets():
	# Initially "Default"
	assert_eq(config_manager.current_preset, "Default")

	# Apply "Mysterious"
	config_manager.apply_preset("Mysterious")
	assert_eq(config_manager.current_preset, "Mysterious")
	var mysterious_preset = config_manager.PRESET_DEFAULTS.PRESETS["Mysterious"]
	assert_eq(config_manager.freeze_time, mysterious_preset["freeze_time"])
	assert_almost_eq(config_manager.fog_density, mysterious_preset["fog_density"], 0.001)
	assert_almost_eq(config_manager.terrain_albedo, mysterious_preset["terrain_albedo"], 0.001)

	# Check dirty detection
	config_manager.terrain_albedo = 0.5
	assert_true(config_manager.is_preset_dirty())

	config_manager.terrain_albedo = 0.5
	config_manager.update_preset("CustomPreset")
	assert_true(config_manager.PRESETS.has("CustomPreset"))
	assert_eq(config_manager.PRESETS["CustomPreset"]["terrain_albedo"], 0.5)

	config_manager.delete_preset("CustomPreset")
	assert_false(config_manager.PRESETS.has("CustomPreset"))


func test_function_type_setter():
	# Initial state
	assert_eq(config_manager.function_type, ConfigManager.ComplexFunc.ZETA_CONTINUATION)
	config_manager.iterations = 123

	# Change function_type
	config_manager.function_type = ConfigManager.ComplexFunc.MANDELBROT

	# Check if previous iterations were saved
	assert_true(config_manager.function_iterations.has(ConfigManager.ComplexFunc.ZETA_CONTINUATION))
	assert_eq(config_manager.function_iterations[ConfigManager.ComplexFunc.ZETA_CONTINUATION], 123)

	# Check if new function metadata is loaded
	assert_eq(config_manager.function.name, "Mandelbrot")

	# Check if iterations for MANDELBROT loaded from defaults
	var expected_iters = int(ConfigManager.FUNCTIONS[ConfigManager.ComplexFunc.MANDELBROT]["iters_range"][3])
	assert_eq(config_manager.iterations, expected_iters)

func test_save_and_load_settings():
	config_manager.movement_speed = 99.9
	config_manager.color_scheme = 2
	config_manager.show_hud_phase_wheel = false
	config_manager.function_type = ConfigManager.ComplexFunc.GAMMA

	config_manager.save_settings()

	# Create a new instance
	var new_config = ConfigManager.new()
	new_config.save_path = "user://test_settings.cfg"
	new_config.load_settings()

	assert_almost_eq(new_config.movement_speed, 99.9, 0.001)
	assert_eq(new_config.color_scheme, 2)
	assert_eq(new_config.show_hud_phase_wheel, false)
	assert_eq(new_config.function_type, ConfigManager.ComplexFunc.GAMMA)

	new_config.free()

func test_load_settings_no_file():
	var dir = DirAccess.open("user://")
	if dir != null and dir.file_exists("test_settings.cfg"):
		dir.remove("test_settings.cfg")

	# Should not crash, and should keep defaults
	var initial_speed = config_manager.movement_speed
	config_manager.load_settings()

	assert_almost_eq(config_manager.movement_speed, initial_speed, 0.001)

func test_ready_initializes_properly():
	# _ready calls load_settings, sets effective_zoom and function
	config_manager.zoom_factor = 3.5
	config_manager.function_type = ConfigManager.ComplexFunc.SIN
	config_manager.save_settings()

	var new_config = ConfigManager.new()
	new_config.save_path = "user://test_settings.cfg"
	new_config._ready()

	assert_almost_eq(GameState.effective_zoom, 3.5, 0.001)
	assert_eq(new_config.function.name, "Sin")

	new_config.free()

func test_preset_dirty_workflow():
	# 1. Create a new Test Preset using current settings as base
	config_manager.update_preset("TestPreset")
	config_manager.apply_preset("TestPreset")
	assert_false(config_manager.is_preset_dirty())
	assert_eq(config_manager.current_preset, "TestPreset")
	
	# 2. Change a setting, like Brightness to 2.0
	config_manager.terrain_brightness = 2.0
	assert_true(config_manager.is_preset_dirty())
	
	# 3. Change preset to Mysterious and apply
	config_manager.apply_preset("Mysterious")
	assert_eq(config_manager.current_preset, "Mysterious")
	assert_almost_eq(config_manager.terrain_brightness, 0.0, 0.001)
	
	# 4. Select back TestPreset and see if it is still dirtied with Brightness 2.0
	config_manager.apply_preset("TestPreset")
	assert_eq(config_manager.current_preset, "TestPreset")
	assert_almost_eq(config_manager.terrain_brightness, 2.0, 0.001)
	assert_true(config_manager.is_preset_dirty())
	
	# 5. Save/Update TestPreset
	config_manager.update_preset("TestPreset")
	assert_false(config_manager.is_preset_dirty())
	assert_almost_eq(config_manager.terrain_brightness, 2.0, 0.001)
	
	# 6. Select Mysterious again and verify it is not affected (still 0.0)
	config_manager.apply_preset("Mysterious")
	assert_eq(config_manager.current_preset, "Mysterious")
	assert_almost_eq(config_manager.terrain_brightness, 0.0, 0.001)
	
	# 7. Select TestPreset back again
	config_manager.apply_preset("TestPreset")
	assert_eq(config_manager.current_preset, "TestPreset")
	assert_almost_eq(config_manager.terrain_brightness, 2.0, 0.001)
	assert_false(config_manager.is_preset_dirty())
	
	# 8. Modify TestPreset again to 1.5
	config_manager.terrain_brightness = 1.5
	assert_true(config_manager.is_preset_dirty())
	
	# 9. Restore TestPreset
	config_manager.restore_preset("TestPreset")
	assert_almost_eq(config_manager.terrain_brightness, 2.0, 0.001)
	assert_false(config_manager.is_preset_dirty())

func test_is_same_packed_vector2_array():
	var arr1 = PackedVector2Array([Vector2(1, 2)])
	var arr2 = PackedVector2Array([Vector2(1, 2)])
	assert_true(arr1 == arr2)

func test_preset_dirty_day_time_behavior():
	config_manager.apply_preset("Default")
	assert_false(config_manager.is_preset_dirty())
	
	# With freeze_time = false (default), changing day_time should NOT mark preset dirty
	config_manager.freeze_time = false
	config_manager.day_time = 12345.6
	assert_false(config_manager.is_preset_dirty())
	
	# With freeze_time = true, changing day_time SHOULD mark preset dirty
	config_manager.freeze_time = true
	config_manager.day_time = 12345.6
	assert_true(config_manager.is_preset_dirty())

func test_persisted_settings_schema_and_round_trip():
	# Verify every declared key exists on ConfigManager and round-trips through its section
	var expected_values = {
		"height_type": 2,
		"height_a": 4.25,
		"height_epsilon": 0.75,
		"height_theta": 1.25,
		"rational_num_coeffs": PackedVector2Array([Vector2(1.5, -2.0), Vector2(3.0, 0.5)]),
		"rational_den_coeffs": PackedVector2Array([Vector2(2.0, 1.0), Vector2(0.0, -1.0)]),
		"input_rational_num_coeffs": PackedVector2Array([Vector2(-1.0, 2.5)]),
		"input_rational_den_coeffs": PackedVector2Array([Vector2(4.0, 0.0)]),
		"multivalued_n": 5,
		"zoom_factor": 4.5,
		"zoom_damping": 0.25,
		"morph_style": ConfigManager.MorphStyle.EXPONENTIAL,
		"terrain_detail": 2,
		"antialiasing_mode": 2,
		"rendering_scale": 0.75,
		"show_curves": false,
		"show_curves_labels": true,
		"show_critical_stripe": false,
		"view_distance": 9,
		"show_flow": true,
		"show_position_marker": false,
		"riemann_sphere_mode": true,
		"riemann_sphere_radius": 120.0,
		"riemann_sphere_height": true,
		"color_scheme": 3,
		"freeze_time": true,
		"day_duration": 180.0,
		"day_time": 21600.0,
		"sunrise_direction": 1.5,
		"sky_luminosity": 1.4,
		"sun_luminosity": 0.8,
		"self_illumination": 0.35,
		"shadows_enabled": true,
		"terrain_brightness": 1.3,
		"terrain_saturation": 0.65,
		"terrain_albedo": 0.45,
		"terrain_emission": 0.25,
		"terrain_metallic": 0.3,
		"terrain_roughness": 0.55,
		"terrain_ao": 0.7,
		"terrain_rim": 0.4,
		"terrain_rim_tint": 0.6,
		"fog_density": 0.2,
		"movement_speed": 22.5,
		"speed_near_zeros": 40.0,
		"camera_height": 3.2,
		"zero_proximity_nav": 1.25,
		"show_minimap": false,
		"show_minimap_range": true,
		"show_hud_domain_sphere": true,
		"show_hud_target_sphere": true,
		"show_hud_phase_wheel": false,
		"show_hud_navigation": false,
		"show_hud_zeros": false,
		"show_rvm": false,
		"show_hud_monitor_fps": true,
		"hud_scale": 1.25,
		"menu_scale": 0.9,
		"master_volume": 75.0,
		"bg_music_volume": 50.0,
		"drone_volume": 25.0,
	}

	var schema_keys_count = 0
	for section in ConfigManager.PERSISTED_SETTINGS:
		for key in ConfigManager.PERSISTED_SETTINGS[section]:
			schema_keys_count += 1
			assert_true(expected_values.has(key), "Test fixture missing persisted key: %s" % key)
			config_manager.set(key, expected_values[key])
	assert_eq(schema_keys_count, expected_values.size())

	config_manager.function_type = ConfigManager.ComplexFunc.SIN
	config_manager.input_function_type = ConfigManager.ComplexFunc.EXP
	config_manager.iterations = 321
	config_manager.save_settings()

	var raw_cfg = ConfigFile.new()
	assert_eq(raw_cfg.load(config_manager.save_path), OK)
	for section in ConfigManager.PERSISTED_SETTINGS:
		for key in ConfigManager.PERSISTED_SETTINGS[section]:
			assert_true(raw_cfg.has_section_key(section, key), "Missing [%s] %s in saved file" % [section, key])

	var reloaded = ConfigManager.new()
	reloaded.save_path = config_manager.save_path
	reloaded.load_settings()

	assert_eq(reloaded.function_type, ConfigManager.ComplexFunc.SIN)
	assert_eq(reloaded.input_function_type, ConfigManager.ComplexFunc.EXP)
	assert_eq(reloaded.iterations, 321)
	for section in ConfigManager.PERSISTED_SETTINGS:
		for key in ConfigManager.PERSISTED_SETTINGS[section]:
			var expected = expected_values[key]
			var actual = reloaded.get(key)
			if typeof(expected) == TYPE_FLOAT:
				assert_almost_eq(actual, expected, 1e-5, "Mismatch for persisted float key: %s" % key)
			else:
				assert_eq(actual, expected, "Mismatch for persisted key: %s" % key)

	reloaded.free()

func test_load_settings_sphere_mode_overrides_multivalued_function():
	var raw_cfg = ConfigFile.new()
	raw_cfg.set_value("field", "function_type", int(ConfigManager.ComplexFunc.MULTIVALUED_LOG))
	raw_cfg.set_value("rendering", "riemann_sphere_mode", true)
	assert_eq(raw_cfg.save(config_manager.save_path), OK)

	config_manager.load_settings()
	assert_true(config_manager.riemann_sphere_mode)
	assert_eq(config_manager.function_type, ConfigManager.ComplexFunc.ZETA_CONTINUATION)

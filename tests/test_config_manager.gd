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
	assert_eq(config_manager.freeze_time, true)
	assert_almost_eq(config_manager.fog_density, 0.8, 0.001)
	assert_almost_eq(config_manager.terrain_albedo, 0.0, 0.001)

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
	assert_eq(config_manager.function_type, ConfigManager.ComplexFunc.ZETA)
	config_manager.iterations = 123

	# Change function_type
	config_manager.function_type = ConfigManager.ComplexFunc.MANDELBROT

	# Check if previous iterations were saved
	assert_true(config_manager.function_iterations.has(ConfigManager.ComplexFunc.ZETA))
	assert_eq(config_manager.function_iterations[ConfigManager.ComplexFunc.ZETA], 123)

	# Check if new function metadata is loaded
	assert_eq(config_manager.function.name, "Mandelbrot")

	# Check if iterations for MANDELBROT loaded from defaults
	var expected_iters = int(ConfigManager.FUNCTIONS[ConfigManager.ComplexFunc.MANDELBROT]["iters_range"][3])
	assert_eq(config_manager.iterations, expected_iters)

func test_save_and_load_settings():
	config_manager.movement_speed = 99.9
	config_manager.color_scheme = 2
	config_manager.show_hud_complex = false
	config_manager.function_type = ConfigManager.ComplexFunc.GAMMA

	config_manager.save_settings()

	# Create a new instance
	var new_config = ConfigManager.new()
	new_config.save_path = "user://test_settings.cfg"
	new_config.load_settings()

	assert_almost_eq(new_config.movement_speed, 99.9, 0.001)
	assert_eq(new_config.color_scheme, 2)
	assert_eq(new_config.show_hud_complex, false)
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

	assert_almost_eq(new_config.effective_zoom, 3.5, 0.001)
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

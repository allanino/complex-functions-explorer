extends GutTest

const ConfigManager = preload("res://scripts/config_manager.gd")
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
	assert_almost_eq(config_manager.fog_density, 0.4, 0.001)
	assert_almost_eq(config_manager.terrain_albedo, 0.0, 0.001)

	# Mark dirty
	config_manager.mark_preset_dirty()
	assert_eq(config_manager.current_preset, "Mysterious*")

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

extends GutTest

const ConfigManager = preload("res://scripts/config_manager.gd")
var config_manager

var _has_backup = false

func before_each():
	_backup_settings()
	config_manager = ConfigManager.new()

func after_each():
	if is_instance_valid(config_manager):
		config_manager.free()
	_restore_settings()

func _backup_settings():
	var dir = DirAccess.open("user://")
	if dir != null and dir.file_exists("settings.cfg"):
		dir.copy("settings.cfg", "settings_backup.cfg")
		dir.remove("settings.cfg")
		_has_backup = true
	else:
		_has_backup = false

func _restore_settings():
	var dir = DirAccess.open("user://")
	if dir != null:
		if _has_backup:
			if dir.file_exists("settings.cfg"):
				dir.remove("settings.cfg")
			dir.copy("settings_backup.cfg", "settings.cfg")
			dir.remove("settings_backup.cfg")
		else:
			if dir.file_exists("settings.cfg"):
				dir.remove("settings.cfg")

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
	new_config.load_settings()

	assert_almost_eq(new_config.movement_speed, 99.9, 0.001)
	assert_eq(new_config.color_scheme, 2)
	assert_eq(new_config.show_hud_complex, false)
	assert_eq(new_config.function_type, ConfigManager.ComplexFunc.GAMMA)

	new_config.free()

func test_load_settings_no_file():
	var dir = DirAccess.open("user://")
	if dir != null and dir.file_exists("settings.cfg"):
		dir.remove("settings.cfg")

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
	new_config._ready()

	assert_almost_eq(new_config.effective_zoom, 3.5, 0.001)
	assert_eq(new_config.function.name, "Sin")

	new_config.free()

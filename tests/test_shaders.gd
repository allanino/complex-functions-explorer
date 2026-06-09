extends GutTest

var _original_save_path: String
var _has_backup: bool = false

func before_all():
	_original_save_path = Config.save_path
	Config.save_path = "user://test_shaders_settings.cfg"

	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("test_shaders_settings.cfg"):
			dir.remove("test_shaders_settings.cfg")

		# Back up production settings.cfg if it exists
		if dir.file_exists("settings.cfg"):
			var err = dir.copy("user://settings.cfg", "user://settings.cfg.bak")
			if err == OK:
				_has_backup = true

	# Load clean/empty test settings so the singleton starts fresh
	Config.load_settings()
	# Restore PRESETS to built-ins only
	Config.PRESETS = Config.PRESET_DEFAULTS.PRESETS.duplicate(true)
	# Apply Default preset to ensure reproducibility across local environments
	Config.apply_preset("Default")

func after_all():
	# Remove the temporary test settings file
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("test_shaders_settings.cfg"):
			dir.remove("test_shaders_settings.cfg")

		# Restore original settings.cfg
		if _has_backup and dir.file_exists("settings.cfg.bak"):
			# Remove any settings.cfg created during test
			if dir.file_exists("settings.cfg"):
				dir.remove("settings.cfg")
			dir.rename("settings.cfg.bak", "settings.cfg")

	# Restore path and reload original settings
	Config.save_path = _original_save_path
	Config.load_settings()


func test_sky_shader_loads():
	var shader := load("res://environment/sky.gdshader")

	assert_not_null(shader)
	assert_true(shader is Shader)

	# Optional: ensure it has code
	assert_ne(shader.code.length(), 0)

func test_sky_shader_material_creation():
	var shader := load("res://environment/sky.gdshader")
	var material := ShaderMaterial.new()

	material.shader = shader

	assert_not_null(material.shader)

func test_terrain_shader_loads():
	var shader := load("res://terrain/terrain.gdshader")

	assert_not_null(shader)
	assert_true(shader is Shader)

	# Optional: ensure it has code
	assert_ne(shader.code.length(), 0)

func test_terrain_shader_material_creation():
	var shader := load("res://terrain/terrain.gdshader")
	var material := ShaderMaterial.new()

	material.shader = shader

	assert_not_null(material.shader)

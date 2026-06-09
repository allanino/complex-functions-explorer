extends GutTest
class_name BaseTest

var _original_save_path: String
var _has_backup: bool = false

func before_all():
	_original_save_path = Config.save_path
	Config.save_path = "user://test_sandbox_settings.cfg"

	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("test_sandbox_settings.cfg"):
			dir.remove("test_sandbox_settings.cfg")

		# Back up production settings.cfg if it exists
		if dir.file_exists("settings.cfg"):
			var err = dir.copy("user://settings.cfg", "user://settings.cfg.bak")
			if err == OK:
				_has_backup = true

	# Load clean/empty test settings so the singleton starts fresh
	Config.load_settings()
	# Restore PRESETS to built-ins only (in case previous session saved custom presets)
	Config.PRESETS = Config.PRESET_DEFAULTS.PRESETS.duplicate(true)
	# Apply Default preset to ensure reproducibility across local environments
	Config.apply_preset("Default")

func after_all():
	# Remove the temporary test settings file
	var dir = DirAccess.open("user://")
	if dir:
		if dir.file_exists("test_sandbox_settings.cfg"):
			dir.remove("test_sandbox_settings.cfg")

		# Restore original settings.cfg
		if _has_backup:
			if dir.file_exists("settings.cfg"):
				dir.remove("settings.cfg")
			dir.rename("user://settings.cfg.bak", "user://settings.cfg")

	# Restore path and reload production settings
	Config.save_path = _original_save_path
	Config.load_settings()

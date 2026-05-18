extends Node

const SAVE_PATH = "user://settings.cfg"

# Field parameters
var iterations: int = 300
var function_type: int = 0
var height_type: int = 0
var height_a: float = 3.0
var height_epsilon: float = 1.0
var rational_num_coeffs: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var rational_den_coeffs: PackedFloat32Array = PackedFloat32Array([1, 0, 0, 0, 0, 0, 0, 0, 0, 0])
var zero_threshold: float = 0.5

# Rendering parameters
var terrain_detail: int = 1
var antialiasing_mode: int = 1
var show_curves: bool = true
var show_critical_stripe: bool = true
var view_distance: int = 7
var environment_type: int = 0
var sunrise_direction: float = 0.0
var shadows_enabled: bool = false

# Player parameters
var movement_speed: float = 10.0
var speed_near_zeros: float = 100.0
var camera_height: float = 1.8

# UI parameters
var show_hud_complex: bool = true
var show_hud_navigation: bool = true
var show_hud_zeros: bool = true
var show_rvm: bool = true

# Audio parameters
var bg_music_volume: float = 100.0
var drone_volume: float = 100.0

# Session state (not saved)
var visited_zeros: Array[float] = []

func _ready():
	load_settings()

func save_settings():
	var config = ConfigFile.new()

	config.set_value("field", "iterations", iterations)
	config.set_value("field", "function_type", function_type)
	config.set_value("field", "height_type", height_type)
	config.set_value("field", "height_a", height_a)
	config.set_value("field", "height_epsilon", height_epsilon)
	config.set_value("field", "rational_num_coeffs", rational_num_coeffs)
	config.set_value("field", "rational_den_coeffs", rational_den_coeffs)
	config.set_value("field", "zero_threshold", zero_threshold)

	config.set_value("rendering", "terrain_detail", terrain_detail)
	config.set_value("rendering", "antialiasing_mode", antialiasing_mode)
	config.set_value("rendering", "show_curves", show_curves)
	config.set_value("rendering", "show_critical_stripe", show_critical_stripe)
	config.set_value("rendering", "view_distance", view_distance)
	config.set_value("rendering", "environment_type", environment_type)
	config.set_value("rendering", "sunrise_direction", sunrise_direction)
	config.set_value("rendering", "shadows_enabled", shadows_enabled)

	config.set_value("player", "movement_speed", movement_speed)
	config.set_value("player", "speed_near_zeros", speed_near_zeros)
	config.set_value("player", "camera_height", camera_height)

	config.set_value("ui", "show_hud_complex", show_hud_complex)
	config.set_value("ui", "show_hud_navigation", show_hud_navigation)
	config.set_value("ui", "show_hud_zeros", show_hud_zeros)
	config.set_value("ui", "show_rvm", show_rvm)

	config.set_value("audio", "bg_music_volume", bg_music_volume)
	config.set_value("audio", "drone_volume", drone_volume)

	var err = config.save(SAVE_PATH)
	if err != OK:
		print("Error saving settings: ", err)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		return

	iterations = config.get_value("field", "iterations", iterations)
	function_type = config.get_value("field", "function_type", function_type)
	height_type = config.get_value("field", "height_type", height_type)
	height_a = config.get_value("field", "height_a", height_a)
	height_epsilon = config.get_value("field", "height_epsilon", height_epsilon)
	rational_num_coeffs = config.get_value("field", "rational_num_coeffs", rational_num_coeffs)
	rational_den_coeffs = config.get_value("field", "rational_den_coeffs", rational_den_coeffs)
	zero_threshold = config.get_value("field", "zero_threshold", zero_threshold)

	terrain_detail = config.get_value("rendering", "terrain_detail", terrain_detail)
	antialiasing_mode = config.get_value("rendering", "antialiasing_mode", antialiasing_mode)
	show_curves = config.get_value("rendering", "show_curves", show_curves)
	show_critical_stripe = config.get_value("rendering", "show_critical_stripe", show_critical_stripe)
	view_distance = config.get_value("rendering", "view_distance", view_distance)
	environment_type = config.get_value("rendering", "environment_type", environment_type)
	sunrise_direction = config.get_value("rendering", "sunrise_direction", sunrise_direction)
	shadows_enabled = config.get_value("rendering", "shadows_enabled", shadows_enabled)

	movement_speed = config.get_value("player", "movement_speed", movement_speed)
	speed_near_zeros = config.get_value("player", "speed_near_zeros", speed_near_zeros)
	camera_height = config.get_value("player", "camera_height", camera_height)

	show_hud_complex = config.get_value("ui", "show_hud_complex", show_hud_complex)
	show_hud_navigation = config.get_value("ui", "show_hud_navigation", show_hud_navigation)
	show_hud_zeros = config.get_value("ui", "show_hud_zeros", show_hud_zeros)
	show_rvm = config.get_value("ui", "show_rvm", show_rvm)

	bg_music_volume = config.get_value("audio", "bg_music_volume", bg_music_volume)
	drone_volume = config.get_value("audio", "drone_volume", drone_volume)

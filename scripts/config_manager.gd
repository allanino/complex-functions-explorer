extends Node

var save_path = "user://settings.cfg"

enum ComplexFunc {
	ZETA,
	ZETA_REFLECTION,
	DIRICHLET_ETA,
	DIRICHLET_BETA,
	GAMMA,
	LOG_GAMMA,
	DEDEKIND_ETA,
	MANDELBROT,
	SIN,
	COS,
	TAN,
	COT,
	EXP,
	LOG,
	IDENTITY,
	RATIONAL,
	MULTIVALUED_Z_POW,
	MULTIVALUED_LOG,

	# Not exposed in UI
	MULTIVALUED_RSVD1,
	MULTIVALUED_RSVD2,
	MULTIVALUED_RSVD3,
}

const FUNCTIONS = {
	ComplexFunc.ZETA: {
		"name": "Zeta (σ > 0)",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		# [min, max, step, initial]
		"iters_range": [100.0, 5000.0, 100.0, 500.0],
	},
	ComplexFunc.ZETA_REFLECTION: {
		"name": "Zeta (reflection formula)",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 5000.0, 100.0, 500.0],
	},
	ComplexFunc.DIRICHLET_ETA: {
		"name": "Dirichlet Eta (σ > 0)",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 5000.0, 100.0, 500.0],
	},
	ComplexFunc.DIRICHLET_BETA: {
		"name": "Dirichlet Beta (σ > 0)",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 5000.0, 100.0, 500.0],
	},
	ComplexFunc.GAMMA: {
		"name": "Gamma"
	},
	ComplexFunc.LOG_GAMMA: {
		"name": "Log Gamma"
	},
	ComplexFunc.DEDEKIND_ETA: {
		"name": "Dedekind Eta",
		"iters_range": [1.0, 20.0, 1.0, 10.0],
	},
	ComplexFunc.MANDELBROT: {
		"name": "Mandelbrot",
		"iters_range": [100.0, 5000.0, 100.0, 500.0],
	},
	ComplexFunc.SIN: {
		"name": "Sin",
	},
	ComplexFunc.COS: {
		"name": "Cos",
	},
	ComplexFunc.TAN: {
		"name": "Tan",
	},
	ComplexFunc.COT: {
		"name": "Cot",
	},
	ComplexFunc.EXP: {
		"name": "Exp",
	},
	ComplexFunc.LOG: {
		"name": "Log",
	},
	ComplexFunc.IDENTITY: {
		"name": "Identity",
	},
	ComplexFunc.RATIONAL: {
		"name": "Rational",
		"is_rational": true,
	},
	ComplexFunc.MULTIVALUED_Z_POW: {
		"name": "Multivalued z^(1/n)",
		"is_multivalued": true,
	},
	ComplexFunc.MULTIVALUED_LOG: {
		"name": "Multivalued Log",
		"is_multivalued": true,
	},
	ComplexFunc.MULTIVALUED_RSVD1: {
		"name": "Multivalued Reserved 1",
		"is_multivalued": true,
		"hidden": true,
	},
	ComplexFunc.MULTIVALUED_RSVD2: {
		"name": "Multivalued Reserved 2",
		"is_multivalued": true,
		"hidden": true,
	},
	ComplexFunc.MULTIVALUED_RSVD3: {
		"name": "Multivalued Reserved 3",
		"is_multivalued": true,
		"hidden": true,
	},
}

# Field parameters
var iterations: int = 500
var function_iterations: Dictionary = {}
var function_type: int = ComplexFunc.ZETA:
	set(value):
		function_iterations[function_type] = iterations
		function_type = value
		function = FUNCTIONS.get(function_type, {})
		if function_iterations.has(function_type):
			iterations = function_iterations[function_type]
		elif function.has("iters_range"):
			iterations = int(function["iters_range"][3])
var function: Dictionary = FUNCTIONS[ComplexFunc.ZETA]

var height_type: int = 0
var height_a: float = 3.0
var height_epsilon: float = 1.0
var rational_num_coeffs: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)])
var rational_den_coeffs: PackedVector2Array = PackedVector2Array([Vector2(1, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)])
var multivalued_n: int = 2
var multivalued_mode: int = 0 # 0: Time cycle, 1: Branch portals
var branch_cycle_speed: float = 0.5
var multivalued_morph_time: float = 0.1
var branch_time: float = 0.0
var current_branch: int = 0 # Session state for Portals mode
var zoom_factor: float = 1.0
var zoom_damping: float = 0.5

# Rendering parameters
var terrain_detail: int = 1
var antialiasing_mode: int = 1
var show_curves: bool = true
var show_critical_stripe: bool = true
var view_distance: int = 7
var show_flow: bool = false
var color_scheme: int = 0
var freeze_time: bool = false
var day_duration: float = 60.0 # Seconds for a full cycle
var day_time: float = 43200.0 # Current time in seconds (Noon = 12h = 43200s)
var sunrise_direction: float = 0.0
var sky_luminosity: float = 1.0
var sun_luminosity: float = 1.0
var self_illumination: float = 0.0
var shadows_enabled: bool = false
var terrain_brightness: float = 1.0
var terrain_saturation: float = 0.85
var terrain_albedo: float = 0.15
var terrain_emission: float = 0.1
var terrain_metallic: float = 0.7
var terrain_roughness: float = 0.1
var terrain_surface_texture: float = 0.0
var morph_value: float = 1.0
var fog_density: float = 0.4

# Player parameters
var movement_speed: float = 10.0
var speed_near_zeros: float = 100.0
var camera_height: float = 1.8
var zero_proximity_nav: float = 0.5

# UI parameters
var show_hud_complex: bool = true
var show_hud_navigation: bool = true
var show_hud_zeros: bool = true
var show_rvm: bool = true
var show_hud_monitor_fps: bool = false
var show_hud_monitor_chunks: bool = false
var hud_scale: float = 1.0

# Audio parameters
var master_volume: float = 100.0
var bg_music_volume: float = 100.0
var drone_volume: float = 100.0

# Session state (not saved)
var visited_zeros: Array[Vector2] = []
var rvm_start_t: float = 0.0
var performance_protection_active: bool = false
var effective_zoom: float = 1.0

func _ready():
	load_settings()
	effective_zoom = float(zoom_factor)
	function = FUNCTIONS.get(function_type, {})

func save_settings():
	var config = ConfigFile.new()

	function_iterations[function_type] = iterations
	config.set_value("field", "iterations", iterations)
	config.set_value("field", "function_iterations", function_iterations)
	config.set_value("field", "function_type", int(function_type))
	config.set_value("field", "height_type", height_type)
	config.set_value("field", "height_a", height_a)
	config.set_value("field", "height_epsilon", height_epsilon)
	config.set_value("field", "rational_num_coeffs", rational_num_coeffs)
	config.set_value("field", "rational_den_coeffs", rational_den_coeffs)
	config.set_value("field", "multivalued_n", multivalued_n)
	config.set_value("field", "zoom_factor", zoom_factor)
	config.set_value("field", "zoom_damping", zoom_damping)

	config.set_value("rendering", "terrain_detail", terrain_detail)
	config.set_value("rendering", "antialiasing_mode", antialiasing_mode)
	config.set_value("rendering", "show_curves", show_curves)
	config.set_value("rendering", "show_critical_stripe", show_critical_stripe)
	config.set_value("rendering", "view_distance", view_distance)
	config.set_value("rendering", "show_flow", show_flow)
	config.set_value("rendering", "color_scheme", color_scheme)
	config.set_value("rendering", "freeze_time", freeze_time)
	config.set_value("rendering", "day_duration", day_duration)
	config.set_value("rendering", "day_time", day_time)
	config.set_value("rendering", "sunrise_direction", sunrise_direction)
	config.set_value("rendering", "sky_luminosity", sky_luminosity)
	config.set_value("rendering", "sun_luminosity", sun_luminosity)
	config.set_value("rendering", "self_illumination", self_illumination)
	config.set_value("rendering", "shadows_enabled", shadows_enabled)
	config.set_value("rendering", "terrain_brightness", terrain_brightness)
	config.set_value("rendering", "terrain_saturation", terrain_saturation)
	config.set_value("rendering", "terrain_albedo", terrain_albedo)
	config.set_value("rendering", "terrain_emission", terrain_emission)
	config.set_value("rendering", "terrain_metallic", terrain_metallic)
	config.set_value("rendering", "terrain_roughness", terrain_roughness)
	config.set_value("rendering", "terrain_surface_texture", terrain_surface_texture)
	config.set_value("rendering", "morph_value", morph_value)
	config.set_value("rendering", "fog_density", fog_density)

	config.set_value("player", "movement_speed", movement_speed)
	config.set_value("player", "speed_near_zeros", speed_near_zeros)
	config.set_value("player", "camera_height", camera_height)
	config.set_value("player", "zero_proximity_nav", zero_proximity_nav)

	config.set_value("ui", "show_hud_complex", show_hud_complex)
	config.set_value("ui", "show_hud_navigation", show_hud_navigation)
	config.set_value("ui", "show_hud_zeros", show_hud_zeros)
	config.set_value("ui", "show_rvm", show_rvm)
	config.set_value("ui", "show_hud_monitor_fps", show_hud_monitor_fps)
	config.set_value("ui", "show_hud_monitor_chunks", show_hud_monitor_chunks)
	config.set_value("ui", "hud_scale", hud_scale)

	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bg_music_volume", bg_music_volume)
	config.set_value("audio", "drone_volume", drone_volume)

	config.save(save_path)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(save_path)
	if err != OK:
		return

	var ft_raw = config.get_value("field", "function_type", int(function_type))
	function_type = ft_raw

	function_iterations = config.get_value("field", "function_iterations", {})
	if function_iterations.has(function_type):
		iterations = function_iterations[function_type]
	else:
		iterations = config.get_value("field", "iterations", iterations)

	height_type = config.get_value("field", "height_type", height_type)
	height_a = config.get_value("field", "height_a", height_a)
	height_epsilon = config.get_value("field", "height_epsilon", height_epsilon)
	rational_num_coeffs = config.get_value("field", "rational_num_coeffs", rational_num_coeffs)
	rational_den_coeffs = config.get_value("field", "rational_den_coeffs", rational_den_coeffs)
	multivalued_n = config.get_value("field", "multivalued_n", multivalued_n)
	zoom_factor = config.get_value("field", "zoom_factor", zoom_factor)
	zoom_damping = config.get_value("field", "zoom_damping", zoom_damping)

	terrain_detail = config.get_value("rendering", "terrain_detail", terrain_detail)
	antialiasing_mode = config.get_value("rendering", "antialiasing_mode", antialiasing_mode)
	show_curves = config.get_value("rendering", "show_curves", show_curves)
	show_critical_stripe = config.get_value("rendering", "show_critical_stripe", show_critical_stripe)
	view_distance = config.get_value("rendering", "view_distance", view_distance)
	show_flow = config.get_value("rendering", "show_flow", show_flow)
	color_scheme = config.get_value("rendering", "color_scheme", color_scheme)
	freeze_time = config.get_value("rendering", "freeze_time", freeze_time)
	day_duration = config.get_value("rendering", "day_duration", day_duration)
	day_time = config.get_value("rendering", "day_time", day_time)
	sunrise_direction = config.get_value("rendering", "sunrise_direction", sunrise_direction)
	sky_luminosity = config.get_value("rendering", "sky_luminosity", sky_luminosity)
	sun_luminosity = config.get_value("rendering", "sun_luminosity", sun_luminosity)
	self_illumination = config.get_value("rendering", "self_illumination", self_illumination)
	shadows_enabled = config.get_value("rendering", "shadows_enabled", shadows_enabled)
	terrain_brightness = config.get_value("rendering", "terrain_brightness", terrain_brightness)
	terrain_saturation = config.get_value("rendering", "terrain_saturation", terrain_saturation)
	terrain_albedo = config.get_value("rendering", "terrain_albedo", terrain_albedo)
	terrain_emission = config.get_value("rendering", "terrain_emission", terrain_emission)
	terrain_metallic = config.get_value("rendering", "terrain_metallic", terrain_metallic)
	terrain_roughness = config.get_value("rendering", "terrain_roughness", terrain_roughness)
	terrain_surface_texture = config.get_value("rendering", "terrain_surface_texture", terrain_surface_texture)
	morph_value = config.get_value("rendering", "morph_value", morph_value)
	fog_density = config.get_value("rendering", "fog_density", fog_density)

	movement_speed = config.get_value("player", "movement_speed", movement_speed)
	speed_near_zeros = config.get_value("player", "speed_near_zeros", speed_near_zeros)
	camera_height = config.get_value("player", "camera_height", camera_height)
	zero_proximity_nav = config.get_value("player", "zero_proximity_nav", zero_proximity_nav)

	show_hud_complex = config.get_value("ui", "show_hud_complex", show_hud_complex)
	show_hud_navigation = config.get_value("ui", "show_hud_navigation", show_hud_navigation)
	show_hud_zeros = config.get_value("ui", "show_hud_zeros", show_hud_zeros)
	show_rvm = config.get_value("ui", "show_rvm", show_rvm)
	show_hud_monitor_fps = config.get_value("ui", "show_hud_monitor_fps", show_hud_monitor_fps)
	show_hud_monitor_chunks = config.get_value("ui", "show_hud_monitor_chunks", show_hud_monitor_chunks)
	hud_scale = config.get_value("ui", "hud_scale", hud_scale)

	master_volume = config.get_value("audio", "master_volume", master_volume)
	bg_music_volume = config.get_value("audio", "bg_music_volume", bg_music_volume)
	drone_volume = config.get_value("audio", "drone_volume", drone_volume)

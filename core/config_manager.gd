extends Node

signal config_changed(key: String)


var save_path = "user://settings.cfg"

const FUNCTIONS_ENUM_PATH = "res://math/functions_enum.gdshaderinc"
static var ComplexFunc = {}

static func _load_shader_enums(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line.begins_with("#define"):
				var parts = line.split(" ", false)
				if parts.size() >= 3:
					ComplexFunc[parts[1]] = int(parts[2])




static var FUNCTIONS = {
	"ZETA": {
		"name": "Zeta",
		"symbol": "ζ (σ > 0)",
		"hidden": true,
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		# [min, max, step, initial]
		"iters_range": [100.0, 10000.0, 100.0, 100.0],
		"initial_pos": Vector3(5.0, 0.0, 0.0),
	},
	"ZETA_REFLECTION": {
		"name": "Zeta",
		"symbol": "ζ",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 10000.0, 100.0, 100.0],
		"initial_pos": Vector3(5.0, 0.0, 0.0),
	},
	"DIRICHLET_ETA": {
		"name": "Dirichlet Eta (σ > 0)",
		"symbol": "η",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 10000.0, 100.0, 100.0],
		"initial_pos": Vector3(5.0, 0.0, 0.0),
		"hidden": true,
	},
	"DIRICHLET_ETA_REFLECTION": {
		"name": "Dirichlet Eta",
		"symbol": "η",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 10000.0, 100.0, 100.0],
		"initial_pos": Vector3(5.0, 0.0, 0.0),
	},
	"DIRICHLET_BETA": {
		"name": "Dirichlet Beta",
		"symbol": "β (σ > 0)",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 10000.0, 100.0, 100.0],
		"initial_pos": Vector3(5.0, 0.0, 0.0),
	},
	"GAMMA": {
		"name": "Gamma",
		"symbol": "Γ",
		"initial_pos": Vector3(30.0, 0.0, 0.0),
	},
	"LOG_GAMMA": {
		"name": "Log Gamma",
		"symbol": "f",
	},
	"DEDEKIND_ETA": {
		"name": "Dedekind Eta",
		"symbol": "η",
		"iters_range": [1.0, 20.0, 1.0, 10.0],
		"initial_pos": Vector3(10.0, 0.0, 0.0),
	},
	"MANDELBROT": {
		"name": "Mandelbrot",
		"symbol": "f",
		"iters_range": [100.0, 5000.0, 100.0, 500.0],
	},
	"SIN": {
		"name": "Sin",
		"symbol": "f",
	},
	"COS": {
		"name": "Cos",
		"symbol": "f",
	},
	"TAN": {
		"name": "Tan",
		"symbol": "f",
	},
	"COT": {
		"name": "Cot",
		"symbol": "f",
		"initial_pos": Vector3(10.0, 0.0, 0.0),
	},
	"EXP": {
		"name": "Exp",
		"symbol": "f",
	},
	"LOG": {
		"name": "Log",
		"symbol": "f",
	},
	"IDENTITY": {
		"name": "Identity",
		"symbol": "f",
	},
	"RATIONAL": {
		"name": "Rational",
		"symbol": "f",
		"is_rational": true,
	},
	"MULTIVALUED_Z_POW": {
		"name": "Multivalued z^(1/n)",
		"symbol": "f",
		"is_multivalued": true,
	},
	"MULTIVALUED_LOG": {
		"name": "Multivalued Log",
		"symbol": "f",
		"is_multivalued": true,
		"initial_pos": Vector3(10.0, 0.0, 0.0),
	},
	"MULTIVALUED_ASIN": {
		"name": "Multivalued arcsin",
		"symbol": "f",
		"is_multivalued": true,
		"initial_pos": Vector3(5.0, 0.0, 0.0),
	},
	"MULTIVALUED_ACOS": {
		"name": "Multivalued arccos",
		"symbol": "f",
		"is_multivalued": true,
	},
	"ZETA_POWER_SERIES": {
		"name": "Zeta (power series)",
		"symbol": "ζ",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [100.0, 10000.0, 100.0, 100.0],
		"hidden": true,
	},
	"ETA_BORWEIN": {
		"name": "Eta Borwein",
		"symbol": "η",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [10.0, 200.0, 10.0, 50.0],
		"hidden": true,
	},
	"ZETA_BORWEIN": {
		"name": "Zeta Borwein",
		"symbol": "ζ",
		"is_dirichlect": true,
		"has_von_mangoldt": true,
		"iters_range": [10.0, 200.0, 10.0, 50.0],
		"hidden": true,
		},
}

# Field parameters

const PRESET_KEYS = [
	"terrain_detail",
	"antialiasing_mode",
	"show_curves",
	"show_curves_labels",
	"show_critical_stripe",
	"view_distance",
	"show_flow",
	"show_position_marker",
	"color_scheme",
	"freeze_time",
	"day_duration",
	"day_time",
	"sunrise_direction",
	"sky_luminosity",
	"sun_luminosity",
	"self_illumination",
	"shadows_enabled",
	"terrain_brightness",
	"terrain_saturation",
	"terrain_albedo",
	"terrain_emission",
	"terrain_metallic",
	"terrain_roughness",
	"terrain_surface_texture",
	"fog_density",
	"movement_speed",
	"speed_near_zeros",
	"camera_height",
	"zero_proximity_nav",
	"show_minimap",
	"show_hud_phase_wheel",
	"show_hud_navigation",
	"show_hud_zeros",
	"show_rvm",
	"show_hud_monitor_fps",
	"hud_scale",
	"menu_scale",
	"master_volume",
	"bg_music_volume",
	"drone_volume"
]

const PRESET_DEFAULTS = preload("res://core/preset_defaults.gd")
var PRESETS = PRESET_DEFAULTS.PRESETS.duplicate(true)

var current_preset: String = "Default"
var _edited_presets: Dictionary = {}

signal preset_applied

# Field parameters
var iterations: int = 500:
	set(v):
		if iterations == v: return
		iterations = v
		config_changed.emit("iterations")
var function_iterations: Dictionary = {}
var function_type: int = ComplexFunc.ZETA_REFLECTION:
	set(value):
		function_iterations[function_type] = iterations
		function_type = value
		function = FUNCTIONS.get(function_type, {})
		config_changed.emit("function_type")
		if function_iterations.has(function_type):
			iterations = function_iterations[function_type]
		elif function.has("iters_range"):
			iterations = int(function["iters_range"][3])
var function: Dictionary = {}
var input_function_type: int = ComplexFunc.IDENTITY

var height_type: int = 0:
	set(v):
		if height_type == v: return
		height_type = v
		config_changed.emit("height_type")
var height_a: float = 3.0:
	set(v):
		if height_a == v: return
		height_a = v
		config_changed.emit("height_a")
var height_epsilon: float = 1.0:
	set(v):
		if height_epsilon == v: return
		height_epsilon = v
		config_changed.emit("height_epsilon")
var height_theta: float = 0.0:
	set(v):
		if height_theta == v: return
		height_theta = v
		config_changed.emit("height_theta")
var rational_num_coeffs: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]):
	set(v):
		if rational_num_coeffs == v: return
		rational_num_coeffs = v
		config_changed.emit("rational_num_coeffs")
var rational_den_coeffs: PackedVector2Array = PackedVector2Array([Vector2(1, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]):
	set(v):
		if rational_den_coeffs == v: return
		rational_den_coeffs = v
		config_changed.emit("rational_den_coeffs")
var input_rational_num_coeffs: PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]):
	set(v):
		if input_rational_num_coeffs == v: return
		input_rational_num_coeffs = v
		config_changed.emit("input_rational_num_coeffs")
var input_rational_den_coeffs: PackedVector2Array = PackedVector2Array([Vector2(1, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]):
	set(v):
		if input_rational_den_coeffs == v: return
		input_rational_den_coeffs = v
		config_changed.emit("input_rational_den_coeffs")
var multivalued_n: int = 2:
	set(v):
		if multivalued_n == v: return
		multivalued_n = v
		config_changed.emit("multivalued_n")
var zoom_factor: float = 1.0:
	set = _set_zoom_factor
var zoom_damping: float = 0.5

# Rendering parameters
var terrain_detail: int = 1:
	set(v):
		if terrain_detail == v: return
		terrain_detail = v
		config_changed.emit("terrain_detail")
var antialiasing_mode: int = 1
var show_curves: bool = true:
	set(v):
		if show_curves == v: return
		show_curves = v
		config_changed.emit("show_curves")
var show_curves_labels: bool = false
var show_critical_stripe: bool = true:
	set(v):
		if show_critical_stripe == v: return
		show_critical_stripe = v
		config_changed.emit("show_critical_stripe")
var view_distance: int = 7:
	set(v):
		if view_distance == v: return
		view_distance = v
		config_changed.emit("view_distance")
var show_flow: bool = false:
	set(v):
		if show_flow == v: return
		show_flow = v
		config_changed.emit("show_flow")
var show_position_marker: bool = true:
	set(v):
		if show_position_marker == v: return
		show_position_marker = v
		config_changed.emit("show_position_marker")
var color_scheme: int = 0:
	set(v):
		if color_scheme == v: return
		color_scheme = v
		config_changed.emit("color_scheme")
var freeze_time: bool = false
var day_duration: float = 60.0 # Seconds for a full cycle
var day_time: float = 43200.0: # Current time in seconds (Noon = 12h = 43200s)
	set(v):
		if day_time == v: return
		day_time = v
		config_changed.emit("day_time")
var sunrise_direction: float = 0.0
var sky_luminosity: float = 1.0
var sun_luminosity: float = 1.0
var self_illumination: float = 0.0:
	set(v):
		if self_illumination == v: return
		self_illumination = v
		config_changed.emit("self_illumination")
var shadows_enabled: bool = false
var terrain_brightness: float = 1.0:
	set(v):
		if terrain_brightness == v: return
		terrain_brightness = v
		config_changed.emit("terrain_brightness")
var terrain_saturation: float = 0.85:
	set(v):
		if terrain_saturation == v: return
		terrain_saturation = v
		config_changed.emit("terrain_saturation")
var terrain_albedo: float = 0.15:
	set(v):
		if terrain_albedo == v: return
		terrain_albedo = v
		config_changed.emit("terrain_albedo")
var terrain_emission: float = 0.1:
	set(v):
		if terrain_emission == v: return
		terrain_emission = v
		config_changed.emit("terrain_emission")
var terrain_metallic: float = 0.7:
	set(v):
		if terrain_metallic == v: return
		terrain_metallic = v
		config_changed.emit("terrain_metallic")
var terrain_roughness: float = 0.1:
	set(v):
		if terrain_roughness == v: return
		terrain_roughness = v
		config_changed.emit("terrain_roughness")
var terrain_surface_texture: float = 0.0:
	set(v):
		if terrain_surface_texture == v: return
		terrain_surface_texture = v
		config_changed.emit("terrain_surface_texture")
var fog_density: float = 0.4:
	set(v):
		if fog_density == v: return
		fog_density = v
		config_changed.emit("fog_density")

# Player parameters
var movement_speed: float = 10.0
var speed_near_zeros: float = 100.0
var camera_height: float = 1.8
var zero_proximity_nav: float = 0.5


# UI parameters
var show_minimap: bool = true:
	set(v):
		if show_minimap == v: return
		show_minimap = v
		config_changed.emit("show_minimap")
var show_hud_phase_wheel: bool = true:
	set(v):
		if show_hud_phase_wheel == v: return
		show_hud_phase_wheel = v
		config_changed.emit("show_hud_phase_wheel")
var show_hud_navigation: bool = true:
	set(v):
		if show_hud_navigation == v: return
		show_hud_navigation = v
		config_changed.emit("show_hud_navigation")
var show_hud_zeros: bool = true:
	set(v):
		if show_hud_zeros == v: return
		show_hud_zeros = v
		config_changed.emit("show_hud_zeros")
var show_rvm: bool = true:
	set(v):
		if show_rvm == v: return
		show_rvm = v
		config_changed.emit("show_rvm")
var show_hud_monitor_fps: bool = false:
	set(v):
		if show_hud_monitor_fps == v: return
		show_hud_monitor_fps = v
		config_changed.emit("show_hud_monitor_fps")

var hud_scale: float = 1.0
var menu_scale: float = 1.0

# Audio parameters
var master_volume: float = 100.0:
	set(v):
		if master_volume == v: return
		master_volume = v
		config_changed.emit("master_volume")
var bg_music_volume: float = 100.0:
	set(v):
		if bg_music_volume == v: return
		bg_music_volume = v
		config_changed.emit("bg_music_volume")
var drone_volume: float = 100.0:
	set(v):
		if drone_volume == v: return
		drone_volume = v
		config_changed.emit("drone_volume")


func _set_zoom_factor(value: float):
	var nv = clampf(value, 0.1, 100.0)
	if zoom_factor == nv:
		return
	zoom_factor = nv
	config_changed.emit("zoom_factor")

func apply_zoom_immediate():
	GameState.effective_zoom = float(zoom_factor)

func world_to_complex(world_x: float, world_z: float) -> Vector2:
	return Vector2(world_x * 0.1 / GameState.effective_zoom, -world_z * 0.1 / GameState.effective_zoom)

# Converts 2D complex plane coordinates (Re, Im) to 3D world coordinates (x, z), accounting for zoom.
func complex_to_world(complex_x: float, complex_y: float) -> Vector2:
	return Vector2(complex_x * 10.0 * GameState.effective_zoom, -complex_y * 10.0 * GameState.effective_zoom)


func _snapshot_current() -> Dictionary:
	var snapshot = {}
	for key in PRESET_KEYS:
		snapshot[key] = get(key)
	return snapshot

func apply_preset(preset_name: String):
	# Save current preset's state only when switching away to a different preset
	var old_clean = current_preset.trim_suffix("*")
	if PRESETS.has(old_clean) and old_clean != preset_name:
		_edited_presets[old_clean] = _snapshot_current()

	if PRESETS.has(preset_name):
		var target_preset = _edited_presets.get(preset_name, PRESETS[preset_name])
		for key in target_preset:
			set(key, target_preset[key])
		current_preset = preset_name
		preset_applied.emit()

func is_preset_dirty() -> bool:
	var clean_name = current_preset.trim_suffix("*")
	if not PRESETS.has(clean_name):
		return true
	var preset = PRESETS[clean_name]
	for key in PRESET_KEYS:
		if key == "day_time" and not get("freeze_time"):
			continue
		if preset.has(key):
			var val1 = get(key)
			var val2 = preset[key]
			if typeof(val1) == TYPE_FLOAT and typeof(val2) == TYPE_FLOAT:
				if not is_equal_approx(val1, val2):
					return true
			elif val1 != val2:
				return true
	return false

func is_preset_dirty_by_name(preset_name: String) -> bool:
	if preset_name == current_preset.trim_suffix("*"):
		return is_preset_dirty()
	if not PRESETS.has(preset_name):
		return false
	if not _edited_presets.has(preset_name):
		return false
	var cached = _edited_presets[preset_name]
	var clean = PRESETS[preset_name]
	for key in PRESET_KEYS:
		if key == "day_time" and not cached.get("freeze_time", false):
			continue
		if clean.has(key) and cached.has(key):
			var val1 = cached[key]
			var val2 = clean[key]
			if typeof(val1) == TYPE_FLOAT and typeof(val2) == TYPE_FLOAT:
				if not is_equal_approx(val1, val2):
					return true
			elif val1 != val2:
				return true
	return false

func update_preset(preset_name: String):
	var preset_data = {}
	for key in PRESET_KEYS:
		preset_data[key] = get(key)
	PRESETS[preset_name] = preset_data
	if _edited_presets.has(preset_name):
		_edited_presets.erase(preset_name)
	current_preset = preset_name
	save_settings()

func delete_preset(preset_name: String):
	if PRESETS.has(preset_name):
		PRESETS.erase(preset_name)
		if _edited_presets.has(preset_name):
			_edited_presets.erase(preset_name)
		save_settings()

func restore_preset(preset_name: String):
	if _edited_presets.has(preset_name):
		_edited_presets.erase(preset_name)
	if current_preset.trim_suffix("*") == preset_name:
		if PRESETS.has(preset_name):
			var preset = PRESETS[preset_name]
			for key in preset:
				set(key, preset[key])
			preset_applied.emit()


static func _static_init() -> void:
	_load_shader_enums(FUNCTIONS_ENUM_PATH)
	var new_funcs = {}
	for key in FUNCTIONS.keys():
		new_funcs[ComplexFunc[key]] = FUNCTIONS[key]
	FUNCTIONS = new_funcs


func _init() -> void:
	function = FUNCTIONS.get(function_type, {})

func _ready():
	load_settings()
	apply_zoom_immediate()

func save_settings():
	var config = ConfigFile.new()

	function_iterations[function_type] = iterations
	config.set_value("field", "iterations", iterations)
	config.set_value("field", "function_iterations", function_iterations)
	config.set_value("field", "function_type", int(function_type))
	config.set_value("field", "input_function_type", int(input_function_type))
	config.set_value("field", "height_type", height_type)
	config.set_value("field", "height_a", height_a)
	config.set_value("field", "height_epsilon", height_epsilon)
	config.set_value("field", "height_theta", height_theta)
	config.set_value("field", "rational_num_coeffs", rational_num_coeffs)
	config.set_value("field", "rational_den_coeffs", rational_den_coeffs)
	config.set_value("field", "input_rational_num_coeffs", input_rational_num_coeffs)
	config.set_value("field", "input_rational_den_coeffs", input_rational_den_coeffs)
	config.set_value("field", "multivalued_n", multivalued_n)
	config.set_value("field", "zoom_factor", zoom_factor)
	config.set_value("field", "zoom_damping", zoom_damping)

	config.set_value("rendering", "terrain_detail", terrain_detail)
	config.set_value("rendering", "antialiasing_mode", antialiasing_mode)
	config.set_value("rendering", "show_curves", show_curves)
	config.set_value("rendering", "show_curves_labels", show_curves_labels)
	config.set_value("rendering", "show_critical_stripe", show_critical_stripe)
	config.set_value("rendering", "view_distance", view_distance)
	config.set_value("rendering", "show_flow", show_flow)
	config.set_value("rendering", "show_position_marker", show_position_marker)
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
	config.set_value("rendering", "fog_density", fog_density)
	config.set_value("session", "current_preset", current_preset)
	config.set_value("session", "custom_presets", PRESETS)

	config.set_value("player", "movement_speed", movement_speed)
	config.set_value("player", "speed_near_zeros", speed_near_zeros)
	config.set_value("player", "camera_height", camera_height)
	config.set_value("player", "zero_proximity_nav", zero_proximity_nav)

	config.set_value("ui", "show_minimap", show_minimap)
	config.set_value("ui", "show_hud_phase_wheel", show_hud_phase_wheel)
	config.set_value("ui", "show_hud_navigation", show_hud_navigation)
	config.set_value("ui", "show_hud_zeros", show_hud_zeros)
	config.set_value("ui", "show_rvm", show_rvm)
	config.set_value("ui", "show_hud_monitor_fps", show_hud_monitor_fps)
	config.set_value("ui", "hud_scale", hud_scale)
	config.set_value("ui", "menu_scale", menu_scale)

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

	var in_ft_raw = config.get_value("field", "input_function_type", int(input_function_type))
	input_function_type = in_ft_raw

	function_iterations = config.get_value("field", "function_iterations", {})
	if function_iterations.has(function_type):
		iterations = function_iterations[function_type]
	else:
		iterations = config.get_value("field", "iterations", iterations)

	height_type = config.get_value("field", "height_type", height_type)
	height_a = config.get_value("field", "height_a", height_a)
	height_epsilon = config.get_value("field", "height_epsilon", height_epsilon)
	height_theta = config.get_value("field", "height_theta", height_theta)
	rational_num_coeffs = config.get_value("field", "rational_num_coeffs", rational_num_coeffs)
	rational_den_coeffs = config.get_value("field", "rational_den_coeffs", rational_den_coeffs)
	input_rational_num_coeffs = config.get_value("field", "input_rational_num_coeffs", input_rational_num_coeffs)
	input_rational_den_coeffs = config.get_value("field", "input_rational_den_coeffs", input_rational_den_coeffs)
	multivalued_n = config.get_value("field", "multivalued_n", multivalued_n)
	zoom_factor = config.get_value("field", "zoom_factor", zoom_factor)
	zoom_damping = config.get_value("field", "zoom_damping", zoom_damping)

	terrain_detail = config.get_value("rendering", "terrain_detail", terrain_detail)
	antialiasing_mode = config.get_value("rendering", "antialiasing_mode", antialiasing_mode)
	show_curves = config.get_value("rendering", "show_curves", show_curves)
	show_curves_labels = config.get_value("rendering", "show_curves_labels", show_curves_labels)
	show_critical_stripe = config.get_value("rendering", "show_critical_stripe", show_critical_stripe)
	view_distance = config.get_value("rendering", "view_distance", view_distance)
	show_flow = config.get_value("rendering", "show_flow", show_flow)
	show_position_marker = config.get_value("rendering", "show_position_marker", show_position_marker)
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
	fog_density = config.get_value("rendering", "fog_density", fog_density)
	current_preset = config.get_value("session", "current_preset", "Default")
	# Only restore custom (non-built-in) presets; built-ins always come from preset_defaults.gd
	var built_in_keys = PRESET_DEFAULTS.PRESETS.keys()
	var saved_presets = config.get_value("session", "custom_presets", {})
	for preset_name in saved_presets:
		if not built_in_keys.has(preset_name):
			PRESETS[preset_name] = saved_presets[preset_name]

	movement_speed = config.get_value("player", "movement_speed", movement_speed)
	speed_near_zeros = config.get_value("player", "speed_near_zeros", speed_near_zeros)
	camera_height = config.get_value("player", "camera_height", camera_height)
	zero_proximity_nav = config.get_value("player", "zero_proximity_nav", zero_proximity_nav)

	show_minimap = config.get_value("ui", "show_minimap", show_minimap)
	show_hud_phase_wheel = config.get_value("ui", "show_hud_phase_wheel", show_hud_phase_wheel)
	show_hud_navigation = config.get_value("ui", "show_hud_navigation", show_hud_navigation)
	show_hud_zeros = config.get_value("ui", "show_hud_zeros", show_hud_zeros)
	show_rvm = config.get_value("ui", "show_rvm", show_rvm)
	show_hud_monitor_fps = config.get_value("ui", "show_hud_monitor_fps", show_hud_monitor_fps)
	hud_scale = config.get_value("ui", "hud_scale", hud_scale)
	menu_scale = config.get_value("ui", "menu_scale", menu_scale)

	master_volume = config.get_value("audio", "master_volume", master_volume)
	bg_music_volume = config.get_value("audio", "bg_music_volume", bg_music_volume)
	drone_volume = config.get_value("audio", "drone_volume", drone_volume)

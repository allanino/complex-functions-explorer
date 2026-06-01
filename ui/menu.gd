extends ColorRect

signal apply_aa_signal
signal portal_flash_signal
signal update_hud_layout_signal
signal toggle_menu_signal(applied)

var player: Node3D
var world_manager: Node

@onready var main_menu_panel = get_node("CenterContainer/MainMenuPanel")
@onready var tab_container = %TabContainer
@onready var func_button = %FuncContainer.get_option_button()
@onready var input_button = %InputContainer.get_option_button()
@onready var height_button = %HeightContainer.get_option_button()
@onready var height_a_container = %HeightAContainer
@onready var height_a_input = %HeightAContainer.get_line_edit()
@onready var height_eps_container = %HeightEpsContainer
@onready var height_eps_input = %HeightEpsContainer.get_line_edit()
@onready var height_theta_slider = %HeightThetaSlider
@onready var iter_slider = %IterSlider
@onready var func_rational_container = %FuncRationalContainer
@onready var func_rational_input = %FuncRationalContainer.get_line_edit()
@onready var input_rational_container = %InputRationalContainer
@onready var input_rational_input = %InputRationalContainer.get_line_edit()
@onready var multivalued_slider = %MultivaluedSlider
@onready var branch_k_slider = %BranchKSlider
@onready var re_input = %ReContainer.get_line_edit()
@onready var im_input = %ImContainer.get_line_edit()
@onready var speed_input = %SpeedContainer.get_line_edit()
@onready var zoom_slider = %ZoomContainer
@onready var zero_speed_slider = %ZeroSpeedContainer
@onready var zero_proximity_nav_slider = %ZeroProximityNavContainer
@onready var camera_height_input = %CameraHeightContainer.get_line_edit()
@onready var auto_walk_checkbox = %AutoWalkCheckbox
@onready var terrain_detail_button = %TerrainDetailContainer.get_option_button()
@onready var aa_button = %AAContainer.get_option_button()
@onready var color_scheme_button = %ColorSchemeContainer.get_option_button()
@onready var view_distance_slider = %ViewDistanceContainer
@onready var curves_checkbox = %CurvesCheckbox
@onready var curves_labels_checkbox = %CurvesLabelsCheckbox
@onready var critical_checkbox = %CriticalCheckbox
@onready var flow_checkbox = %FlowCheckbox
@onready var position_marker_checkbox = %PositionMarkerCheckbox
@onready var freeze_time_checkbox = %FreezeTimeCheckbox
@onready var day_duration_slider = %DayDurationSlider
@onready var day_time_slider = %DayTimeSlider
@onready var sunrise_slider = %SunriseContainer
@onready var sky_luminosity_slider = %SkyLuminosityContainer
@onready var sun_luminosity_slider = %SunLuminosityContainer
@onready var self_illumination_slider = %SelfIlluminationContainer
@onready var fog_density_slider = %FogDensitySlider
@onready var shadows_checkbox = %ShadowsCheckbox
@onready var hud_complex_checkbox = %HudComplexCheckbox
@onready var hud_navigation_checkbox = %HudNavigationCheckbox
@onready var hud_zeros_checkbox = %HudZerosDetectionCheckbox
@onready var rvm_checkbox = %RvmCheckbox
@onready var hud_monitor_fps_checkbox = %HudMonitorFpsCheckbox
@onready var hud_monitor_chunks_checkbox = %HudMonitorChunksCheckbox
@onready var menu_scale_slider = %MenuScaleContainer
@onready var hud_scale_slider = %HudScaleContainer
@onready var master_volume_slider = %MasterVolumeContainer
@onready var bg_music_slider = %BgMusicContainer
@onready var drone_slider = %DroneContainer
@onready var detach_controller = get_node("../DetachOverlay")

@onready var brightness_slider = %BrightnessContainer
@onready var saturation_slider = %SaturationContainer
@onready var albedo_slider = %AlbedoContainer
@onready var emission_slider = %EmissionContainer
@onready var metallic_slider = %MetallicContainer
@onready var roughness_slider = %RoughnessContainer
@onready var surface_texture_slider = %SurfaceTextureContainer
@onready var morph_slider = %MorphSliderContainer
@onready var preset_controller = get_node("../PresetController")

@onready var new_preset_dialog = %NewPresetDialog
@onready var delete_preset_dialog = %DeletePresetDialog
@onready var apply_button = %ApplyButton
@onready var close_button = %CloseButton
@onready var quit_button = %QuitButton
@onready var quit_dialog = %QuitDialog
@onready var quit_message_label = %QuitMessageLabel
@onready var quit_cancel = %QuitCancel
@onready var quit_save_and_quit = %QuitSaveAndQuit
@onready var quit_confirm = %QuitConfirm
@onready var perf_label = %PerfProtectionLabel
@onready var func_tab_button = %FunctionTabButton
@onready var env_tab_button = %EnvironmentTabButton
@onready var terrain_tab_button = %TerrainTabButton
@onready var visualization_tab_button = %VisualizationTabButton
@onready var graphics_tab_button = %GraphicsTabButton
@onready var navigation_tab_button = %NavigationTabButton
@onready var ui_tab_button = %UiTabButton
@onready var audio_tab_button = %AudioTabButton
var tab_buttons: Array = []
var active_tab_style: StyleBoxFlat
var inactive_tab_style: StyleBoxFlat
var hover_tab_style: StyleBoxFlat
var hover_active_tab_style: StyleBoxFlat
@onready var tooltip_manager = %TooltipManager
var current_scale = 2.0
var _initial_master_volume: float
var _initial_bg_music_volume: float
var _initial_drone_volume: float
var _initial_zero_proximity_nav: float
var _initial_iterations: int
var _initial_terrain_brightness: float
var _initial_terrain_saturation: float
var _initial_terrain_albedo: float
var _initial_terrain_emission: float
var _initial_terrain_metallic: float
var _initial_terrain_roughness: float
var _initial_terrain_surface_texture: float
var _initial_menu_scale: float
var _initial_hud_scale: float
var _initial_sky_luminosity: float
var _initial_sun_luminosity: float
var _initial_self_illumination: float
var _initial_freeze_time: bool
var _initial_day_duration: float
var _initial_day_time: float
var _initial_fog_density: float
var _initial_morph_value: float
var _initial_terrain_detail: int
var _initial_antialiasing_mode: int
var _initial_view_distance: int
var _initial_shadows_enabled: bool
var _speed_modified: bool = false
var _camera_height_modified: bool = false
var _syncing_ui: bool = false
var SLIDER_BINDINGS: Dictionary = {}
func _init_slider_bindings():
	var bindings = {
		master_volume_slider: {
			"config_key": "master_volume",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		bg_music_slider: {
			"config_key": "bg_music_volume",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		drone_slider: {
			"config_key": "drone_volume",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		zero_proximity_nav_slider: {
			"config_key": "zero_proximity_nav",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return "%.2f" % v,
			"immediate": true
		},
		zoom_slider: {
			"config_key": "zoom_factor",
			"to_config": func(v): return _slider_to_zoom(v),
			"from_config": func(c): return _zoom_to_slider(c),
			"format": func(v): return "x%.2f" % _slider_to_zoom(v),
			"immediate": true
		},
		zero_speed_slider: {
			"config_key": "speed_near_zeros",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": false
		},
		view_distance_slider: {
			"config_key": "view_distance",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))),
			"immediate": true
		},
		day_duration_slider: {
			"config_key": "day_duration",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return _format_time(v),
			"immediate": true
		},
		day_time_slider: {
			"config_key": "day_time",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return _format_time(v),
			"immediate": true
		},
		sunrise_slider: {
			"config_key": "sunrise_direction",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "°",
			"immediate": false
		},
		sky_luminosity_slider: {
			"config_key": "sky_luminosity",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		sun_luminosity_slider: {
			"config_key": "sun_luminosity",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		self_illumination_slider: {
			"config_key": "self_illumination",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		fog_density_slider: {
			"config_key": "fog_density",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return "%.1f%%" % v,
			"immediate": true
		},
		menu_scale_slider: {
			"config_key": "menu_scale",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true,
			"on_changed": func(_v): update_hud_layout_signal.emit()
		},
		hud_scale_slider: {
			"config_key": "hud_scale",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true,
			"on_changed": func(_v): update_hud_layout_signal.emit()
		},
		iter_slider: {
			"config_key": "iterations",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))),
			"immediate": true
		},
		height_theta_slider: {
			"config_key": "height_theta",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return "%.2f rad" % v,
			"immediate": true,
			"on_changed": func(_v): if world_manager and world_manager.has_method("_update_terrain_material_uniforms"): world_manager._update_terrain_material_uniforms()
		},
		multivalued_slider: {
			"config_key": "multivalued_n",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))),
			"immediate": true,
			"on_changed": func(_v): _update_branch_k_slider_range()
		},
		branch_k_slider: {
			"config_key": "current_branch",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))),
			"immediate": true
		},
		brightness_slider: {
			"config_key": "terrain_brightness",
			"to_config": func(v): return v / 50.0,
			"from_config": func(c): return c * 50.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		saturation_slider: {
			"config_key": "terrain_saturation",
			"to_config": func(v): return 0.3 + (v / 100.0) * 0.7,
			"from_config": func(c): return (c - 0.3) / 0.7 * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		albedo_slider: {
			"config_key": "terrain_albedo",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		emission_slider: {
			"config_key": "terrain_emission",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		metallic_slider: {
			"config_key": "terrain_metallic",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		roughness_slider: {
			"config_key": "terrain_roughness",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		surface_texture_slider: {
			"config_key": "terrain_surface_texture",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"immediate": true
		},
		morph_slider: {
			"config_key": "morph_value",
			"to_config": func(v): return v,
			"from_config": func(_c): return 1.0,
			"format": func(v): return "%.2f" % v,
			"immediate": true
		}
	}
	for slider in bindings:
		if slider != null:
			SLIDER_BINDINGS[slider] = bindings[slider]

func _on_generic_slider_changed(slider: Control, value: float):
	if not SLIDER_BINDINGS.has(slider):
		return
	var binding = SLIDER_BINDINGS[slider]

	if "format" in binding:
		slider.value_text = binding["format"].call(value)

	if binding.get("immediate", false) and binding.get("config_key", "") != "":
		var cfg_val = binding["to_config"].call(value)
		Config.set(binding["config_key"], cfg_val)

	if binding.has("on_changed"):
		binding["on_changed"].call(value)

var _menu_scale_dragging: bool = false

func _ready():
	_init_slider_bindings()
	_update_tab_buttons_styling()
	# Create the portal crossing flash overlay dynamically
	tab_buttons = [
		func_tab_button,
		env_tab_button,
		terrain_tab_button,
		visualization_tab_button,
		graphics_tab_button,
		navigation_tab_button,
		ui_tab_button,
		audio_tab_button
	]
	active_tab_style = StyleBoxFlat.new()
	active_tab_style.content_margin_left = 15.0
	active_tab_style.content_margin_top = 12.0
	active_tab_style.content_margin_right = 10.0
	active_tab_style.content_margin_bottom = 12.0
	active_tab_style.bg_color = Color(1, 1, 1, 0.05)
	active_tab_style.border_width_left = 4
	active_tab_style.border_width_top = 0
	active_tab_style.border_width_right = 0
	active_tab_style.border_width_bottom = 0
	active_tab_style.border_color = Color(0.65, 0.65, 0.68, 0.85) # Gray accent
	inactive_tab_style = StyleBoxFlat.new()
	inactive_tab_style.content_margin_left = 19.0
	inactive_tab_style.content_margin_top = 12.0
	inactive_tab_style.content_margin_right = 10.0
	inactive_tab_style.content_margin_bottom = 12.0
	inactive_tab_style.bg_color = Color(0, 0, 0, 0)
	hover_tab_style = StyleBoxFlat.new()
	hover_tab_style.content_margin_left = 19.0
	hover_tab_style.content_margin_top = 12.0
	hover_tab_style.content_margin_right = 10.0
	hover_tab_style.content_margin_bottom = 12.0
	hover_tab_style.bg_color = Color(1, 1, 1, 0.03)
	hover_active_tab_style = StyleBoxFlat.new()
	hover_active_tab_style.content_margin_left = 15.0
	hover_active_tab_style.content_margin_top = 12.0
	hover_active_tab_style.content_margin_right = 10.0
	hover_active_tab_style.content_margin_bottom = 12.0
	hover_active_tab_style.bg_color = Color(1, 1, 1, 0.08) # Slightly brighter background on hover
	hover_active_tab_style.border_width_left = 4
	hover_active_tab_style.border_width_top = 0
	hover_active_tab_style.border_width_right = 0
	hover_active_tab_style.border_width_bottom = 0
	hover_active_tab_style.border_color = Color(0.65, 0.65, 0.68, 0.85)
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		if btn:
			btn.flat = false
			btn.add_theme_font_size_override("font_size", 18)
			btn.add_theme_stylebox_override("hover", hover_tab_style)
			btn.add_theme_stylebox_override("pressed", active_tab_style)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(func(): _on_tab_button_pressed(i))
	tab_container.tab_changed.connect(func(_idx): _update_tab_buttons_styling())
	_update_tab_buttons_styling()
	speed_input.text_changed.connect(func(_t): _speed_modified = true)
	speed_input.text_submitted.connect(_on_speed_text_submitted)
	camera_height_input.text_changed.connect(func(_t): _camera_height_modified = true)
	camera_height_input.text_submitted.connect(_on_camera_height_text_submitted)
	re_input.text_submitted.connect(_on_re_text_submitted)
	im_input.text_submitted.connect(_on_im_text_submitted)
	height_a_input.text_submitted.connect(_on_height_a_text_submitted)
	height_eps_input.text_submitted.connect(_on_height_eps_text_submitted)
	func_rational_input.text_submitted.connect(_on_func_rational_text_submitted)
	input_rational_input.text_submitted.connect(_on_input_rational_text_submitted)
	curves_checkbox.toggled.connect(_on_curves_toggled)
	curves_labels_checkbox.toggled.connect(_on_curves_labels_toggled)
	critical_checkbox.toggled.connect(_on_critical_toggled)
	flow_checkbox.toggled.connect(_on_flow_toggled)
	position_marker_checkbox.toggled.connect(_on_position_marker_toggled)
	hud_complex_checkbox.toggled.connect(_on_hud_complex_toggled)
	hud_navigation_checkbox.toggled.connect(_on_hud_navigation_toggled)
	hud_zeros_checkbox.toggled.connect(_on_hud_zeros_toggled)
	rvm_checkbox.toggled.connect(_on_rvm_toggled)
	hud_monitor_fps_checkbox.toggled.connect(_on_hud_monitor_fps_toggled)
	hud_monitor_chunks_checkbox.toggled.connect(_on_hud_monitor_chunks_toggled)
	color_scheme_button.item_selected.connect(_on_color_scheme_selected)
	apply_button.pressed.connect(_on_set_pos_pressed)
	close_button.pressed.connect(func(): toggle_menu_signal.emit(false))
	quit_button.pressed.connect(_on_quit_pressed)
	quit_cancel.pressed.connect(_on_quit_cancel_pressed)
	quit_save_and_quit.pressed.connect(_on_quit_save_and_quit_pressed)
	quit_confirm.pressed.connect(_on_quit_confirm_pressed)
	func_button.item_selected.connect(_on_func_item_selected)
	input_button.item_selected.connect(_on_input_item_selected)
	height_button.item_selected.connect(_on_height_selected)
	_init_slider_bindings()
	for slider in SLIDER_BINDINGS:
		slider.value_changed.connect(func(v): _on_generic_slider_changed(slider, v))
	freeze_time_checkbox.toggled.connect(_on_freeze_time_toggled)
	terrain_detail_button.item_selected.connect(_on_terrain_detail_selected)
	aa_button.item_selected.connect(_on_aa_selected)
	shadows_checkbox.toggled.connect(_on_shadows_toggled)
	_populate_function_dropdown(func_button, false)
	_populate_function_dropdown(input_button, true)
	height_button.clear()
	height_button.add_item("Absolute: Abs(f)")
	height_button.add_item("Logarithmic: a * Log(Abs(f) + ε)")
	height_button.add_item("Imaginary component: Im(f)")
	height_button.add_item("Real component: Re(f)")
	height_button.add_item("Projected component: Re( e^(-iθ) * f )")
	height_button.add_item("Flat: 0")
	terrain_detail_button.clear()
	terrain_detail_button.add_item("High")
	terrain_detail_button.add_item("Medium")
	terrain_detail_button.add_item("Low")
	terrain_detail_button.add_item("Lowest")
	aa_button.clear()
	aa_button.add_item("Disabled (fastest)")
	aa_button.add_item("MSAA 3D x2 (average)")
	aa_button.add_item("MSAA 3D x4 (slow)")
	aa_button.add_item("MSAA 3D x8 (slowest)")
	aa_button.add_item("FXAA (fast)")
	aa_button.add_item("SMAA (average)")
	color_scheme_button.clear()
	color_scheme_button.add_item("Cyan real line (flipped)")
	color_scheme_button.add_item("Red real line (standard)")
	iter_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Iterations"))
	height_theta_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Parameter θ"))
	morph_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Terrain Morph"))
	multivalued_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Branches (n)"))
	branch_k_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Branch number"))
	day_duration_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Day Duration"))
	day_time_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Time of day"))
	sunrise_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Sunrise Direction"))
	sky_luminosity_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Sky Luminosity"))
	sun_luminosity_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Sun Luminosity"))
	self_illumination_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Self-Illumination"))
	fog_density_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Fog Density"))
	brightness_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Brightness"))
	saturation_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Saturation"))
	albedo_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Albedo"))
	emission_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Emission"))
	metallic_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Metallic"))
	roughness_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Roughness"))
	surface_texture_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "SurfaceTexture"))
	view_distance_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "View Distance"))
	# Apply initial menu scale on startup
	if main_menu_panel:
		main_menu_panel.scale = Vector2.ONE
		_rescale_menu(Config.menu_scale)
	# Connect dragging events for the menu scale slider to prevent real-time feedback loop during drag
	if menu_scale_slider:
		var menu_scale_hslider = menu_scale_slider.get_slider()
		if menu_scale_hslider:
			menu_scale_hslider.drag_started.connect(func():
				_menu_scale_dragging = true
			)
			menu_scale_hslider.drag_ended.connect(func(_value_changed: bool):
				_menu_scale_dragging = false
				_rescale_menu(Config.menu_scale)
			)
func _disable_sliders_focus(node: Node):
	if node is HSlider:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_sliders_focus(child)


func toggle_menu(applied: bool = false):
	if detach_controller.visible:
		detach_controller.interaction_active = !detach_controller.interaction_active
		if detach_controller.interaction_active:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if main_menu_panel:
		main_menu_panel.scale = Vector2.ONE
		_rescale_menu(Config.menu_scale)

	visible = !visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_initial_master_volume = Config.master_volume
		_initial_bg_music_volume = Config.bg_music_volume
		_initial_drone_volume = Config.drone_volume
		_initial_zero_proximity_nav = Config.zero_proximity_nav
		_initial_iterations = Config.iterations
		_initial_terrain_brightness = Config.terrain_brightness
		_initial_terrain_saturation = Config.terrain_saturation
		_initial_terrain_albedo = Config.terrain_albedo
		_initial_terrain_emission = Config.terrain_emission
		_initial_terrain_metallic = Config.terrain_metallic
		_initial_terrain_roughness = Config.terrain_roughness
		_initial_terrain_surface_texture = Config.terrain_surface_texture
		_initial_menu_scale = Config.menu_scale
		_initial_hud_scale = Config.hud_scale
		_initial_sky_luminosity = Config.sky_luminosity
		_initial_sun_luminosity = Config.sun_luminosity
		_initial_self_illumination = Config.self_illumination
		_initial_freeze_time = Config.freeze_time
		_initial_day_duration = Config.day_duration
		_initial_day_time = Config.day_time
		_initial_fog_density = Config.fog_density
		_initial_morph_value = 1.0
		_initial_terrain_detail = Config.terrain_detail
		_initial_antialiasing_mode = Config.antialiasing_mode
		_initial_view_distance = Config.view_distance
		_initial_shadows_enabled = Config.shadows_enabled

		_sync_ui_to_config()

		freeze_time_checkbox.button_pressed = Config.freeze_time

		if player:
			var scale_factor = 1.0 / Config.effective_zoom
			var re_val = player.global_position.x * 0.1 * scale_factor
			var im_val = - player.global_position.z * 0.1 * scale_factor
			if not is_finite(re_val): re_val = 0.5
			if not is_finite(im_val): im_val = 0.0
			re_input.text = _format_float_3(re_val)
			im_input.text = _format_float_3(im_val)

		preset_controller.update_preset_button_text()

	else:
		tooltip_manager.hide_tooltip()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if not applied:
			Config.master_volume = _initial_master_volume
			Config.bg_music_volume = _initial_bg_music_volume
			Config.drone_volume = _initial_drone_volume
			Config.zero_proximity_nav = _initial_zero_proximity_nav
			Config.iterations = _initial_iterations
			Config.terrain_brightness = _initial_terrain_brightness
			Config.terrain_saturation = _initial_terrain_saturation
			Config.terrain_albedo = _initial_terrain_albedo
			Config.terrain_emission = _initial_terrain_emission
			Config.terrain_metallic = _initial_terrain_metallic
			Config.terrain_roughness = _initial_terrain_roughness
			Config.terrain_surface_texture = _initial_terrain_surface_texture
			if Config.menu_scale != _initial_menu_scale:
				Config.menu_scale = _initial_menu_scale
			if Config.hud_scale != _initial_hud_scale:
				Config.hud_scale = _initial_hud_scale
				update_hud_layout_signal.emit()
			Config.sky_luminosity = _initial_sky_luminosity
			Config.sun_luminosity = _initial_sun_luminosity
			Config.self_illumination = _initial_self_illumination
			Config.freeze_time = _initial_freeze_time
			Config.day_duration = _initial_day_duration
			Config.day_time = _initial_day_time
			Config.fog_density = _initial_fog_density
			Config.morph_value = _initial_morph_value
			Config.terrain_detail = _initial_terrain_detail
			Config.antialiasing_mode = _initial_antialiasing_mode
			Config.view_distance = _initial_view_distance
			Config.shadows_enabled = _initial_shadows_enabled

			apply_aa_signal.emit()

func _populate_function_dropdown(button: OptionButton, exclude_multivalued: bool):
	button.clear()
	var sorted_keys = Config.FUNCTIONS.keys()
	sorted_keys.sort()
	for f_key in sorted_keys:
		var f_data = Config.FUNCTIONS.get(f_key, {})
		if f_data.get("hidden", false):
			continue
		if exclude_multivalued and f_data.get("is_multivalued", false):
			continue
		button.add_item(f_data.get("name", "Unknown"), f_key)

func _on_func_item_selected(index):
	_on_func_selected(func_button.get_item_id(index))

func _on_input_item_selected(index: int):
	_on_input_selected(input_button.get_item_id(index))

func _on_input_selected(f_type: int):
	Config.input_function_type = f_type
	var f_data = Config.FUNCTIONS.get(f_type, {})
	var is_rational = f_data.get("is_rational", false)
	input_rational_container.visible = is_rational

func _on_func_selected(f_type: int):
	Config.function_type = f_type
	var f_data = Config.function

	var is_dirichlect = f_data.get("is_dirichlect", false)
	var iters_range = f_data.get("iters_range", {})
	var has_iters = !iters_range.is_empty()
	var is_rational = f_data.get("is_rational", false)
	var is_multivalued_n = f_type == Config.ComplexFunc.MULTIVALUED_Z_POW

	if has_iters:
		iter_slider.min_value = iters_range[0]
		iter_slider.max_value = iters_range[1]
		iter_slider.step = iters_range[2]

		Config.iterations = Config.function_iterations.get(f_type, iters_range[3])
		iter_slider.value = Config.iterations

	func_rational_container.visible = is_rational
	multivalued_slider.visible = is_multivalued_n
	iter_slider.visible = has_iters
	critical_checkbox.visible = is_dirichlect
	auto_walk_checkbox.visible = is_dirichlect
	rvm_checkbox.visible = is_dirichlect

	var is_multivalued = f_data.get("is_multivalued", false)
	branch_k_slider.visible = is_multivalued
	_update_branch_k_slider_range()

func _update_branch_k_slider_range():
	if Config.function_type == Config.ComplexFunc.MULTIVALUED_Z_POW:
		branch_k_slider.min_value = 0
		branch_k_slider.max_value = max(0, Config.multivalued_n - 1)
	else:
		branch_k_slider.min_value = -5
		branch_k_slider.max_value = 5
	# Clamp value to new range
	branch_k_slider.value = clamp(branch_k_slider.value, branch_k_slider.min_value, branch_k_slider.max_value)

func _on_height_selected(index):
	Config.height_type = index
	var is_log = (index == 1)
	height_a_container.visible = is_log
	height_eps_container.visible = is_log
	height_theta_slider.visible = (index == 4)

func _on_freeze_time_toggled(pressed: bool):
	Config.freeze_time = pressed


func _format_time(total_seconds: float) -> String:
	var hours = int(total_seconds) / 3600.0
	var minutes = (int(total_seconds) % 3600) / 60.0
	var seconds = int(total_seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _format_float_3(val: float) -> String:
	return "%.3f" % snappedf(val, 0.001)

func _get_rvm_n(T: float) -> float:
	if T <= 0.1:
		return 0.0

	# L-function for Dirichlet Beta has character modulo q = 4
	if Config.function_type == Config.ComplexFunc.DIRICHLET_BETA:
		# Riemann-von Mangoldt formula for Dirichlet L-functions:
		# N(T, chi) ≈ (T/2π) * log(qT/2πe)
		return (T / (2.0 * PI)) * (log((4.0 * T) / (2.0 * PI)) - 1.0)

	# Riemann-von Mangoldt formula for Zeta: N(T) ≈ (T/2π) log(T/2πe) + 7/8
	return (T / (2.0 * PI)) * (log(T / (2.0 * PI)) - 1.0) + 7.0 / 8.0

func _zoom_to_slider(zoom: float) -> float:
	var min_zoom = 0.01
	var max_zoom = 200.0
	var b = (log(max_zoom) - log(min_zoom)) / 100.0
	return (log(zoom) - log(min_zoom)) / b

func _slider_to_zoom(value: float) -> float:
	var min_zoom = 0.01
	var max_zoom = 200.0
	var b = (log(max_zoom) - log(min_zoom)) / 100.0
	return exp(log(min_zoom) + value * b)

func _on_set_pos_pressed(_toggle_menu: bool = true):
	Config.performance_protection_active = false
	var re = float(re_input.text)
	var im = float(im_input.text)
	if not is_finite(re): re = 0.5
	if not is_finite(im): im = 0.0

	var h_a = float(height_a_input.text)
	if not is_finite(h_a): h_a = 3.0
	var h_eps = float(height_eps_input.text)
	if not is_finite(h_eps): h_eps = 1.0
	var m_speed = float(speed_input.text) * 10.0
	if not is_finite(m_speed): m_speed = 100.0
	var c_height = float(camera_height_input.text)
	if not is_finite(c_height): c_height = 1.8

	if !hud_zeros_checkbox.button_pressed:
		Config.visited_zeros.clear()

	# Apply non-slider values to Config
	Config.movement_speed = m_speed
	Config.camera_height = c_height
	Config.height_a = h_a
	Config.height_epsilon = h_eps

	# Apply all sliders to Config via bindings
	for slider in SLIDER_BINDINGS:
		var binding = SLIDER_BINDINGS[slider]
		var cfg_key = binding.get("config_key", "")
		if cfg_key != "":
			var cfg_val = binding["to_config"].call(slider.value)
			Config.set(cfg_key, cfg_val)

	# Ensure effective zoom is updated from applied zoom_factor
	Config.effective_zoom = float(Config.zoom_factor)

	_speed_modified = false
	_camera_height_modified = false

	Config.terrain_detail = terrain_detail_button.selected
	Config.antialiasing_mode = aa_button.selected
	Config.color_scheme = color_scheme_button.selected
	Config.show_curves = curves_checkbox.button_pressed
	Config.show_curves_labels = curves_labels_checkbox.button_pressed
	Config.show_critical_stripe = critical_checkbox.button_pressed
	Config.shadows_enabled = shadows_checkbox.button_pressed
	Config.show_hud_complex = hud_complex_checkbox.button_pressed
	Config.show_hud_navigation = hud_navigation_checkbox.button_pressed
	Config.show_hud_zeros = hud_zeros_checkbox.button_pressed
	Config.show_rvm = rvm_checkbox.button_pressed
	Config.show_hud_monitor_fps = hud_monitor_fps_checkbox.button_pressed
	Config.show_hud_monitor_chunks = hud_monitor_chunks_checkbox.button_pressed
	Config.show_flow = flow_checkbox.button_pressed
	Config.show_position_marker = position_marker_checkbox.button_pressed
	Config.function_type = func_button.get_item_id(func_button.selected)
	Config.input_function_type = input_button.get_item_id(input_button.selected)
	Config.height_type = height_button.selected

	apply_aa_signal.emit()

	if Config.function_type == Config.ComplexFunc.RATIONAL:
		var expr = func_rational_input.text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			# We only strip outer parentheses if they enclose the whole numerator/denominator
			var num_str = parts[0]
			if num_str.begins_with("(") and num_str.ends_with(")"):
				num_str = num_str.substr(1, num_str.length() - 2)
			var den_str = parts[1]
			if den_str.begins_with("(") and den_str.ends_with(")"):
				den_str = den_str.substr(1, den_str.length() - 2)

			Config.rational_num_coeffs = FormulaParser.parse_poly(num_str)
			Config.rational_den_coeffs = FormulaParser.parse_poly(den_str)
		else:
			Config.rational_num_coeffs = FormulaParser.parse_poly(expr)
			Config.rational_den_coeffs = PackedVector2Array([Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	if Config.input_function_type == Config.ComplexFunc.RATIONAL:
		var expr = input_rational_input.text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			var num_str = parts[0]
			if num_str.begins_with("(") and num_str.ends_with(")"):
				num_str = num_str.substr(1, num_str.length() - 2)
			var den_str = parts[1]
			if den_str.begins_with("(") and den_str.ends_with(")"):
				den_str = den_str.substr(1, den_str.length() - 2)

			Config.input_rational_num_coeffs = FormulaParser.parse_poly(num_str)
			Config.input_rational_den_coeffs = FormulaParser.parse_poly(den_str)
		else:
			Config.input_rational_num_coeffs = FormulaParser.parse_poly(expr)
			Config.input_rational_den_coeffs = PackedVector2Array([Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	Config.save_settings()
	update_hud_layout_signal.emit()
	preset_controller.update_preset_button_text()

	if player:
		var zoom_mult = Config.zoom_factor
		if not is_finite(player.global_position.x) or not is_finite(player.global_position.y) or not is_finite(player.global_position.z):
			player.velocity = Vector3.ZERO
			player.global_position = Vector3(10.0 * re * zoom_mult, 0.0, -10.0 * im * zoom_mult)
		else:
			player.global_position.x = 10.0 * re * zoom_mult
			player.global_position.z = -10.0 * im * zoom_mult

		# Update auto-walk state
		if auto_walk_checkbox.button_pressed:
			if player.auto_walk_state == 0: # NONE
				player.auto_walk_state = 1 # MOVING_TO_LINE
				Config.rvm_start_t = abs(player.global_position.z * 0.1 / Config.effective_zoom)
				Config.visited_zeros.clear()
				if "last_detected_t" in player:
					player.last_detected_t = -1.0
		else:
			player.auto_walk_state = 0 # NONE

	preset_controller.update_preset_button_text()
	if _toggle_menu:
		toggle_menu(true)


func _sync_ui_to_config():
	_syncing_ui = true
	_update_branch_k_slider_range()
	var backup = {}
	for key in Config.PRESET_KEYS:
		backup[key] = Config.get(key)

	# Sync all sliders programmatically
	for slider in SLIDER_BINDINGS:
		var binding = SLIDER_BINDINGS[slider]
		var cfg_key = binding.get("config_key", "")
		if cfg_key != "":
			var cfg_val = Config.get(cfg_key)
			var ui_val = binding["from_config"].call(cfg_val)
			slider.set_value_no_signal(ui_val)
			slider.value_text = binding["format"].call(ui_val)
			if binding.has("on_changed"):
				binding["on_changed"].call(ui_val)

	_speed_modified = false
	_camera_height_modified = false
	speed_input.text = "%.1f" % (Config.movement_speed * 0.1)
	camera_height_input.text = str(Config.camera_height)
	height_a_input.text = str(Config.height_a)
	height_eps_input.text = str(Config.height_epsilon)

	terrain_detail_button.selected = Config.terrain_detail
	aa_button.selected = Config.antialiasing_mode
	color_scheme_button.selected = Config.color_scheme

	curves_checkbox.button_pressed = Config.show_curves
	curves_labels_checkbox.button_pressed = Config.show_curves_labels
	critical_checkbox.button_pressed = Config.show_critical_stripe
	shadows_checkbox.button_pressed = Config.shadows_enabled
	hud_complex_checkbox.button_pressed = Config.show_hud_complex
	hud_navigation_checkbox.button_pressed = Config.show_hud_navigation
	hud_zeros_checkbox.button_pressed = Config.show_hud_zeros
	rvm_checkbox.button_pressed = Config.show_rvm
	hud_monitor_fps_checkbox.button_pressed = Config.show_hud_monitor_fps
	hud_monitor_chunks_checkbox.button_pressed = Config.show_hud_monitor_chunks

	if player:
		auto_walk_checkbox.button_pressed = (player.auto_walk_state != 0)

	flow_checkbox.button_pressed = Config.show_flow
	position_marker_checkbox.button_pressed = Config.show_position_marker

	func_button.select(func_button.get_item_index(Config.function_type))
	input_button.select(input_button.get_item_index(Config.input_function_type))
	height_button.selected = Config.height_type
	_on_func_selected(Config.function_type)
	_on_input_selected(Config.input_function_type)
	_on_height_selected(Config.height_type)

	for key in Config.PRESET_KEYS:
		Config.set(key, backup[key])
	_syncing_ui = false
	if main_menu_panel:
		main_menu_panel.scale = Vector2.ONE
		_rescale_menu(Config.menu_scale)

func _on_quit_pressed():
	if Config.is_preset_dirty():
		var preset_name = Config.current_preset.trim_suffix("*")
		quit_message_label.text = 'Preset "' + preset_name + '" contains unsaved changes.'
		quit_save_and_quit.visible = true
		quit_confirm.text = "Quit Without Saving"
	else:
		quit_message_label.text = "Any unapplied view changes will be lost."
		quit_save_and_quit.visible = false
		quit_confirm.text = "Quit"

	quit_dialog.visible = true

func _on_quit_cancel_pressed():
	quit_dialog.visible = false

func _on_quit_save_and_quit_pressed():
	Config.update_preset(Config.current_preset.trim_suffix("*"))
	get_tree().quit()

func _on_quit_confirm_pressed():
	get_tree().quit()

func _on_terrain_detail_selected(index: int):
	Config.terrain_detail = index

func _on_aa_selected(index: int):
	Config.antialiasing_mode = index
	apply_aa_signal.emit()

func _on_shadows_toggled(pressed: bool):
	Config.shadows_enabled = pressed

func _on_curves_toggled(pressed: bool):
	Config.show_curves = pressed

func _on_curves_labels_toggled(pressed: bool):
	Config.show_curves_labels = pressed

func _on_critical_toggled(pressed: bool):
	Config.show_critical_stripe = pressed

func _on_flow_toggled(pressed: bool):
	Config.show_flow = pressed

func _on_position_marker_toggled(pressed: bool):
	Config.show_position_marker = pressed

func _on_hud_complex_toggled(pressed: bool):
	Config.show_hud_complex = pressed

func _on_hud_navigation_toggled(pressed: bool):
	Config.show_hud_navigation = pressed

func _on_hud_zeros_toggled(pressed: bool):
	Config.show_hud_zeros = pressed
	if not pressed:
		Config.visited_zeros.clear()

func _on_rvm_toggled(pressed: bool):
	Config.show_rvm = pressed

func _on_hud_monitor_fps_toggled(pressed: bool):
	Config.show_hud_monitor_fps = pressed

func _on_hud_monitor_chunks_toggled(pressed: bool):
	Config.show_hud_monitor_chunks = pressed

func _on_color_scheme_selected(index: int):
	Config.color_scheme = index

func _on_speed_text_submitted(new_text: String):
	var m_speed = float(new_text) * 10.0
	if is_finite(m_speed):
		Config.movement_speed = m_speed
		_speed_modified = false

func _on_camera_height_text_submitted(new_text: String):
	var c_height = float(new_text)
	if is_finite(c_height):
		Config.camera_height = c_height
		_camera_height_modified = false

func _on_re_text_submitted(new_text: String):
	var re = float(new_text)
	if is_finite(re) and player:
		var zoom_mult = Config.zoom_factor
		player.global_position.x = 10.0 * re * zoom_mult

func _on_im_text_submitted(new_text: String):
	var im = float(new_text)
	if is_finite(im) and player:
		var zoom_mult = Config.zoom_factor
		player.global_position.z = -10.0 * im * zoom_mult

func _on_height_a_text_submitted(new_text: String):
	var h_a = float(new_text)
	if is_finite(h_a):
		Config.height_a = h_a

func _on_height_eps_text_submitted(new_text: String):
	var h_eps = float(new_text)
	if is_finite(h_eps):
		Config.height_epsilon = h_eps

func _on_func_rational_text_submitted(new_text: String):
	if Config.function_type == Config.ComplexFunc.RATIONAL:
		var expr = new_text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			var num_str = parts[0]
			if num_str.begins_with("(") and num_str.ends_with(")"):
				num_str = num_str.substr(1, num_str.length() - 2)
			var den_str = parts[1]
			if den_str.begins_with("(") and den_str.ends_with(")"):
				den_str = den_str.substr(1, den_str.length() - 2)

			Config.rational_num_coeffs = FormulaParser.parse_poly(num_str)
			Config.rational_den_coeffs = FormulaParser.parse_poly(den_str)
		else:
			Config.rational_num_coeffs = FormulaParser.parse_poly(expr)
			Config.rational_den_coeffs = PackedVector2Array([Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

func _on_input_rational_text_submitted(new_text: String):
	if Config.input_function_type == Config.ComplexFunc.RATIONAL:
		var expr = new_text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			var num_str = parts[0]
			if num_str.begins_with("(") and num_str.ends_with(")"):
				num_str = num_str.substr(1, num_str.length() - 2)
			var den_str = parts[1]
			if den_str.begins_with("(") and den_str.ends_with(")"):
				den_str = den_str.substr(1, den_str.length() - 2)

			Config.input_rational_num_coeffs = FormulaParser.parse_poly(num_str)
			Config.input_rational_den_coeffs = FormulaParser.parse_poly(den_str)
		else:
			Config.input_rational_num_coeffs = FormulaParser.parse_poly(expr)
			Config.input_rational_den_coeffs = PackedVector2Array([Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

func _rescale_menu(_scale: float):
	if main_menu_panel == null: return

	# We use meta to check if we already applied this scale to avoid redundant traversals
	if main_menu_panel.has_meta("last_applied_menu_scale") and main_menu_panel.get_meta("last_applied_menu_scale") == _scale:
		return
	main_menu_panel.set_meta("last_applied_menu_scale", _scale)

	var actual_scale = _scale

	var stack = []
	if main_menu_panel: stack.push_back(main_menu_panel)
	if new_preset_dialog: stack.push_back(new_preset_dialog)
	if delete_preset_dialog: stack.push_back(delete_preset_dialog)
	if quit_dialog: stack.push_back(quit_dialog)

	while stack.size() > 0:
		var node = stack.pop_back()

		# 1. Scale Fonts
		if node is Label or node is Button or node is LineEdit or node is TabContainer:
			var font_size_key = "font_size"
			if node is RichTextLabel:
				font_size_key = "normal_font_size"

			if not node.has_meta("base_font_size"):
				node.set_meta("base_font_size", node.get_theme_font_size(font_size_key))
			node.add_theme_font_size_override(font_size_key, int(round(node.get_meta("base_font_size") * actual_scale)))

		# 2. Scale Layout Parameters on Controls
		if node is Control:
			# Scale custom minimum sizes proportionally
			if node.custom_minimum_size != Vector2.ZERO:
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", node.custom_minimum_size)
				node.custom_minimum_size = node.get_meta("base_min_size") * actual_scale

			# Scale margins for MarginContainers
			if node is MarginContainer:
				for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
					if not node.has_meta("base_" + margin):
						node.set_meta("base_" + margin, node.get_theme_constant(margin))
					node.add_theme_constant_override(margin, int(round(node.get_meta("base_" + margin) * actual_scale)))

			# Scale separations for BoxContainers
			elif node is BoxContainer:
				if not node.has_meta("base_separation"):
					node.set_meta("base_separation", node.get_theme_constant("separation"))
				node.add_theme_constant_override("separation", int(round(node.get_meta("base_separation") * actual_scale)))

		# Traverse children
		for child in node.get_children():
			if child is Control:
				stack.push_back(child)


func _on_tab_button_pressed(index: int):
	tab_container.current_tab = index
	_update_tab_buttons_styling()

func _update_tab_buttons_styling():
	if tab_buttons.is_empty(): return
	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		if not btn: continue
		if i == tab_container.current_tab:
			btn.add_theme_stylebox_override("normal", active_tab_style)
			btn.add_theme_stylebox_override("hover", hover_active_tab_style)
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0))
		else:
			btn.add_theme_stylebox_override("normal", inactive_tab_style)
			btn.add_theme_stylebox_override("hover", hover_tab_style)
			btn.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			btn.add_theme_color_override("font_hover_color", Color(0.85, 0.85, 0.85))
			btn.add_theme_color_override("font_pressed_color", Color(0.65, 0.65, 0.65))
			btn.add_theme_color_override("font_focus_color", Color(0.65, 0.65, 0.65))

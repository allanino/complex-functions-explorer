extends Control

var SLIDER_BINDINGS: Dictionary = {}

signal apply_aa_signal()
signal update_hud_layout_signal()

@export var player: Node3D
@export var world_manager: Node

@onready var main_menu_panel = $CenterContainer/MainMenuPanel
@onready var tab_container = %TabContainer
@onready var title_label = %TitleLabel
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
@onready var speed_slider = %SpeedContainer
@onready var zoom_slider = %ZoomContainer
@onready var zero_speed_slider = %ZeroSpeedContainer
@onready var zero_proximity_nav_slider = %ZeroProximityNavContainer
@onready var camera_height_slider = %CameraHeightContainer
@onready var auto_walk_checkbox = %AutoWalkCheckbox
@onready var zero_walk_checkbox = %ZeroWalkCheckbox
@onready var terrain_detail_button = %TerrainDetailContainer.get_option_button()
@onready var aa_button = %AAContainer.get_option_button()
@onready var rendering_scale_slider = %RenderingScaleContainer
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
@onready var minimap_checkbox = %MinimapCheckbox
@onready var hud_phase_wheel_checkbox = %HudComplexCheckbox
@onready var hud_position_checkbox = %HudPositionCheckbox
@onready var hud_zeros_checkbox = %HudZerosDetectionCheckbox
@onready var rvm_checkbox = %RvmCheckbox
@onready var hud_monitor_fps_checkbox = %HudMonitorFpsCheckbox
@onready var menu_scale_slider = %MenuScaleContainer
@onready var hud_scale_slider = %HudScaleContainer
@onready var master_volume_slider = %MasterVolumeContainer
@onready var bg_music_slider = %BgMusicContainer
@onready var drone_slider = %DroneContainer
@export var detach_controller: Node
@onready var brightness_slider = %BrightnessContainer
@onready var saturation_slider = %SaturationContainer
@onready var albedo_slider = %AlbedoContainer
@onready var emission_slider = %EmissionContainer
@onready var metallic_slider = %MetallicContainer
@onready var roughness_slider = %RoughnessContainer
@onready var surface_texture_slider = %SurfaceTextureContainer
@onready var morph_slider = %MorphSliderContainer
@onready var morph_style_container = %MorphStyleContainer
@onready var morph_style_dropdown = %MorphStyleContainer.get_option_button()
@export var preset_controller: Node
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
@onready var func_tab_button = %FunctionTabButton
@onready var env_tab_button = %EnvironmentTabButton
@onready var terrain_tab_button = %TerrainTabButton
@onready var visualization_tab_button = %VisualizationTabButton
@onready var graphics_tab_button = %GraphicsTabButton
@onready var navigation_tab_button = %NavigationTabButton
@onready var zeros_tab_button = %ZerosTabButton
@onready var ui_tab_button = %UiTabButton
@onready var audio_tab_button = %AudioTabButton
var tab_buttons: Array = []
var active_tab_style: StyleBoxFlat
var inactive_tab_style: StyleBoxFlat
var hover_tab_style: StyleBoxFlat
var hover_active_tab_style: StyleBoxFlat
@export var tooltip_manager: Node
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
var _initial_rendering_scale: float
var _initial_view_distance: int
var _initial_shadows_enabled: bool
var _initial_preset: String
var _initial_edited_presets: Dictionary

var _title_clicks: int = 0
var _title_click_timer: float = 0.0

func _ready():
	# Performance: Start with _process disabled since no timers are active initially
	set_process(false)

	if title_label:
		title_label.gui_input.connect(_on_title_gui_input)

	current_submitted_func = Config.function_type
	current_submitted_input = Config.input_function_type
	last_submitted_func = Config.function_type
	last_submitted_input = Config.input_function_type

	tab_buttons = [
		func_tab_button,
		env_tab_button,
		terrain_tab_button,
		visualization_tab_button,
		graphics_tab_button,
		navigation_tab_button,
		zeros_tab_button,
		ui_tab_button,
		audio_tab_button
	]

	active_tab_style = StyleBoxFlat.new()
	active_tab_style.content_margin_left = 17.0
	active_tab_style.content_margin_top = 10.0
	active_tab_style.content_margin_right = 10.0
	active_tab_style.content_margin_bottom = 10.0
	active_tab_style.bg_color = Color(ThemeColors.real.r, ThemeColors.real.g, ThemeColors.real.b, 0.06)
	active_tab_style.border_width_left = 2
	active_tab_style.border_width_top = 0
	active_tab_style.border_width_right = 0
	active_tab_style.border_width_bottom = 0
	active_tab_style.border_color = ThemeColors.gold

	inactive_tab_style = StyleBoxFlat.new()
	inactive_tab_style.content_margin_left = 19.0
	inactive_tab_style.content_margin_top = 10.0
	inactive_tab_style.content_margin_right = 10.0
	inactive_tab_style.content_margin_bottom = 10.0
	inactive_tab_style.bg_color = Color(0, 0, 0, 0)

	hover_tab_style = StyleBoxFlat.new()
	hover_tab_style.content_margin_left = 18.0
	hover_tab_style.content_margin_top = 10.0
	hover_tab_style.content_margin_right = 10.0
	hover_tab_style.content_margin_bottom = 10.0
	hover_tab_style.bg_color = Color(1, 1, 1, 0.03)
	hover_tab_style.border_width_left = 1
	hover_tab_style.border_width_top = 0
	hover_tab_style.border_width_right = 0
	hover_tab_style.border_width_bottom = 0
	hover_tab_style.border_color = Color(0.909804, 0.894118, 0.862745, 0.2)

	hover_active_tab_style = StyleBoxFlat.new()
	hover_active_tab_style.content_margin_left = 17.0
	hover_active_tab_style.content_margin_top = 10.0
	hover_active_tab_style.content_margin_right = 10.0
	hover_active_tab_style.content_margin_bottom = 10.0
	hover_active_tab_style.bg_color = Color(ThemeColors.real.r, ThemeColors.real.g, ThemeColors.real.b, 0.1)
	hover_active_tab_style.border_width_left = 2
	hover_active_tab_style.border_width_top = 0
	hover_active_tab_style.border_width_right = 0
	hover_active_tab_style.border_width_bottom = 0
	hover_active_tab_style.border_color = ThemeColors.gold

	for i in range(tab_buttons.size()):
		var btn = tab_buttons[i]
		if btn:
			btn.flat = false
			btn.add_theme_stylebox_override("hover", hover_tab_style)
			btn.add_theme_stylebox_override("pressed", active_tab_style)
			btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
			btn.pressed.connect(func(): _on_tab_button_pressed(i))

	tab_container.tab_changed.connect(func(_idx): _update_tab_buttons_styling())
	_update_tab_buttons_styling()

	re_input.text_submitted.connect(_on_re_text_submitted)
	im_input.text_submitted.connect(_on_im_text_submitted)
	re_input.theme_type_variation = &"ValueRealLineEdit"
	im_input.theme_type_variation = &"ValueImaginaryLineEdit"
	height_a_input.text_submitted.connect(_on_height_a_text_submitted)
	height_eps_input.text_submitted.connect(_on_height_eps_text_submitted)
	func_rational_input.text_submitted.connect(_on_func_rational_text_submitted)
	input_rational_input.text_submitted.connect(_on_input_rational_text_submitted)

	curves_checkbox.toggled.connect(_on_curves_toggled)
	curves_labels_checkbox.toggled.connect(_on_curves_labels_toggled)
	critical_checkbox.toggled.connect(_on_critical_toggled)
	flow_checkbox.toggled.connect(_on_flow_toggled)
	position_marker_checkbox.toggled.connect(_on_position_marker_toggled)
	minimap_checkbox.toggled.connect(_on_minimap_toggled)
	hud_phase_wheel_checkbox.toggled.connect(_on_hud_phase_wheel_toggled)
	hud_position_checkbox.toggled.connect(_on_hud_navigation_toggled)
	hud_zeros_checkbox.toggled.connect(_on_hud_zeros_toggled)
	rvm_checkbox.toggled.connect(_on_rvm_toggled)
	hud_monitor_fps_checkbox.toggled.connect(_on_hud_monitor_fps_toggled)
	color_scheme_button.item_selected.connect(_on_color_scheme_selected)

	apply_button.pressed.connect(_on_set_pos_pressed)
	close_button.pressed.connect(func(): toggle_menu(false))
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
	get_viewport().size_changed.connect(func(): emit_signal("update_hud_layout_signal"))

	_populate_function_dropdown(func_button, false)
	_populate_function_dropdown(input_button, true)

	height_button.clear()
	height_button.add_item("|f|")
	height_button.add_item("a·log(|f| + ε)")
	height_button.add_item("Im(f)")
	height_button.add_item("Re(f)")
	height_button.add_item("Re(e^(-iθ)·f)")
	height_button.add_item("0")

	terrain_detail_button.clear()
	terrain_detail_button.add_item("High")
	terrain_detail_button.add_item("Medium")
	terrain_detail_button.add_item("Low")

	rendering_scale_slider.get_slider().min_value = 0.1
	rendering_scale_slider.get_slider().max_value = 2.0
	rendering_scale_slider.get_slider().step = 0.05

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
	color_scheme_button.add_item("Grayscale")

	morph_style_dropdown.clear()
	morph_style_dropdown.add_item("Disabled")
	morph_style_dropdown.add_item("Linear")

	# TODO: Implement better exponential morph style
	#morph_style_dropdown.add_item("Exponential")

	emit_signal("apply_aa_signal")
	_disable_sliders_focus(self )

	iter_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Iterations"))
	height_theta_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Parameter θ"))
	morph_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Morph Transition"))
	Config.config_changed.connect(_on_config_changed)
	morph_style_dropdown.item_selected.connect(_on_morph_style_selected)
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
	rendering_scale_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "Rendering Scale"))
	view_distance_slider.detach_requested.connect(func(s, v): detach_controller.detach_slider_control(s, v, "View Distance"))

	main_menu_panel.scale = Vector2.ONE
	_rescale_menu(Config.menu_scale)

	var menu_scale_hslider = menu_scale_slider.get_slider()
	if menu_scale_hslider:
		menu_scale_hslider.drag_started.connect(func():
			_menu_scale_dragging = true
		)
		menu_scale_hslider.drag_ended.connect(func(_value_changed: bool):
			_menu_scale_dragging = false
			_rescale_menu(Config.menu_scale)
		)
	_update_morph_style_ui()


func _init_slider_bindings():
	var bindings = {
		rendering_scale_slider: {
			"config_key": "rendering_scale",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return "%.2f" % v
		},
		camera_height_slider: {
			"config_key": "camera_height",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return "%.1f" % v
		},
		speed_slider: {
			"config_key": "movement_speed",
			"to_config": func(v): return v * 10.0,
			"from_config": func(c): return c * 0.1,
			"format": func(v): return "%.1f" % v
		},
		master_volume_slider: {
			"config_key": "master_volume",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%"
		},
		bg_music_slider: {
			"config_key": "bg_music_volume",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%"
		},
		drone_slider: {
			"config_key": "drone_volume",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%"
		},
		zero_proximity_nav_slider: {
			"config_key": "zero_proximity_nav",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return "%.2f" % v
		},
		zoom_slider: {
			"config_key": "zoom_factor",
			"to_config": func(v): return _slider_to_zoom(v),
			"from_config": func(c): return _zoom_to_slider(c),
			"format": func(v): return "x%.2f" % _slider_to_zoom(v)
		},
		zero_speed_slider: {
			"config_key": "speed_near_zeros",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "%"
		},
		view_distance_slider: {
			"config_key": "view_distance",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v)))
		},
		day_duration_slider: {
			"config_key": "day_duration",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return _format_time(v)
		},
		day_time_slider: {
			"config_key": "day_time",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return _format_time(v)
		},
		sunrise_slider: {
			"config_key": "sunrise_direction",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))) + "°"
		},
		sky_luminosity_slider: {
			"config_key": "sky_luminosity",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		sun_luminosity_slider: {
			"config_key": "sun_luminosity",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		self_illumination_slider: {
			"config_key": "self_illumination",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		fog_density_slider: {
			"config_key": "fog_density",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return "%.1f%%" % v
		},
		menu_scale_slider: {
			"config_key": "menu_scale",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%",
			"on_changed": func(_v): emit_signal('update_hud_layout_signal')
		},
		hud_scale_slider: {
			"config_key": "hud_scale",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		iter_slider: {
			"config_key": "iterations",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v)))
		},
		height_theta_slider: {
			"config_key": "height_theta",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return "%.2f rad" % v
		},
		multivalued_slider: {
			"config_key": "multivalued_n",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v))),
			"on_changed": func(_v): _update_branch_k_slider_range()
		},
		branch_k_slider: {
			"config_target": GameState, "config_key": "current_branch",
			"to_config": func(v): return int(round(v)),
			"from_config": func(c): return c,
			"format": func(v): return str(int(round(v)))
		},
		brightness_slider: {
			"config_key": "terrain_brightness",
			"to_config": func(v): return v / 50.0,
			"from_config": func(c): return c * 50.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		saturation_slider: {
			"config_key": "terrain_saturation",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		albedo_slider: {
			"config_key": "terrain_albedo",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		emission_slider: {
			"config_key": "terrain_emission",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		metallic_slider: {
			"config_key": "terrain_metallic",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		roughness_slider: {
			"config_key": "terrain_roughness",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		surface_texture_slider: {
			"config_key": "terrain_surface_texture",
			"to_config": func(v): return v / 100.0,
			"from_config": func(c): return c * 100.0,
			"format": func(v): return str(int(round(v))) + "%"
		},
		morph_slider: {
			"config_target": GameState, "config_key": "morph_value",
			"to_config": func(v): return v,
			"from_config": func(c): return c,
			"format": func(v): return "%.2f" % v
		}
	}
	for slider in bindings:
		if slider != null:
			SLIDER_BINDINGS[slider] = bindings[slider]

func _on_generic_slider_changed(slider: Control, value: float):
	if _syncing_ui:
		return
	if not SLIDER_BINDINGS.has(slider):
		return
	var binding = SLIDER_BINDINGS[slider]

	if "format" in binding:
		slider.value_text = binding["format"].call(value)

	if binding.get("config_key", "") != "":
		var cfg_val = binding["to_config"].call(value)
		binding.get("config_target", Config).set(binding["config_key"], cfg_val)

	if binding.has("on_changed"):
		binding["on_changed"].call(value)

var _menu_scale_dragging: bool = false

var current_submitted_func: int = -1
var current_submitted_input: int = -1
var last_submitted_func: int = -1
var last_submitted_input: int = -1

var _syncing_ui: bool = false

func _disable_sliders_focus(node: Node):
	if node is HSlider:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_sliders_focus(child)


func _populate_function_dropdown(button: OptionButton, exclude_multivalued: bool):
	button.clear()
	var sorted_keys = Config.FUNCTIONS.keys()
	sorted_keys.sort()
	for f_key in sorted_keys:
		var f_data = Config.FUNCTIONS.get(f_key, {})
		if f_data.get("hidden", false) and not GameState.show_hidden_options:
			continue
		if exclude_multivalued and f_data.get("is_multivalued", false):
			continue
		button.add_item(f_data.get("name", "Unknown"), f_key)

func _on_func_item_selected(index):
	_on_func_selected(func_button.get_item_id(index))

func _on_input_item_selected(index: int):
	_on_input_selected(input_button.get_item_id(index))

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_P and event.ctrl_pressed:
		var target_func = last_submitted_func if current_submitted_func == Config.function_type else current_submitted_func
		var target_input = last_submitted_input if current_submitted_input == Config.input_function_type else current_submitted_input

		var func_index = func_button.get_item_index(target_func)
		var input_index = input_button.get_item_index(target_input)

		if func_index >= 0:
			func_button.select(func_index)
			var was_syncing = _syncing_ui
			_syncing_ui = true
			_on_func_item_selected(func_index)
			_syncing_ui = was_syncing
		if input_index >= 0:
			input_button.select(input_index)
			var was_syncing = _syncing_ui
			_syncing_ui = true
			_on_input_item_selected(input_index)
			_syncing_ui = was_syncing

		if func_index >= 0 or input_index >= 0:
			_on_set_pos_pressed(false)
			get_viewport().set_input_as_handled()

func _on_input_selected(f_type: int):
	Config.input_function_type = f_type
	var f_data = Config.FUNCTIONS.get(f_type, {})
	var is_rational = f_data.get("is_rational", false)
	input_rational_container.visible = is_rational
	if is_rational:
		_on_input_rational_text_submitted(input_rational_input.text)

func _on_func_selected(f_type: int):
	Config.function_type = f_type
	var f_data = Config.function

	var is_dirichlet = f_data.get("is_dirichlet", false)
	var iters_range = f_data.get("iters_range", {})
	var has_iters = !iters_range.is_empty()
	var is_rational = f_data.get("is_rational", false)
	var is_multivalued_n = f_type == Config.ComplexFunc.MULTIVALUED_Z_POW

	var was_syncing = _syncing_ui
	if has_iters:
		_syncing_ui = true
		iter_slider.min_value = iters_range[0]
		iter_slider.max_value = iters_range[1]
		iter_slider.step = iters_range[2]

		Config.iterations = Config.function_iterations.get(f_type, iters_range[3])
		iter_slider.set_value_no_signal(Config.iterations)
		if SLIDER_BINDINGS.has(iter_slider) and "format" in SLIDER_BINDINGS[iter_slider]:
			iter_slider.value_text = SLIDER_BINDINGS[iter_slider]["format"].call(Config.iterations)
		_syncing_ui = was_syncing

	func_rational_container.visible = is_rational
	if is_rational:
		_on_func_rational_text_submitted(func_rational_input.text)
	multivalued_slider.visible = is_multivalued_n
	iter_slider.visible = has_iters
	critical_checkbox.visible = is_dirichlet
	auto_walk_checkbox.visible = is_dirichlet
	rvm_checkbox.visible = is_dirichlet

	var is_multivalued = f_data.get("is_multivalued", false)
	branch_k_slider.visible = is_multivalued
	_update_branch_k_slider_range()

	if is_multivalued:
		input_button.disabled = true
		input_button.select(input_button.get_item_index(Config.ComplexFunc.IDENTITY))
		_on_input_selected(Config.ComplexFunc.IDENTITY)
	else:
		input_button.disabled = false

	var re = _parse_float_input(re_input, 0.5)
	var im = _parse_float_input(im_input, 0.0)

	if player and not _syncing_ui:
		var target_pos = Config.complex_to_world(re, im)
		player.teleport_to_world_pos(Vector3(target_pos.x, 0, target_pos.y))

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


func _on_set_pos_pressed(_toggle_menu: bool = true):
	var audio = get_node_or_null("/root/Main/Audio")
	if audio.has_method("trigger_teleport_fade"):
		audio.trigger_teleport_fade()

	GameState.performance_protection_active = false
	var re = _parse_float_input(re_input, 0.5)
	var im = _parse_float_input(im_input, 0.0)

	var h_a = _parse_float_input(height_a_input, 3.0)
	var h_eps = _parse_float_input(height_eps_input, 1.0)

	if !hud_zeros_checkbox.button_pressed:
		GameState.visited_zeros.clear()
		GameState.total_zeros_found = 0

	# Apply non-slider values to Config
	Config.height_a = h_a
	Config.height_epsilon = h_eps

	# Apply all sliders to Config via bindings
	for slider in SLIDER_BINDINGS:
		var binding = SLIDER_BINDINGS[slider]
		var cfg_key = binding.get("config_key", "")
		if cfg_key != "":
			var cfg_val = binding["to_config"].call(slider.value)
			binding.get("config_target", Config).set(cfg_key, cfg_val)

	# Ensure effective zoom is updated from applied zoom_factor
	Config.apply_zoom_immediate()

	Config.terrain_detail = terrain_detail_button.selected
	Config.antialiasing_mode = aa_button.selected
	Config.color_scheme = color_scheme_button.selected
	Config.show_curves = curves_checkbox.button_pressed
	Config.show_curves_labels = curves_labels_checkbox.button_pressed
	Config.show_critical_stripe = critical_checkbox.button_pressed
	Config.shadows_enabled = shadows_checkbox.button_pressed
	Config.show_minimap = minimap_checkbox.button_pressed
	Config.show_hud_phase_wheel = hud_phase_wheel_checkbox.button_pressed
	Config.show_hud_navigation = hud_position_checkbox.button_pressed
	Config.show_hud_zeros = hud_zeros_checkbox.button_pressed
	Config.show_rvm = rvm_checkbox.button_pressed
	Config.show_hud_monitor_fps = hud_monitor_fps_checkbox.button_pressed
	Config.show_flow = flow_checkbox.button_pressed
	Config.show_position_marker = position_marker_checkbox.button_pressed

	var new_func = func_button.get_item_id(func_button.selected)
	var new_input = input_button.get_item_id(input_button.selected)
	if new_func != current_submitted_func or new_input != current_submitted_input:
		last_submitted_func = current_submitted_func
		last_submitted_input = current_submitted_input
		current_submitted_func = new_func
		current_submitted_input = new_input

	Config.function_type = new_func
	Config.input_function_type = new_input
	Config.height_type = height_button.selected

	emit_signal('apply_aa_signal')

	if Config.function_type == Config.ComplexFunc.RATIONAL:
		var coeffs = _parse_rational_expression(func_rational_input.text)
		Config.rational_num_coeffs = coeffs[0]
		Config.rational_den_coeffs = coeffs[1]

	if Config.input_function_type == Config.ComplexFunc.RATIONAL:
		var coeffs = _parse_rational_expression(input_rational_input.text)
		Config.input_rational_num_coeffs = coeffs[0]
		Config.input_rational_den_coeffs = coeffs[1]

	Config.save_settings()
	emit_signal('update_hud_layout_signal')
	preset_controller.update_preset_button_text()

	GameState.visited_zeros.clear()
	GameState.total_zeros_found = 0

	if player:
		if is_finite(re) and is_finite(im) and player:
			var target_pos = Config.complex_to_world(re, im)
			player.teleport_to_world_pos(Vector3(target_pos.x, player.global_position.y, target_pos.y))

		var f_data = Config.function
		if f_data.get("is_dirichlet", false):
			GameState.rvm_start_t = abs(Config.world_to_complex(0.0, player.global_position.z).y)

		# Update auto-walk state
		if auto_walk_checkbox.button_pressed:
			if player.auto_walk_state == 0 or player.auto_walk_state == 3: # NONE or NEWTON_WALK
				player.auto_walk_state = 1 # MOVING_TO_LINE
				GameState.rvm_start_t = abs(Config.world_to_complex(0.0, player.global_position.z).y)
				if "last_detected_t" in player:
					player.last_detected_t = -1.0
		elif zero_walk_checkbox.button_pressed:
			if player.auto_walk_state == 0 or player.auto_walk_state == 1 or player.auto_walk_state == 2:
				player.auto_walk_state = 0 # Reset state before starting newton walk
				player.start_newton_walk()
		else:
			player.auto_walk_state = 0 # NONE

	emit_signal('update_hud_layout_signal')

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
			var cfg_val = binding.get("config_target", Config).get(cfg_key)
			if cfg_val == null:
				cfg_val = 0.0
			var ui_val = binding["from_config"].call(cfg_val)
			if ui_val == null:
				ui_val = 0.0
			slider.set_value_no_signal(ui_val)
			slider.value_text = binding["format"].call(ui_val)
			if binding.has("on_changed"):
				binding["on_changed"].call(ui_val)

	height_a_input.text = str(Config.height_a)
	height_eps_input.text = str(Config.height_epsilon)

	terrain_detail_button.selected = Config.terrain_detail
	aa_button.selected = Config.antialiasing_mode
	color_scheme_button.selected = Config.color_scheme

	curves_checkbox.button_pressed = Config.show_curves
	curves_labels_checkbox.button_pressed = Config.show_curves_labels
	critical_checkbox.button_pressed = Config.show_critical_stripe
	shadows_checkbox.button_pressed = Config.shadows_enabled
	minimap_checkbox.button_pressed = Config.show_minimap
	hud_phase_wheel_checkbox.button_pressed = Config.show_hud_phase_wheel
	hud_position_checkbox.button_pressed = Config.show_hud_navigation
	hud_phase_wheel_checkbox.visible = Config.show_hud_navigation
	hud_zeros_checkbox.button_pressed = Config.show_hud_zeros
	rvm_checkbox.button_pressed = Config.show_rvm
	hud_monitor_fps_checkbox.button_pressed = Config.show_hud_monitor_fps

	if player:
		auto_walk_checkbox.button_pressed = (player.auto_walk_state == 1 or player.auto_walk_state == 2)
		zero_walk_checkbox.button_pressed = (player.auto_walk_state == 3)

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
	emit_signal('apply_aa_signal')

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

func _on_minimap_toggled(pressed: bool):
	Config.show_minimap = pressed

func _on_hud_phase_wheel_toggled(pressed: bool):
	Config.show_hud_phase_wheel = pressed

func _on_hud_navigation_toggled(pressed: bool):
	Config.show_hud_navigation = pressed
	hud_phase_wheel_checkbox.visible = pressed
	emit_signal('update_hud_layout_signal')

func _on_hud_zeros_toggled(pressed: bool):
	Config.show_hud_zeros = pressed
	if not pressed:
		GameState.visited_zeros.clear()
		GameState.total_zeros_found = 0
		emit_signal('update_hud_layout_signal')

func _on_rvm_toggled(pressed: bool):
	Config.show_rvm = pressed

func _on_hud_monitor_fps_toggled(pressed: bool):
	Config.show_hud_monitor_fps = pressed

func _on_color_scheme_selected(index: int):
	Config.color_scheme = index

func _parse_float_input(input_node: LineEdit, default_value: float) -> float:
	var text = input_node.text
	if not text.is_valid_float():
		var default_str = "0.0" if default_value == 0.0 else str(default_value)
		# Try to keep decimal point for 3.0, 1.0 etc if it's an integer
		if default_value == round(default_value):
			default_str = "%.1f" % default_value
		input_node.text = default_str
		return default_value
	var val = float(text)
	if not is_finite(val):
		var default_str = "0.0" if default_value == 0.0 else str(default_value)
		if default_value == round(default_value):
			default_str = "%.1f" % default_value
		input_node.text = default_str
		return default_value
	return val

func _on_re_text_submitted(_new_text: String):
	var re = _parse_float_input(re_input, 0.0)
	if player:
		var current_complex = Config.world_to_complex(player.global_position.x, player.global_position.z)
		var target_x = Config.complex_to_world(re, current_complex.y).x
		player.teleport_to_world_pos(Vector3(target_x, player.global_position.y, player.global_position.z))

func _on_im_text_submitted(_new_text: String):
	var im = _parse_float_input(im_input, 0.0)
	if player:
		var current_complex = Config.world_to_complex(player.global_position.x, player.global_position.z)
		var target_z = Config.complex_to_world(current_complex.x, im).y
		player.teleport_to_world_pos(Vector3(player.global_position.x, player.global_position.y, target_z))

func _on_height_a_text_submitted(_new_text: String):
	var h_a = _parse_float_input(height_a_input, 3.0)
	Config.height_a = h_a

func _on_height_eps_text_submitted(_new_text: String):
	var h_eps = _parse_float_input(height_eps_input, 1.0)
	Config.height_epsilon = h_eps

func _on_func_rational_text_submitted(new_text: String):
	if Config.function_type == Config.ComplexFunc.RATIONAL:
		var coeffs = _parse_rational_expression(new_text)
		Config.rational_num_coeffs = coeffs[0]
		Config.rational_den_coeffs = coeffs[1]

func _on_input_rational_text_submitted(new_text: String):
	if Config.input_function_type == Config.ComplexFunc.RATIONAL:
		var coeffs = _parse_rational_expression(new_text)
		Config.input_rational_num_coeffs = coeffs[0]
		Config.input_rational_den_coeffs = coeffs[1]

func _parse_rational_expression(text: String) -> Array:
	var expr = text.replace(" ", "")
	var num_coeffs
	var den_coeffs
	if "/" in expr:
		var parts = expr.split("/")
		var num_str = parts[0]
		if num_str.begins_with("(") and num_str.ends_with(")"):
			num_str = num_str.substr(1, num_str.length() - 2)
		var den_str = parts[1]
		if den_str.begins_with("(") and den_str.ends_with(")"):
			den_str = den_str.substr(1, den_str.length() - 2)

		num_coeffs = FormulaParser.parse_poly(num_str)
		den_coeffs = FormulaParser.parse_poly(den_str)
	else:
		num_coeffs = FormulaParser.parse_poly(expr)
		den_coeffs = PackedVector2Array([Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	return [num_coeffs, den_coeffs]

func _rescale_menu(_scale: float):
	if main_menu_panel == null: return

	# We use meta to check if we already applied this scale to avoid redundant traversals
	if main_menu_panel.has_meta("last_applied_menu_scale") and main_menu_panel.get_meta("last_applied_menu_scale") == _scale:
		return
	main_menu_panel.set_meta("last_applied_menu_scale", _scale)

	var actual_scale = _scale

	var stack = []
	stack.push_back(main_menu_panel)
	stack.push_back(new_preset_dialog)
	stack.push_back(delete_preset_dialog)
	stack.push_back(quit_dialog)

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

		# Scale Sliders and ScrollBars
		if node is HSlider or node is VScrollBar or node is HScrollBar:
			var scale_factor = max(1.0, actual_scale)

			if node is HSlider:
				if not node.has_meta("base_scaled_slider"):
					node.set_meta("base_scaled_slider", true)

				var grabber_size = int(round(18 * scale_factor))
				var center = Vector2(grabber_size / 2.0, grabber_size / 2.0)
				var inner_radius = 6.0 * scale_factor
				var outer_radius = 6.5 * scale_factor

				var normal_color = ThemeColors.gold
				var hover_color = normal_color.lightened(0.2)
				var pressed_color = normal_color.darkened(0.2)

				var tex_normal = _create_scaled_grabber_texture(normal_color, grabber_size, center, inner_radius, outer_radius)
				var tex_hover = _create_scaled_grabber_texture(hover_color, grabber_size, center, inner_radius, outer_radius)
				var tex_pressed = _create_scaled_grabber_texture(pressed_color, grabber_size, center, inner_radius, outer_radius)

				node.add_theme_icon_override("grabber", tex_normal)
				node.add_theme_icon_override("grabber_highlight", tex_hover)
				node.add_theme_icon_override("grabber_disabled", tex_normal)
				node.set_meta("custom_grabber_pressed", tex_pressed)
				node.set_meta("custom_grabber_highlight", tex_hover)

				for style_name in ["slider", "grabber_area", "grabber_area_highlight"]:
					var base_style = node.get_theme_stylebox(style_name)
					if base_style and base_style is StyleBoxFlat:
						if not node.has_meta("base_style_" + style_name + "_top"):
							node.set_meta("base_style_" + style_name + "_top", base_style.content_margin_top)
							node.set_meta("base_style_" + style_name + "_bottom", base_style.content_margin_bottom)

						var dup = base_style.duplicate()
						dup.content_margin_top = node.get_meta("base_style_" + style_name + "_top") * scale_factor
						dup.content_margin_bottom = node.get_meta("base_style_" + style_name + "_bottom") * scale_factor
						node.add_theme_stylebox_override(style_name, dup)

			if node is VScrollBar:
				for style_name in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
					var base_style = node.get_theme_stylebox(style_name)
					if base_style and base_style is StyleBoxFlat:
						if not node.has_meta("base_style_" + style_name + "_left"):
							node.set_meta("base_style_" + style_name + "_left", base_style.content_margin_left)
							node.set_meta("base_style_" + style_name + "_right", base_style.content_margin_right)

						var dup = base_style.duplicate()
						dup.content_margin_left = node.get_meta("base_style_" + style_name + "_left") * scale_factor
						dup.content_margin_right = node.get_meta("base_style_" + style_name + "_right") * scale_factor
						node.add_theme_stylebox_override(style_name, dup)

			if node is HScrollBar:
				for style_name in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
					var base_style = node.get_theme_stylebox(style_name)
					if base_style and base_style is StyleBoxFlat:
						if not node.has_meta("base_style_" + style_name + "_top"):
							node.set_meta("base_style_" + style_name + "_top", base_style.content_margin_top)
							node.set_meta("base_style_" + style_name + "_bottom", base_style.content_margin_bottom)

						var dup = base_style.duplicate()
						dup.content_margin_top = node.get_meta("base_style_" + style_name + "_top") * scale_factor
						dup.content_margin_bottom = node.get_meta("base_style_" + style_name + "_bottom") * scale_factor
						node.add_theme_stylebox_override(style_name, dup)

		# Traverse children
		for child in node.get_children(true):
			if child is Control:
				stack.push_back(child)


func _process(delta: float):
	if _title_clicks > 0:
		_title_click_timer -= delta
		if _title_click_timer <= 0.0:
			_title_clicks = 0
			# Performance: Suspend _process when the title click timer expires
			set_process(false)

func _on_title_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_title_clicks += 1

		if _title_clicks == 1:
			set_process(true)

		_title_click_timer = 1.0 # 1 second window to do the 3 clicks
		if _title_clicks >= 3:
			GameState.show_hidden_options = !GameState.show_hidden_options
			_populate_function_dropdown(func_button, false)
			_populate_function_dropdown(input_button, true)

			var f_idx = func_button.get_item_index(current_submitted_func)
			if f_idx >= 0: func_button.select(f_idx)
			var i_idx = input_button.get_item_index(current_submitted_input)
			if i_idx >= 0: input_button.select(i_idx)

			if GameState.show_hidden_options:
				title_label.add_theme_color_override("font_color", ThemeColors.gold)
			else:
				title_label.add_theme_color_override("font_color", Color(0.909804, 0.894118, 0.862745))

			_title_clicks = 0

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
			btn.add_theme_color_override("font_color", ThemeColors.gold)
			btn.add_theme_color_override("font_hover_color", ThemeColors.gold)
			btn.add_theme_color_override("font_pressed_color", ThemeColors.gold)
			btn.add_theme_color_override("font_focus_color", ThemeColors.gold)
		else:
			btn.add_theme_stylebox_override("normal", inactive_tab_style)
			btn.add_theme_stylebox_override("hover", hover_tab_style)
			btn.add_theme_color_override("font_color", Color(0.909804, 0.894118, 0.862745, 0.5))
			btn.add_theme_color_override("font_hover_color", Color(0.909804, 0.894118, 0.862745, 1.0))
			btn.add_theme_color_override("font_pressed_color", Color(0.909804, 0.894118, 0.862745, 0.3))
			btn.add_theme_color_override("font_focus_color", Color(0.909804, 0.894118, 0.862745, 0.5))


func _format_time(total_seconds: float) -> String:
	var hours = int(total_seconds) / 3600.0
	var minutes = (int(total_seconds) % 3600) / 60.0
	var seconds = int(total_seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func _slider_to_zoom(value: float) -> float:
	var min_zoom = 0.1
	var max_zoom = 100.0
	var b = (log(max_zoom) - log(min_zoom)) / 100.0
	return exp(log(min_zoom) + value * b)


func _zoom_to_slider(zoom: float) -> float:
	var min_zoom = 0.1
	var max_zoom = 100.0
	var b = (log(max_zoom) - log(min_zoom)) / 100.0
	return (log(zoom) - log(min_zoom)) / b


func _format_float_3(val: float) -> String:
	return "%.3f" % snappedf(val, 0.001)

func toggle_menu(applied: bool = false):
	if detach_controller.visible:
		detach_controller.interaction_active = !detach_controller.interaction_active
		if detach_controller.interaction_active:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			GameState.is_detached_interactive = true
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			GameState.is_detached_interactive = false
		return

	main_menu_panel.scale = Vector2.ONE
	_rescale_menu(Config.menu_scale)

	visible = !visible
	GameState.is_menu_open = visible

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
		_initial_rendering_scale = Config.rendering_scale
		_initial_view_distance = Config.view_distance
		_initial_shadows_enabled = Config.shadows_enabled
		_initial_preset = Config.current_preset
		_initial_edited_presets = Config._edited_presets.duplicate(true)

		_sync_ui_to_config()

		freeze_time_checkbox.button_pressed = Config.freeze_time

		if player:
			var complex_pos = Config.world_to_complex(player.global_position.x, player.global_position.z)
			var re_val = complex_pos.x
			var im_val = complex_pos.y
			if not is_finite(re_val): re_val = 0.5
			if not is_finite(im_val): im_val = 0.0
			re_input.text = _format_float_3(re_val)
			im_input.text = _format_float_3(im_val)

		preset_controller.update_preset_button_text()

	else:
		if not detach_controller.visible and not detach_controller.is_detaching:
			Config.morph_style = Config.MorphStyle.DISABLED
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
			Config.sky_luminosity = _initial_sky_luminosity
			Config.sun_luminosity = _initial_sun_luminosity
			Config.self_illumination = _initial_self_illumination
			Config.freeze_time = _initial_freeze_time
			Config.day_duration = _initial_day_duration
			Config.day_time = _initial_day_time
			Config.fog_density = _initial_fog_density
			GameState.morph_value = _initial_morph_value
			Config.terrain_detail = _initial_terrain_detail
			Config.antialiasing_mode = _initial_antialiasing_mode
			Config.rendering_scale = _initial_rendering_scale
			Config.view_distance = _initial_view_distance
			Config.shadows_enabled = _initial_shadows_enabled
			Config.current_preset = _initial_preset
			Config._edited_presets = _initial_edited_presets

			emit_signal('apply_aa_signal')


static func _create_scaled_grabber_texture(color: Color, _size: int, center: Vector2, inner_radius: float, outer_radius: float) -> Texture2D:
	var tex = GradientTexture2D.new()
	tex.width = _size
	tex.height = _size
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = center / float(_size)
	tex.fill_to = Vector2(center.x + outer_radius, center.y) / float(_size)

	var grad = Gradient.new()
	grad.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_LINEAR
	var inner_offset = inner_radius / outer_radius
	grad.offsets = PackedFloat32Array([0.0, inner_offset, 1.0])
	grad.colors = PackedColorArray([color, color, Color(color.r, color.g, color.b, 0.0)])

	tex.gradient = grad
	return tex

func _on_morph_style_selected(index: int):
	Config.morph_style = index

func _on_config_changed(key: String):
	if key == "morph_style":
		_update_morph_style_ui()

func _update_morph_style_ui():
	morph_style_dropdown.selected = Config.morph_style
	morph_slider.visible = Config.morph_style != Config.MorphStyle.DISABLED

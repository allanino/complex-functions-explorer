extends CanvasLayer

@export var player: Node3D
@onready var hud_columns = %MainUIColumns
@onready var hud_stack_left = %MainUIStackLeft
@onready var hud_stack_right = %MainUIStackRight
@onready var complex_panel = %ComplexAspect
@onready var info_panel = %InfoPanel
@onready var monitor_panel = %MonitorPanel
@onready var fps_label = %FpsLabel
@onready var complex_rect = %ComplexPlane
@onready var world_manager = get_node_or_null("../WorldManager")
@onready var domain_label = %DomainLabel
@onready var target_label = %TargetLabel
@onready var zeros_panel = %ZerosPanel
@onready var zeros_count_label = %CountLabel
@onready var rvm_label = %RvmLabel
@onready var zeros_list_label = %ListLabel
@onready var menu_overlay = %MenuOverlay

# New UI Node Paths
@onready var tab_container = %MenuOverlay/%TabContainer
@onready var func_button = %MenuOverlay/%FuncButton
@onready var height_button = %MenuOverlay/%HeightButton
@onready var height_a_container = %MenuOverlay/%HeightAContainer
@onready var height_a_input = %MenuOverlay/%HeightAInput
@onready var height_eps_container = %MenuOverlay/%HeightEpsContainer
@onready var height_eps_input = %MenuOverlay/%HeightEpsInput
@onready var iter_slider = %MenuOverlay/%IterSlider
@onready var rational_container = %MenuOverlay/%RationalContainer
@onready var rational_input = %MenuOverlay/%RationalInput
@onready var multivalued_slider = %MenuOverlay/%MultivaluedSlider

@onready var re_input = %MenuOverlay/%ReInput
@onready var im_input = %MenuOverlay/%ImInput
@onready var speed_input = %MenuOverlay/%SpeedInput
@onready var zoom_slider = %MenuOverlay/%ZoomContainer
@onready var zero_speed_slider = %MenuOverlay/%ZeroSpeedContainer
@onready var zero_proximity_nav_slider = %MenuOverlay/%ZeroProximityNavContainer
@onready var camera_height_input = %MenuOverlay/%CameraHeightInput
@onready var auto_walk_checkbox = %MenuOverlay/%AutoWalkCheckbox

@onready var terrain_detail_button = %MenuOverlay/%TerrainDetailButton
@onready var aa_button = %MenuOverlay/%AAButton
@onready var color_scheme_button = %MenuOverlay/%ColorSchemeButton
@onready var view_distance_slider = %MenuOverlay/%ViewDistanceContainer
@onready var curves_checkbox = %MenuOverlay/%CurvesCheckbox
@onready var critical_checkbox = %MenuOverlay/%CriticalCheckbox
@onready var flow_checkbox = %MenuOverlay/%FlowCheckbox
@onready var freeze_time_checkbox = %MenuOverlay/%FreezeTimeCheckbox
@onready var day_duration_slider = %MenuOverlay/%DayDurationSlider
@onready var day_time_slider = %MenuOverlay/%DayTimeSlider
@onready var sunrise_slider = %MenuOverlay/%SunriseContainer
@onready var sky_luminosity_slider = %MenuOverlay/%SkyLuminosityContainer
@onready var sun_luminosity_slider = %MenuOverlay/%SunLuminosityContainer
@onready var self_illumination_slider = %MenuOverlay/%SelfIlluminationContainer
@onready var fog_density_slider = %MenuOverlay/%FogDensitySlider
@onready var shadows_checkbox = %MenuOverlay/%ShadowsCheckbox

@onready var hud_complex_checkbox = %MenuOverlay/%HudComplexCheckbox
@onready var hud_navigation_checkbox = %MenuOverlay/%HudNavigationCheckbox
@onready var hud_zeros_checkbox = %MenuOverlay/%HudZerosDetectionCheckbox
@onready var rvm_checkbox = %MenuOverlay/%RvmCheckbox
@onready var hud_monitor_fps_checkbox = %MenuOverlay/%HudMonitorFpsCheckbox
@onready var hud_monitor_chunks_checkbox = %MenuOverlay/%HudMonitorChunksCheckbox
@onready var hud_scale_slider = %MenuOverlay/%HudScaleContainer

@onready var master_volume_slider = %MenuOverlay/%MasterVolumeContainer
@onready var bg_music_slider = %MenuOverlay/%BgMusicContainer
@onready var drone_slider = %MenuOverlay/%DroneContainer

@onready var detach_overlay = %MenuOverlay/%DetachOverlay
@onready var detach_slider = %MenuOverlay/%DetachSlider
@onready var detach_label = %MenuOverlay/%Label
@onready var detach_value = %MenuOverlay/%DetachValue
@onready var exit_detach_button = %MenuOverlay/%ExitDetachButton

var active_detached_slider: HSlider = null
var active_detached_value: Label = null

@onready var brightness_slider = %MenuOverlay/%BrightnessContainer
@onready var saturation_slider = %MenuOverlay/%SaturationContainer
@onready var albedo_slider = %MenuOverlay/%AlbedoContainer
@onready var emission_slider = %MenuOverlay/%EmissionContainer
@onready var metallic_slider = %MenuOverlay/%MetallicContainer
@onready var roughness_slider = %MenuOverlay/%RoughnessContainer

@onready var surface_texture_slider = %MenuOverlay/%SurfaceTextureContainer
@onready var morph_slider = %MenuOverlay/%MorphSliderContainer

@onready var preset_button = %MenuOverlay/%PresetButton
@onready var preset_update_button = %MenuOverlay/%PresetUpdateButton
@onready var preset_delete_button = %MenuOverlay/%PresetDeleteButton
@onready var preset_new_button = %MenuOverlay/%PresetNewButton
@onready var preset_restore_button = %MenuOverlay/%PresetRestoreButton
@onready var new_preset_dialog = %MenuOverlay/%NewPresetDialog
@onready var new_preset_input = %MenuOverlay/%NewPresetInput
@onready var new_preset_save = %MenuOverlay/%NewPresetSave
@onready var new_preset_cancel = %MenuOverlay/%NewPresetCancel
@onready var delete_preset_dialog = %MenuOverlay/%DeletePresetDialog
@onready var delete_message_label = %MenuOverlay/%DeleteMessageLabel
@onready var delete_preset_cancel = %MenuOverlay/%DeletePresetCancel
@onready var delete_preset_confirm = %MenuOverlay/%DeletePresetConfirm
@onready var apply_button = %MenuOverlay/%ApplyButton
@onready var close_button = %MenuOverlay/%CloseButton
@onready var quit_button = %MenuOverlay/%QuitButton
@onready var perf_label = %MenuOverlay/%PerfProtectionLabel

@onready var tooltip = %MenuOverlay/%Tooltip
@onready var tooltip_label = %MenuOverlay/%TooltipLabel
@onready var tooltip_timer = %MenuOverlay/%TooltipTimer

var _pending_tooltip_key: String = ""

const DESCRIPTIONS = {
	"Function": "Select the complex function to visualize on the terrain.",
	"Height Map": "Choose how the function's magnitude is mapped to terrain height.",
	"Parameter a": "Scaling factor for logarithmic height mapping.",
	"Parameter ε": "Small offset in logarithmic mapping to prevent log(0) at zeros.",
	"Iterations": "Number of terms used in the summation for Zeta and Eta functions, or steps for Mandelbrot recursion.",
	"Expression": "Enter a rational function expression with complext coefficients using 'z' as variable and 'i' as imaginary unit (e.g., z^2 - i).",
	"Real (x)": "Manually set the real part of the player's position in the complex plane.  Shortcut: CTRL + R to reset to (0, 0)",
	"Imaginary (y)": "Manually set the imaginary part of the player's position. Shortcut: CTRL + R to reset to (0, 0)",
	"Camera Height": "Vertical height of the player's camera above the terrain. Shortcut: SPACE (double press to reset)",
	"Move Speed": "Horizontal movement speed when navigating the complex plane. Shortcut: SHIFT (fast) / CTRL (slow)",
	"Zoom Factor": "Increase detail by scaling coordinates (1.0 / Zoom). Shortcut: Mouse Wheel (click to reset)",
	"Zeros proximity": "Terrain height threshold for detecting function zeros. Actually we look for minima along the path with magnitude below this value.",
	"Speed near Zeros": "Slows down movement speed near function zeros to allow closer inspection.",
	"Automatic Walking": "Automatically follow the critical line (Re = 0.5) to find Riemann Zeta zeros. Shortcut: CTRL + C",
	"Terrain Details": "Quality and subdivision level of the procedurally generated terrain meshes.",
	"Antialiasing": "Choose a technique to reduce jagged edges in the 3D view.",
	"Branches (n)": "Number of branches for the multivalued function z^(1/n).",
	"Morph Time": "Duration of the smooth transition between branches.",
	"Color Scheme": "Select the color mapping for the complex plane of the target function.",
	"View Distance": "Number of terrain chunks loaded around the player.",
	"Level Curves": "Overlay contour lines for integer values of Re(f) (black) and Im(f) (white).",
	"Critical Stripe": "Visual guide indicating the 0 < Re < 1 region where non-trivial zeros reside.",
	"Freeze time": "Choose between a dynamic day/night cycle or a fixed time of day. Shortcut: CTRL + G (Golden Hour) / CTRL + N (Freeze / Unfreeze time)",
	"Day Duration": "Set the real-time duration for a full 24-hour mathematical day cycle.",
	"Time of day": "Manually set the current time of day when time is frozen.",
	"Sunrise Direction": "Adjust the angle from which the sun rises (180° is towards +σ).",
	"Sky Luminosity": "Adjust the overall brightness of the sky and clouds.",
	"Sun Luminosity": "Adjust the intensity of the sun and moon light.",
	"Fog": "Enable or disable global volumetric fog effects.",
	"Fog Density": "Adjust the thickness of the fog and aerial perspective.",
	"Shadows": "Enable real-time directional shadows for terrain features.",
	"Complex plane": "Show the domain coloring map of the current position on the MainUI.",
	"Navigation": "Show coordinate and magnitude information on the MainUI.",
	"Zeros detection": "Show the list of discovered zeros during walking.",
	"Riemann–von Mangoldt": "Show the estimated number of zeta zeros N(t) based on the Riemann–von Mangoldt formula.",
	"Monitor FPS": "Show real-time performance metrics (FPS) on the MainUI.",
	"Monitor Chunks": "Show real-time chunks statistics on the MainUI.",
	"MainUI Scale": "Adjust the size of the MainUI elements.",
	"Master Volume": "Control the global volume level of all sound sources.",
	"Background Music": "Adjust the volume of the ambient mathematical soundscape.",
	"Topographic Drone": "Adjust the volume of the terrain-responsive spatial audio.",
	"Brightness": "Adjust the overall brightness of the terrain surface.",
	"Terrain Morph": "Transition between the flat complex plane and the 3D terrain.",
	"Flow": "Overlay flowing arrows that follow the terrain gradient.",
	"Saturation": "Control the intensity of the domain colors on the terrain.",
	"Albedo": "Base reflectivity of the terrain material.",
	"Emission": "Intensity of the self-illumination of the terrain.",
	"Metallic": "Adjust how metallic the terrain surface appears.",
	"Roughness": "Control the surface smoothness; lower values are glossier."
}

var current_scale = 2.0
var _last_zeros_visible: bool = false
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


func _ready():
	hud_columns.offset_top = -1000
	speed_input.text_changed.connect(func(_t): _speed_modified = true)
	speed_input.text_submitted.connect(_on_speed_text_submitted)
	camera_height_input.text_changed.connect(func(_t): _camera_height_modified = true)
	camera_height_input.text_submitted.connect(_on_camera_height_text_submitted)
	re_input.text_submitted.connect(_on_re_text_submitted)
	im_input.text_submitted.connect(_on_im_text_submitted)
	height_a_input.text_submitted.connect(_on_height_a_text_submitted)
	height_eps_input.text_submitted.connect(_on_height_eps_text_submitted)
	rational_input.text_submitted.connect(_on_rational_text_submitted)

	curves_checkbox.toggled.connect(_on_curves_toggled)
	critical_checkbox.toggled.connect(_on_critical_toggled)
	flow_checkbox.toggled.connect(_on_flow_toggled)
	hud_complex_checkbox.toggled.connect(_on_hud_complex_toggled)
	hud_navigation_checkbox.toggled.connect(_on_hud_navigation_toggled)
	hud_zeros_checkbox.toggled.connect(_on_hud_zeros_toggled)
	rvm_checkbox.toggled.connect(_on_rvm_toggled)
	hud_monitor_fps_checkbox.toggled.connect(_on_hud_monitor_fps_toggled)
	hud_monitor_chunks_checkbox.toggled.connect(_on_hud_monitor_chunks_toggled)
	color_scheme_button.item_selected.connect(_on_color_scheme_selected)


	for preset_name in Config.PRESETS.keys():
		preset_button.add_item(preset_name)

	preset_button.item_selected.connect(_on_preset_selected)
	Config.preset_applied.connect(_on_preset_applied)


	preset_update_button.pressed.connect(_on_preset_update_pressed)
	preset_delete_button.pressed.connect(_on_preset_delete_pressed)
	preset_new_button.pressed.connect(_on_preset_new_pressed)
	preset_restore_button.pressed.connect(_on_preset_restore_pressed)
	_connect_preset_dirtiers()
	new_preset_save.pressed.connect(_on_new_preset_save_pressed)
	new_preset_cancel.pressed.connect(_on_new_preset_cancel_pressed)
	delete_preset_cancel.pressed.connect(_on_delete_preset_cancel_pressed)
	delete_preset_confirm.pressed.connect(_on_delete_preset_confirm_pressed)

	_update_preset_button_text()

	apply_button.pressed.connect(_on_set_pos_pressed)
	close_button.pressed.connect(toggle_menu)
	quit_button.pressed.connect(_on_quit_pressed)
	func_button.item_selected.connect(_on_func_item_selected)
	height_button.item_selected.connect(_on_height_selected)

	master_volume_slider.value_changed.connect(_on_master_volume_value_changed)
	bg_music_slider.value_changed.connect(_on_bg_music_value_changed)
	drone_slider.value_changed.connect(_on_drone_value_changed)
	zero_proximity_nav_slider.value_changed.connect(_on_zero_proximity_nav_value_changed)
	zoom_slider.value_changed.connect(_on_zoom_value_changed)
	zero_speed_slider.value_changed.connect(_on_zero_speed_value_changed)
	view_distance_slider.value_changed.connect(_on_view_distance_value_changed)
	freeze_time_checkbox.toggled.connect(_on_freeze_time_toggled)
	day_duration_slider.value_changed.connect(_on_day_duration_value_changed)
	day_time_slider.value_changed.connect(_on_day_time_value_changed)
	sunrise_slider.value_changed.connect(_on_sunrise_value_changed)
	sky_luminosity_slider.value_changed.connect(_on_sky_luminosity_value_changed)
	sun_luminosity_slider.value_changed.connect(_on_sun_luminosity_value_changed)
	self_illumination_slider.value_changed.connect(_on_self_illumination_value_changed)
	fog_density_slider.value_changed.connect(_on_fog_density_value_changed)
	hud_scale_slider.value_changed.connect(_on_hud_scale_value_changed)
	iter_slider.value_changed.connect(_on_iterations_value_changed)

	terrain_detail_button.item_selected.connect(_on_terrain_detail_selected)
	aa_button.item_selected.connect(_on_aa_selected)
	shadows_checkbox.toggled.connect(_on_shadows_toggled)
	get_viewport().size_changed.connect(_update_hud_layout)
	multivalued_slider.value_changed.connect(_on_multivalued_n_value_changed)

	brightness_slider.value_changed.connect(_on_terrain_brightness_value_changed)
	saturation_slider.value_changed.connect(_on_terrain_saturation_value_changed)
	albedo_slider.value_changed.connect(_on_terrain_albedo_value_changed)
	emission_slider.value_changed.connect(_on_terrain_emission_value_changed)
	metallic_slider.value_changed.connect(_on_terrain_metallic_value_changed)
	roughness_slider.value_changed.connect(_on_terrain_roughness_value_changed)
	surface_texture_slider.value_changed.connect(_on_terrain_surface_texture_value_changed)
	morph_slider.value_changed.connect(_on_morph_slider_changed)

	func_button.clear()
	var sorted_keys = Config.FUNCTIONS.keys()
	sorted_keys.sort()
	for f_key in sorted_keys:
		var f_data = Config.FUNCTIONS.get(f_key, {})
		if f_data.get("hidden", false):
			continue
		func_button.add_item(f_data.get("name", "Unknown"), f_key)

	height_button.clear()
	height_button.add_item("Logarithmic (a*log(ε + abs))")
	height_button.add_item("Absolute")

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

	apply_aa()
	_setup_tooltips()
	_disable_sliders_focus(self )
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	_last_zeros_visible = Config.show_hud_zeros

	detach_slider.value_changed.connect(_on_detach_slider_changed)
	exit_detach_button.pressed.connect(_on_exit_detach_pressed)
	iter_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Iterations"))
	morph_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Terrain Morph"))
	multivalued_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Branches (n)"))
	day_duration_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Day Duration"))
	day_time_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Time of day"))
	sunrise_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Sunrise Direction"))
	sky_luminosity_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Sky Luminosity"))
	sun_luminosity_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Sun Luminosity"))
	self_illumination_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Self-Illumination"))
	fog_density_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Fog Density"))
	brightness_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Brightness"))
	saturation_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Saturation"))
	albedo_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Albedo"))
	emission_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Emission"))
	metallic_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Metallic"))
	roughness_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "Roughness"))
	surface_texture_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "SurfaceTexture"))
	view_distance_slider.detach_requested.connect(func(s, v): _on_detach_pressed(s, v, "View Distance"))

func _disable_sliders_focus(node: Node):
	if node is HSlider:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_disable_sliders_focus(child)

func _setup_tooltips():
	# We want to find all Labels and CheckBoxes in the menu tabs
	var tabs = tab_container.get_children()
	for tab in tabs:
		_connect_tooltips_recursive(tab)

func _connect_tooltips_recursive(node: Node):
	if node is Label or node is CheckBox:
		var text = node.text
		if text in DESCRIPTIONS:
			node.mouse_entered.connect(_on_tooltip_mouse_entered.bind(text))
			node.mouse_exited.connect(_on_tooltip_mouse_exited)
			node.mouse_filter = Control.MOUSE_FILTER_STOP

	for child in node.get_children():
		_connect_tooltips_recursive(child)

func _on_tooltip_mouse_entered(key: String):
	_pending_tooltip_key = key
	tooltip_timer.start()

func _on_tooltip_mouse_exited():
	tooltip_timer.stop()
	tooltip.visible = false
	_pending_tooltip_key = ""

func _any_dropdown_popup():
	return (
		func_button.get_popup().visible
		|| height_button.get_popup().visible
		|| terrain_detail_button.get_popup().visible
		|| aa_button.get_popup().visible
		|| color_scheme_button.get_popup().visible
	)

func _on_tooltip_timer_timeout():
	# Do not draw tooltip behind the dropdown lists
	if _any_dropdown_popup():
		return

	if _pending_tooltip_key != "":
		tooltip_label.custom_minimum_size.x = 250
		tooltip_label.text = DESCRIPTIONS[_pending_tooltip_key]
		if "Shortcut: " in tooltip_label.text:
			tooltip_label.text = tooltip_label.text.replace("Shortcut: ", "\n\n[color=gray]Shortcut: ") + "[/color]"
		# Hide it during layout processing to prevent flicker
		tooltip.modulate.a = 0.0
		tooltip.visible = true
		# Force a complete layout recalculation to fix the first-render height bug
		await get_tree().process_frame
		tooltip.size = Vector2.ZERO
		tooltip.reset_size()
		_update_tooltip_position()
		tooltip.modulate.a = 1.0

func _update_tooltip_position():
	var mouse_pos = get_viewport().get_mouse_position()
	# Position at the tip of the mouse
	tooltip.global_position = mouse_pos + Vector2(5, 5)

func apply_aa():
	var vp = get_viewport()
	# Reset both
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	vp.use_taa = false
	vp.use_debanding = false

	match Config.antialiasing_mode:
		1: vp.msaa_3d = Viewport.MSAA_2X
		2: vp.msaa_3d = Viewport.MSAA_4X
		3: vp.msaa_3d = Viewport.MSAA_8X
		4: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		5: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA

func toggle_menu(applied: bool = false):
	if detach_overlay.visible:
		_on_exit_detach_pressed()
		return

	menu_overlay.visible = !menu_overlay.visible
	if menu_overlay.visible:
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

		_syncing_ui = true
		var backup = {}
		for key in Config.PRESET_KEYS:
			backup[key] = Config.get(key)

		freeze_time_checkbox.button_pressed = Config.freeze_time


		if player:
			var scale_factor = 1.0 / Config.effective_zoom
			var re_val = player.global_position.x * 0.1 * scale_factor
			var im_val = - player.global_position.z * 0.1 * scale_factor
			if not is_finite(re_val): re_val = 0.5
			if not is_finite(im_val): im_val = 0.0
			re_input.text = "%.3f" % re_val
			im_input.text = "%.3f" % im_val
		iter_slider.value = Config.iterations
		_on_iterations_value_changed(Config.iterations)
		_speed_modified = false
		_camera_height_modified = false
		speed_input.text = "%.1f" % (Config.movement_speed * 0.1)
		zoom_slider.value = _zoom_to_slider(Config.zoom_factor)
		_on_zoom_value_changed(zoom_slider.value)
		zero_speed_slider.value = Config.speed_near_zeros
		_on_zero_speed_value_changed(Config.speed_near_zeros)
		zero_proximity_nav_slider.value = Config.zero_proximity_nav
		_on_zero_proximity_nav_value_changed(Config.zero_proximity_nav)
		camera_height_input.text = str(Config.camera_height)
		height_a_input.text = str(Config.height_a)
		height_eps_input.text = str(Config.height_epsilon)
		terrain_detail_button.selected = Config.terrain_detail
		aa_button.selected = Config.antialiasing_mode
		color_scheme_button.selected = Config.color_scheme
		view_distance_slider.value = Config.view_distance
		_on_view_distance_value_changed(Config.view_distance)
		curves_checkbox.button_pressed = Config.show_curves
		critical_checkbox.button_pressed = Config.show_critical_stripe
		day_duration_slider.value = Config.day_duration
		_on_day_duration_value_changed(Config.day_duration)
		day_time_slider.value = Config.day_time
		_on_day_time_value_changed(Config.day_time)
		sunrise_slider.value = Config.sunrise_direction
		_on_sunrise_value_changed(Config.sunrise_direction)
		sky_luminosity_slider.value = Config.sky_luminosity * 100.0
		_on_sky_luminosity_value_changed(sky_luminosity_slider.value)
		sun_luminosity_slider.value = Config.sun_luminosity * 100.0
		_on_sun_luminosity_value_changed(sun_luminosity_slider.value)
		self_illumination_slider.value = Config.self_illumination * 100.0
		_on_self_illumination_value_changed(self_illumination_slider.value)
		fog_density_slider.value = Config.fog_density * 100.0
		morph_slider.value = 1.0
		_on_morph_slider_changed(1.0)
		_on_fog_density_value_changed(fog_density_slider.value)
		shadows_checkbox.button_pressed = Config.shadows_enabled
		hud_complex_checkbox.button_pressed = Config.show_hud_complex
		hud_navigation_checkbox.button_pressed = Config.show_hud_navigation
		hud_zeros_checkbox.button_pressed = Config.show_hud_zeros
		rvm_checkbox.button_pressed = Config.show_rvm
		hud_monitor_fps_checkbox.button_pressed = Config.show_hud_monitor_fps
		hud_monitor_chunks_checkbox.button_pressed = Config.show_hud_monitor_chunks
		hud_scale_slider.value = Config.hud_scale * 100.0
		_on_hud_scale_value_changed(hud_scale_slider.value)
		if player:
			auto_walk_checkbox.button_pressed = (player.auto_walk_state != 0) # 0 is AutoWalkState.NONE
		flow_checkbox.button_pressed = Config.show_flow
		master_volume_slider.value = Config.master_volume
		_on_master_volume_value_changed(Config.master_volume)
		bg_music_slider.value = Config.bg_music_volume
		_on_bg_music_value_changed(Config.bg_music_volume)
		drone_slider.value = Config.drone_volume
		_on_drone_value_changed(Config.drone_volume)

		brightness_slider.value = Config.terrain_brightness * 50.0
		_on_terrain_brightness_value_changed(brightness_slider.value)
		saturation_slider.value = (Config.terrain_saturation - 0.3) / 0.7 * 100.0
		_on_terrain_saturation_value_changed(saturation_slider.value)
		albedo_slider.value = Config.terrain_albedo * 100.0
		_on_terrain_albedo_value_changed(albedo_slider.value)
		emission_slider.value = Config.terrain_emission * 100.0
		_on_terrain_emission_value_changed(emission_slider.value)
		metallic_slider.value = Config.terrain_metallic * 100.0
		_on_terrain_metallic_value_changed(metallic_slider.value)
		roughness_slider.value = Config.terrain_roughness * 100.0
		_on_terrain_roughness_value_changed(roughness_slider.value)

		surface_texture_slider.value = Config.terrain_surface_texture * 100.0
		_on_terrain_surface_texture_value_changed(surface_texture_slider.value)

		multivalued_slider.value = Config.multivalued_n
		_on_multivalued_n_value_changed(Config.multivalued_n)

		func_button.select(func_button.get_item_index(Config.function_type))
		height_button.selected = Config.height_type
		_on_func_selected(Config.function_type)
		_on_height_selected(Config.height_type)

		for key in Config.PRESET_KEYS:
			Config.set(key, backup[key])
		_syncing_ui = false
		_update_preset_button_text()

	else:
		tooltip.visible = false
		tooltip_timer.stop()
		_pending_tooltip_key = ""
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
			if Config.hud_scale != _initial_hud_scale:
				Config.hud_scale = _initial_hud_scale
				_update_hud_layout()
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

			apply_aa()

func _on_func_item_selected(index):
	_on_func_selected(func_button.get_item_id(index))

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
		_on_iterations_value_changed(Config.iterations)

	rational_container.visible = is_rational
	multivalued_slider.visible = is_multivalued_n
	iter_slider.visible = has_iters
	critical_checkbox.visible = is_dirichlect
	auto_walk_checkbox.visible = is_dirichlect
	rvm_checkbox.visible = is_dirichlect

func _on_height_selected(index):
	Config.height_type = index
	var is_log = (index == 0)
	height_a_container.visible = is_log
	height_eps_container.visible = is_log

func _on_freeze_time_toggled(pressed: bool):
	Config.freeze_time = pressed


func _format_time(total_seconds: float) -> String:
	var hours = int(total_seconds) / 3600.0
	var minutes = (int(total_seconds) % 3600) / 60.0
	var seconds = int(total_seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _on_day_duration_value_changed(value):
	Config.day_duration = value
	day_duration_slider.value_text = _format_time(value)

func _on_day_time_value_changed(value):
	Config.day_time = value
	day_time_slider.value_text = _format_time(value)
func _on_master_volume_value_changed(value):
	Config.master_volume = value
	master_volume_slider.value_text = str(int(value)) + "%"

func _on_bg_music_value_changed(value):
	Config.bg_music_volume = value
	bg_music_slider.value_text = str(int(value)) + "%"

func _on_drone_value_changed(value):
	Config.drone_volume = value
	drone_slider.value_text = str(int(value)) + "%"

func _on_zero_proximity_nav_value_changed(value):
	Config.zero_proximity_nav = value
	zero_proximity_nav_slider.value_text = "%.2f" % value


func _on_zoom_value_changed(value):
	var z = _slider_to_zoom(value)
	zoom_slider.value_text = "x%.2f" % z
	Config.zoom_factor = z

func _on_zero_speed_value_changed(value):
	zero_speed_slider.value_text = str(int(value)) + "%"

func _on_view_distance_value_changed(value):
	view_distance_slider.value_text = str(int(value))
	Config.view_distance = int(value)

func _on_sunrise_value_changed(value):
	sunrise_slider.value_text = str(int(value)) + "°"

func _on_sky_luminosity_value_changed(value):
	Config.sky_luminosity = value / 100.0
	sky_luminosity_slider.value_text = str(int(value)) + "%"

func _on_sun_luminosity_value_changed(value):
	Config.sun_luminosity = value / 100.0
	sun_luminosity_slider.value_text = str(int(value)) + "%"

func _on_self_illumination_value_changed(value):
	Config.self_illumination = value / 100.0
	self_illumination_slider.value_text = str(int(value)) + "%"

func _on_fog_density_value_changed(value):
	Config.fog_density = value / 100.0
	fog_density_slider.value_text = "%.1f%%" % value

func _on_hud_scale_value_changed(value):
	hud_scale_slider.value_text = str(int(value)) + "%"
	Config.hud_scale = value / 100.0
	_update_hud_layout()

func _on_iterations_value_changed(value):
	Config.iterations = int(value)
	iter_slider.value_text = str(int(value))

func _on_multivalued_n_value_changed(value):
	multivalued_slider.value_text = str(int(value))
	Config.multivalued_n = int(value)

func _on_terrain_brightness_value_changed(value):
	Config.terrain_brightness = value / 50.0
	brightness_slider.value_text = str(int(value)) + "%"

func _on_terrain_saturation_value_changed(value):
	Config.terrain_saturation = 0.3 + (value / 100.0) * 0.7
	saturation_slider.value_text = str(int(value)) + "%"

func _on_terrain_albedo_value_changed(value):
	Config.terrain_albedo = value / 100.0
	albedo_slider.value_text = str(int(value)) + "%"

func _on_terrain_emission_value_changed(value):
	Config.terrain_emission = value / 100.0
	emission_slider.value_text = str(int(value)) + "%"

func _on_terrain_metallic_value_changed(value):
	Config.terrain_metallic = value / 100.0
	metallic_slider.value_text = str(int(value)) + "%"

func _on_terrain_roughness_value_changed(value):
	Config.terrain_roughness = value / 100.0
	roughness_slider.value_text = str(int(value)) + "%"

func _on_terrain_surface_texture_value_changed(value):
	Config.terrain_surface_texture = value / 100.0
	surface_texture_slider.value_text = str(int(value)) + "%"

func _on_morph_slider_changed(value):
	Config.morph_value = value
	morph_slider.value_text = "%.2f" % value

func _parse_complex(text: String) -> Vector2:
	text = text.replace(" ", "").replace("I", "i").replace("*", "")
	if text == "": return Vector2.ZERO

	# Handle pure imaginary "i" or "-i"
	if text == "i": return Vector2(0, 1)
	if text == "-i": return Vector2(0, -1)

	if not "i" in text:
		return Vector2(float(text), 0.0)

	# If we have "i", it might be "1+2i", "2i", "-2i", "1+i", "1-i"
	# Let's split by + and - but keep signs
	var re = 0.0
	var im = 0.0

	var normalized = text.replace("-", "+-")
	var parts = normalized.split("+", false)

	for p in parts:
		if p.ends_with("i"):
			var im_str = p.substr(0, p.length() - 1)
			if im_str == "" or im_str == "+": im += 1.0
			elif im_str == "-": im -= 1.0
			else: im += float(im_str)
		else:
			re += float(p)

	return Vector2(re, im)

func _parse_poly(text: String) -> PackedVector2Array:
	var coeffs = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	text = text.replace(" ", "").replace("*", "")

	# We want to split by terms. A term usually starts with + or -
	# unless it's inside parentheses.
	var terms = []
	var depth = 0
	var start_idx = 0
	for i in range(text.length()):
		var c = text[i]
		if c == "(": depth += 1
		elif c == ")": depth -= 1

		if depth == 0 and i > 0 and (c == "+" or c == "-") and text[i - 1] != "e" and text[i - 1] != "E":
			terms.append(text.substr(start_idx, i - start_idx))
			start_idx = i
	terms.append(text.substr(start_idx))

	for term in terms:
		if term == "": continue
		var coeff = Vector2(1, 0)
		var degree = 0

		if "z" in term:
			var parts = term.split("z")
			var coeff_str = parts[0]
			if coeff_str == "" or coeff_str == "+": coeff = Vector2(1, 0)
			elif coeff_str == "-": coeff = Vector2(-1, 0)
			else:
				var _sign = 1.0
				if coeff_str.begins_with("+"):
					coeff_str = coeff_str.substr(1)
				elif coeff_str.begins_with("-"):
					_sign = -1.0
					coeff_str = coeff_str.substr(1)

				# Remove surrounding parentheses if any
				if coeff_str.begins_with("(") and coeff_str.ends_with(")"):
					coeff_str = coeff_str.substr(1, coeff_str.length() - 2)
				coeff = _parse_complex(coeff_str) * _sign

			var degree_str = parts[1]
			if degree_str == "": degree = 1
			elif degree_str.begins_with("^"):
				degree = int(degree_str.substr(1))
		else:
			var coeff_str = term
			var _sign = 1.0
			if coeff_str.begins_with("+"):
				coeff_str = coeff_str.substr(1)
			elif coeff_str.begins_with("-"):
				_sign = -1.0
				coeff_str = coeff_str.substr(1)
			if coeff_str.begins_with("(") and coeff_str.ends_with(")"):
				coeff_str = coeff_str.substr(1, coeff_str.length() - 2)
			coeff = _parse_complex(coeff_str) * _sign
			degree = 0

		if degree >= 0 and degree < 10:
			coeffs[degree] += coeff

	return coeffs

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

func _on_set_pos_pressed():
	Config.performance_protection_active = false
	var re = float(re_input.text)
	var im = float(im_input.text)
	if not is_finite(re): re = 0.5
	if not is_finite(im): im = 0.0

	var iters = int(iter_slider.value)
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

	Config.iterations = iters
	Config.movement_speed = m_speed
	Config.zoom_factor = _slider_to_zoom(zoom_slider.value)
	Config.effective_zoom = float(Config.zoom_factor)
	Config.speed_near_zeros = zero_speed_slider.value
	Config.zero_proximity_nav = zero_proximity_nav_slider.value
	Config.camera_height = c_height
	Config.height_a = h_a
	Config.height_epsilon = h_eps

	_speed_modified = false
	_camera_height_modified = false

	Config.terrain_detail = terrain_detail_button.selected
	Config.antialiasing_mode = aa_button.selected
	Config.color_scheme = color_scheme_button.selected
	Config.show_curves = curves_checkbox.button_pressed
	Config.show_critical_stripe = critical_checkbox.button_pressed
	Config.sunrise_direction = sunrise_slider.value
	Config.sky_luminosity = sky_luminosity_slider.value / 100.0
	Config.sun_luminosity = sun_luminosity_slider.value / 100.0
	Config.shadows_enabled = shadows_checkbox.button_pressed
	Config.show_hud_complex = hud_complex_checkbox.button_pressed
	Config.show_hud_navigation = hud_navigation_checkbox.button_pressed
	Config.show_hud_zeros = hud_zeros_checkbox.button_pressed
	Config.show_rvm = rvm_checkbox.button_pressed
	Config.show_hud_monitor_fps = hud_monitor_fps_checkbox.button_pressed
	Config.show_hud_monitor_chunks = hud_monitor_chunks_checkbox.button_pressed
	Config.show_flow = flow_checkbox.button_pressed
	Config.master_volume = master_volume_slider.value
	Config.bg_music_volume = bg_music_slider.value
	Config.drone_volume = drone_slider.value
	Config.terrain_brightness = brightness_slider.value / 50.0
	Config.terrain_saturation = 0.3 + (saturation_slider.value / 100.0) * 0.7
	Config.terrain_albedo = albedo_slider.value / 100.0
	Config.terrain_emission = emission_slider.value / 100.0
	Config.terrain_metallic = metallic_slider.value / 100.0
	Config.terrain_roughness = roughness_slider.value / 100.0
	Config.terrain_surface_texture = surface_texture_slider.value / 100.0
	Config.view_distance = int(view_distance_slider.value)
	Config.day_duration = day_duration_slider.value
	Config.day_time = day_time_slider.value
	Config.fog_density = fog_density_slider.value / 100.0
	Config.hud_scale = hud_scale_slider.value / 100.0
	Config.function_type = func_button.get_item_id(func_button.selected)
	Config.height_type = height_button.selected
	Config.multivalued_n = int(multivalued_slider.value)

	apply_aa()

	if Config.function_type == Config.ComplexFunc.RATIONAL:
		var expr = rational_input.text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			# We only strip outer parentheses if they enclose the whole numerator/denominator
			var num_str = parts[0]
			if num_str.begins_with("(") and num_str.ends_with(")"):
				num_str = num_str.substr(1, num_str.length() - 2)
			var den_str = parts[1]
			if den_str.begins_with("(") and den_str.ends_with(")"):
				den_str = den_str.substr(1, den_str.length() - 2)

			Config.rational_num_coeffs = _parse_poly(num_str)
			Config.rational_den_coeffs = _parse_poly(den_str)
		else:
			Config.rational_num_coeffs = _parse_poly(expr)
			Config.rational_den_coeffs = PackedVector2Array([Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	Config.save_settings()
	_update_hud_layout()

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

	_update_preset_button_text()
	toggle_menu(true)


func _on_preset_update_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	if preset_name in ["Default", "Mysterious"]:
		new_preset_dialog.visible = true
		new_preset_input.text = preset_name + " Copy"
		new_preset_input.grab_focus()
	else:
		Config.update_preset(preset_name)
		Config.current_preset = preset_name
		_update_preset_button_text()

func _on_preset_delete_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	if preset_name in ["Default", "Mysterious"]:
		return
	delete_message_label.text = "Are you sure you want to delete the
preset '" + preset_name + "'?"
	delete_preset_dialog.visible = true

func _on_delete_preset_cancel_pressed():
	delete_preset_dialog.visible = false

func _on_delete_preset_confirm_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	if Config.PRESETS.has(preset_name):
		Config.delete_preset(preset_name)

		# Repopulate dropdown
		preset_button.clear()
		for p_name in Config.PRESETS.keys():
			preset_button.add_item(p_name)

		if Config.PRESETS.size() > 0:
			var new_preset = Config.PRESETS.keys()[0]
			Config.apply_preset(new_preset)
		else:
			Config.current_preset = "Custom"
			_update_preset_button_text()
	delete_preset_dialog.visible = false

func _on_preset_new_pressed():
	new_preset_dialog.visible = true
	new_preset_input.text = ""
	new_preset_input.grab_focus()

func _on_new_preset_cancel_pressed():
	new_preset_dialog.visible = false

func _on_new_preset_save_pressed():
	var preset_name = new_preset_input.text.strip_edges()
	if preset_name != "":
		Config.update_preset(preset_name)

		preset_button.clear()
		for p_name in Config.PRESETS.keys():
			preset_button.add_item(p_name)

		Config.apply_preset(preset_name)

	new_preset_dialog.visible = false

func _on_preset_selected(index: int):
	var preset_name = preset_button.get_item_text(index).trim_suffix("*")
	Config.apply_preset(preset_name)

func _sync_ui_to_config():
	_syncing_ui = true
	var backup = {}
	for key in Config.PRESET_KEYS:
		backup[key] = Config.get(key)

	iter_slider.value = Config.iterations
	_on_iterations_value_changed(Config.iterations)
	
	_speed_modified = false
	_camera_height_modified = false
	speed_input.text = "%.1f" % (Config.movement_speed * 0.1)
	
	zoom_slider.value = _zoom_to_slider(Config.zoom_factor)
	_on_zoom_value_changed(zoom_slider.value)
	
	zero_speed_slider.value = Config.speed_near_zeros
	_on_zero_speed_value_changed(Config.speed_near_zeros)
	
	zero_proximity_nav_slider.value = Config.zero_proximity_nav
	_on_zero_proximity_nav_value_changed(Config.zero_proximity_nav)
	
	camera_height_input.text = str(Config.camera_height)
	height_a_input.text = str(Config.height_a)
	height_eps_input.text = str(Config.height_epsilon)
	
	terrain_detail_button.selected = Config.terrain_detail
	aa_button.selected = Config.antialiasing_mode
	color_scheme_button.selected = Config.color_scheme
	
	view_distance_slider.value = Config.view_distance
	_on_view_distance_value_changed(Config.view_distance)
	
	curves_checkbox.button_pressed = Config.show_curves
	critical_checkbox.button_pressed = Config.show_critical_stripe
	
	day_duration_slider.value = Config.day_duration
	_on_day_duration_value_changed(Config.day_duration)
	
	day_time_slider.value = Config.day_time
	_on_day_time_value_changed(Config.day_time)
	
	sunrise_slider.value = Config.sunrise_direction
	_on_sunrise_value_changed(Config.sunrise_direction)
	
	sky_luminosity_slider.value = Config.sky_luminosity * 100.0
	_on_sky_luminosity_value_changed(sky_luminosity_slider.value)
	
	sun_luminosity_slider.value = Config.sun_luminosity * 100.0
	_on_sun_luminosity_value_changed(sun_luminosity_slider.value)
	
	self_illumination_slider.value = Config.self_illumination * 100.0
	_on_self_illumination_value_changed(self_illumination_slider.value)
	
	fog_density_slider.value = Config.fog_density * 100.0
	_on_fog_density_value_changed(fog_density_slider.value)
	
	shadows_checkbox.button_pressed = Config.shadows_enabled
	hud_complex_checkbox.button_pressed = Config.show_hud_complex
	hud_navigation_checkbox.button_pressed = Config.show_hud_navigation
	hud_zeros_checkbox.button_pressed = Config.show_hud_zeros
	rvm_checkbox.button_pressed = Config.show_rvm
	hud_monitor_fps_checkbox.button_pressed = Config.show_hud_monitor_fps
	hud_monitor_chunks_checkbox.button_pressed = Config.show_hud_monitor_chunks
	
	hud_scale_slider.value = Config.hud_scale * 100.0
	_on_hud_scale_value_changed(hud_scale_slider.value)
	
	if player:
		auto_walk_checkbox.button_pressed = (player.auto_walk_state != 0)
	
	flow_checkbox.button_pressed = Config.show_flow
	
	master_volume_slider.value = Config.master_volume
	_on_master_volume_value_changed(Config.master_volume)
	
	bg_music_slider.value = Config.bg_music_volume
	_on_bg_music_value_changed(Config.bg_music_volume)
	
	drone_slider.value = Config.drone_volume
	_on_drone_value_changed(Config.drone_volume)

	brightness_slider.value = Config.terrain_brightness * 50.0
	_on_terrain_brightness_value_changed(brightness_slider.value)
	
	saturation_slider.value = (Config.terrain_saturation - 0.3) / 0.7 * 100.0
	_on_terrain_saturation_value_changed(saturation_slider.value)
	
	albedo_slider.value = Config.terrain_albedo * 100.0
	_on_terrain_albedo_value_changed(albedo_slider.value)
	
	emission_slider.value = Config.terrain_emission * 100.0
	_on_terrain_emission_value_changed(emission_slider.value)
	
	metallic_slider.value = Config.terrain_metallic * 100.0
	_on_terrain_metallic_value_changed(metallic_slider.value)
	
	roughness_slider.value = Config.terrain_roughness * 100.0
	_on_terrain_roughness_value_changed(roughness_slider.value)

	surface_texture_slider.value = Config.terrain_surface_texture * 100.0
	_on_terrain_surface_texture_value_changed(surface_texture_slider.value)

	multivalued_slider.value = Config.multivalued_n
	_on_multivalued_n_value_changed(Config.multivalued_n)

	func_button.select(func_button.get_item_index(Config.function_type))
	height_button.selected = Config.height_type
	_on_func_selected(Config.function_type)
	_on_height_selected(Config.height_type)

	for key in Config.PRESET_KEYS:
		Config.set(key, backup[key])
	_syncing_ui = false


func _on_preset_applied():
	_sync_ui_to_config()
	_update_preset_button_text()

func _on_preset_restore_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	Config.restore_preset(preset_name)

func _connect_preset_dirtiers():
	var on_changed = func(_val = null):
		if not _syncing_ui:
			_update_preset_button_text()

	# Connect sliders
	for slider in [
		iter_slider, zero_proximity_nav_slider, zoom_slider, zero_speed_slider,
		view_distance_slider, day_duration_slider, day_time_slider, sunrise_slider,
		sky_luminosity_slider, sun_luminosity_slider, self_illumination_slider,
		fog_density_slider, hud_scale_slider, master_volume_slider, bg_music_slider,
		drone_slider, brightness_slider, saturation_slider, albedo_slider,
		emission_slider, metallic_slider, roughness_slider, surface_texture_slider,
		multivalued_slider
	]:
		if slider and slider.has_signal("value_changed"):
			slider.value_changed.connect(on_changed)

	# Connect checkboxes
	for cb in [
		curves_checkbox, critical_checkbox, flow_checkbox, hud_complex_checkbox,
		hud_navigation_checkbox, hud_zeros_checkbox, rvm_checkbox,
		hud_monitor_fps_checkbox, hud_monitor_chunks_checkbox, shadows_checkbox,
		auto_walk_checkbox, freeze_time_checkbox
	]:
		if cb and cb.has_signal("toggled"):
			cb.toggled.connect(on_changed)

	# Connect buttons/option buttons
	for ob in [func_button, height_button, terrain_detail_button, aa_button, color_scheme_button]:
		if ob and ob.has_signal("item_selected"):
			ob.item_selected.connect(on_changed)

	# Connect line edits
	for le in [speed_input, camera_height_input, height_a_input, height_eps_input]:
		if le and le.has_signal("text_submitted"):
			le.text_submitted.connect(on_changed)

func _update_preset_button_text():
	var preset_name = Config.current_preset.trim_suffix("*")
	var is_dirty = Config.is_preset_dirty()

	# Update current_preset to match computed state
	Config.current_preset = preset_name + "*" if is_dirty else preset_name

	# Try to select the right item, then set text
	for i in range(preset_button.item_count):
		var item_clean_name = preset_button.get_item_text(i).trim_suffix("*")
		if item_clean_name == preset_name:
			preset_button.select(i)
			break

	# Update all items' texts based on their dirtiness
	for i in range(preset_button.item_count):
		var item_clean_name = preset_button.get_item_text(i).trim_suffix("*")
		var item_dirty = Config.is_preset_dirty_by_name(item_clean_name)
		if item_dirty:
			preset_button.set_item_text(i, item_clean_name + "*")
		else:
			preset_button.set_item_text(i, item_clean_name)

	# Force OptionButton to update its displayed text by re-selecting the index
	var selected_idx = preset_button.selected
	if selected_idx != -1:
		preset_button.select(-1)
		preset_button.select(selected_idx)

	# Save/Update button state
	preset_update_button.disabled = not is_dirty
	preset_restore_button.disabled = not is_dirty

	# Default & Mysterious are read-only
	if preset_name in ["Default", "Mysterious"]:
		preset_delete_button.disabled = true
	else:
		preset_delete_button.disabled = false


func _on_quit_pressed():
	get_tree().quit()

func _process(_delta):
	if Config.show_hud_zeros and not _last_zeros_visible:
		Config.rvm_start_t = abs(player.global_position.z * 0.1 / Config.effective_zoom)
	_last_zeros_visible = Config.show_hud_zeros

	if tooltip.visible:
		_update_tooltip_position()

	if menu_overlay.visible:
		if abs(_slider_to_zoom(zoom_slider.value) - Config.zoom_factor) > 0.001:
			zoom_slider.value = _zoom_to_slider(Config.zoom_factor)
			_on_zoom_value_changed(zoom_slider.value)

		# Live update speed and height inputs as they change smoothly with zoom
		if not _speed_modified and not speed_input.has_focus():
			var formatted_speed = "%.1f" % (Config.movement_speed * 0.1)
			if speed_input.text != formatted_speed:
				speed_input.text = formatted_speed

		if not _camera_height_modified and not camera_height_input.has_focus():
			var formatted_height = "%.3f" % Config.camera_height
			if camera_height_input.text != formatted_height:
				camera_height_input.text = formatted_height

		# Live update time slider if time is flowing
		if not Config.freeze_time:
			day_time_slider.value = Config.day_time
			day_time_slider.value_text = _format_time(Config.day_time)

	perf_label.visible = Config.performance_protection_active

	if not player:
		return

	var x = player.global_position.x
	var z = player.global_position.z

	var f = Field.get_field(x, z)

	# Update Zeta Zeros display
	var f_data = Config.function
	zeros_panel.visible = Config.show_hud_zeros

	if Config.show_hud_zeros:
		var total_count = Config.visited_zeros.size()
		var last_zeros_text = ""
		var zero = Vector2(0.0, 0.0)

		# Show all visited zeros in the scrolling list
		for i in range(total_count - 1, -1, -1):
			zero = Config.visited_zeros[i]
			last_zeros_text += "(%.3f, %.3f)\n" % [zero[0], zero[1]]

		zeros_count_label.text = "Count: %d" % total_count

		# Riemann-von Mangoldt formula: N(T) ≈ (T/2π) log(T/2πe) + 7/8
		if Config.show_rvm and f_data.get("has_von_mangoldt", false):
			var T = abs(z * 0.1 / Config.effective_zoom)
			var val = _get_rvm_n(T) - _get_rvm_n(Config.rvm_start_t)
			val = max(0.0, val)
			rvm_label.text = "N(t) ≈ %.2f" % val
			rvm_label.visible = true
		else:
			rvm_label.visible = false

		zeros_list_label.text = last_zeros_text

	# Update shader uniforms
	var material = complex_rect.material as ShaderMaterial
	material.set_shader_parameter("current_f", f)
	material.set_shader_parameter("multivalued_n", Config.multivalued_n)
	material.set_shader_parameter("function_type", Config.function_type)
	material.set_shader_parameter("color_scheme", Config.color_scheme)
	material.set_shader_parameter("scale", current_scale)
	material.set_shader_parameter("performance_protection_active", Config.performance_protection_active)

	var scale_factor = 1.0 / Config.effective_zoom
	domain_label.text = "Re = %.3f\nIm = %.3f" % [x * 0.1 * scale_factor, -z * 0.1 * scale_factor]
	var target_text = "Re = %.3f\nIm = %.3f\n|f| = %.3f" % [f.x, f.y, f.length()]
	if f_data.get("is_multivalued", false):
		target_text += "\nBranch k = %d" % Config.current_branch
	target_label.text = target_text

	complex_panel.visible = Config.show_hud_complex
	info_panel.visible = Config.show_hud_navigation
	monitor_panel.visible = Config.show_hud_monitor_fps or Config.show_hud_monitor_chunks
	if monitor_panel.visible:
		var parts = []
		if Config.show_hud_monitor_fps:
			parts.append("FPS: %d" % Engine.get_frames_per_second())
		if Config.show_hud_monitor_chunks and world_manager:
			var chunks_text = "Chunks"
			var num_lods = world_manager.LOD_SUBS.size()
			var lod_counts = []
			lod_counts.resize(num_lods)
			lod_counts.fill(0)

			for chunk in world_manager.chunks.values():
				var lod = chunk.get_meta("lod_level", 0)
				if lod >= 0 and lod < num_lods:
					lod_counts[lod] += 1

			for i in range(num_lods):
				if lod_counts[i] > 0:
					chunks_text += "\n%d: %d" % [world_manager.LOD_SUBS[i], lod_counts[i]]
			parts.append(chunks_text)

		fps_label.text = "\n\n".join(parts)

	_update_hud_layout()

var _last_hud_state = {}

func _update_hud_layout():
	if not hud_columns: return

	var cards = [complex_panel, info_panel, monitor_panel, zeros_panel, perf_label]

	# Always rescale all cards to ensure their combined_minimum_size is correct for height check
	for card in cards:
		_rescale_card(card, Config.hud_scale)

	var current_state = {
		"size": get_viewport().size,
		"scale": Config.hud_scale,
		"visibility": cards.map(func(c): return c.visible)
	}

	if current_state.hash() == _last_hud_state.hash():
		return
	_last_hud_state = current_state

	# Scale stack widths to accommodate wider fonts
	hud_stack_right.custom_minimum_size.x = 150 * Config.hud_scale
	hud_stack_left.custom_minimum_size.x = 150 * Config.hud_scale

	var available_height = get_viewport().size.y - 40
	var current_height = 0.0
	var separation = 10.0

	var right_cards = []
	var left_cards = []

	for card in cards:
		if not card.visible: continue
		var card_height = card.get_combined_minimum_size().y
		if current_height + card_height <= available_height:
			right_cards.push_back(card)
			current_height += card_height + separation
		else:
			left_cards.push_back(card)

	_apply_stack_layout(hud_stack_right, right_cards)
	_apply_stack_layout(hud_stack_left, left_cards)

	hud_stack_right.add_theme_constant_override("separation", 10)
	hud_stack_left.add_theme_constant_override("separation", 10)

func _apply_stack_layout(stack: VBoxContainer, desired_cards: Array):
	for child in stack.get_children():
		if not child in desired_cards:
			stack.remove_child(child)
			add_child(child)

	# Optimization: The original code moved each card to index 0 in forward order,
	# which inverted the final display order. By iterating backwards through the
	# desired_cards array, we can safely target absolute indices (0 to N-1) as we build
	# the stack from top to bottom. This ensures `move_child` operates within valid
	# index bounds even when new cards are being added, and eliminates redundant moves.
	for i in range(desired_cards.size()):
		var target_index = i
		var card = desired_cards[desired_cards.size() - 1 - i]
		if card.get_parent() != stack:
			if card.get_parent():
				card.get_parent().remove_child(card)
			stack.add_child(card)

		if card.get_index() != target_index:
			stack.move_child(card, target_index)

func _rescale_card(card: Control, _scale: float):
	if card == null: return

	if card.has_meta("last_applied_scale") and card.get_meta("last_applied_scale") == _scale:
		return
	card.set_meta("last_applied_scale", _scale)

	var stack = [card]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is Label:
			if not node.has_meta("base_font_size"):
				node.set_meta("base_font_size", node.get_theme_font_size("font_size"))
			node.add_theme_font_size_override("font_size", int(round(node.get_meta("base_font_size") * _scale)))
		elif node is RichTextLabel:
			if not node.has_meta("base_font_size"):
				node.set_meta("base_font_size", node.get_theme_font_size("normal_font_size"))
			node.add_theme_font_size_override("normal_font_size", int(round(node.get_meta("base_font_size") * _scale)))

		if node is Control:
			# Only scale custom minimum size for specific panels to maintain layout proportions
			if node.name == "ComplexAspect":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", Vector2(150, 150))
				node.custom_minimum_size = node.get_meta("base_min_size") * _scale
			elif node.name == "ZerosPanel" or node.name == "InfoPanel":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", node.custom_minimum_size)
				node.custom_minimum_size.y = node.get_meta("base_min_size").y * _scale

			# Keep container separations and margins constant at their original design values
			if node is BoxContainer:
				if not node.has_meta("base_separation"):
					node.set_meta("base_separation", node.get_theme_constant("separation"))
				node.add_theme_constant_override("separation", node.get_meta("base_separation"))
			elif node is MarginContainer:
				for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
					if not node.has_meta("base_" + margin):
						node.set_meta("base_" + margin, node.get_theme_constant(margin))
					node.add_theme_constant_override(margin, node.get_meta("base_" + margin))

		for child in node.get_children():
			if child is Control:
				stack.push_back(child)


func _on_detach_pressed(source_slider: HSlider, source_value_label: Label, title: String):
	active_detached_slider = null

	detach_label.text = title
	# Using set_block_signals(true) prevents _on_detach_slider_changed from firing while we update its properties.
	detach_slider.set_block_signals(true)
	# Expand bounds first to avoid clamping
	detach_slider.min_value = min(detach_slider.min_value, source_slider.min_value)
	detach_slider.max_value = max(detach_slider.max_value, source_slider.max_value)
	detach_slider.custom_minimum_size = Vector2(200.0, 50.0)

	detach_slider.min_value = source_slider.min_value
	detach_slider.max_value = source_slider.max_value
	detach_slider.step = source_slider.step
	detach_slider.value = source_slider.value
	detach_slider.set_block_signals(false)

	detach_value.text = source_value_label.text

	active_detached_slider = source_slider
	active_detached_value = source_value_label

	toggle_menu(true)
	detach_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_detach_slider_changed(value: float):
	if active_detached_slider:
		# Emit value_changed to trigger the existing logic on the source slider
		active_detached_slider.value = value
		# active_detached_slider.value_changed.emit(value) # value setting already emits if value actually changes
		# Update the overlay label to match what the menu label would be
		# It's better to just copy the text from the source_value_label
		detach_value.text = active_detached_value.text

func _on_exit_detach_pressed():
	# Avoid accidental morph blending when returning from a detached slider
	morph_slider.value = 1.0

	detach_overlay.visible = false
	menu_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_terrain_detail_selected(index: int):
	Config.terrain_detail = index

func _on_aa_selected(index: int):
	Config.antialiasing_mode = index
	apply_aa()

func _on_shadows_toggled(pressed: bool):
	Config.shadows_enabled = pressed

func _on_curves_toggled(pressed: bool):
	Config.show_curves = pressed

func _on_critical_toggled(pressed: bool):
	Config.show_critical_stripe = pressed

func _on_flow_toggled(pressed: bool):
	Config.show_flow = pressed

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

func _on_rational_text_submitted(new_text: String):
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

			Config.rational_num_coeffs = _parse_poly(num_str)
			Config.rational_den_coeffs = _parse_poly(den_str)
		else:
			Config.rational_num_coeffs = _parse_poly(expr)
			Config.rational_den_coeffs = PackedVector2Array([Vector2(1, 0), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

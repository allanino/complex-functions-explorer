extends CanvasLayer

@export var player: Node3D
@onready var hud_columns = $Control/HUDColumns
@onready var hud_stack_left = $Control/HUDColumns/HUDStackLeft
@onready var hud_stack_right = $Control/HUDColumns/HUDStackRight
@onready var complex_panel = $Control/HUDColumns/HUDStackRight/ComplexAspect
@onready var info_panel = $Control/HUDColumns/HUDStackRight/InfoPanel
@onready var monitor_panel = $Control/HUDColumns/HUDStackRight/MonitorPanel
@onready var fps_label = $Control/HUDColumns/HUDStackRight/MonitorPanel/MarginContainer/VBox/FpsLabel
@onready var complex_rect = $Control/HUDColumns/HUDStackRight/ComplexAspect/ComplexPanel/MarginContainer/ClipPanel/ComplexPlane
@onready var world_manager = get_node("../WorldManager")
@onready var domain_label = $Control/HUDColumns/HUDStackRight/InfoPanel/MarginContainer/VBox/DomainLabel
@onready var target_label = $Control/HUDColumns/HUDStackRight/InfoPanel/MarginContainer/VBox/TargetLabel
@onready var zeros_panel = $Control/HUDColumns/HUDStackRight/ZerosPanel
@onready var zeros_count_label = $Control/HUDColumns/HUDStackRight/ZerosPanel/MarginContainer/VBox/CountLabel
@onready var rvm_label = $Control/HUDColumns/HUDStackRight/ZerosPanel/MarginContainer/VBox/RvmLabel
@onready var zeros_list_label = $Control/HUDColumns/HUDStackRight/ZerosPanel/MarginContainer/VBox/Scroll/ListLabel
@onready var menu_overlay = $Control/MenuOverlay

# New UI Node Paths
@onready var tab_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer
@onready var func_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/FuncContainer/FuncButton
@onready var height_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/HeightContainer/HeightButton
@onready var height_a_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/HeightAContainer
@onready var height_a_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/HeightAContainer/HeightAInput
@onready var height_eps_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/HeightEpsContainer
@onready var height_eps_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/HeightEpsContainer/HeightEpsInput
@onready var iter_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/IterContainer
@onready var iter_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/IterContainer/IterInput
@onready var rational_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/RationalContainer
@onready var rational_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/RationalContainer/RationalInput
@onready var multivalued_mode_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MultivaluedModeContainer
@onready var multivalued_mode_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MultivaluedModeContainer/MultivaluedModeButton
@onready var multivalued_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MultivaluedContainer
@onready var multivalued_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MultivaluedContainer/MultivaluedSlider
@onready var multivalued_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MultivaluedContainer/MultivaluedValue
@onready var cycle_speed_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/CycleSpeedContainer
@onready var cycle_speed_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/CycleSpeedContainer/CycleSpeedSlider
@onready var cycle_speed_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/CycleSpeedContainer/CycleSpeedValue
@onready var morph_time_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MorphTimeContainer
@onready var morph_time_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MorphTimeContainer/MorphTimeSlider
@onready var morph_time_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/MorphTimeContainer/MorphTimeValue

@onready var re_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ReContainer/ReInput
@onready var im_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ImContainer/ImInput
@onready var speed_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/SpeedContainer/SpeedInput
@onready var zoom_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ZoomContainer/ZoomSlider
@onready var zoom_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ZoomContainer/ZoomValue
@onready var zero_speed_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ZeroSpeedContainer/ZeroSpeedSlider
@onready var zero_speed_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ZeroSpeedContainer/ZeroSpeedValue
@onready var camera_height_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/CameraHeightContainer/CameraHeightInput
@onready var auto_walk_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/AutoWalkCheckbox

@onready var terrain_detail_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/TerrainDetailContainer/TerrainDetailButton
@onready var aa_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/AAContainer/AAButton
@onready var color_scheme_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/ColorSchemeContainer/ColorSchemeButton
@onready var view_distance_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/ViewDistanceContainer/ViewDistanceSlider
@onready var view_distance_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/ViewDistanceContainer/ViewDistanceValue
@onready var curves_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/CurvesCheckbox
@onready var critical_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/CriticalCheckbox
@onready var flow_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/FlowCheckbox
@onready var environment_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/EnvironmentContainer/EnvironmentButton
@onready var sunrise_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/SunriseContainer/SunriseSlider
@onready var sunrise_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/SunriseContainer/SunriseValue
@onready var shadows_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/ShadowsCheckbox

@onready var hud_complex_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudComplexCheckbox
@onready var hud_navigation_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudNavigationCheckbox
@onready var hud_zeros_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudZetaZerosCheckbox
@onready var rvm_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/RvmCheckbox
@onready var hud_monitor_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudMonitorCheckbox
@onready var hud_scale_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudScaleContainer/HudScaleSlider
@onready var hud_scale_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudScaleContainer/HudScaleValue

@onready var bg_music_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/BgMusicContainer/BgMusicSlider
@onready var bg_music_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/BgMusicContainer/BgMusicValue
@onready var drone_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/DroneContainer/DroneSlider
@onready var drone_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/DroneContainer/DroneValue

@onready var brightness_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/BrightnessContainer/BrightnessSlider
@onready var brightness_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/BrightnessContainer/BrightnessValue
@onready var saturation_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/SaturationContainer/SaturationSlider
@onready var saturation_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/SaturationContainer/SaturationValue
@onready var albedo_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/AlbedoContainer/AlbedoSlider
@onready var albedo_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/AlbedoContainer/AlbedoValue
@onready var emission_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/EmissionContainer/EmissionSlider
@onready var emission_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/EmissionContainer/EmissionValue
@onready var metallic_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/MetallicContainer/MetallicSlider
@onready var metallic_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/MetallicContainer/MetallicValue
@onready var roughness_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/RoughnessContainer/RoughnessSlider
@onready var roughness_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/RoughnessContainer/RoughnessValue
@onready var morph_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/MorphContainer/MorphButton

@onready var morph_overlay = $Control/MorphOverlay
@onready var morph_slider = $Control/MorphOverlay/MarginContainer/HBox/MorphSlider
@onready var exit_morph_button = $Control/MorphOverlay/MarginContainer/HBox/ExitMorphButton

@onready var apply_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/ButtonsHBox/ApplyButton
@onready var close_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/ButtonsHBox/CloseButton
@onready var quit_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/ButtonsHBox/QuitContainer/QuitButton
@onready var perf_label = $Control/HUDColumns/HUDStackRight/PerfProtectionLabel

@onready var tooltip = $TooltipLayer/Tooltip
@onready var tooltip_label = $TooltipLayer/Tooltip/MarginContainer/Label
@onready var tooltip_timer = $TooltipTimer

var _pending_tooltip_key: String = ""

const DESCRIPTIONS = {
	"Function": "Select the complex function to visualize on the terrain.",
	"Height Map": "Choose how the function's magnitude is mapped to terrain height.",
	"Parameter a": "Scaling factor for logarithmic height mapping.",
	"Parameter ε": "Small offset in logarithmic mapping to prevent log(0) at zeros.",
	"Iterations": "Number of terms used in the summation for Zeta and Eta functions, or steps for Mandelbrot recursion.",
	"Expression": "Enter a rational function expression using 'z' as variable (e.g., z^2 - 1).",
	"Real (σ)": "Manually set the real part of the player's position in the complex plane.",
	"Imaginary (t)": "Manually set the imaginary part of the player's position.",
	"Camera Height": "Vertical height of the player's camera above the terrain.",
	"Move Speed": "Horizontal movement speed when navigating the complex plane.",
	"Zoom Factor": "Increase detail by scaling coordinates (1.0 / Zoom).",
	"Speed near Zeros": "Slows down movement speed near function zeros to allow closer inspection.",
	"Automatic Walking": "Automatically follow the critical line (Re = 0.5) to find Riemann Zeta zeros.",
	"Terrain Details": "Quality and subdivision level of the procedurally generated terrain meshes.",
	"Antialiasing": "Choose a technique to reduce jagged edges in the 3D view.",
	"Branch Experience": "Choose how to visualize multiple branches: temporal cycling or spatial portals.",
	"Branches (n)": "Number of branches for the multivalued function z^(1/n).",
	"Cycle Speed": "Temporal branch morphing speed.",
	"Morph Time": "Duration of the smooth transition between branches.",
	"Color Scheme": "Select the color mapping for the complex plane of the target function.",
	"View Distance": "Number of terrain chunks loaded around the player.",
	"Level Curves": "Overlay contour lines for integer values of Re(f) (black) and Im(f) (white).",
	"Critical Stripe": "Visual guide indicating the 0 < Re < 1 region where non-trivial zeros reside.",
	"Sun Position": "Select between a static sun at noon, a static sun at golden hour, or a dynamic day/night cycle.",
	"Sunrise Direction": "Adjust the angle from which the sun rises (180° is towards +σ).",
	"Shadows": "Enable real-time directional shadows for terrain features.",
	"Complex plane": "Show the domain coloring map of the current position on the HUD.",
	"Navigation": "Show coordinate and magnitude information on the HUD.",
	"Zeta zeros": "Show the list of discovered zeros during automatic walking.",
	"Riemann–von Mangoldt": "Show the estimated number of zeros N(t) based on the Riemann–von Mangoldt formula.",
	"Performance Monitor": "Show real-time performance metrics (FPS) and chunks statistics on the HUD.",
	"HUD Scale": "Adjust the size of the HUD elements.",
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
var _initial_bg_music_volume: float
var _initial_drone_volume: float
var _initial_terrain_brightness: float
var _initial_terrain_saturation: float
var _initial_terrain_albedo: float
var _initial_terrain_emission: float
var _initial_terrain_metallic: float
var _initial_terrain_roughness: float

func _ready():
	apply_button.pressed.connect(_on_set_pos_pressed)
	close_button.pressed.connect(toggle_menu)
	quit_button.pressed.connect(_on_quit_pressed)
	func_button.item_selected.connect(_on_func_selected)
	height_button.item_selected.connect(_on_height_selected)
	multivalued_mode_button.item_selected.connect(_on_multivalued_mode_selected)

	bg_music_slider.value_changed.connect(_on_bg_music_value_changed)
	drone_slider.value_changed.connect(_on_drone_value_changed)
	zoom_slider.value_changed.connect(_on_zoom_value_changed)
	zero_speed_slider.value_changed.connect(_on_zero_speed_value_changed)
	view_distance_slider.value_changed.connect(_on_view_distance_value_changed)
	sunrise_slider.value_changed.connect(_on_sunrise_value_changed)
	hud_scale_slider.value_changed.connect(_on_hud_scale_value_changed)

	get_viewport().size_changed.connect(_update_hud_layout)
	multivalued_slider.value_changed.connect(_on_multivalued_n_value_changed)
	cycle_speed_slider.value_changed.connect(_on_cycle_speed_value_changed)
	morph_time_slider.value_changed.connect(_on_morph_time_value_changed)

	brightness_slider.value_changed.connect(_on_terrain_brightness_value_changed)
	saturation_slider.value_changed.connect(_on_terrain_saturation_value_changed)
	albedo_slider.value_changed.connect(_on_terrain_albedo_value_changed)
	emission_slider.value_changed.connect(_on_terrain_emission_value_changed)
	metallic_slider.value_changed.connect(_on_terrain_metallic_value_changed)
	roughness_slider.value_changed.connect(_on_terrain_roughness_value_changed)
	morph_button.item_selected.connect(_on_morph_selected)
	morph_slider.value_changed.connect(_on_morph_slider_changed)
	exit_morph_button.pressed.connect(_on_exit_morph_pressed)

	environment_button.clear()
	environment_button.add_item("Noon")
	environment_button.add_item("Sunrise golden hour")
	environment_button.add_item("Dynamic sun and moon")

	func_button.clear()
	func_button.add_item("Zeta (σ > 0)")
	func_button.add_item("Zeta (reflection formula)")
	func_button.add_item("Dirichlet Eta (σ > 0)")
	func_button.add_item("Dirichlet Beta (σ > 0)")
	func_button.add_item("Gamma")
	func_button.add_item("Log Gamma")
	func_button.add_item("Dedekind Eta")
	func_button.add_item("Mandelbrot")
	func_button.add_item("Sin")
	func_button.add_item("Cos")
	func_button.add_item("Tan")
	func_button.add_item("Exp")
	func_button.add_item("Log")
	func_button.add_item("Rational")
	func_button.add_item("Multivalued z^(1/n)")

	multivalued_mode_button.clear()
	multivalued_mode_button.add_item("Time cycle")
	multivalued_mode_button.add_item("Branch portals")

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

	morph_button.clear()
	morph_button.add_item("None")
	morph_button.add_item("Smooth Morph")

	apply_aa()
	_setup_tooltips()
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)

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
		|| environment_button.get_popup().visible
		|| multivalued_mode_button.get_popup().visible
	)

func _on_tooltip_timer_timeout():
	# Do not draw tooltip behind the dropdown lists
	if _any_dropdown_popup():
		return

	if _pending_tooltip_key != "":
		tooltip_label.custom_minimum_size.x = 250
		tooltip_label.text = DESCRIPTIONS[_pending_tooltip_key]
		tooltip.visible = true
		# Force a complete layout recalculation to fix the first-render height bug
		tooltip.size = Vector2.ZERO
		tooltip.reset_size()
		_update_tooltip_position()

func _update_tooltip_position():
	var mouse_pos = get_viewport().get_mouse_position()
	# Position at the tip of the mouse
	tooltip.global_position = mouse_pos + Vector2(5, 5)

func apply_aa():
	var vp = get_viewport()
	# Reset both
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	match Config.antialiasing_mode:
		1: vp.msaa_3d = Viewport.MSAA_2X
		2: vp.msaa_3d = Viewport.MSAA_4X
		3: vp.msaa_3d = Viewport.MSAA_8X
		4: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		5: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA

func toggle_menu(applied: bool = false):
	menu_overlay.visible = !menu_overlay.visible
	if menu_overlay.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_initial_bg_music_volume = Config.bg_music_volume
		_initial_drone_volume = Config.drone_volume
		_initial_terrain_brightness = Config.terrain_brightness
		_initial_terrain_saturation = Config.terrain_saturation
		_initial_terrain_albedo = Config.terrain_albedo
		_initial_terrain_emission = Config.terrain_emission
		_initial_terrain_metallic = Config.terrain_metallic
		_initial_terrain_roughness = Config.terrain_roughness

		if player:
			var scale_factor = 1.0 / Config.effective_zoom
			var re_val = player.global_position.x * 0.1 * scale_factor
			var im_val = -player.global_position.z * 0.1 * scale_factor
			if not is_finite(re_val): re_val = 0.5
			if not is_finite(im_val): im_val = 0.0
			re_input.text = "%.3f" % re_val
			im_input.text = "%.3f" % im_val
		iter_input.text = str(Config.iterations)
		speed_input.text = "%.1f" % (Config.movement_speed * 0.1)
		zoom_slider.value = _zoom_to_slider(Config.zoom_factor)
		_on_zoom_value_changed(zoom_slider.value)
		zero_speed_slider.value = Config.speed_near_zeros
		_on_zero_speed_value_changed(Config.speed_near_zeros)
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
		environment_button.selected = Config.environment_type
		sunrise_slider.value = Config.sunrise_direction
		_on_sunrise_value_changed(Config.sunrise_direction)
		shadows_checkbox.button_pressed = Config.shadows_enabled
		hud_complex_checkbox.button_pressed = Config.show_hud_complex
		hud_navigation_checkbox.button_pressed = Config.show_hud_navigation
		hud_zeros_checkbox.button_pressed = Config.show_hud_zeros
		rvm_checkbox.button_pressed = Config.show_rvm
		hud_monitor_checkbox.button_pressed = Config.show_hud_monitor
		hud_scale_slider.value = Config.hud_scale * 100.0
		_on_hud_scale_value_changed(hud_scale_slider.value)
		if player:
			auto_walk_checkbox.button_pressed = (player.auto_walk_state != 0) # 0 is AutoWalkState.NONE
		flow_checkbox.button_pressed = Config.show_flow
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

		multivalued_slider.value = Config.multivalued_n
		_on_multivalued_n_value_changed(Config.multivalued_n)
		multivalued_mode_button.selected = Config.multivalued_mode
		_on_multivalued_mode_selected(Config.multivalued_mode)
		cycle_speed_slider.value = Config.branch_cycle_speed
		_on_cycle_speed_value_changed(Config.branch_cycle_speed)
		morph_time_slider.value = Config.multivalued_morph_time
		_on_morph_time_value_changed(Config.multivalued_morph_time)

		func_button.selected = Config.function_type
		height_button.selected = Config.height_type
		_on_func_selected(Config.function_type)
		_on_height_selected(Config.height_type)
	else:
		tooltip.visible = false
		tooltip_timer.stop()
		_pending_tooltip_key = ""
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if not applied:
			Config.bg_music_volume = _initial_bg_music_volume
			Config.drone_volume = _initial_drone_volume
			Config.terrain_brightness = _initial_terrain_brightness
			Config.terrain_saturation = _initial_terrain_saturation
			Config.terrain_albedo = _initial_terrain_albedo
			Config.terrain_emission = _initial_terrain_emission
			Config.terrain_metallic = _initial_terrain_metallic
			Config.terrain_roughness = _initial_terrain_roughness

func _on_func_selected(index):
	var is_zeta_variant = (index >= 0 and index <= 3)

	if index == 6 and Config.function_type != 6:
		iter_input.text = "10"

	rational_container.visible = (index == 13)
	multivalued_mode_container.visible = (index == 14)
	multivalued_container.visible = (index == 14)
	_on_multivalued_mode_selected(multivalued_mode_button.selected)
	iter_container.visible = (is_zeta_variant or index == 6 or index == 7)
	critical_checkbox.visible = is_zeta_variant
	hud_zeros_checkbox.visible = is_zeta_variant
	auto_walk_checkbox.visible = is_zeta_variant
	rvm_checkbox.visible = is_zeta_variant

func _on_height_selected(index):
	var is_log = (index == 0)
	height_a_container.visible = is_log
	height_eps_container.visible = is_log

func _on_multivalued_mode_selected(index):
	var is_multivalued = (func_button.selected == 14)
	var is_cycle = (index == 0)
	cycle_speed_container.visible = is_multivalued and is_cycle
	morph_time_container.visible = is_multivalued and is_cycle

func _on_bg_music_value_changed(value):
	Config.bg_music_volume = value
	bg_music_value.text = str(int(value)) + "%"

func _on_drone_value_changed(value):
	Config.drone_volume = value
	drone_value.text = str(int(value)) + "%"

func _on_zoom_value_changed(value):
	var z = _slider_to_zoom(value)
	zoom_value.text = "x%.2f" % z
	Config.zoom_factor = z

func _on_zero_speed_value_changed(value):
	zero_speed_value.text = str(int(value)) + "%"

func _on_view_distance_value_changed(value):
	view_distance_value.text = str(int(value))

func _on_sunrise_value_changed(value):
	sunrise_value.text = str(int(value)) + "°"

func _on_hud_scale_value_changed(value):
	hud_scale_value.text = str(int(value)) + "%"

func _on_multivalued_n_value_changed(value):
	multivalued_value.text = str(int(value))
	Config.multivalued_n = int(value)

func _on_cycle_speed_value_changed(value):
	cycle_speed_value.text = "%.1f" % value
	Config.branch_cycle_speed = value

func _on_morph_time_value_changed(value):
	morph_time_value.text = "%.2f" % value
	Config.multivalued_morph_time = value

func _on_terrain_brightness_value_changed(value):
	Config.terrain_brightness = value / 50.0
	brightness_value.text = str(int(value)) + "%"

func _on_terrain_saturation_value_changed(value):
	Config.terrain_saturation = 0.3 + (value / 100.0) * 0.7
	saturation_value.text = str(int(value)) + "%"

func _on_terrain_albedo_value_changed(value):
	Config.terrain_albedo = value / 100.0
	albedo_value.text = str(int(value)) + "%"

func _on_terrain_emission_value_changed(value):
	Config.terrain_emission = value / 100.0
	emission_value.text = str(int(value)) + "%"

func _on_terrain_metallic_value_changed(value):
	Config.terrain_metallic = value / 100.0
	metallic_value.text = str(int(value)) + "%"

func _on_terrain_roughness_value_changed(value):
	Config.terrain_roughness = value / 100.0
	roughness_value.text = str(int(value)) + "%"

func _on_morph_selected(index):
	Config.morph_type = index
	if index == 1:
		toggle_menu(true)
		morph_overlay.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_morph_slider_changed(value):
	Config.morph_value = value

func _on_exit_morph_pressed():
	Config.morph_type = 0
	Config.morph_value = 1.0
	morph_overlay.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	morph_button.selected = 0

func _parse_poly(text: String) -> PackedFloat32Array:
	var coeffs = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	text = text.replace(" ", "").replace("-", "+-")
	var terms = text.split("+", false)

	for term in terms:
		if term == "": continue
		var coeff = 1.0
		var degree = 0

		if "z" in term:
			var parts = term.split("z")
			if parts[0] == "": coeff = 1.0
			elif parts[0] == "-": coeff = -1.0
			else: coeff = float(parts[0])

			if parts[1] == "": degree = 1
			elif parts[1].begins_with("^"):
				degree = int(parts[1].substr(1))
		else:
			coeff = float(term)
			degree = 0

		if degree >= 0 and degree < 10:
			coeffs[degree] += coeff

	return coeffs

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

	var iters = int(iter_input.text)
	var h_a = float(height_a_input.text)
	if not is_finite(h_a): h_a = 3.0
	var h_eps = float(height_eps_input.text)
	if not is_finite(h_eps): h_eps = 1.0
	var m_speed = float(speed_input.text) * 10.0
	if not is_finite(m_speed): m_speed = 100.0
	var c_height = float(camera_height_input.text)
	if not is_finite(c_height): c_height = 1.8

	Config.iterations = iters
	Config.movement_speed = m_speed
	Config.zoom_factor = _slider_to_zoom(zoom_slider.value)
	Config.effective_zoom = float(Config.zoom_factor)
	Config.speed_near_zeros = zero_speed_slider.value
	Config.camera_height = c_height
	Config.height_a = h_a
	Config.height_epsilon = h_eps
	Config.terrain_detail = terrain_detail_button.selected
	Config.antialiasing_mode = aa_button.selected
	Config.color_scheme = color_scheme_button.selected
	Config.show_curves = curves_checkbox.button_pressed
	Config.show_critical_stripe = critical_checkbox.button_pressed
	Config.environment_type = environment_button.selected
	Config.sunrise_direction = sunrise_slider.value
	Config.shadows_enabled = shadows_checkbox.button_pressed
	Config.show_hud_complex = hud_complex_checkbox.button_pressed
	Config.show_hud_navigation = hud_navigation_checkbox.button_pressed
	Config.show_hud_zeros = hud_zeros_checkbox.button_pressed
	Config.show_rvm = rvm_checkbox.button_pressed
	Config.show_hud_monitor = hud_monitor_checkbox.button_pressed
	Config.show_flow = flow_checkbox.button_pressed
	Config.bg_music_volume = bg_music_slider.value
	Config.drone_volume = drone_slider.value
	Config.terrain_brightness = brightness_slider.value / 50.0
	Config.terrain_saturation = 0.3 + (saturation_slider.value / 100.0) * 0.7
	Config.terrain_albedo = albedo_slider.value / 100.0
	Config.terrain_emission = emission_slider.value / 100.0
	Config.terrain_metallic = metallic_slider.value / 100.0
	Config.terrain_roughness = roughness_slider.value / 100.0
	Config.view_distance = int(view_distance_slider.value)
	Config.hud_scale = hud_scale_slider.value / 100.0
	Config.function_type = func_button.selected
	Config.height_type = height_button.selected
	Config.multivalued_n = int(multivalued_slider.value)
	Config.multivalued_mode = multivalued_mode_button.selected
	Config.branch_cycle_speed = cycle_speed_slider.value
	Config.multivalued_morph_time = morph_time_slider.value

	apply_aa()

	if Config.function_type == 13:
		var expr = rational_input.text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			Config.rational_num_coeffs = _parse_poly(parts[0].replace("(", "").replace(")", ""))
			Config.rational_den_coeffs = _parse_poly(parts[1].replace("(", "").replace(")", ""))
		else:
			Config.rational_num_coeffs = _parse_poly(expr)
			Config.rational_den_coeffs = PackedFloat32Array([1, 0, 0, 0, 0, 0, 0, 0, 0, 0])

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
				Config.visited_zeros.clear()
				if "last_detected_t" in player:
					player.last_detected_t = -1.0
		else:
			player.auto_walk_state = 0 # NONE

	toggle_menu(true)

func _on_quit_pressed():
	get_tree().quit()

func _process(_delta):
	if tooltip.visible:
		_update_tooltip_position()

	if menu_overlay.visible:
		if abs(_slider_to_zoom(zoom_slider.value) - Config.zoom_factor) > 0.001:
			zoom_slider.value = _zoom_to_slider(Config.zoom_factor)
			_on_zoom_value_changed(zoom_slider.value)

	perf_label.visible = Config.performance_protection_active

	if not player:
		return

	var x = player.global_position.x
	var z = player.global_position.z

	var f = Field.get_field(x, z)

	# Update Zeta Zeros display
	var is_auto_walking = false
	if player and "auto_walk_state" in player:
		is_auto_walking = player.auto_walk_state != 0 # 0 is AutoWalkState.NONE

	var show_zeros = ((Config.function_type >= 0 and Config.function_type <= 3) and is_auto_walking and Config.show_hud_zeros)
	zeros_panel.visible = show_zeros

	if show_zeros:
		var total_count = Config.visited_zeros.size()
		var last_zeros_text = ""

		# Show all visited zeros in the scrolling list
		for i in range(total_count - 1, -1, -1):
			last_zeros_text += "t = %.3f\n" % Config.visited_zeros[i]

		zeros_count_label.text = "Count: %d" % total_count

		# Riemann-von Mangoldt formula: N(T) ≈ (T/2π) log(T/2πe) + 7/8
		# For small T, it's roughly (T/2π) * (log(T/2π) - 1)
		# A slightly more accurate version for visualization:
		if Config.show_rvm:
			var T = abs(z * 0.1)
			var val = 0.0
			if T > 0.1:
				val = (T / (2.0 * PI)) * (log(T / (2.0 * PI)) - 1.0) + 7.0/8.0
			rvm_label.text = "N(t) ≈ %.2f" % val
			rvm_label.visible = true
		else:
			rvm_label.visible = false

		zeros_list_label.text = last_zeros_text

	# Update shader uniforms
	var material = complex_rect.material as ShaderMaterial
	material.set_shader_parameter("current_f", f)
	material.set_shader_parameter("multivalued_n", Config.multivalued_n)
	material.set_shader_parameter("branch_cycle_speed", Config.branch_cycle_speed)
	material.set_shader_parameter("multivalued_morph_time", Config.multivalued_morph_time)
	material.set_shader_parameter("function_type", Config.function_type)
	material.set_shader_parameter("color_scheme", Config.color_scheme)
	material.set_shader_parameter("scale", current_scale)
	material.set_shader_parameter("performance_protection_active", Config.performance_protection_active)

	var scale_factor = 1.0 / Config.effective_zoom
	domain_label.text = "Re = %.3f\nIm = %.3f" % [x * 0.1 * scale_factor, -z * 0.1 * scale_factor]
	var target_text = "Re = %.3f\nIm = %.3f\n|f| = %.3f" % [f.x, f.y, f.length()]
	if Config.function_type == 14:
		var k = 0
		if Config.multivalued_mode == 0:
			var progress = fmod(Config.branch_time * Config.branch_cycle_speed, 1.0) * Config.multivalued_n
			k = int(floor(progress))
		else:
			k = Config.current_branch
		target_text += "\nBranch k = %d" % k
	target_label.text = target_text

	complex_panel.visible = Config.show_hud_complex
	info_panel.visible = Config.show_hud_navigation
	monitor_panel.visible = Config.show_hud_monitor
	if Config.show_hud_monitor:
		var monitor_text = "FPS: %d" % Engine.get_frames_per_second()
		if world_manager:
			monitor_text += "\n\nChunks"
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
					monitor_text += "\n%d: %d" % [world_manager.LOD_SUBS[i], lod_counts[i]]

		fps_label.text = monitor_text

	_update_hud_layout()

var _last_hud_state = {}

func _update_hud_layout():
	if not hud_columns: return

	var cards = [complex_panel, info_panel, monitor_panel, zeros_panel, perf_label]
	var current_state = {
		"size": get_viewport().size,
		"scale": Config.hud_scale,
		"visibility": cards.map(func(c): return c.visible)
	}

	if current_state.hash() == _last_hud_state.hash():
		return
	_last_hud_state = current_state

	hud_columns.scale = Vector2.ONE * Config.hud_scale
	hud_columns.pivot_offset = hud_columns.size

	var available_height = (get_viewport().size.y - 40) / Config.hud_scale
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

func _apply_stack_layout(stack: VBoxContainer, desired_cards: Array):
	for child in stack.get_children():
		if not child in desired_cards:
			stack.remove_child(child)

	for i in range(desired_cards.size()):
		var card = desired_cards[i]
		if card.get_parent() != stack:
			if card.get_parent():
				card.get_parent().remove_child(card)
			stack.add_child(card)
		stack.move_child(card, 0)

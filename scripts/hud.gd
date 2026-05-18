extends CanvasLayer

@export var player: Node3D
@onready var complex_panel = $Control/HUDStack/ComplexAspect
@onready var info_panel = $Control/HUDStack/InfoPanel
@onready var complex_rect = $Control/HUDStack/ComplexAspect/ComplexPanel/MarginContainer/ClipPanel/ComplexPlane
@onready var domain_label = $Control/HUDStack/InfoPanel/MarginContainer/VBox/DomainLabel
@onready var target_label = $Control/HUDStack/InfoPanel/MarginContainer/VBox/TargetLabel
@onready var zeros_panel = $Control/HUDStack/ZerosPanel
@onready var zeros_count_label = $Control/HUDStack/ZerosPanel/MarginContainer/VBox/CountLabel
@onready var rvm_label = $Control/HUDStack/ZerosPanel/MarginContainer/VBox/RvmLabel
@onready var zeros_list_label = $Control/HUDStack/ZerosPanel/MarginContainer/VBox/Scroll/ListLabel
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

@onready var re_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ReContainer/ReInput
@onready var im_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ImContainer/ImInput
@onready var speed_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/SpeedContainer/SpeedInput
@onready var zero_speed_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ZeroSpeedContainer/ZeroSpeedSlider
@onready var zero_speed_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/ZeroSpeedContainer/ZeroSpeedValue
@onready var camera_height_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/CameraHeightContainer/CameraHeightInput
@onready var auto_walk_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/AutoWalkCheckbox

@onready var terrain_detail_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/TerrainDetailContainer/TerrainDetailButton
@onready var aa_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/AAContainer/AAButton
@onready var view_distance_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/ViewDistanceContainer/ViewDistanceSlider
@onready var view_distance_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/ViewDistanceContainer/ViewDistanceValue
@onready var curves_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/CurvesCheckbox
@onready var critical_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/CriticalCheckbox
@onready var golden_hour_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/GoldenHourCheckbox
@onready var day_night_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/DayNightCheckbox
@onready var shadows_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/ShadowsCheckbox

@onready var hud_complex_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudComplexCheckbox
@onready var hud_navigation_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudNavigationCheckbox
@onready var hud_zeros_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/HudZetaZerosCheckbox
@onready var rvm_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/RvmCheckbox

@onready var bg_music_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/BgMusicContainer/BgMusicSlider
@onready var bg_music_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/BgMusicContainer/BgMusicValue
@onready var drone_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/DroneContainer/DroneSlider
@onready var drone_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/DroneContainer/DroneValue

@onready var apply_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/ButtonsHBox/ApplyButton
@onready var close_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/ButtonsHBox/CloseButton
@onready var quit_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/ButtonsHBox/QuitContainer/QuitButton

@onready var tooltip = $TooltipLayer/Tooltip
@onready var tooltip_label = $TooltipLayer/Tooltip/MarginContainer/Label
@onready var tooltip_timer = $TooltipTimer

var _pending_tooltip_key: String = ""

const DESCRIPTIONS = {
	"Function": "Select the complex function to visualize on the terrain.",
	"Height Map": "Choose how the function's magnitude is mapped to terrain height.",
	"Parameter a": "Scaling factor for logarithmic height mapping.",
	"Parameter ε": "Small offset in logarithmic mapping to prevent log(0) at zeros.",
	"Iterations": "Number of terms used in the summation for Zeta and Eta functions.",
	"Expression": "Enter a rational function expression using 'z' as variable (e.g., z^2 - 1).",
	"Real (σ)": "Manually set the real part of the player's position in the complex plane.",
	"Imaginary (t)": "Manually set the imaginary part of the player's position.",
	"Camera Height": "Vertical height of the player's camera above the terrain.",
	"Move Speed": "Horizontal movement speed when navigating the complex plane.",
	"Speed near Zeros": "Slows down movement speed near function zeros to allow closer inspection.",
	"Automatic Walking": "Automatically follow the critical line (Re = 0.5) to find Riemann Zeta zeros.",
	"Terrain Details": "Quality and subdivision level of the procedurally generated terrain meshes.",
	"Antialiasing": "Choose a technique to reduce jagged edges in the 3D view.",
	"View Distance": "Number of terrain chunks loaded around the player.",
	"Level Curves": "Overlay contour lines for integer values of Re(f) (black) and Im(f) (white).",
	"Critical Stripe": "Visual guide indicating the 0 < Re < 1 region where non-trivial zeros reside.",
	"Golden Hour": "Enable cinematic lighting transitions between day and night.",
	"Day & Night Cycle": "Enable the dynamic sun and moon rotation system.",
	"Shadows": "Enable real-time directional shadows for terrain features.",
	"Complex plane": "Show the domain coloring map of the current position on the HUD.",
	"Navigation": "Show coordinate and magnitude information on the HUD.",
	"Zeta zeros": "Show the list of discovered zeros during automatic walking.",
	"Riemann–von Mangoldt": "Show the estimated number of zeros N(t) based on the Riemann–von Mangoldt formula.",
	"Background Music": "Adjust the volume of the ambient mathematical soundscape.",
	"Topographic Drone": "Adjust the volume of the terrain-responsive spatial audio."
}

var current_scale = 2.0
var _initial_bg_music_volume: float
var _initial_drone_volume: float

func _ready():
	apply_button.pressed.connect(_on_set_pos_pressed)
	close_button.pressed.connect(toggle_menu)
	quit_button.pressed.connect(_on_quit_pressed)
	func_button.item_selected.connect(_on_func_selected)
	height_button.item_selected.connect(_on_height_selected)

	bg_music_slider.value_changed.connect(_on_bg_music_value_changed)
	drone_slider.value_changed.connect(_on_drone_value_changed)
	zero_speed_slider.value_changed.connect(_on_zero_speed_value_changed)
	view_distance_slider.value_changed.connect(_on_view_distance_value_changed)

	func_button.clear()
	func_button.add_item("Zeta (σ > 0)")
	func_button.add_item("Zeta (reflection formula)")
	func_button.add_item("Gamma")
	func_button.add_item("Log Gamma")
	func_button.add_item("Dedekind Eta")
	func_button.add_item("Sin")
	func_button.add_item("Cos")
	func_button.add_item("Tan")
	func_button.add_item("Exp")
	func_button.add_item("Log")
	func_button.add_item("Rational")

	height_button.clear()
	height_button.add_item("Logarithmic (a*log(ε + abs))")
	height_button.add_item("Absolute")

	terrain_detail_button.clear()
	terrain_detail_button.add_item("High")
	terrain_detail_button.add_item("Medium")
	terrain_detail_button.add_item("Low")

	aa_button.clear()
	aa_button.add_item("Disabled (fastest)")
	aa_button.add_item("MSAA 3D x2 (average)")
	aa_button.add_item("MSAA 3D x4 (slow)")
	aa_button.add_item("MSAA 3D x8 (slowest)")
	aa_button.add_item("FXAA (fast)")
	aa_button.add_item("SMAA (average)")

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

		if player:
			var re_val = player.global_position.x * 0.1
			var im_val = -player.global_position.z * 0.1
			if not is_finite(re_val): re_val = 0.5
			if not is_finite(im_val): im_val = 0.0
			re_input.text = "%.3f" % re_val
			im_input.text = "%.3f" % im_val
		iter_input.text = str(Config.iterations)
		speed_input.text = "%.1f" % (Config.movement_speed * 0.1)
		zero_speed_slider.value = Config.speed_near_zeros
		_on_zero_speed_value_changed(Config.speed_near_zeros)
		camera_height_input.text = str(Config.camera_height)
		height_a_input.text = str(Config.height_a)
		height_eps_input.text = str(Config.height_epsilon)
		terrain_detail_button.selected = Config.terrain_detail
		aa_button.selected = Config.antialiasing_mode
		view_distance_slider.value = Config.view_distance
		_on_view_distance_value_changed(Config.view_distance)
		curves_checkbox.button_pressed = Config.show_curves
		critical_checkbox.button_pressed = Config.show_critical_stripe
		golden_hour_checkbox.button_pressed = Config.golden_hour
		day_night_checkbox.button_pressed = Config.day_night_cycle
		shadows_checkbox.button_pressed = Config.shadows_enabled
		hud_complex_checkbox.button_pressed = Config.show_hud_complex
		hud_navigation_checkbox.button_pressed = Config.show_hud_navigation
		hud_zeros_checkbox.button_pressed = Config.show_hud_zeros
		rvm_checkbox.button_pressed = Config.show_rvm
		if player:
			auto_walk_checkbox.button_pressed = (player.auto_walk_state != 0) # 0 is AutoWalkState.NONE
		bg_music_slider.value = Config.bg_music_volume
		_on_bg_music_value_changed(Config.bg_music_volume)
		drone_slider.value = Config.drone_volume
		_on_drone_value_changed(Config.drone_volume)

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

func _on_func_selected(index):
	var is_zeta_variant = (index == 0 or index == 1)

	if index == 4 and Config.function_type != 4:
		iter_input.text = "10"

	rational_container.visible = (index == 10)
	iter_container.visible = (is_zeta_variant or index == 4)
	critical_checkbox.visible = is_zeta_variant
	hud_zeros_checkbox.visible = is_zeta_variant
	auto_walk_checkbox.visible = is_zeta_variant
	rvm_checkbox.visible = is_zeta_variant

func _on_height_selected(index):
	var is_log = (index == 0)
	height_a_container.visible = is_log
	height_eps_container.visible = is_log

func _on_bg_music_value_changed(value):
	Config.bg_music_volume = value
	bg_music_value.text = str(int(value)) + "%"

func _on_drone_value_changed(value):
	Config.drone_volume = value
	drone_value.text = str(int(value)) + "%"

func _on_zero_speed_value_changed(value):
	zero_speed_value.text = str(int(value)) + "%"

func _on_view_distance_value_changed(value):
	view_distance_value.text = str(int(value))

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

func _on_set_pos_pressed():
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
	Config.speed_near_zeros = zero_speed_slider.value
	Config.camera_height = c_height
	Config.height_a = h_a
	Config.height_epsilon = h_eps
	Config.terrain_detail = terrain_detail_button.selected
	Config.antialiasing_mode = aa_button.selected
	Config.show_curves = curves_checkbox.button_pressed
	Config.show_critical_stripe = critical_checkbox.button_pressed
	Config.golden_hour = golden_hour_checkbox.button_pressed
	Config.day_night_cycle = day_night_checkbox.button_pressed
	Config.shadows_enabled = shadows_checkbox.button_pressed
	Config.show_hud_complex = hud_complex_checkbox.button_pressed
	Config.show_hud_navigation = hud_navigation_checkbox.button_pressed
	Config.show_hud_zeros = hud_zeros_checkbox.button_pressed
	Config.show_rvm = rvm_checkbox.button_pressed
	Config.bg_music_volume = bg_music_slider.value
	Config.drone_volume = drone_slider.value
	Config.view_distance = int(view_distance_slider.value)
	Config.function_type = func_button.selected
	Config.height_type = height_button.selected

	apply_aa()

	if Config.function_type == 10:
		var expr = rational_input.text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			Config.rational_num_coeffs = _parse_poly(parts[0].replace("(", "").replace(")", ""))
			Config.rational_den_coeffs = _parse_poly(parts[1].replace("(", "").replace(")", ""))
		else:
			Config.rational_num_coeffs = _parse_poly(expr)
			Config.rational_den_coeffs = PackedFloat32Array([1, 0, 0, 0, 0, 0, 0, 0, 0, 0])

	Config.save_settings()

	if player:
		if not is_finite(player.global_position.x) or not is_finite(player.global_position.y) or not is_finite(player.global_position.z):
			player.velocity = Vector3.ZERO
			player.global_position = Vector3(10.0 * re, 0.0, -10.0 * im)
		else:
			player.global_position.x = 10.0 * re
			player.global_position.z = -10.0 * im

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

	if not player:
		return

	var x = player.global_position.x
	var z = player.global_position.z

	var f = Field.get_field(x, z)

	# Update Zeta Zeros display
	var is_auto_walking = false
	if player and "auto_walk_state" in player:
		is_auto_walking = player.auto_walk_state != 0 # 0 is AutoWalkState.NONE

	var show_zeros = ((Config.function_type == 0 or Config.function_type == 1) and is_auto_walking and Config.show_hud_zeros)
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
	material.set_shader_parameter("scale", current_scale)

	domain_label.text = "Re = %.3f\nIm = %.3f" % [x * 0.1, -z * 0.1]
	target_label.text = "Re = %.3f\nIm = %.3f\n|f| = %.3f" % [f.x, f.y, f.length()]

	complex_panel.visible = Config.show_hud_complex
	info_panel.visible = Config.show_hud_navigation

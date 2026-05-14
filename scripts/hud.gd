extends CanvasLayer

@export var player: Node3D
@onready var complex_panel = $Control/HUDStack/ComplexPanel
@onready var info_panel = $Control/HUDStack/InfoPanel
@onready var complex_rect = $Control/HUDStack/ComplexPanel/MarginContainer/ComplexPlane
@onready var domain_label = $Control/HUDStack/InfoPanel/MarginContainer/VBox/DomainLabel
@onready var target_label = $Control/HUDStack/InfoPanel/MarginContainer/VBox/TargetLabel
@onready var zeros_panel = $Control/HUDStack/ZerosPanel
@onready var zeros_count_label = $Control/HUDStack/ZerosPanel/MarginContainer/VBox/CountLabel
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
@onready var camera_height_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/CameraHeightContainer/CameraHeightInput

@onready var normals_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/ShadingContainer/NormalsButton
@onready var curves_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/CurvesContainer/CurvesCheckbox
@onready var critical_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/CriticalContainer
@onready var critical_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/CriticalContainer/CriticalCheckbox
@onready var golden_hour_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/GoldenHourContainer/GoldenHourCheckbox
@onready var shadows_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/ShadowsContainer/ShadowsCheckbox

@onready var hud_complex_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/HudComplexContainer/HudComplexCheckbox
@onready var hud_navigation_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/HudNavigationContainer/HudNavigationCheckbox
@onready var hud_zeros_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/HudZetaZerosContainer
@onready var hud_zeros_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/RENDERING/HudZetaZerosContainer/HudZetaZerosCheckbox

@onready var bg_music_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/BgMusicContainer/BgMusicSlider
@onready var drone_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/DroneContainer/DroneSlider

@onready var apply_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/ApplyButton

var current_scale = 2.0

func _ready():
	apply_button.pressed.connect(_on_set_pos_pressed)
	func_button.item_selected.connect(_on_func_selected)
	height_button.item_selected.connect(_on_height_selected)

	func_button.clear()
	func_button.add_item("Zeta")
	func_button.add_item("Sin")
	func_button.add_item("Cos")
	func_button.add_item("Tan")
	func_button.add_item("Exp")
	func_button.add_item("Log")
	func_button.add_item("Rational")

	height_button.clear()
	height_button.add_item("Logarithmic (a*log(ε + abs))")
	height_button.add_item("Absolute")

	normals_button.clear()
	normals_button.add_item("Disabled")
	normals_button.add_item("Estimated")
	normals_button.add_item("Precise")

func toggle_menu():
	menu_overlay.visible = !menu_overlay.visible
	if menu_overlay.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if player:
			re_input.text = "%.3f" % (player.global_position.x * 0.1)
			im_input.text = "%.3f" % (-player.global_position.z * 0.1)
		iter_input.text = str(Field.iterations)
		speed_input.text = "%.1f" % (Field.movement_speed * 0.1)
		camera_height_input.text = str(Field.camera_height)
		height_a_input.text = str(Field.height_a)
		height_eps_input.text = str(Field.height_epsilon)
		normals_button.selected = Field.surface_shading_mode
		curves_checkbox.button_pressed = Field.show_curves
		critical_checkbox.button_pressed = Field.show_critical_stripe
		golden_hour_checkbox.button_pressed = Field.golden_hour
		shadows_checkbox.button_pressed = Field.shadows_enabled
		hud_complex_checkbox.button_pressed = Field.show_hud_complex
		hud_navigation_checkbox.button_pressed = Field.show_hud_navigation
		hud_zeros_checkbox.button_pressed = Field.show_hud_zeros
		bg_music_slider.value = Field.bg_music_volume
		drone_slider.value = Field.drone_volume

		func_button.selected = Field.function_type
		height_button.selected = Field.height_type
		_on_func_selected(Field.function_type)
		_on_height_selected(Field.height_type)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_func_selected(index):
	rational_container.visible = (index == 6)
	iter_container.visible = (index == 0)
	critical_container.visible = (index == 0)
	hud_zeros_container.visible = (index == 0)

func _on_height_selected(index):
	var is_log = (index == 0)
	height_a_container.visible = is_log
	height_eps_container.visible = is_log

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
	var iters = int(iter_input.text)
	var h_a = float(height_a_input.text)
	var h_eps = float(height_eps_input.text)
	var m_speed = float(speed_input.text) * 10.0
	var c_height = float(camera_height_input.text)

	Field.iterations = iters
	Field.movement_speed = m_speed
	Field.camera_height = c_height
	Field.height_a = h_a
	Field.height_epsilon = h_eps
	Field.surface_shading_mode = normals_button.selected
	Field.show_curves = curves_checkbox.button_pressed
	Field.show_critical_stripe = critical_checkbox.button_pressed
	Field.golden_hour = golden_hour_checkbox.button_pressed
	Field.shadows_enabled = shadows_checkbox.button_pressed
	Field.show_hud_complex = hud_complex_checkbox.button_pressed
	Field.show_hud_navigation = hud_navigation_checkbox.button_pressed
	Field.show_hud_zeros = hud_zeros_checkbox.button_pressed
	Field.bg_music_volume = bg_music_slider.value
	Field.drone_volume = drone_slider.value
	Field.function_type = func_button.selected
	Field.height_type = height_button.selected

	if Field.function_type == 6:
		var expr = rational_input.text.replace(" ", "")
		if "/" in expr:
			var parts = expr.split("/")
			Field.rational_num_coeffs = _parse_poly(parts[0].replace("(", "").replace(")", ""))
			Field.rational_den_coeffs = _parse_poly(parts[1].replace("(", "").replace(")", ""))
		else:
			Field.rational_num_coeffs = _parse_poly(expr)
			Field.rational_den_coeffs = PackedFloat32Array([1, 0, 0, 0, 0, 0, 0, 0, 0, 0])

	if player:
		player.global_position.x = 10.0 * re
		player.global_position.z = -10.0 * im

	toggle_menu()

func _process(_delta):
	if not player:
		return

	var x = player.global_position.x
	var z = player.global_position.z

	var f = Field.get_field(x, z)

	# Update Zeta Zeros display
	var is_auto_walking = false
	if player and "auto_walk_state" in player:
		is_auto_walking = player.auto_walk_state != 0 # 0 is AutoWalkState.NONE

	var show_zeros = (Field.function_type == 0 and is_auto_walking and Field.show_hud_zeros)
	zeros_panel.visible = show_zeros

	if show_zeros:
		var total_count = Field.visited_zeros.size()
		var last_zeros_text = ""

		# Show all visited zeros in the scrolling list
		for i in range(total_count - 1, -1, -1):
			last_zeros_text += "t = %.3f\n" % Field.visited_zeros[i]

		zeros_count_label.text = "ZEROS DETECTED: %d" % total_count
		zeros_list_label.text = last_zeros_text

	# Update shader uniforms
	var material = complex_rect.material as ShaderMaterial
	material.set_shader_parameter("current_f", f)
	material.set_shader_parameter("scale", current_scale)

	domain_label.text = "DOMAIN\nRe = %.3f\nIm = %.3f" % [x * 0.1, -z * 0.1]
	target_label.text = "TARGET\nRe = %.3f\nIm = %.3f\n|f| = %.3f" % [f.x, f.y, f.length()]

	complex_panel.visible = Field.show_hud_complex
	info_panel.visible = Field.show_hud_navigation

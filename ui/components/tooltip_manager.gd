extends CanvasLayer

const DESCRIPTIONS = {
	"Function": "Select the complex function to visualize on the terrain.",
	"Input": "Select the input expression or transformation passed to the function. Choose 'Identity' to evaluate directly at the complex coordinate z.",
	"Height Map": "Choose how the function's magnitude is mapped to terrain height.",
	"Parameter a": "Scaling factor for logarithmic height mapping.",
	"Parameter ε": "Small offset in logarithmic mapping to prevent log(0) at zeros.",
	"Parameter θ": "Angle in radians used to project the complex function onto the terrain. If 0 it is equal Re(f) and if π/2 it is equal Im(f).",
	"Iterations": "Number of terms used in the summation for Zeta and Eta functions, or steps for Mandelbrot recursion.",
	"Expression": "Enter a rational function expression with complex coefficients using 'z' as variable and 'i' as imaginary unit (e.g., z^2 - i).",
	"Real (x)": "Manually set the real part of the player's position in the complex plane.  Shortcut: CTRL + R to reset to (0, 0)",
	"Imaginary (y)": "Manually set the imaginary part of the player's position. Shortcut: CTRL + R to reset to (0, 0)",
	"Camera Height": "Vertical height of the player's camera above the terrain. Shortcut: SPACE (double press to reset)",
	"Move Speed": "Horizontal movement speed when navigating the complex plane. Shortcut: SHIFT (fast) / CTRL (slow)",
	"Zoom Factor": "Increase detail by scaling coordinates (1.0 / Zoom). Shortcut: Mouse Wheel (click to reset)",
	"Zeros proximity": "Terrain height threshold for detecting function zeros. Actually we look for minima along the path with magnitude below this value.",
	"Speed near Zeros": "Slows down movement speed near function zeros to allow closer inspection.",
	"Automatic Walking": "Automatically follow the critical line (Re = 0.5) to find Riemann Zeta zeros. Shortcut: CTRL + C",
	"Zero Walking": "Automatically find a path towards a zero using the Newton-Raphson method. Shortcut: CTRL + Z",
	"Terrain Details": "Quality and subdivision level of the procedurally generated terrain meshes.",
	"Antialiasing": "Choose a technique to reduce jagged edges in the 3D view.",
	"Branches (n)": "Number of branches for the multivalued function z^(1/n).",
	"Morph Time": "Duration of the smooth transition between branches.",
	"Color Scheme": "Select the color mapping for the complex plane of the target function.",
	"View Distance": "Number of terrain chunks loaded around the player.",
	"Level Curves": "Overlay contour lines for integer values of Re(f) (black) and Im(f) (white).  Shortcut: CTRL + LEFT CLICK to highlight the curve you are over / RIGHT CLICK to remove all highlights",
	"Curves Labels": "Show floating labels on level curves for integer values of Re(f) (black) and Im(f) (white). This uses raymarching and can be slow. Disabling it improves performance.",
	"Position marker": "Enable or disable the player's ground projection marker.",
	"Critical Stripe": "Visual guide indicating the 0 < Re < 1 region where non-trivial zeros reside.",
	"Freeze time": "Choose between a dynamic day/night cycle or a fixed time of day. Shortcut: CTRL + G (Golden Hour) / CTRL + N (Freeze / Unfreeze time)",
	"Day Duration": "Set the real-time duration for a full 24-hour mathematical day cycle.",
	"Time of day": "Manually set the current time of day when time is frozen.",
	"Sunrise Direction": "Adjust the angle from which the sun rises (0° is towards +x).",
	"Sky Luminosity": "Adjust the overall brightness of the sky and clouds.",
	"Sun Luminosity": "Adjust the intensity of the sun and moon light.",
	"Fog": "Enable or disable global volumetric fog effects.",
	"Fog Density": "Adjust the thickness of the fog and aerial perspective.",
	"Shadows": "Enable real-time directional shadows for terrain features.",
	"Phase wheel": "Show the phase wheel for the argument of f(s).",
	"Position": "Show coordinate and magnitude information for domain and target on the HUD.",
	"Zeros detection": "Show the list of discovered zeros during walking.",
	"Riemann–von Mangoldt": "Show the estimated number of zeta zeros N(t) based on the Riemann–von Mangoldt formula.",
	"Monitor FPS": "Show real-time performance metrics (FPS) on the HUD.",
	"Menu Scale": "Adjust the size of this menu panel. Changes are applied after the slider is released.",
	"HUD Scale": "Adjust the size of the HUD elements.",
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

@onready var tooltip = $Tooltip
@onready var tooltip_label = $Tooltip/MarginContainer/TooltipLabel
@onready var tooltip_timer = $TooltipTimer

@onready var tab_container = %MenuOverlay/%TabContainer

@onready var func_button = %MenuOverlay/%FuncContainer.get_option_button()
@onready var height_button = %MenuOverlay/%HeightContainer.get_option_button()
@onready var terrain_detail_button = %MenuOverlay/%TerrainDetailContainer.get_option_button()
@onready var aa_button = %MenuOverlay/%AAContainer.get_option_button()
@onready var color_scheme_button = %MenuOverlay/%ColorSchemeContainer.get_option_button()

var _pending_tooltip_key: String = ""

func _ready():
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	_setup_tooltips()

func _setup_tooltips():
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

func _any_dropdown_popup() -> bool:
	return (
		func_button.get_popup().visible
		|| height_button.get_popup().visible
		|| terrain_detail_button.get_popup().visible
		|| aa_button.get_popup().visible
		|| color_scheme_button.get_popup().visible
	)

func _on_tooltip_timer_timeout():
	if _any_dropdown_popup():
		return

	if _pending_tooltip_key != "":
		tooltip_label.custom_minimum_size.x = 250
		tooltip_label.text = DESCRIPTIONS[_pending_tooltip_key]
		if "Shortcut: " in tooltip_label.text:
			tooltip_label.text = tooltip_label.text.replace("Shortcut: ", "\n\n[font_size=12][color=#e8e4dc80]Shortcut: ") + "[/color][/font_size]"
		tooltip.modulate.a = 0.0
		tooltip.visible = true
		await get_tree().process_frame
		if not is_inside_tree() or not tooltip:
			return
		tooltip.size = Vector2.ZERO
		tooltip.reset_size()
		_update_tooltip_position()
		tooltip.modulate.a = 1.0

func _update_tooltip_position():
	var mouse_pos = get_viewport().get_mouse_position()
	tooltip.global_position = mouse_pos + Vector2(5, 5)

func _process(_delta):
	if tooltip.visible:
		_update_tooltip_position()

func hide_tooltip():
	tooltip_timer.stop()
	tooltip.visible = false
	_pending_tooltip_key = ""

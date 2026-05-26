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
@onready var func_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/FuncContainer/FuncButton
@onready var height_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/HeightContainer/HeightButton
@onready var height_a_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/HeightAContainer
@onready var height_a_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/HeightAContainer/HeightAInput
@onready var height_eps_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/HeightEpsContainer
@onready var height_eps_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/HeightEpsContainer/HeightEpsInput
@onready var iter_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/IterContainer
@onready var iter_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/IterContainer/IterSlider
@onready var iter_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/IterContainer/IterValue
@onready var rational_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/RationalContainer
@onready var rational_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/RationalContainer/RationalInput
@onready var multivalued_mode_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedModeContainer
@onready var multivalued_mode_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedModeContainer/MultivaluedModeButton
@onready var multivalued_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedContainer
@onready var multivalued_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedContainer/MultivaluedSlider
@onready var multivalued_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedContainer/MultivaluedValue
@onready var cycle_speed_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/CycleSpeedContainer
@onready var cycle_speed_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/CycleSpeedContainer/CycleSpeedSlider
@onready var cycle_speed_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/CycleSpeedContainer/CycleSpeedValue
@onready var morph_time_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MorphTimeContainer
@onready var morph_time_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MorphTimeContainer/MorphTimeSlider
@onready var morph_time_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MorphTimeContainer/MorphTimeValue

@onready var re_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ReContainer/ReInput
@onready var im_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ImContainer/ImInput
@onready var speed_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/SpeedContainer/SpeedInput
@onready var zoom_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ZoomContainer/ZoomSlider
@onready var zoom_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ZoomContainer/ZoomValue
@onready var zero_speed_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ZeroSpeedContainer/ZeroSpeedSlider
@onready var zero_speed_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ZeroSpeedContainer/ZeroSpeedValue
@onready var zero_proximity_nav_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ZeroProximityNavContainer/ZeroProximityNavSlider
@onready var zero_proximity_nav_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/ZeroProximityNavContainer/ZeroProximityNavValue
@onready var camera_height_input = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/CameraHeightContainer/CameraHeightInput
@onready var auto_walk_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/NAVIGATION/Margin/VBox/AutoWalkCheckbox

@onready var terrain_detail_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/TerrainDetailContainer/TerrainDetailButton
@onready var aa_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/AAContainer/AAButton
@onready var color_scheme_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/ColorSchemeContainer/ColorSchemeButton
@onready var view_distance_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/ViewDistanceContainer/ViewDistanceSlider
@onready var view_distance_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/ViewDistanceContainer/ViewDistanceValue
@onready var curves_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/CurvesCheckbox
@onready var critical_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/CriticalCheckbox
@onready var flow_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/FlowCheckbox
@onready var freeze_time_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FreezeTimeCheckbox
@onready var day_duration_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/DayDurationContainer
@onready var day_duration_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/DayDurationContainer/DayDurationSlider
@onready var day_duration_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/DayDurationContainer/DayDurationValue
@onready var static_time_container = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/StaticTimeContainer
@onready var static_time_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/StaticTimeContainer/StaticTimeSlider
@onready var static_time_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/StaticTimeContainer/StaticTimeValue
@onready var sunrise_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunriseContainer/SunriseSlider
@onready var sunrise_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunriseContainer/SunriseValue
@onready var sky_luminosity_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SkyLuminosityContainer/SkyLuminositySlider
@onready var sky_luminosity_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SkyLuminosityContainer/SkyLuminosityValue
@onready var sun_luminosity_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunLuminosityContainer/SunLuminositySlider
@onready var sun_luminosity_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunLuminosityContainer/SunLuminosityValue
@onready var self_illumination_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SelfIlluminationContainer/SelfIlluminationSlider
@onready var self_illumination_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SelfIlluminationContainer/SelfIlluminationValue
@onready var fog_enabled_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogEnabledCheckbox
@onready var fog_density_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDensityContainer/FogDensitySlider
@onready var fog_density_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDensityContainer/FogDensityValue
@onready var fog_distance_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDistanceContainer/FogDistanceSlider
@onready var fog_distance_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDistanceContainer/FogDistanceValue
@onready var shadows_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/ShadowsCheckbox

@onready var hud_complex_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/Margin/VBox/HudComplexCheckbox
@onready var hud_navigation_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/Margin/VBox/HudNavigationCheckbox
@onready var hud_zeros_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/Margin/VBox/HudZerosDetectionCheckbox
@onready var rvm_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/Margin/VBox/RvmCheckbox
@onready var hud_monitor_checkbox = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/Margin/VBox/HudMonitorCheckbox
@onready var hud_scale_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/Margin/VBox/HudScaleContainer/HudScaleSlider
@onready var hud_scale_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/HUD/Margin/VBox/HudScaleContainer/HudScaleValue

@onready var master_volume_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/Margin/VBox/MasterVolumeContainer/MasterVolumeSlider
@onready var master_volume_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/Margin/VBox/MasterVolumeContainer/MasterVolumeValue
@onready var bg_music_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/Margin/VBox/BgMusicContainer/BgMusicSlider
@onready var bg_music_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/Margin/VBox/BgMusicContainer/BgMusicValue
@onready var drone_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/Margin/VBox/DroneContainer/DroneSlider
@onready var drone_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/AUDIO/Margin/VBox/DroneContainer/DroneValue

@onready var detach_overlay = $Control/DetachOverlay
@onready var detach_slider = $Control/DetachOverlay/MarginContainer/HBox/DetachSlider
@onready var detach_label = $Control/DetachOverlay/MarginContainer/HBox/Label
@onready var detach_value = $Control/DetachOverlay/MarginContainer/HBox/DetachValue
@onready var exit_detach_button = $Control/DetachOverlay/MarginContainer/HBox/ExitDetachButton

var active_detached_slider: HSlider = null
var active_detached_value: Label = null

@onready var brightness_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/BrightnessContainer/BrightnessSlider
@onready var brightness_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/BrightnessContainer/BrightnessValue
@onready var saturation_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SaturationContainer/SaturationSlider
@onready var saturation_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SaturationContainer/SaturationValue
@onready var albedo_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/AlbedoContainer/AlbedoSlider
@onready var albedo_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/AlbedoContainer/AlbedoValue
@onready var emission_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/EmissionContainer/EmissionSlider
@onready var emission_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/EmissionContainer/EmissionValue
@onready var metallic_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/MetallicContainer/MetallicSlider
@onready var metallic_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/MetallicContainer/MetallicValue
@onready var roughness_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/RoughnessContainer/RoughnessSlider
@onready var roughness_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/RoughnessContainer/RoughnessValue

@onready var surface_texture_slider = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SurfaceTextureContainer/SurfaceTextureSlider
@onready var surface_texture_value = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SurfaceTextureContainer/SurfaceTextureValue
@onready var morph_button = $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/MorphContainer/MorphButton

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
	"Expression": "Enter a rational function expression with complext coefficients using 'z' as variable and 'i' as imaginary unit (e.g., z^2 - i).",
	"Real (x)": "Manually set the real part of the player's position in the complex plane.",
	"Imaginary (y)": "Manually set the imaginary part of the player's position.",
	"Camera Height": "Vertical height of the player's camera above the terrain.",
	"Move Speed": "Horizontal movement speed when navigating the complex plane.",
	"Zoom Factor": "Increase detail by scaling coordinates (1.0 / Zoom).",
	"Zeros proximity": "Terrain height threshold for detecting function zeros. Actually we look for minima along the path with magnitude below this value.",
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
	"Freeze time": "Choose between a dynamic day/night cycle or a fixed time of day.",
	"Day Duration": "Set the real-time duration for a full 24-hour mathematical day cycle.",
	"Time of day": "Manually set the current time of day when time is frozen.",
	"Sunrise Direction": "Adjust the angle from which the sun rises (180° is towards +σ).",
	"Sky Luminosity": "Adjust the overall brightness of the sky and clouds.",
	"Sun Luminosity": "Adjust the intensity of the sun and moon light.",
	"Fog Enabled": "Enable or disable global volumetric fog effects.",
	"Fog Density": "Adjust the thickness of the fog and aerial perspective.",
	"Fog Distance": "Set the distance from the camera where fog begins to appear.",
	"Shadows": "Enable real-time directional shadows for terrain features.",
	"Complex plane": "Show the domain coloring map of the current position on the HUD.",
	"Navigation": "Show coordinate and magnitude information on the HUD.",
	"Zeros detection": "Show the list of discovered zeros during walking.",
	"Riemann–von Mangoldt": "Show the estimated number of zeta zeros N(t) based on the Riemann–von Mangoldt formula.",
	"Performance Monitor": "Show real-time performance metrics (FPS) and chunks statistics on the HUD.",
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
var _initial_environment_type: int
var _initial_day_duration: float
var _initial_static_time: float
var _initial_fog_enabled: bool
var _initial_fog_density: float
var _initial_fog_distance: float
var _initial_terrain_detail: int
var _initial_antialiasing_mode: int
var _initial_view_distance: int
var _initial_shadows_enabled: bool

var _speed_modified: bool = false
var _camera_height_modified: bool = false

func _ready():
	hud_columns.offset_top = -1000
	speed_input.text_changed.connect(func(_t): _speed_modified = true)
	camera_height_input.text_changed.connect(func(_t): _camera_height_modified = true)
	apply_button.pressed.connect(_on_set_pos_pressed)
	close_button.pressed.connect(toggle_menu)
	quit_button.pressed.connect(_on_quit_pressed)
	func_button.item_selected.connect(_on_func_item_selected)
	height_button.item_selected.connect(_on_height_selected)
	multivalued_mode_button.item_selected.connect(_on_multivalued_mode_selected)

	master_volume_slider.value_changed.connect(_on_master_volume_value_changed)
	bg_music_slider.value_changed.connect(_on_bg_music_value_changed)
	drone_slider.value_changed.connect(_on_drone_value_changed)
	zero_proximity_nav_slider.value_changed.connect(_on_zero_proximity_nav_value_changed)
	zoom_slider.value_changed.connect(_on_zoom_value_changed)
	zero_speed_slider.value_changed.connect(_on_zero_speed_value_changed)
	view_distance_slider.value_changed.connect(_on_view_distance_value_changed)
	freeze_time_checkbox.toggled.connect(_on_freeze_time_toggled)
	day_duration_slider.value_changed.connect(_on_day_duration_value_changed)
	static_time_slider.value_changed.connect(_on_static_time_value_changed)
	sunrise_slider.value_changed.connect(_on_sunrise_value_changed)
	sky_luminosity_slider.value_changed.connect(_on_sky_luminosity_value_changed)
	sun_luminosity_slider.value_changed.connect(_on_sun_luminosity_value_changed)
	self_illumination_slider.value_changed.connect(_on_self_illumination_value_changed)
	fog_enabled_checkbox.toggled.connect(_on_fog_enabled_toggled)
	fog_density_slider.value_changed.connect(_on_fog_density_value_changed)
	fog_distance_slider.value_changed.connect(_on_fog_distance_value_changed)
	hud_scale_slider.value_changed.connect(_on_hud_scale_value_changed)
	iter_slider.value_changed.connect(_on_iterations_value_changed)

	terrain_detail_button.item_selected.connect(_on_terrain_detail_selected)
	aa_button.item_selected.connect(_on_aa_selected)
	shadows_checkbox.toggled.connect(_on_shadows_toggled)
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
	surface_texture_slider.value_changed.connect(_on_terrain_surface_texture_value_changed)
	morph_button.item_selected.connect(_on_morph_selected)
	morph_slider.value_changed.connect(_on_morph_slider_changed)
	exit_morph_button.pressed.connect(_on_exit_morph_pressed)

	func_button.clear()
	var sorted_keys = Config.FUNCTIONS.keys()
	sorted_keys.sort()
	for f_key in sorted_keys:
		var f_data = Config.FUNCTIONS.get(f_key, {})
		if f_data.get("hidden", false):
			continue
		func_button.add_item(f_data.get("name", "Unknown"), f_key)

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
	_disable_sliders_focus(self)
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	_last_zeros_visible = Config.show_hud_zeros

	detach_slider.value_changed.connect(_on_detach_slider_changed)
	exit_detach_button.pressed.connect(_on_exit_detach_pressed)
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/IterContainer/IterDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/IterContainer/IterSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/IterContainer/IterValue, "Iterations"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedContainer/MultivaluedDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedContainer/MultivaluedSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MultivaluedContainer/MultivaluedValue, "Branches (n)"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/CycleSpeedContainer/CycleSpeedDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/CycleSpeedContainer/CycleSpeedSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/CycleSpeedContainer/CycleSpeedValue, "Cycle Speed"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MorphTimeContainer/MorphTimeDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MorphTimeContainer/MorphTimeSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/FUNCTION/Margin/VBox/MorphTimeContainer/MorphTimeValue, "Morph Time"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/DayDurationContainer/DayDurationDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/DayDurationContainer/DayDurationSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/DayDurationContainer/DayDurationValue, "Day Duration"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/StaticTimeContainer/StaticTimeDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/StaticTimeContainer/StaticTimeSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/StaticTimeContainer/StaticTimeValue, "Time of day"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunriseContainer/SunriseDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunriseContainer/SunriseSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunriseContainer/SunriseValue, "Sunrise Direction"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SkyLuminosityContainer/SkyLuminosityDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SkyLuminosityContainer/SkyLuminositySlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SkyLuminosityContainer/SkyLuminosityValue, "Sky Luminosity"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunLuminosityContainer/SunLuminosityDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunLuminosityContainer/SunLuminositySlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SunLuminosityContainer/SunLuminosityValue, "Sun Luminosity"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SelfIlluminationContainer/SelfIlluminationDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SelfIlluminationContainer/SelfIlluminationSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/SelfIlluminationContainer/SelfIlluminationValue, "Self-Illumination"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDensityContainer/FogDensityDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDensityContainer/FogDensitySlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDensityContainer/FogDensityValue, "Fog Density"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDistanceContainer/FogDistanceDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDistanceContainer/FogDistanceSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/ENVIRONMENT/Margin/VBox/FogDistanceContainer/FogDistanceValue, "Fog Distance"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/BrightnessContainer/BrightnessDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/BrightnessContainer/BrightnessSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/BrightnessContainer/BrightnessValue, "Brightness"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SaturationContainer/SaturationDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SaturationContainer/SaturationSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SaturationContainer/SaturationValue, "Saturation"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/AlbedoContainer/AlbedoDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/AlbedoContainer/AlbedoSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/AlbedoContainer/AlbedoValue, "Albedo"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/EmissionContainer/EmissionDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/EmissionContainer/EmissionSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/EmissionContainer/EmissionValue, "Emission"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/MetallicContainer/MetallicDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/MetallicContainer/MetallicSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/MetallicContainer/MetallicValue, "Metallic"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/RoughnessContainer/RoughnessDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/RoughnessContainer/RoughnessSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/RoughnessContainer/RoughnessValue, "Roughness"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SurfaceTextureContainer/SurfaceTextureDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SurfaceTextureContainer/SurfaceTextureSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/TERRAIN/Margin/VBox/SurfaceTextureContainer/SurfaceTextureValue, "SurfaceTexture"))
	$Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/ViewDistanceContainer/ViewDistanceDetachButton.pressed.connect(func(): _on_detach_pressed($Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/ViewDistanceContainer/ViewDistanceSlider, $Control/MenuOverlay/CenterContainer/MainPanel/MarginContainer/ContentVBox/TabContainer/GRAPHICS/Margin/VBox/ViewDistanceContainer/ViewDistanceValue, "View Distance"))

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
	if morph_overlay.visible:
		_on_exit_morph_pressed()
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
		_initial_environment_type = Config.environment_type
		_initial_day_duration = Config.day_duration
		_initial_static_time = Config.static_time
		_initial_fog_enabled = Config.fog_enabled
		_initial_fog_density = Config.fog_density
		_initial_fog_distance = Config.fog_distance
		_initial_terrain_detail = Config.terrain_detail
		_initial_antialiasing_mode = Config.antialiasing_mode
		_initial_view_distance = Config.view_distance
		_initial_shadows_enabled = Config.shadows_enabled

		freeze_time_checkbox.button_pressed = (Config.environment_type != 0)

		if player:
			var scale_factor = 1.0 / Config.effective_zoom
			var re_val = player.global_position.x * 0.1 * scale_factor
			var im_val = -player.global_position.z * 0.1 * scale_factor
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
		static_time_slider.value = Config.static_time
		_on_static_time_value_changed(Config.static_time)
		sunrise_slider.value = Config.sunrise_direction
		_on_sunrise_value_changed(Config.sunrise_direction)
		sky_luminosity_slider.value = Config.sky_luminosity * 100.0
		_on_sky_luminosity_value_changed(sky_luminosity_slider.value)
		sun_luminosity_slider.value = Config.sun_luminosity * 100.0
		_on_sun_luminosity_value_changed(sun_luminosity_slider.value)
		self_illumination_slider.value = Config.self_illumination * 100.0
		_on_self_illumination_value_changed(self_illumination_slider.value)
		fog_enabled_checkbox.button_pressed = Config.fog_enabled
		fog_density_slider.value = Config.fog_density * 100.0
		_on_fog_density_value_changed(fog_density_slider.value)
		fog_distance_slider.value = Config.fog_distance
		_on_fog_distance_value_changed(fog_distance_slider.value)
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
		multivalued_mode_button.selected = Config.multivalued_mode
		_on_multivalued_mode_selected(Config.multivalued_mode)
		cycle_speed_slider.value = Config.branch_cycle_speed
		_on_cycle_speed_value_changed(Config.branch_cycle_speed)
		morph_time_slider.value = Config.multivalued_morph_time
		_on_morph_time_value_changed(Config.multivalued_morph_time)

		func_button.select(func_button.get_item_index(Config.function_type))
		height_button.selected = Config.height_type
		_on_func_selected(Config.function_type)
		_on_height_selected(Config.height_type)
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
			Config.environment_type = _initial_environment_type
			Config.day_duration = _initial_day_duration
			Config.static_time = _initial_static_time
			Config.fog_enabled = _initial_fog_enabled
			Config.fog_density = _initial_fog_density
			Config.fog_distance = _initial_fog_distance
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
	var is_multivalued = f_data.get("is_multivalued", false)

	if has_iters:
		iter_slider.min_value = iters_range[0]
		iter_slider.max_value = iters_range[1]
		iter_slider.step = iters_range[2]

		Config.iterations = Config.function_iterations.get(f_type, iters_range[3])
		iter_slider.value = Config.iterations
		_on_iterations_value_changed(Config.iterations)

	rational_container.visible = is_rational
	multivalued_mode_container.visible = is_multivalued
	multivalued_container.visible = is_multivalued
	_on_multivalued_mode_selected(multivalued_mode_button.selected)
	iter_container.visible = has_iters
	critical_checkbox.visible = is_dirichlect
	auto_walk_checkbox.visible = is_dirichlect
	rvm_checkbox.visible = is_dirichlect

func _on_height_selected(index):
	var is_log = (index == 0)
	height_a_container.visible = is_log
	height_eps_container.visible = is_log

func _on_multivalued_mode_selected(index):
	var is_multivalued = Config.function.get("is_multivalued", false)
	var is_cycle = (index == 0)
	cycle_speed_container.visible = is_multivalued and is_cycle
	morph_time_container.visible = is_multivalued and is_cycle

func _on_freeze_time_toggled(pressed: bool):
	if pressed:
		if Config.environment_type == 0:
			Config.environment_type = 4 # Static
	else:
		Config.environment_type = 0 # Dynamic

func _format_time(total_seconds: float) -> String:
	var hours = int(total_seconds) / 3600
	var minutes = (int(total_seconds) % 3600) / 60
	var seconds = int(total_seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _on_day_duration_value_changed(value):
	Config.day_duration = value
	day_duration_value.text = _format_time(value)

func _on_static_time_value_changed(value):
	Config.static_time = value
	static_time_value.text = _format_time(value)
func _on_master_volume_value_changed(value):
	Config.master_volume = value
	master_volume_value.text = str(int(value)) + "%"

func _on_bg_music_value_changed(value):
	Config.bg_music_volume = value
	bg_music_value.text = str(int(value)) + "%"

func _on_drone_value_changed(value):
	Config.drone_volume = value
	drone_value.text = str(int(value)) + "%"

func _on_zero_proximity_nav_value_changed(value):
	Config.zero_proximity_nav = value
	zero_proximity_nav_value.text = "%.2f" % value


func _on_zoom_value_changed(value):
	var z = _slider_to_zoom(value)
	zoom_value.text = "x%.2f" % z
	Config.zoom_factor = z

func _on_zero_speed_value_changed(value):
	zero_speed_value.text = str(int(value)) + "%"

func _on_view_distance_value_changed(value):
	view_distance_value.text = str(int(value))
	Config.view_distance = int(value)

func _on_sunrise_value_changed(value):
	sunrise_value.text = str(int(value)) + "°"

func _on_sky_luminosity_value_changed(value):
	Config.sky_luminosity = value / 100.0
	sky_luminosity_value.text = str(int(value)) + "%"

func _on_sun_luminosity_value_changed(value):
	Config.sun_luminosity = value / 100.0
	sun_luminosity_value.text = str(int(value)) + "%"

func _on_self_illumination_value_changed(value):
	Config.self_illumination = value / 100.0
	self_illumination_value.text = str(int(value)) + "%"

func _on_fog_enabled_toggled(pressed: bool):
	Config.fog_enabled = pressed

func _on_fog_density_value_changed(value):
	Config.fog_density = value / 100.0
	fog_density_value.text = "%.2f" % Config.fog_density

func _on_fog_distance_value_changed(value):
	Config.fog_distance = value
	fog_distance_value.text = str(int(value))

func _on_hud_scale_value_changed(value):
	hud_scale_value.text = str(int(value)) + "%"
	Config.hud_scale = value / 100.0
	_update_hud_layout()

func _on_iterations_value_changed(value):
	Config.iterations = int(value)
	iter_value.text = str(int(value))

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

func _on_terrain_surface_texture_value_changed(value):
	Config.terrain_surface_texture = value / 100.0
	surface_texture_value.text = str(int(value)) + "%"

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

		if depth == 0 and i > 0 and (c == "+" or c == "-"):
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
				var sign = 1.0
				if coeff_str.begins_with("+"):
					coeff_str = coeff_str.substr(1)
				elif coeff_str.begins_with("-"):
					sign = -1.0
					coeff_str = coeff_str.substr(1)

				# Remove surrounding parentheses if any
				if coeff_str.begins_with("(") and coeff_str.ends_with(")"):
					coeff_str = coeff_str.substr(1, coeff_str.length() - 2)
				coeff = _parse_complex(coeff_str) * sign

			var degree_str = parts[1]
			if degree_str == "": degree = 1
			elif degree_str.begins_with("^"):
				degree = int(degree_str.substr(1))
		else:
			coeff = _parse_complex(term)
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
	return (T / (2.0 * PI)) * (log(T / (2.0 * PI)) - 1.0) + 7.0/8.0

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
	Config.show_hud_monitor = hud_monitor_checkbox.button_pressed
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
	Config.static_time = static_time_slider.value
	Config.fog_enabled = fog_enabled_checkbox.button_pressed
	Config.fog_density = fog_density_slider.value / 100.0
	Config.fog_distance = fog_distance_slider.value
	Config.hud_scale = hud_scale_slider.value / 100.0
	Config.function_type = func_button.get_item_id(func_button.selected)
	Config.height_type = height_button.selected
	Config.multivalued_n = int(multivalued_slider.value)
	Config.multivalued_mode = multivalued_mode_button.selected
	Config.branch_cycle_speed = cycle_speed_slider.value
	Config.multivalued_morph_time = morph_time_slider.value

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

	toggle_menu(true)

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
		if Config.environment_type == 0:
			static_time_slider.value = Config.static_time
			static_time_value.text = _format_time(Config.static_time)

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
	material.set_shader_parameter("branch_cycle_speed", Config.branch_cycle_speed)
	material.set_shader_parameter("multivalued_morph_time", Config.multivalued_morph_time)
	material.set_shader_parameter("function_type", Config.function_type)
	material.set_shader_parameter("color_scheme", Config.color_scheme)
	material.set_shader_parameter("scale", current_scale)
	material.set_shader_parameter("performance_protection_active", Config.performance_protection_active)

	var scale_factor = 1.0 / Config.effective_zoom
	domain_label.text = "Re = %.3f\nIm = %.3f" % [x * 0.1 * scale_factor, -z * 0.1 * scale_factor]
	var target_text = "Re = %.3f\nIm = %.3f\n|f| = %.3f" % [f.x, f.y, f.length()]
	if f_data.get("is_multivalued", false):
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

	for i in range(desired_cards.size()):
		var card = desired_cards[i]
		if card.get_parent() != stack:
			if card.get_parent():
				card.get_parent().remove_child(card)
			stack.add_child(card)
		stack.move_child(card, 0)

func _rescale_card(card: Control, scale: float):
	if card == null: return

	if card.has_meta("last_applied_scale") and card.get_meta("last_applied_scale") == scale:
		return
	card.set_meta("last_applied_scale", scale)

	var stack = [card]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is Label:
			if not node.has_meta("base_font_size"):
				node.set_meta("base_font_size", node.get_theme_font_size("font_size"))
			node.add_theme_font_size_override("font_size", int(round(node.get_meta("base_font_size") * scale)))
		elif node is RichTextLabel:
			if not node.has_meta("base_font_size"):
				node.set_meta("base_font_size", node.get_theme_font_size("normal_font_size"))
			node.add_theme_font_size_override("normal_font_size", int(round(node.get_meta("base_font_size") * scale)))

		if node is Control:
			# Only scale custom minimum size for specific panels to maintain layout proportions
			if node.name == "ComplexAspect":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", Vector2(150, 150))
				node.custom_minimum_size = node.get_meta("base_min_size") * scale
			elif node.name == "ZerosPanel" or node.name == "InfoPanel":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", node.custom_minimum_size)
				node.custom_minimum_size.y = node.get_meta("base_min_size").y * scale

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

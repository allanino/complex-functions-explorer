class_name TargetSphere
extends AspectRatioContainer

@onready var color_rect: ColorRect = %ColorRect

const MAX_TRAIL_POINTS := 32
const TRAIL_MIN_STEP := 0.035
const SMOOTH_SPEED := 18.0
const DEFAULT_CAM_YAW := 0.55
const DEFAULT_CAM_PITCH := 0.36

var target_point: Vector3 = Vector3(0.0, -1.0, 0.0)
var display_point: Vector3 = Vector3(0.0, -1.0, 0.0)
var has_valid_point: bool = true

var _trail: Array[Vector3] = []
var _trail_dirty: bool = true

var cam_yaw: float = DEFAULT_CAM_YAW
var cam_pitch: float = DEFAULT_CAM_PITCH
var _dragging: bool = false


# Maps a complex target value w = f(z) onto the unit target Riemann sphere:
#   w = 0        -> (0, -1, 0)  (south pole)
#   w = infinity -> (0, +1, 0)  (north pole)
#   |w| = 1      -> equator (y = 0), with +1 -> +X and +i -> -Z.
# Returns Vector3.ZERO if w contains NaN.
static func complex_to_target_unit(w: Vector2) -> Vector3:
	if is_nan(w.x) or is_nan(w.y):
		return Vector3.ZERO
	if is_inf(w.x) or is_inf(w.y):
		return Vector3(0.0, 1.0, 0.0)
	var r2: float = w.length_squared()
	if not is_finite(r2) or r2 > 1e12:
		return Vector3(0.0, 1.0, 0.0)
	var den: float = 1.0 + r2
	return Vector3(2.0 * w.x / den, (r2 - 1.0) / den, -2.0 * w.y / den).normalized()


func _ready():
	Config.config_changed.connect(_on_config_changed)
	GameState.state_changed.connect(_on_state_changed)
	resized.connect(_on_resized)
	_update_material_config()
	_sync_camera_uniforms()
	_sync_point_uniforms()
	_sync_trail_uniforms()
	set_process(is_visible_in_tree())


func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(is_visible_in_tree())


func _on_resized():
	if custom_minimum_size.y != size.x:
		custom_minimum_size.y = size.x


func _on_config_changed(key: String):
	if key in ["color_scheme", "terrain_brightness", "terrain_saturation", "terrain_albedo", "terrain_emission"]:
		_update_material_config()
	elif key in ["function_type", "input_function_type", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs"]:
		clear_trail()


func _on_state_changed(key: String):
	if key == "is_teleporting" and GameState.is_teleporting:
		clear_trail()


func _update_material_config():
	if not color_rect or not color_rect.material:
		return
	var mat := color_rect.material as ShaderMaterial
	mat.set_shader_parameter("color_scheme", Config.color_scheme)
	mat.set_shader_parameter("brightness", Config.terrain_brightness)
	mat.set_shader_parameter("saturation", Config.terrain_saturation)
	mat.set_shader_parameter("albedo", Config.terrain_albedo)
	mat.set_shader_parameter("emission", Config.terrain_emission)


func _sync_camera_uniforms():
	if not color_rect or not color_rect.material:
		return
	var mat := color_rect.material as ShaderMaterial
	mat.set_shader_parameter("cam_yaw", cam_yaw)
	mat.set_shader_parameter("cam_pitch", cam_pitch)


func _sync_point_uniforms():
	if not color_rect or not color_rect.material:
		return
	var mat := color_rect.material as ShaderMaterial
	mat.set_shader_parameter("current_point", display_point)
	mat.set_shader_parameter("has_valid_point", has_valid_point)


func _sync_trail_uniforms():
	if not color_rect or not color_rect.material:
		return
	var mat := color_rect.material as ShaderMaterial
	var padded := PackedVector3Array()
	padded.resize(MAX_TRAIL_POINTS)
	padded.fill(Vector3.ZERO)
	var count: int = mini(_trail.size(), MAX_TRAIL_POINTS)
	for i in range(count):
		padded[i] = _trail[i]
	mat.set_shader_parameter("trail", padded)
	mat.set_shader_parameter("trail_count", count)
	_trail_dirty = false


func clear_trail() -> void:
	_trail.clear()
	_trail_dirty = true
	if is_inside_tree():
		_sync_trail_uniforms()


func update_data(f: Vector2) -> void:
	var u: Vector3 = complex_to_target_unit(f)
	if u.length_squared() < 0.5:
		has_valid_point = false
		return

	var was_invalid: bool = not has_valid_point
	has_valid_point = true
	target_point = u
	if was_invalid or _trail.is_empty():
		display_point = u
		_trail.clear()
		_trail.append(u)
		_trail_dirty = true
	elif _trail[_trail.size() - 1].distance_to(u) >= TRAIL_MIN_STEP:
		_trail.append(u)
		if _trail.size() > MAX_TRAIL_POINTS:
			_trail.pop_front()
		_trail_dirty = true


func _process(delta: float) -> void:
	if has_valid_point:
		var t: float = 1.0 - exp(-SMOOTH_SPEED * delta)
		var blended: Vector3 = display_point.lerp(target_point, t)
		if blended.length_squared() > 1e-6:
			display_point = blended.normalized()
		else:
			display_point = target_point
	_sync_point_uniforms()
	if _trail_dirty:
		_sync_trail_uniforms()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			cam_yaw = DEFAULT_CAM_YAW
			cam_pitch = DEFAULT_CAM_PITCH
			_sync_camera_uniforms()
			_dragging = false
		else:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		cam_yaw -= event.relative.x * 0.012
		cam_pitch = clampf(cam_pitch + event.relative.y * 0.012, -1.35, 1.35)
		_sync_camera_uniforms()


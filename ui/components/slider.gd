extends HBoxContainer

signal value_changed(value: float)
signal detach_requested(slider: HSlider, value_label: Label)

@export var text: String = "Label":
	set(v):
		text = v
		if is_inside_tree():
			$Label.text = v

@export var min_value: float = 0.0:
	set(v):
		min_value = v
		if is_inside_tree():
			$Slider.min_value = v

@export var max_value: float = 100.0:
	set(v):
		max_value = v
		if is_inside_tree():
			$Slider.max_value = v

@export var step: float = 1.0:
	set(v):
		step = v
		if is_inside_tree():
			$Slider.step = v

var _syncing: bool = false
@export var value: float = 0.0:
	set(v):
		if _syncing:
			value = v
			return
		value = v
		if is_inside_tree():
			$Slider.value = v

@export var value_text: String = "":
	set(v):
		value_text = v
		if is_inside_tree():
			$ValueLabel.text = v

@export var show_detach_button: bool = false:
	set(v):
		show_detach_button = v
		if is_inside_tree():
			$DetachButton.visible = v

static var _grabber_initialized: bool = false
static var _grabber_pressed_tex: Texture2D
static var _grabber_highlight_tex: Texture2D

static func _create_grabber_texture(color: Color, _size: int, center: Vector2) -> Texture2D:
	var data = PackedByteArray()
	data.resize(_size * _size * 4)
	var cx = center.x
	var cy = center.y
	var cr = int(color.r * 255.0)
	var cg = int(color.g * 255.0)
	var cb = int(color.b * 255.0)
	var ca = color.a
	var outer = 6.5
	var inner = outer - 1.0
	var inv_range = 1.0 / (outer - inner)
	var idx = 0

	for y in range(_size):
		var dy = (float(y) + 0.5) - cy
		var dy2 = dy * dy
		for x in range(_size):
			var dx = (float(x) + 0.5) - cx
			var dist = sqrt(dx * dx + dy2)
			if dist <= inner:
				data[idx] = cr
				data[idx+1] = cg
				data[idx+2] = cb
				data[idx+3] = int(ca * 255.0)
			elif dist < outer:
				var alpha = (outer - dist) * inv_range
				data[idx] = cr
				data[idx+1] = cg
				data[idx+2] = cb
				data[idx+3] = int(ca * alpha * 255.0)
			else:
				data[idx] = 0
				data[idx+1] = 0
				data[idx+2] = 0
				data[idx+3] = 0
			idx += 4

	var img = Image.create_from_data(_size, _size, false, Image.FORMAT_RGBA8, data)
	return ImageTexture.create_from_image(img)

func _ready():
	$Label.text = text
	$Slider.min_value = min_value
	$Slider.max_value = max_value
	$Slider.step = step
	$Slider.value = value
	$ValueLabel.text = value_text
	$DetachButton.visible = show_detach_button

	if not _grabber_initialized:
		_grabber_initialized = true
		var grabber_size = 18
		var center = Vector2(9.0, 9.0)

		var normal_color = Color(0.784314, 0.662745, 0.431373, 1.0)
		var hover_color = normal_color.lightened(0.2)
		var pressed_color = normal_color.darkened(0.2)

		var tex_normal = _create_grabber_texture(normal_color, grabber_size, center)
		_grabber_highlight_tex = _create_grabber_texture(hover_color, grabber_size, center)
		_grabber_pressed_tex = _create_grabber_texture(pressed_color, grabber_size, center)

		var global_theme = preload("res://ui/theme/theme.tres")
		global_theme.set_icon("grabber", "HSlider", tex_normal)
		global_theme.set_icon("grabber_highlight", "HSlider", _grabber_highlight_tex)
		global_theme.set_icon("grabber_disabled", "HSlider", tex_normal)

	$Slider.value_changed.connect(func(v):
		value = v
		value_changed.emit(v)
	)

	$Slider.drag_started.connect(func():
		if $Slider.has_meta("custom_grabber_pressed"):
			$Slider.add_theme_icon_override("grabber_highlight", $Slider.get_meta("custom_grabber_pressed"))
		else:
			$Slider.add_theme_icon_override("grabber_highlight", _grabber_pressed_tex)
	)

	$Slider.drag_ended.connect(func(_value_changed: bool):
		if $Slider.has_meta("custom_grabber_highlight"):
			$Slider.add_theme_icon_override("grabber_highlight", $Slider.get_meta("custom_grabber_highlight"))
		else:
			$Slider.remove_theme_icon_override("grabber_highlight")
	)

	$DetachButton.pressed.connect(func():
		detach_requested.emit($Slider, $ValueLabel)
	)

func set_value_no_signal(v: float):
	_syncing = true
	value = v
	_syncing = false
	if is_inside_tree():
		$Slider.set_value_no_signal(v)

func get_slider() -> HSlider:
	return $Slider

func get_value_label() -> Label:
	return $ValueLabel

func get_detach_button() -> Button:
	return $DetachButton

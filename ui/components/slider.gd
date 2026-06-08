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
static var _grabber_pressed_tex: ImageTexture
static var _grabber_highlight_tex: ImageTexture

static func _create_grabber_texture(color: Color, _size: int, center: Vector2) -> ImageTexture:
	var img = Image.create(_size, _size, false, Image.FORMAT_RGBA8)
	for y in range(_size):
		for x in range(_size):
			var dist = center.distance_to(Vector2(x, y))
			if dist <= 6.0:
				img.set_pixel(x, y, color)
			elif dist < 6.5:
				var alpha = (6.5 - dist) / 0.5
				img.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))
			else:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
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

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

@export var value: float = 0.0:
	set(v):
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
		var grabber_size = 14
		var img = Image.create(grabber_size, grabber_size, false, Image.FORMAT_RGBA8)
		var center = Vector2(5.5, 5.5)
		var gold_color = Color(0.862745, 0.729020, 0.474510, 1.0)
		for y in range(grabber_size):
			for x in range(grabber_size):
				var dist = center.distance_to(Vector2(x, y))
				if dist <= 5.5:
					img.set_pixel(x, y, gold_color)
				elif dist < 6.0:
					var alpha = (6.0 - dist) / 0.5
					img.set_pixel(x, y, Color(gold_color.r, gold_color.g, gold_color.b, alpha))
				else:
					img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
		var grabber_tex = ImageTexture.create_from_image(img)
		var global_theme = preload("res://ui/theme/theme.tres")
		global_theme.set_icon("grabber", "HSlider", grabber_tex)
		global_theme.set_icon("grabber_highlight", "HSlider", grabber_tex)
		global_theme.set_icon("grabber_disabled", "HSlider", grabber_tex)

	$Slider.value_changed.connect(func(v):
		value = v
		value_changed.emit(v)
	)

	$DetachButton.pressed.connect(func():
		detach_requested.emit($Slider, $ValueLabel)
	)

func set_value_no_signal(v: float):
	value = v
	$Slider.set_value_no_signal(v)

func get_slider() -> HSlider:
	return $Slider

func get_value_label() -> Label:
	return $ValueLabel

func get_detach_button() -> Button:
	return $DetachButton

extends HBoxContainer

signal toggled(toggled_on: bool)

@export var text: String = "":
	set(value):
		text = value
		if is_inside_tree():
			$Label.text = text

@export var button_pressed: bool = false:
	set(value):
		button_pressed = value
		if is_inside_tree():
			$Control/CheckBox.button_pressed = button_pressed

func _ready():
	$Label.text = text
	$Control/CheckBox.button_pressed = button_pressed
	_update_text_and_color(button_pressed)
	$Control/CheckBox.toggled.connect(func(toggled_on):
		button_pressed = toggled_on
		_update_text_and_color(toggled_on)
		toggled.emit(toggled_on)
	)

func set_pressed_no_signal(pressed: bool):
	button_pressed = pressed
	$Control/CheckBox.set_pressed_no_signal(pressed)
	_update_text_and_color(pressed)

func _update_text_and_color(is_on: bool):
	$Control/CheckBox.text = "On" if is_on else "Off"
	if is_on:
		$Control/CheckBox.remove_theme_color_override("font_color")
		$Control/CheckBox.remove_theme_color_override("font_hover_color")
		$Control/CheckBox.remove_theme_color_override("font_focus_color")
		$Control/CheckBox.remove_theme_color_override("font_hover_pressed_color")
	else:
		var ink_dim = Color(0.909804, 0.894118, 0.862745, 0.5)
		$Control/CheckBox.add_theme_color_override("font_color", ink_dim)
		$Control/CheckBox.add_theme_color_override("font_hover_color", ink_dim)
		$Control/CheckBox.add_theme_color_override("font_focus_color", ink_dim)
		$Control/CheckBox.add_theme_color_override("font_hover_pressed_color", ink_dim)

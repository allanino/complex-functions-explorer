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

static var _checkbox_icons_initialized: bool = false

func _ready():
	$Label.text = text
	$Control/CheckBox.button_pressed = button_pressed
	_update_text_and_color(button_pressed)
	$Control/CheckBox.toggled.connect(func(toggled_on):
		button_pressed = toggled_on
		_update_text_and_color(toggled_on)
		toggled.emit(toggled_on)
	)

	if not _checkbox_icons_initialized:
		_checkbox_icons_initialized = true
		
		var check_tex = preload("res://ui/theme/icons/checkbox_checked.png")
		var uncheck_tex = preload("res://ui/theme/icons/checkbox_unchecked.png")
		var check_disabled_tex = preload("res://ui/theme/icons/checkbox_checked_disabled.png")
		var uncheck_disabled_tex = preload("res://ui/theme/icons/checkbox_unchecked_disabled.png")
		
		var global_theme = preload("res://ui/theme/theme.tres")
		global_theme.set_icon("checked", "CheckBox", check_tex)
		global_theme.set_icon("unchecked", "CheckBox", uncheck_tex)
		global_theme.set_icon("checked_disabled", "CheckBox", check_disabled_tex)
		global_theme.set_icon("unchecked_disabled", "CheckBox", uncheck_disabled_tex)

func set_pressed_no_signal(pressed: bool):
	button_pressed = pressed
	$Control/CheckBox.set_pressed_no_signal(pressed)
	_update_text_and_color(pressed)

func _update_text_and_color(is_on: bool):
	$Control/CheckBox.text = "Enabled" if is_on else "Disabled"
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

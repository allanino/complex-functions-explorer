extends HBoxContainer

signal toggled(toggled_on: bool)

@export var text: String = "" :
	set(value):
		text = value
		if is_inside_tree():
			$Label.text = text

@export var button_pressed: bool = false :
	set(value):
		button_pressed = value
		if is_inside_tree():
			$Control/CheckBox.button_pressed = button_pressed

func _ready():
	$Label.text = text
	$Control/CheckBox.button_pressed = button_pressed
	$Control/CheckBox.text = "On" if button_pressed else "Off"
	$Control/CheckBox.toggled.connect(func(toggled_on):
		button_pressed = toggled_on
		$Control/CheckBox.text = "On" if toggled_on else "Off"
		toggled.emit(toggled_on)
	)

func set_pressed_no_signal(pressed: bool):
	button_pressed = pressed
	$Control/CheckBox.set_pressed_no_signal(pressed)
	$Control/CheckBox.text = "On" if pressed else "Off"

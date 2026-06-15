extends HBoxContainer

@export var text: String = "Label" :
	set(v):
		text = v
		if is_inside_tree():
			$Label.text = v

@export var input_text: String = "" :
	set(v):
		input_text = v
		if is_inside_tree():
			$LineEdit.text = v

@export var placeholder_text: String = "" :
	set(v):
		placeholder_text = v
		if is_inside_tree():
			$LineEdit.placeholder_text = v

func _ready():
	$Label.text = text
	$LineEdit.text = input_text
	$LineEdit.placeholder_text = placeholder_text
	$LineEdit.gui_input.connect(_on_line_edit_gui_input)

var _dead_key_active: bool = false

func _on_line_edit_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		var is_dead_circumflex = (event.keycode == KEY_DEAD_CIRCUMFLEX)

		if _dead_key_active:
			if event.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]:
				return # Ignore modifiers, keep dead key active

			get_viewport().set_input_as_handled()
			var char_to_insert = ""
			if event.keycode == KEY_0: char_to_insert = "⁰"
			elif event.keycode == KEY_1: char_to_insert = "¹"
			elif event.keycode == KEY_2: char_to_insert = "²"
			elif event.keycode == KEY_3: char_to_insert = "³"
			elif event.keycode == KEY_4: char_to_insert = "⁴"
			elif event.keycode == KEY_5: char_to_insert = "⁵"
			elif event.keycode == KEY_6: char_to_insert = "⁶"
			elif event.keycode == KEY_7: char_to_insert = "⁷"
			elif event.keycode == KEY_8: char_to_insert = "⁸"
			elif event.keycode == KEY_9: char_to_insert = "⁹"
			elif event.keycode == KEY_SPACE: char_to_insert = "^"
			else:
				char_to_insert = "^"
				if event.unicode != 0:
					char_to_insert += String.chr(event.unicode)

			_dead_key_active = false

			if char_to_insert != "":
				var le = $LineEdit
				le.insert_text_at_caret(char_to_insert)
				le.text_changed.emit(le.text)
			return

		if is_dead_circumflex:
			_dead_key_active = true
			get_viewport().set_input_as_handled()

func get_line_edit() -> LineEdit:
	return $LineEdit

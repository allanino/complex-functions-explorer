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

func get_line_edit() -> LineEdit:
	return $LineEdit

func _on_line_edit_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		var is_circumflex = false
		if event.unicode == 94:
			is_circumflex = true
		else:
			var dead_circumflex_keycode = -1
			if ClassDB.class_has_integer_constant("@GlobalScope", "KEY_DEAD_CIRCUMFLEX"):
				dead_circumflex_keycode = ClassDB.class_get_integer_constant("@GlobalScope", "KEY_DEAD_CIRCUMFLEX")
			if dead_circumflex_keycode != -1 and event.keycode == dead_circumflex_keycode:
				is_circumflex = true
			else:
				var keycode_str = OS.get_keycode_string(event.keycode).to_lower()
				var key_label_str = OS.get_keycode_string(event.key_label).to_lower()
				if "circumflex" in keycode_str or "circumflex" in key_label_str:
					is_circumflex = true
				elif "asciicircum" in keycode_str or "asciicircum" in key_label_str:
					is_circumflex = true
		
		if is_circumflex:
			var line_edit = $LineEdit
			var caret = line_edit.caret_column
			var old_text = line_edit.text
			
			# Insert '^' manually at caret position
			var new_text = old_text.substr(0, caret) + "^" + old_text.substr(caret)
			line_edit.text = new_text
			line_edit.caret_column = caret + 1
			
			# Cancel IME to abort any composition sessions
			if line_edit.has_method("cancel_ime"):
				line_edit.cancel_ime()
				
			# Emit text_changed signal since we manually edited text
			line_edit.text_changed.emit(new_text)
			
			# Prevent Godot from processing this event further (bypassing X11/IBus composition bug)
			get_viewport().set_input_as_handled()

func _process(_delta):
	var line_edit = $LineEdit
	if line_edit.has_ime_text():
		line_edit.apply_ime()

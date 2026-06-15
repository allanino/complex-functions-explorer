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

func _on_line_edit_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_DEAD_CIRCUMFLEX or event.keycode == KEY_ASCIICIRCUM or event.unicode == 94:
			var le = $LineEdit
			var pos = le.caret_column
			le.text = le.text.insert(pos, "^")
			le.caret_column = pos + 1
			le.text_changed.emit(le.text)
			get_viewport().set_input_as_handled()

func get_line_edit() -> LineEdit:
	return $LineEdit

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
	set_process(true)
	$LineEdit.gui_input.connect(_on_line_edit_gui_input)

func _process(_delta):
	# Force IME off continuously to defeat LineEdit's internal re-enablement on Linux,
	# preventing Godot 4.3 IBus dead key freezes.
	if $LineEdit.has_focus() and is_inside_tree() and get_window() != null:
		DisplayServer.window_set_ime_active(false, get_window().get_window_id())

func _on_line_edit_gui_input(event: InputEvent):
	# Also catch it here just in case _process runs too late between input events.
	if is_inside_tree() and get_window() != null:
		DisplayServer.window_set_ime_active(false, get_window().get_window_id())

	if event is InputEventKey and event.pressed:
		if event.keycode == 4194419 or event.unicode == 94:
			get_viewport().set_input_as_handled()
			$LineEdit.insert_text_at_caret("^")
			$LineEdit.text_changed.emit($LineEdit.text)

func get_line_edit() -> LineEdit:
	return $LineEdit

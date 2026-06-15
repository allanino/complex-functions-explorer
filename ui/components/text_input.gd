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
	$LineEdit.text_changed.connect(_on_line_edit_text_changed)

func _process(_delta):
	# Force IME off continuously to defeat LineEdit's internal re-enablement on Linux,
	# preventing Godot 4.3 IBus dead key freezes.
	if $LineEdit.has_focus() and is_inside_tree() and get_window() != null:
		DisplayServer.window_set_ime_active(false, get_window().get_window_id())

func _on_line_edit_text_changed(new_text: String):
	# Allow users to type ** instead of ^, and auto-replace it,
	# as a fallback if their dead key is uncatchable while IME is disabled.
	if "**" in new_text:
		var caret_pos = $LineEdit.caret_column
		var diff = 1 # "**" (2 chars) becomes "^" (1 char), so caret moves left by 1
		$LineEdit.text = new_text.replace("**", "^")
		$LineEdit.caret_column = max(0, caret_pos - diff)
		$LineEdit.text_changed.emit($LineEdit.text)

func _input(event: InputEvent):
	if not $LineEdit.has_focus() or not is_inside_tree():
		return

	if event is InputEventKey and event.pressed:
		# If IME is disabled, Godot 4 emits dead keys with unicode == 0 and their physical keycode.
		# Since this is a math input, the only dead key used is ^ (circumflex).
		# We catch any physical key < 255 (printable keys) that outputs unicode 0,
		# EXCLUDING those with Ctrl/Alt/Meta pressed (like Ctrl+C which also has unicode 0).
		var is_dead_key = (event.physical_keycode > 0 and event.physical_keycode < 255 and event.unicode == 0 and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed)

		# If it's a dead key OR Godot 3's dead circumflex keycode OR explicitly the circumflex character:
		if event.keycode == 4194419 or event.unicode == 94 or is_dead_key:
			get_viewport().set_input_as_handled()
			$LineEdit.insert_text_at_caret("^")
			$LineEdit.text_changed.emit($LineEdit.text)

func get_line_edit() -> LineEdit:
	return $LineEdit

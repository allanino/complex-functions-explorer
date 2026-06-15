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

	# Workaround for Godot Linux IME dead key freezes
	$LineEdit.focus_entered.connect(_on_line_edit_focus_entered)
	$LineEdit.focus_exited.connect(_on_line_edit_focus_exited)

func _on_line_edit_focus_entered():
	if is_inside_tree() and get_window() != null:
		DisplayServer.window_set_ime_active(false, get_window().get_window_id())

func _on_line_edit_focus_exited():
	if is_inside_tree() and get_window() != null:
		DisplayServer.window_set_ime_active(true, get_window().get_window_id())

func get_line_edit() -> LineEdit:
	return $LineEdit

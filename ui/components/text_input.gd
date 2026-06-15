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
	$LineEdit.focus_entered.connect(_on_focus_entered)
	$LineEdit.text_changed.connect(_on_text_changed)

func _on_focus_entered():
	# Wait for Godot's internal LineEdit focus handling to finish before overriding
	await get_tree().process_frame
	if DisplayServer.has_method("window_set_ime_active"):
		DisplayServer.window_set_ime_active(false, get_window().get_window_id())

func _on_text_changed(new_text: String):
	if "^" in new_text:
		var caret = $LineEdit.caret_column
		var modified = new_text.replace("^0", "⁰").replace("^1", "¹").replace("^2", "²").replace("^3", "³").replace("^4", "⁴").replace("^5", "⁵").replace("^6", "⁶").replace("^7", "⁷").replace("^8", "⁸").replace("^9", "⁹")
		if modified != new_text:
			var diff = new_text.length() - modified.length()
			$LineEdit.text = modified
			$LineEdit.caret_column = max(0, caret - diff)

func get_line_edit() -> LineEdit:
	return $LineEdit

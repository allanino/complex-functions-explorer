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

func get_line_edit() -> LineEdit:
	return $LineEdit

func _process(_delta):
	var line_edit = $LineEdit
	if line_edit.has_ime_text():
		line_edit.apply_ime()

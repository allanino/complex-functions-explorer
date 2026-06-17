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

@onready var _line_edit: LineEdit = $LineEdit

func _ready():
	$Label.text = text
	_line_edit.text = input_text
	_line_edit.placeholder_text = placeholder_text

	_line_edit.focus_entered.connect(_on_focus_entered)
	_line_edit.focus_exited.connect(_on_focus_exited)
	set_process(false)

func _on_focus_entered():
	set_process(true)

func _on_focus_exited():
	set_process(false)

func get_line_edit() -> LineEdit:
	return _line_edit

func _process(_delta):
	if _line_edit.has_ime_text():
		_line_edit.apply_ime()

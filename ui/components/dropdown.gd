extends HBoxContainer

@export var text: String = "Label" :
	set(v):
		text = v
		if is_inside_tree():
			$Label.text = v

func _ready():
	$Label.text = text

func get_option_button() -> OptionButton:
	return $OptionButton

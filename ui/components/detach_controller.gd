extends PanelContainer

@onready var main_ui = get_parent().get_parent() # parent is Control, grandparent is MainUI

@onready var detach_label = %Label
@onready var detach_slider = %DetachSlider
@onready var detach_value = %DetachValue
@onready var exit_detach_button = %ExitDetachButton

var active_detached_slider: HSlider = null
var active_detached_value: Label = null

func _ready():
	detach_slider.value_changed.connect(_on_detach_slider_changed)
	exit_detach_button.pressed.connect(_on_exit_detach_pressed)

func detach_slider_control(source_slider: HSlider, source_value_label: Label, title: String):
	active_detached_slider = null

	detach_label.text = title
	# Using set_block_signals(true) prevents _on_detach_slider_changed from firing while we update its properties.
	detach_slider.set_block_signals(true)
	# Expand bounds first to avoid clamping
	detach_slider.min_value = min(detach_slider.min_value, source_slider.min_value)
	detach_slider.max_value = max(detach_slider.max_value, source_slider.max_value)
	detach_slider.custom_minimum_size = Vector2(200.0, 50.0)

	detach_slider.min_value = source_slider.min_value
	detach_slider.max_value = source_slider.max_value
	detach_slider.step = source_slider.step
	detach_slider.value = source_slider.value
	detach_slider.set_block_signals(false)

	detach_value.text = source_value_label.text

	active_detached_slider = source_slider
	active_detached_value = source_value_label

	main_ui.toggle_menu(true)
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_detach_slider_changed(value: float):
	if active_detached_slider:
		# Emit value_changed to trigger the existing logic on the source slider
		active_detached_slider.value = value
		# Update the overlay label to match what the menu label would be
		# It's better to just copy the text from the source_value_label
		detach_value.text = active_detached_value.text

func _on_exit_detach_pressed():
	# Avoid accidental morph blending when returning from a detached slider
	if "morph_slider" in main_ui:
		main_ui.morph_slider.value = 1.0

	visible = false
	main_ui.menu_overlay.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

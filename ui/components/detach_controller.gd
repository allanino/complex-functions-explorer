extends PanelContainer

@onready var main_ui = get_parent().get_parent() # parent is Control, grandparent is MainUI

@onready var detach_label = %Label
@onready var detach_slider = %DetachSlider
@onready var detach_value = %DetachValue
@onready var play_button = %PlayButton
@onready var exit_detach_button = %ExitDetachButton

var active_detached_slider: HSlider = null
var active_detached_value: Label = null
var interaction_active: bool = true
var is_detaching: bool = false

var is_playing: bool = false
var play_direction: float = 1.0
var playback_value: float = 0.0

func _ready():
	detach_slider.value_changed.connect(_on_detach_slider_changed)
	exit_detach_button.pressed.connect(_on_exit_detach_pressed)
	play_button.pressed.connect(_on_play_pressed)
	# Performance: Default _process to false to avoid running empty loops when slider is not animating
	set_process(false)

func detach_slider_control(source_slider: HSlider, source_value_label: Label, title: String):
	is_playing = false
	set_process(false)
	play_button.text = "▶"
	play_direction = 1.0
	playback_value = source_slider.value

	active_detached_slider = null

	detach_label.text = title
	# Using set_block_signals(true) prevents _on_detach_slider_changed from firing while we update its properties.
	detach_slider.set_block_signals(true)
	# Expand bounds first to avoid clamping
	detach_slider.min_value = min(detach_slider.min_value, source_slider.min_value)
	detach_slider.max_value = max(detach_slider.max_value, source_slider.max_value)
	detach_slider.custom_minimum_size = Vector2(300.0, 50.0)

	detach_slider.min_value = source_slider.min_value
	detach_slider.max_value = source_slider.max_value
	detach_slider.step = source_slider.step
	detach_slider.value = source_slider.value
	detach_slider.set_block_signals(false)

	detach_value.text = source_value_label.text

	active_detached_slider = source_slider
	active_detached_value = source_value_label
	interaction_active = true

	is_detaching = true
	main_ui.toggle_menu(true)
	is_detaching = false
	visible = true
	set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameState.is_detached_interactive = true

func _process(delta):
	if visible and interaction_active:
		# Emulate mouse movement with Right Analog Stick
		var right_stick = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		if right_stick != Vector2.ZERO:
			var mouse_pos = get_viewport().get_mouse_position()
			var new_mouse_pos = mouse_pos + right_stick * 800.0 * delta
			var vp_size = get_viewport().get_visible_rect().size
			new_mouse_pos.x = clamp(new_mouse_pos.x, 0, vp_size.x)
			new_mouse_pos.y = clamp(new_mouse_pos.y, 0, vp_size.y)
			get_viewport().warp_mouse(new_mouse_pos)

	if is_playing:
		var range_val = detach_slider.max_value - detach_slider.min_value
		if range_val > 0.0:
			var speed = range_val / 5.0
			playback_value += play_direction * speed * delta
			if playback_value >= detach_slider.max_value:
				playback_value = detach_slider.max_value
				play_direction = -1.0
			elif playback_value <= detach_slider.min_value:
				playback_value = detach_slider.min_value
				play_direction = 1.0
			detach_slider.value = playback_value

func _on_play_pressed():
	is_playing = !is_playing
	if is_playing:
		play_button.text = "■"
		playback_value = detach_slider.value
	else:
		play_button.text = "▶"

func _on_detach_slider_changed(value: float):
	playback_value = value
	if active_detached_slider:
		# Emit value_changed to trigger the existing logic on the source slider
		active_detached_slider.value = value
		# Update the overlay label to match what the menu label would be
		# It's better to just copy the text from the source_value_label
		detach_value.text = active_detached_value.text

func _on_exit_detach_pressed():
	is_playing = false
	set_process(false)
	play_button.text = "▶"

	# Avoid accidental morph blending when returning from a detached slider
	if "morph_slider" in main_ui:
		main_ui.morph_slider.value = 1.0
		Config.morph_style = Config.MorphStyle.DISABLED

	interaction_active = false
	visible = false
	GameState.is_detached_interactive = false
	main_ui.toggle_menu()

func _input(event):
	if visible:
		if event is InputEventJoypadButton:
			if event.pressed:
				if event.button_index == JOY_BUTTON_RIGHT_STICK:
					main_ui.toggle_menu()
					get_viewport().set_input_as_handled()
					return
				
				if not interaction_active:
					return

				if event.button_index == JOY_BUTTON_B:
					_on_exit_detach_pressed()
					get_viewport().set_input_as_handled()
					return
				elif event.button_index == JOY_BUTTON_X or event.button_index == JOY_BUTTON_Y:
					_on_play_pressed()
					get_viewport().set_input_as_handled()
					return

			if not interaction_active:
				return

			if event.button_index == JOY_BUTTON_A:
				var m_event = InputEventMouseButton.new()
				m_event.button_index = MOUSE_BUTTON_LEFT
				m_event.pressed = event.pressed
				m_event.position = get_viewport().get_mouse_position()
				m_event.global_position = m_event.position
				get_viewport().push_input(m_event)
				get_viewport().set_input_as_handled()
				return
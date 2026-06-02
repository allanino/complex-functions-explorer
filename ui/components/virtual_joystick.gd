extends Control

@export var use_input_actions: bool = true
@export var is_camera: bool = false
@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_up: String = "move_forward"
@export var action_down: String = "move_backward"

var output: Vector2 = Vector2.ZERO
var is_pressed: bool = false
var touch_index: int = -1

var base_radius: float = 64.0
var stick_radius: float = 32.0

var base_pos: Vector2 = Vector2.ZERO
var stick_pos: Vector2 = Vector2.ZERO

func _ready():
    base_pos = size / 2.0
    stick_pos = size / 2.0

func _gui_input(event: InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed and touch_index == -1:
            touch_index = event.index
            is_pressed = true
            base_pos = event.position
            stick_pos = event.position
            update_output()
            queue_redraw()
            accept_event()
        elif not event.pressed and event.index == touch_index:
            reset_joystick()
            accept_event()
    elif event is InputEventScreenDrag and is_pressed and event.index == touch_index:
        stick_pos = event.position
        var diff = stick_pos - base_pos
        if diff.length() > base_radius:
            stick_pos = base_pos + diff.normalized() * base_radius
        update_output()
        queue_redraw()
        accept_event()

func _input(event):
    if event is InputEventScreenTouch and not event.pressed and event.index == touch_index:
        reset_joystick()

func reset_joystick():
    touch_index = -1
    is_pressed = false
    base_pos = size / 2.0
    stick_pos = size / 2.0
    update_output()
    queue_redraw()

func update_output():
    if not is_pressed:
        output = Vector2.ZERO
    else:
        var diff = stick_pos - base_pos
        output = diff / base_radius

    if use_input_actions and not is_camera:
        if output.x < 0:
            Input.action_press(action_left, -output.x)
            Input.action_release(action_right)
        elif output.x > 0:
            Input.action_press(action_right, output.x)
            Input.action_release(action_left)
        else:
            Input.action_release(action_left)
            Input.action_release(action_right)

        if output.y < 0:
            Input.action_press(action_up, -output.y)
            Input.action_release(action_down)
        elif output.y > 0:
            Input.action_press(action_down, output.y)
            Input.action_release(action_up)
        else:
            Input.action_release(action_up)
            Input.action_release(action_down)

func _draw():
    if is_pressed:
        draw_circle(base_pos, base_radius, Color(0, 0, 0, 0.3))
        draw_circle(stick_pos, stick_radius, Color(1, 1, 1, 0.5))
    else:
        draw_circle(size / 2.0, base_radius, Color(0, 0, 0, 0.3))
        draw_circle(size / 2.0, stick_radius, Color(1, 1, 1, 0.5))

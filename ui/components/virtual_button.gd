extends Control

signal pressed

var is_pressed: bool = false
var touch_index: int = -1

var base_radius: float = 32.0

var base_pos: Vector2 = Vector2.ZERO

func _ready():
    base_pos = size / 2.0

func _gui_input(event: InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed and touch_index == -1:
            var dist = event.position.distance_to(base_pos)
            if dist <= base_radius:
                touch_index = event.index
                is_pressed = true
                queue_redraw()
                accept_event()
        elif not event.pressed and event.index == touch_index:
            if is_pressed:
                var dist = event.position.distance_to(base_pos)
                if dist <= base_radius:
                    pressed.emit()
            reset_button()
            accept_event()

func reset_button():
    touch_index = -1
    is_pressed = false
    queue_redraw()

func _draw():
    # Draw gear teeth
    var num_teeth = 8
    var outer_radius = base_radius * 0.9
    var inner_radius = base_radius * 0.7
    var hole_radius = base_radius * 0.3

    var color = Color(1, 1, 1, 0.5) if is_pressed else Color(0, 0, 0, 0.3)

    # Outer circle for the main body
    draw_circle(size / 2.0, inner_radius, color)

    # Draw teeth
    for i in range(num_teeth):
        var angle = i * (PI * 2.0 / num_teeth)
        var next_angle = angle + (PI * 2.0 / num_teeth) * 0.5

        var p1 = size / 2.0 + Vector2(cos(angle), sin(angle)) * inner_radius
        var p2 = size / 2.0 + Vector2(cos(angle), sin(angle)) * outer_radius
        var p3 = size / 2.0 + Vector2(cos(next_angle), sin(next_angle)) * outer_radius
        var p4 = size / 2.0 + Vector2(cos(next_angle), sin(next_angle)) * inner_radius

        var points = PackedVector2Array([p1, p2, p3, p4])
        draw_polygon(points, PackedColorArray([color, color, color, color]))

    # Draw hole
    draw_circle(size / 2.0, hole_radius, Color(0, 0, 0, 0.0) if not is_pressed else Color(1, 1, 1, 0.5))

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
    # Draw a solid gray gear icon
    var num_teeth = 8
    var outer_radius = base_radius * 0.8
    var inner_radius = base_radius * 0.6
    var hole_radius = base_radius * 0.25
    var center = size / 2.0

    var fill_color = Color(0.65, 0.65, 0.65, 1.0) if is_pressed else Color(0.5, 0.5, 0.5, 1.0)
    var shadow_color = Color(0, 0, 0, 0.3)
    var outline_color = Color(0.2, 0.2, 0.2, 1.0)
    var inner_fill = Color(0.4, 0.4, 0.4, 1.0) if is_pressed else Color(0.3, 0.3, 0.3, 1.0)

    # Draw drop shadow
    var shadow_offset = Vector2(2, 4)
    # Background circle for shadow
    draw_circle(center + shadow_offset, inner_radius, shadow_color)
    # Shadow teeth
    for i in range(num_teeth):
        var angle = i * (PI * 2.0 / num_teeth)
        var next_angle = angle + (PI * 2.0 / num_teeth) * 0.5
        var p1 = center + shadow_offset + Vector2(cos(angle), sin(angle)) * inner_radius
        var p2 = center + shadow_offset + Vector2(cos(angle), sin(angle)) * outer_radius
        var p3 = center + shadow_offset + Vector2(cos(next_angle), sin(next_angle)) * outer_radius
        var p4 = center + shadow_offset + Vector2(cos(next_angle), sin(next_angle)) * inner_radius
        draw_polygon(PackedVector2Array([p1, p2, p3, p4]), PackedColorArray([shadow_color, shadow_color, shadow_color, shadow_color]))

    # Draw gear body (circle with hole)
    # To leave a transparent hole without a background mask, we can draw a thick arc
    # However draw_arc's thickness grows outward/inward, which is tricky.
    # Alternatively, we can draw a polygon with a hole.

    # Draw teeth first so they are under the main body ring outlines
    for i in range(num_teeth):
        var angle = i * (PI * 2.0 / num_teeth)
        var next_angle = angle + (PI * 2.0 / num_teeth) * 0.4

        var p1 = center + Vector2(cos(angle), sin(angle)) * inner_radius
        var p2 = center + Vector2(cos(angle), sin(angle)) * outer_radius
        var p3 = center + Vector2(cos(next_angle), sin(next_angle)) * outer_radius
        var p4 = center + Vector2(cos(next_angle), sin(next_angle)) * inner_radius

        var points = PackedVector2Array([p1, p2, p3, p4])
        draw_polygon(points, PackedColorArray([fill_color, fill_color, fill_color, fill_color]))
        # Outline for teeth
        draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), outline_color, 2.0, true)

    # Draw main body fill
    draw_circle(center, inner_radius, fill_color)

    # Draw inner dark circle to represent bevel/hole depth
    draw_circle(center, hole_radius * 1.5, inner_fill)

    # Draw hole (transparent) by drawing a circle of the background?
    # Godot _draw doesn't support subtractive drawing natively.
    # To simulate the hole, we can just leave it as the inner dark circle, or we can use a polygon mask.
    # A simple gray gear with a dark center is standard enough. Let's make it a dark gray hole.
    draw_circle(center, hole_radius, Color(0.1, 0.1, 0.1, 1.0))

    # Draw outlines
    draw_arc(center, inner_radius, 0, PI * 2, 32, outline_color, 2.0, true)
    draw_arc(center, hole_radius * 1.5, 0, PI * 2, 32, outline_color, 2.0, true)
    draw_arc(center, hole_radius, 0, PI * 2, 32, outline_color, 2.0, true)

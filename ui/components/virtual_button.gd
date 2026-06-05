extends Control

var settings_icon: Texture2D

signal pressed

var is_pressed: bool = false
var touch_index: int = -1

var base_radius: float = 32.0

var base_pos: Vector2 = Vector2.ZERO

func _ready():
    base_pos = size / 2.0
    settings_icon = preload("res://ui/assets/settings.svg")

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
    if settings_icon:
        var icon_size = settings_icon.get_size()
        var center = size / 2.0
        var target_size = base_radius * 1.5
        var scale_factor = target_size / max(icon_size.x, icon_size.y)
        var scaled_size = icon_size * scale_factor
        var draw_rect = Rect2(center - scaled_size / 2.0, scaled_size)
        var modulate_color = Color(0.8, 0.8, 0.8, 1.0) if is_pressed else Color(1.0, 1.0, 1.0, 0.8)
        draw_texture_rect(settings_icon, draw_rect, false, modulate_color)

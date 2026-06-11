extends Control

var settings_icon: Texture2D

signal pressed

var is_pressed: bool = false
var touch_index: int = -1

var base_radius: float = 64.0

var base_pos: Vector2 = Vector2.ZERO

func _ready():
    base_pos = size / 2.0
    base_radius = max(size.x, size.y)
    settings_icon = preload("res://ui/assets/settings.svg")

    if not DisplayServer.has_feature(DisplayServer.FEATURE_TOUCHSCREEN) or OS.has_feature("pc"):
        visible = false

func _gui_input(event: InputEvent):
    if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
        var _index = -2
        if event is InputEventScreenTouch:
            _index = event.index

        var rect = Rect2(Vector2.ZERO, size)

        if event.pressed and touch_index == -1:
            if rect.has_point(event.position):
                touch_index = _index
                is_pressed = true
                queue_redraw()
                accept_event()
        elif not event.pressed and _index == touch_index:
            if is_pressed:
                if rect.has_point(event.position):
                    pressed.emit()
            reset_button()
            accept_event()

func reset_button():
    touch_index = -1
    is_pressed = false
    queue_redraw()


func _draw():
    var panel_style = get_theme_stylebox("panel", "PanelContainer")
    if panel_style:
        draw_style_box(panel_style, Rect2(Vector2.ZERO, size))
    else:
        var bg_color = Color(0.04, 0.06, 0.1, 0.7)
        var border_color = Color(0.78, 0.66, 0.43, 0.3)
        draw_rect(Rect2(Vector2.ZERO, size), bg_color, true)
        draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 1.0)

    if settings_icon:
        var icon_size = settings_icon.get_size()
        var center = size / 2.0
        var _draw_rect = Rect2(center - icon_size / 2.0, icon_size)
        var gold_color = Color(0.784, 0.663, 0.431, 1.0)
        var modulate_color = gold_color * 0.7 if is_pressed else gold_color
        draw_texture_rect(settings_icon, _draw_rect, false, modulate_color)

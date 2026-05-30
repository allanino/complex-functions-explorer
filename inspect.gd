extends SceneTree

func _init():
    var scene = preload("res://ui/main_ui.tscn").instantiate()
    var menu = scene.get_node("Control/MenuOverlay")
    print("Menu layout_mode: ", menu.layout_mode)
    print("Menu anchors: right=", menu.anchor_right, " bottom=", menu.anchor_bottom)
    print("Menu size: ", menu.size)
    var center = menu.get_node("CenterContainer")
    print("Center layout_mode: ", center.layout_mode)
    print("Center anchors: right=", center.anchor_right, " bottom=", center.anchor_bottom)
    print("Center size: ", center.size)
    quit()

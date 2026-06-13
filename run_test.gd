extends SceneTree
func _init():
    var cf = load("res://math/complex_field.gd").new()
    var cfg = load("res://core/config_manager.gd").new()

    cfg.iterations = 1000
    var z1 = cf.zeta(0.499, 100.0)
    var z2 = cf.zeta(0.501, 100.0)
    print("distance at y=100: ", z1.distance_to(z2))

    cfg.iterations = 10
    var z1_2 = cf.zeta(0.499, 200.0)
    var z2_2 = cf.zeta(0.501, 200.0)
    print("distance at y=200: ", z1_2.distance_to(z2_2))
    quit()

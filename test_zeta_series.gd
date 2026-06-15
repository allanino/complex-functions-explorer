extends SceneTree

func _init():
    var complex_field_script = load("res://math/complex_field.gd")

    var K = complex_field_script.PATCH_MAX_K
    var max_terms = 2000

    var x = -0.5
    var y = 3.0

    var res = complex_field_script.compute_zeta_taylor_patch(x, y, max_terms)
    print(res[0])

    quit()

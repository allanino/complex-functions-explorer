extends SceneTree

func _init():
    var script = load("res://tests/test_complex_field.gd")
    var instance = script.new()
    print("Testing zeta...")
    instance.test_is_close_to_zero_zeta()
    print("Testing eta...")
    instance.test_is_close_to_zero_dirichlet_eta()
    print("Testing zeta_reflection...")
    instance.test_is_close_to_zero_zeta_reflection()
    print("Testing log...")
    instance.test_is_close_to_zero_log_fallback()
    print("Testing sin...")
    instance.test_is_close_to_zero_sin_fallback()
    print("Tests finished")
    quit()

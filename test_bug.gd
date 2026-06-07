extends SceneTree

func _init():
    var config = load("res://core/config_manager.gd").new()
    config.function_type = config.ComplexFunc.ZETA
    config.iterations = 5000
    print("Zeta iterations: ", config.iterations)
    print("Zeta in dict: ", config.function_iterations.get(config.ComplexFunc.ZETA))

    # Simulate _on_func_selected
    var f_type = config.ComplexFunc.DEDEKIND_ETA

    # ui/menu.gd:555
    config.function_type = f_type

    print("Dedekind iterations immediately after function_type change: ", config.iterations)

    var f_data = config.function
    var iters_range = f_data.get("iters_range", {})

    config.iterations = config.function_iterations.get(f_type, iters_range[3])
    print("Dedekind iterations after ui/menu logic: ", config.iterations)

    quit()

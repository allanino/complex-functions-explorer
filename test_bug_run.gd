extends SceneTree

func _init():
    var config_script = load("res://core/config_manager.gd")
    var config = config_script.new()

    # 1. Initialize
    config.function_type = config.ComplexFunc.ZETA
    config.iterations = 5000

    # Simulate UI Slider state
    var slider_val = 5000.0
    var slider_min = 200.0
    var slider_max = 10000.0

    print("Before switch - Config iterations: ", config.iterations)

    # 2. Switch to Dedekind (simulate menu.gd logic)
    var f_type = config.ComplexFunc.DEDEKIND_ETA
    config.function_type = f_type

    var f_data = config.function
    var iters_range = f_data.get("iters_range", {})

    # Simulating the slider property setters:
    # First set min
    slider_min = iters_range[0]
    # Then set max
    slider_max = iters_range[1]

    # Slider clamping simulation
    if slider_val > slider_max:
        slider_val = slider_max
        config.iterations = int(slider_val) # UI binding triggers!
    if slider_val < slider_min:
        slider_val = slider_min
        config.iterations = int(slider_val) # UI binding triggers!

    config.iterations = config.function_iterations.get(f_type, iters_range[3])
    slider_val = config.iterations

    print("After switch - Config iterations: ", config.iterations)

    quit()

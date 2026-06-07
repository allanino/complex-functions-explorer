extends SceneTree

func _init():
    # simulate the sequence of ui updates
    var slider_min = 200.0
    var slider_max = 10000.0
    var slider_val = 5000.0
    var config_iterations = 5000.0

    # Switch to Dedekind, iters_range = [1.0, 20.0, 1.0, 10.0]

    # 1. Update min:
    slider_min = 1.0
    if slider_val < slider_min:
        slider_val = slider_min
    elif slider_val > slider_max:
        slider_val = slider_max

    print("After min update: slider_val=", slider_val)

    # 2. Update max:
    slider_max = 20.0
    if slider_val < slider_min:
        slider_val = slider_min
    elif slider_val > slider_max:
        slider_val = slider_max
        # If the UI element auto-updates its value, it might trigger the signal here!
        # And when it triggers the signal, the value 20.0 gets sent to config.
        config_iterations = 20.0

    print("After max update: slider_val=", slider_val)

    # Let's say config_iterations gets updated to 20 because of the max change.
    # What happens in _on_func_selected next?

    # Config.iterations = Config.function_iterations.get(f_type, iters_range[3])
    # Which calls setter of Config.iterations!
    # Wait, in Config.function_iterations it had no value, so it sets 10.0
    config_iterations = 10.0

    # iter_slider.value = Config.iterations
    slider_val = config_iterations

    print("Final: config=", config_iterations, " slider=", slider_val)
    quit()

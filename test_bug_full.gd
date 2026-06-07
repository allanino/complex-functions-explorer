extends SceneTree

func _init():
	var config_script = load("res://core/config_manager.gd")
	var config = config_script.new()

	print("Initial function type: ", config.function_type)

	# Set ZETA with 5000 iterations
	config.function_type = config.ComplexFunc.ZETA
	config.iterations = 5000

	print("Function: ZETA, iterations: ", config.iterations)

	# Now switch to DEDEKIND
	config.function_type = config.ComplexFunc.DEDEKIND_ETA

	print("Switched to DEDEKIND. Iterations is now: ", config.iterations)

	quit()

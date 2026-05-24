extends SceneTree

func _init():
	print("Starting config verification...")
	var Config = load("res://scripts/config_manager.gd").new()
	Config._ready() # Initialize

	# Test 1: Initial state
	if Config.iterations != 500:
		print("FAIL: Initial iterations should be 500, got ", Config.iterations)
		quit(1)

	# Test 2: Change iterations for Zeta
	Config.iterations = 600
	print("Set Zeta iterations to 600")

	# Test 3: Switch to Dirichlet Beta
	# ComplexFunc.DIRICHLET_BETA is index 3
	Config.function_type = 3
	print("Switched to Dirichlet Beta")
	if Config.iterations != 500: # Beta default from iters_range[3] is 500.0
		print("FAIL: Beta iterations should be 500, got ", Config.iterations)
		quit(1)

	# Test 4: Switch back to Zeta
	Config.function_type = 0
	print("Switched back to Zeta")
	if Config.iterations != 600:
		print("FAIL: Zeta iterations should be preserved as 600, got ", Config.iterations)
		quit(1)

	# Test 5: Dedekind Eta (iters_range [1, 20, 1, 10])
	Config.function_type = 6
	print("Switched to Dedekind Eta")
	if Config.iterations != 10:
		print("FAIL: Dedekind Eta iterations should be 10, got ", Config.iterations)
		quit(1)

	print("Verification SUCCESS")
	quit(0)

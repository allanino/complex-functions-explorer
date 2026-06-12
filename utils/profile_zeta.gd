extends Node

const ComplexField = preload("res://math/complex_field.gd")

func _ready():
	print("Starting profile of zeta_continuation_with_derivatives...")
	# Perform a few warm-up runs
	for i in range(10):
		ComplexField.zeta_continuation_with_derivatives(0.25, 1000.0, 10000)

	var runs = 1000
	var times = []
	var total_time = 0.0

	for i in range(runs):
		var start = Time.get_ticks_usec()
		var _res = ComplexField.zeta_continuation_with_derivatives(0.25, 1000.0, 10000)
		var end = Time.get_ticks_usec()
		var duration = (end - start) / 1000.0 # convert microseconds to milliseconds
		times.append(duration)
		total_time += duration

	var min_time = times[0]
	var max_time = times[0]
	for t in times:
		if t < min_time:
			min_time = t
		if t > max_time:
			max_time = t

	var avg_time = total_time / runs

	print("\n=== PROFILE RESULTS (1000 runs) ===")
	print("Total Execution Time: %f ms" % total_time)
	print("Average Time per Run: %f ms" % avg_time)
	print("Min Time:             %f ms" % min_time)
	print("Max Time:             %f ms" % max_time)
	print("===================================\n")

	get_tree().quit()

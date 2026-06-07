extends SceneTree

func _init():
	var cards = []

	var a = {
		"size": Vector2(1920, 1080),
		"scale": 1.0,
		"visibility": [true, true, true, false, false, false],
		"heights": [240.0, 300.0, 150.0, 0.0, 0.0, 0.0],
		"available_height": 1000.0
	}
	var b = {
		"size": Vector2(1920, 1080),
		"scale": 1.0,
		"visibility": [true, true, true, false, false, false],
		"heights": [240.0, 300.0, 150.0, 0.0, 0.0, 0.0],
		"available_height": 1000.0
	}
	print(a.hash() == b.hash())
	quit()

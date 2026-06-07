extends MainLoop

func _process(delta):
	var a = { "a": [1, 2, 3], "b": 4 }
	var b = { "a": [1, 2, 3], "b": 4 }
	var c = { "a": [1, 2, 4], "b": 4 }
	print("a hash: ", a.hash())
	print("b hash: ", b.hash())
	print("c hash: ", c.hash())
	return true

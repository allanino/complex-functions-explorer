# Shared field and height functions for GDScript
class_name Field

static func get_field(x: float, z: float) -> Vector2:
	var theta1 = 0.15 * x + 0.12 * z
	var theta2 = 0.31 * x - 0.27 * z

	var re = cos(theta1) + 0.5 * cos(theta2)
	var im = sin(theta1) + 0.5 * sin(theta2)

	return Vector2(re, im)

static func get_height(x: float, z: float) -> float:
	var f = get_field(x, z)
	return log(1.0 + f.length())

class_name DoubleVector2

var x: float
var y: float

func _init(_x: float = 0.0, _y: float = 0.0):
	x = _x
	y = _y

func _to_string() -> String:
	return "(%f, %f)" % [x, y]

func length() -> float:
	return sqrt(x * x + y * y)

func length_squared() -> float:
	return x * x + y * y

func distance_to(other: DoubleVector2) -> float:
	var dx = x - other.x
	var dy = y - other.y
	return sqrt(dx * dx + dy * dy)

func normalized() -> DoubleVector2:
	var l = length()
	if l == 0:
		return DoubleVector2.new(0, 0)
	return DoubleVector2.new(x / l, y / l)

func to_vector2() -> Vector2:
	return Vector2(x, y)

func add(other: DoubleVector2) -> DoubleVector2:
    return DoubleVector2.new(x + other.x, y + other.y)

func sub(other: DoubleVector2) -> DoubleVector2:
    return DoubleVector2.new(x - other.x, y - other.y)

func mul(scalar: float) -> DoubleVector2:
    return DoubleVector2.new(x * scalar, y * scalar)

func div(scalar: float) -> DoubleVector2:
    return DoubleVector2.new(x / scalar, y / scalar)

func complex_mul(other: DoubleVector2) -> DoubleVector2:
    if ClassDB.class_exists("ComplexFunctions"):
        var ext = ClassDB.instantiate("ComplexFunctions")
        var res = ext.call("complex_mul", x, y, other.x, other.y)
        return DoubleVector2.new(res[0], res[1])
    return DoubleVector2.new(
        x * other.x - y * other.y,
        x * other.y + y * other.x
    )

func complex_div(other: DoubleVector2) -> DoubleVector2:
    if ClassDB.class_exists("ComplexFunctions"):
        var ext = ClassDB.instantiate("ComplexFunctions")
        var res = ext.call("complex_div", x, y, other.x, other.y)
        return DoubleVector2.new(res[0], res[1])
    var denom = other.x * other.x + other.y * other.y + 1e-24
    return DoubleVector2.new(
        (x * other.x + y * other.y) / denom,
        (y * other.x - x * other.y) / denom
    )

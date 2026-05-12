# Shared field and height functions for GDScript
class_name Field

static var iterations: int = 120
static var compute_normals: bool = false
static var function_type: int = 0 # 0: Zeta, 1: Sin, 2: Cos, 3: Exp, 4: Log
static var height_type: int = 0 # 0: Log, 1: Abs

static func complex_mul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(
		a.x * b.x - a.y * b.y,
		a.x * b.y + a.y * b.x
	)


static func complex_div(a: Vector2, b: Vector2) -> Vector2:

	var denom = b.x * b.x + b.y * b.y

	if denom == 0.0:
		return Vector2.ZERO

	return Vector2(
		(a.x * b.x + a.y * b.y) / denom,
		(a.y * b.x - a.x * b.y) / denom
	)


static func zeta(sigma: float, t: float) -> Vector2:

	#----------------------------------------
	# STEP 1: Compute eta(s)
	#----------------------------------------

	var eta = Vector2.ZERO

	for n in range(1, iterations + 1):

		var nf = float(n)

		# amplitude = n^{-sigma}
		var amp = pow(nf, -sigma)
		
		if (amp < 1e-6):
			break

		# phase = -t log n
		var theta = -t * log(nf)

		# alternating sign
		var _sign = 1.0 if (n % 2 == 1) else -1.0

		# term = sign * n^{-s}
		eta += _sign * amp * Vector2(
			cos(theta),
			sin(theta)
		)

	#----------------------------------------
	# STEP 2: Compute denominator
	#
	# d = 1 - 2^{1-s}
	#----------------------------------------

	var amp2 = pow(2.0, 1.0 - sigma)

	var theta2 = -t * log(2.0)

	var two_term = amp2 * Vector2(
		cos(theta2),
		sin(theta2)
	)

	var denom = Vector2(1.0, 0.0) - two_term

	#----------------------------------------
	# STEP 3: zeta = eta / denom
	#----------------------------------------

	return complex_div(eta, denom)

static func complex_sin(sigma: float, t: float) -> Vector2:
	return Vector2(
		sin(sigma) * cosh(t),
		cos(sigma) * sinh(t)
	)

static func complex_cos(sigma: float, t: float) -> Vector2:
	return Vector2(
		cos(sigma) * cosh(t),
		-sin(sigma) * sinh(t)
	)

static func complex_exp(sigma: float, t: float) -> Vector2:
	var amp = exp(sigma)
	return Vector2(
		amp * cos(t),
		amp * sin(t)
	)

static func complex_log(sigma: float, t: float) -> Vector2:
	# Principal branch
	var mag = sqrt(sigma * sigma + t * t)
	if mag < 1e-9:
		return Vector2(-10.0, 0.0) # avoid singularity
	return Vector2(
		log(mag),
		atan2(t, sigma)
	)

static func get_field(x: float, z: float) -> Vector2:
	var sigma: float = x * 0.1
	var t: float = -z * 0.1

	if function_type == 0:
		return zeta(sigma, t)
	elif function_type == 1:
		return complex_sin(sigma, t)
	elif function_type == 2:
		return complex_cos(sigma, t)
	elif function_type == 3:
		return complex_exp(sigma, t)
	elif function_type == 4:
		return complex_log(sigma, t)

	return Vector2.ZERO

static func get_height(x: float, z: float) -> float:
	var f = get_field(x, z)
	var mag = f.length()

	if height_type == 0:
		return 3.0 * log(1.0 + mag)
	else:
		return mag

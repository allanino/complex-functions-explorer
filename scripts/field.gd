# Shared field and height functions for GDScript
class_name Field

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

	for n in range(1, 121):

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

static func get_field(x: float, z: float) -> Vector2:
	#if x <= 0.0:
		#return Vector2.ZERO
	
	var sigma: float = x * 0.1
	# We reverse z to get the usual Re, Im axis orientation
	# It looks like godot puts the z axis downwards
	var t: float = -z * 0.1

	return zeta(sigma, t)

static func get_height(x: float, z: float) -> float:
	var f = get_field(x, z)
	return 3.0 * log(1.0 + f.length())

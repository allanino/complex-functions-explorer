# Shared field and height functions for GDScript
class_name Field

static var iterations: int = 300
static var terrain_detail: int = 1
static var antialiasing_mode: int = 1
static var show_curves: bool = true
static var show_critical_stripe: bool = true
static var golden_hour: bool = false
static var day_night_cycle: bool = false
static var shadows_enabled: bool = false
static var function_type: int = 0 # 0: Zeta, 1: Gamma, 2: Dedekind Eta, 3: Sin, 4: Cos, 5: Tan, 6: Exp, 7: Log, 8: Rational
static var view_distance: int = 7
static var height_type: int = 0 # 0: Log, 1: Abs
static var height_a: float = 3.0
static var height_epsilon: float = 1.0
static var movement_speed: float = 10.0
static var speed_near_zeros: float = 100.0
static var zero_threshold: float = 0.5
static var camera_height: float = 1.8
static var show_hud_complex: bool = true
static var show_hud_navigation: bool = true
static var show_hud_zeros: bool = true
static var show_rvm: bool = true
static var bg_music_volume: float = 100.0
static var drone_volume: float = 100.0

static var visited_zeros: Array[float] = []

static var rational_num_coeffs: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
static var rational_den_coeffs: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

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

const LANCZOS_P = [
	0.99999999999980993,
	676.5203681218851,
	-1259.1392167224028,
	771.32342877765313,
	-176.61502916214059,
	12.507343278686905,
	-0.13857109526572012,
	9.9843695780195716e-6,
	1.5056327351493116e-7
]
const SQRT_2PI = 2.5066282746310005

static func complex_pow(z: Vector2, w: Vector2) -> Vector2:
	var lz = complex_log(z.x, z.y)
	var res_log = complex_mul(w, lz)
	return complex_exp(res_log.x, res_log.y)

static func lanczos_gamma(z_orig: Vector2) -> Vector2:
	var z = z_orig - Vector2(1.0, 0.0)
	var x = Vector2(LANCZOS_P[0], 0.0)
	for i in range(1, 9):
		x += complex_div(Vector2(LANCZOS_P[i], 0.0), z + Vector2(float(i), 0.0))

	var tmp = z + Vector2(7.5, 0.0)
	var p = complex_pow(tmp, z + Vector2(0.5, 0.0))
	var etmp = complex_exp(-tmp.x, -tmp.y)

	return SQRT_2PI * complex_mul(complex_mul(p, etmp), x)

static func complex_gamma(sigma: float, t: float) -> Vector2:
	if sigma < 0.5:
		var z = Vector2(sigma, t)
		var sin_pi_z = complex_sin(PI * sigma, PI * t)
		var g1z = lanczos_gamma(Vector2(1.0 - sigma, -t))
		return complex_div(Vector2(PI, 0.0), complex_mul(sin_pi_z, g1z))
	return lanczos_gamma(Vector2(sigma, t))

static func dedekind_eta(sigma: float, t: float) -> Vector2:
	# eta(tau) = exp(pi * i * tau / 12) * product_{n=1}^inf (1 - exp(2 * pi * i * n * tau))
	# Let tau = sigma + i*t
	# pi * i * tau / 12 = pi * i * (sigma + i*t) / 12 = (-pi * t / 12) + i * (pi * sigma / 12)
	var factor = complex_exp(-PI * t / 12.0, PI * sigma / 12.0)

	var prod = Vector2(1.0, 0.0)
	var q_re_base = -2.0 * PI * t
	var q_im_base = 2.0 * PI * sigma

	for n in range(1, iterations + 1):
		var nf = float(n)
		var term_exp = complex_exp(nf * q_re_base, nf * q_im_base)
		var term = Vector2(1.0, 0.0) - term_exp
		prod = complex_mul(prod, term)

		# Convergence check: if q^n is extremely small, 1-q^n is basically 1
		if nf > 10 and term_exp.length() < 1e-12:
			break

	return complex_mul(factor, prod)

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

static func complex_tan(sigma: float, t: float) -> Vector2:
	return complex_div(complex_sin(sigma, t), complex_cos(sigma, t))

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

static func evaluate_poly(sigma: float, t: float, coeffs: PackedFloat32Array) -> Vector2:
	var z = Vector2(sigma, t)
	var res = Vector2.ZERO
	var z_pow = Vector2(1.0, 0.0)

	for i in range(10):
		res += coeffs[i] * z_pow
		z_pow = complex_mul(z_pow, z)

	return res

static func get_rational(sigma: float, t: float) -> Vector2:
	var num = evaluate_poly(sigma, t, rational_num_coeffs)
	var den = evaluate_poly(sigma, t, rational_den_coeffs)
	return complex_div(num, den)

static func get_field(x: float, z: float) -> Vector2:
	var sigma: float = x * 0.1
	var t: float = -z * 0.1

	if function_type == 0:
		return zeta(sigma, t)
	elif function_type == 1:
		return complex_gamma(sigma, t)
	elif function_type == 2:
		return dedekind_eta(sigma, t)
	elif function_type == 3:
		return complex_sin(sigma, t)
	elif function_type == 4:
		return complex_cos(sigma, t)
	elif function_type == 5:
		return complex_tan(sigma, t)
	elif function_type == 6:
		return complex_exp(sigma, t)
	elif function_type == 7:
		return complex_log(sigma, t)
	elif function_type == 8:
		return get_rational(sigma, t)

	return Vector2.ZERO

static func get_height(x: float, z: float) -> float:
	var f = get_field(x, z)
	if not is_finite(f.x) or not is_finite(f.y):
		return 0.0

	var mag = f.length()
	if not is_finite(mag):
		return 0.0

	var h: float
	if height_type == 0:
		h = height_a * log(height_epsilon + mag)
	else:
		h = mag

	return h if is_finite(h) else 0.0

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
static var function_type: int = 0 # 0: Zeta, 1: Zeta continuation, 2: Gamma, 3: Log Gamma, 4: Dedekind Eta, 5: Sin, 6: Cos, 7: Tan, 8: Exp, 9: Log, 10: Rational
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

#-------------------------------------------------------------------------
# Complex Arithmetic
#-------------------------------------------------------------------------

static func complex_mul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(
		a.x * b.x - a.y * b.y,
		a.x * b.y + a.y * b.x
	)

static func complex_div(a: Vector2, b: Vector2) -> Vector2:
	var denom = b.x * b.x + b.y * b.y
	if denom == 0.0: return Vector2.ZERO
	return Vector2(
		(a.x * b.x + a.y * b.y) / denom,
		(a.y * b.x - a.x * b.y) / denom
	)

static func complex_exp(sigma: float, t: float) -> Vector2:
	var amp = exp(sigma)
	return Vector2(amp * cos(t), amp * sin(t))

static func complex_log(sigma: float, t: float) -> Vector2:
	var mag = sqrt(sigma * sigma + t * t)
	if mag < 1e-9: return Vector2(-10.0, 0.0)
	return Vector2(log(mag), atan2(t, sigma))

static func complex_pow(z: Vector2, w: Vector2) -> Vector2:
	var lz = complex_log(z.x, z.y)
	var res_log = complex_mul(w, lz)
	return complex_exp(res_log.x, res_log.y)

static func complex_sin(sigma: float, t: float) -> Vector2:
	return Vector2(sin(sigma) * cosh(t), cos(sigma) * sinh(t))

static func complex_cos(sigma: float, t: float) -> Vector2:
	return Vector2(cos(sigma) * cosh(t), -sin(sigma) * sinh(t))

static func complex_tan(sigma: float, t: float) -> Vector2:
	return complex_div(complex_sin(sigma, t), complex_cos(sigma, t))

#-------------------------------------------------------------------------
# Component Functions: Zeta, Gamma, Dedekind Eta
#-------------------------------------------------------------------------

static func zeta(sigma: float, t: float) -> Vector2:
	var eta = Vector2.ZERO
	for n in range(1, iterations + 1):
		var nf = float(n)
		var amp = pow(nf, -sigma)
		if amp < 1e-6: break
		var theta = -t * log(nf)
		var _sign = 1.0 if (n % 2 == 1) else -1.0
		eta += _sign * amp * Vector2(cos(theta), sin(theta))
	var amp2 = pow(2.0, 1.0 - sigma)
	var theta2 = -t * log(2.0)
	var two_term = amp2 * Vector2(cos(theta2), sin(theta2))
	var denom = Vector2(1.0, 0.0) - two_term
	return complex_div(eta, denom)

const LANCZOS_P = [
	1.000000000000000174663,
	5716.400188274341379136,
	-14815.30426768413909044,
	14291.49277657478554025,
	-6348.160217641458813289,
	1301.608286058321874105,
	-108.1767053514369634679,
	2.605696505611755827729,
	0.7423452510201416151527e-2,
	0.5384136432509564062961e-7,
	-0.4023533141268236372067e-8
]
const SQRT_2PI = 2.5066282746310005

static func lanczos_gamma(z_orig: Vector2) -> Vector2:
	var z = z_orig - Vector2(1.0, 0.0)
	var x = Vector2(LANCZOS_P[0], 0.0)
	for i in range(1, 11):
		x += complex_div(Vector2(LANCZOS_P[i], 0.0), z + Vector2(float(i), 0.0))
	var tmp = z + Vector2(9.5, 0.0)
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

static func zeta_continuation(sigma: float, t: float) -> Vector2:
	if sigma >= 0.5: return zeta(sigma, t)
	var s = Vector2(sigma, t)
	var s1 = Vector2(1.0 - sigma, -t)

	var log_sum = (complex_mul(s, Vector2(log(2.0), 0.0))
				+ complex_mul(s - Vector2(1.0, 0.0), Vector2(log(PI), 0.0)))

	var pi_s_2 = (PI * 0.5) * s
	var sin_part = complex_sin(pi_s_2.x, pi_s_2.y)
	log_sum += complex_log(sin_part.x, sin_part.y)

	log_sum += complex_log_gamma(s1.x, s1.y)

	var zeta_part = zeta(s1.x, s1.y)
	log_sum += complex_log(zeta_part.x, zeta_part.y)

	return complex_exp(log_sum.x, log_sum.y)

static func lanczos_log_gamma(z: Vector2) -> Vector2:
	var z_m1 = z - Vector2(1.0, 0.0)
	var x = Vector2(LANCZOS_P[0], 0.0)
	for i in range(1, 11):
		x += complex_div(Vector2(LANCZOS_P[i], 0.0), z_m1 + Vector2(float(i), 0.0))
	var tmp = z_m1 + Vector2(9.5, 0.0)
	var res = (Vector2(log(SQRT_2PI), 0.0)
		+ complex_mul(z - Vector2(0.5, 0.0), complex_log(tmp.x, tmp.y))
		- tmp
		+ complex_log(x.x, x.y))
	res.y = posmod(res.y + PI, TAU) - PI
	return res

static func complex_log_gamma(sigma: float, t: float) -> Vector2:
	var res: Vector2
	if sigma < 0.5:
		var pi_z = Vector2(PI * sigma, PI * t)
		var s = complex_sin(pi_z.x, pi_z.y)
		res = Vector2(log(PI), 0.0) - complex_log(s.x, s.y) - lanczos_log_gamma(Vector2(1.0 - sigma, -t))
	else:
		res = lanczos_log_gamma(Vector2(sigma, t))
	res.y = posmod(res.y + PI, TAU) - PI
	return res

static func dedekind_eta(sigma: float, t: float) -> Vector2:
	var factor = complex_exp(-PI * t / 12.0, PI * sigma / 12.0)
	var prod = Vector2(1.0, 0.0)
	var q_re_base = -2.0 * PI * t
	var q_im_base = 2.0 * PI * sigma
	for n in range(1, iterations + 1):
		var nf = float(n)
		var term_exp = complex_exp(nf * q_re_base, nf * q_im_base)
		var term = Vector2(1.0, 0.0) - term_exp
		prod = complex_mul(prod, term)
		if nf > 10 and term_exp.length() < 1e-12: break
	return complex_mul(factor, prod)

#-------------------------------------------------------------------------
# Rational Functions
#-------------------------------------------------------------------------

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

#-------------------------------------------------------------------------
# Dispatchers
#-------------------------------------------------------------------------

static func get_field(x: float, z: float) -> Vector2:
	var sigma: float = x * 0.1
	var t: float = -z * 0.1
	if function_type == 0: return zeta(sigma, t)
	elif function_type == 1: return zeta_continuation(sigma, t)
	elif function_type == 2: return complex_gamma(sigma, t)
	elif function_type == 3: return complex_log_gamma(sigma, t)
	elif function_type == 4: return dedekind_eta(sigma, t)
	elif function_type == 5: return complex_sin(sigma, t)
	elif function_type == 6: return complex_cos(sigma, t)
	elif function_type == 7: return complex_tan(sigma, t)
	elif function_type == 8: return complex_exp(sigma, t)
	elif function_type == 9: return complex_log(sigma, t)
	elif function_type == 10: return get_rational(sigma, t)
	return Vector2.ZERO

static func get_height(x: float, z: float) -> float:
	var f = get_field(x, z)
	if not is_finite(f.x) or not is_finite(f.y): return 0.0
	var mag = f.length()
	if not is_finite(mag): return 0.0
	var h: float
	if height_type == 0: h = height_a * log(height_epsilon + mag)
	else: h = mag
	return h if is_finite(h) else 0.0

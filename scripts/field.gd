# Shared field and height functions for GDScript
class_name Field

static var iterations: int = 2200
static var terrain_detail: int = 1
static var antialiasing_mode: int = 1
static var show_curves: bool = true
static var show_critical_stripe: bool = true
static var debug_view_texture: bool = false
static var golden_hour: bool = false
static var day_night_cycle: bool = true
static var shadows_enabled: bool = false
static var function_type: int = 0
# 0: Zeta, 1: Zeta Continuation, 2: Gamma, 3: Log Gamma, 4: Dedekind Eta, 5: Sin, 6: Cos, 7: Tan, 8: Exp, 9: Log, 10: Rational
static var view_distance: int = 8
static var height_type: int = 1 # 0: Log, 1: Abs
static var height_a: float = 3.0
static var height_epsilon: float = 1.0
static var movement_speed: float = 10.0
static var speed_near_zeros: float = 50.0
static var zero_threshold: float = 0.5
static var camera_height: float = 3.5
static var show_hud_complex: bool = true
static var show_hud_navigation: bool = true
static var show_hud_zeros: bool = true
static var show_rvm: bool = true
static var bg_music_volume: float = 50.0
static var drone_volume: float = 80.0

static var visited_zeros: Array[float] = []

static var rational_num_coeffs: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
static var rational_den_coeffs: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

static func complex_mul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x)

static func complex_div(a: Vector2, b: Vector2) -> Vector2:
	var denom = b.x * b.x + b.y * b.y
	if denom == 0.0: return Vector2.ZERO
	return Vector2((a.x * b.x + a.y * b.y) / denom, (a.y * b.x - a.x * b.y) / denom)

static func complex_exp(z: Vector2) -> Vector2:
	var amp = exp(z.x)
	return Vector2(amp * cos(z.y), amp * sin(z.y))

static func complex_log(z: Vector2) -> Vector2:
	var mag = z.length()
	if mag < 1e-12: return Vector2(-30.0, 0.0)
	return Vector2(log(mag), atan2(z.y, z.x))

static func complex_pow(base: Vector2, exponent: Vector2) -> Vector2:
	return complex_exp(complex_mul(complex_log(base), exponent))

static func complex_sin(z: Vector2) -> Vector2:
	return Vector2(sin(z.x) * cosh(z.y), cos(z.x) * sinh(z.y))

static func complex_cos(z: Vector2) -> Vector2:
	return Vector2(cos(z.x) * cosh(z.y), -sin(z.x) * sinh(z.y))

static func complex_gamma(z: Vector2) -> Vector2:
	if z.x < 0.5:
		# pi / (sin(pi*z) * Gamma(1-z))
		var pi_z = PI * z
		var sin_pi_z = complex_sin(pi_z)
		var g_1z = complex_gamma(Vector2(1.0, 0.0) - z)
		return complex_div(Vector2(PI, 0.0), complex_mul(sin_pi_z, g_1z))

	var zh = z - Vector2(0.5, 0.0)
	var z_plus_g_plus_h = z + Vector2(8.5, 0.0) # Using g=9 for Lanczos
	var ag = Vector2(0.99999999999980993, 0.0)
	var l_coeffs = [676.5203681218851, -1259.1392167224028, 771.32342877765313, -176.61502916214059, 12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7]
	for i in range(len(l_coeffs)):
		ag += complex_div(Vector2(l_coeffs[i], 0.0), z + Vector2(i + 1, 0.0))

	var term = complex_mul(Vector2(sqrt(2.0 * PI), 0.0), complex_mul(complex_pow(z_plus_g_plus_h, zh), complex_mul(complex_exp(-z_plus_g_plus_h), ag)))
	return term

static func zeta(sigma: float, t: float) -> Vector2:
	var eta = Vector2.ZERO
	for n in range(1, iterations + 1):
		var nf = float(n)
		var amp = pow(nf, -sigma)
		if amp < 1e-7: break
		var theta = -t * log(nf)
		var _sign = 1.0 if (n % 2 == 1) else -1.0
		eta += _sign * amp * Vector2(cos(theta), sin(theta))
	var denom = Vector2(1.0, 0.0) - complex_exp(Vector2((1.0 - sigma) * log(2.0), -t * log(2.0)))
	return complex_div(eta, denom)

static func zeta_continuation(sigma: float, t: float) -> Vector2:
	if sigma >= 0.5: return zeta(sigma, t)
	var s = Vector2(sigma, t)
	# 2^s * pi^(s-1) * sin(pi*s/2) * Gamma(1-s) * zeta(1-s)
	var term1 = complex_pow(Vector2(2.0, 0.0), s)
	var term2 = complex_pow(Vector2(PI, 0.0), s - Vector2(1.0, 0.0))
	var term3 = complex_sin(PI * s * 0.5)
	var term4 = complex_gamma(Vector2(1.0, 0.0) - s)
	var term5 = zeta(1.0 - sigma, -t)
	return complex_mul(complex_mul(term1, term2), complex_mul(term3, complex_mul(term4, term5)))

static func dedekind_eta(sigma: float, t: float) -> Vector2:
	var factor = complex_exp(Vector2(-PI * t / 12.0, PI * sigma / 12.0))
	var prod = Vector2(1.0, 0.0)
	for n in range(1, iterations + 1):
		var nf = float(n)
		var q_n = complex_exp(Vector2(-2.0 * PI * nf * t, 2.0 * PI * nf * sigma))
		prod = complex_mul(prod, Vector2(1.0, 0.0) - q_n)
		if nf > 10 and q_n.length() < 1e-12: break
	return complex_mul(factor, prod)

static func get_field(x: float, z: float) -> Vector2:
	var sigma = x * 0.1
	var t = -z * 0.1
	var s = Vector2(sigma, t)
	match function_type:
		0: return zeta(sigma, t)
		1: return zeta_continuation(sigma, t)
		2: return complex_gamma(s)
		3: return complex_log(complex_gamma(s))
		4: return dedekind_eta(sigma, t)
		5: return complex_sin(s)
		6: return complex_cos(s)
		7: return complex_div(complex_sin(s), complex_cos(s))
		8: return complex_exp(s)
		9: return complex_log(s)
		10:
			var num = Vector2.ZERO; var den = Vector2.ZERO; var zp = Vector2(1, 0)
			for i in range(10):
				num += rational_num_coeffs[i] * zp; den += rational_den_coeffs[i] * zp
				zp = complex_mul(zp, s)
			return complex_div(num, den)
	return Vector2.ZERO

static func get_height(x: float, z: float) -> float:
	var f = get_field(x, z)
	if not is_finite(f.x) or not is_finite(f.y): return 0.0
	var mag = f.length()
	if height_type == 0: return height_a * log(height_epsilon + mag)
	return mag

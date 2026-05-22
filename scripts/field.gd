# Shared field and height functions for GDScript
class_name Field

#-------------------------------------------------------------------------
# Complex Arithmetic
#-------------------------------------------------------------------------

static func complex_mul(a: Vector2, b: Vector2) -> Vector2:
	return Vector2(
		a.x * b.x - a.y * b.y,
		a.x * b.y + a.y * b.x
	)

static func complex_div(a: Vector2, b: Vector2) -> Vector2:
	var denom = b.x * b.x + b.y * b.y + 1e-24
	return Vector2(
		(a.x * b.x + a.y * b.y) / denom,
		(a.y * b.x - a.x * b.y) / denom
	)

static func complex_exp(sigma: float, t: float) -> Vector2:
	var amp = exp(sigma)
	return Vector2(amp * cos(t), amp * sin(t))

static func complex_log(sigma: float, t: float) -> Vector2:
	var mag_sq = sigma * sigma + t * t
	if mag_sq < 1e-48: return Vector2(-60.0, 0.0)
	return Vector2(0.5 * log(mag_sq), atan2(t, sigma))

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
# Component Functions: Zeta, Eta, Gamma, Dedekind Eta
#-------------------------------------------------------------------------

const LOG_2 = 0.6931471805599453
const LOG_PI = 1.1447298858494002

static func dirichlet_eta(sigma: float, t: float, iterations: int) -> Vector2:
	if iterations <= 0: return Vector2.ZERO
	var eta = Vector2.ZERO
	for n in range(1, iterations + 1):
		var nf = float(n)
		var amp = pow(nf, -sigma)
		if amp < 1e-6: break
		var theta = -t * log(nf)
		var _sign = 1.0 if (n % 2 == 1) else -1.0
		eta += _sign * amp * Vector2(cos(theta), sin(theta))
	return eta

static func dirichlet_beta(sigma: float, t: float, iterations: int) -> Vector2:
	if iterations <= 0: return Vector2.ZERO
	var beta = Vector2.ZERO
	for n in range(iterations):
		var k = 2.0 * float(n) + 1.0
		var amp = pow(k, -sigma)
		if amp < 1e-6: break
		var theta = -t * log(k)
		var _sign = 1.0 if (n % 2 == 0) else -1.0
		beta += _sign * amp * Vector2(cos(theta), sin(theta))
	return beta

static func zeta(sigma: float, t: float) -> Vector2:
	var iterations = Config.iterations
	var eta = dirichlet_eta(sigma, t, iterations)

	var amp2 = pow(2.0, 1.0 - sigma)
	var theta2 = -t * LOG_2
	var two_term = amp2 * Vector2(cos(theta2), sin(theta2))
	var denom = Vector2(1.0, 0.0) - two_term
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

static func zeta_continuation(sigma: float, t: float) -> Vector2:
	if sigma >= 0.5: return zeta(sigma, t)
	var s = Vector2(sigma, t)
	var s1 = Vector2(1.0 - sigma, -t)

	var log_sum = (complex_mul(s, Vector2(LOG_2, 0.0))
				+ complex_mul(s - Vector2(1.0, 0.0), Vector2(LOG_PI, 0.0)))

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
	for i in range(1, 9):
		x += complex_div(Vector2(LANCZOS_P[i], 0.0), z_m1 + Vector2(float(i), 0.0))
	var tmp = z_m1 + Vector2(7.5, 0.0)
	var res = (Vector2(log(SQRT_2PI), 0.0)
		+ complex_mul(z - Vector2(0.5, 0.0), complex_log(tmp.x, tmp.y))
		- tmp
		+ complex_log(x.x, x.y))
	return res

static func complex_log_gamma(sigma: float, t: float) -> Vector2:
	var res: Vector2
	if sigma < 0.5:
		var pi_z = Vector2(PI * sigma, PI * t)
		var s = complex_sin(pi_z.x, pi_z.y)
		res = Vector2(log(PI), 0.0) - complex_log(s.x, s.y) - lanczos_log_gamma(Vector2(1.0 - sigma, -t))
	else:
		res = lanczos_log_gamma(Vector2(sigma, t))
	return res

static func dedekind_eta(sigma: float, t: float) -> Vector2:
	var factor = complex_exp(-PI * t / 12.0, PI * sigma / 12.0)
	var prod = Vector2(1.0, 0.0)
	var q_re_base = -2.0 * PI * t
	var q_im_base = 2.0 * PI * sigma
	var iterations = Config.iterations
	for n in range(1, iterations + 1):
		var nf = float(n)
		var term_exp = complex_exp(nf * q_re_base, nf * q_im_base)
		var term = Vector2(1.0, 0.0) - term_exp
		prod = complex_mul(prod, term)
		if nf > 10 and term_exp.length() < 1e-12: break
	return complex_mul(factor, prod)

static func mandelbrot(sigma: float, t: float, iterations: int) -> Vector2:
	var c = Vector2(sigma, t)
	var z = Vector2.ZERO
	for i in range(iterations):
		z = complex_mul(z, z) + c
		if z.length_squared() > 100.0: break
	return z

#-------------------------------------------------------------------------
# Rational Functions
#-------------------------------------------------------------------------

static func evaluate_poly(sigma: float, t: float, coeffs: PackedFloat32Array) -> Vector2:
	var z = Vector2(sigma, t)
	var res = Vector2.ZERO
	# Horner's method for polynomial evaluation
	for i in range(9, -1, -1):
		res = complex_mul(res, z) + Vector2(coeffs[i], 0.0)
	return res

static func get_rational(sigma: float, t: float) -> Vector2:
	var num = evaluate_poly(sigma, t, Config.rational_num_coeffs)
	var den = evaluate_poly(sigma, t, Config.rational_den_coeffs)
	return complex_div(num, den)

static func multivalued_z_pow_inv_n(sigma: float, t: float, n: int, cycle_speed: float) -> Vector2:
	var r = sqrt(sigma * sigma + t * t)
	var theta = atan2(t, sigma)
	if theta < 0.0: theta += 2.0 * PI
	var float_n = float(n)

	var time = Config.branch_time
	var progress = fmod(time * cycle_speed, 1.0) * float_n
	var k_current = floor(progress)
	var t_in_branch = progress - k_current

	# Non-linear transition: stay on branch, then morph
	var morph_time = Config.multivalued_morph_time
	var transition_fraction = clamp(morph_time * float_n * cycle_speed, 0.0, 1.0)
	var transition_threshold = 1.0 - transition_fraction
	var blend_factor = 0.0
	if transition_threshold < 1.0:
		blend_factor = smoothstep(transition_threshold, 1.0, t_in_branch)
	else:
		blend_factor = 1.0 if t_in_branch >= 1.0 else 0.0

	var morphed_phase = (theta + 2.0 * PI * (k_current + blend_factor)) / float_n
	var morphed_r = pow(r, 1.0 / float_n)
	return Vector2(morphed_r * cos(morphed_phase), morphed_r * sin(morphed_phase))

static func smoothstep(edge0: float, edge1: float, x: float) -> float:
	x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

#-------------------------------------------------------------------------
# Dispatchers
#-------------------------------------------------------------------------

static func get_field(x: float, z: float) -> Vector2:
	if Config.performance_protection_active:
		return Vector2.ZERO

	var zoom: float = 1.0 / Config.effective_zoom
	var sigma: float = x * 0.1 * zoom
	var t: float = -z * 0.1 * zoom
	var function_type = Config.function_type
	if function_type == 0: return zeta(sigma, t)
	elif function_type == 1: return zeta_continuation(sigma, t)
	elif function_type == 2: return dirichlet_eta(sigma, t, Config.iterations)
	elif function_type == 3: return dirichlet_beta(sigma, t, Config.iterations)
	elif function_type == 4: return complex_gamma(sigma, t)
	elif function_type == 5: return complex_log_gamma(sigma, t)
	elif function_type == 6: return dedekind_eta(sigma, t)
	elif function_type == 7: return mandelbrot(sigma, t, Config.iterations)
	elif function_type == 8: return complex_sin(sigma, t)
	elif function_type == 9: return complex_cos(sigma, t)
	elif function_type == 10: return complex_tan(sigma, t)
	elif function_type == 11: return complex_exp(sigma, t)
	elif function_type == 12: return complex_log(sigma, t)
	elif function_type == 13: return get_rational(sigma, t)
	elif function_type == 14: return multivalued_z_pow_inv_n(sigma, t, Config.multivalued_n, Config.branch_cycle_speed)
	return Vector2.ZERO

static func get_height_from_field(f: Vector2) -> float:
	if not is_finite(f.x) or not is_finite(f.y): return 0.0
	var mag = f.length()
	if not is_finite(mag): return 0.0
	var h: float
	if Config.height_type == 0: h = Config.height_a * log(Config.height_epsilon + mag)
	else: h = mag
	return h if is_finite(h) else 0.0

static func get_height(x: float, z: float) -> float:
	if Config.performance_protection_active:
		return 0.0

	var f = get_field(x, z)
	return get_height_from_field(f)

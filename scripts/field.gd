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

static func complex_exp(z: Vector2) -> Vector2:
	var amp = exp(z.x)
	return Vector2(amp * cos(z.y), amp * sin(z.y))

static func complex_log(z: Vector2) -> Vector2:
	var mag_sq = z.x * z.x + z.y * z.y
	if mag_sq < 1e-48: return Vector2(-60.0, 0.0)
	return Vector2(0.5 * log(mag_sq), atan2(z.y, z.x))

static func complex_pow(z: Vector2, w: Vector2) -> Vector2:
	var lz = complex_log(z)
	var res_log = complex_mul(w, lz)
	return complex_exp(res_log)

static func complex_sin(z: Vector2) -> Vector2:
	return Vector2(sin(z.x) * cosh(z.y), cos(z.x) * sinh(z.y))

static func complex_cos(z: Vector2) -> Vector2:
	return Vector2(cos(z.x) * cosh(z.y), -sin(z.x) * sinh(z.y))

static func complex_tan(z: Vector2) -> Vector2:
	var abs_2y = 2.0 * abs(z.y)
	var exp_neg = exp(-abs_2y)
	var scaled_cosh = 0.5 * (1.0 + exp_neg * exp_neg)
	var scaled_sinh = 0.5 * (1.0 - exp_neg * exp_neg) * (1.0 if z.y >= 0.0 else -1.0)
	var scaled_sin_2x = sin(2.0 * z.x) * exp_neg
	var scaled_cos_2x = cos(2.0 * z.x) * exp_neg
	var denom = scaled_cosh + scaled_cos_2x
	return Vector2(scaled_sin_2x / denom, scaled_sinh / denom)

static func complex_cot(z: Vector2) -> Vector2:
	var abs_2y = 2.0 * abs(z.y)
	var exp_neg = exp(-abs_2y)
	var scaled_cosh = 0.5 * (1.0 + exp_neg * exp_neg)
	var scaled_sinh = 0.5 * (1.0 - exp_neg * exp_neg) * (1.0 if z.y >= 0.0 else -1.0)
	var scaled_sin_2x = sin(2.0 * z.x) * exp_neg
	var scaled_cos_2x = cos(2.0 * z.x) * exp_neg
	var denom = scaled_cosh - scaled_cos_2x
	return Vector2(scaled_sin_2x / denom, -scaled_sinh / denom)

static func complex_log_sin(z: Vector2) -> Vector2:
	var abs_y = abs(z.y)
	var log_scale = abs_y - log(2.0)
	var e_neg2 = exp(-2.0 * abs_y)
	var internal_z = Vector2(
		sin(z.x) * (1.0 + e_neg2),
		(1.0 if z.y >= 0.0 else -1.0) * cos(z.x) * (1.0 - e_neg2)
	)
	var log_internal = complex_log(internal_z)
	return Vector2(log_scale + log_internal.x, log_internal.y)

#-------------------------------------------------------------------------
# Component Functions: Zeta, Eta, Gamma, Dedekind Eta
#-------------------------------------------------------------------------

const LOG_2 = 0.6931471805599453
const LOG_PI = 1.1447298858494002

static func dirichlet_eta(z: Vector2, iterations: int) -> Vector2:
	if iterations <= 0: return Vector2.ZERO
	var eta = Vector2.ZERO
	for n in range(1, iterations + 1, 2):
		var nf = float(n)
		var amp = pow(nf, -z.x)
		var log_n = log(nf)
		var theta = -z.y * log_n
		eta += amp * Vector2(cos(theta), sin(theta))

		var nf2 = float(n + 1)
		var amp2 = pow(nf2, -z.x)
		var theta2 = -z.y * log(nf2)
		eta -= amp2 * Vector2(cos(theta2), sin(theta2))

		if (amp < 1e-6 || amp2 < 1e-6 || amp > 1e6 || amp2 > 1e6): break
	return eta

static func dirichlet_beta(z: Vector2, iterations: int) -> Vector2:
	if iterations <= 0: return Vector2.ZERO
	var beta = Vector2.ZERO
	for n in range(0, iterations, 2):
		var kf = 2.0 * float(n) + 1.0
		var amp = pow(kf, -z.x)
		var theta = -z.y * log(kf)
		beta += amp * Vector2(cos(theta), sin(theta))

		var kf2 = 2.0 * float(n + 1) + 1.0
		var amp2 = pow(kf2, -z.x)
		var theta2 = -z.y * log(kf2)
		beta -= amp2 * Vector2(cos(theta2), sin(theta2))

		if (amp < 1e-6 || amp2 < 1e-6 || amp > 1e6 || amp2 > 1e6): break
	return beta

static func zeta(z: Vector2) -> Vector2:
	var iterations = Config.iterations
	var eta = dirichlet_eta(z, iterations)

	var amp2 = pow(2.0, 1.0 - z.x)
	var theta2 = -z.y * LOG_2
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
	var etmp = complex_exp(-tmp)
	return SQRT_2PI * complex_mul(complex_mul(p, etmp), x)

static func complex_gamma(z: Vector2) -> Vector2:
	if z.x < 0.5:
		var log_sin_pi_z = complex_log_sin(PI * z)
		var lg1z = complex_log_gamma(Vector2(1.0 - z.x, -z.y))
		var log_sum = Vector2(log(PI), 0.0) - log_sin_pi_z - lg1z
		return complex_exp(log_sum)
	return lanczos_gamma(z)

static func log_zeta_continuation(z: Vector2) -> Vector2:
	if z.x >= 0.5:
		var z_val = zeta(z)
		return complex_log(z_val)

	var s = Vector2(z.x, z.y)
	var s1 = Vector2(1.0 - z.x, -z.y)

	var log_sum = (complex_mul(s, Vector2(LOG_2, 0.0))
				+ complex_mul(s - Vector2(1.0, 0.0), Vector2(LOG_PI, 0.0)))

	var pi_s_2 = (PI * 0.5) * s
	log_sum += complex_log_sin(pi_s_2)

	log_sum += complex_log_gamma(s1)

	var zeta_part = zeta(s1)
	log_sum += complex_log(zeta_part)

	return log_sum

static func zeta_continuation(z: Vector2) -> Vector2:
	var log_val = log_zeta_continuation(z)
	return complex_exp(log_val)

static func lanczos_log_gamma(z: Vector2) -> Vector2:
	var z_m1 = z - Vector2(1.0, 0.0)
	var x = Vector2(LANCZOS_P[0], 0.0)
	for i in range(1, 9):
		x += complex_div(Vector2(LANCZOS_P[i], 0.0), z_m1 + Vector2(float(i), 0.0))
	var tmp = z_m1 + Vector2(7.5, 0.0)
	var res = (Vector2(log(SQRT_2PI), 0.0)
		+ complex_mul(z - Vector2(0.5, 0.0), complex_log(tmp))
		- tmp
		+ complex_log(x))
	return res

static func complex_log_gamma(z: Vector2) -> Vector2:
	var res: Vector2
	if z.x < 0.5:
		res = Vector2(log(PI), 0.0) - complex_log_sin(PI * z) - lanczos_log_gamma(Vector2(1.0, 0.0) - z)
	else:
		res = lanczos_log_gamma(z)
	return res

static func dedekind_eta(z: Vector2) -> Vector2:
	var factor = complex_exp(Vector2(-PI * z.y / 12.0, PI * z.x / 12.0))
	var prod = Vector2(1.0, 0.0)
	var q_re_base = -2.0 * PI * z.y
	var q_im_base = 2.0 * PI * z.x
	var iterations = Config.iterations
	for n in range(1, iterations + 1):
		var nf = float(n)
		var term_exp = complex_exp(Vector2(nf * q_re_base, nf * q_im_base))
		var term = Vector2(1.0, 0.0) - term_exp
		prod = complex_mul(prod, term)
		if nf > 10 and term_exp.length() < 1e-12: break
	return complex_mul(factor, prod)

static func mandelbrot(z: Vector2, iterations: int) -> Vector2:
	var c = Vector2(z.x, z.y)
	var z_val = Vector2.ZERO
	for i in range(iterations):
		z_val = complex_mul(z_val, z_val) + c
		if z.length_squared() > 100.0: break
	return z_val

#-------------------------------------------------------------------------
# Rational Functions
#-------------------------------------------------------------------------

static func evaluate_poly(z: Vector2, coeffs: PackedVector2Array) -> Vector2:
	var z_val = Vector2(z.x, z.y)
	var res = Vector2.ZERO
	# Horner's method for polynomial evaluation
	for i in range(9, -1, -1):
		res = complex_mul(res, z_val) + coeffs[i]
	return res

static func get_rational(z: Vector2) -> Vector2:
	var num = evaluate_poly(z, Config.rational_num_coeffs)
	var den = evaluate_poly(z, Config.rational_den_coeffs)
	return complex_div(num, den)

static func xi(z: Vector2) -> Vector2:
	var s = Vector2(z.x, z.y)
	var s_minus_1 = Vector2(z.x - 1.0, z.y)
	var s_half = Vector2(z.x * 0.5, z.y * 0.5)

	var log_sum = Vector2(log(0.5), 0.0)
	log_sum += complex_log(s)
	log_sum += complex_log(s_minus_1)

	log_sum -= complex_mul(s_half, Vector2(LOG_PI, 0.0))
	log_sum += complex_log_gamma(s_half)

	log_sum += log_zeta_continuation(z)

	return complex_exp(log_sum)

static func multivalued_z_pow_inv_n(z: Vector2, n: int, cycle_speed: float) -> Vector2:
	var r = sqrt(z.x * z.x + z.y * z.y)
	var theta = atan2(z.y, z.x)
	if theta < 0.0: theta += 2.0 * PI
	var float_n = float(n)

	var blend_factor = 0.0
	var k_current = 0.0

	if Config.multivalued_mode == 0: # Time cycle
		var time = Config.branch_time
		var progress = fmod(time * cycle_speed, 1.0) * float_n
		k_current = floor(progress)
		var t_in_branch = progress - k_current

		# Non-linear transition: stay on branch, then morph
		var morph_time = Config.multivalued_morph_time
		var transition_fraction = clamp(morph_time * float_n * cycle_speed, 0.0, 1.0)
		var transition_threshold = 1.0 - transition_fraction
		if transition_threshold < 1.0:
			blend_factor = smoothstep(transition_threshold, 1.0, t_in_branch)
		else:
			blend_factor = 1.0 if t_in_branch >= 1.0 else 0.0
	else: # Branch portals
		k_current = float(Config.current_branch)

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
	var z_val: Vector2 = Vector2(sigma, t)

	match Config.function_type:
		Config.ComplexFunc.ZETA: return zeta(z_val)
		Config.ComplexFunc.ZETA_REFLECTION: return zeta_continuation(z_val)
		Config.ComplexFunc.DIRICHLET_ETA: return dirichlet_eta(z_val, Config.iterations)
		Config.ComplexFunc.DIRICHLET_BETA: return dirichlet_beta(z_val, Config.iterations)
		Config.ComplexFunc.GAMMA: return complex_gamma(z_val)
		Config.ComplexFunc.LOG_GAMMA: return complex_log_gamma(z_val)
		Config.ComplexFunc.DEDEKIND_ETA: return dedekind_eta(z_val)
		Config.ComplexFunc.MANDELBROT: return mandelbrot(z_val, Config.iterations)
		Config.ComplexFunc.SIN: return complex_sin(z_val)
		Config.ComplexFunc.COS: return complex_cos(z_val)
		Config.ComplexFunc.TAN: return complex_tan(z_val)
		Config.ComplexFunc.COT: return complex_cot(z_val)
		Config.ComplexFunc.EXP: return complex_exp(z_val)
		Config.ComplexFunc.LOG: return complex_log(z_val)
		Config.ComplexFunc.IDENTITY: return z_val
		Config.ComplexFunc.RATIONAL: return get_rational(z_val)
		Config.ComplexFunc.MULTIVALUED_Z_POW: return multivalued_z_pow_inv_n(z_val, Config.multivalued_n, Config.branch_cycle_speed)

	return Vector2.ZERO

static func get_height_from_field(f: Vector2) -> float:
	if not is_finite(f.x) or not is_finite(f.y): return 0.0
	var mag = f.length()
	if not is_finite(mag): return 0.0
	var h: float
	if Config.height_type == 0: h = Config.height_a * log(Config.height_epsilon + mag)
	else: h = mag

	# Match shader morphing blend factor (usually 1.0)
	var s = 0.5 - 0.5 * cos(PI * Config.morph_value)
	var blend = log(1.0 + 8.0 * s) / log(9.0)
	h *= blend * Config.effective_zoom

	return h if is_finite(h) else 0.0

static func get_height(x: float, z: float) -> float:
	if Config.performance_protection_active:
		return 0.0

	var f = get_field(x, z)
	return get_height_from_field(f)

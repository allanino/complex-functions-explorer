# Shared field and height functions for GDScript
class_name ComplexField

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

static func complex_exp(x: float, y: float) -> Vector2:
	var amp = exp(x)
	return Vector2(amp * cos(y), amp * sin(y))

static func complex_log(x: float, y: float) -> Vector2:
	var mag_sq = x * x + y * y
	if mag_sq < 1e-48: return Vector2(-60.0, 0.0)
	return Vector2(0.5 * log(mag_sq), atan2(y, x))

static func complex_pow(z: Vector2, w: Vector2) -> Vector2:
	var lz = complex_log(z.x, z.y)
	var res_log = complex_mul(w, lz)
	return complex_exp(res_log.x, res_log.y)

static func complex_sin(x: float, y: float) -> Vector2:
	return Vector2(sin(x) * cosh(y), cos(x) * sinh(y))

static func complex_cos(x: float, y: float) -> Vector2:
	return Vector2(cos(x) * cosh(y), -sin(x) * sinh(y))

static func complex_tan(x: float, y: float) -> Vector2:
	var abs_2y = 2.0 * abs(y)
	var exp_neg = exp(-abs_2y)
	var scaled_cosh = 0.5 * (1.0 + exp_neg * exp_neg)
	var scaled_sinh = 0.5 * (1.0 - exp_neg * exp_neg) * (1.0 if y >= 0.0 else -1.0)
	var scaled_sin_2x = sin(2.0 * x) * exp_neg
	var scaled_cos_2x = cos(2.0 * x) * exp_neg
	var denom = scaled_cosh + scaled_cos_2x
	return Vector2(scaled_sin_2x / denom, scaled_sinh / denom)

static func multivalued_asin(x: float, y: float) -> Vector2:
	var z = Vector2(x, y)
	var z2 = complex_mul(z, z)
	var one_minus_z2 = Vector2(1.0 - z2.x, -z2.y)
	
	var B = GameState.current_branch
	var sqrt_branch = abs(B) % 2
	var log_branch = int(floor(float(B + 1) / 2.0)) if x < 0.0 else int(floor(float(B) / 2.0))
	
	var sqrt_part = multivalued_z_pow_inv_n(one_minus_z2.x, one_minus_z2.y, 2, sqrt_branch, true)
	var iz = Vector2(-z.y, z.x)
	var sum_val = Vector2(iz.x + sqrt_part.x, iz.y + sqrt_part.y)
	var log_val = multivalued_log(sum_val.x, sum_val.y, log_branch, true)
	return Vector2(log_val.y, -log_val.x)

static func multivalued_acos(x: float, y: float) -> Vector2:
	var asin_val = multivalued_asin(x, y)
	return Vector2(PI * 0.5 - asin_val.x, -asin_val.y)

static func complex_cot(x: float, y: float) -> Vector2:
	var abs_2y = 2.0 * abs(y)
	var exp_neg = exp(-abs_2y)
	var scaled_cosh = 0.5 * (1.0 + exp_neg * exp_neg)
	var scaled_sinh = 0.5 * (1.0 - exp_neg * exp_neg) * (1.0 if y >= 0.0 else -1.0)
	var scaled_sin_2x = sin(2.0 * x) * exp_neg
	var scaled_cos_2x = cos(2.0 * x) * exp_neg
	var denom = scaled_cosh - scaled_cos_2x
	return Vector2(scaled_sin_2x / denom, -scaled_sinh / denom)

static func complex_log_sin(x: float, y: float) -> Vector2:
	var abs_y = abs(y)
	var log_scale = abs_y - log(2.0)
	var e_neg2 = exp(-2.0 * abs_y)
	var internal_z = Vector2(
		sin(x) * (1.0 + e_neg2),
		(1.0 if y >= 0.0 else -1.0) * cos(x) * (1.0 - e_neg2)
	)
	var log_internal = complex_log(internal_z.x, internal_z.y)
	return Vector2(log_scale + log_internal.x, log_internal.y)

#-------------------------------------------------------------------------
# Component Functions: Zeta, Eta, Gamma, Dedekind Eta
#-------------------------------------------------------------------------

const LOG_2 = 0.6931471805599453
const LOG_PI = 1.1447298858494002

static func dirichlet_eta(x: float, y: float, iterations: int) -> Vector2:
	if iterations <= 0: return Vector2.ZERO
	var eta = Vector2.ZERO
	var actual_iters = 0
	for n in range(1, iterations + 1, 2):
		var nf = float(n)
		var amp = pow(nf, -x)
		var log_n = log(nf)
		var theta = -y * log_n
		eta += amp * Vector2(cos(theta), sin(theta))

		var nf2 = float(n + 1)
		var amp2 = pow(nf2, -x)
		var theta2 = -y * log(nf2)
		eta -= amp2 * Vector2(cos(theta2), sin(theta2))

		actual_iters = n + 1

		if (amp < 1e-4 || amp2 < 1e-4 || amp > 1e4 || amp2 > 1e4): break

	if actual_iters > 0:
		var next_n = float(actual_iters + 1)
		var rem_amp = 0.5 * pow(next_n, -x)
		var rem_theta = -y * log(next_n)
		var rem_sign = 1.0
		eta += rem_sign * rem_amp * Vector2(cos(rem_theta), sin(rem_theta))

	return eta

static func dirichlet_beta(x: float, y: float, iterations: int) -> Vector2:
	if iterations <= 0: return Vector2.ZERO
	var beta = Vector2.ZERO
	for n in range(0, iterations, 2):
		var kf = 2.0 * float(n) + 1.0
		var amp = pow(kf, -x)
		var theta = -y * log(kf)
		beta += amp * Vector2(cos(theta), sin(theta))

		var kf2 = 2.0 * float(n + 1) + 1.0
		var amp2 = pow(kf2, -x)
		var theta2 = -y * log(kf2)
		beta -= amp2 * Vector2(cos(theta2), sin(theta2))

		if (amp < 1e-4 || amp2 < 1e-4 || amp > 1e4 || amp2 > 1e4): break
	return beta

static func zeta(x: float, y: float) -> Vector2:
	var iterations = Config.iterations
	var eta = dirichlet_eta(x, y, iterations)

	var amp2 = pow(2.0, 1.0 - x)
	var theta2 = -y * LOG_2
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

static func complex_gamma(x: float, y: float) -> Vector2:
	if x < 0.5:
		var log_sin_pi_z = complex_log_sin(PI * x, PI * y)
		var lg1z = complex_log_gamma(1.0 - x, -y)
		var log_sum = Vector2(log(PI), 0.0) - log_sin_pi_z - lg1z
		return complex_exp(log_sum.x, log_sum.y)
	return lanczos_gamma(Vector2(x, y))

static func log_zeta_continuation(x: float, y: float) -> Vector2:
	if x >= 0.5:
		var z = zeta(x, y)
		return complex_log(z.x, z.y)

	var s = Vector2(x, y)
	var s1 = Vector2(1.0 - x, -y)

	var log_sum = (complex_mul(s, Vector2(LOG_2, 0.0))
				+ complex_mul(s - Vector2(1.0, 0.0), Vector2(LOG_PI, 0.0)))

	var pi_s_2 = (PI * 0.5) * s
	log_sum += complex_log_sin(pi_s_2.x, pi_s_2.y)

	log_sum += complex_log_gamma(s1.x, s1.y)

	var zeta_part = zeta(s1.x, s1.y)
	log_sum += complex_log(zeta_part.x, zeta_part.y)

	return log_sum


static func dirichlet_eta_with_derivatives(x: float, y: float, iterations: int) -> Array:
	if iterations <= 0: return [Vector2.ZERO, Vector2.ZERO]
	var eta = Vector2.ZERO
	var deta_dx = Vector2.ZERO
	var actual_iters = 0
	for n in range(1, iterations + 1, 2):
		var nf = float(n)
		var amp = pow(nf, -x)
		var log_n = log(nf)
		var theta = -y * log_n
		var term = amp * Vector2(cos(theta), sin(theta))
		eta += term
		deta_dx -= log_n * term

		var nf2 = float(n + 1)
		var amp2 = pow(nf2, -x)
		var log_n2 = log(nf2)
		var theta2 = -y * log_n2
		var term2 = amp2 * Vector2(cos(theta2), sin(theta2))
		eta -= term2
		deta_dx += log_n2 * term2

		actual_iters = n + 1

		if (amp < 1e-4 || amp2 < 1e-4 || amp > 1e4 || amp2 > 1e4): break

	if actual_iters > 0 && x >= 0.5:
		var next_n = float(actual_iters + 1)
		var rem_amp = 0.5 * pow(next_n, -x)
		var rem_log_n = log(next_n)
		var rem_theta = -y * rem_log_n
		var rem_sign = 1.0
		var rem_term = rem_sign * rem_amp * Vector2(cos(rem_theta), sin(rem_theta))

		eta += rem_term
		deta_dx -= rem_log_n * rem_term

	return [eta, deta_dx]

static func zeta_with_derivatives(x: float, y: float) -> Array:
	var iterations = Config.iterations
	var eta_data = dirichlet_eta_with_derivatives(x, y, iterations)
	var eta = eta_data[0]
	var deta_dx = eta_data[1]

	var amp2 = pow(2.0, 1.0 - x)
	var theta2 = -y * LOG_2
	var two_term = amp2 * Vector2(cos(theta2), sin(theta2))
	var denom = Vector2(1.0, 0.0) - two_term
	var ddenom_dx = LOG_2 * two_term

	var value = complex_div(eta, denom)
	var denom_sqr = complex_mul(denom, denom)
	var num_x = complex_mul(deta_dx, denom) - complex_mul(eta, ddenom_dx)
	var dx = complex_div(num_x, denom_sqr)

	return [value, dx]

static func lanczos_log_gamma_with_derivatives(z: Vector2) -> Array:
	var z_m1 = z - Vector2(1.0, 0.0)
	var x = Vector2(LANCZOS_P[0], 0.0)
	var dx_val = Vector2(0.0, 0.0)
	for i in range(1, 9):
		var denom = z_m1 + Vector2(float(i), 0.0)
		x += complex_div(Vector2(LANCZOS_P[i], 0.0), denom)
		dx_val -= complex_div(Vector2(LANCZOS_P[i], 0.0), complex_mul(denom, denom))
	var tmp = z_m1 + Vector2(7.5, 0.0)
	var log_tmp = complex_log(tmp.x, tmp.y)

	var value = (Vector2(log(SQRT_2PI), 0.0)
			   + complex_mul(z - Vector2(0.5, 0.0), log_tmp)
			   - tmp
			   + complex_log(x.x, x.y))

	var psi = log_tmp + complex_div(z - Vector2(0.5, 0.0), tmp) - Vector2(1.0, 0.0) + complex_div(dx_val, x)

	return [value, psi]

static func complex_log_gamma_with_derivatives(x: float, y: float) -> Array:
	var value: Vector2
	var dx: Vector2
	if x < 0.5:
		var pi_z = Vector2(PI * x, PI * y)
		var lg1z = lanczos_log_gamma_with_derivatives(Vector2(1.0 - x, -y))

		var log_sin_pi_z = complex_log_sin(pi_z.x, pi_z.y)

		value = Vector2(LOG_PI, 0.0) - log_sin_pi_z - lg1z[0]

		var cot_pi_z = complex_cot(pi_z.x, pi_z.y)
		dx = - PI * cot_pi_z + lg1z[1]
	else:
		var res = lanczos_log_gamma_with_derivatives(Vector2(x, y))
		value = res[0]
		dx = res[1]
	return [value, dx]

static func log_zeta_continuation_with_derivatives(x: float, y: float) -> Array:
	if x >= 0.5:
		var z_res = zeta_with_derivatives(x, y)
		var z_val = z_res[0]
		var z_dx = z_res[1]
		var value = complex_log(z_val.x, z_val.y)
		var dx = complex_div(z_dx, z_val)
		return [value, dx]

	var s = Vector2(x, y)
	var s1 = Vector2(1.0 - x, -y)

	var log_sum = complex_mul(s, Vector2(LOG_2, 0.0)) + complex_mul(s - Vector2(1.0, 0.0), Vector2(LOG_PI, 0.0))
	var ratio = Vector2(LOG_2 + LOG_PI, 0.0)

	var pi_s_2 = (PI * 0.5) * s

	log_sum += complex_log_sin(pi_s_2.x, pi_s_2.y)
	ratio += (PI * 0.5) * complex_cot(pi_s_2.x, pi_s_2.y)

	var lg_data = complex_log_gamma_with_derivatives(s1.x, s1.y)
	log_sum += lg_data[0]
	ratio -= lg_data[1]

	var z_data = zeta_with_derivatives(s1.x, s1.y)
	log_sum += complex_log(z_data[0].x, z_data[0].y)
	ratio -= complex_div(z_data[1], z_data[0])

	return [log_sum, ratio]

static func zeta_continuation_with_derivatives(x: float, y: float) -> Array:
	var log_z = log_zeta_continuation_with_derivatives(x, y)
	var value = complex_exp(log_z[0].x, log_z[0].y)
	var dx = complex_mul(value, log_z[1])
	return [value, dx]

static func newton_step_zeta_reflection(z: Vector2, multiplier: float = 1.0) -> Vector2:
	var res = zeta_continuation_with_derivatives(z.x, z.y)
	var f_val = res[0]
	var f_prime = res[1]
	var step = complex_div(f_val, f_prime)
	if step.length() > 1.0:
		step = step.normalized()
	return z - step * multiplier

static func zeta_continuation(x: float, y: float) -> Vector2:
	var log_val = log_zeta_continuation(x, y)
	return complex_exp(log_val.x, log_val.y)

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

static func complex_log_gamma(x: float, y: float) -> Vector2:
	var res: Vector2
	if x < 0.5:
		res = Vector2(log(PI), 0.0) - complex_log_sin(PI * x, PI * y) - lanczos_log_gamma(Vector2(1.0 - x, -y))
	else:
		res = lanczos_log_gamma(Vector2(x, y))
	return res

static func dedekind_eta(x: float, y: float) -> Vector2:
	var factor = complex_exp(-PI * y / 12.0, PI * x / 12.0)
	var prod = Vector2(1.0, 0.0)
	var q_re_base = -2.0 * PI * y
	var q_im_base = 2.0 * PI * x
	var iterations = Config.iterations
	for n in range(1, iterations + 1):
		var nf = float(n)
		var term_exp = complex_exp(nf * q_re_base, nf * q_im_base)
		var term = Vector2(1.0, 0.0) - term_exp
		prod = complex_mul(prod, term)
		if nf > 10 and term_exp.length() < 1e-12: break
	return complex_mul(factor, prod)

static func mandelbrot(x: float, y: float, iterations: int) -> Vector2:
	var c = Vector2(x, y)
	var z = Vector2.ZERO
	for i in range(iterations):
		z = complex_mul(z, z) + c
		if z.length_squared() > 100.0: break
	return z

#-------------------------------------------------------------------------
# Rational Functions
#-------------------------------------------------------------------------

static func evaluate_poly(x: float, y: float, coeffs: PackedVector2Array) -> Vector2:
	var z = Vector2(x, y)
	var res = Vector2.ZERO
	# Horner's method for polynomial evaluation
	for i in range(9, -1, -1):
		res = complex_mul(res, z) + coeffs[i]
	return res

static func get_rational(x: float, y: float, num_coeffs: PackedVector2Array, den_coeffs: PackedVector2Array) -> Vector2:
	var num = evaluate_poly(x, y, num_coeffs)
	var den = evaluate_poly(x, y, den_coeffs)
	return complex_div(num, den)

static func xi(x: float, y: float) -> Vector2:
	var s = Vector2(x, y)
	var s_minus_1 = Vector2(x - 1.0, y)
	var s_half = Vector2(x * 0.5, y * 0.5)

	var log_sum = Vector2(log(0.5), 0.0)
	log_sum += complex_log(s.x, s.y)
	log_sum += complex_log(s_minus_1.x, s_minus_1.y)

	log_sum -= complex_mul(s_half, Vector2(LOG_PI, 0.0))
	log_sum += complex_log_gamma(s_half.x, s_half.y)

	log_sum += log_zeta_continuation(x, y)

	return complex_exp(log_sum.x, log_sum.y)

static func multivalued_z_pow_inv_n(x: float, y: float, n: int, branch: int = -99999, use_negative_cut: bool = false) -> Vector2:
	var r = sqrt(x * x + y * y)
	var theta = atan2(y, x)
	if not use_negative_cut and theta < 0.0: theta += 2.0 * PI
	var float_n = float(n)

	var k_current = float(branch if branch != -99999 else GameState.current_branch)

	var morphed_phase = (theta + 2.0 * PI * k_current) / float_n
	var morphed_r = pow(r, 1.0 / float_n)
	return Vector2(morphed_r * cos(morphed_phase), morphed_r * sin(morphed_phase))

static func multivalued_log(x: float, y: float, branch: int = -99999, use_negative_cut: bool = false) -> Vector2:
	var mag_sq = x * x + y * y
	if mag_sq < 1e-48: return Vector2(-60.0, 0.0)
	var r = sqrt(mag_sq)
	var theta = atan2(y, x)
	if not use_negative_cut and theta < 0.0: theta += 2.0 * PI

	var k_current = float(branch if branch != -99999 else GameState.current_branch)

	var morphed_phase = theta + 2.0 * PI * k_current
	return Vector2(log(r), morphed_phase)

#-------------------------------------------------------------------------
# Dispatchers
#-------------------------------------------------------------------------

static func get_field_at(x: float, y: float, function_type: int, is_input: bool) -> Vector2:
	match function_type:
		Config.ComplexFunc.ZETA: return zeta(x, y)
		Config.ComplexFunc.ZETA_REFLECTION: return zeta_continuation(x, y)
		Config.ComplexFunc.DIRICHLET_ETA: return dirichlet_eta(x, y, Config.iterations)
		Config.ComplexFunc.DIRICHLET_BETA: return dirichlet_beta(x, y, Config.iterations)
		Config.ComplexFunc.GAMMA: return complex_gamma(x, y)
		Config.ComplexFunc.LOG_GAMMA: return complex_log_gamma(x, y)
		Config.ComplexFunc.DEDEKIND_ETA: return dedekind_eta(x, y)
		Config.ComplexFunc.MANDELBROT: return mandelbrot(x, y, Config.iterations)
		Config.ComplexFunc.SIN: return complex_sin(x, y)
		Config.ComplexFunc.COS: return complex_cos(x, y)
		Config.ComplexFunc.TAN: return complex_tan(x, y)
		Config.ComplexFunc.COT: return complex_cot(x, y)
		Config.ComplexFunc.EXP: return complex_exp(x, y)
		Config.ComplexFunc.LOG: return complex_log(x, y)
		Config.ComplexFunc.IDENTITY: return Vector2(x, y)
		Config.ComplexFunc.RATIONAL:
			if is_input:
				return get_rational(x, y, Config.input_rational_num_coeffs, Config.input_rational_den_coeffs)
			else:
				return get_rational(x, y, Config.rational_num_coeffs, Config.rational_den_coeffs)
		Config.ComplexFunc.MULTIVALUED_Z_POW: return multivalued_z_pow_inv_n(x, y, Config.multivalued_n, -99999, true)
		Config.ComplexFunc.MULTIVALUED_LOG: return multivalued_log(x, y, -99999, true)
		Config.ComplexFunc.MULTIVALUED_ASIN: return multivalued_asin(x, y)
		Config.ComplexFunc.MULTIVALUED_ACOS: return multivalued_acos(x, y)
	return Vector2.ZERO

static func get_field(world_x: float, world_z: float) -> Vector2:
	if GameState.performance_protection_active:
		return Vector2.ZERO

	var complex_pos = Config.world_to_complex(world_x, world_z)

	var w: Vector2 = get_field_at(complex_pos.x, complex_pos.y, Config.input_function_type, true)

	return get_field_at(w.x, w.y, Config.function_type, false)

static func get_height_from_field(f: Vector2) -> float:
	if not is_finite(f.x) or not is_finite(f.y): return 0.0
	var mag = f.length()
	if not is_finite(mag): return 0.0
	
	mag = clamp(mag, -1e5, 1e5)

	var h: float
	if Config.height_type == 0: h = mag
	elif Config.height_type == 1: h = Config.height_a * log(Config.height_epsilon + mag)
	elif Config.height_type == 2: h = f.y
	elif Config.height_type == 3: h = f.x
	elif Config.height_type == 4: h = f.x * cos(Config.height_theta) + f.y * sin(Config.height_theta)
	elif Config.height_type == 5: h = 0.0


	# Match shader morphing blend factor (usually 1.0)
	var s = 0.5 - 0.5 * cos(PI * GameState.morph_value)
	var blend = log(1.0 + 8.0 * s) / log(9.0)
	h *= blend * GameState.effective_zoom

	return h if is_finite(h) else 0.0

static func get_height(x: float, z: float) -> float:
	if GameState.performance_protection_active:
		return 0.0

	var f = get_field(x, z)
	return get_height_from_field(f)

static func get_surface_normal(x: float, z: float) -> Vector3:
	var h = 0.01 * GameState.effective_zoom
	var hx = get_height(x + h, z) - get_height(x - h, z)
	var hz = get_height(x, z + h) - get_height(x, z - h)
	return Vector3(-hx, 2.0 * h, -hz).normalized()

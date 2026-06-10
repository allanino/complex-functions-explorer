# Shared field and height functions for GDScript
class_name ComplexField

const PATCH_MAX_K = 15
const PATCH_RADIUS = 2.0
const PATCH_THRESHOLD = 0.65
static var zeta_patches: Array = []

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


static func evaluate_power_series(center: Vector2, coeffs: Array, z: Vector2) -> Vector2:
	var res = Vector2.ZERO
	var dz = z - center
	var dz_k = Vector2(1.0, 0.0)
	for k in range(coeffs.size()):
		res += complex_mul(coeffs[k], dz_k)
		dz_k = complex_mul(dz_k, dz)
	return res

static func compute_zeta_taylor_patch(x: float, y: float, iters: int) -> Array:
	var eta_coeffs = []
	for k in range(PATCH_MAX_K + 1):
		eta_coeffs.append(Vector2.ZERO)

	for n in range(1, iters + 1):
		var nf = float(n)
		var amp = pow(nf, -x)
		var log_n = log(nf)
		var theta = -y * log_n

		var sign_f = 1.0 if n % 2 != 0 else -1.0
		var base = sign_f * amp * Vector2(cos(theta), sin(theta))

		var term = base
		eta_coeffs[0] += term
		for k in range(1, PATCH_MAX_K + 1):
			term = term * (-log_n / float(k))
			eta_coeffs[k] += term

	var d_coeffs = []
	var base_d = 2.0 * pow(2.0, -x) * Vector2(cos(-y * LOG_2), sin(-y * LOG_2))
	var d_term = base_d
	d_coeffs.append(Vector2(1.0, 0.0) - d_term)
	for k in range(1, PATCH_MAX_K + 1):
		d_term = d_term * (-LOG_2 / float(k))
		d_coeffs.append(-d_term)

	var zeta_coeffs = []
	for k in range(PATCH_MAX_K + 1):
		var sum_val = eta_coeffs[k]
		for j in range(k):
			sum_val -= complex_mul(zeta_coeffs[j], d_coeffs[k - j])
		zeta_coeffs.append(complex_div(sum_val, d_coeffs[0]))

	return zeta_coeffs

static func _get_or_create_patch(z: Vector2, iters: int) -> Dictionary:
	var closest_patch = null
	var min_dist = 1e9

	for patch in zeta_patches:
		var dist = (z - patch["center"]).length()
		if dist < min_dist:
			min_dist = dist
			closest_patch = patch

	if closest_patch != null and min_dist <= PATCH_RADIUS * PATCH_THRESHOLD:
		return closest_patch

	if closest_patch == null:
		var start_x = max(z.x, 0.5)
		var start_z = Vector2(start_x, z.y)
		var coeffs = compute_zeta_taylor_patch(start_z.x, start_z.y, iters)
		var p = {
			"center": start_z,
			"coeffs": coeffs,
			"radius": PATCH_RADIUS
		}
		zeta_patches.append(p)
		return _get_or_create_patch(z, iters)

	var dir = (z - closest_patch["center"]).normalized()
	var step_dist = min(min_dist, PATCH_RADIUS * PATCH_THRESHOLD)
	var new_center = closest_patch["center"] + dir * step_dist

	var K = PATCH_MAX_K
	var new_coeffs = []

	# The reviewer noted: "when Re(s_0) > 0, generate coefficients directly from eta / Dirichlet evaluation... when Re(s_0) <= 0, do not evaluate the Dirichlet series at the patch center."
	if new_center.x > 0.0:
		new_coeffs = compute_zeta_taylor_patch(new_center.x, new_center.y, iters)
	else:
		for k in range(K + 1):
			new_coeffs.append(Vector2.ZERO)

		var dz = new_center - closest_patch["center"]
		var old_coeffs = closest_patch["coeffs"]

		for j in range(K + 1):
			var res = Vector2.ZERO
			var dz_k = Vector2(1.0, 0.0)
			for k in range(j, K + 1):
				var comb = 1.0
				for i in range(1, k - j + 1):
					comb = comb * float(j + i) / float(i)
				var term = complex_mul(old_coeffs[k], dz_k)
				res += term * comb
				dz_k = complex_mul(dz_k, dz)
			new_coeffs[j] = res

	var new_patch = {
		"center": new_center,
		"coeffs": new_coeffs,
		"radius": PATCH_RADIUS
	}
	zeta_patches.append(new_patch)
	return _get_or_create_patch(z, iters)

static func zeta_continuation_power_series(x: float, y: float) -> Vector2:
	if x >= 0.5:
		return zeta(x, y)
	var z = Vector2(x, y)
	var patch = _get_or_create_patch(z, Config.iterations)
	return evaluate_power_series(patch["center"], patch["coeffs"], z)

static func zeta_continuation_power_series_with_derivatives(x: float, y: float, iters: int) -> Array:
	if x >= 0.5:
		return zeta_with_derivatives(x, y, iters)
	var z = Vector2(x, y)
	var patch = _get_or_create_patch(z, iters)
	var val = evaluate_power_series(patch["center"], patch["coeffs"], z)

	var res_prime = Vector2.ZERO
	var dz = z - patch["center"]
	var dz_k = Vector2(1.0, 0.0)
	for k in range(1, patch["coeffs"].size()):
		var coeff_scaled = patch["coeffs"][k] * float(k)
		res_prime += complex_mul(coeff_scaled, dz_k)
		dz_k = complex_mul(dz_k, dz)

	return [val, res_prime]

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


static func dirichlet_eta_with_derivatives(x: float, y: float, iters: int) -> Array:
	var eta = Vector2.ZERO
	var deta_dx = Vector2.ZERO
	var actual_iters = 0
	for n in range(1, iters + 1, 2):
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

		if amp < 1e-4 or amp2 < 1e-4 or amp > 1e4 or amp2 > 1e4:
			break

	if actual_iters > 0 and x >= 0.5:
		var next_n = float(actual_iters + 1)
		var rem_amp = 0.5 * pow(next_n, -x)
		var rem_log_n = log(next_n)
		var rem_theta = -y * rem_log_n
		var rem_sign = 1.0
		var rem_term = rem_sign * rem_amp * Vector2(cos(rem_theta), sin(rem_theta))

		eta += rem_term
		deta_dx -= rem_log_n * rem_term

	return [eta, deta_dx]

static func zeta_with_derivatives(x: float, y: float, iters: int) -> Array:
	var eta_data = dirichlet_eta_with_derivatives(x, y, iters)
	var eta = eta_data[0]
	var deta_dx = eta_data[1]

	var amp2 = pow(2.0, 1.0 - x)
	var theta2 = -y * LOG_2
	var two_term = amp2 * Vector2(cos(theta2), sin(theta2))
	var denom = Vector2(1.0, 0.0) - two_term
	var ddenom_dx = LOG_2 * two_term

	var val = complex_div(eta, denom)
	var denom_sqr = complex_mul(denom, denom)
	var num_x = complex_mul(deta_dx, denom) - complex_mul(eta, ddenom_dx)
	var dx = complex_div(num_x, denom_sqr)

	return [val, dx]

static func lanczos_log_gamma_with_derivatives(z: Vector2) -> Array:
	var z_m1 = z - Vector2(1.0, 0.0)
	var x = Vector2(LANCZOS_P[0], 0.0)
	var dx_val = Vector2.ZERO
	for i in range(1, 9):
		var denom = z_m1 + Vector2(float(i), 0.0)
		x += complex_div(Vector2(LANCZOS_P[i], 0.0), denom)
		dx_val -= complex_div(Vector2(LANCZOS_P[i], 0.0), complex_mul(denom, denom))

	var tmp = z_m1 + Vector2(7.5, 0.0)
	var log_tmp = complex_log(tmp.x, tmp.y)

	var val = Vector2(log(SQRT_2PI), 0.0) + complex_mul(z - Vector2(0.5, 0.0), log_tmp) - tmp + complex_log(x.x, x.y)

	var psi = log_tmp + complex_div(z - Vector2(0.5, 0.0), tmp) - Vector2(1.0, 0.0) + complex_div(dx_val, x)

	return [val, psi]

static func complex_log_gamma_with_derivatives(x: float, y: float) -> Array:
	if x < 0.5:
		var pi_z = Vector2(PI * x, PI * y)
		var lg1z = lanczos_log_gamma_with_derivatives(Vector2(1.0 - x, -y))
		var log_sin_pi_z = complex_log_sin(pi_z.x, pi_z.y)

		var val = Vector2(LOG_PI, 0.0) - log_sin_pi_z - lg1z[0]
		var cot_pi_z = complex_cot(pi_z.x, pi_z.y)
		var dx = -PI * cot_pi_z + lg1z[1]
		return [val, dx]
	else:
		return lanczos_log_gamma_with_derivatives(Vector2(x, y))

static func log_zeta_continuation_with_derivatives(x: float, y: float, iters: int) -> Array:
	if x >= 0.5:
		var z_data = zeta_with_derivatives(x, y, iters)
		var z_val = z_data[0]
		var z_dx = z_data[1]
		var val = complex_log(z_val.x, z_val.y)
		var dx = complex_div(z_dx, z_val)
		return [val, dx]

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

	var z_data = zeta_with_derivatives(s1.x, s1.y, iters)
	var z_val = z_data[0]
	log_sum += complex_log(z_val.x, z_val.y)
	ratio -= complex_div(z_data[1], z_val)

	return [log_sum, ratio]

static func zeta_continuation_with_derivatives(x: float, y: float, iters: int) -> Array:
	if x >= 0.5:
		return zeta_with_derivatives(x, y, iters)

	var log_z = log_zeta_continuation_with_derivatives(x, y, iters)
	var val = complex_exp(log_z[0].x, log_z[0].y)
	var dx = complex_mul(val, log_z[1])
	return [val, dx]

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

# Returns [next_z: Vector2, f_val: Vector2] so the caller can reuse f_val
# without an extra get_field evaluation.
static func newton_step(z: Vector2, step_size_mult: float, max_step: float = 1.0) -> Array:
	var use_analytic = false
	var f_val = Vector2.ZERO
	var f_prime = Vector2.ZERO

	if Config.input_function_type == Config.ComplexFunc.IDENTITY:
		if Config.function_type == Config.ComplexFunc.ZETA:
			var res = zeta_with_derivatives(z.x, z.y, Config.iterations)
			f_val = res[0]
			f_prime = res[1]
			use_analytic = true
		elif Config.function_type == Config.ComplexFunc.ZETA_REFLECTION:
			var res = zeta_continuation_with_derivatives(z.x, z.y, Config.iterations)
			f_val = res[0]
			f_prime = res[1]
			use_analytic = true
		elif Config.function_type == Config.ComplexFunc.DIRICHLET_ETA:
			var res = dirichlet_eta_with_derivatives(z.x, z.y, Config.iterations)
			f_val = res[0]
			f_prime = res[1]
			use_analytic = true

	if not use_analytic:
		var p_ref = Config.complex_to_world(z.x, z.y)
		f_val = get_field(p_ref.x, p_ref.y)
		var delta_x = 1e-5
		var p_ref_dx = Config.complex_to_world(z.x + delta_x, z.y)
		var f_val_dx = get_field(p_ref_dx.x, p_ref_dx.y)
		f_prime = (f_val_dx - f_val) / delta_x

	if f_prime.length_squared() < 1e-12:
		return [z, f_val]

	var step = complex_div(f_val, f_prime)
	if step.length() > max_step:
		step = step.normalized() * max_step
	return [z - step * step_size_mult, f_val]

static func get_height_from_field(f: Vector2) -> float:
	if not is_finite(f.x) or not is_finite(f.y): return NAN
	var mag = f.length()
	if not is_finite(mag): return NAN
	
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
	h = clamp(h, -1e5, 1e5)
	h *= blend * GameState.effective_zoom

	return h if is_finite(h) else NAN

static func get_height(x: float, z: float) -> float:
	if GameState.performance_protection_active:
		return 0.0

	var f = get_field(x, z)
	return get_height_from_field(f)

def process_code():
    gdscript_code = """
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
	var log_z = log_zeta_continuation_with_derivatives(x, y, iters)
	var val = complex_exp(log_z[0].x, log_z[0].y)
	var dx = complex_mul(val, log_z[1])
	return [val, dx]
"""
    with open("math/complex_field.gd", "r") as f:
        content = f.read()

    # Insert before get_field_at
    content = content.replace("static func get_field_at", gdscript_code + "\nstatic func get_field_at")

    # Replace newton_step
    new_newton = """# Returns [next_z: Vector2, f_val: Vector2] so the caller can reuse f_val
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
	return [z - step * step_size_mult, f_val]"""

    import re
    content = re.sub(r"# Returns \[next_z: Vector2, f_val: Vector2\] so the caller can reuse f_val\n# without an extra get_field evaluation\.\nstatic func newton_step[\s\S]+?return \[z - step \* step_size_mult, f_val\]", new_newton, content)

    with open("math/complex_field.gd", "w") as f:
        f.write(content)

process_code()

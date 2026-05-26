extends GutTest

const TestField = preload("res://scripts/field.gd")

func test_complex_mul():
	var z1 = Vector2(1, 2)
	var z2 = Vector2(3, 4)
	var res = TestField.complex_mul(z1, z2)
	assert_eq(res, Vector2(-5, 10))

func test_complex_div():
	var z1 = Vector2(5, 7)
	var z2 = Vector2(2, 3)
	var res = TestField.complex_div(z1, z2)
	assert_almost_eq(res.x, 31.0/13.0, 0.0001)
	assert_almost_eq(res.y, -1.0/13.0, 0.0001)

func test_complex_exp():
	var res = TestField.complex_exp(0, PI)
	assert_almost_eq(res.x, -1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_exp(0, PI/2)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 1.0, 0.0001)

func test_complex_log():
	var res = TestField.complex_log(1, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_log(0, 1)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, PI/2, 0.0001)

func test_complex_pow():
	var res = TestField.complex_pow(Vector2(2, 0), Vector2(3, 0))
	assert_almost_eq(res.x, 8.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_pow(Vector2(0, 1), Vector2(2, 0))
	assert_almost_eq(res.x, -1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_pow(Vector2(0, 0), Vector2(2, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_pow(Vector2(0, 0), Vector2(0, 0))
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_sin():
	var res = TestField.complex_sin(0, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_sin(PI/2, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cos():
	var res = TestField.complex_cos(0, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_cos(PI/2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_tan():
	var res = TestField.complex_tan(0, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cot():
	var res = TestField.complex_cot(PI/2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_log_sin():
	var res = TestField.complex_log_sin(PI/2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_eta():
	var res = TestField.dirichlet_eta(1, 0, 100)
	assert_almost_eq(res.x, log(2.0), 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_beta():
	var res = TestField.dirichlet_beta(1, 0, 100)
	assert_almost_eq(res.x, PI/4, 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_evaluate_poly():
	var coeffs = PackedVector2Array([Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]) # 1 + 2z + 3z^2
	var res = TestField.evaluate_poly(2, 0, coeffs)
	assert_almost_eq(res.x, 17.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_lanczos_gamma():
	var res = TestField.lanczos_gamma(Vector2(1, 0))
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	var res2 = TestField.lanczos_gamma(Vector2(2, 0))
	assert_almost_eq(res2.x, 1.0, 0.0001)
	assert_almost_eq(res2.y, 0.0, 0.0001)

	var res3 = TestField.lanczos_gamma(Vector2(3, 0))
	assert_almost_eq(res3.x, 2.0, 0.0001)
	assert_almost_eq(res3.y, 0.0, 0.0001)

	var res4 = TestField.lanczos_gamma(Vector2(0.5, 0))
	assert_almost_eq(res4.x, sqrt(PI), 0.0001)
	assert_almost_eq(res4.y, 0.0, 0.0001)

func test_complex_gamma():
	var res = TestField.complex_gamma(1, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)
	
	var res2 = TestField.complex_gamma(-2, -1)
	assert_almost_eq(res2.x, 0.133910, 0.0001)
	assert_almost_eq(res2.y, 0.0962865, 0.0001)

func test_complex_log_gamma():
	var res = TestField.complex_log_gamma(1, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	var res2 = TestField.complex_log_gamma(-2, -1)
	assert_almost_eq(res2.x, -1.802215, 0.0001)
	assert_almost_eq(res2.y, 0.62339, 0.0001)

func test_zeta():
	var res = TestField.zeta(0.5, 14.134725)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
func test_zeta_continuation():
	var res = TestField.zeta_continuation(0.5, 14.134725)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
	var res2 = TestField.zeta_continuation(-2.0, 3.0)
	assert_almost_eq(res2.x, 0.132971, 0.015)
	assert_almost_eq(res2.y, 0.123053, 0.015)

func test_dedekind_eta():
	var res = TestField.dedekind_eta(0, 1)
	assert_almost_eq(res.x, 0.7682, 0.01)
	assert_almost_eq(res.y, 0.0, 0.01)

func test_mandelbrot():
	var res = TestField.mandelbrot(0, 0, 10)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_lanczos_log_gamma():
	var res = TestField.lanczos_log_gamma(Vector2(1.0, 0.0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.lanczos_log_gamma(Vector2(2.0, 0.0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.lanczos_log_gamma(Vector2(3.0, 0.0))
	assert_almost_eq(res.x, log(2.0), 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.lanczos_log_gamma(Vector2(1.0, 1.0))
	assert_almost_eq(res.x, -0.6509, 0.0001)
	assert_almost_eq(res.y, -0.3016, 0.0001)

	res = TestField.lanczos_log_gamma(Vector2(-2.0, -1.0))
	assert_almost_eq(res.x, -1.8022, 0.0001)
	assert_almost_eq(res.y, 0.6233, 0.0001)

func test_get_rational():
	var orig_num = Config.rational_num_coeffs
	var orig_den = Config.rational_den_coeffs

	# f(z) = (1 + 2z) / (1 + z)
	var test_num = PackedVector2Array()
	var test_den = PackedVector2Array()
	for i in range(10):
		test_num.append(Vector2.ZERO)
		test_den.append(Vector2.ZERO)

	test_num[0] = Vector2(1, 0)
	test_num[1] = Vector2(2, 0)
	test_den[0] = Vector2(1, 0)
	test_den[1] = Vector2(1, 0)

	Config.rational_num_coeffs = test_num
	Config.rational_den_coeffs = test_den

	# Test with z = 2.0 + 0.0i -> f(2) = (1 + 4) / (1 + 2) = 5/3
	var res1 = TestField.get_rational(2.0, 0.0)
	assert_almost_eq(res1.x, 5.0/3.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test with z = 0.0 + 1.0i -> f(i) = (1 + 2i) / (1 + i) = (1 + 2i)(1 - i) / 2 = (1 - i + 2i + 2) / 2 = (3 + i) / 2 = 1.5 + 0.5i
	var res2 = TestField.get_rational(0.0, 1.0)
	assert_almost_eq(res2.x, 1.5, 0.0001)
	assert_almost_eq(res2.y, 0.5, 0.0001)

	Config.rational_num_coeffs = orig_num
	Config.rational_den_coeffs = orig_den

func test_multivalued_z_pow_inv_n():
	# Save original config values to restore them later
	var orig_mode = Config.multivalued_mode
	var orig_current_branch = Config.current_branch
	var orig_branch_time = Config.branch_time
	var orig_morph_time = Config.multivalued_morph_time

	# Test 1: Branch Portals mode (mode 1), branch 0
	Config.multivalued_mode = 1
	Config.current_branch = 0
	var res1 = TestField.multivalued_z_pow_inv_n(1.0, 0.0, 2, 1.0)
	assert_almost_eq(res1.x, 1.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test 2: Branch Portals mode (mode 1), branch 1
	Config.current_branch = 1
	var res2 = TestField.multivalued_z_pow_inv_n(1.0, 0.0, 2, 1.0)
	assert_almost_eq(res2.x, -1.0, 0.0001)
	assert_almost_eq(res2.y, 0.0, 0.0001)

	# Test 3: Branch Portals mode (mode 1), z = -1, branch 0, n = 2 -> sqrt(-1) = i
	Config.current_branch = 0
	var res3 = TestField.multivalued_z_pow_inv_n(-1.0, 0.0, 2, 1.0)
	assert_almost_eq(res3.x, 0.0, 0.0001)
	assert_almost_eq(res3.y, 1.0, 0.0001)

	# Test 4: Time cycle mode (mode 0), t=0 (branch 0)
	Config.multivalued_mode = 0
	Config.branch_time = 0.0
	Config.multivalued_morph_time = 0.5
	var res4 = TestField.multivalued_z_pow_inv_n(1.0, 0.0, 2, 1.0)
	assert_almost_eq(res4.x, 1.0, 0.0001)
	assert_almost_eq(res4.y, 0.0, 0.0001)

	# Test 5: Time cycle mode (mode 0), time = 0.25 (progress = 0.5, t_in_branch = 0.5)
	# n=2, cycle_speed=1.0, morph_time=0.5
	# morph_time * n * cycle_speed = 1.0 (transition_fraction)
	# transition_threshold = 1.0 - 1.0 = 0.0
	# blend_factor = smoothstep(0.0, 1.0, 0.5) = 0.5
	# morphed_phase = (0 + 2PI * (0 + 0.5)) / 2 = PI / 2
	Config.branch_time = 0.25
	var res5 = TestField.multivalued_z_pow_inv_n(1.0, 0.0, 2, 1.0)
	assert_almost_eq(res5.x, 0.0, 0.0001)
	assert_almost_eq(res5.y, 1.0, 0.0001)

	# Test 6: Time cycle mode (mode 0), time = 0.5 (progress = 1.0, branch 1, t_in_branch = 0.0)
	Config.branch_time = 0.5
	var res6 = TestField.multivalued_z_pow_inv_n(1.0, 0.0, 2, 1.0)
	assert_almost_eq(res6.x, -1.0, 0.0001)
	assert_almost_eq(res6.y, 0.0, 0.0001)

	# Restore config values
	Config.multivalued_mode = orig_mode
	Config.current_branch = orig_current_branch
	Config.branch_time = orig_branch_time
	Config.multivalued_morph_time = orig_morph_time

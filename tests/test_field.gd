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
	var res = TestField.complex_exp(Vector2(0, PI))
	assert_almost_eq(res.x, -1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_exp(Vector2(0, PI/2))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 1.0, 0.0001)

func test_complex_log():
	var res = TestField.complex_log(Vector2(1, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_log(Vector2(0, 1))
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
	var res = TestField.complex_sin(Vector2(0, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_sin(Vector2(PI/2, 0))
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cos():
	var res = TestField.complex_cos(Vector2(0, 0))
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = TestField.complex_cos(Vector2(PI/2, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_tan():
	var res = TestField.complex_tan(Vector2(0, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cot():
	var res = TestField.complex_cot(Vector2(PI/2, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_log_sin():
	var res = TestField.complex_log_sin(Vector2(PI/2, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_eta():
	var res = TestField.dirichlet_eta(Vector2(1, 0), 100)
	assert_almost_eq(res.x, log(2.0), 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_beta():
	var res = TestField.dirichlet_beta(Vector2(1, 0), 100)
	assert_almost_eq(res.x, PI/4, 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_evaluate_poly():
	var coeffs = PackedVector2Array([Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]) # 1 + 2z + 3z^2
	var res = TestField.evaluate_poly(Vector2(2, 0), coeffs)
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
	var res = TestField.complex_gamma(Vector2(1, 0))
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)
	
	var res2 = TestField.complex_gamma(Vector2(-2, -1))
	assert_almost_eq(res2.x, 0.133910, 0.0001)
	assert_almost_eq(res2.y, 0.0962865, 0.0001)

func test_complex_log_gamma():
	var res = TestField.complex_log_gamma(Vector2(1, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	var res2 = TestField.complex_log_gamma(Vector2(-2, -1))
	assert_almost_eq(res2.x, -1.802215, 0.0001)
	assert_almost_eq(res2.y, 0.62339, 0.0001)

func test_zeta():
	var res = TestField.zeta(Vector2(0.5, 14.134725))
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
func test_zeta_continuation():
	var res = TestField.zeta_continuation(Vector2(0.5, 14.134725))
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
	var res2 = TestField.zeta_continuation(Vector2(-2.0, 3.0))
	assert_almost_eq(res2.x, 0.132971, 0.015)
	assert_almost_eq(res2.y, 0.123053, 0.015)

func test_dedekind_eta():
	var res = TestField.dedekind_eta(Vector2(0, 1))
	assert_almost_eq(res.x, 0.7682, 0.01)
	assert_almost_eq(res.y, 0.0, 0.01)

func test_mandelbrot():
	var res = TestField.mandelbrot(Vector2(0, 0), 10)
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
	var res1 = TestField.get_rational(Vector2(2.0, 0.0))
	assert_almost_eq(res1.x, 5.0/3.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test with z = 0.0 + 1.0i -> f(i) = (1 + 2i) / (1 + i) = (1 + 2i)(1 - i) / 2 = (1 - i + 2i + 2) / 2 = (3 + i) / 2 = 1.5 + 0.5i
	var res2 = TestField.get_rational(Vector2(0.0, 1.0))
	assert_almost_eq(res2.x, 1.5, 0.0001)
	assert_almost_eq(res2.y, 0.5, 0.0001)

	Config.rational_num_coeffs = orig_num
	Config.rational_den_coeffs = orig_den

func test_multivalued_z_pow_inv_n():
	# Save original config values to restore them later
	var orig_current_branch = Config.current_branch

	# Test 1: branch 0
	Config.current_branch = 0
	var res1 = TestField.multivalued_z_pow_inv_n(Vector2(1.0, 0.0), 2)
	assert_almost_eq(res1.x, 1.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test 2: branch 1
	Config.current_branch = 1
	var res2 = TestField.multivalued_z_pow_inv_n(Vector2(1.0, 0.0), 2)
	assert_almost_eq(res2.x, -1.0, 0.0001)
	assert_almost_eq(res2.y, 0.0, 0.0001)

	# Test 3: z = -1, branch 0, n = 2 -> sqrt(-1) = i
	Config.current_branch = 0
	var res3 = TestField.multivalued_z_pow_inv_n(Vector2(-1.0, 0.0), 2)
	assert_almost_eq(res3.x, 0.0, 0.0001)
	assert_almost_eq(res3.y, 1.0, 0.0001)

	# Restore config values
	Config.current_branch = orig_current_branch

func test_get_height_from_field():
	var orig_height_type = Config.height_type
	var orig_height_a = Config.height_a
	var orig_height_epsilon = Config.height_epsilon
	var orig_morph_value = Config.morph_value
	var orig_effective_zoom = Config.effective_zoom

	# Test 1: Non-finite inputs
	var res1 = TestField.get_height_from_field(Vector2(INF, 0))
	assert_almost_eq(res1, 0.0, 0.0001)

	var res2 = TestField.get_height_from_field(Vector2(NAN, 0))
	assert_almost_eq(res2, 0.0, 0.0001)

	# Test 2: height_type = 0 (Logarithmic), morph_value = 1.0
	Config.height_type = 0
	Config.height_a = 3.0
	Config.height_epsilon = 1.0
	Config.morph_value = 1.0
	Config.effective_zoom = 1.0
	var f3 = Vector2(3, 4) # mag = 5
	# log(1.0 + 5) = log(6) ~ 1.791759 * 3.0 = 5.375278
	var expected_log = 3.0 * log(6.0)
	var res3 = TestField.get_height_from_field(f3)
	assert_almost_eq(res3, expected_log, 0.0001)

	# Test 3: height_type = 1 (Linear), morph_value = 1.0
	Config.height_type = 1
	var expected_linear = 5.0
	var res4 = TestField.get_height_from_field(f3)
	assert_almost_eq(res4, expected_linear, 0.0001)

	# Test 4: Morph and zoom scaling
	Config.morph_value = 0.5
	Config.effective_zoom = 2.0
	# s = 0.5 - 0.5 * cos(PI * 0.5) = 0.5 - 0.5 * 0 = 0.5
	# blend = log(1.0 + 8.0 * 0.5) / log(9.0) = log(5.0) / log(9.0) ~ 0.732486
	# height = expected_linear * blend * effective_zoom
	var expected_blend = log(5.0) / log(9.0)
	var expected_scaled = 5.0 * expected_blend * 2.0
	var res5 = TestField.get_height_from_field(f3)
	assert_almost_eq(res5, expected_scaled, 0.0001)

	Config.height_type = orig_height_type
	Config.height_a = orig_height_a
	Config.height_epsilon = orig_height_epsilon
	Config.morph_value = orig_morph_value
	Config.effective_zoom = orig_effective_zoom

func test_get_height():
	var orig_perf = Config.performance_protection_active
	var orig_func = Config.function_type
	var orig_zoom = Config.effective_zoom
	var orig_type = Config.height_type
	var orig_morph = Config.morph_value

	Config.set("function_type", Config.ComplexFunc.ZETA_REFLECTION)
	Config.iterations = 2000
	Config.effective_zoom = 1.0
	Config.height_type = 1 # linear height
	Config.morph_value = 1.0 # blend = 1.0

	# Test performance protection early exit
	Config.performance_protection_active = true
	var h1 = TestField.get_height(0.0, 0.0)
	assert_eq(h1, 0.0)

	Config.performance_protection_active = false

	# x=1.0, z=0 -> sigma=0.1, t=0 -> zeta(0.1, 0) = -0.603038
	# mag = 0.603038
	# height_type = 1 -> h = 0.603038 * 1.0 * 1.0 = 0.603038
	var world_pos = Vector2(1.0, 0.0)
	var h2 = TestField.get_height(world_pos.x, world_pos.y)
	assert_almost_eq(h2, 0.603038, 0.001)

	Config.performance_protection_active = orig_perf
	Config.set("function_type", orig_func)
	Config.effective_zoom = orig_zoom
	Config.height_type = orig_type
	Config.morph_value = orig_morph

func test_multivalued_log():
	# Save original config values to restore them later
	var orig_mode = Config.multivalued_mode
	var orig_current_branch = Config.current_branch
	var orig_branch_time = Config.branch_time
	var orig_morph_time = Config.multivalued_morph_time

	# Test 1: Branch Portals mode (mode 1), branch 0, z = e
	Config.multivalued_mode = 1
	Config.current_branch = 0
	var res1 = TestField.multivalued_log(Vector2(2.718281828459, 0.0))
	assert_almost_eq(res1.x, 1.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test 2: Branch Portals mode (mode 1), branch 1, z = e
	Config.current_branch = 1
	var res2 = TestField.multivalued_log(Vector2(2.718281828459, 0.0))
	assert_almost_eq(res2.x, 1.0, 0.0001)
	assert_almost_eq(res2.y, 2.0 * PI, 0.0001)

	# Test 3: Branch Portals mode (mode 1), branch 2, z = e
	Config.current_branch = 2
	var res3 = TestField.multivalued_log(Vector2(2.718281828459, 0.0))
	assert_almost_eq(res3.x, 1.0, 0.0001)
	assert_almost_eq(res3.y, 4.0 * PI, 0.0001)

	# Restore config values
	Config.multivalued_mode = orig_mode
	Config.current_branch = orig_current_branch
	Config.branch_time = orig_branch_time
	Config.multivalued_morph_time = orig_morph_time

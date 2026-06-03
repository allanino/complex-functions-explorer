extends GutTest

const ComplexFieldScript = preload("res://math/complex_field.gd")

func test_complex_mul():
	var z1 = Vector2(1, 2)
	var z2 = Vector2(3, 4)
	var res = ComplexFieldScript.complex_mul(z1, z2)
	assert_eq(res, Vector2(-5, 10))

func test_complex_div():
	var z1 = Vector2(5, 7)
	var z2 = Vector2(2, 3)
	var res = ComplexFieldScript.complex_div(z1, z2)
	assert_almost_eq(res.x, 31.0 / 13.0, 0.0001)
	assert_almost_eq(res.y, -1.0 / 13.0, 0.0001)

func test_complex_exp():
	var res = ComplexFieldScript.complex_exp(0, PI)
	assert_almost_eq(res.x, -1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.complex_exp(0, PI / 2)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 1.0, 0.0001)

func test_complex_log():
	var res = ComplexFieldScript.complex_log(1, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.complex_log(0, 1)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, PI / 2, 0.0001)

func test_complex_pow():
	var res = ComplexFieldScript.complex_pow(Vector2(2, 0), Vector2(3, 0))
	assert_almost_eq(res.x, 8.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.complex_pow(Vector2(0, 1), Vector2(2, 0))
	assert_almost_eq(res.x, -1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.complex_pow(Vector2(0, 0), Vector2(2, 0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.complex_pow(Vector2(0, 0), Vector2(0, 0))
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_sin():
	var res = ComplexFieldScript.complex_sin(0, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.complex_sin(PI / 2, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cos():
	var res = ComplexFieldScript.complex_cos(0, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.complex_cos(PI / 2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_tan():
	var res = ComplexFieldScript.complex_tan(0, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cot():
	var res = ComplexFieldScript.complex_cot(PI / 2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_log_sin():
	var res = ComplexFieldScript.complex_log_sin(PI / 2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_eta():
	var res = ComplexFieldScript.dirichlet_eta(1, 0, 100)
	assert_almost_eq(res.x, log(2.0), 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_beta():
	var res = ComplexFieldScript.dirichlet_beta(1, 0, 100)
	assert_almost_eq(res.x, PI / 4, 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_evaluate_poly():
	var coeffs = PackedVector2Array([Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]) # 1 + 2z + 3z^2
	var res = ComplexFieldScript.evaluate_poly(2, 0, coeffs)
	assert_almost_eq(res.x, 17.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_lanczos_gamma():
	var res = ComplexFieldScript.lanczos_gamma(Vector2(1, 0))
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	var res2 = ComplexFieldScript.lanczos_gamma(Vector2(2, 0))
	assert_almost_eq(res2.x, 1.0, 0.0001)
	assert_almost_eq(res2.y, 0.0, 0.0001)

	var res3 = ComplexFieldScript.lanczos_gamma(Vector2(3, 0))
	assert_almost_eq(res3.x, 2.0, 0.0001)
	assert_almost_eq(res3.y, 0.0, 0.0001)

	var res4 = ComplexFieldScript.lanczos_gamma(Vector2(0.5, 0))
	assert_almost_eq(res4.x, sqrt(PI), 0.0001)
	assert_almost_eq(res4.y, 0.0, 0.0001)

func test_complex_gamma():
	var res = ComplexFieldScript.complex_gamma(1, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)
	
	var res2 = ComplexFieldScript.complex_gamma(-2, -1)
	assert_almost_eq(res2.x, 0.133910, 0.0001)
	assert_almost_eq(res2.y, 0.0962865, 0.0001)

func test_complex_log_gamma():
	var res = ComplexFieldScript.complex_log_gamma(1, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	var res2 = ComplexFieldScript.complex_log_gamma(-2, -1)
	assert_almost_eq(res2.x, -1.802215, 0.0001)
	assert_almost_eq(res2.y, 0.62339, 0.0001)

func test_zeta():
	var res = ComplexFieldScript.zeta(0.5, 14.134725)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
func test_zeta_continuation():
	var res = ComplexFieldScript.zeta_continuation(0.5, 14.134725)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
	var res2 = ComplexFieldScript.zeta_continuation(-2.0, 3.0)
	assert_almost_eq(res2.x, 0.132971, 0.015)
	assert_almost_eq(res2.y, 0.123053, 0.015)

	# Zeta from Mathematica:
	# Zeta[-2. + 3. I]
	# 0.132971 + 0.123053 I
	var data = ComplexFieldScript.zeta_continuation_with_derivatives(-2.0, 3.0)
	var res3 = data[0]
	assert_almost_eq(res3.x, 0.132971, 0.015)
	assert_almost_eq(res3.y, 0.123053, 0.015)

	# Zeta derivative from Mathematica:
	# D[Zeta[x + 3.0 I], x] /. x -> -2.0
	# 0.132743 - 0.037438 I
	var dx = data[1]
	assert_almost_eq(dx.x, 0.132743, 0.015)
	assert_almost_eq(dx.y, -0.037438, 0.015)

func test_dedekind_eta():
	var res = ComplexFieldScript.dedekind_eta(0, 1)
	assert_almost_eq(res.x, 0.7682, 0.01)
	assert_almost_eq(res.y, 0.0, 0.01)

func test_mandelbrot():
	var res = ComplexFieldScript.mandelbrot(0, 0, 10)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_lanczos_log_gamma():
	var res = ComplexFieldScript.lanczos_log_gamma(Vector2(1.0, 0.0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.lanczos_log_gamma(Vector2(2.0, 0.0))
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.lanczos_log_gamma(Vector2(3.0, 0.0))
	assert_almost_eq(res.x, log(2.0), 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = ComplexFieldScript.lanczos_log_gamma(Vector2(1.0, 1.0))
	assert_almost_eq(res.x, -0.6509, 0.0001)
	assert_almost_eq(res.y, -0.3016, 0.0001)

	res = ComplexFieldScript.lanczos_log_gamma(Vector2(-2.0, -1.0))
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
	var res1 = ComplexFieldScript.get_rational(2.0, 0.0, test_num, test_den)
	assert_almost_eq(res1.x, 5.0 / 3.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test with z = 0.0 + 1.0i -> f(i) = (1 + 2i) / (1 + i) = (1 + 2i)(1 - i) / 2 = (1 - i + 2i + 2) / 2 = (3 + i) / 2 = 1.5 + 0.5i
	var res2 = ComplexFieldScript.get_rational(0.0, 1.0, test_num, test_den)
	assert_almost_eq(res2.x, 1.5, 0.0001)
	assert_almost_eq(res2.y, 0.5, 0.0001)

	Config.rational_num_coeffs = orig_num
	Config.rational_den_coeffs = orig_den

func test_multivalued_z_pow_inv_n():
	# Save original config values to restore them later
	var orig_current_branch = GameState.current_branch

	# Test 1: branch 0
	GameState.current_branch = 0
	var res1 = ComplexFieldScript.multivalued_z_pow_inv_n(1.0, 0.0, 2)
	assert_almost_eq(res1.x, 1.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test 2: branch 1
	GameState.current_branch = 1
	var res2 = ComplexFieldScript.multivalued_z_pow_inv_n(1.0, 0.0, 2)
	assert_almost_eq(res2.x, -1.0, 0.0001)
	assert_almost_eq(res2.y, 0.0, 0.0001)

	# Test 3: z = -1, branch 0, n = 2 -> sqrt(-1) = i
	GameState.current_branch = 0
	var res3 = ComplexFieldScript.multivalued_z_pow_inv_n(-1.0, 0.0, 2)
	assert_almost_eq(res3.x, 0.0, 0.0001)
	assert_almost_eq(res3.y, 1.0, 0.0001)

	# Restore config values
	GameState.current_branch = orig_current_branch

func test_multivalued_log():
	# Save original config values to restore them later
	var orig_current_branch = GameState.current_branch

	# Test 1: branch 0, z = e
	GameState.current_branch = 0
	var res1 = ComplexFieldScript.multivalued_log(2.718281828459, 0.0)
	assert_almost_eq(res1.x, 1.0, 0.0001)
	assert_almost_eq(res1.y, 0.0, 0.0001)

	# Test 2: branch 1, z = e
	GameState.current_branch = 1
	var res2 = ComplexFieldScript.multivalued_log(2.718281828459, 0.0)
	assert_almost_eq(res2.x, 1.0, 0.0001)
	assert_almost_eq(res2.y, 2.0 * PI, 0.0001)

	# Test 3: branch 2, z = e
	GameState.current_branch = 2
	var res3 = ComplexFieldScript.multivalued_log(2.718281828459, 0.0)
	assert_almost_eq(res3.x, 1.0, 0.0001)
	assert_almost_eq(res3.y, 4.0 * PI, 0.0001)

	# Restore config values
	GameState.current_branch = orig_current_branch

func test_multivalued_asin_exact_values():
	var orig_branch = GameState.current_branch

	var expected_values = {
		-2: Vector2(-4.7213, 0.9625),
		-1: Vector2(-4.7034, -0.9625),
		0: Vector2(1.5619, 0.9625),
		1: Vector2(1.5797, -0.9625),
		2: Vector2(7.8450, 0.9625)
	}

	for B in expected_values.keys():
		GameState.current_branch = B
		var res = ComplexFieldScript.multivalued_asin(1.5, 0.01)
		var expected = expected_values[B]
		assert_almost_eq(res.x, expected.x, 0.005)
		assert_almost_eq(res.y, expected.y, 0.005)

	GameState.current_branch = orig_branch

func test_multivalued_asin_continuity():
	var orig_branch = GameState.current_branch

	for B in [-2, -1, 0, 1, 2]:
		GameState.current_branch = B
		var val_above = ComplexFieldScript.multivalued_asin(1.5, 0.01)

		var B_next_pos = B + 1 if B % 2 == 0 else B - 1
		GameState.current_branch = B_next_pos
		var val_below = ComplexFieldScript.multivalued_asin(1.5, -0.01)

		assert_almost_eq(val_above.x, val_below.x, 0.05)
		assert_almost_eq(val_above.y, val_below.y, 0.05)

	for B in [-2, -1, 0, 1, 2]:
		GameState.current_branch = B
		var val_above = ComplexFieldScript.multivalued_asin(-1.5, 0.01)

		var B_next_neg = B - 1 if B % 2 == 0 else B + 1
		GameState.current_branch = B_next_neg
		var val_below = ComplexFieldScript.multivalued_asin(-1.5, -0.01)

		assert_almost_eq(val_above.x, val_below.x, 0.05)
		assert_almost_eq(val_above.y, val_below.y, 0.05)

	GameState.current_branch = orig_branch

func test_multivalued_acos_continuity():
	var orig_branch = GameState.current_branch

	for B in [-2, -1, 0, 1, 2]:
		GameState.current_branch = B
		var val_above = ComplexFieldScript.multivalued_acos(1.5, 0.01)

		var B_next_pos = B + 1 if B % 2 == 0 else B - 1
		GameState.current_branch = B_next_pos
		var val_below = ComplexFieldScript.multivalued_acos(1.5, -0.01)

		assert_almost_eq(val_above.x, val_below.x, 0.05)
		assert_almost_eq(val_above.y, val_below.y, 0.05)

	for B in [-2, -1, 0, 1, 2]:
		GameState.current_branch = B
		var val_above = ComplexFieldScript.multivalued_acos(-1.5, 0.01)

		var B_next_neg = B - 1 if B % 2 == 0 else B + 1
		GameState.current_branch = B_next_neg
		var val_below = ComplexFieldScript.multivalued_acos(-1.5, -0.01)

		assert_almost_eq(val_above.x, val_below.x, 0.05)
		assert_almost_eq(val_above.y, val_below.y, 0.05)

	GameState.current_branch = orig_branch

func test_get_height_from_field():
	var orig_height_type = Config.height_type
	var orig_height_a = Config.height_a
	var orig_height_epsilon = Config.height_epsilon
	var orig_morph_value = GameState.morph_value
	var orig_effective_zoom = GameState.effective_zoom

	# Test 1: Non-finite inputs
	var res1 = ComplexFieldScript.get_height_from_field(Vector2(INF, 0))
	assert_almost_eq(res1, 0.0, 0.0001)

	var res2 = ComplexFieldScript.get_height_from_field(Vector2(NAN, 0))
	assert_almost_eq(res2, 0.0, 0.0001)

	# Test 2: height_type = 1 (Logarithmic), morph_value = 1.0
	Config.height_type = 1
	Config.height_a = 3.0
	Config.height_epsilon = 1.0
	GameState.morph_value = 1.0
	GameState.effective_zoom = 1.0
	var f3 = Vector2(3, 4) # mag = 5
	# log(1.0 + 5) = log(6) ~ 1.791759 * 3.0 = 5.375278
	var expected_log = 3.0 * log(6.0)
	var res3 = ComplexFieldScript.get_height_from_field(f3)
	assert_almost_eq(res3, expected_log, 0.0001)

	# Test 3: height_type = 0 (Linear), morph_value = 1.0
	Config.height_type = 0
	var expected_linear = 5.0
	var res4 = ComplexFieldScript.get_height_from_field(f3)
	assert_almost_eq(res4, expected_linear, 0.0001)

	# Test 4: height_type = 2 (Im(f)), morph_value = 1.0
	Config.height_type = 2
	var expected_im = 4.0
	var res_im = ComplexFieldScript.get_height_from_field(f3)
	assert_almost_eq(res_im, expected_im, 0.0001)

	# Test 5: height_type = 3 (Re(f)), morph_value = 1.0
	Config.height_type = 3
	var expected_re = 3.0
	var res_re = ComplexFieldScript.get_height_from_field(f3)
	assert_almost_eq(res_re, expected_re, 0.0001)

	# Test negative values for Im(f) and Re(f)
	var f4 = Vector2(-2, -7)
	Config.height_type = 2
	assert_almost_eq(ComplexFieldScript.get_height_from_field(f4), -7.0, 0.0001)
	Config.height_type = 3
	assert_almost_eq(ComplexFieldScript.get_height_from_field(f4), -2.0, 0.0001)

	# Test 6: Morph and zoom scaling
	Config.height_type = 0
	GameState.morph_value = 0.5
	GameState.effective_zoom = 2.0
	# s = 0.5 - 0.5 * cos(PI * 0.5) = 0.5 - 0.5 * 0 = 0.5
	# blend = log(1.0 + 8.0 * 0.5) / log(9.0) = log(5.0) / log(9.0) ~ 0.732486
	# height = expected_linear * blend * effective_zoom
	var expected_blend = log(5.0) / log(9.0)
	var expected_scaled = 5.0 * expected_blend * 2.0
	var res5 = ComplexFieldScript.get_height_from_field(f3)
	assert_almost_eq(res5, expected_scaled, 0.0001)

	# Test 7: Clamping height to [-1e5, 1e5]
	Config.height_type = 2
	GameState.morph_value = 1.0
	GameState.effective_zoom = 1.0
	var f_huge_neg = Vector2(0.0, -200000.0)
	var res_clamped_neg = ComplexFieldScript.get_height_from_field(f_huge_neg)
	assert_almost_eq(res_clamped_neg, -100000.0, 0.0001)

	var f_huge_pos = Vector2(0.0, 200000.0)
	var res_clamped_pos = ComplexFieldScript.get_height_from_field(f_huge_pos)
	assert_almost_eq(res_clamped_pos, 100000.0, 0.0001)

	# Test 8: Projected Complex Component (height_type = 4)
	var orig_theta = Config.height_theta
	Config.height_type = 4
	GameState.morph_value = 1.0
	GameState.effective_zoom = 1.0
	Config.height_theta = PI / 4.0
	# f = (3, 4) -> 3 * cos(PI/4) + 4 * sin(PI/4) = 7 * sqrt(2)/2 = 4.949747
	var res_projected = ComplexFieldScript.get_height_from_field(f3)
	assert_almost_eq(res_projected, 7.0 * sqrt(2.0) / 2.0, 0.0001)
	Config.height_theta = orig_theta

	# Test 9: Flat (height_type = 5)
	Config.height_type = 5
	GameState.morph_value = 1.0
	GameState.effective_zoom = 1.0
	var res_flat = ComplexFieldScript.get_height_from_field(f3)
	assert_almost_eq(res_flat, 0.0, 0.0001)

	Config.height_type = orig_height_type
	Config.height_a = orig_height_a
	Config.height_epsilon = orig_height_epsilon
	GameState.morph_value = orig_morph_value
	GameState.effective_zoom = orig_effective_zoom

func test_get_height():
	var orig_perf = GameState.performance_protection_active
	var orig_func = Config.function_type
	var orig_zoom = GameState.effective_zoom
	var orig_type = Config.height_type
	var orig_morph = GameState.morph_value

	Config.set("function_type", Config.ComplexFunc.ZETA_REFLECTION)
	Config.iterations = 2000
	GameState.effective_zoom = 1.0
	Config.height_type = 0 # linear height
	GameState.morph_value = 1.0 # blend = 1.0

	# Test performance protection early exit
	GameState.performance_protection_active = true
	var h1 = ComplexFieldScript.get_height(0.0, 0.0)
	assert_eq(h1, 0.0)

	GameState.performance_protection_active = false

	# world_x=1.0, world_z=0 -> x=0.1, t=0 -> zeta(0.1, 0) = -0.603038
	# mag = 0.603038
	# height_type = 1 -> h = 0.603038 * 1.0 * 1.0 = 0.603038
	var world_pos = Vector2(1.0, 0.0)
	var h2 = ComplexFieldScript.get_height(world_pos.x, world_pos.y)
	assert_almost_eq(h2, 0.603038, 0.001)

	GameState.performance_protection_active = orig_perf
	Config.set("function_type", orig_func)
	GameState.effective_zoom = orig_zoom
	Config.height_type = orig_type
	GameState.morph_value = orig_morph

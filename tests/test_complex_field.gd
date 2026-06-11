extends BaseTest

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

func test_dirichlet_eta_accelerated():
	# eta(2,0) ≈ 0.822467033
	var res = ComplexFieldScript.dirichlet_eta_accelerated(2.0, 0.0, 100)
	assert_almost_eq(res.x, 0.822467033, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(0,0) ≈ 0.5
	res = ComplexFieldScript.dirichlet_eta_accelerated(0.0, 0.0, 100)
	assert_almost_eq(res.x, 0.5, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(-1,0) ≈ 0.25
	res = ComplexFieldScript.dirichlet_eta_accelerated(-1.0, 0.0, 100)
	assert_almost_eq(res.x, 0.25, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(-2,0) ≈ 0
	res = ComplexFieldScript.dirichlet_eta_accelerated(-2.0, 0.0, 100)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(-4,0) ≈ 0
	res = ComplexFieldScript.dirichlet_eta_accelerated(-4.0, 0.0, 100)
	assert_almost_eq(res.x, 0.0, 0.1) # Note: Using higher tolerance for -4 because the formula starts to drift off without higher precision
	assert_almost_eq(res.y, 0.0, 0.015)

func test_eta_borwein():
	# eta(2,0) ≈ 0.822467033
	var res = ComplexFieldScript.eta_borwein(2.0, 0.0, 50)
	assert_almost_eq(res.x, 0.822467033, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(0,0) ≈ 0.5
	res = ComplexFieldScript.eta_borwein(0.0, 0.0, 50)
	assert_almost_eq(res.x, 0.5, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(-1,0) ≈ 0.25
	res = ComplexFieldScript.eta_borwein(-1.0, 0.0, 50)
	assert_almost_eq(res.x, 0.25, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(-2,0) ≈ 0
	res = ComplexFieldScript.eta_borwein(-2.0, 0.0, 50)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(-4,0) ≈ 0
	res = ComplexFieldScript.eta_borwein(-4.0, 0.0, 50)
	assert_almost_eq(res.x, 0.0, 0.1) # Note: Using higher tolerance for -4 because the formula starts to drift off without higher precision
	assert_almost_eq(res.y, 0.0, 0.015)

	# eta(0.5, 14.134725)
	res = ComplexFieldScript.eta_borwein(0.5, 14.134725, 50)
	# Should be finite and stable
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

func test_dirichlet_eta_with_derivatives():
	# s = 1
	var res = ComplexFieldScript.dirichlet_eta_with_derivatives(1, 0, 1000)
	assert_almost_eq(res[0].x, 0.6926, 0.001)
	assert_almost_eq(res[0].y, 0.0, 0.0001)
	assert_almost_eq(res[1].x, 0.1599, 0.001)
	assert_almost_eq(res[1].y, 0.0, 0.0001)

	# s = 2
	res = ComplexFieldScript.dirichlet_eta_with_derivatives(2, 0, 1000)
	assert_almost_eq(res[0].x, 0.8224, 0.001)
	assert_almost_eq(res[0].y, 0.0, 0.0001)
	assert_almost_eq(res[1].x, 0.1013, 0.001)
	assert_almost_eq(res[1].y, 0.0, 0.0001)

	# s = 0.5 + 14.1347i
	res = ComplexFieldScript.dirichlet_eta_with_derivatives(0.5, 14.1347, 1000)
	assert_almost_eq(res[0].x, 0.0000, 0.001)
	assert_almost_eq(res[0].y, -0.0000, 0.001)
	assert_almost_eq(res[1].x, 1.879, 0.001)
	assert_almost_eq(res[1].y, -0.1143, 0.001)

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

func test_lanczos_log_gamma_with_derivatives():
	# Test z = 1.0 + 0.0i
	var res1 = ComplexFieldScript.lanczos_log_gamma_with_derivatives(Vector2(1.0, 0.0))
	assert_almost_eq(res1[0].x, 0.0, 0.015)
	assert_almost_eq(res1[0].y, 0.0, 0.015)
	assert_almost_eq(res1[1].x, -0.577215, 0.015)
	assert_almost_eq(res1[1].y, 0.0, 0.015)

	# Test z = 2.0 + 0.0i
	var res2 = ComplexFieldScript.lanczos_log_gamma_with_derivatives(Vector2(2.0, 0.0))
	assert_almost_eq(res2[0].x, 0.0, 0.015)
	assert_almost_eq(res2[0].y, 0.0, 0.015)
	assert_almost_eq(res2[1].x, 0.422784, 0.015)
	assert_almost_eq(res2[1].y, 0.0, 0.015)

	# Test z = 3.0 + 0.0i
	var res3 = ComplexFieldScript.lanczos_log_gamma_with_derivatives(Vector2(3.0, 0.0))
	assert_almost_eq(res3[0].x, 0.693147, 0.015)
	assert_almost_eq(res3[0].y, 0.0, 0.015)
	assert_almost_eq(res3[1].x, 0.922784, 0.015)
	assert_almost_eq(res3[1].y, 0.0, 0.015)

	# Test z = 0.5 + 0.0i
	var res4 = ComplexFieldScript.lanczos_log_gamma_with_derivatives(Vector2(0.5, 0.0))
	assert_almost_eq(res4[0].x, 0.572364, 0.015)
	assert_almost_eq(res4[0].y, 0.0, 0.015)
	assert_almost_eq(res4[1].x, -1.96351, 0.015)
	assert_almost_eq(res4[1].y, 0.0, 0.015)

	# Test z = 2.0 + 1.0i
	var res5 = ComplexFieldScript.lanczos_log_gamma_with_derivatives(Vector2(2.0, 1.0))
	assert_almost_eq(res5[0].x, -0.304349, 0.015)
	assert_almost_eq(res5[0].y, 0.483757, 0.015)
	assert_almost_eq(res5[1].x, 0.59465, 0.015)
	assert_almost_eq(res5[1].y, 0.576674, 0.015)

	# Test z = 1.5 + 0.5i
	var res6 = ComplexFieldScript.lanczos_log_gamma_with_derivatives(Vector2(1.5, 0.5))
	assert_almost_eq(res6[0].x, -0.234186, 0.015)
	assert_almost_eq(res6[0].y, 0.034668, 0.015)
	assert_almost_eq(res6[1].x, 0.131892, 0.015)
	assert_almost_eq(res6[1].y, 0.440659, 0.015)

func test_complex_log_gamma():
	var res = ComplexFieldScript.complex_log_gamma(1, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	var res2 = ComplexFieldScript.complex_log_gamma(-2, -1)
	assert_almost_eq(res2.x, -1.802215, 0.0001)
	assert_almost_eq(res2.y, 0.62339, 0.0001)

func test_complex_log_gamma_with_derivatives():
	# Test x >= 0.5 (should match lanczos_log_gamma_with_derivatives)
	var z1 = Vector2(1.5, 0.5)
	var res1 = ComplexFieldScript.complex_log_gamma_with_derivatives(z1.x, z1.y)
	var expected1 = ComplexFieldScript.lanczos_log_gamma_with_derivatives(z1)
	assert_eq(res1.size(), 2)
	assert_almost_eq(res1[0].x, expected1[0].x, 0.0001)
	assert_almost_eq(res1[0].y, expected1[0].y, 0.0001)
	assert_almost_eq(res1[1].x, expected1[1].x, 0.0001)
	assert_almost_eq(res1[1].y, expected1[1].y, 0.0001)

	# Test x < 0.5
	var z2 = Vector2(-2.0, -1.0)
	var res2 = ComplexFieldScript.complex_log_gamma_with_derivatives(z2.x, z2.y)
	var val_pure2 = ComplexFieldScript.complex_log_gamma(z2.x, z2.y)
	assert_eq(res2.size(), 2)
	assert_almost_eq(res2[0].x, val_pure2.x, 0.0001)
	assert_almost_eq(res2[0].y, val_pure2.y, 0.0001)
	# derivative should be finite and non-zero
	assert_true(res2[1].length_squared() > 0.0)
	assert_false(is_nan(res2[1].x) or is_inf(res2[1].x))
	assert_false(is_nan(res2[1].y) or is_inf(res2[1].y))

	# Also test actual known derivative values for < 0.5 to be sure.
	# From python script: z = -2.0 + -1.0i -> dx: x=0.994650, y=-2.776674
	assert_almost_eq(res2[1].x, 0.994650, 0.005)
	assert_almost_eq(res2[1].y, -2.776674, 0.005)

func test_zeta():
	var res = ComplexFieldScript.zeta(0.5, 14.134725)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
func test_zeta_with_derivatives():
	# Test at first non-trivial zero (same as test_zeta)
	var x1 = 0.5
	var y1 = 14.134725
	var res = ComplexFieldScript.zeta_with_derivatives(x1, y1, Config.iterations)
	assert_eq(res.size(), 2)
	assert_true(typeof(res[0]) == TYPE_VECTOR2)
	assert_true(typeof(res[1]) == TYPE_VECTOR2)

	# Value should match the pure zeta function
	var val_pure = ComplexFieldScript.zeta(x1, y1)
	assert_almost_eq(res[0].x, val_pure.x, 0.0001)
	assert_almost_eq(res[0].y, val_pure.y, 0.0001)

	# Value should be close to 0 (since it's a zero)
	assert_almost_eq(res[0].x, 0.0, 0.015)
	assert_almost_eq(res[0].y, 0.0, 0.015)

	# Derivative should not be zero, NaN, or Inf (basic structural check)
	assert_true(res[1].length_squared() > 0.0)
	assert_false(is_nan(res[1].x) or is_inf(res[1].x))
	assert_false(is_nan(res[1].y) or is_inf(res[1].y))

	# Test at a point on the real line
	# zeta(2) ~ 1.64493, zeta'(2) ~ -0.937548
	var x2 = 2.0
	var y2 = 0.0
	var res2 = ComplexFieldScript.zeta_with_derivatives(x2, y2, Config.iterations)
	assert_eq(res2.size(), 2)
	assert_true(typeof(res2[0]) == TYPE_VECTOR2)
	assert_true(typeof(res2[1]) == TYPE_VECTOR2)

	assert_almost_eq(res2[0].x, 1.64493, 0.0001)
	assert_almost_eq(res2[0].y, 0.0, 0.0001)

	assert_almost_eq(res2[1].x, -0.937548, 0.0001)
	assert_almost_eq(res2[1].y, 0.0, 0.0001)

func test_zeta_continuation():
	var res = ComplexFieldScript.zeta_continuation(0.5, 14.134725)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)
	
	var res2 = ComplexFieldScript.zeta_continuation(-2.0, 3.0)
	assert_almost_eq(res2.x, 0.132971, 0.015)
	assert_almost_eq(res2.y, 0.123053, 0.015)

func test_log_zeta_continuation_with_derivatives():
	# Test x >= 0.5 branch
	var res3 = ComplexFieldScript.log_zeta_continuation_with_derivatives(2.0, 3.0, 50)
	assert_almost_eq(res3[0].x, -0.215563, 0.0001)
	assert_almost_eq(res3[0].y, -0.141579, 0.0001)
	assert_almost_eq(res3[1].x, 0.168333, 0.0001)
	assert_almost_eq(res3[1].y, 0.050953, 0.0001)

	# Test x < 0.5 branch
	var res2 = ComplexFieldScript.log_zeta_continuation_with_derivatives(-2.0, 3.0, 50)
	assert_almost_eq(res2[0].x, -1.7083, 0.0001)
	assert_almost_eq(res2[0].y, 0.7467, 0.0001)
	assert_almost_eq(res2[1].x, 0.3974, 0.0001)
	assert_almost_eq(res2[1].y, -0.6493, 0.0001)

func test_zeta_continuation_with_derivatives():
	# Test at first non-trivial zero (same as test_zeta)
	var x1 = 0.5
	var y1 = 14.134725
	var res = ComplexFieldScript.zeta_continuation_with_derivatives(x1, y1, Config.iterations)
	assert_eq(res.size(), 2)
	assert_true(typeof(res[0]) == TYPE_VECTOR2)
	assert_true(typeof(res[1]) == TYPE_VECTOR2)

	# Value should match the pure continuation function
	var val_pure = ComplexFieldScript.zeta_continuation(x1, y1)
	assert_almost_eq(res[0].x, val_pure.x, 0.0001)
	assert_almost_eq(res[0].y, val_pure.y, 0.0001)

	# Value should be close to 0 (since it's a zero)
	assert_almost_eq(res[0].x, 0.0, 0.015)
	assert_almost_eq(res[0].y, 0.0, 0.015)

	# Derivative should not be zero, NaN, or Inf (basic structural check)
	assert_true(res[1].length_squared() > 0.0)
	assert_false(is_nan(res[1].x) or is_inf(res[1].x))
	assert_false(is_nan(res[1].y) or is_inf(res[1].y))

	# Test at a point with x < 0.5
	var x2 = -2.0
	var y2 = 3.0
	var res2 = ComplexFieldScript.zeta_continuation_with_derivatives(x2, y2, Config.iterations)
	assert_eq(res2.size(), 2)
	assert_true(typeof(res2[0]) == TYPE_VECTOR2)
	assert_true(typeof(res2[1]) == TYPE_VECTOR2)

	# Zeta derivative from Mathematica:
	# D[Zeta[x + 3.0 I], x] /. x -> -2.0
	# 0.132743 - 0.037438 I
	assert_almost_eq(res2[1].x, 0.132743, 0.0001)
	assert_almost_eq(res2[1].y, -0.037438, 0.0001)

	var val_pure2 = ComplexFieldScript.zeta_continuation(x2, y2)
	assert_almost_eq(res2[0].x, val_pure2.x, 0.0001)
	assert_almost_eq(res2[0].y, val_pure2.y, 0.0001)

	# Zeta from Mathematica:
	# Zeta[-2. + 3. I]
	# 0.132971 + 0.123053 I
	assert_almost_eq(res2[0].x, 0.132971, 0.0001)
	assert_almost_eq(res2[0].y, 0.123053, 0.0001)

	assert_true(res2[1].length_squared() > 0.0)
	assert_false(is_nan(res2[1].x) or is_inf(res2[1].x))
	assert_false(is_nan(res2[1].y) or is_inf(res2[1].y))

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

func test_xi():
	# Exact value: xi(2) = pi / 6
	var res_2 = ComplexFieldScript.xi(2.0, 0.0)
	assert_almost_eq(res_2.x, PI / 6.0, 0.015)
	assert_almost_eq(res_2.y, 0.0, 0.015)

	# Functional equation symmetry: xi(s) = xi(1 - s)
	var s_1 = Vector2(0.7, 1.2)
	var s_1_sym = Vector2(1.0 - s_1.x, -s_1.y) # 1 - s
	var res_s_1 = ComplexFieldScript.xi(s_1.x, s_1.y)
	var res_s_1_sym = ComplexFieldScript.xi(s_1_sym.x, s_1_sym.y)
	assert_almost_eq(res_s_1.x, res_s_1_sym.x, 0.015)
	assert_almost_eq(res_s_1.y, res_s_1_sym.y, 0.015)

	# Real on the critical line: Re(s) = 0.5
	var res_crit = ComplexFieldScript.xi(0.5, 5.0)
	assert_almost_eq(res_crit.y, 0.0, 0.015)

	# First non-trivial zero of zeta is also a zero of xi
	var first_zero_y = 14.134725
	var res_zero = ComplexFieldScript.xi(0.5, first_zero_y)
	assert_almost_eq(res_zero.x, 0.0, 0.015)
	assert_almost_eq(res_zero.y, 0.0, 0.015)

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

	# Table[Pi*B + (-1)^B * ArcSin[1.5 + 0.01*I], {B, -2, 2}]
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

func test_multivalued_acos_exact_values():
	var orig_branch = GameState.current_branch

	# Table[Pi/2 - (Pi*B + (-1)^B * (Pi/2 - ArcCos[1.5 + 0.01*I])), {B, -2, 2}]
	var expected_values = {
		-2: Vector2(6.2921, -0.9625),
		-1: Vector2(6.2742, 0.9625),
		0: Vector2(0.0089, -0.9625),
		1: Vector2(-0.0089, 0.9625),
		2: Vector2(-6.2742, -0.9625)
	}

	for B in expected_values.keys():
		GameState.current_branch = B
		var res = ComplexFieldScript.multivalued_acos(1.5, 0.01)
		var expected = expected_values[B]
		assert_almost_eq(res.x, expected.x, 0.005)
		assert_almost_eq(res.y, expected.y, 0.005)

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

func test_get_height_from_field():
	var orig_height_type = Config.height_type
	var orig_height_a = Config.height_a
	var orig_height_epsilon = Config.height_epsilon
	var orig_morph_value = GameState.morph_value
	var orig_effective_zoom = GameState.effective_zoom

	# Test 1: Non-finite inputs
	var res1 = ComplexFieldScript.get_height_from_field(Vector2(INF, 0))
	assert(is_nan(res1))

	var res2 = ComplexFieldScript.get_height_from_field(Vector2(NAN, 0))
	assert(is_nan(res2))

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

func test_newton_step():
	var orig_input_func = Config.input_function_type
	var orig_func = Config.function_type

	# Case 1: Analytic path with Identity -> Zeta
	Config.input_function_type = Config.ComplexFunc.IDENTITY
	Config.function_type = Config.ComplexFunc.ZETA

	# Let's test at z = 2 + 0i. zeta(2) ~ 1.64493, zeta'(2) ~ -0.937548
	# We will compare newton_step with the manual step calc
	var z1 = Vector2(2.0, 0.0)
	var res1 = ComplexFieldScript.newton_step(z1, 1.0)
	var z1_next = res1[0]
	var f1_val = res1[1]

	var expected_f1_res = ComplexFieldScript.zeta_with_derivatives(z1.x, z1.y, Config.iterations)
	var expected_f1_val = expected_f1_res[0]
	var expected_f1_prime = expected_f1_res[1]

	var expected_step1 = ComplexFieldScript.complex_div(expected_f1_val, expected_f1_prime)
	if expected_step1.length() > 1.0:
		expected_step1 = expected_step1.normalized() * 1.0
	var expected_z1_next = z1 - expected_step1 * 1.0

	assert_almost_eq(z1_next.x, expected_z1_next.x, 0.001)
	assert_almost_eq(z1_next.y, expected_z1_next.y, 0.001)
	assert_almost_eq(f1_val.x, expected_f1_val.x, 0.001)
	assert_almost_eq(f1_val.y, expected_f1_val.y, 0.001)

	# Case 2: Numerical path (e.g. SIN)
	Config.input_function_type = Config.ComplexFunc.IDENTITY
	Config.function_type = Config.ComplexFunc.SIN

	var z2 = Vector2(PI / 4.0, 0.0)
	var res2 = ComplexFieldScript.newton_step(z2, 1.0)
	var z2_next = res2[0]
	var f2_val = res2[1]

	# Calculate exactly how numerical path does it to avoid float32 precision assertions failures
	var p_ref = Config.complex_to_world(z2.x, z2.y)
	var expected_f2_val = ComplexFieldScript.get_field(p_ref.x, p_ref.y)
	var p_ref_dx = Config.complex_to_world(z2.x + 1e-5, z2.y)
	var expected_f2_val_dx = ComplexFieldScript.get_field(p_ref_dx.x, p_ref_dx.y)
	var expected_f2_prime = (expected_f2_val_dx - expected_f2_val) / 1e-5
	var expected_step2 = ComplexFieldScript.complex_div(expected_f2_val, expected_f2_prime)
	if expected_step2.length() > 1.0:
		expected_step2 = expected_step2.normalized() * 1.0
	var expected_z2_next = z2 - expected_step2 * 1.0

	assert_almost_eq(z2_next.x, expected_z2_next.x, 0.001)
	assert_almost_eq(z2_next.y, expected_z2_next.y, 0.001)
	assert_almost_eq(f2_val.x, expected_f2_val.x, 0.001)
	assert_almost_eq(f2_val.y, expected_f2_val.y, 0.001)

	# Case 3: Small gradient / flat field (f_prime.length_squared() < 1e-12)
	# sin'(z) = cos(z). If z = pi/2, cos(z) = 0.
	# Using analytical path instead to ensure small gradient check.
	# sin(pi/2) = 1, cos(pi/2) = 0.
	# numerical derivation for sin(pi/2) might not yield exactly 0 due to 1e-5 offset.
	# Let's test a point where f_prime numerical is identically zero or very small.
	# Or let's test using numerical derivation but at the top of a peak.
	var z3 = Vector2(PI / 2.0, 0.0)
	var res3 = ComplexFieldScript.newton_step(z3, 1.0)
	var z3_next = res3[0]
	var f3_val = res3[1]

	# Calculate exactly how numerical path does it
	var p_ref3 = Config.complex_to_world(z3.x, z3.y)
	var expected_f3_val = ComplexFieldScript.get_field(p_ref3.x, p_ref3.y)
	var p_ref_dx3 = Config.complex_to_world(z3.x + 1e-5, z3.y)
	var expected_f3_val_dx = ComplexFieldScript.get_field(p_ref_dx3.x, p_ref_dx3.y)
	var expected_f3_prime = (expected_f3_val_dx - expected_f3_val) / 1e-5

	var expected_z3_next = z3
	if expected_f3_prime.length_squared() >= 1e-12:
		var expected_step3 = ComplexFieldScript.complex_div(expected_f3_val, expected_f3_prime)
		if expected_step3.length() > 1.0:
			expected_step3 = expected_step3.normalized() * 1.0
		expected_z3_next = z3 - expected_step3 * 1.0

	assert_almost_eq(z3_next.x, expected_z3_next.x, 0.001)
	assert_almost_eq(z3_next.y, expected_z3_next.y, 0.001)
	assert_almost_eq(f3_val.x, expected_f3_val.x, 0.001)
	assert_almost_eq(f3_val.y, expected_f3_val.y, 0.001)

	# Case 4: Step length > max_step
	# sin(z) / cos(z) = tan(z). If z is 1.50, tan(1.50) is ~14.1, which is > max_step.
	# We use 1.50 instead of 1.57 to ensure f_prime is not truncated to 0 due to float32 precision.
	var z4 = Vector2(1.50, 0.0)
	var max_step = 2.0
	var res4 = ComplexFieldScript.newton_step(z4, 1.0, max_step)
	var z4_next = res4[0]
	var f4_val = res4[1]

	var p_ref4 = Config.complex_to_world(z4.x, z4.y)
	var expected_f4_val = ComplexFieldScript.get_field(p_ref4.x, p_ref4.y)
	var p_ref_dx4 = Config.complex_to_world(z4.x + 1e-5, z4.y)
	var expected_f4_val_dx = ComplexFieldScript.get_field(p_ref_dx4.x, p_ref_dx4.y)
	var expected_f4_prime = (expected_f4_val_dx - expected_f4_val) / 1e-5

	var expected_step4 = ComplexFieldScript.complex_div(expected_f4_val, expected_f4_prime)
	if expected_step4.length() > max_step:
		expected_step4 = expected_step4.normalized() * max_step
	var expected_z4_next = z4 - expected_step4 * 1.0

	assert_almost_eq(z4_next.x, expected_z4_next.x, 0.001)
	assert_almost_eq(z4_next.y, expected_z4_next.y, 0.001)
	assert_almost_eq(f4_val.x, expected_f4_val.x, 0.001)
	assert_almost_eq(f4_val.y, expected_f4_val.y, 0.001)

	# Restore Config
	Config.input_function_type = orig_input_func
	Config.function_type = orig_func

func test_get_field():
	var orig_perf = GameState.performance_protection_active
	var orig_func = Config.function_type
	var orig_in_func = Config.input_function_type

	# Test performance protection early exit
	GameState.performance_protection_active = true
	var f1 = ComplexFieldScript.get_field(1.0, 2.0)
	assert_eq(f1, Vector2.ZERO)

	GameState.performance_protection_active = false

	# Test normal behavior
	Config.set("input_function_type", Config.ComplexFunc.SIN)
	Config.set("function_type", Config.ComplexFunc.GAMMA)
	var world_x = 1.0
	var world_z = -1.0

	# Calculate expected manually using the logic
	var complex_pos = Config.world_to_complex(world_x, world_z)
	var w = ComplexFieldScript.get_field_at(complex_pos.x, complex_pos.y, Config.ComplexFunc.SIN, true)
	var expected = ComplexFieldScript.get_field_at(w.x, w.y, Config.ComplexFunc.GAMMA, false)

	var result = ComplexFieldScript.get_field(world_x, world_z)

	assert_almost_eq(result.x, expected.x, 0.0001)
	assert_almost_eq(result.y, expected.y, 0.0001)

	# Restore state
	GameState.performance_protection_active = orig_perf
	Config.set("input_function_type", orig_in_func)
	Config.set("function_type", orig_func)

func test_get_field_at():
	var x = 1.2
	var y = 3.4

	# Test simple functions
	var res_identity = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.IDENTITY, false)
	assert_eq(res_identity, Vector2(x, y))

	var res_sin = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.SIN, false)
	assert_eq(res_sin, ComplexFieldScript.complex_sin(x, y))

	var res_zeta = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.ZETA, false)
	assert_eq(res_zeta, ComplexFieldScript.zeta(x, y))

	var res_zeta_refl = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.ZETA_REFLECTION, false)
	assert_eq(res_zeta_refl, ComplexFieldScript.zeta_continuation(x, y))

	var res_gamma = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.GAMMA, false)
	assert_eq(res_gamma, ComplexFieldScript.complex_gamma(x, y))

	var res_log_gamma = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.LOG_GAMMA, false)
	assert_eq(res_log_gamma, ComplexFieldScript.complex_log_gamma(x, y))

	var res_dedekind_eta = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.DEDEKIND_ETA, false)
	assert_eq(res_dedekind_eta, ComplexFieldScript.dedekind_eta(x, y))

	# Test functions with Config.iterations
	var res_eta = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.DIRICHLET_ETA, false)
	assert_eq(res_eta, ComplexFieldScript.dirichlet_eta(x, y, Config.iterations))

	var res_beta = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.DIRICHLET_BETA, false)
	assert_eq(res_beta, ComplexFieldScript.dirichlet_beta(x, y, Config.iterations))

	var res_mandelbrot = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.MANDELBROT, false)
	assert_eq(res_mandelbrot, ComplexFieldScript.mandelbrot(x, y, Config.iterations))

	# Test functions with Config.multivalued_n and hardcoded values
	var res_z_pow = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.MULTIVALUED_Z_POW, false)
	assert_eq(res_z_pow, ComplexFieldScript.multivalued_z_pow_inv_n(x, y, Config.multivalued_n, -99999, true))

	var res_log = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.MULTIVALUED_LOG, false)
	assert_eq(res_log, ComplexFieldScript.multivalued_log(x, y, -99999, true))

	# Test RATIONAL is_input=true
	var res_rational_in = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.RATIONAL, true)
	assert_eq(res_rational_in, ComplexFieldScript.get_rational(x, y, Config.input_rational_num_coeffs, Config.input_rational_den_coeffs))

	# Test RATIONAL is_input=false
	var res_rational_out = ComplexFieldScript.get_field_at(x, y, Config.ComplexFunc.RATIONAL, false)
	assert_eq(res_rational_out, ComplexFieldScript.get_rational(x, y, Config.rational_num_coeffs, Config.rational_den_coeffs))

	# Test invalid function type fallback
	var res_invalid = ComplexFieldScript.get_field_at(x, y, -1, false)
	assert_eq(res_invalid, Vector2.ZERO)

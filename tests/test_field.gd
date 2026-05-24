extends GutTest

const Field = preload("res://scripts/field.gd")

func test_complex_mul():
	var z1 = Vector2(1, 2)
	var z2 = Vector2(3, 4)
	var res = Field.complex_mul(z1, z2)
	assert_eq(res, Vector2(-5, 10))

func test_complex_div():
	var z1 = Vector2(5, 7)
	var z2 = Vector2(2, 3)
	var res = Field.complex_div(z1, z2)
	assert_almost_eq(res.x, 31.0/13.0, 0.0001)
	assert_almost_eq(res.y, -1.0/13.0, 0.0001)

func test_complex_exp():
	var res = Field.complex_exp(0, PI)
	assert_almost_eq(res.x, -1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = Field.complex_exp(0, PI/2)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 1.0, 0.0001)

func test_complex_log():
	var res = Field.complex_log(1, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = Field.complex_log(0, 1)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, PI/2, 0.0001)

func test_complex_pow():
	var res = Field.complex_pow(Vector2(2, 0), Vector2(3, 0))
	assert_almost_eq(res.x, 8.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = Field.complex_pow(Vector2(0, 1), Vector2(2, 0))
	assert_almost_eq(res.x, -1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_sin():
	var res = Field.complex_sin(0, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = Field.complex_sin(PI/2, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cos():
	var res = Field.complex_cos(0, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

	res = Field.complex_cos(PI/2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_tan():
	var res = Field.complex_tan(0, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_cot():
	var res = Field.complex_cot(PI/2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_log_sin():
	var res = Field.complex_log_sin(PI/2, 0)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_eta():
	var res = Field.dirichlet_eta(1, 0, 100)
	assert_almost_eq(res.x, log(2.0), 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_dirichlet_beta():
	var res = Field.dirichlet_beta(1, 0, 100)
	assert_almost_eq(res.x, PI/4, 0.01)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_evaluate_poly():
	var coeffs = PackedVector2Array([Vector2(1, 0), Vector2(2, 0), Vector2(3, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), Vector2(0, 0)]) # 1 + 2z + 3z^2
	var res = Field.evaluate_poly(2, 0, coeffs)
	assert_almost_eq(res.x, 17.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_complex_gamma():
	var res = Field.complex_gamma(1, 0)
	assert_almost_eq(res.x, 1.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

func test_zeta():
	var res = Field.zeta(0.5, 14.134725)
	assert_almost_eq(res.x, 0.0, 0.015)
	assert_almost_eq(res.y, 0.0, 0.015)

func test_dedekind_eta():
	var res = Field.dedekind_eta(0, 1)
	assert_almost_eq(res.x, 0.7682, 0.01)
	assert_almost_eq(res.y, 0.0, 0.01)

func test_mandelbrot():
	var res = Field.mandelbrot(0, 0, 10)
	assert_almost_eq(res.x, 0.0, 0.0001)
	assert_almost_eq(res.y, 0.0, 0.0001)

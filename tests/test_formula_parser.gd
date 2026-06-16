extends BaseTest


func test_parse_complex_empty() -> void:
	assert_eq(
		FormulaParser.parse_complex(""), Vector2.ZERO, "Empty string should return Vector2.ZERO"
	)


func test_parse_complex_pure_imaginary() -> void:
	assert_eq(FormulaParser.parse_complex("i"), Vector2(0, 1), "'i' should return (0, 1)")
	assert_eq(FormulaParser.parse_complex("-i"), Vector2(0, -1), "'-i' should return (0, -1)")
	assert_eq(FormulaParser.parse_complex("2i"), Vector2(0, 2), "'2i' should return (0, 2)")
	assert_eq(FormulaParser.parse_complex("-2i"), Vector2(0, -2), "'-2i' should return (0, -2)")
	assert_eq(
		FormulaParser.parse_complex("3.14i"), Vector2(0, 3.14), "'3.14i' should return (0, 3.14)"
	)
	assert_eq(
		FormulaParser.parse_complex("-3.14i"),
		Vector2(0, -3.14),
		"'-3.14i' should return (0, -3.14)"
	)


func test_parse_complex_pure_real() -> void:
	assert_eq(FormulaParser.parse_complex("1"), Vector2(1, 0), "'1' should return (1, 0)")
	assert_eq(FormulaParser.parse_complex("-1"), Vector2(-1, 0), "'-1' should return (-1, 0)")
	assert_eq(
		FormulaParser.parse_complex("3.14"), Vector2(3.14, 0), "'3.14' should return (3.14, 0)"
	)
	assert_eq(
		FormulaParser.parse_complex("-3.14"), Vector2(-3.14, 0), "'-3.14' should return (-3.14, 0)"
	)


func test_parse_complex_mixed() -> void:
	assert_eq(FormulaParser.parse_complex("1+2i"), Vector2(1, 2), "'1+2i' should return (1, 2)")
	assert_eq(FormulaParser.parse_complex("1-2i"), Vector2(1, -2), "'1-2i' should return (1, -2)")
	assert_eq(FormulaParser.parse_complex("-1+2i"), Vector2(-1, 2), "'-1+2i' should return (-1, 2)")
	assert_eq(
		FormulaParser.parse_complex("-1-2i"), Vector2(-1, -2), "'-1-2i' should return (-1, -2)"
	)
	assert_eq(FormulaParser.parse_complex("1+i"), Vector2(1, 1), "'1+i' should return (1, 1)")
	assert_eq(FormulaParser.parse_complex("1-i"), Vector2(1, -1), "'1-i' should return (1, -1)")
	assert_eq(FormulaParser.parse_complex("-1+i"), Vector2(-1, 1), "'-1+i' should return (-1, 1)")
	assert_eq(FormulaParser.parse_complex("-1-i"), Vector2(-1, -1), "'-1-i' should return (-1, -1)")
	assert_eq(
		FormulaParser.parse_complex("1.5+2.5i"),
		Vector2(1.5, 2.5),
		"'1.5+2.5i' should return (1.5, 2.5)"
	)
	assert_eq(
		FormulaParser.parse_complex("-1.5-2.5i"),
		Vector2(-1.5, -2.5),
		"'-1.5-2.5i' should return (-1.5, -2.5)"
	)


func test_parse_complex_formatting() -> void:
	assert_eq(FormulaParser.parse_complex(" 1 + 2 i "), Vector2(1, 2), "Spaces should be ignored")
	assert_eq(FormulaParser.parse_complex("1+2I"), Vector2(1, 2), "Capital 'I' should be handled")
	assert_eq(
		FormulaParser.parse_complex("1 + 2*i"), Vector2(1, 2), "Asterisk '*' should be ignored"
	)
	assert_eq(
		FormulaParser.parse_complex(" 1.5   -  2.5 I "),
		Vector2(1.5, -2.5),
		"Multiple spaces, capital I, and negative sign should be handled correctly"
	)

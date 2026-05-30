class_name FormulaParser
extends Object

## Parses a string representing a complex number (e.g. "1+2i", "2i", "-2i", "1-i") into a Vector2.
static func parse_complex(text: String) -> Vector2:
	text = text.replace(" ", "").replace("I", "i").replace("*", "")
	if text == "": return Vector2.ZERO

	# Handle pure imaginary "i" or "-i"
	if text == "i": return Vector2(0, 1)
	if text == "-i": return Vector2(0, -1)

	if not "i" in text:
		return Vector2(float(text), 0.0)

	# If we have "i", it might be "1+2i", "2i", "-2i", "1+i", "1-i"
	# Let's split by + and - but keep signs
	var re = 0.0
	var im = 0.0

	var normalized = text.replace("-", "+-")
	var parts = normalized.split("+", false)

	for p in parts:
		if p.ends_with("i"):
			var im_str = p.substr(0, p.length() - 1)
			if im_str == "" or im_str == "+": im += 1.0
			elif im_str == "-": im -= 1.0
			else: im += float(im_str)
		else:
			re += float(p)

	return Vector2(re, im)

## Parses a polynomial string expression (e.g. "z^3 - 2z^2 + (1+i)z - (2-i)") into coefficients.
static func parse_poly(text: String) -> PackedVector2Array:
	var coeffs = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	text = text.replace(" ", "").replace("*", "")

	# We want to split by terms. A term usually starts with + or -
	# unless it's inside parentheses.
	var terms = []
	var depth = 0
	var start_idx = 0
	for i in range(text.length()):
		var c = text[i]
		if c == "(": depth += 1
		elif c == ")": depth -= 1

		if depth == 0 and i > 0 and (c == "+" or c == "-") and text[i - 1] != "e" and text[i - 1] != "E":
			terms.append(text.substr(start_idx, i - start_idx))
			start_idx = i
	terms.append(text.substr(start_idx))

	for term in terms:
		if term == "": continue
		var coeff = Vector2(1, 0)
		var degree = 0

		if "z" in term:
			var parts = term.split("z")
			var coeff_str = parts[0]
			if coeff_str == "" or coeff_str == "+": coeff = Vector2(1, 0)
			elif coeff_str == "-": coeff = Vector2(-1, 0)
			else:
				var _sign = 1.0
				if coeff_str.begins_with("+"):
					coeff_str = coeff_str.substr(1)
				elif coeff_str.begins_with("-"):
					_sign = -1.0
					coeff_str = coeff_str.substr(1)

				# Remove surrounding parentheses if any
				if coeff_str.begins_with("(") and coeff_str.ends_with(")"):
					coeff_str = coeff_str.substr(1, coeff_str.length() - 2)
				coeff = parse_complex(coeff_str) * _sign

			var degree_str = parts[1]
			if degree_str == "": degree = 1
			elif degree_str.begins_with("^"):
				degree = int(degree_str.substr(1))
		else:
			var coeff_str = term
			var _sign = 1.0
			if coeff_str.begins_with("+"):
				coeff_str = coeff_str.substr(1)
			elif coeff_str.begins_with("-"):
				_sign = -1.0
				coeff_str = coeff_str.substr(1)
			if coeff_str.begins_with("(") and coeff_str.ends_with(")"):
				coeff_str = coeff_str.substr(1, coeff_str.length() - 2)
			coeff = parse_complex(coeff_str) * _sign
			degree = 0

		if degree >= 0 and degree < 10:
			coeffs[degree] += coeff

	return coeffs

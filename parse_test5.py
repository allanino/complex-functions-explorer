def parse_complex(text):
    text = text.replace(" ", "").replace("I", "i").replace("*", "")
    if text == "": return 0,0
    if text == "i": return 0, 1
    if text == "-i": return 0, -1
    if "i" not in text:
        return float(text), 0.0

    re = 0.0
    im = 0.0
    normalized = text.replace("-", "+-")
    parts = [p for p in normalized.split("+") if p]

    for p in parts:
        if p.endswith("i"):
            im_str = p[:-1]
            if im_str == "" or im_str == "+": im += 1.0
            elif im_str == "-": im -= 1.0
            else: im += float(im_str)
        else:
            re += float(p)
    return re, im

def parse_poly(text):
    text = text.replace(" ", "").replace("*", "")
    terms = []
    depth = 0
    start_idx = 0
    for i in range(len(text)):
        c = text[i]
        if c == '(': depth += 1
        elif c == ')': depth -= 1

        if depth == 0 and i > 0 and (c == '+' or c == '-'):
            terms.append(text[start_idx:i])
            start_idx = i
    terms.append(text[start_idx:])
    print("Terms:", terms)

    for term in terms:
        if term == "": continue
        coeff = (1, 0)
        degree = 0

        if "z" in term:
            parts = term.split("z")
            coeff_str = parts[0]
            if coeff_str == "" or coeff_str == "+": coeff = (1, 0)
            elif coeff_str == "-": coeff = (-1, 0)
            else:
                sign = 1.0
                if coeff_str.startswith("+"):
                    coeff_str = coeff_str[1:]
                elif coeff_str.startswith("-"):
                    sign = -1.0
                    coeff_str = coeff_str[1:]

                if coeff_str.startswith("(") and coeff_str.endswith(")"):
                    coeff_str = coeff_str[1:-1]

                c_re, c_im = parse_complex(coeff_str)
                coeff = (c_re * sign, c_im * sign)

            degree_str = parts[1]
            if degree_str == "": degree = 1
            elif degree_str.startswith("^"):
                degree = int(degree_str[1:])
        else:
            coeff_str = term
            sign = 1.0
            if coeff_str.startswith("+"):
                coeff_str = coeff_str[1:]
            elif coeff_str.startswith("-"):
                sign = -1.0
                coeff_str = coeff_str[1:]

            if coeff_str.startswith("(") and coeff_str.endswith(")"):
                coeff_str = coeff_str[1:-1]

            c_re, c_im = parse_complex(coeff_str)
            coeff = (c_re * sign, c_im * sign)
            degree = 0

        print(f"Degree {degree}: {coeff}")

parse_poly("(1+i)z^2-iz+(2-i)")

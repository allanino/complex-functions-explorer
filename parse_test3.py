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

    # Pre-processing step: group trailing terms into parentheses if they don't contain 'z'
    # Wait, the issue is about `2-i` being parsed as two terms `2` and `-i`.
    # In Godot script, we have coeffs[degree] += coeff
    # So `2` goes to degree 0, `-i` goes to degree 0.
    # The sum is `2 - i`.
    # Let's check Godot test:
    # res7 = hud_instance._parse_poly("(1+i)z^2 - iz + 2-i")
    # assert_eq(res7[0], Vector2(2, -1))

    # Oh! The test says it works!
    # "This fails as it is, but works with var res5 = hud_instance._parse_poly("(1+i)z^2 - iz + 2-i")"
    pass

parse_poly("(1+i)z^2-iz+2-i")

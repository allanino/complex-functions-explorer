import re

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
            # Check previous character to not break exponents
            if text[i-1] != 'e' and text[i-1] != 'E':
                terms.append(text[start_idx:i])
                start_idx = i
    terms.append(text[start_idx:])

    print(terms)

parse_poly("(1+i)z^2-iz+2-i")

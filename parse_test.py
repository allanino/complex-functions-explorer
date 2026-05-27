import re

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
            # The issue in Godot code is that "2-i" gets split into "2" and "-i" because it's not enclosed in ()
            # However, since they both don't have "z", they get added as 0 degree and summed up
            pass

    return terms

parse_poly("(1+i)z^2 - iz + 2-i")

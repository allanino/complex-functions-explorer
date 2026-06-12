import math

def ds_two_sum(a, b):
    s = a + b
    v = s - a
    e = (a - (s - v)) + (b - v)
    return s, e

def ds_add(a, b):
    s_hi, s_lo1 = ds_two_sum(a[0], b[0])
    s_lo2 = s_lo1 + a[1] + b[1]
    return ds_two_sum(s_hi, s_lo2)

def ds_split(a):
    MULTIPLIER = 131073.0
    c = MULTIPLIER * a
    a_hi = c - (c - a)
    a_lo = a - a_hi
    return a_hi, a_lo

def ds_two_prod(a, b):
    p = a * b
    a_hi, a_lo = ds_split(a)
    b_hi, b_lo = ds_split(b)
    err = p - (a_hi * b_hi) - (a_lo * b_hi) - (a_hi * b_lo) - (a_lo * b_lo)
    return p, err

def ds_mul(a, b):
    p_hi, p_lo1 = ds_two_prod(a[0], b[0])
    p_lo2 = p_lo1 + a[0] * b[1] + a[1] * b[0]
    return ds_two_sum(p_hi, p_lo2)

def ds_mul_scalar(a, scalar):
    p_hi, p_lo1 = ds_two_prod(a[0], scalar)
    p_lo2 = p_lo1 + a[1] * scalar
    return ds_two_sum(p_hi, p_lo2)

def expm1_polyfill(x):
    if abs(x) < 1e-5:
        return x + 0.5 * x * x
    return math.exp(x) - 1.0

def eta_borwein(x, y, order):
    order = min(order, 200)
    n = float(order)

    log_d = [0.0] * 201
    prev_T = 0.0
    current_max = 0.0
    current_sum_exp = 1.0

    for l in range(1, order + 1):
        fl = float(l)
        current_T = prev_T + math.log(n - fl + 1.0) + math.log(n + fl - 1.0) - math.log(2.0 * fl - 1.0) - math.log(2.0 * fl) + math.log(4.0)

        if current_T > current_max:
            diff = current_max - current_T
            current_sum_exp = current_sum_exp * math.exp(diff) + 1.0
            current_max = current_T
        else:
            current_sum_exp += math.exp(current_T - current_max)

        log_d[l] = current_max + math.log(current_sum_exp)
        prev_T = current_T

    log_d_n = log_d[order]

    # Double-Single accumulators
    sum_val_real = (0.0, 0.0)
    sum_val_imag = (0.0, 0.0)
    sum_dx_real = (0.0, 0.0)
    sum_dx_imag = (0.0, 0.0)

    for k in range(order):
        w_k = -expm1_polyfill(log_d[k] - log_d_n)

        k_plus_1 = float(k + 1)
        logk = math.log(k_plus_1)
        amp = math.exp(-x * logk)

        raw_theta = -y * logk
        raw_turns = raw_theta / (2 * math.pi)
        bounded_turns = raw_turns - math.floor(raw_turns)
        safe_theta = bounded_turns * (2 * math.pi)

        pow_term_real = amp * math.cos(safe_theta)
        pow_term_imag = amp * math.sin(safe_theta)

        if (k % 2) != 0:
            pow_term_real = -pow_term_real
            pow_term_imag = -pow_term_imag

        # w_k * pow_term
        term_real = ds_mul_scalar((pow_term_real, 0.0), w_k)
        term_imag = ds_mul_scalar((pow_term_imag, 0.0), w_k)

        # sum_val += term
        sum_val_real = ds_add(sum_val_real, term_real)
        sum_val_imag = ds_add(sum_val_imag, term_imag)

        # term_dx = -logk * term
        term_dx_real = ds_mul_scalar(term_real, -logk)
        term_dx_imag = ds_mul_scalar(term_imag, -logk)

        # sum_dx += term_dx
        sum_dx_real = ds_add(sum_dx_real, term_dx_real)
        sum_dx_imag = ds_add(sum_dx_imag, term_dx_imag)

    return (sum_val_real[0], sum_val_imag[0]), (sum_dx_real[0], sum_dx_imag[0])

# Tests
tests = [
    (2.0, 0.0, 50, (0.822467033, 0.0)),
    (0.0, 0.0, 50, (0.5, 0.0)),
    (-1.0, 0.0, 50, (0.25, 0.0)),
    (-2.0, 0.0, 50, (0.0, 0.0)),
    (-4.0, 0.0, 50, (0.0, 0.0)),
    (0.5, 14.134725, 50, (0.0, 0.0))
]

def assert_almost_eq(a, b, tol):
    if abs(a - b) > tol:
        print(f"FAILED: {a} != {b} (tol {tol})")
        return False
    return True

all_passed = True
for x, y, order, expected in tests:
    val, _ = eta_borwein(x, y, order)
    if not (assert_almost_eq(val[0], expected[0], 0.00001) and assert_almost_eq(val[1], expected[1], 0.00001)):
        all_passed = False

if all_passed:
    print("All tests passed!")

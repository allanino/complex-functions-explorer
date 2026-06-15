import math

def compute_eta_original(x, y, max_terms, K):
    s = complex(x, y)

    eta_coeffs = [0j] * (K + 1)
    fact = [math.factorial(k) for k in range(K + 1)]

    for n in range(1, max_terms + 1):
        sign = 1 if n % 2 != 0 else -1
        if n == 1:
            term = 1 + 0j
            log_n = 0
        else:
            term = sign * (n ** -s)
            log_n = math.log(n)

        current_term = term

        for k in range(K + 1):
            eta_coeffs[k] += current_term / fact[k]
            current_term *= -log_n

    return eta_coeffs

def compute_zeta_patch(x, y, max_terms, K=15):
    eta_coeffs = compute_eta_original(x, y, max_terms, K)

    s = complex(x, y)
    d_coeffs = [0j] * (K + 1)
    fact = [math.factorial(k) for k in range(K + 1)]

    log_2 = math.log(2)
    base_d = 2.0 * (2.0 ** -s)

    d_coeffs[0] = 1.0 - base_d

    d_term = base_d
    for k in range(1, K + 1):
        d_term *= -log_2
        d_coeffs[k] = -d_term / fact[k]

    zeta_coeffs = [0j] * (K + 1)
    for k in range(K + 1):
        sum_val = eta_coeffs[k]
        for j in range(k):
            sum_val -= zeta_coeffs[j] * d_coeffs[k - j]
        zeta_coeffs[k] = sum_val / d_coeffs[0]

    return zeta_coeffs

res = compute_zeta_patch(-0.5, 0.0, 2000, 15)
print("zeta_coeffs[0] for -0.5, 0.0:", res[0])

# I should also test the other zeros that failed. Wait, why did the other zeros fail?
# test_find_zero_log_fallback and test_find_zero_sin_fallback failing with ~0.0001 error?
# Let's read their tests and why they might fail now.
# Did I break `find_zero`?
# `compute_zeta_taylor_patch` is only used for zeta continuation patch evaluation.
# Wait, did `find_zero` use `compute_zeta_taylor_patch`?
# Let's search `find_zero` in `math/complex_field.gd`

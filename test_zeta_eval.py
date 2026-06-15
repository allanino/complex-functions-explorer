import cmath

def zeta_dirichlet(s, limit=2000):
    # Using dirichlet eta original
    # eta(s) = (1 - 2^{1-s}) zeta(s)

    eta = 0j
    for n in range(1, limit + 1):
        sign = 1 if n % 2 != 0 else -1
        eta += sign / (n ** s)

    zeta_val = eta / (1 - 2**(1 - s))
    return zeta_val

print(zeta_dirichlet(complex(-0.5, 0.0)))

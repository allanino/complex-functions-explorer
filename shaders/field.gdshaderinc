// Shared field and height functions for shaders

uniform int iterations = 120;
uniform int function_type = 0;
// 0: Zeta, 1: Zeta Continuation, 2: Gamma, 3: Log Gamma, 4: Dedekind Eta, 5: Sin, 6: Cos, 7: Tan, 8: Exp, 9: Log, 10: Rational
uniform int height_type = 0;   // 0: Log, 1: Abs
uniform float height_a = 3.0;
uniform float height_epsilon = 1.0;

uniform mat4 rational_num_mat;
uniform mat4 rational_den_mat;

struct FieldData {
    vec2 value;    // The actual complex f(sigma, t)
    vec2 d_sigma;  // Partial derivative with respect to sigma
    vec2 d_t;      // Partial derivative with respect to t
};

vec2 complex_mul(vec2 a, vec2 b) {
    return vec2(
        a.x * b.x - a.y * b.y,
        a.x * b.y + a.y * b.x
    );
}

vec2 complex_div(vec2 a, vec2 b) {
    float denom = b.x * b.x + b.y * b.y + 1e-24;
    return vec2(
        (a.x * b.x + a.y * b.y) / denom,
        (a.y * b.x - a.x * b.y) / denom
    );
}

vec2 complex_exp(vec2 z) {
    float amp = exp(z.x);
    return vec2(amp * cos(z.y), amp * sin(z.y));
}

vec2 complex_log(vec2 z) {
    float mag = length(z);
    return vec2(log(mag + 1e-24), atan(z.y, z.x));
}

vec2 complex_sin(vec2 z) {
    return vec2(sin(z.x) * cosh(z.y), cos(z.x) * sinh(z.y));
}

vec2 complex_cos(vec2 z) {
    return vec2(cos(z.x) * cosh(z.y), -sin(z.x) * sinh(z.y));
}

vec2 complex_pow(vec2 base, vec2 exponent) {
    return complex_exp(complex_mul(complex_log(base), exponent));
}

// Lanczos approximation for Gamma function
const float LANCZOS_G = 9.0;
const float LANCZOS_COEFFS[11] = {
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
    0.0,
    0.0
};

FieldData complex_gamma_with_derivatives(vec2 z) {
    FieldData res;
    if (z.x < 0.5) {
        // Reflection formula: Gamma(z) = pi / (sin(pi*z) * Gamma(1-z))
        vec2 one_minus_z = vec2(1.0, 0.0) - z;
        FieldData g_1z = complex_gamma_with_derivatives(one_minus_z);
        vec2 pi_z = PI * z;
        vec2 sin_pi_z = complex_sin(pi_z);
        vec2 denom = complex_mul(sin_pi_z, g_1z.value);
        res.value = complex_div(vec2(PI, 0.0), denom);

        // Logarithmic derivative for d_sigma
        // d/dz log Gamma(z) = d/dz [ log(pi) - log(sin(pi*z)) - log(Gamma(1-z)) ]
        // psi(z) = -pi * cot(pi*z) + psi(1-z)
        vec2 cot_pi_z = complex_div(complex_cos(pi_z), sin_pi_z);
        // g_1z.d_sigma is d/d(1-sigma) Gamma(1-z). We want d/dsigma log Gamma(1-z) = (d/dz log Gamma(1-z)) * (dz/dsigma)
        // Actually d/dz log Gamma(1-z) = -psi(1-z)
        // psi(z) = res.d_sigma / res.value
        // We use the relation: psi(z) = -PI * cot(PI*z) + psi(1-z)
        // g_1z.d_sigma / g_1z.value is d/d(1-z) log Gamma(1-z) = psi(1-z)
        vec2 psi_1z = complex_div(g_1z.d_sigma, g_1z.value);
        vec2 psi_z = -PI * cot_pi_z + psi_1z;
        res.d_sigma = complex_mul(res.value, psi_z);
    } else {
        vec2 zh = z - vec2(0.5, 0.0);
        vec2 z_plus_g_plus_h = z + vec2(LANCZOS_G - 0.5, 0.0);
        vec2 ag = vec2(LANCZOS_COEFFS[0], 0.0);
        vec2 dag = vec2(0.0);
        for (int i = 1; i < 9; i++) {
            vec2 z_plus_i = z + vec2(float(i), 0.0);
            vec2 inv_z_i = complex_div(vec2(1.0, 0.0), z_plus_i);
            ag += LANCZOS_COEFFS[i] * inv_z_i;
            dag -= LANCZOS_COEFFS[i] * complex_mul(inv_z_i, inv_z_i);
        }

        vec2 sqrt_2pi = vec2(sqrt(2.0 * PI), 0.0);
        vec2 p1 = complex_pow(z_plus_g_plus_h, zh);
        vec2 p2 = complex_exp(-z_plus_g_plus_h);
        vec2 term = complex_mul(complex_mul(sqrt_2pi, p1), complex_mul(p2, ag));
        res.value = term;

        // Logarithmic derivative
        // log Gamma = log(sqrt(2pi)) + (z-0.5)log(z+g-0.5) - (z+g-0.5) + log(ag)
        // psi(z) = log(z+g-0.5) + (z-0.5)/(z+g-0.5) - 1 + dag/ag
        vec2 psi = complex_log(z_plus_g_plus_h) + complex_div(zh, z_plus_g_plus_h) - vec2(1.0, 0.0) + complex_div(dag, ag);
        res.d_sigma = complex_mul(res.value, psi);
    }
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

FieldData complex_log_gamma_with_derivatives(vec2 z) {
    // Principal branch of log gamma
    FieldData g = complex_gamma_with_derivatives(z);
    FieldData res;
    res.value = complex_log(g.value);
    // Log gamma branch wrapping to prevent terrain jumps
    res.value.y = mod(res.value.y + PI, 2.0 * PI) - PI;

    res.d_sigma = complex_div(g.d_sigma, g.value);
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

FieldData zeta_with_derivatives(float sigma, float t, int iters) {
    vec2 eta = vec2(0.0);
    vec2 deta_ds = vec2(0.0);
    for (int n = 1; n <= iters; n++) {
        float nf = float(n);
        float log_n = log(nf);
        vec2 n_pow_s = complex_exp(vec2(-sigma * log_n, -t * log_n));
        float _sign = (mod(float(n), 2.0) < 0.5) ? -1.0 : 1.0;
        vec2 term = _sign * n_pow_s;
        eta += term;
        deta_ds -= log_n * term;
    }
    vec2 two_s = complex_exp(vec2((1.0 - sigma) * log(2.0), -t * log(2.0)));
    vec2 denom = vec2(1.0, 0.0) - two_s;
    vec2 ddenom_ds = log(2.0) * two_s;

    FieldData res;
    res.value = complex_div(eta, denom);
    res.d_sigma = complex_div(complex_mul(deta_ds, denom) - complex_mul(eta, ddenom_ds), complex_mul(denom, denom));
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

FieldData zeta_continuation_with_derivatives(float sigma, float t, int iters) {
    if (sigma >= 0.5) {
        return zeta_with_derivatives(sigma, t, iters);
    }
    // zeta(s) = 2^s * pi^(s-1) * sin(pi*s/2) * Gamma(1-s) * zeta(1-s)
    vec2 s = vec2(sigma, t);
    vec2 one_minus_s = vec2(1.0, 0.0) - s;
    FieldData z_1s = zeta_with_derivatives(one_minus_s.x, one_minus_s.y, iters);
    FieldData g_1s = complex_gamma_with_derivatives(one_minus_s);

    vec2 two_s = complex_pow(vec2(2.0, 0.0), s);
    vec2 pi_s_minus_1 = complex_pow(vec2(PI, 0.0), s - vec2(1.0, 0.0));
    vec2 sin_term = complex_sin(PI * s * 0.5);

    vec2 val = complex_mul(complex_mul(two_s, pi_s_minus_1), complex_mul(sin_term, complex_mul(g_1s.value, z_1s.value)));

    FieldData res;
    res.value = val;

    // Logarithmic derivative
    // log zeta(s) = s log 2 + (s-1) log pi + log sin(pi s / 2) + log Gamma(1-s) + log zeta(1-s)
    // d/ds log zeta(s) = log 2 + log pi + (pi/2) cot(pi s / 2) - psi(1-s) - zeta'(1-s)/zeta(1-s)
    vec2 cot_term = complex_div(complex_cos(PI * s * 0.5), sin_term);
    vec2 psi_1s = complex_div(g_1s.d_sigma, g_1s.value);
    vec2 lz_1s = complex_div(z_1s.d_sigma, z_1s.value);

    vec2 dlog = vec2(log(2.0) + log(PI), 0.0) + (PI * 0.5) * cot_term - psi_1s - lz_1s;
    res.d_sigma = complex_mul(val, dlog);
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

FieldData dedekind_eta_with_derivatives(float sigma, float t, int iters) {
    vec2 factor = complex_exp(vec2(-PI * t / 12.0, PI * sigma / 12.0));
    vec2 d_factor = complex_mul(vec2(0.0, PI / 12.0), factor);
    vec2 prod = vec2(1.0, 0.0);
    vec2 sum_log_deriv = vec2(0.0);
    for (int n = 1; n <= iters; n++) {
        float nf = float(n);
        vec2 q_n = complex_exp(vec2(-2.0 * PI * nf * t, 2.0 * PI * nf * sigma));
        vec2 dq_n = complex_mul(vec2(0.0, 2.0 * PI * nf), q_n);
        vec2 term = vec2(1.0, 0.0) - q_n;
        prod = complex_mul(prod, term);
        sum_log_deriv -= complex_div(dq_n, term);
        if (nf > 10.0 && length(q_n) < 1e-12) break;
    }
    FieldData res;
    res.value = complex_mul(factor, prod);
    res.d_sigma = complex_mul(res.value, complex_div(d_factor, factor) + sum_log_deriv);
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

FieldData get_rational_with_derivatives(vec2 z) {
    vec2 num = vec2(0.0);
    vec2 dnum = vec2(0.0);
    vec2 den = vec2(0.0);
    vec2 dden = vec2(0.0);
    vec2 z_pow = vec2(1.0, 0.0);
    for (int i = 0; i < 10; i++) {
        vec2 cn = vec2(rational_num_mat[i/4][i%4], 0.0);
        vec2 cd = vec2(rational_den_mat[i/4][i%4], 0.0);
        num += complex_mul(cn, z_pow);
        den += complex_mul(cd, z_pow);
        if (i < 9) {
            vec2 cn1 = vec2(rational_num_mat[(i+1)/4][(i+1)%4], 0.0);
            vec2 cd1 = vec2(rational_den_mat[(i+1)/4][(i+1)%4], 0.0);
            dnum += float(i+1) * complex_mul(cn1, z_pow);
            dden += float(i+1) * complex_mul(cd1, z_pow);
        }
        z_pow = complex_mul(z_pow, z);
    }
    FieldData res;
    res.value = complex_div(num, den);
    res.d_sigma = complex_div(complex_mul(dnum, den) - complex_mul(num, dden), complex_mul(den, den));
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

FieldData get_field_with_derivatives(float x, float z) {
	float sigma = x * 0.1;
	float t = -z * 0.1;
    vec2 s = vec2(sigma, t);

    if (function_type == 0) return zeta_with_derivatives(sigma, t, iterations);
    if (function_type == 1) return zeta_continuation_with_derivatives(sigma, t, iterations);
    if (function_type == 2) return complex_gamma_with_derivatives(s);
    if (function_type == 3) return complex_log_gamma_with_derivatives(s);
    if (function_type == 4) return dedekind_eta_with_derivatives(sigma, t, iterations);
    if (function_type == 5) {
        FieldData res; res.value = complex_sin(s);
        vec2 d = complex_cos(s); res.d_sigma = d; res.d_t = vec2(-d.y, d.x); return res;
    }
    if (function_type == 6) {
        FieldData res; res.value = complex_cos(s);
        vec2 d = -complex_sin(s); res.d_sigma = d; res.d_t = vec2(-d.y, d.x); return res;
    }
    if (function_type == 7) {
        FieldData res; vec2 si = complex_sin(s); vec2 co = complex_cos(s);
        res.value = complex_div(si, co);
        vec2 d = complex_div(vec2(1.0, 0.0), complex_mul(co, co));
        res.d_sigma = d; res.d_t = vec2(-d.y, d.x); return res;
    }
    if (function_type == 8) {
        FieldData res; res.value = complex_exp(s);
        res.d_sigma = res.value; res.d_t = vec2(-res.value.y, res.value.x); return res;
    }
    if (function_type == 9) {
        FieldData res; res.value = complex_log(s);
        vec2 d = complex_div(vec2(1.0, 0.0), s);
        res.d_sigma = d; res.d_t = vec2(-d.y, d.x); return res;
    }
    if (function_type == 10) return get_rational_with_derivatives(s);

    FieldData res; res.value = vec2(0.0); res.d_sigma = vec2(0.0); res.d_t = vec2(0.0); return res;
}

vec2 get_field(float x, float z) {
    return get_field_with_derivatives(x, z).value;
}

float get_height(float x, float z) {
    vec2 f = get_field(x, z);
    float mag = length(f);
    if (height_type == 0) return height_a * log(height_epsilon + mag);
    return mag;
}

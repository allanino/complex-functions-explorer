// Shared field and height functions for shaders

uniform int iterations = 120;
uniform int function_type = 0; // 0: Zeta, 1: Gamma, 2: Dedekind Eta, 3: Sin, 4: Cos, 5: Tan, 6: Exp, 7: Log, 8: Rational
uniform int height_type = 0;   // 0: Log, 1: Abs
uniform float height_a = 3.0;
uniform float height_epsilon = 1.0;

uniform float rational_num_coeffs[10];
uniform float rational_den_coeffs[10];

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

    float denom = b.x * b.x + b.y * b.y + 1e-12;

    return vec2(
        (a.x * b.x + a.y * b.y) / denom,
        (a.y * b.x - a.x * b.y) / denom
    );
}

const float LANCZOS_P[9] = float[](
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7
);
const float SQRT_2PI = 2.5066282746310005;

vec2 complex_exp(float sigma, float t) {
    float amp = exp(sigma);
    return vec2(
        amp * cos(t),
        amp * sin(t)
    );
}

vec2 complex_log(float sigma, float t) {
    float mag = length(vec2(sigma, t));
    if (mag < 1e-9) {
        return vec2(-10.0, 0.0);
    }
    return vec2(
        log(mag),
        atan(t, sigma)
    );
}

vec2 complex_pow(vec2 z, vec2 w) {
    vec2 lz = complex_log(z.x, z.y);
    vec2 res_log = complex_mul(w, lz);
    return complex_exp(res_log.x, res_log.y);
}

vec2 lanczos_gamma(vec2 z_orig) {
    vec2 z = z_orig - vec2(1.0, 0.0);
    vec2 x = vec2(LANCZOS_P[0], 0.0);
    for (int i = 1; i < 9; i++) {
        x += complex_div(vec2(LANCZOS_P[i], 0.0), z + vec2(float(i), 0.0));
    }

    vec2 tmp = z + vec2(7.5, 0.0);
    vec2 p = complex_pow(tmp, z + vec2(0.5, 0.0));
    vec2 etmp = complex_exp(-tmp.x, -tmp.y);

    return SQRT_2PI * complex_mul(complex_mul(p, etmp), x);
}

vec2 complex_sin(float sigma, float t) {
    return vec2(
        sin(sigma) * cosh(t),
        cos(sigma) * sinh(t)
    );
}

vec2 complex_cos(float sigma, float t) {
    return vec2(
        cos(sigma) * cosh(t),
        -sin(sigma) * sinh(t)
    );
}

vec2 complex_gamma(float sigma, float t) {
    if (sigma < 0.5) {
        vec2 z = vec2(sigma, t);
        vec2 sin_pi_z = complex_sin(PI * sigma, PI * t);
        vec2 g1z = lanczos_gamma(vec2(1.0 - sigma, -t));
        return complex_div(vec2(PI, 0.0), complex_mul(sin_pi_z, g1z));
    }
    return lanczos_gamma(vec2(sigma, t));
}

FieldData lanczos_gamma_with_derivatives(vec2 z_orig) {
    vec2 z = z_orig - vec2(1.0, 0.0);
    vec2 x = vec2(LANCZOS_P[0], 0.0);
    vec2 dx = vec2(0.0, 0.0);
    for (int i = 1; i < 9; i++) {
        vec2 denom = z + vec2(float(i), 0.0);
        x += complex_div(vec2(LANCZOS_P[i], 0.0), denom);
        dx -= complex_div(vec2(LANCZOS_P[i], 0.0), complex_mul(denom, denom));
    }

    vec2 tmp = z + vec2(7.5, 0.0);
    vec2 p = complex_pow(tmp, z + vec2(0.5, 0.0));
    vec2 etmp = complex_exp(-tmp.x, -tmp.y);

    vec2 value = SQRT_2PI * complex_mul(complex_mul(p, etmp), x);

    // f'/f = log(tmp) + (z+0.5)/tmp - 1 + x'/x
    vec2 log_tmp = complex_log(tmp.x, tmp.y);
    vec2 deriv_ratio = log_tmp + complex_div(z + vec2(0.5, 0.0), tmp) - vec2(1.0, 0.0) + complex_div(dx, x);

    FieldData res;
    res.value = value;
    res.d_sigma = complex_mul(value, deriv_ratio);
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

FieldData complex_gamma_with_derivatives(float sigma, float t) {
    if (sigma < 0.5) {
        vec2 z = vec2(sigma, t);
        FieldData g1z = lanczos_gamma_with_derivatives(vec2(1.0 - sigma, -t));

        vec2 pi_z = PI * z;
        vec2 cot_pi_z = complex_div(complex_cos(pi_z.x, pi_z.y), complex_sin(pi_z.x, pi_z.y));

        vec2 ratio_g1z = complex_div(g1z.d_sigma, g1z.value);
        vec2 ratio = -PI * cot_pi_z + ratio_g1z;

        FieldData res;
        res.value = complex_div(vec2(PI, 0.0), complex_mul(complex_sin(pi_z.x, pi_z.y), g1z.value));
        res.d_sigma = complex_mul(res.value, ratio);
        res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
        return res;
    }
    return lanczos_gamma_with_derivatives(vec2(sigma, t));
}

vec2 zeta(float sigma, float t) {

    //----------------------------------------
    // STEP 1: Compute eta(s)
    //----------------------------------------

    vec2 eta = vec2(0.0);

    for (int n = 1; n <= iterations; n++) {

        float nf = float(n);

        //----------------------------------------
        // amplitude = n^{-sigma}
        //----------------------------------------

        float amp = pow(nf, -sigma);

        if (amp < 1e-6) {
            break;
        }

        //----------------------------------------
        // phase = -t log n
        //----------------------------------------

        float theta = -t * log(nf);

        //----------------------------------------
        // alternating sign
        //----------------------------------------

        float _sign = (mod(float(n), 2.0) < 0.5)
            ? -1.0
            : 1.0;

        //----------------------------------------
        // term = sign * n^{-s}
        //----------------------------------------

        eta += _sign * amp * vec2(
            cos(theta),
            sin(theta)
        );
    }

    //----------------------------------------
    // STEP 2: Compute denominator
    //
    // d = 1 - 2^{1-s}
    //----------------------------------------

    float amp2 = pow(2.0, 1.0 - sigma);

    float theta2 = -t * log(2.0);

    vec2 two_term = amp2 * vec2(
        cos(theta2),
        sin(theta2)
    );

    vec2 denom = vec2(1.0, 0.0) - two_term;

    //----------------------------------------
    // STEP 3: zeta = eta / denom
    //----------------------------------------

    return complex_div(eta, denom);
}


vec2 dedekind_eta(float sigma, float t) {
    // eta(tau) = exp(pi * i * tau / 12) * product_{n=1}^inf (1 - exp(2 * pi * i * n * tau))
    // Let tau = sigma + i*t
    // pi * i * tau / 12 = pi * i * (sigma + i*t) / 12 = (-pi * t / 12) + i * (pi * sigma / 12)
    vec2 factor = complex_exp(-PI * t / 12.0, PI * sigma / 12.0);

    vec2 prod = vec2(1.0, 0.0);
    float q_re_base = -2.0 * PI * t;
    float q_im_base = 2.0 * PI * sigma;

    for (int n = 1; n <= iterations; n++) {
        float nf = float(n);
        vec2 term_exp = complex_exp(nf * q_re_base, nf * q_im_base);
        vec2 term = vec2(1.0, 0.0) - term_exp;
        prod = complex_mul(prod, term);

        if (nf > 10.0 && length(term_exp) < 1e-12) {
            break;
        }
    }

    return complex_mul(factor, prod);
}

FieldData dedekind_eta_with_derivatives(float sigma, float t, int iters) {
    // Dedekind eta is holomorphic, so d_t = i * d_sigma
    // We compute d_sigma analytically.
    // eta(tau) = factor(tau) * prod_{n=1}^inf (1 - q_n(tau))
    // log(eta) = log(factor) + sum log(1 - q_n)
    // eta' / eta = factor' / factor + sum (-q_n' / (1 - q_n))
    // tau = sigma + i*t => d_tau / d_sigma = 1.

    vec2 factor = complex_exp(-PI * t / 12.0, PI * sigma / 12.0);
    vec2 d_factor_dsigma = complex_mul(vec2(0.0, PI / 12.0), factor);

    vec2 prod = vec2(1.0, 0.0);
    vec2 sum_log_deriv = vec2(0.0);

    float q_re_base = -2.0 * PI * t;
    float q_im_base = 2.0 * PI * sigma;

    for (int n = 1; n <= iters; n++) {
        float nf = float(n);
        vec2 q_n = complex_exp(nf * q_re_base, nf * q_im_base);
        vec2 dq_n_dsigma = complex_mul(vec2(0.0, 2.0 * PI * nf), q_n);

        vec2 term = vec2(1.0, 0.0) - q_n;
        prod = complex_mul(prod, term);

        sum_log_deriv += complex_div(-dq_n_dsigma, term);

        if (nf > 10.0 && length(q_n) < 1e-12) {
            break;
        }
    }

    FieldData res;
    res.value = complex_mul(factor, prod);

    // eta' = eta * (factor' / factor + sum_log_deriv)
    res.d_sigma = complex_mul(res.value, complex_div(d_factor_dsigma, factor) + sum_log_deriv);
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);

    return res;
}

FieldData zeta_with_derivatives(float sigma, float t, int iters) {
    vec2 eta = vec2(0.0);
    vec2 deta_dsigma = vec2(0.0);

    for (int n = 1; n <= iters; n++) {
        float nf = float(n);
        float amp = pow(nf, -sigma);
        if (amp < 1e-6) {
            break;
        }

        float log_n = log(nf);
        float theta = -t * log_n;
        float _sign = (mod(float(n), 2.0) < 0.5) ? -1.0 : 1.0;

        vec2 term = _sign * amp * vec2(cos(theta), sin(theta));
        eta += term;
        deta_dsigma += -log_n * term;
    }

    float log_2 = log(2.0);
    float amp2 = pow(2.0, 1.0 - sigma);
    float theta2 = -t * log_2;
    vec2 two_term = amp2 * vec2(cos(theta2), sin(theta2));

    vec2 denom = vec2(1.0, 0.0) - two_term;
    vec2 ddenom_dsigma = log_2 * two_term;

    FieldData result;
    result.value = complex_div(eta, denom);

    vec2 denom_sqr = complex_mul(denom, denom);
    vec2 num_sigma = complex_mul(deta_dsigma, denom) - complex_mul(eta, ddenom_dsigma);
    result.d_sigma = complex_div(num_sigma, denom_sqr);
    result.d_t = vec2(-result.d_sigma.y, result.d_sigma.x);

    return result;
}

vec2 complex_tan(float sigma, float t) {
    return complex_div(complex_sin(sigma, t), complex_cos(sigma, t));
}

vec2 evaluate_poly(float sigma, float t, float coeffs[10]) {
    vec2 z = vec2(sigma, t);
    vec2 res = vec2(0.0);
    vec2 z_pow = vec2(1.0, 0.0);

    for (int i = 0; i < 10; i++) {
        res += coeffs[i] * z_pow;
        z_pow = complex_mul(z_pow, z);
    }

    return res;
}

vec2 get_rational(float sigma, float t) {
    vec2 num = evaluate_poly(sigma, t, rational_num_coeffs);
    vec2 den = evaluate_poly(sigma, t, rational_den_coeffs);
    return complex_div(num, den);
}

FieldData complex_sin_with_derivatives(float sigma, float t) {
    FieldData res;
    res.value = complex_sin(sigma, t);
    vec2 deriv = complex_cos(sigma, t);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

FieldData complex_cos_with_derivatives(float sigma, float t) {
    FieldData res;
    res.value = complex_cos(sigma, t);
    vec2 deriv = -complex_sin(sigma, t);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

FieldData complex_tan_with_derivatives(float sigma, float t) {
    FieldData res;
    res.value = complex_tan(sigma, t);
    vec2 cos_z = complex_cos(sigma, t);
    vec2 cos_z_sqr = complex_mul(cos_z, cos_z);
    vec2 deriv = complex_div(vec2(1.0, 0.0), cos_z_sqr);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

FieldData complex_exp_with_derivatives(float sigma, float t) {
    FieldData res;
    res.value = complex_exp(sigma, t);
    vec2 deriv = res.value;
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

FieldData complex_log_with_derivatives(float sigma, float t) {
    FieldData res;
    res.value = complex_log(sigma, t);
    vec2 z = vec2(sigma, t);
    vec2 deriv = complex_div(vec2(1.0, 0.0), z);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

FieldData evaluate_poly_with_derivatives(float sigma, float t, float coeffs[10]) {
    vec2 z = vec2(sigma, t);
    vec2 val = vec2(0.0);
    vec2 deriv = vec2(0.0);
    vec2 z_pow = vec2(1.0, 0.0);

    for (int i = 0; i < 10; i++) {
        val += coeffs[i] * z_pow;
        if (i < 9) {
            deriv += float(i + 1) * coeffs[i+1] * z_pow;
        }
        z_pow = complex_mul(z_pow, z);
    }

    FieldData res;
    res.value = val;
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

FieldData get_rational_with_derivatives(float sigma, float t) {
    FieldData num = evaluate_poly_with_derivatives(sigma, t, rational_num_coeffs);
    FieldData den = evaluate_poly_with_derivatives(sigma, t, rational_den_coeffs);

    FieldData res;
    res.value = complex_div(num.value, den.value);

    vec2 den_sqr = complex_mul(den.value, den.value);

    // (num' * den - num * den') / den^2
    vec2 deriv = complex_div(
        complex_mul(num.d_sigma, den.value) - complex_mul(num.value, den.d_sigma),
        den_sqr
    );

    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

FieldData get_field_with_derivatives(float x, float z) {
	float sigma = x * 0.1;
	float t = -z * 0.1;

    if (function_type == 0) {
        return zeta_with_derivatives(sigma, t, iterations);
    } else if (function_type == 1) {
        return complex_gamma_with_derivatives(sigma, t);
    } else if (function_type == 2) {
        return dedekind_eta_with_derivatives(sigma, t, iterations);
    } else if (function_type == 3) {
        return complex_sin_with_derivatives(sigma, t);
    } else if (function_type == 4) {
        return complex_cos_with_derivatives(sigma, t);
    } else if (function_type == 5) {
        return complex_tan_with_derivatives(sigma, t);
    } else if (function_type == 6) {
        return complex_exp_with_derivatives(sigma, t);
    } else if (function_type == 7) {
        return complex_log_with_derivatives(sigma, t);
    } else if (function_type == 8) {
        return get_rational_with_derivatives(sigma, t);
    }

    FieldData res;
    res.value = vec2(0.0);
    res.d_sigma = vec2(0.0);
    res.d_t = vec2(0.0);
    return res;
}

vec2 get_field(float x, float z) {
	float sigma = x * 0.1;
	float t = -z * 0.1;

    if (function_type == 0) {
        return zeta(sigma, t);
    } else if (function_type == 1) {
        return complex_gamma(sigma, t);
    } else if (function_type == 2) {
        return dedekind_eta(sigma, t);
    } else if (function_type == 3) {
        return complex_sin(sigma, t);
    } else if (function_type == 4) {
        return complex_cos(sigma, t);
    } else if (function_type == 5) {
        return complex_tan(sigma, t);
    } else if (function_type == 6) {
        return complex_exp(sigma, t);
    } else if (function_type == 7) {
        return complex_log(sigma, t);
    } else if (function_type == 8) {
        return get_rational(sigma, t);
    }

    return vec2(0.0);
}

float get_height(float x, float z) {
    vec2 f = get_field(x, z);
    float mag = length(f);

    if (height_type == 0) {
        return height_a * log(height_epsilon + mag);
    } else {
        return mag;
    }
}

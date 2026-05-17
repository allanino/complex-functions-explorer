// Shared field and height functions for shaders

uniform int iterations = 120;
uniform int function_type = 0; // 0: Zeta, 1: Zeta continuation, 2: Gamma, 3: Log Gamma, 4: Dedekind Eta, 5: Sin, 6: Cos, 7: Tan, 8: Exp, 9: Log, 10: Rational
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

//-------------------------------------------------------------------------
// Complex Arithmetic
//-------------------------------------------------------------------------

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

vec2 complex_tan(float sigma, float t) {
    return complex_div(complex_sin(sigma, t), complex_cos(sigma, t));
}

//-------------------------------------------------------------------------
// Component Functions: Zeta, Gamma, Dedekind Eta
//-------------------------------------------------------------------------

// 1. Zeta
vec2 zeta(float sigma, float t) {
    vec2 eta = vec2(0.0);
    for (int n = 1; n <= iterations; n++) {
        float nf = float(n);
        float amp = pow(nf, -sigma);
        if (amp < 1e-6) break;
        float theta = -t * log(nf);
        float _sign = (mod(float(n), 2.0) < 0.5) ? -1.0 : 1.0;
        eta += _sign * amp * vec2(cos(theta), sin(theta));
    }
    float amp2 = pow(2.0, 1.0 - sigma);
    float theta2 = -t * log(2.0);
    vec2 two_term = amp2 * vec2(cos(theta2), sin(theta2));
    vec2 denom = vec2(1.0, 0.0) - two_term;
    return complex_div(eta, denom);
}

FieldData zeta_with_derivatives(float sigma, float t, int iters) {
    vec2 eta = vec2(0.0);
    vec2 deta_dsigma = vec2(0.0);
    for (int n = 1; n <= iters; n++) {
        float nf = float(n);
        float amp = pow(nf, -sigma);
        if (amp < 1e-6) break;
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

// 2. Gamma
const float LANCZOS_P[11] = float[](
    1.000000000000000174663,
    5716.400188274341379136,
    -14815.30426768413909044,
    14291.49277657478554025,
    -6348.160217641458813289,
    1301.608286058321874105,
    -108.1767053514369634679,
    2.605696505611755827729,
    0.7423452510201416151527e-2,
    0.5384136432509564062961e-7,
    -0.4023533141268236372067e-8
);
const float SQRT_2PI = 2.5066282746310005;

vec2 lanczos_gamma(vec2 z_orig) {
    vec2 z = z_orig - vec2(1.0, 0.0);
    vec2 x = vec2(LANCZOS_P[0], 0.0);
    for (int i = 1; i < 11; i++) {
        x += complex_div(vec2(LANCZOS_P[i], 0.0), z + vec2(float(i), 0.0));
    }
    vec2 tmp = z + vec2(9.5, 0.0);
    vec2 p = complex_pow(tmp, z + vec2(0.5, 0.0));
    vec2 etmp = complex_exp(-tmp.x, -tmp.y);
    return SQRT_2PI * complex_mul(complex_mul(p, etmp), x);
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
    for (int i = 1; i < 11; i++) {
        vec2 denom = z + vec2(float(i), 0.0);
        x += complex_div(vec2(LANCZOS_P[i], 0.0), denom);
        dx -= complex_div(vec2(LANCZOS_P[i], 0.0), complex_mul(denom, denom));
    }
    vec2 tmp = z + vec2(9.5, 0.0);
    vec2 p = complex_pow(tmp, z + vec2(0.5, 0.0));
    vec2 etmp = complex_exp(-tmp.x, -tmp.y);
    vec2 value = SQRT_2PI * complex_mul(complex_mul(p, etmp), x);
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
        vec2 pi_z = vec2(PI * sigma, PI * t);
        FieldData g1z = lanczos_gamma_with_derivatives(vec2(1.0 - sigma, -t));
        vec2 cot_pi_z = complex_div(complex_cos(pi_z.x, pi_z.y), complex_sin(pi_z.x, pi_z.y));
        vec2 ratio = -PI * cot_pi_z + complex_div(g1z.d_sigma, g1z.value);
        FieldData res;
        res.value = complex_div(vec2(PI, 0.0), complex_mul(complex_sin(pi_z.x, pi_z.y), g1z.value));
        res.d_sigma = complex_mul(res.value, ratio);
        res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
        return res;
    }
    return lanczos_gamma_with_derivatives(vec2(sigma, t));
}

// 3. Log Gamma
vec2 lanczos_log_gamma(vec2 z) {
    vec2 z_m1 = z - vec2(1.0, 0.0);
    vec2 x = vec2(LANCZOS_P[0], 0.0);
    for (int i = 1; i < 11; i++) {
        x += complex_div(vec2(LANCZOS_P[i], 0.0), z_m1 + vec2(float(i), 0.0));
    }
    vec2 tmp = z_m1 + vec2(9.5, 0.0);
    return vec2(log(SQRT_2PI), 0.0)
           + complex_mul(z - vec2(0.5, 0.0), complex_log(tmp.x, tmp.y))
           - tmp
           + complex_log(x.x, x.y);
}

vec2 complex_log_gamma(float sigma, float t) {
    if (sigma < 0.5) {
        vec2 pi_z = vec2(PI * sigma, PI * t);
        vec2 s = complex_sin(pi_z.x, pi_z.y);
        return vec2(log(PI), 0.0) - complex_log(s.x, s.y) - lanczos_log_gamma(vec2(1.0 - sigma, -t));
    }
    return lanczos_log_gamma(vec2(sigma, t));
}

FieldData lanczos_log_gamma_with_derivatives(vec2 z) {
    vec2 z_m1 = z - vec2(1.0, 0.0);
    vec2 x = vec2(LANCZOS_P[0], 0.0);
    vec2 dx = vec2(0.0, 0.0);
    for (int i = 1; i < 11; i++) {
        vec2 denom = z_m1 + vec2(float(i), 0.0);
        x += complex_div(vec2(LANCZOS_P[i], 0.0), denom);
        dx -= complex_div(vec2(LANCZOS_P[i], 0.0), complex_mul(denom, denom));
    }
    vec2 tmp = z_m1 + vec2(9.5, 0.0);
    vec2 log_tmp = complex_log(tmp.x, tmp.y);

    vec2 value = vec2(log(SQRT_2PI), 0.0)
               + complex_mul(z - vec2(0.5, 0.0), log_tmp)
               - tmp
               + complex_log(x.x, x.y);

    vec2 psi = log_tmp + complex_div(z - vec2(0.5, 0.0), tmp) - vec2(1.0, 0.0) + complex_div(dx, x);

    FieldData res;
    res.value = value;
    res.d_sigma = psi;
    res.d_t = vec2(-psi.y, psi.x);
    return res;
}

FieldData complex_log_gamma_with_derivatives(float sigma, float t) {
    if (sigma < 0.5) {
        vec2 pi_z = vec2(PI * sigma, PI * t);
        FieldData lg1z = lanczos_log_gamma_with_derivatives(vec2(1.0 - sigma, -t));
        vec2 sin_pi_z = complex_sin(pi_z.x, pi_z.y);
        vec2 log_sin_pi_z = complex_log(sin_pi_z.x, sin_pi_z.y);

        vec2 value = vec2(log(PI), 0.0) - log_sin_pi_z - lg1z.value;

        vec2 cot_pi_z = complex_div(complex_cos(pi_z.x, pi_z.y), sin_pi_z);
        vec2 psi = -PI * cot_pi_z + lg1z.d_sigma;

        FieldData res;
        res.value = value;
        res.d_sigma = psi;
        res.d_t = vec2(-psi.y, psi.x);
        return res;
    }
    return lanczos_log_gamma_with_derivatives(vec2(sigma, t));
}

// 4. Dedekind Eta
vec2 dedekind_eta(float sigma, float t) {
    vec2 factor = complex_exp(-PI * t / 12.0, PI * sigma / 12.0);
    vec2 prod = vec2(1.0, 0.0);
    float q_re_base = -2.0 * PI * t;
    float q_im_base = 2.0 * PI * sigma;
    for (int n = 1; n <= iterations; n++) {
        float nf = float(n);
        vec2 term_exp = complex_exp(nf * q_re_base, nf * q_im_base);
        vec2 term = vec2(1.0, 0.0) - term_exp;
        prod = complex_mul(prod, term);
        if (nf > 10.0 && length(term_exp) < 1e-12) break;
    }
    return complex_mul(factor, prod);
}

FieldData dedekind_eta_with_derivatives(float sigma, float t, int iters) {
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
        if (nf > 10.0 && length(q_n) < 1e-12) break;
    }
    FieldData res;
    res.value = complex_mul(factor, prod);
    res.d_sigma = complex_mul(res.value, complex_div(d_factor_dsigma, factor) + sum_log_deriv);
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

//-------------------------------------------------------------------------
// Composite Functions
//-------------------------------------------------------------------------

// Zeta Continuation using functional equation via log-sum
vec2 zeta_continuation(float sigma, float t, int iters) {
    if (sigma >= 0.5) return zeta(sigma, t);
    vec2 s = vec2(sigma, t);
    vec2 s1 = vec2(1.0 - sigma, -t);

    vec2 log_sum = complex_mul(s, vec2(log(2.0), 0.0))
                 + complex_mul(s - vec2(1.0, 0.0), vec2(log(PI), 0.0));

    vec2 pi_s_2 = (PI * 0.5) * s;
    vec2 sin_part = complex_sin(pi_s_2.x, pi_s_2.y);
    log_sum += complex_log(sin_part.x, sin_part.y);

    log_sum += complex_log_gamma(s1.x, s1.y);

    vec2 zeta_part = zeta(s1.x, s1.y);
    log_sum += complex_log(zeta_part.x, zeta_part.y);

    return complex_exp(log_sum.x, log_sum.y);
}

FieldData zeta_continuation_with_derivatives(float sigma, float t, int iters) {
    if (sigma >= 0.5) return zeta_with_derivatives(sigma, t, iters);
    vec2 s = vec2(sigma, t);
    vec2 s1 = vec2(1.0 - sigma, -t);

    vec2 log_sum = complex_mul(s, vec2(log(2.0), 0.0))
                 + complex_mul(s - vec2(1.0, 0.0), vec2(log(PI), 0.0));
    vec2 ratio = vec2(log(2.0) + log(PI), 0.0);

    vec2 pi_s_2 = (PI * 0.5) * s;
    vec2 sin_part = complex_sin(pi_s_2.x, pi_s_2.y);
    vec2 cos_part = complex_cos(pi_s_2.x, pi_s_2.y);
    log_sum += complex_log(sin_part.x, sin_part.y);
    ratio += (PI * 0.5) * complex_div(cos_part, sin_part);

    FieldData lg_data = complex_log_gamma_with_derivatives(s1.x, s1.y);
    log_sum += lg_data.value;
    ratio -= lg_data.d_sigma; // d/ds log Gamma(1-s) = -psi(1-s)

    FieldData z_data = zeta_with_derivatives(s1.x, s1.y, iters);
    log_sum += complex_log(z_data.value.x, z_data.value.y);
    ratio -= complex_div(z_data.d_sigma, z_data.value); // d/ds log zeta(1-s) = -zeta'(1-s)/zeta(1-s)

    FieldData res;
    res.value = complex_exp(log_sum.x, log_sum.y);
    res.d_sigma = complex_mul(res.value, ratio);
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

//-------------------------------------------------------------------------
// Other Functions
//-------------------------------------------------------------------------

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

FieldData evaluate_poly_with_derivatives(float sigma, float t, float coeffs[10]) {
    vec2 z = vec2(sigma, t);
    vec2 val = vec2(0.0);
    vec2 deriv = vec2(0.0);
    vec2 z_pow = vec2(1.0, 0.0);
    for (int i = 0; i < 10; i++) {
        val += coeffs[i] * z_pow;
        if (i < 9) deriv += float(i + 1) * coeffs[i+1] * z_pow;
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
    vec2 deriv = complex_div(complex_mul(num.d_sigma, den.value) - complex_mul(num.value, den.d_sigma), den_sqr);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

//-------------------------------------------------------------------------
// Dispatchers
//-------------------------------------------------------------------------

FieldData get_field_with_derivatives(float x, float z) {
    float sigma = x * 0.1;
    float t = -z * 0.1;
    if (function_type == 0) return zeta_with_derivatives(sigma, t, iterations);
    if (function_type == 1) return zeta_continuation_with_derivatives(sigma, t, iterations);
    if (function_type == 2) return complex_gamma_with_derivatives(sigma, t);
    if (function_type == 3) return complex_log_gamma_with_derivatives(sigma, t);
    if (function_type == 4) return dedekind_eta_with_derivatives(sigma, t, iterations);
    if (function_type == 5) return complex_sin_with_derivatives(sigma, t);
    if (function_type == 6) return complex_cos_with_derivatives(sigma, t);
    if (function_type == 7) return complex_tan_with_derivatives(sigma, t);
    if (function_type == 8) return complex_exp_with_derivatives(sigma, t);
    if (function_type == 9) return complex_log_with_derivatives(sigma, t);
    if (function_type == 10) return get_rational_with_derivatives(sigma, t);
    FieldData res;
    res.value = vec2(0.0);
    res.d_sigma = vec2(0.0);
    res.d_t = vec2(0.0);
    return res;
}

vec2 get_field(float x, float z) {
    float sigma = x * 0.1;
    float t = -z * 0.1;
    if (function_type == 0) return zeta(sigma, t);
    if (function_type == 1) return zeta_continuation(sigma, t, iterations);
    if (function_type == 2) return complex_gamma(sigma, t);
    if (function_type == 3) return complex_log_gamma(sigma, t);
    if (function_type == 4) return dedekind_eta(sigma, t);
    if (function_type == 5) return complex_sin(sigma, t);
    if (function_type == 6) return complex_cos(sigma, t);
    if (function_type == 7) return complex_tan(sigma, t);
    if (function_type == 8) return complex_exp(sigma, t);
    if (function_type == 9) return complex_log(sigma, t);
    if (function_type == 10) return get_rational(sigma, t);
    return vec2(0.0);
}

float get_height(float x, float z) {
    vec2 f = get_field(x, z);
    float mag = length(f);
    if (height_type == 0) return height_a * log(height_epsilon + mag);
    return mag;
}

// Shared field and height functions for shaders

uniform int iterations = 120;
uniform int function_type = 0; // 0: Zeta, 1: Sin, 2: Cos, 3: Tan, 4: Exp, 5: Log, 6: Rational
uniform int height_type = 0;   // 0: Log, 1: Abs
uniform float height_a = 3.0;
uniform float height_epsilon = 1.0;

uniform float rational_num_coeffs[10];
uniform float rational_den_coeffs[10];

struct ZetaData {
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

    float denom = b.x * b.x + b.y * b.y;

    return vec2(
        (a.x * b.x + a.y * b.y) / denom,
        (a.y * b.x - a.x * b.y) / denom
    );
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

ZetaData zeta_with_derivatives(float sigma, float t, int iters) {
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

    ZetaData result;
    result.value = complex_div(eta, denom);

    vec2 denom_sqr = complex_mul(denom, denom);
    vec2 num_sigma = complex_mul(deta_dsigma, denom) - complex_mul(eta, ddenom_dsigma);
    result.d_sigma = complex_div(num_sigma, denom_sqr);
    result.d_t = vec2(-result.d_sigma.y, result.d_sigma.x);

    return result;
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

ZetaData complex_sin_with_derivatives(float sigma, float t) {
    ZetaData res;
    res.value = complex_sin(sigma, t);
    vec2 deriv = complex_cos(sigma, t);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

ZetaData complex_cos_with_derivatives(float sigma, float t) {
    ZetaData res;
    res.value = complex_cos(sigma, t);
    vec2 deriv = -complex_sin(sigma, t);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

ZetaData complex_tan_with_derivatives(float sigma, float t) {
    ZetaData res;
    res.value = complex_tan(sigma, t);
    vec2 cos_z = complex_cos(sigma, t);
    vec2 cos_z_sqr = complex_mul(cos_z, cos_z);
    vec2 deriv = complex_div(vec2(1.0, 0.0), cos_z_sqr);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

ZetaData complex_exp_with_derivatives(float sigma, float t) {
    ZetaData res;
    res.value = complex_exp(sigma, t);
    vec2 deriv = res.value;
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

ZetaData complex_log_with_derivatives(float sigma, float t) {
    ZetaData res;
    res.value = complex_log(sigma, t);
    vec2 z = vec2(sigma, t);
    vec2 deriv = complex_div(vec2(1.0, 0.0), z);
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

ZetaData evaluate_poly_with_derivatives(float sigma, float t, float coeffs[10]) {
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

    ZetaData res;
    res.value = val;
    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

ZetaData get_rational_with_derivatives(float sigma, float t) {
    ZetaData num = evaluate_poly_with_derivatives(sigma, t, rational_num_coeffs);
    ZetaData den = evaluate_poly_with_derivatives(sigma, t, rational_den_coeffs);

    ZetaData res;
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

ZetaData get_field_with_derivatives(float x, float z) {
	float sigma = x * 0.1;
	float t = -z * 0.1;

    if (function_type == 0) {
        return zeta_with_derivatives(sigma, t, iterations);
    } else if (function_type == 1) {
        return complex_sin_with_derivatives(sigma, t);
    } else if (function_type == 2) {
        return complex_cos_with_derivatives(sigma, t);
    } else if (function_type == 3) {
        return complex_tan_with_derivatives(sigma, t);
    } else if (function_type == 4) {
        return complex_exp_with_derivatives(sigma, t);
    } else if (function_type == 5) {
        return complex_log_with_derivatives(sigma, t);
    } else if (function_type == 6) {
        return get_rational_with_derivatives(sigma, t);
    }

    ZetaData res;
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
        return complex_sin(sigma, t);
    } else if (function_type == 2) {
        return complex_cos(sigma, t);
    } else if (function_type == 3) {
        return complex_tan(sigma, t);
    } else if (function_type == 4) {
        return complex_exp(sigma, t);
    } else if (function_type == 5) {
        return complex_log(sigma, t);
    } else if (function_type == 6) {
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

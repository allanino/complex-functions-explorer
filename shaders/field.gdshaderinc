// Shared field and height functions for shaders

uniform int iterations = 120;
uniform float zoom_factor = 1.0;
uniform int function_type = 0; // 0: Zeta, 1: Zeta continuation, 2: Dirichlet Eta, 3: Dirichlet Beta, 4: Gamma, 5: Log Gamma, 6: Dedekind Eta, 7: Mandelbrot, 8: Sin, 9: Cos, 10: Tan, 11: Exp, 12: Log, 13: Rational, 14: Multivalued
uniform int height_type = 0;   // 0: Log, 1: Abs
uniform float height_a = 3.0;
uniform float height_epsilon = 1.0;
uniform bool performance_protection_active = false;

uniform float rational_num_coeffs[10];
uniform float rational_den_coeffs[10];
uniform int multivalued_n = 2;
uniform int multivalued_mode = 0;
uniform float branch_cycle_speed = 0.5;
uniform float multivalued_morph_time = 0.1;
uniform float branch_time = 0.0;
uniform int current_branch = 0;

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
    float denom = b.x * b.x + b.y * b.y + 1e-24;
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
    if (mag < 1e-24) {
        return vec2(-60.0, 0.0);
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

/*
================================================================================
DERIVATION OF THE OVERFLOW-SAFE COMPLEX TANGENT FORMULA
================================================================================

Goal: Compute tan(x + iy) in a single Cartesian vec2 without evaluating raw
      sine or cosine functions that explode to INF when |y| is large.

1. Start with the standard real-hyperbolic identity for complex tangent:
   tan(x + iy) = [ sin(2x) + i*sinh(2y) ] / [ cosh(2y) + cos(2x) ]

2. Express the hyperbolic terms using their exponential definitions:
   cosh(2y) = (e^(2y) + e^(-2y)) / 2
   sinh(2y) = (e^(2y) - e^(-2y)) / 2

3. To prevent overflow when |y| is large, we can algebraically multiply the 
   entire numerator and denominator by a scaling factor of e^(-2|y|):
   tan(x + iy) = [ (sin(2x) + i*sinh(2y)) * e^(-2|y|) ] 
                 --------------------------------------
                 [ (cosh(2y) + cos(2x)) * e^(-2|y|) ]

4. Distribute the e^(-2|y|) scaling factor across the hyperbolic definitions:
   cosh(2y) * e^(-2|y|) = [(e^(2y) + e^(-2y)) / 2] * e^(-2|y|)
                        = (e^(2y - 2|y|) + e^(-2y - 2|y|)) / 2

   - When y >= 0:  1/2 * (e^(0) + e^(-4y))  = 0.5 * (1.0 + e^(-4|y|))
   - When y < 0:   1/2 * (e^(-4|y|) + e^0)  = 0.5 * (1.0 + e^(-4|y|))
   Therefore, scaled_cosh = 0.5 * (1.0 + e^(-4|y|)) globally.

5. Do the same for the sinh(2y) component, tracking the sign of y:
   sinh(2y) * e^(-2|y|) = [(e^(2y) - e^(-2y)) / 2] * e^(-2|y|)
                        = (e^(2y - 2|y|) - e^(-2y - 2|y|)) / 2

   - When y >= 0:  1/2 * (e^(0) - e^(-4y))  =  0.5 * (1.0 - e^(-4|y|))
   - When y < 0:   1/2 * (e^(-4|y|) - e^0)  = -0.5 * (1.0 - e^(-4|y|))
   Therefore, scaled_sinh = 0.5 * (1.0 - e^(-4|y|)) * sign(y) globally.

6. Distribute the e^(-2|y|) scaling factor across the standard trig terms:
   scaled_sin_2x = sin(2x) * e^(-2|y|)
   scaled_cos_2x = cos(2x) * e^(-2|y|)

7. Reconstruct the component fractions:
   Denominator = scaled_cosh + scaled_cos_2x
   Real Part   = scaled_sin_2x / Denominator
   Imag Part   = scaled_sinh / Denominator

Why this is bulletproof:
- As |y| grows, e^(-2|y|) and e^(-4|y|) safely underflow to 0.0.
- The denominator naturally approaches exactly 0.5 as |y| -> INF, completely 
  eliminating division-by-zero risks or precision blowouts.
- Real and imaginary components smoothly converge asymptotically to (0.0, sign(y)).
================================================================================
*/
vec2 complex_tan(float x, float y) {
    float abs_2y = 2.0 * abs(y);
    
    // This scales down the hyperbolic functions so they never overflow
    float exp_neg = exp(-abs_2y); 
    
    // Bounded hyperbolic terms (approach 0.5 and 0.5 * sign(y) respectively)
    float scaled_cosh = 0.5 * (1.0 + exp_neg * exp_neg);
    float scaled_sinh = 0.5 * (1.0 - exp_neg * exp_neg) * sign(y);
    
    // Scale standard trigonometric terms by the same factor
    float scaled_sin_2x = sin(2.0 * x) * exp_neg;
    float scaled_cos_2x = cos(2.0 * x) * exp_neg;
    
    // Denominator is completely safe from overflow/underflow now
    float denom = scaled_cosh + scaled_cos_2x;
    
    // Real part: sin(2x) / denom
    // Imaginary part: sinh(2y) / denom
    return vec2(scaled_sin_2x / denom, scaled_sinh / denom);
}

/*
================================================================================
DERIVATION OF THE OVERFLOW-SAFE COMPLEX COTANGENT FORMULA
================================================================================

Goal: Compute cot(x + iy) in a single Cartesian vec2 without evaluating raw
      hyperbolic functions that explode to INF when |y| is large.

1. Start with the standard real-hyperbolic identity for complex cotangent:
   cot(x + iy) = [ sin(2x) - i*sinh(2y) ] / [ cosh(2y) - cos(2x) ]

2. Express the hyperbolic terms using their exponential definitions:
   cosh(2y) = (e^(2y) + e^(-2y)) / 2
   sinh(2y) = (e^(2y) - e^(-2y)) / 2

3. To prevent overflow when |y| is large, we can algebraically multiply the 
   entire numerator and denominator by a scaling factor of e^(-2|y|):
   cot(x + iy) = [ (sin(2x) - i*sinh(2y)) * e^(-2|y|) ] 
                 --------------------------------------
                 [ (cosh(2y) - cos(2x)) * e^(-2|y|) ]

4. Distribute the e^(-2|y|) scaling factor across the hyperbolic definitions:
   cosh(2y) * e^(-2|y|) = [(e^(2y) + e^(-2y)) / 2] * e^(-2|y|)
                        = (e^(2y - 2|y|) + e^(-2y - 2|y|)) / 2

   - When y >= 0:  1/2 * (e^(0) + e^(-4y))  = 0.5 * (1.0 + e^(-4|y|))
   - When y < 0:   1/2 * (e^(-4|y|) + e^0)  = 0.5 * (1.0 + e^(-4|y|))
   Therefore, scaled_cosh = 0.5 * (1.0 + e^(-4|y|)) globally.

5. Do the same for the sinh(2y) component, tracking the sign of y:
   sinh(2y) * e^(-2|y|) = [(e^(2y) - e^(-2y)) / 2] * e^(-2|y|)
                        = (e^(2y - 2|y|) - e^(-2y - 2|y|)) / 2

   - When y >= 0:  1/2 * (e^(0) - e^(-4y))  =  0.5 * (1.0 - e^(-4|y|))
   - When y < 0:   1/2 * (e^(-4|y|) - e^0)  = -0.5 * (1.0 - e^(-4|y|))
   Therefore, scaled_sinh = 0.5 * (1.0 - e^(-4|y|)) * sign(y) globally.

6. Distribute the e^(-2|y|) scaling factor across the standard trig terms:
   scaled_sin_2x = sin(2x) * e^(-2|y|)
   scaled_cos_2x = cos(2x) * e^(-2|y|)

7. Reconstruct the component fractions:
   Denominator = scaled_cosh - scaled_cos_2x
   Real Part   = scaled_sin_2x / Denominator
   Imag Part   = -scaled_sinh / Denominator

Why this is bulletproof:
- As |y| grows, e^(-2|y|) and e^(-4|y|) safely underflow to 0.0.
- The denominator naturally approaches exactly 0.5 as |y| -> INF, completely 
  eliminating division-by-zero risks or precision blowouts.
- Real and imaginary components smoothly converge asymptotically to (0.0, -sign(y)).
================================================================================
*/

vec2 complex_cot(float x, float y) {
    float abs_2y = 2.0 * abs(y);
    
    // This scales down the hyperbolic functions so they never overflow
    float exp_neg = exp(-abs_2y); 
    
    // Bounded hyperbolic terms:
    // cosh(2y) * e^(-2|y|) approaches 0.5 as |y| grows
    // sinh(2y) * e^(-2|y|) approaches 0.5 * sign(y) as |y| grows
    float scaled_cosh = 0.5 * (1.0 + exp_neg * exp_neg);
    float scaled_sinh = 0.5 * (1.0 - exp_neg * exp_neg) * sign(y);
    
    // We must also scale the standard cos/sin terms by the same factor
    float scaled_sin_2x = sin(2.0 * x) * exp_neg;
    float scaled_cos_2x = cos(2.0 * x) * exp_neg;
    
    // Denominator is completely safe from overflow now
    float denom = scaled_cosh - scaled_cos_2x;
    
    // Real part: sin(2x) / denom
    // Imaginary part: -sinh(2y) / denom
    return vec2(scaled_sin_2x / denom, -scaled_sinh / denom);
}

/*
================================================================================
DERIVATION OF THE OVERFLOW-SAFE COMPLEX LOG SINE FORMULA
================================================================================

Goal: Compute ln(sin(x + iy)) directly in log-space without evaluating massive
      exponential terms that overflow standard floating-point limits.

1. Start with the standard Cartesian definition of complex sine:
   sin(x + iy) = sin(x)*cosh(y) + i*cos(x)*sinh(y)

2. Express the hyperbolic functions in terms of their exponential components:
   cosh(y) = (e^|y| + e^-|y|) / 2
   sinh(y) = sign(y) * (e^|y| - e^-|y|) / 2

3. Substitute these exponential definitions back into step 1:
   sin(x + iy) = sin(x) * [(e^|y| + e^-|y|) / 2] + i*cos(x) * [sign(y) * (e^|y| - e^-|y|) / 2]

4. Factor out the dominant scaling factor, (e^|y| / 2), from both terms:
   sin(x + iy) = (e^|y| / 2) * [ sin(x)*(1 + e^(-2|y|)) + i * sign(y)*cos(x)*(1 - e^(-2|y|)) ]

5. Apply the complex logarithm identity, ln(A * B) = ln(A) + ln(B):
   ln(sin(x + iy)) = ln(e^|y| / 2) + ln[ sin(x)*(1 + e^(-2|y|)) + i * sign(y)*cos(x)*(1 - e^(-2|y|)) ]

6. Simplify the first log term using basic logarithm rules:
   ln(e^|y| / 2) = ln(e^|y|) - ln(2)
                 = |y| - ln(2)

7. This yields the final, completely stable two-part equation:
   Real Scaler (log_scale) = |y| - ln(2)
   Bounded Internal Z      = vec2( sin(x)*(1 + e^(-2|y|)), sign(y)*cos(x)*(1 - e^(-2|y|)) )

   Result = vec2(log_scale, 0.0) + complex_log(Internal Z)

Why this is bulletproof:
- As |y| grows, e^(-2|y|) cleanly underflows to 0.0 instead of exploding to INF.
- Internal Z stays strictly bounded between 0.0 and 2.0 everywhere in the plane.
- Eliminates catastrophic subtraction cancellation near the real axis (y ≈ 0).
================================================================================
*/
vec2 complex_log_sin(float x, float y) {
    float abs_y = abs(y);
    
    // Mathematically exact scale factor in log-space
    float log_scale = abs_y - log(2.0);
    
    // e^(-2 * |y|)
    float e_neg2 = exp(-2.0 * abs_y);
    
    // Derived directly from first principles:
    // Real part gets the (1.0 + e_neg2) factor
    // Imaginary part gets the sign(y) * (1.0 - e_neg2) factor
    vec2 internal_z = vec2(
        sin(x) * (1.0 + e_neg2),
        sign(y) * cos(x) * (1.0 - e_neg2)
    );
    
    // Let your standard complex_log handle the phase tracking smoothly
    vec2 log_internal = complex_log(internal_z.x, internal_z.y);
    
    return vec2(log_scale + log_internal.x, log_internal.y);
}

//-------------------------------------------------------------------------
// Component Functions: Zeta, Gamma, Dedekind Eta
//-------------------------------------------------------------------------

FieldData dirichlet_eta_with_derivatives(float sigma, float t, int iters) {
    vec2 eta = vec2(0.0);
    vec2 deta_dsigma = vec2(0.0);
    for (int n = 1; n <= iters; n += 2) {
        float nf = float(n);
        float amp = pow(nf, -sigma);
        float log_n = log(nf);
        float theta = -t * log_n;
        vec2 term = amp * vec2(cos(theta), sin(theta));
        eta += term;
        deta_dsigma -= log_n * term;

        float nf2 = float(n + 1);
        float amp2 = pow(nf2, -sigma);
        float log_n2 = log(nf2);
        float theta2 = -t * log_n2;
        vec2 term2 = amp2 * vec2(cos(theta2), sin(theta2));
        eta -= term2;
        deta_dsigma += log_n2 * term2;

        if (amp < 1e-6 || amp2 < 1e-6 || amp > 1e6 || amp2 > 1e6) break;
    }
    FieldData result;
    result.value = eta;
    result.d_sigma = deta_dsigma;
    result.d_t = vec2(-result.d_sigma.y, result.d_sigma.x);
    return result;
}

FieldData dirichlet_beta_with_derivatives(float sigma, float t, int iters) {
    vec2 beta = vec2(0.0);
    vec2 dbeta_dsigma = vec2(0.0);
    for (int n = 0; n < iters; n += 2) {
        float kf = 2.0 * float(n) + 1.0;
        float amp = pow(kf, -sigma);
        float log_k = log(kf);
        float theta = -t * log_k;
        vec2 term = amp * vec2(cos(theta), sin(theta));
        beta += term;
        dbeta_dsigma -= log_k * term;

        float kf2 = 2.0 * float(n + 1) + 1.0;
        float amp2 = pow(kf2, -sigma);
        float log_k2 = log(kf2);
        float theta2 = -t * log_k2;
        vec2 term2 = amp2 * vec2(cos(theta2), sin(theta2));
        beta -= term2;
        dbeta_dsigma += log_k2 * term2;

        if (amp < 1e-6 || amp2 < 1e-6 || amp > 1e6 || amp2 > 1e6) break;
    }
    FieldData result;
    result.value = beta;
    result.d_sigma = dbeta_dsigma;
    result.d_t = vec2(-result.d_sigma.y, result.d_sigma.x);
    return result;
}

FieldData zeta_with_derivatives(float sigma, float t, int iters) {
    FieldData eta_data = dirichlet_eta_with_derivatives(sigma, t, iters);
    vec2 eta = eta_data.value;
    vec2 deta_dsigma = eta_data.d_sigma;

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
        // Gamma(z) = pi / (sin(pi z) * Gamma(1-z))
        // d/dz log Gamma(z) = -pi cot(pi z) - d/dz log Gamma(1-z)
        // d/dz log Gamma(1-z) = -psi(1-z)
        // So d/dz log Gamma(z) = -pi cot(pi z) + psi(1-z)

        FieldData g1z = lanczos_gamma_with_derivatives(vec2(1.0 - sigma, -t));
        vec2 sin_pi_z = complex_sin(pi_z.x, pi_z.y);
        vec2 cot_pi_z = complex_div(complex_cos(pi_z.x, pi_z.y), sin_pi_z);

        // d/dz ln Gamma(1-z) = [Gamma'(1-z)/Gamma(1-z)] * (-1) = -psi(1-z)
        // g1z.d_sigma is Gamma'(1-z)
        // psi(1-z) = g1z.d_sigma / g1z.value
        // ratio = -pi cot(pi z) - (-psi(1-z)) = -pi cot(pi z) + psi(1-z)

        vec2 ratio = -PI * cot_pi_z + complex_div(g1z.d_sigma, g1z.value);

        FieldData res;
        res.value = complex_div(vec2(PI, 0.0), complex_mul(sin_pi_z, g1z.value));
        res.d_sigma = complex_mul(res.value, ratio);
        res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
        return res;
    }
    return lanczos_gamma_with_derivatives(vec2(sigma, t));
}

// 3. Log Gamma
FieldData lanczos_log_gamma_with_derivatives(vec2 z) {
    vec2 z_m1 = z - vec2(1.0, 0.0);
    vec2 x = vec2(LANCZOS_P[0], 0.0);
    vec2 dx = vec2(0.0, 0.0);
    for (int i = 1; i < 9; i++) {
        vec2 denom = z_m1 + vec2(float(i), 0.0);
        x += complex_div(vec2(LANCZOS_P[i], 0.0), denom);
        dx -= complex_div(vec2(LANCZOS_P[i], 0.0), complex_mul(denom, denom));
    }
    vec2 tmp = z_m1 + vec2(7.5, 0.0);
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
    FieldData res;
    if (sigma < 0.5) {
        vec2 pi_z = vec2(PI * sigma, PI * t);
        // ln Gamma(z) = ln pi - ln sin(pi z) - ln Gamma(1-z)
        // d/dz = -pi cot(pi z) - (-psi(1-z)) = -pi cot(pi z) + psi(1-z)

        FieldData lg1z = lanczos_log_gamma_with_derivatives(vec2(1.0 - sigma, -t));

        vec2 log_sin_pi_z = complex_log_sin(pi_z.x, pi_z.y);

        res.value = vec2(log(PI), 0.0) - log_sin_pi_z - lg1z.value;

        vec2 cot_pi_z =  complex_cot(pi_z.x, pi_z.y);
        res.d_sigma = -PI * cot_pi_z + lg1z.d_sigma;
    } else {
        res = lanczos_log_gamma_with_derivatives(vec2(sigma, t));
    }
    res.d_t = vec2(-res.d_sigma.y, res.d_sigma.x);
    return res;
}

// 4. Dedekind Eta
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

// 5. Mandelbrot
FieldData mandelbrot_with_derivatives(float sigma, float t, int iters) {
    vec2 c = vec2(sigma, t);
    vec2 z = vec2(0.0);
    vec2 dz = vec2(0.0);
    for (int i = 0; i < iters; i++) {
        dz = 2.0 * complex_mul(z, dz) + vec2(1.0, 0.0);
        z = complex_mul(z, z) + c;
        if (dot(z, z) > 100.0) break;
    }
    FieldData res;
    res.value = z;
    res.d_sigma = dz;
    res.d_t = vec2(-dz.y, dz.x);
    return res;
}

//-------------------------------------------------------------------------
// Composite Functions
//-------------------------------------------------------------------------

FieldData zeta_continuation_with_derivatives(float sigma, float t, int iters) {
    if (sigma >= 0.5) return zeta_with_derivatives(sigma, t, iters);
    
    vec2 s = vec2(sigma, t);
    vec2 s1 = vec2(1.0 - sigma, -t);

    // 1. Core linear log terms
    vec2 log_sum = complex_mul(s, vec2(log(2.0), 0.0))
                 + complex_mul(s - vec2(1.0, 0.0), vec2(log(PI), 0.0));
                 
    vec2 ratio = vec2(log(2.0) + log(PI), 0.0);

    // 2. Safely compute the sin/cot parts using our log-space tools
    vec2 pi_s_2 = (PI * 0.5) * s;
    
    // Completely safe log(sin(pi * s / 2))
    log_sum += complex_log_sin(pi_s_2.x, pi_s_2.y);
    
    // Completely safe cot(pi * s / 2)
    ratio += (PI * 0.5) * complex_cot(pi_s_2.x, pi_s_2.y);

    // 3. Bring in the upgraded Log Gamma
    FieldData lg_data = complex_log_gamma_with_derivatives(s1.x, s1.y);
    log_sum += lg_data.value;
    ratio -= lg_data.d_sigma; // d/ds log Gamma(1-s) = -psi(1-s)

    // 4. Bring in the reflected Zeta
    FieldData z_data = zeta_with_derivatives(s1.x, s1.y, iters);
    log_sum += complex_log(z_data.value.x, z_data.value.y);
    ratio -= complex_div(z_data.d_sigma, z_data.value); // d/ds log zeta(1-s) = -zeta'(1-s)/zeta(1-s)

    // 5. Exponentiate back out to standard space
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

/*
================================================================================
DERIVATION OF THE OVERFLOW-SAFE COMPLEX TANGENT WITH DERIVATIVES
================================================================================

Goal: Compute tan(z) and its derivative d/dz tan(z) without evaluating raw 
      cosine functions that explode to INF when |y| is large.

1. Compute the stable value first:
   vec2 T = complex_tan_stable(sigma, t);  // T = u + iv

2. Use the trigonometric identity for the derivative of tangent:
   d/dz tan(z) = sec^2(z) = 1 + tan^2(z)

3. Expand tan^2(z) into real and imaginary components:
   tan^2(z) = (u + iv)*(u + iv)
            = (u^2 - v^2) + i*(2*u*v)

4. Add 1.0 to get the final complex derivative:
   deriv.x = 1.0 + u^2 - v^2
   deriv.y = 2.0 * u * v

Why this is bulletproof:
- It completely bypasses complex_cos and complex_mul(cos, cos).
- As |y| -> INF, the stable tangent value T smoothly approaches (0.0, sign(y)).
- Plugging those limits into the derivative formula yields:
  deriv.x = 1.0 + 0.0 - (sign(y))^2 = 1.0 - 1.0 = 0.0
  deriv.y = 2.0 * 0.0 * sign(y) = 0.0
- The derivative safely and perfectly drops to (0.0, 0.0) without ever hitting an intermediate INF.
================================================================================
*/
FieldData complex_tan_with_derivatives(float sigma, float t) {
    FieldData res;
    
    // 1. Calculate value safely using the real-hyperbolic identity
    res.value = complex_tan(sigma, t);
    
    // 2. Extract components: T = u + iv
    float u = res.value.x;
    float v = res.value.y;
    
    // 3. Compute the derivative directly from the value: d/dz = 1 + T^2
    vec2 deriv = vec2(
        1.0 + (u * u) - (v * v),
        2.0 * u * v
    );
    
    // 4. Assign directional derivatives matching your grid space
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

FieldData multivalued_z_pow_inv_n_with_derivatives(float sigma, float t, int n, float cycle_speed, int branch_offset) {
    FieldData res;
    float r_sq = sigma * sigma + t * t;
    float r = sqrt(r_sq);
    float theta = atan(t, sigma);
    if (theta < 0.0) theta += 2.0 * PI;
    float float_n = float(n);

    float blend_factor = 0.0;
    float k_val = 0.0;

    if (multivalued_mode == 0) { // Time cycle
        // Temporal branch selection & blending factor
        float progress = fract(branch_time * cycle_speed) * float_n;
        k_val = floor(progress);
        float t_in_branch = fract(progress);

        // Non-linear transition: stay on branch, then morph
        float dwell_time = (1.0 / float_n) - multivalued_morph_time * cycle_speed;
        dwell_time = max(dwell_time, 0.0);
        float transition_threshold = dwell_time * float_n;
        blend_factor = smoothstep(transition_threshold, 1.0, t_in_branch);
    } else { // Branch portals
        k_val = float((current_branch + branch_offset + n) % n);
    }

    float morphed_phase = (theta + 2.0 * PI * (k_val + blend_factor)) / float_n;
    float morphed_r = pow(r, 1.0 / float_n);
    res.value = vec2(morphed_r * cos(morphed_phase), morphed_r * sin(morphed_phase));

    // dW/dZ = (1/n) * W / Z
    vec2 z = vec2(sigma, t);
    vec2 deriv = complex_div(res.value, float_n * z);

    res.d_sigma = deriv;
    res.d_t = vec2(-deriv.y, deriv.x);
    return res;
}

//-------------------------------------------------------------------------
// Dispatchers
//-------------------------------------------------------------------------

FieldData get_field_with_derivatives(float x, float z, int branch_offset) {
    float zoom = 1.0 / zoom_factor;
    float sigma = x * 0.1 * zoom;
    float t = -z * 0.1 * zoom;
    if (function_type == 0) return zeta_with_derivatives(sigma, t, iterations);
    if (function_type == 1) return zeta_continuation_with_derivatives(sigma, t, iterations);
    if (function_type == 2) return dirichlet_eta_with_derivatives(sigma, t, iterations);
    if (function_type == 3) return dirichlet_beta_with_derivatives(sigma, t, iterations);
    if (function_type == 4) return complex_gamma_with_derivatives(sigma, t);
    if (function_type == 5) return complex_log_gamma_with_derivatives(sigma, t);
    if (function_type == 6) return dedekind_eta_with_derivatives(sigma, t, iterations);
    if (function_type == 7) return mandelbrot_with_derivatives(sigma, t, iterations);
    if (function_type == 8) return complex_sin_with_derivatives(sigma, t);
    if (function_type == 9) return complex_cos_with_derivatives(sigma, t);
    if (function_type == 10) return complex_tan_with_derivatives(sigma, t);
    if (function_type == 11) return complex_exp_with_derivatives(sigma, t);
    if (function_type == 12) return complex_log_with_derivatives(sigma, t);
    if (function_type == 13) return get_rational_with_derivatives(sigma, t);
    if (function_type == 14) return multivalued_z_pow_inv_n_with_derivatives(sigma, t, multivalued_n, branch_cycle_speed, branch_offset);
    FieldData res;
    res.value = vec2(0.0);
    res.d_sigma = vec2(0.0);
    res.d_t = vec2(0.0);
    return res;
}
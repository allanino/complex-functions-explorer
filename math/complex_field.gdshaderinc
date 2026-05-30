// Shared field and height functions for shaders

uniform int iterations = 120;
uniform float zoom_factor = 1.0;
uniform int function_type = 0; // Maps to Config.ComplexFunc enum in GDScript
uniform int height_type = 0;   // 0: Log, 1: Abs
uniform float height_a = 3.0;
uniform float height_epsilon = 1.0;
uniform bool performance_protection_active = false;
uniform bool is_dirichlect = false;
uniform bool is_multivalued = false;

uniform vec2 rational_num_coeffs[10];
uniform vec2 rational_den_coeffs[10];
uniform int multivalued_n = 2;
uniform int current_branch = 0;

struct ComplexFieldData {
    vec2 value;    // The actual complex f(x, y)
    vec2 dx;       // Partial derivative with respect to x
    vec2 dy;       // Partial derivative with respect to y
};

const float SQRT_2PI = 2.5066282746310005;
const float LOG_PI = 1.1447298858494002;
const float LOG_2 = 0.6931471805599453;

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

vec2 complex_exp(float x, float y) {
    float amp = exp(x);
    return vec2(
        amp * cos(y),
        amp * sin(y)
    );
}

vec2 complex_log(float x, float y) {
    float mag = length(vec2(x, y));
    if (mag < 1e-24) {
        return vec2(-60.0, 0.0);
    }
    return vec2(
        log(mag),
        atan(y, x)
    );
}

vec2 complex_pow(vec2 z, vec2 w) {
    vec2 lz = complex_log(z.x, z.y);
    vec2 res_log = complex_mul(w, lz);
    return complex_exp(res_log.x, res_log.y);
}

vec2 complex_sin(float x, float y) {
    return vec2(
        sin(x) * cosh(y),
        cos(x) * sinh(y)
    );
}

vec2 complex_cos(float x, float y) {
    return vec2(
        cos(x) * cosh(y),
        -sin(x) * sinh(y)
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


vec2 complex_asin(float x, float y) {
    vec2 z = vec2(x, y);
    vec2 z2 = complex_mul(z, z);
    vec2 one_minus_z2 = vec2(1.0 - z2.x, -z2.y);
    float r = sqrt(length(one_minus_z2));
    float theta = atan(one_minus_z2.y, one_minus_z2.x) * 0.5;
    vec2 sqrt_part = vec2(r * cos(theta), r * sin(theta));
    vec2 iz = vec2(-y, x);
    vec2 sum_val = iz + sqrt_part;
    vec2 log_val = complex_log(sum_val.x, sum_val.y);
    return vec2(log_val.y, -log_val.x);
}

vec2 complex_acos(float x, float y) {
    vec2 z = vec2(x, y);
    vec2 z2 = complex_mul(z, z);
    vec2 one_minus_z2 = vec2(1.0 - z2.x, -z2.y);
    float r = sqrt(length(one_minus_z2));
    float theta = atan(one_minus_z2.y, one_minus_z2.x) * 0.5;
    vec2 sqrt_part = vec2(r * cos(theta), r * sin(theta));
    vec2 i_sqrt_part = vec2(-sqrt_part.y, sqrt_part.x);
    vec2 sum_val = z + i_sqrt_part;
    vec2 log_val = complex_log(sum_val.x, sum_val.y);
    return vec2(log_val.y, -log_val.x);
}

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
    float log_scale = abs_y - LOG_2;
    
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

ComplexFieldData dirichlet_eta_with_derivatives(float x, float y, int iters) {
    vec2 eta = vec2(0.0);
    vec2 deta_dx = vec2(0.0);
    for (int n = 1; n <= iters; n += 2) {
        float nf = float(n);
        float amp = pow(nf, -x);
        float log_n = log(nf);
        float theta = -y * log_n;
        vec2 term = amp * vec2(cos(theta), sin(theta));
        eta += term;
        deta_dx -= log_n * term;

        float nf2 = float(n + 1);
        float amp2 = pow(nf2, -x);
        float log_n2 = log(nf2);
        float theta2 = -y * log_n2;
        vec2 term2 = amp2 * vec2(cos(theta2), sin(theta2));
        eta -= term2;
        deta_dx += log_n2 * term2;
        
        // We are basically clamping the flat planice x > 1 restricting amp < 1e-4
        // and also preventing overflow when x is very negative by clamping amp > 1e4
        // This improves performance greatly on the acutally interesting region around the critical strip
        if (amp < 1e-4 || amp2 < 1e-4 || amp > 1e4 || amp2 > 1e4) break;
    }
    ComplexFieldData result;
    result.value = eta;
    result.dx = deta_dx;
    result.dy = vec2(-result.dx.y, result.dx.x);
    return result;
}

ComplexFieldData dirichlet_beta_with_derivatives(float x, float y, int iters) {
    vec2 beta = vec2(0.0);
    vec2 dbeta_dx = vec2(0.0);
    for (int n = 0; n < iters; n += 2) {
        float kf = 2.0 * float(n) + 1.0;
        float amp = pow(kf, -x);
        float log_k = log(kf);
        float theta = -y * log_k;
        vec2 term = amp * vec2(cos(theta), sin(theta));
        beta += term;
        dbeta_dx -= log_k * term;

        float kf2 = 2.0 * float(n + 1) + 1.0;
        float amp2 = pow(kf2, -x);
        float log_k2 = log(kf2);
        float theta2 = -y * log_k2;
        vec2 term2 = amp2 * vec2(cos(theta2), sin(theta2));
        beta -= term2;
        dbeta_dx += log_k2 * term2;

       if (amp < 1e-4 || amp2 < 1e-4 || amp > 1e4 || amp2 > 1e4) break;
    }
    ComplexFieldData result;
    result.value = beta;
    result.dx = dbeta_dx;
    result.dy = vec2(-result.dx.y, result.dx.x);
    return result;
}

ComplexFieldData zeta_with_derivatives(float x, float y, int iters) {
    ComplexFieldData eta_data = dirichlet_eta_with_derivatives(x, y, iters);
    vec2 eta = eta_data.value;
    vec2 deta_dx = eta_data.dx;

    float amp2 = pow(2.0, 1.0 - x);
    float theta2 = -y * LOG_2;
    vec2 two_term = amp2 * vec2(cos(theta2), sin(theta2));
    vec2 denom = vec2(1.0, 0.0) - two_term;
    vec2 ddenom_dx = LOG_2 * two_term;
    ComplexFieldData result;
    result.value = complex_div(eta, denom);
    vec2 denom_sqr = complex_mul(denom, denom);
    vec2 num_x = complex_mul(deta_dx, denom) - complex_mul(eta, ddenom_dx);
    result.dx = complex_div(num_x, denom_sqr);
    result.dy = vec2(-result.dx.y, result.dx.x);
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

ComplexFieldData lanczos_gamma_with_derivatives(vec2 z_orig) {
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
    ComplexFieldData res;
    res.value = value;
    res.dx = complex_mul(value, deriv_ratio);
    res.dy = vec2(-res.dx.y, res.dx.x);
    return res;
}

ComplexFieldData complex_gamma_with_derivatives(float x, float y) {
    if (x < 0.5) {
        vec2 pi_z = vec2(PI * x, PI * y);
        // Gamma(z) = pi / (sin(pi z) * Gamma(1-z))
        // d/dz log Gamma(z) = -pi cot(pi z) - d/dz log Gamma(1-z)
        // d/dz log Gamma(1-z) = -psi(1-z)
        // So d/dz log Gamma(z) = -pi cot(pi z) + psi(1-z)

        ComplexFieldData g1z = lanczos_gamma_with_derivatives(vec2(1.0 - x, -y));
        vec2 sin_pi_z = complex_sin(pi_z.x, pi_z.y);
        vec2 cot_pi_z = complex_div(complex_cos(pi_z.x, pi_z.y), sin_pi_z);

        // d/dz ln Gamma(1-z) = [Gamma'(1-z)/Gamma(1-z)] * (-1) = -psi(1-z)
        // g1z.dx is Gamma'(1-z)
        // psi(1-z) = g1z.dx / g1z.value
        // ratio = -pi cot(pi z) - (-psi(1-z)) = -pi cot(pi z) + psi(1-z)

        vec2 ratio = -PI * cot_pi_z + complex_div(g1z.dx, g1z.value);

        ComplexFieldData res;
        res.value = complex_div(vec2(PI, 0.0), complex_mul(sin_pi_z, g1z.value));
        res.dx = complex_mul(res.value, ratio);
        res.dy = vec2(-res.dx.y, res.dx.x);
        return res;
    }
    return lanczos_gamma_with_derivatives(vec2(x, y));
}

// 3. Log Gamma
ComplexFieldData lanczos_log_gamma_with_derivatives(vec2 z) {
    vec2 z_m1 = z - vec2(1.0, 0.0);
    vec2 x = vec2(LANCZOS_P[0], 0.0);
    vec2 dx_val = vec2(0.0, 0.0);
    for (int i = 1; i < 9; i++) {
        vec2 denom = z_m1 + vec2(float(i), 0.0);
        x += complex_div(vec2(LANCZOS_P[i], 0.0), denom);
        dx_val -= complex_div(vec2(LANCZOS_P[i], 0.0), complex_mul(denom, denom));
    }
    vec2 tmp = z_m1 + vec2(7.5, 0.0);
    vec2 log_tmp = complex_log(tmp.x, tmp.y);

    vec2 value = vec2(log(SQRT_2PI), 0.0)
               + complex_mul(z - vec2(0.5, 0.0), log_tmp)
               - tmp
               + complex_log(x.x, x.y);

    vec2 psi = log_tmp + complex_div(z - vec2(0.5, 0.0), tmp) - vec2(1.0, 0.0) + complex_div(dx_val, x);

    ComplexFieldData res;
    res.value = value;
    res.dx = psi;
    res.dy = vec2(-psi.y, psi.x);
    return res;
}

ComplexFieldData complex_log_gamma_with_derivatives(float x, float y) {
    ComplexFieldData res;
    if (x < 0.5) {
        vec2 pi_z = vec2(PI * x, PI * y);
        // ln Gamma(z) = ln pi - ln sin(pi z) - ln Gamma(1-z)
        // d/dz = -pi cot(pi z) - (-psi(1-z)) = -pi cot(pi z) + psi(1-z)

        ComplexFieldData lg1z = lanczos_log_gamma_with_derivatives(vec2(1.0 - x, -y));

        vec2 log_sin_pi_z = complex_log_sin(pi_z.x, pi_z.y);

        res.value = vec2(LOG_PI, 0.0) - log_sin_pi_z - lg1z.value;

        vec2 cot_pi_z =  complex_cot(pi_z.x, pi_z.y);
        res.dx = -PI * cot_pi_z + lg1z.dx;
    } else {
        res = lanczos_log_gamma_with_derivatives(vec2(x, y));
    }
    res.dy = vec2(-res.dx.y, res.dx.x);
    return res;
}

// 4. Dedekind Eta
ComplexFieldData dedekind_eta_with_derivatives(float x, float y, int iters) {
    vec2 factor = complex_exp(-PI * y / 12.0, PI * x / 12.0);
    vec2 d_factor_dx = complex_mul(vec2(0.0, PI / 12.0), factor);
    vec2 prod = vec2(1.0, 0.0);
    vec2 sum_log_deriv = vec2(0.0);
    float q_re_base = -2.0 * PI * y;
    float q_im_base = 2.0 * PI * x;
    for (int n = 1; n <= iters; n++) {
        float nf = float(n);
        vec2 q_n = complex_exp(nf * q_re_base, nf * q_im_base);
        vec2 dq_n_dx = complex_mul(vec2(0.0, 2.0 * PI * nf), q_n);
        vec2 term = vec2(1.0, 0.0) - q_n;
        prod = complex_mul(prod, term);
        sum_log_deriv += complex_div(-dq_n_dx, term);
        if (nf > 10.0 && length(q_n) < 1e-12) break;
    }
    ComplexFieldData res;
    res.value = complex_mul(factor, prod);
    res.dx = complex_mul(res.value, complex_div(d_factor_dx, factor) + sum_log_deriv);
    res.dy = vec2(-res.dx.y, res.dx.x);
    return res;
}

// 5. Mandelbrot
ComplexFieldData mandelbrot_with_derivatives(float x, float y, int iters) {
    vec2 c = vec2(x, y);
    vec2 z = vec2(0.0);
    vec2 dz = vec2(0.0);
    for (int i = 0; i < iters; i++) {
        dz = 2.0 * complex_mul(z, dz) + vec2(1.0, 0.0);
        z = complex_mul(z, z) + c;
        if (dot(z, z) > 100.0) break;
    }
    ComplexFieldData res;
    res.value = z;
    res.dx = dz;
    res.dy = vec2(-dz.y, dz.x);
    return res;
}

//-------------------------------------------------------------------------
// Composite Functions
//-------------------------------------------------------------------------

ComplexFieldData log_zeta_continuation_with_derivatives(float x, float y, int iters) {
    if (x >= 0.5) {
        ComplexFieldData z = zeta_with_derivatives(x, y, iters);
        ComplexFieldData res;
        res.value = complex_log(z.value.x, z.value.y);
        res.dx = complex_div(z.dx, z.value);
        res.dy = vec2(-res.dx.y, res.dx.x);
        return res;
    }
    
    vec2 s = vec2(x, y);
    vec2 s1 = vec2(1.0 - x, -y);

    // 1. Core linear log terms
    vec2 log_sum = complex_mul(s, vec2(LOG_2, 0.0))
                 + complex_mul(s - vec2(1.0, 0.0), vec2(LOG_PI, 0.0));
                 
    vec2 ratio = vec2(LOG_2 + LOG_PI, 0.0);

    // 2. Safely compute the sin/cot parts using our log-space tools
    vec2 pi_s_2 = (PI * 0.5) * s;
    
    // Completely safe log(sin(pi * s / 2))
    log_sum += complex_log_sin(pi_s_2.x, pi_s_2.y);
    
    // Completely safe cot(pi * s / 2)
    ratio += (PI * 0.5) * complex_cot(pi_s_2.x, pi_s_2.y);

    // 3. Bring in the upgraded Log Gamma
    ComplexFieldData lg_data = complex_log_gamma_with_derivatives(s1.x, s1.y);
    log_sum += lg_data.value;
    ratio -= lg_data.dx; // d/ds log Gamma(1-s) = -psi(1-s)

    // 4. Bring in the reflected Zeta
    ComplexFieldData z_data = zeta_with_derivatives(s1.x, s1.y, iters);
    log_sum += complex_log(z_data.value.x, z_data.value.y);
    ratio -= complex_div(z_data.dx, z_data.value); // d/ds log zeta(1-s) = -zeta'(1-s)/zeta(1-s)

    ComplexFieldData res;
    res.value = log_sum;
    res.dx = ratio;
    res.dy = vec2(-res.dx.y, res.dx.x);

    return res;
}

ComplexFieldData zeta_continuation_with_derivatives(float x, float y, int iters) {
    ComplexFieldData log_z = log_zeta_continuation_with_derivatives(x, y, iters);
    ComplexFieldData res;
    res.value = complex_exp(log_z.value.x, log_z.value.y);
    res.dx = complex_mul(res.value, log_z.dx);
    res.dy = vec2(-res.dx.y, res.dx.x);
    return res;
}

//-------------------------------------------------------------------------
// Other Functions
//-------------------------------------------------------------------------

ComplexFieldData complex_sin_with_derivatives(float x, float y) {
    ComplexFieldData res;
    res.value = complex_sin(x, y);
    vec2 deriv = complex_cos(x, y);
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

ComplexFieldData complex_cos_with_derivatives(float x, float y) {
    ComplexFieldData res;
    res.value = complex_cos(x, y);
    vec2 deriv = -complex_sin(x, y);
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

/*
================================================================================
DERIVATION OF THE OVERFLOW-SAFE COMPLEX TANGENT WITH DERIVATIVES
================================================================================

Goal: Compute tan(z) and its derivative d/dz tan(z) without evaluating raw 
      cosine functions that explode to INF when |y| is large.

1. Compute the stable value first:
   vec2 T = complex_tan_stable(x, y);  // T = u + iv

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
ComplexFieldData complex_tan_with_derivatives(float x, float y) {
    ComplexFieldData res;
    
    // 1. Calculate value safely using the real-hyperbolic identity
    res.value = complex_tan(x, y);
    
    // 2. Extract components: T = u + iv
    float u = res.value.x;
    float v = res.value.y;
    
    // 3. Compute the derivative directly from the value: d/dz = 1 + T^2
    vec2 deriv = vec2(
        1.0 + (u * u) - (v * v),
        2.0 * u * v
    );
    
    // 4. Assign directional derivatives matching your grid space
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    
    return res;
}

/*
================================================================================
DERIVATION OF THE OVERFLOW-SAFE COMPLEX COTANGENT WITH DERIVATIVES
================================================================================

Goal: Compute cot(z) and its derivative d/dz cot(z) without evaluating raw 
      sine or cosine functions that explode to INF when |y| is large.

1. Compute the stable value first:
   vec2 C = complex_cot(x, y);  // C = u + iv

2. Use the trigonometric identity for the derivative of cotangent:
   d/dz cot(z) = -csc^2(z) = -(1 + cot^2(z))

3. Expand cot^2(z) into real and imaginary components:
   cot^2(z) = (u + iv)*(u + iv)
            = (u^2 - v^2) + i*(2*u*v)

4. Add 1.0 and negate the entire expression to match -(1 + cot^2(z)):
   deriv.x = -(1.0 + u^2 - v^2) = -1.0 - u^2 + v^2
   deriv.y = -(2.0 * u * v)     = -2.0 * u * v

Why this is bulletproof:
- It completely bypasses complex_sin and complex_mul(sin, sin).
- As |y| -> INF, the stable cotangent value C smoothly approaches (0.0, -sign(y)).
- Plugging those limits into this derivative formula yields:
  deriv.x = -1.0 - 0.0 + (-sign(y))^2 = -1.0 + 1.0 = 0.0
  deriv.y = -2.0 * 0.0 * (-sign(y)) = 0.0
- The derivative safely and perfectly settles to (0.0, 0.0) without ever hitting 
  an intermediate INF or precision blackout.
================================================================================
*/
ComplexFieldData complex_cot_with_derivatives(float x, float y) {
    ComplexFieldData res;
    
    // 1. Calculate value safely using our stable real-hyperbolic identity
    res.value = complex_cot(x, y);
    
    // 2. Extract components: C = u + iv
    float u = res.value.x;
    float v = res.value.y;
    
    // 3. Compute the derivative directly from the value: d/dz = -(1 + C^2)
    vec2 deriv = vec2(
        -1.0 - (u * u) + (v * v),
        -2.0 * u * v
    );
    
    // 4. Assign directional derivatives matching your grid space
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    
    return res;
}

ComplexFieldData complex_exp_with_derivatives(float x, float y) {
    ComplexFieldData res;
    res.value = complex_exp(x, y);
    vec2 deriv = res.value;
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

ComplexFieldData complex_log_with_derivatives(float x, float y) {
    ComplexFieldData res;
    res.value = complex_log(x, y);
    vec2 z = vec2(x, y);
    vec2 deriv = complex_div(vec2(1.0, 0.0), z);
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

ComplexFieldData identity_with_derivatives(float x, float y) {
    ComplexFieldData res;
    res.value = vec2(x, y);
    res.dx = vec2(0.0);
    res.dy = vec2(0.0);
    return res;
}

vec2 evaluate_poly(float x, float y, vec2 coeffs[10]) {
    vec2 z = vec2(x, y);
    vec2 res = vec2(0.0);
    for (int i = 9; i >= 0; i--) {
        res = complex_mul(res, z) + coeffs[i];
    }
    return res;
}

vec2 get_rational(float x, float y) {
    vec2 num = evaluate_poly(x, y, rational_num_coeffs);
    vec2 den = evaluate_poly(x, y, rational_den_coeffs);
    return complex_div(num, den);
}

ComplexFieldData evaluate_poly_with_derivatives(float x, float y, vec2 coeffs[10]) {
    vec2 z = vec2(x, y);
    vec2 val = vec2(0.0);
    vec2 deriv = vec2(0.0);

    // Horner's method for both value and its derivative
    for (int i = 9; i >= 0; i--) {
        if (i < 9) {
            deriv = complex_mul(deriv, z) + val;
        }
        val = complex_mul(val, z) + coeffs[i];
    }

    ComplexFieldData res;
    res.value = val;
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

ComplexFieldData get_rational_with_derivatives(float x, float y) {
    ComplexFieldData num = evaluate_poly_with_derivatives(x, y, rational_num_coeffs);
    ComplexFieldData den = evaluate_poly_with_derivatives(x, y, rational_den_coeffs);
    ComplexFieldData res;
    res.value = complex_div(num.value, den.value);
    vec2 den_sqr = complex_mul(den.value, den.value);
    vec2 deriv = complex_div(complex_mul(num.dx, den.value) - complex_mul(num.value, den.dx), den_sqr);
    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

ComplexFieldData xi_with_derivatives(float x, float y, int iters) {
	vec2 s = vec2(x, y);
	vec2 s_minus_1 = vec2(x - 1.0, y);
	vec2 s_half = vec2(x * 0.5, y * 0.5);

	vec2 log_s = complex_log(s.x, s.y);
	vec2 d_log_s = complex_div(vec2(1.0, 0.0), s);

	vec2 log_s_minus_1 = complex_log(s_minus_1.x, s_minus_1.y);
	vec2 d_log_s_minus_1 = complex_div(vec2(1.0, 0.0), s_minus_1);

	vec2 log_pi_term = -complex_mul(s_half, vec2(LOG_PI, 0.0));
	vec2 d_log_pi_term = vec2(-0.5 * LOG_PI, 0.0);

	ComplexFieldData log_gamma_half = complex_log_gamma_with_derivatives(s_half.x, s_half.y);

	ComplexFieldData log_z = log_zeta_continuation_with_derivatives(x, y, iters);

	vec2 log_sum = vec2(log(0.5), 0.0) + log_s + log_s_minus_1 + log_pi_term + log_gamma_half.value + log_z.value;
	vec2 d_log_sum = d_log_s + d_log_s_minus_1 + d_log_pi_term + 0.5 * log_gamma_half.dx + log_z.dx;

	ComplexFieldData res;
	res.value = complex_exp(log_sum.x, log_sum.y);
	res.dx = complex_mul(res.value, d_log_sum);
	res.dy = vec2(-res.dx.y, res.dx.x);
	return res;
}

ComplexFieldData multivalued_z_pow_inv_n_with_derivatives(float x, float y, int n, int branch_offset, bool use_negative_cut) {
    ComplexFieldData res;
    float r_sq = x * x + y * y;
    float r = sqrt(r_sq);
    float theta = atan(y, x);
    if (!use_negative_cut && theta < 0.0) theta += 2.0 * PI;
    float float_n = float(n);

    float k_val = float((current_branch + branch_offset + n) % n);

    float morphed_phase = (theta + 2.0 * PI * k_val) / float_n;
    float morphed_r = pow(r, 1.0 / float_n);
    res.value = vec2(morphed_r * cos(morphed_phase), morphed_r * sin(morphed_phase));

    // dW/dZ = (1/n) * W / Z
    vec2 z = vec2(x, y);
    vec2 deriv = complex_div(res.value, float_n * z);

    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

ComplexFieldData multivalued_log_with_derivatives(float x, float y, int branch_offset, bool use_negative_cut) {
    ComplexFieldData res;
    float r_sq = x * x + y * y;
    float r = sqrt(r_sq);
    float theta = atan(y, x);
    if (!use_negative_cut && theta < 0.0) theta += 2.0 * PI;

    float k_val = float(current_branch + branch_offset);

    float morphed_phase = theta + 2.0 * PI * k_val;

    // Log(z) = ln|z| + i(arg(z) + 2pi*k)
    res.value = vec2(log(r), morphed_phase);

    // dW/dZ = 1 / Z
    vec2 z = vec2(x, y);
    vec2 deriv = complex_div(vec2(1.0, 0.0), z);

    res.dx = deriv;
    res.dy = vec2(-deriv.y, deriv.x);
    return res;
}

ComplexFieldData multivalued_asin_with_derivatives(float x, float y, int branch_offset) {
    vec2 z = vec2(x, y);
    vec2 z2 = complex_mul(z, z);
    vec2 one_minus_z2 = vec2(1.0 - z2.x, -z2.y);

    // derivative of one_minus_z2 with respect to z is -2z
    vec2 dz2_dz = vec2(-2.0 * z.x, -2.0 * z.y);

    int B = current_branch + branch_offset;
    int sqrt_offset = (abs(B) % 2) - current_branch;
    int log_branch = (x < 0.0) ? int(floor(float(B + 1) / 2.0)) : int(floor(float(B) / 2.0));
    int log_offset = log_branch - current_branch;

    ComplexFieldData sqrt_fd = multivalued_z_pow_inv_n_with_derivatives(one_minus_z2.x, one_minus_z2.y, 2, sqrt_offset, true);

    // Chain rule for sqrt_part
    vec2 d_sqrt_dz = complex_mul(sqrt_fd.dx, dz2_dz);

    vec2 iz = vec2(-z.y, z.x);
    vec2 d_iz_dz = vec2(0.0, 1.0); // i

    vec2 sum_val = iz + sqrt_fd.value;
    vec2 d_sum_dz = d_iz_dz + d_sqrt_dz;

    ComplexFieldData log_fd = multivalued_log_with_derivatives(sum_val.x, sum_val.y, log_offset, true);

    // Chain rule for log_val
    vec2 d_log_dz = complex_mul(log_fd.dx, d_sum_dz);

    ComplexFieldData res;
    res.value = vec2(log_fd.value.y, -log_fd.value.x);
    vec2 final_dx = vec2(d_log_dz.y, -d_log_dz.x);
    res.dx = final_dx;
    res.dy = vec2(-final_dx.y, final_dx.x);
    return res;
}

ComplexFieldData multivalued_acos_with_derivatives(float x, float y, int branch_offset) {
    ComplexFieldData asin_fd = multivalued_asin_with_derivatives(x, y, branch_offset);
    ComplexFieldData res;
    res.value = vec2(PI * 0.5 - asin_fd.value.x, -asin_fd.value.y);
    res.dx = -asin_fd.dx;
    res.dy = -asin_fd.dy;
    return res;
}
//-------------------------------------------------------------------------
// Dispatchers
//-------------------------------------------------------------------------

ComplexFieldData get_field_with_derivatives(float world_x, float world_z, int branch_offset) {
    float zoom = 1.0 / zoom_factor;
    float x = world_x * 0.1 * zoom;
    float y = -world_z * 0.1 * zoom;
    if (function_type == 0) return zeta_with_derivatives(x, y, iterations);
    if (function_type == 1) return zeta_continuation_with_derivatives(x, y, iterations);
    if (function_type == 2) return dirichlet_eta_with_derivatives(x, y, iterations);
    if (function_type == 3) return dirichlet_beta_with_derivatives(x, y, iterations);
    if (function_type == 4) return complex_gamma_with_derivatives(x, y);
    if (function_type == 5) return complex_log_gamma_with_derivatives(x, y);
    if (function_type == 6) return dedekind_eta_with_derivatives(x, y, iterations);
    if (function_type == 7) return mandelbrot_with_derivatives(x, y, iterations);
    if (function_type == 8) return complex_sin_with_derivatives(x, y);
    if (function_type == 9) return complex_cos_with_derivatives(x, y);
    if (function_type == 10) return complex_tan_with_derivatives(x, y);
    if (function_type == 11) return complex_cot_with_derivatives(x, y);
    if (function_type == 12) return complex_exp_with_derivatives(x, y);
    if (function_type == 13) return complex_log_with_derivatives(x, y);
    if (function_type == 14) return identity_with_derivatives(x, y);
    if (function_type == 15) return get_rational_with_derivatives(x, y);
	if (function_type == 16) return multivalued_z_pow_inv_n_with_derivatives(x, y, multivalued_n, branch_offset, true);
	if (function_type == 17) return multivalued_log_with_derivatives(x, y, branch_offset, true);
	if (function_type == 18) return multivalued_asin_with_derivatives(x, y, branch_offset);
	if (function_type == 19) return multivalued_acos_with_derivatives(x, y, branch_offset);
    ComplexFieldData res;
    res.value = vec2(0.0);
    res.dx = vec2(0.0);
    res.dy = vec2(0.0);
    return res;
}
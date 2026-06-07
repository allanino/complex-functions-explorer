# I will write a simple python script to convert the requested glsl functions into gdscript.
import re

shader_code = """
ComplexFieldData dirichlet_eta_with_derivatives(float x, float y, int iters) {
    vec2 eta = vec2(0.0);
    vec2 deta_dx = vec2(0.0);
    int actual_iters = 0;
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

        actual_iters = n + 1;

        if (amp < 1e-4 || amp2 < 1e-4 || amp > 1e4 || amp2 > 1e4) break;
    }

    if (actual_iters > 0 && x >= 0.5) {
        float next_n = float(actual_iters + 1);

        float rem_amp = 0.5 * pow(next_n, -x);
        float rem_log_n = log(next_n);
        float rem_theta = -y * rem_log_n;

        float rem_sign = 1.0;

        vec2 rem_term = rem_sign * rem_amp * vec2(cos(rem_theta), sin(rem_theta));

        eta += rem_term;
        deta_dx -= rem_log_n * rem_term;
    }

    ComplexFieldData result;
    result.value = eta;
    result.dx = deta_dx;
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
    res.dy = vec2(-res.dx.y, res.dx.x);
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
"""

res = shader_code.replace("vec2", "Vector2").replace("ComplexFieldData", "Array").replace("float", "var").replace("int", "var")
print(res)

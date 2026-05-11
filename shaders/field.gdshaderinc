// Shared field and height functions for shaders

uniform int iterations = 120;

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

vec2 get_field(float x, float z) {
    //if (x < 0.0) {
        //return vec2(0.0, 0.0);
    //}
	float sigma = x * 0.1;
	// We reverse z to get the usual Re, Im axis orientation
	// It looks like godot puts the z axis downwards
	float t = -z * 0.1;

    return zeta(sigma, t);
}

float get_height(float x, float z) {
    vec2 f = get_field(x, z);
    float mag = length(f);
    return 3.0 * mag;
}

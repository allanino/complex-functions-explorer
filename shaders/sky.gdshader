shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.3, 0.6, 0.9);
uniform vec3 horizon_color : source_color = vec3(0.6, 0.8, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);

// Simple hash for noise
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// 2D Noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// FBM Noise
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(0.87758, 0.47942), vec2(-0.47942, 0.87758)); // approx cos(0.5), sin(0.5)
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(10.0);
        a *= 0.5;
    }
    return v;
}

void sky() {
    float eye_alt = EYEDIR.y;

    // Sky gradient
    vec3 final_color = mix(horizon_color, sky_color, clamp(eye_alt * 2.0, 0.0, 1.0));

    // Sun
    if (LIGHT0_ENABLED) {
        float sun_dist = distance(EYEDIR, LIGHT0_DIRECTION);
        // Sun disk
        // LIGHT0_SIZE is angular diameter in radians.
        // distance() between normalized vectors is approximately the angle for small angles.
        float sun_size = max(0.01, LIGHT0_SIZE); // Ensure it's not zero
        float sun_disk = smoothstep(sun_size * 0.5, sun_size * 0.45, sun_dist);
        final_color += LIGHT0_COLOR * sun_disk * LIGHT0_ENERGY;

        // Sun glow
        float sun_glow = pow(max(0.0, 1.0 - sun_dist * 0.5), 100.0);
        final_color += LIGHT0_COLOR * sun_glow * 0.5 * LIGHT0_ENERGY;
    }

    // Clouds
    if (eye_alt > 0.0) {
        vec2 cloud_uv = EYEDIR.xz / max(eye_alt, 0.001);
        cloud_uv += TIME * 0.05; // Cloud movement

        float cloud_density = fbm(cloud_uv * 0.2);
        cloud_density = smoothstep(0.4, 0.8, cloud_density);

        // Fade clouds at horizon
        cloud_density *= smoothstep(0.0, 0.2, eye_alt);

        final_color = mix(final_color, cloud_color, cloud_density);
    }

    COLOR = final_color;
}

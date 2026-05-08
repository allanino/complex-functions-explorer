shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.3, 0.6, 0.9);
uniform vec3 horizon_color : source_color = vec3(0.6, 0.8, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);

// Dave Hoskins' hash (2D to 1D)
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D Noise with quintic interpolation
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    // Quintic interpolation
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
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
        float sun_size = max(0.01, LIGHT0_SIZE);
        float sun_disk = smoothstep(sun_size * 0.5, sun_size * 0.45, sun_dist);
        final_color += LIGHT0_COLOR * sun_disk * LIGHT0_ENERGY;

        // Sun glow (Mie-like scattering approximation)
        float mie = 0.01 / (0.001 + sun_dist * sun_dist * 10.0);
        final_color += LIGHT0_COLOR * mie * LIGHT0_ENERGY;

        float haze = 0.02 / (0.01 + sun_dist);
        final_color += LIGHT0_COLOR * haze * LIGHT0_ENERGY;
    }

    // Clouds
    if (eye_alt > -0.1) {
        // Improved UV projection to reduce horizon stretching
        vec2 cloud_uv = EYEDIR.xz / (max(eye_alt, 0.0) + 0.2);
        cloud_uv += TIME * 0.02; // Slower, more realistic cloud movement

        float cloud_fbm = fbm(cloud_uv * 0.25);
        // Multi-layered density for softer transitions and varied thickness
        float cloud_density = smoothstep(0.4, 0.9, cloud_fbm);
        float detail_noise = fbm(cloud_uv * 0.8 + vec2(TIME * 0.01));
        cloud_density *= 0.8 + 0.4 * detail_noise;

        // Fade clouds at horizon more gracefully
        float horizon_fade = smoothstep(-0.1, 0.3, eye_alt);
        cloud_density *= horizon_fade;
        cloud_density = clamp(cloud_density, 0.0, 1.0);

        // Cloud lighting: slightly brighten clouds near the sun
        vec3 final_cloud_color = cloud_color;
        if (LIGHT0_ENABLED) {
            float sun_dot = max(0.0, dot(EYEDIR, LIGHT0_DIRECTION));
            final_cloud_color = mix(cloud_color, LIGHT0_COLOR * 1.5, pow(sun_dot, 8.0) * cloud_density);
        }

        final_color = mix(final_color, final_cloud_color, cloud_density);
    }

    COLOR = final_color;
}

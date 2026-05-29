shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.3, 0.6, 0.9);
uniform vec3 horizon_color : source_color = vec3(0.6, 0.8, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float golden_hour_factor = 0.0;
uniform float night_factor = 0.0;
uniform float sky_luminosity = 1.0;
uniform bool performance_protection_active = false;
uniform float sun_size: hint_range(0.0, 1.0) = 0.05;

// Dave Hoskins' hash (2D to 1D)
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// 2D Noise with quintic interpolation
float noise(vec2 p) {
    // Wrap to prevent precision loss over time
    p = mod(p, 289.0);
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(mod(i + vec2(1.0, 0.0), 289.0));
    float c = hash(mod(i + vec2(0.0, 1.0), 289.0));
    float d = hash(mod(i + vec2(1.0, 1.0), 289.0));
    // Quintic interpolation
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// FBM Noise
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(0.87758, 0.47942), vec2(-0.47942, 0.87758)); // approx cos(0.5), sin(0.5)
    for (int i = 0; i < 3; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(10.0);
        a *= 0.5;
    }
    return v;
}

void sky() {
    if (performance_protection_active) {
        COLOR = vec3(0.01, 0.01, 0.02);
    } else {
        float eye_alt = EYEDIR.y;

        vec3 golden_hour_sky = vec3(0.1, 0.15, 0.3); // Deep blue/purple
        vec3 golden_hour_horizon = vec3(1.0, 0.4, 0.1); // Deep orange
        vec3 golden_hour_cloud = vec3(1.0, 0.7, 0.5); // Golden/Pinkish

        vec3 night_sky = vec3(0.005, 0.01, 0.02);
        vec3 night_horizon = vec3(0.01, 0.02, 0.05);

        vec3 blue_hour_sky = night_sky; // Rich blue
        vec3 blue_hour_horizon = night_horizon; // Deep blue horizon

        // Blue hour factor: peaks at night_factor 0.5
        float blue_hour_factor = smoothstep(0.0, 0.5, night_factor) * (1.0 - smoothstep(0.5, 1.0, night_factor)) * 2.0;
        float full_night_factor = smoothstep(0.5, 1.0, night_factor);

        // Sequence: Day -> Golden Hour -> Blue Hour -> Night
        // golden_hour_factor handles Day -> Golden
        // night_factor handles Golden -> Blue -> Night

        vec3 current_sky = mix(sky_color, golden_hour_sky, golden_hour_factor);
        current_sky = mix(current_sky, blue_hour_sky, smoothstep(0.0, 0.5, night_factor));
        current_sky = mix(current_sky, night_sky, full_night_factor);

        vec3 current_horizon = mix(horizon_color, golden_hour_horizon, golden_hour_factor);
        current_horizon = mix(current_horizon, blue_hour_horizon, smoothstep(0.0, 0.5, night_factor));
        current_horizon = mix(current_horizon, night_horizon, full_night_factor);

        vec3 night_cloud = vec3(0.15, 0.2, 0.4);
        vec3 blue_hour_cloud = night_cloud;

        vec3 current_cloud = mix(cloud_color, golden_hour_cloud, golden_hour_factor);
        current_cloud = mix(current_cloud, blue_hour_cloud, smoothstep(0.0, 0.5, night_factor));
        current_cloud = mix(current_cloud, night_cloud, full_night_factor);

        // Sky gradient
        vec3 final_color = mix(current_horizon, current_sky, clamp(eye_alt * 2.0, 0.0, 1.0));

        // Stars
        if (night_factor > 0.01 && eye_alt > 0.0) {

            vec3 star_dir = normalize(EYEDIR);

            // Spherical UV mapping
            float u = atan(star_dir.z, star_dir.x) / (2.0 * PI) + 0.5;
            float v = asin(clamp(star_dir.y, -1.0, 1.0)) / PI + 0.5;

            vec2 star_uv = vec2(u, v);

            // Stable 2D star grid
            float star_res = 512.0;
            vec2 cell = floor(star_uv * star_res);

            // Cell hash
            float h = hash(cell);

            // Star existence
            if (h > 0.992) {

                // Random star position INSIDE the cell
                vec2 rnd = vec2(
                    hash(cell + vec2(13.1, 7.2)),
                    hash(cell + vec2(2.8, 19.7))
                );

                vec2 star_pos = (cell + rnd) / star_res;

                // Wrap-safe UV distance
                vec2 delta = abs(star_uv - star_pos);
                delta.x = min(delta.x, 1.0 - delta.x);

                float dist = length(delta);

                // Softer Gaussian-like falloff
                float star = exp(-dist * 10000.0);

                // Brightness and flicker
                float flicker = 0.8 + 0.2 * sin(TIME * 2.0 + h * 100.0);
                float brightness = 0.8 + fract(h * 17.31);

                float star_intensity = 1.0;

                final_color += vec3(
                    star *
                    brightness *
                    flicker *
                    night_factor *
                    star_intensity
                );
            }
        }

        vec3 cloud_final_color = final_color;

        // Clouds
        if (eye_alt > -0.1) {
            // Use a more balanced projection for coverage across the entire sky
            // Adding a smaller offset to the denominator to keep clouds visible at zenith

            vec2 cloud_uv =EYEDIR.xz / (max(eye_alt, 0.01) + 0.05);

            vec2 uv1 = cloud_uv + vec2(TIME * 0.002, TIME * 0.001);
            vec2 uv2 = cloud_uv + vec2(TIME * -0.0007, TIME * 0.0015);

            float cloud_fbm =
                fbm(uv1 * 0.3) * 0.7 +
                fbm(uv2 * 0.6) * 0.3;
                
            // Lower threshold for more cloud coverage across the sky
            float cloud_density = smoothstep(0.4, 0.8, cloud_fbm);

            // Add detail noise without over-thinning
            float detail_noise = fbm(cloud_uv * 1.5 + vec2(TIME * 0.005));
            cloud_density = mix(cloud_density, cloud_density * detail_noise, 0.3);

            // Fade clouds at horizon more gracefully
            float horizon_fade = smoothstep(-0.05, 0.2, eye_alt);
            cloud_density *= horizon_fade;
            cloud_density = clamp(cloud_density, 0.0, 1.0);

            // Cloud lighting: slightly brighten clouds near the sun
            vec3 final_cloud_color = current_cloud;
            if (LIGHT0_ENABLED) {
                float sun_dot = max(0.0, dot(EYEDIR, LIGHT0_DIRECTION));
                final_cloud_color = mix(current_cloud, LIGHT0_COLOR * 1.5, pow(sun_dot, 8.0) * cloud_density);
            }

            cloud_final_color = mix(final_color, final_cloud_color, cloud_density);
        }

        // Sun
        if (LIGHT0_ENABLED && LIGHT0_ENERGY > 0.0) {
            float sun_dist = distance(EYEDIR, LIGHT0_DIRECTION);
            float sun_disk = smoothstep(sun_size * 0.5, sun_size * 0.45, sun_dist);
            // disk_intensity stays 1.0 while sun is visible to keep its size
            // Using a small threshold to avoid flickering
            float disk_intensity = smoothstep(0.0, 0.1, LIGHT0_ENERGY);
            cloud_final_color += LIGHT0_COLOR * sun_disk * disk_intensity;

            // Sun glow (Mie-like scattering approximation)
            float mie = 0.01 / (0.001 + sun_dist * sun_dist * 10.0); // Decreased from 10.0 to widen the bright core
            cloud_final_color += LIGHT0_COLOR * mie * LIGHT0_ENERGY;

            float haze = 0.02 / (0.01 + sun_dist);
            cloud_final_color += LIGHT0_COLOR * haze * LIGHT0_ENERGY;
        }

        // Moon
        if (LIGHT1_ENERGY > 0.01) {
            // Subtle whole-sky diffuse contribution from moon
            cloud_final_color += LIGHT1_COLOR * 0.05 * LIGHT1_ENERGY;

            float moon_dist = distance(EYEDIR, LIGHT1_DIRECTION);
            // Moon disk: Match sun size
            float moon_size = 0.05;
            float moon_disk = smoothstep(moon_size * 0.5, moon_size * 0.45, moon_dist);
            float moon_disk_intensity = smoothstep(0.0, 0.1, LIGHT1_ENERGY);
            cloud_final_color += LIGHT1_COLOR * moon_disk * moon_disk_intensity;

            // Moon glow
            float moon_glow = 0.01 / (0.001 + moon_dist * moon_dist * 10.0);
            cloud_final_color += LIGHT1_COLOR * moon_glow * LIGHT1_ENERGY;
        }


        COLOR = cloud_final_color * sky_luminosity;
    }
}

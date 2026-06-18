shader_type sky;

uniform vec3 sky_color : source_color = vec3(0.3, 0.6, 0.9);
uniform vec3 horizon_color : source_color = vec3(0.6, 0.8, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float golden_hour_factor = 0.0;
uniform float night_factor = 0.0;
uniform float sky_luminosity = 1.0;
uniform bool performance_protection_active = false;

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
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0 + vec2(10.0);
        a *= 0.5;
    }
    return v;
}



void compute_sky_colors(float n_factor, float g_factor, vec3 sky_c, vec3 horizon_c, vec3 cloud_c, out vec3 current_sky, out vec3 current_horizon, out vec3 current_cloud) {
    vec3 golden_hour_sky = vec3(0.1, 0.15, 0.3); // Deep blue/purple
    vec3 golden_hour_horizon = vec3(1.0, 0.3, 0.05); // Deep orange
    vec3 golden_hour_cloud = vec3(1.0, 0.4, 0.2); // Golden/Pinkish

    vec3 night_sky = vec3(0.005, 0.01, 0.02);
    vec3 night_horizon = vec3(0.01, 0.02, 0.05);

    vec3 blue_hour_sky = night_sky; // Rich blue
    vec3 blue_hour_horizon = night_horizon; // Deep blue horizon

    // Blue hour factor: peaks at night_factor 0.5
    float blue_hour_factor = smoothstep(0.0, 0.5, n_factor) * (1.0 - smoothstep(0.5, 1.0, n_factor)) * 2.0;
    float full_night_factor = smoothstep(0.5, 1.0, n_factor);

    // Sequence: Day -> Golden Hour -> Blue Hour -> Night
    // golden_hour_factor handles Day -> Golden
    // night_factor handles Golden -> Blue -> Night

    current_sky = mix(sky_c, golden_hour_sky, g_factor);
    current_sky = mix(current_sky, blue_hour_sky, smoothstep(0.0, 0.5, n_factor));
    current_sky = mix(current_sky, night_sky, full_night_factor);

    current_horizon = mix(horizon_c, golden_hour_horizon, g_factor);
    current_horizon = mix(current_horizon, blue_hour_horizon, smoothstep(0.0, 0.5, n_factor));
    current_horizon = mix(current_horizon, night_horizon, full_night_factor);

    vec3 night_cloud = vec3(0.15, 0.2, 0.4);
    vec3 blue_hour_cloud = night_cloud;

    current_cloud = mix(cloud_c, golden_hour_cloud, g_factor);
    current_cloud = mix(current_cloud, blue_hour_cloud, smoothstep(0.0, 0.5, n_factor));
    current_cloud = mix(current_cloud, night_cloud, full_night_factor);
}


void compute_stars(vec3 eye_dir, float eye_alt, float n_factor, float time, inout vec3 final_color) {
    if (n_factor > 0.01 && eye_alt > 0.0) {

        vec3 star_dir = normalize(eye_dir);

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
            float flicker = 0.8 + 0.2 * sin(time * 2.0 + h * 100.0);
            float brightness = 0.8 + fract(h * 17.31);

            float star_intensity = 1.0;

            final_color += vec3(
                star *
                brightness *
                flicker *
                n_factor *
                star_intensity
            );
        }
    }
}


void compute_clouds(vec3 eye_dir, float eye_alt, float time, vec3 current_cloud, vec3 final_color, bool light0_enabled, vec3 light0_dir, vec3 light0_col, out vec3 cloud_final_color) {
    cloud_final_color = final_color;
    if (eye_alt > -0.1) {
        // Use a more balanced projection for coverage across the entire sky
        // Adding a smaller offset to the denominator to keep clouds visible at zenith

        vec2 cloud_uv = eye_dir.xz / (max(eye_alt, 0.01) + 0.05);

        vec2 uv1 = cloud_uv + vec2(time * 0.002, time * 0.001);
        vec2 uv2 = cloud_uv + vec2(time * -0.0007, time * 0.0015);

        float cloud_fbm =
            fbm(uv1 * 0.3) * 0.7 +
            fbm(uv2 * 0.6) * 0.3;

        // Lower threshold for more cloud coverage across the sky
        float cloud_density = smoothstep(0.5, 0.8, cloud_fbm);

        // Add detail noise without over-thinning
        float detail_noise = fbm(cloud_uv * 1.5 + vec2(time * 0.005));
        cloud_density = mix(cloud_density, cloud_density * detail_noise, 0.3);

        // Fade clouds at horizon more gracefully
        float horizon_fade = smoothstep(-0.05, 0.2, eye_alt);
        cloud_density *= horizon_fade;
        cloud_density = clamp(cloud_density, 0.0, 1.0);

        // Cloud lighting: slightly brighten clouds near the sun
        vec3 final_cloud_color = current_cloud;
        if (light0_enabled) {
            float sun_dot = max(0.0, dot(eye_dir, light0_dir));
            final_cloud_color = mix(current_cloud, light0_col * 1.5, pow(sun_dot, 8.0) * cloud_density);
        }

        cloud_final_color = mix(final_color, final_cloud_color, cloud_density);
    }
}


void compute_sun_moon(vec3 eye_dir, bool light0_enabled, vec3 light0_dir, vec3 light0_col, float light0_en, vec3 light1_dir, vec3 light1_col, float light1_en, inout vec3 cloud_final_color) {
    // Sun
    if (light0_enabled && light0_en > 0.0) {
        float sun_dist = distance(eye_dir, light0_dir);
        float sun_size = 0.05;
        float sun_disk = smoothstep(sun_size * 0.5, sun_size * 0.45, sun_dist);
        // disk_intensity stays 1.0 while sun is visible to keep its size
        // Using a small threshold to avoid flickering
        float disk_intensity = smoothstep(0.0, 0.1, light0_en);
        cloud_final_color += light0_col * sun_disk * disk_intensity;

        float sun_glow_dist = max(0.0, sun_dist - sun_size * 0.45);

        // Sun glow (Mie-like scattering approximation)
        float mie = 0.005 / (0.001 + sun_glow_dist * sun_glow_dist * 5.0); // Decreased from 10.0 to widen the bright core
        cloud_final_color += light0_col * mie * light0_en;

        float haze = 0.01 / (0.01 + sun_glow_dist);
        cloud_final_color += light0_col * haze * light0_en;
    }

    // Moon
    if (light1_en > 0.01) {
        // Subtle whole-sky diffuse contribution from moon
        cloud_final_color += light1_col * 0.05 * light1_en;

        float moon_dist = distance(eye_dir, light1_dir);
        // Moon disk: Match sun size
        float moon_size = 0.05;
        float moon_disk = smoothstep(moon_size * 0.5, moon_size * 0.45, moon_dist);
        float moon_disk_intensity = smoothstep(0.0, 0.1, light1_en);

        float moon_glow_dist = max(0.0, moon_dist - moon_size * 0.45);
        float moon_glow = 0.005 / (0.001 + moon_glow_dist * moon_glow_dist * 5.0);

        if (moon_disk > 0.0) {
            float moon_radius = moon_size * 0.5;
            vec3 up = abs(light1_dir.y) < 0.999 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
            vec3 right = normalize(cross(up, light1_dir));
            vec3 moon_up = normalize(cross(light1_dir, right));

            float mx = dot(eye_dir, right) / moon_radius;
            float my = dot(eye_dir, moon_up) / moon_radius;
            float mz = sqrt(max(1.0 - mx * mx - my * my, 0.0));

            vec2 moon_uv = vec2(mx, my) * 1.5;
            vec2 offset = moon_uv + vec2(5.0, 10.0);

            float val = fbm(offset);
            float craters = smoothstep(0.4, 0.6, val);
            float detail = fbm(offset * 3.0);

            float texture = 0.6 + 0.4 * craters;
            texture *= 0.8 + 0.2 * detail;

            float edge_shade = clamp(mz, 0.0, 1.0);
            texture *= 0.8 + 0.2 * edge_shade;

            float texture_blend = mix(1.0, texture, moon_disk);
            vec3 disk_color = light1_col * moon_disk * moon_disk_intensity * texture_blend;
            vec3 local_glow = light1_col * moon_glow * light1_en * mix(1.0, texture_blend, moon_disk);
            cloud_final_color += disk_color + local_glow;
        } else {
            cloud_final_color += light1_col * moon_glow * light1_en;
        }
    }
}


void compute_haze(vec3 eye_dir, float n_factor, float g_factor, bool light0_enabled, vec3 light0_dir, vec3 light0_col, inout vec3 cloud_final_color) {
    // --------------- Haze (re-applied with exponential falloff) ---------------
    float horizon = 1.0 - clamp(eye_dir.y, 0.0, 1.0);

    // Exponential falloff, no artificial horizon strengthening
    float haze_amount = 1.0 - exp(-horizon * 3.5);

    // Sun haze (wide forward scattering)
    float sun_haze = 0.0;
    if (light0_enabled) {
        float sun_dot = max(dot(eye_dir, light0_dir), 0.0);
        sun_haze = pow(sun_dot, 3.0);
    }

    // Atmospheric color based on sun
    vec3 haze_color = mix(
        vec3(0.52, 0.68, 0.84), // blue daytime haze
        light0_col * vec3(1.0, 0.7, 0.4), // warm sunset haze
        g_factor
    );

    haze_color += light0_col * sun_haze * 0.2;

    // Final haze intensity
    float night_haze_factor = 1.0 - smoothstep(0.05, 1.0, n_factor);
    float final_haze = (haze_amount * 0.1 + sun_haze * 0.08) * night_haze_factor;
    final_haze = clamp(final_haze, 0.0, 1.0);

    // Blend with clouds
    cloud_final_color = mix(cloud_final_color, haze_color, final_haze);
}


void sky() {
    if (performance_protection_active) {
        COLOR = vec3(0.01, 0.01, 0.02);
    } else {
        float eye_alt = EYEDIR.y;

        vec3 current_sky, current_horizon, current_cloud;
        compute_sky_colors(night_factor, golden_hour_factor, sky_color, horizon_color, cloud_color, current_sky, current_horizon, current_cloud);

        // Sky gradient
        float horizon_span = mix(1.0, 0.4, golden_hour_factor);
        float grad_factor = clamp(eye_alt / horizon_span, 0.0, 1.0);
        grad_factor = 1.0 - exp(-grad_factor * mix(2.0, 4.0, golden_hour_factor));
        vec3 final_color = mix(current_horizon, current_sky, grad_factor);
        float sun_factor = pow(max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0), 3.0);
        final_color += current_horizon * sun_factor * 0.08;

        float horizon_alt = max(eye_alt, 0.0);
        float haze = exp(-pow(horizon_alt * 6.0, 2.0));
        final_color = mix(final_color, current_horizon, haze * 0.12 * golden_hour_factor);
        
    
        // Stars
        compute_stars(EYEDIR, eye_alt, night_factor, TIME, final_color);

        vec3 cloud_final_color;
        // Clouds
        compute_clouds(EYEDIR, eye_alt, TIME, current_cloud, final_color, LIGHT0_ENABLED, LIGHT0_DIRECTION, LIGHT0_COLOR, cloud_final_color);

        // Sun & Moon
        compute_sun_moon(EYEDIR, LIGHT0_ENABLED, LIGHT0_DIRECTION, LIGHT0_COLOR, LIGHT0_ENERGY, LIGHT1_DIRECTION, LIGHT1_COLOR, LIGHT1_ENERGY, cloud_final_color);

        // Haze
        compute_haze(EYEDIR, night_factor, golden_hour_factor, LIGHT0_ENABLED, LIGHT0_DIRECTION, LIGHT0_COLOR, cloud_final_color);

        COLOR = cloud_final_color * sky_luminosity;
    }
}

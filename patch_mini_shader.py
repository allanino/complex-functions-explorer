with open("ui/mini_terrain.gdshader", "r") as f:
    content = f.read()

# I need to add level curves and critical stripe logic, which are controlled by uniforms.
uniforms = """
uniform bool draw_level_curves = false;
uniform bool draw_critical_stripe = false;
uniform float zoom_factor = 1.0;
uniform float level_curve_thickness = 1.0;
uniform float level_curve_frequency = 10.0;
"""

if "uniform bool draw_level_curves" not in content:
    content = content.replace("uniform int color_scheme = 0;", "uniform int color_scheme = 0;\n" + uniforms)

# Add level curves and critical stripe
logic = """
    // Dim the color when moiré is high
    base_color = mix(base_color, vec3(0.5), moire_suppression * 0.5);

    // Grid / Level Curves
    if (draw_level_curves) {
        float fmag = length(f);
        if (fmag > 1e-6) {
            float m = log(fmag);
            // Dynamic scale for level curves to avoid aliasing at poles/zeros
            float scaled_thickness = level_curve_thickness * 2.0;

            float phase_curve = abs(sin(phase * level_curve_frequency * 0.5));
            float mag_curve = abs(sin(m * level_curve_frequency));

            float derivative_mag = length(vec2(fd.dx.x, fd.dx.y));
            float fw_phase = abs(derivative_mag / fmag) * view_radius * 0.05;
            float fw_mag = abs(derivative_mag / fmag) * view_radius * 0.05;

            float phase_alpha = smoothstep(scaled_thickness * fw_phase, 0.0, phase_curve);
            float mag_alpha = smoothstep(scaled_thickness * fw_mag, 0.0, mag_curve);

            float grid_alpha = max(phase_alpha, mag_alpha) * (1.0 - moire_suppression);

            vec3 grid_color = vec3(0.0);
            if (color_scheme == 2) {
                grid_color = vec3(1.0);
            }
            base_color = mix(base_color, grid_color, grid_alpha * 0.8);
        }
    }

    // Critical Stripe
    if (draw_critical_stripe && is_dirichlect) {
        vec2 complex_pos = world_to_complex(world_pos.x, world_pos.y, zoom_factor);
        if (complex_pos.x >= 0.0 && complex_pos.x <= 1.0) {
            base_color = mix(base_color, vec3(1.0), 0.15); // highlight
            if (abs(complex_pos.x - 0.5) < 0.01 / zoom_factor) {
                 base_color = mix(base_color, vec3(1.0, 0.0, 0.0), 0.5); // red center line
            }
        }
    }
"""

if "if (draw_level_curves)" not in content:
    content = content.replace("    // Dim the color when moiré is high\n    base_color = mix(base_color, vec3(0.5), moire_suppression * 0.5);", logic)


with open("ui/mini_terrain.gdshader", "w") as f:
    f.write(content)

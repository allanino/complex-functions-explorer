shader_type canvas_item;

#include "res://math/complex_field.gdshaderinc"

uniform vec2 player_pos_world;
uniform float view_radius = 20.0;
uniform int color_scheme = 0;

uniform bool show_curves = false;
uniform bool show_critical_stripe = false;
uniform float level_curve_thickness = 0.1;
uniform float level_curve_frequency = 10.0;


// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 world_to_complex(float x, float y) {
    return vec2(0.1 * x, -0.1 * y) / zoom_factor;
}

void fragment() {
    vec2 offset = (UV - vec2(0.5)) * 2.0 * view_radius;
    vec2 world_pos = player_pos_world + offset;

    ComplexFieldData fd = get_field_with_derivatives(world_pos.x, world_pos.y, current_branch);
    vec2 f = fd.value;

    float phase = atan(f.y, f.x);
    float hue = (phase + PI) / (2.0 * PI);
    if (color_scheme == 1) {
        hue = fract(hue + 0.5);
    }

    // Moiré suppression to make it smooth
    float f_mag = length(f);
    float phase_change = length(vec2(fd.dx.x, fd.dx.y)) / (f_mag + 1e-12);
    // Rough heuristic for screen-space moiré suppression depending on view_radius/resolution
    float moire_suppression = smoothstep(0.5, 3.0, phase_change * view_radius * 0.05);

    vec3 base_color = hsv2rgb(vec3(hue, 0.85, 1.0));
    if (color_scheme == 2) {
        float v = 0.5 + 0.5 * cos(phase);
        base_color = vec3(v);
    }


    // Dim the color when moiré is high
    base_color = mix(base_color, vec3(0.5), moire_suppression * 0.5);

    // Grid / Level Curves
    if (show_curves) {
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
            base_color = mix(base_color, grid_color, grid_alpha * 0.1);
        }
    }

    if (show_critical_stripe && is_dirichlect) {
        vec2 complex_pos = world_to_complex(world_pos.x, world_pos.y);
        if (complex_pos.x >= 0.0 && complex_pos.x <= 1.0) {
            base_color = mix(base_color, vec3(1.0), 0.15); // highlight
            if (abs(complex_pos.x - 0.5) < 0.01 / zoom_factor) {
                 base_color = mix(base_color, vec3(1.0, 0.655, 0.0), 0.5); // red center line
            }
        }
    }


    COLOR = vec4(base_color, 1.0);
}
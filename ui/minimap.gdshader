shader_type canvas_item;

#include "res://math/complex_field.gdshaderinc"

uniform vec2 player_pos_world;
uniform float view_radius = 20.0;
uniform int color_scheme = 0;

uniform bool show_curves = false;
uniform bool show_critical_stripe = false;
uniform float level_curve_thickness = 0.1;
uniform float level_curve_frequency = 10.0;

uniform float real_level_curves_highlighted[10];
uniform float imag_level_curves_highlighted[10];

uniform vec2 newton_path[50];
uniform int newton_path_size;
uniform vec4 newton_path_bbox; // x_min, x_max, y_min, y_max

float sdLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

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
            float derivative_mag = length(vec2(fd.dx.x, fd.dx.y));
            float raw_w_re = abs(derivative_mag / fmag) * view_radius * 0.005;
            float raw_w_im = abs(derivative_mag / fmag) * view_radius * 0.005;

            float max_density_threshold = 0.2;

            float d_re = abs(f.x - round(f.x));
            bool is_real_highlighted = false;
            for (int i = 0; i < 10; i++) {
                if (abs(round(f.x) - real_level_curves_highlighted[i]) < 0.1) {
                    is_real_highlighted = true;
                    break;
                }
            }
            float w_re = clamp(raw_w_re, 0.000005, 0.001) + (is_real_highlighted ? 0.06 : 0.02);
            float line_re = smoothstep(w_re, 0.0, d_re);
            float density_re = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_re);
            line_re *= density_re;

            float d_im = abs(f.y - round(f.y));
            bool is_imag_highlighted = false;
            for (int i = 0; i < 10; i++) {
                if (abs(round(f.y) - imag_level_curves_highlighted[i]) < 0.1) {
                    is_imag_highlighted = true;
                    break;
                }
            }
            float w_im = clamp(raw_w_im, 0.000005, 0.001) + (is_imag_highlighted ? 0.06 : 0.02);
            float line_im = smoothstep(w_im, 0.0, d_im);
            float density_im = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_im);
            line_im *= density_im;

            float line_alpha = max(line_re * (is_real_highlighted ? 0.8 : 0.3), line_im * (is_imag_highlighted ? 0.8 : 0.3));

            vec3 grid_color = vec3(0.0);
            if (color_scheme == 2) {
                grid_color = vec3(1.0);
            }
            base_color = mix(base_color, grid_color, line_alpha);
        }
    }

    if (newton_path_size > 0) {
        float expand = 2.0;
        float x_min = newton_path_bbox.x * 10.0 * zoom_factor - expand;
        float x_max = newton_path_bbox.y * 10.0 * zoom_factor + expand;
        float z_min = -newton_path_bbox.w * 10.0 * zoom_factor - expand;
        float z_max = -newton_path_bbox.z * 10.0 * zoom_factor + expand;

        if (world_pos.x >= x_min && world_pos.x <= x_max && world_pos.y >= z_min && world_pos.y <= z_max) {
            float total_intensity = 0.0;
            float scale = clamp(0.5 / zoom_factor, 0.2, 0.5) * 2.0;
            for (int i = 0; i < newton_path_size - 1; i++) {
                vec2 p1 = vec2(newton_path[i].x * 10.0 * zoom_factor, -newton_path[i].y * 10.0 * zoom_factor);
                vec2 p2 = vec2(newton_path[i+1].x * 10.0 * zoom_factor, -newton_path[i+1].y * 10.0 * zoom_factor);

                float seg_len = length(p2 - p1);
                if (seg_len < 0.0001) continue;

                float local_thickness = max(0.005 * scale, min(0.02 * scale, seg_len * 0.05));
                float d_seg = sdLine(world_pos, p1, p2);
                float core = 1.0 - step(local_thickness, d_seg);
                float glow = (1.0 - smoothstep(local_thickness, local_thickness * 2.0, d_seg)) * 0.5;
                total_intensity = max(total_intensity, core + glow);

                vec2 dir = (p2 - p1) / seg_len;
                vec2 perp = vec2(-dir.y, dir.x);
                vec2 mid = (p1 + p2) * 0.5;

                float path_arrow_len = min(0.16 * scale, seg_len * 0.4);
                float path_arrow_width = min(0.08 * scale, seg_len * 0.2);
                float local_arr_thickness = max(0.005 * scale, min(0.02 * scale, path_arrow_len * 0.15));

                float d_arr = min(
                    sdLine(world_pos, mid + dir * path_arrow_len * 0.5, mid - dir * path_arrow_len * 0.5 + perp * path_arrow_width),
                    sdLine(world_pos, mid + dir * path_arrow_len * 0.5, mid - dir * path_arrow_len * 0.5 - perp * path_arrow_width)
                );
                float arr_core = 1.0 - step(local_arr_thickness, d_arr);
                float arr_glow = (1.0 - smoothstep(local_arr_thickness, local_arr_thickness * 2.0, d_arr)) * 0.5;
                total_intensity = max(total_intensity, arr_core + arr_glow);
            }
            if (total_intensity > 0.0) {
                vec3 final_emission = vec3(0.0, 0.8, 1.0) * total_intensity * 2.0;
                base_color = mix(base_color, final_emission, clamp(total_intensity, 0.0, 1.0));
            }
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
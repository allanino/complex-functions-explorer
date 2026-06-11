shader_type canvas_item;

#include "res://math/complex_field.gdshaderinc"

uniform vec2 player_pos_world;
uniform float view_radius = 20.0;
uniform int color_scheme = 0;

uniform bool show_curves = false;
uniform bool show_critical_stripe = false;
uniform float level_curve_thickness = 0.1;
uniform float level_curve_frequency = 10.0;

uniform float morph = 1.0;
uniform float max_world_height = 1000.0;

uniform float real_level_curves_highlighted[10];
uniform float imag_level_curves_highlighted[10];

uniform vec2 newton_path[50];
uniform int newton_path_size;
uniform vec4 newton_path_bbox; // x_min, x_max, y_min, y_max

uniform bool show_hud_zeros = false;
uniform vec2 visited_zeros[10];
uniform int visited_zeros_size;
uniform int accented_zero_index = -1;

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

    float blend = 0.5 - 0.5 * cos(PI * morph);
    vec2 z_id = vec2(0.1 * world_pos.x, -0.1 * world_pos.y) / zoom_factor;
    vec2 field_val = mix(z_id, f, blend);
    bool h_clamped = false;
    float h = get_complex_height(f, field_val, h_clamped);
    h *= blend * zoom_factor;

    float h_abs = abs(h);
    float fade_factor = 1.0;

    if (h_clamped) {
        fade_factor = 0.3;
    } else if (h_abs > max_world_height) {
        // Exponentially smooth decay from 1.0 approaching 0.3
        float excess = h_abs - max_world_height;
        float decay_rate = 0.0005; // Tunes how fast it fades out
        float exp_fade = exp(-decay_rate * excess);
        fade_factor = 0.3 + 0.7 * exp_fade;
    }

    base_color *= fade_factor;

    // Grid / Level Curves
    if (show_curves) {
        float fmag = length(f);
        if (fmag > 1e-6) {
            float raw_w_re = fwidth(f.x);
            float raw_w_im = fwidth(f.y);

            float max_density_threshold = 0.2;

            float d_re = abs(f.x - round(f.x));
            bool is_real_highlighted = false;
            for (int i = 0; i < 10; i++) {
                if (abs(round(f.x) - real_level_curves_highlighted[i]) < 0.1) {
                    is_real_highlighted = true;
                    break;
                }
            }
            float w_re = raw_w_re * 0.2 + (is_real_highlighted ? 0.02 : 0.006);
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
            float w_im = raw_w_im * 0.2 + (is_imag_highlighted ? 0.02 : 0.006);
            float line_im = smoothstep(w_im, 0.0, d_im);
            float density_im = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_im);
            line_im *= density_im;

            base_color *= 1.0 - line_re * (is_real_highlighted ? 0.6 : 0.15);
            base_color *= 1.0 + line_im * (is_imag_highlighted ? 0.6 : 0.15);

            if (is_real_highlighted) {
                base_color += vec3(0.0, 0.6, 1.0) * line_re * 0.6;
            }
            if (is_imag_highlighted) {
                base_color += vec3(1.0, 0.0, 0.549) * line_im * 0.6;
            }
        }
    }

    if (newton_path_size > 0) {
        float expand = 20.0;
        float x_min = newton_path_bbox.x * 10.0 * zoom_factor - expand;
        float x_max = newton_path_bbox.y * 10.0 * zoom_factor + expand;
        float z_min = -newton_path_bbox.w * 10.0 * zoom_factor - expand;
        float z_max = -newton_path_bbox.z * 10.0 * zoom_factor + expand;

        if (world_pos.x >= x_min && world_pos.x <= x_max && world_pos.y >= z_min && world_pos.y <= z_max) {
            float total_intensity = 0.0;
            float scale = clamp(0.5 / zoom_factor, 0.2, 0.5) * 2.0;
            
            float pixel_size_world = fwidth(UV.x) * 2.0 * view_radius;
            float aa = pixel_size_world * 1.0;
            float min_thickness = pixel_size_world * 1.5;

            for (int i = 0; i < newton_path_size - 1; i++) {
                vec2 p1 = vec2(newton_path[i].x * 10.0 * zoom_factor, -newton_path[i].y * 10.0 * zoom_factor);
                vec2 p2 = vec2(newton_path[i+1].x * 10.0 * zoom_factor, -newton_path[i+1].y * 10.0 * zoom_factor);

                float seg_len = length(p2 - p1);
                if (seg_len < 0.0001) continue;

                float local_thickness = max(min_thickness, min(0.02 * scale, seg_len * 0.05));
                float d_seg = sdLine(world_pos, p1, p2);
                float core = 1.0 - smoothstep(local_thickness - aa, local_thickness + aa, d_seg);
                float glow = (1.0 - smoothstep(local_thickness + aa, local_thickness * 3.0 + aa * 2.0, d_seg)) * 0.5;
                total_intensity = max(total_intensity, core + glow);

                vec2 dir = (p2 - p1) / seg_len;
                vec2 perp = vec2(-dir.y, dir.x);
                vec2 mid = (p1 + p2) * 0.5;

                float path_arrow_len = min(0.16 * scale, seg_len * 0.4);
                float path_arrow_width = min(0.08 * scale, seg_len * 0.2);
                float local_arr_thickness = max(min_thickness, min(0.02 * scale, path_arrow_len * 0.15));

                float d_arr = min(
                    sdLine(world_pos, mid + dir * path_arrow_len * 0.5, mid - dir * path_arrow_len * 0.5 + perp * path_arrow_width),
                    sdLine(world_pos, mid + dir * path_arrow_len * 0.5, mid - dir * path_arrow_len * 0.5 - perp * path_arrow_width)
                );
                float arr_core = 1.0 - smoothstep(local_arr_thickness - aa, local_arr_thickness + aa, d_arr);
                float arr_glow = (1.0 - smoothstep(local_arr_thickness + aa, local_arr_thickness * 3.0 + aa * 2.0, d_arr)) * 0.5;
                total_intensity = max(total_intensity, arr_core + arr_glow);
            }
            if (total_intensity > 0.0) {
                vec3 path_color = vec3(1.0, 1.0, 1.0);
                vec3 final_emission = path_color * total_intensity * 2.0;
                base_color = mix(base_color, final_emission, clamp(total_intensity, 0.0, 1.0));
            }
        }
    }

    if (show_critical_stripe && is_dirichlect) {
        vec2 complex_pos = world_to_complex(world_pos.x, world_pos.y);
        if (complex_pos.x >= 0.0 && complex_pos.x <= 1.0) {
            base_color = mix(base_color, vec3(1.0), 0.15); // highlight
        }
        
        float pixel_size_world = fwidth(UV.x) * 2.0 * view_radius;
        float aa = pixel_size_world * 1.0;
        float line_width = pixel_size_world * 1.25;
        
        float pulse = 0.5 + 0.5 * sin(TIME * 2.0);
        
        // Screen-space anti-aliased gold center line at Re = 0.5 (world_x = 5.0 * zoom_factor)
        float d_critical = abs(world_pos.x - 5.0 * zoom_factor);
        float line_val = 1.0 - smoothstep(line_width - aa, line_width + aa, d_critical);
        
        // Outer glow for the critical center line
        float glow_width = pixel_size_world * 3.0;
        float critical_glow = (1.0 - smoothstep(line_width - aa, line_width + glow_width + aa, d_critical)) * (1.0 - line_val);
        
        // Mix critical line glow
        base_color = mix(base_color, vec3(1.0, 0.84, 0.3), critical_glow * pulse * 0.5);
        
        // Mix pulsed critical center line core
        vec3 pulsed_gold = vec3(1.0, 0.84, 0.3) * (1.0 + 0.15 * pulse);
        base_color = mix(base_color, pulsed_gold, line_val * 0.8);
    }

    if (show_hud_zeros && visited_zeros_size > 0) {
        float core_intensity = 0.0;
        float border_intensity = 0.0;
        float glow_intensity = 0.0;

        float accented_core_intensity = 0.0;
        float accented_border_intensity = 0.0;
        float accented_glow_intensity = 0.0;

        float scale = view_radius * 0.4;
        
        float r_core = 0.10 * scale;
        float border_width = 0.05 * scale;
        float r_total = r_core + border_width;
        float r_glow = r_total + 0.15 * scale;

        float acc_r_core = 0.10 * scale;
        float acc_r_total = acc_r_core + border_width;
        float acc_r_glow = acc_r_total + 0.20 * scale;

        float pulse = 0.5 + 0.5 * sin(TIME * 5.0);
        float fast_pulse = 0.5 + 0.5 * sin(TIME * 15.0);

        for (int i = 0; i < visited_zeros_size; i++) {
            vec2 p = vec2(visited_zeros[i].x * 10.0 * zoom_factor, -visited_zeros[i].y * 10.0 * zoom_factor);

            float d_center = length(world_pos - p);
            float aa = fwidth(d_center);

            bool is_accented = (i == accented_zero_index);

            float cur_r_core = is_accented ? acc_r_core : r_core;
            float cur_r_total = is_accented ? acc_r_total : r_total;
            float cur_r_glow = is_accented ? acc_r_glow : r_glow;

            float core_val = 1.0 - smoothstep(cur_r_core - aa, cur_r_core + aa, d_center);
            float total_val = 1.0 - smoothstep(cur_r_total - aa, cur_r_total + aa, d_center);
            float border_val = clamp(total_val - core_val, 0.0, 1.0);

            // Pulsing glow outside the circle boundary
            float glow_val = (1.0 - smoothstep(cur_r_total - aa, cur_r_glow + aa, d_center)) * (1.0 - total_val);

            if (is_accented) {
                accented_core_intensity = max(accented_core_intensity, core_val);
                accented_border_intensity = max(accented_border_intensity, border_val);
                accented_glow_intensity = max(accented_glow_intensity, glow_val);
            } else {
                core_intensity = max(core_intensity, core_val);
                border_intensity = max(border_intensity, border_val);
                glow_intensity = max(glow_intensity, glow_val);
            }
        }

        vec3 bright_gold = vec3(1.0, 0.84, 0.3); // Bright gold
        vec3 dark_gold = vec3(0.5, 0.35, 0.05);   // Darker gold tone

        if (core_intensity > 0.0 || border_intensity > 0.0 || glow_intensity > 0.0) {
            // First mix the pulsing glow outside the circle
            base_color = mix(base_color, bright_gold, glow_intensity * pulse * 0.7);
            
            // Then mix the dark gold outline
            base_color = mix(base_color, dark_gold, clamp(border_intensity, 0.0, 1.0));
            
            // Overlay the bright gold core with a subtle brightness pulse
            vec3 pulsed_core_color = bright_gold * (1.0 + 0.25 * pulse);
            base_color = mix(base_color, pulsed_core_color, clamp(core_intensity, 0.0, 1.0));
        }

        if (accented_core_intensity > 0.0 || accented_border_intensity > 0.0 || accented_glow_intensity > 0.0) {
            // First mix the pulsing glow outside the circle
            base_color = mix(base_color, bright_gold, accented_glow_intensity * fast_pulse * 0.7);

            // Then mix the dark gold outline
            base_color = mix(base_color, dark_gold, clamp(accented_border_intensity, 0.0, 1.0));

            // Overlay the bright gold core with a subtle brightness pulse
            vec3 pulsed_core_color = bright_gold * (1.0 + 0.25 * fast_pulse);
            base_color = mix(base_color, pulsed_core_color, clamp(accented_core_intensity, 0.0, 1.0));
        }
    }

    COLOR = vec4(base_color * 0.9, 1.0);
}
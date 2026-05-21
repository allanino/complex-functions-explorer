shader_type spatial;

#include "res://shaders/field.gdshaderinc"

varying vec3 world_pos;
varying vec3 v_normal;
varying vec2 field_val;
varying float v_nan;

instance uniform int lod_level = 0;
instance uniform int neighbor_lod_left = -1;
instance uniform int neighbor_lod_right = -1;
instance uniform int neighbor_lod_top = -1;
instance uniform int neighbor_lod_bottom = -1;

uniform float lod_segments[4];
uniform float chunk_size;

uniform int color_scheme = 0;
uniform bool show_curves = true;
uniform bool show_critical_stripe = true;
uniform bool show_flow = false;

uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.3, 1.0) = 0.85;
uniform float albedo : hint_range(0.0, 1.0) = 0.15;
uniform float emission : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.7;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float matrix_hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float sdLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void vertex() {
    vec3 local_pos = VERTEX;
    if (performance_protection_active) {
        VERTEX = local_pos;
        world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
        v_normal = vec3(0.0, 1.0, 0.0);
        NORMAL = (MODEL_NORMAL_MATRIX * v_normal);
        v_nan = 0.0;
        field_val = vec2(0.0);
    } else {
        float half_size = chunk_size * 0.5;
        float eps = 0.01;

        bool on_left = VERTEX.x < -half_size + eps;
        bool on_right = VERTEX.x > half_size - eps;
        bool on_top = VERTEX.z < -half_size + eps;
        bool on_bottom = VERTEX.z > half_size - eps;

        int n_lod = -1;
        bool horizontal_edge = false; // edge along X (Top/Bottom)

        if (on_left && neighbor_lod_left > lod_level) {
            n_lod = neighbor_lod_left;
            horizontal_edge = false;
        } else if (on_right && neighbor_lod_right > lod_level) {
            n_lod = neighbor_lod_right;
            horizontal_edge = false;
        } else if (on_top && neighbor_lod_top > lod_level) {
            n_lod = neighbor_lod_top;
            horizontal_edge = true;
        } else if (on_bottom && neighbor_lod_bottom > lod_level) {
            n_lod = neighbor_lod_bottom;
            horizontal_edge = true;
        }

        vec3 snap_v = VERTEX;
        if (n_lod != -1) {
            float segments = lod_segments[n_lod];
            float s = chunk_size / segments;
            if (horizontal_edge) {
                float t = (VERTEX.x + half_size) / s;
                snap_v.x = floor(t + 0.5) * s - half_size;
            } else {
                float t = (VERTEX.z + half_size) / s;
                snap_v.z = floor(t + 0.5) * s - half_size;
            }
        }

        vec3 world_v_pos = (MODEL_MATRIX * vec4(snap_v, 1.0)).xyz;
        FieldData final_fd = get_field_with_derivatives(world_v_pos.x, world_v_pos.z);

        bool is_invalid = any(isnan(final_fd.value)) || any(isinf(final_fd.value)) ||
                        any(isnan(final_fd.d_sigma)) || any(isinf(final_fd.d_sigma)) ||
                        any(isnan(final_fd.d_t)) || any(isinf(final_fd.d_t));

        if (is_invalid) {
            v_nan = 1.0;
            field_val = vec2(0.0);
            v_normal = vec3(0.0, 1.0, 0.0);
            local_pos = vec3(snap_v.x, 0.0, snap_v.z);
        } else {
            v_nan = 0.0;
            field_val = final_fd.value;
            float mag = length(field_val);
            float h = (height_type == 0) ? height_a * log(height_epsilon + mag) : mag;

            local_pos = vec3(snap_v.x, snap_v.y + h, snap_v.z);

            float u = field_val.x;
            float v = field_val.y;
            float du_dx = 0.1 * final_fd.d_sigma.x;
            float dv_dx = 0.1 * final_fd.d_sigma.y;
            float du_dz = -0.1 * final_fd.d_t.x;
            float dv_dz = -0.1 * final_fd.d_t.y;

            float dmag_dx = (mag > 1e-12) ? (u * du_dx + v * dv_dx) / mag : 0.0;
            float dmag_dz = (mag > 1e-12) ? (u * du_dz + v * dv_dz) / mag : 0.0;

            float dh_dx = (height_type == 0) ? (height_a / (height_epsilon + mag)) * dmag_dx : dmag_dx;
            float dh_dz = (height_type == 0) ? (height_a / (height_epsilon + mag)) * dmag_dz : dmag_dz;

            v_normal = normalize(vec3(-dh_dx, 1.0, -dh_dz));
        }

        VERTEX = local_pos;
        world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
        NORMAL = (MODEL_NORMAL_MATRIX * v_normal);
    }
}

void fragment() {
    if (performance_protection_active) {
        ALBEDO = vec3(0.01, 0.02, 0.03);
        ROUGHNESS = 1.0;
        METALLIC = 0.0;
    } else if (v_nan > 0.5) {
        ALBEDO = vec3(0.0);

        // Matrix Effect
        vec2 grid = world_pos.xz * 5.0;
        vec2 ipos = floor(grid);
        vec2 fpos = fract(grid);

        float col_rand = matrix_hash(vec2(ipos.x, 0.0));
        float speed = 2.0 + col_rand * 4.0;
        float y_offset = TIME * speed;

        // Flow downwards (in Z)
        float row = ipos.y + y_offset;
        float irow = floor(row);

        float char_rand = matrix_hash(vec2(ipos.x, irow));

        // Droplet trail
        float trail = fract(-grid.y * 0.15 + TIME * speed * 0.05 + col_rand * 10.0);
        trail = pow(trail, 4.0) * 2.5;

        // Character flickering/selection
        float char_vis = step(0.997, char_rand);

        // Character shape (simple blocky approximation)
        float char_shape = smoothstep(0.1, 0.2, fpos.x) * smoothstep(0.9, 0.8, fpos.x) *
                           smoothstep(0.1, 0.2, fpos.y) * smoothstep(0.9, 0.8, fpos.y);

        vec3 matrix_color = vec3(0.0, 0.8, 0.2);

        // Glowy head of the trail
        if (trail > 2.0) {
            matrix_color = vec3(0.7, 1.0, 0.7);
        }

        EMISSION = matrix_color * trail * char_shape * char_vis;
        ROUGHNESS = 1.0;
        METALLIC = 0.0;
        SPECULAR = 0.0;
    } else {
        float x = world_pos.x;
        float z = world_pos.z;
        
        vec2 f = field_val;
        float phase = atan(f.y, f.x);
        float hue = (phase + PI) / (2.0 * PI);
        if (color_scheme == 1) {
            hue = fract(hue + 0.5);
        }
        vec3 base = hsv2rgb(vec3(hue, saturation, brightness));

        if (show_curves) {
            // 1. Get raw pixel derivatives (true density indicators)
            float raw_w_re = fwidth(f.x);
            float raw_w_im = fwidth(f.y);

            // 2. Define a density threshold where curves should completely disappear.
            // Adjust this value: lower means it fades out sooner/farther away.
            float max_density_threshold = 0.2; 

            // 3. Compute contour lines using your padded width for rendering stability
            float d_re = abs(f.x - round(f.x));
            float w_re = clamp(raw_w_re, 0.000005, 0.001) + 0.02;
            float line_re = smoothstep(w_re, 0.0, d_re);

            // Smoothly fade to 0.0 as raw_w_re approaches the threshold
            float density_re = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_re);
            line_re *= density_re;

            base *= 1.0 - line_re * 0.3;

            // 4. Compute contour lines for f.y
            float d_im = abs(f.y - round(f.y));
            float w_im = clamp(raw_w_im, 0.000005, 0.001) + 0.02;
            float line_im = smoothstep(w_im, 0.0, d_im);

            // Smoothly fade to 0.0 as raw_w_im approaches the threshold
            float density_im = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_im);
            line_im *= density_im;

            base *= 1.0 + line_im * 0.3; 
        }


        ALBEDO = base * albedo;
        vec3 final_emission = base * emission;

        // Only apply the lines rendering for zeta (at x = 0, x = 5.0, x = 10.0)
        // which corresponds to Re = 0.0, Re = 0.5, Re = 1.0
        if (show_critical_stripe && (function_type >= 0 && function_type <= 3)) {
            float zoom = zoom_factor;
            // Periodic glow factor
            float glow = 0.5 + 0.5 * sin(TIME * 2.0);
            float line_width = 0.05 * zoom;

            // Critical line at x = 5.0 * zoom (HUD x = 0.5)
            float dist_to_critical = abs(world_pos.x - 5.0 * zoom);
            float core_critical = 1.0 - smoothstep(0.0, line_width, dist_to_critical);
            float glow_critical = 1.0 - smoothstep(0.0, 0.1 * zoom, dist_to_critical);
            vec3 line_color = vec3(1.0, 1.0, 0.0); // Yellow

            // Critical stripe boundaries at x = 0.0 and x = 10.0 * zoom
            float dist_to_0 = abs(world_pos.x - 0.0);
            float core_0 = 1.0 - smoothstep(0.0, line_width, dist_to_0);
            float glow_0 = 1.0 - smoothstep(0.0, 0.1 * zoom, dist_to_0);

            float dist_to_10 = abs(world_pos.x - 10.0 * zoom);
            float core_10 = 1.0 - smoothstep(0.0, line_width, dist_to_10);
            float glow_10 = 1.0 - smoothstep(0.0, 0.1 * zoom, dist_to_10);

            vec3 white_line_color = vec3(1.0, 1.0, 1.0);

            // Combine core (sharp, steady) and glow (wide, oscillating) using additive blending
            // to prevent dark shadows when glow is low.
            final_emission += line_color * (core_critical * 0.5 + glow_critical * glow * 1.0);
            final_emission += white_line_color * (core_0 * 0.5 + glow_0 * glow * 1.0);
            final_emission += white_line_color * (core_10 * 0.5 + glow_10 * glow * 1.0);
        }

        if (show_flow) {
            float g_size = 1.25;
            vec2 cell_id = floor(world_pos.xz / g_size);
            vec2 grid_uv = fract(world_pos.xz / g_size) - 0.5;

            // Get gradient from normal (change the sign to change flow direction)
            vec2 grad = v_normal.xz;
            float grad_mag = length(grad);

            if (grad_mag > 0.001) {
                vec2 dir = grad / grad_mag;

                // Rotate grid_uv to align with gradient (pointing along +X)
                vec2 p = vec2(grid_uv.x * dir.x + grid_uv.y * dir.y, -grid_uv.x * dir.y + grid_uv.y * dir.x);

                float arrow_len = clamp(grad_mag * g_size * 2.0, 0.1 * g_size, 0.7 * g_size);
                float thickness = 0.02 * g_size;

                // Body
                float d_body = sdLine(p, vec2(-arrow_len * 0.5, 0.0), vec2(arrow_len * 0.5, 0.0));

                // Head
                vec2 head_base = vec2(arrow_len * 0.5, 0.0);
                float head_size = clamp(arrow_len * 0.2, 0.0075 * g_size, 0.1 * g_size);
                float d_head = sdLine(p, head_base, head_base + vec2(-head_size, head_size * 0.6));
                d_head = min(d_head, sdLine(p, head_base, head_base + vec2(-head_size, -head_size * 0.6)));

                float arrow_dist = min(d_body, d_head);
                float arrow_mask = smoothstep(thickness, thickness * 0.5, arrow_dist);

                // Pulse emission: sync across all arrows
                float pulse_time = fract(TIME * 1.2);
                float p_coord = (p.x / arrow_len) + 0.5; // 0 (tail) to 1 (tip)
                float pulse = smoothstep(pulse_time - 0.3, pulse_time, p_coord) * smoothstep(pulse_time + 0.05, pulse_time, p_coord);

                vec3 flow_color = vec3(1.0) * arrow_mask * (0.1 + 0.9 * pulse);
                final_emission += flow_color * 0.5;
                ALBEDO = mix(ALBEDO, vec3(1.0), arrow_mask * 0.15);
            }
        }

        EMISSION = final_emission;
        ROUGHNESS = roughness;
        METALLIC = metallic;
        SPECULAR = 0.1;
    }
}

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

struct TerrainData {
    float height;
    vec3 normal;
    vec2 field_val;
    float nan_factor;
};

TerrainData get_terrain_data(float x, float z) {
    TerrainData td;
    FieldData fd = get_field_with_derivatives(x, z);

    bool is_invalid = any(isnan(fd.value)) || any(isinf(fd.value)) ||
                    any(isnan(fd.d_sigma)) || any(isinf(fd.d_sigma)) ||
                    any(isnan(fd.d_t)) || any(isinf(fd.d_t));

    if (is_invalid) {
        td.nan_factor = 1.0;
        td.field_val = vec2(0.0);
        td.normal = vec3(0.0, 1.0, 0.0);
        td.height = 0.0;
    } else {
        td.nan_factor = 0.0;
        td.field_val = fd.value;
        float mag = length(td.field_val);
        if (height_type == 0) {
            td.height = height_a * log(height_epsilon + mag);
        } else {
            td.height = mag;
        }

        float u = td.field_val.x;
        float v = td.field_val.y;
        vec2 du_dsigma_v = fd.d_sigma;
        vec2 du_dt_v = fd.d_t;

        float du_dx = 0.1 * du_dsigma_v.x;
        float dv_dx = 0.1 * du_dsigma_v.y;
        float du_dz = -0.1 * du_dt_v.x;
        float dv_dz = -0.1 * du_dt_v.y;

        float dmag_dx = (mag > 1e-12) ? (u * du_dx + v * dv_dx) / mag : 0.0;
        float dmag_dz = (mag > 1e-12) ? (u * du_dz + v * dv_dz) / mag : 0.0;

        float dh_dx = 0.0;
        float dh_dz = 0.0;

        if (height_type == 0) {
            float denom = height_epsilon + mag;
            dh_dx = (height_a / denom) * dmag_dx;
            dh_dz = (height_a / denom) * dmag_dz;
        } else {
            dh_dx = dmag_dx;
            dh_dz = dmag_dz;
        }
        td.normal = normalize(vec3(-dh_dx, 1.0, -dh_dz));
    }
    return td;
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
        TerrainData final_td;
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

        if (n_lod != -1) {
            float segments = lod_segments[n_lod];
            float s = chunk_size / segments;
            float t, t1, t2;
            vec3 p1_local, p2_local;

            if (horizontal_edge) {
                t = (VERTEX.x + half_size) / s;
                t1 = floor(t + 0.0001);
                t2 = t1 + 1.0;
                p1_local = vec3(t1 * s - half_size, 0.0, VERTEX.z);
                p2_local = vec3(t2 * s - half_size, 0.0, VERTEX.z);
            } else {
                t = (VERTEX.z + half_size) / s;
                t1 = floor(t + 0.0001);
                t2 = t1 + 1.0;
                p1_local = vec3(VERTEX.x, 0.0, t1 * s - half_size);
                p2_local = vec3(VERTEX.x, 0.0, t2 * s - half_size);
            }

            float w = clamp(t - t1, 0.0, 1.0);
            vec3 p1_world = (MODEL_MATRIX * vec4(p1_local, 1.0)).xyz;
            vec3 p2_world = (MODEL_MATRIX * vec4(p2_local, 1.0)).xyz;

            TerrainData td1 = get_terrain_data(p1_world.x, p1_world.z);
            TerrainData td2 = get_terrain_data(p2_world.x, p2_world.z);

            final_td.height = mix(td1.height, td2.height, w);
            final_td.normal = normalize(mix(td1.normal, td2.normal, w));
            final_td.field_val = mix(td1.field_val, td2.field_val, w);
            final_td.nan_factor = mix(td1.nan_factor, td2.nan_factor, w);
        } else {
            vec3 world_v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
            final_td = get_terrain_data(world_v_pos.x, world_v_pos.z);
        }

        v_nan = final_td.nan_factor;
        field_val = final_td.field_val;
        v_normal = final_td.normal;

        local_pos.y += final_td.height;
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

        EMISSION = final_emission;
        ROUGHNESS = roughness;
        METALLIC = metallic;
        SPECULAR = 0.1;
    }
}

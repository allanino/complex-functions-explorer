shader_type spatial;

#include "res://shaders/field.gdshaderinc"

varying vec3 world_pos;
varying vec3 v_normal;
varying vec2 field_val;
varying float v_nan;

uniform int lod_level = 0;
uniform bool show_curves = true;
uniform bool show_critical_stripe = true;
uniform sampler2D field_texture : repeat_disable, filter_linear;
uniform bool use_texture = false;
uniform bool debug_view_texture = false;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float matrix_hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
    vec3 local_pos = VERTEX;
    vec3 world_v_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;

    vec2 d_sigma;
    vec2 d_t;

    if (use_texture) {
        // Leeway correction: The texture covers (size + leeway), but mesh covers size.
        // Mesh local bounds are [-size/2 - leeway/2, size/2 + leeway/2] because of how PlaneMesh was created.
        // Actually, PlaneMesh size was (size + leeway). So UV [0,1] maps exactly to the texture.
        vec4 sampled = texture(field_texture, UV);
        field_val = sampled.rg;
        d_sigma = sampled.ba;
        d_t = vec2(-d_sigma.y, d_sigma.x);
    } else {
        field_val = get_field(world_v_pos.x, world_v_pos.z);
        float eps = 0.01;
        vec2 f_dx = get_field(world_v_pos.x + eps, world_v_pos.z);
        vec2 f_dz = get_field(world_v_pos.x, world_v_pos.z + eps);
        d_sigma = (f_dx - field_val) * (10.0 / eps);
        d_t = (f_dz - field_val) * (-10.0 / eps);
    }

    bool is_invalid = any(isnan(field_val)) || any(isinf(field_val));

    if (is_invalid) {
        v_nan = 1.0;
        field_val = vec2(0.0);
        v_normal = vec3(0.0, 1.0, 0.0);
    } else {
        v_nan = 0.0;
        float mag = length(field_val);
        float h = (height_type == 0) ? height_a * log(height_epsilon + mag) : mag;
        local_pos.y += h;

        float u = field_val.x;
        float v = field_val.y;
        float du_dx = 0.1 * d_sigma.x;
        float dv_dx = 0.1 * d_sigma.y;
        float du_dz = -0.1 * d_t.x;
        float dv_dz = -0.1 * d_t.y;

        float mag_sq = u*u + v*v + 1e-12;
        float dmag_dx = (u * du_dx + v * dv_dx) / sqrt(mag_sq);
        float dmag_dz = (u * du_dz + v * dv_dz) / sqrt(mag_sq);

        float dh_dx = (height_type == 0) ? (height_a / (height_epsilon + mag)) * dmag_dx : dmag_dx;
        float dh_dz = (height_type == 0) ? (height_a / (height_epsilon + mag)) * dmag_dz : dmag_dz;

        v_normal = normalize(vec3(-dh_dx, 1.0, -dh_dz));
    }

    VERTEX = local_pos;
    world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
    NORMAL = (VIEW_MATRIX * vec4(v_normal, 0.0)).xyz;
}

void fragment() {
    if (v_nan > 0.5) {
        ALBEDO = vec3(0.0);
        vec2 grid = world_pos.xz * 5.0;
        vec2 ipos = floor(grid);
        vec2 fpos = fract(grid);
        float col_rand = matrix_hash(vec2(ipos.x, 0.0));
        float row = ipos.y + TIME * (2.0 + col_rand * 4.0);
        float char_rand = matrix_hash(vec2(ipos.x, floor(row)));
        float trail = pow(fract(-grid.y * 0.15 + TIME * (2.0 + col_rand * 4.0) * 0.05 + col_rand * 10.0), 4.0) * 2.5;
        float char_vis = step(0.997, char_rand);
        float char_shape = smoothstep(0.1, 0.2, fpos.x) * smoothstep(0.9, 0.8, fpos.x) * smoothstep(0.1, 0.2, fpos.y) * smoothstep(0.9, 0.8, fpos.y);
        EMISSION = vec3(0.0, 0.8, 0.2) * trail * char_shape * char_vis;
        ROUGHNESS = 1.0; METALLIC = 0.0; SPECULAR = 0.0;
    } else {
    float phase = atan(field_val.y, field_val.x);
    vec3 base = hsv2rgb(vec3((phase + PI) / (2.0 * PI), 0.85, 1.0));

    if (show_curves) {
        float raw_w_re = fwidth(field_val.x);
        float raw_w_im = fwidth(field_val.y);
        float max_density_threshold = 0.2; 
        float line_re = smoothstep(clamp(raw_w_re, 0.000005, 0.001) + 0.02, 0.0, abs(field_val.x - round(field_val.x)));
        line_re *= smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_re);
        base *= 1.0 - line_re * 0.3;
        float line_im = smoothstep(clamp(raw_w_im, 0.000005, 0.001) + 0.02, 0.0, abs(field_val.y - round(field_val.y)));
        line_im *= smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_im);
        base *= 1.0 + line_im * 0.3; 
    }

    ALBEDO = base * 0.15;
    vec3 final_emission = base * 0.1;

    if (debug_view_texture && use_texture) {
        vec4 tex = texture(field_texture, UV);
        ALBEDO = vec3(tex.rg * 0.1, 0.0);
        final_emission = vec3(0.0);
    }

    if (show_critical_stripe && function_type == 0) {
        float glow = 0.5 + 0.5 * sin(TIME * 2.0);
        float dist_to_critical = abs(world_pos.x - 5.0);
        final_emission += vec3(1.0, 1.0, 0.0) * ((1.0 - smoothstep(0.0, 0.05, dist_to_critical)) * 0.5 + (1.0 - smoothstep(0.0, 0.1, dist_to_critical)) * glow * 1.0);
        float dist_to_0 = abs(world_pos.x - 0.0);
        final_emission += vec3(1.0) * ((1.0 - smoothstep(0.0, 0.05, dist_to_0)) * 0.5 + (1.0 - smoothstep(0.0, 0.1, dist_to_0)) * glow * 1.0);
        float dist_to_10 = abs(world_pos.x - 10.0);
        final_emission += vec3(1.0) * ((1.0 - smoothstep(0.0, 0.05, dist_to_10)) * 0.5 + (1.0 - smoothstep(0.0, 0.1, dist_to_10)) * glow * 1.0);
    }
        EMISSION = final_emission;
        ROUGHNESS = 0.1; METALLIC = 0.7; SPECULAR = 0.1;
    }
}

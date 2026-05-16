shader_type spatial;

#include "res://shaders/field.gdshaderinc"

varying vec3 world_pos;
varying vec3 v_normal;
varying vec2 field_val;

uniform int lod_level = 0;
global uniform bool show_curves;
global uniform bool show_critical_stripe;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void vertex() {
    vec3 local_pos = VERTEX;
    vec3 world_v_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;

    int iters = iterations;
    if (function_type == 0) {
        if (lod_level == 1) iters = int(float(iters) * 0.8);
        else if (lod_level == 2) iters = int(float(iters) * 0.6);
        else if (lod_level == 3) iters = int(float(iters) * 0.4);
    }

    FieldData fd = get_field_with_derivatives(world_v_pos.x, world_v_pos.z, iters);
    field_val = fd.value;

    float mag = length(field_val);
    float h = 0.0;
    if (height_type == 0) {
        h = height_a * log(height_epsilon + mag);
    } else {
        h = mag;
    }
    local_pos.y += h;
    VERTEX = local_pos;
    world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;

    // Analytical normals using derivatives
    float u = field_val.x;
    float v = field_val.y;

    // sigma = x * 0.1, t = -z * 0.1
    // d_sigma/dx = 0.1, dt/dz = -0.1
    vec2 du_dsigma_v = fd.d_sigma; // (du/dsigma, dv/dsigma)
    vec2 du_dt_v = fd.d_t;         // (du/dt, dv/dt)

    float du_dx = 0.1 * du_dsigma_v.x;
    float dv_dx = 0.1 * du_dsigma_v.y;
    float du_dz = -0.1 * du_dt_v.x;
    float dv_dz = -0.1 * du_dt_v.y;

    float mag_sq = u*u + v*v + 1e-12;
    float dmag_dx = (u * du_dx + v * dv_dx) / sqrt(mag_sq);
    float dmag_dz = (u * du_dz + v * dv_dz) / sqrt(mag_sq);

    float dh_dx = 0.0;
    float dh_dz = 0.0;

    if (height_type == 0) {
        // h = height_a * log(height_epsilon + mag)
        float denom = height_epsilon + mag;
        dh_dx = (height_a / denom) * dmag_dx;
        dh_dz = (height_a / denom) * dmag_dz;
    } else {
        // h = mag
        dh_dx = dmag_dx;
        dh_dz = dmag_dz;
    }

    v_normal = normalize(vec3(-dh_dx, 1.0, -dh_dz));
    NORMAL = (MODEL_NORMAL_MATRIX * v_normal);
}

void fragment() {
    float x = world_pos.x;
    float z = world_pos.z;
	
	vec2 f = field_val;
    float phase = atan(f.y, f.x);
    float hue = (phase + PI) / (2.0 * PI);
    vec3 base = hsv2rgb(vec3(hue, 0.85, 1.0));

    if (show_curves) {
        // Compute countour lines where f.x is integer
        float d_re = abs(f.x - round(f.x));
        float w_re = clamp(fwidth(f.x), 0.000005, 0.001) + 0.02;
        float line_re = smoothstep(w_re, 0.0, d_re);

        float density_re = 1.0 / (1.0 + 20.0 * w_re);
        line_re *= density_re;

        base *= 1.0 - line_re * 0.75;

        // Compute countour lines where f.y is integer
        float d_im = abs(f.y - round(f.y));
        float w_im = clamp(fwidth(f.y), 0.000005, 0.001) + 0.02;
        float line_im = smoothstep(w_im, 0.0, d_im);

        float density_im = 1.0 / (1.0 + 20.0 * w_im);
        line_im *= density_im;

        base *= 1.0 + line_im * 0.75;

        // Apply to base and emission
        // (Note: ALBEDO and base emission use the modified base)
    }


    ALBEDO = base * 0.5;
    vec3 final_emission = base * 0.05;

    // Only apply the lines rendering for zeta (at x = 0, x = 5.0, x = 10.0)
    // which corresponds to Re = 0.0, Re = 0.5, Re = 1.0
    if (show_critical_stripe && function_type == 0) {
        // Periodic glow factor
        float glow = 0.5 + 0.5 * sin(TIME * 2.0);
        float line_width = 0.05;

        // Critical line at x = 5.0 (HUD x = 0.5)
        float dist_to_critical = abs(world_pos.x - 5.0);
        float core_critical = 1.0 - smoothstep(0.0, line_width, dist_to_critical);
        float glow_critical = 1.0 - smoothstep(0.0, 0.1, dist_to_critical);
        vec3 line_color = vec3(1.0, 1.0, 0.0); // Yellow

        // Critical stripe boundaries at x = 0.0 and x = 10.0
        float dist_to_0 = abs(world_pos.x - 0.0);
        float core_0 = 1.0 - smoothstep(0.0, line_width, dist_to_0);
        float glow_0 = 1.0 - smoothstep(0.0, 0.1, dist_to_0);

        float dist_to_10 = abs(world_pos.x - 10.0);
        float core_10 = 1.0 - smoothstep(0.0, line_width, dist_to_10);
        float glow_10 = 1.0 - smoothstep(0.0, 0.1, dist_to_10);

        vec3 white_line_color = vec3(1.0, 1.0, 1.0);

        // Combine core (sharp, steady) and glow (wide, oscillating) using additive blending
        // to prevent dark shadows when glow is low.
        final_emission += line_color * (core_critical * 0.5 + glow_critical * glow * 1.0);
        final_emission += white_line_color * (core_0 * 0.5 + glow_0 * glow * 1.0);
        final_emission += white_line_color * (core_10 * 0.5 + glow_10 * glow * 1.0);
    }

    float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
    final_emission += fresnel * 0.03;

    EMISSION = final_emission;
	ROUGHNESS = 0.05;
	METALLIC = 0.4;
	SPECULAR = 0.2;
}

shader_type spatial;

#include "res://shaders/field.gdshaderinc"

varying vec3 world_pos;
varying vec3 v_normal;
varying vec2 field_val;

uniform int surface_shading_mode = 2; // 0: Disabled, 1: Estimated, 2: Precise
uniform bool show_curves = true;
uniform bool show_critical_stripe = true;
uniform float night_factor = 0.0;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}


void vertex() {
    vec3 local_pos = VERTEX;
    vec3 world_v_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;

    field_val = get_field(world_v_pos.x, world_v_pos.z);
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

    if (surface_shading_mode == 2) {
        // Precise normals using finite differences
        float delta = 0.01;
        float h_right = get_height(world_v_pos.x + delta, world_v_pos.z);
        float h_forward = get_height(world_v_pos.x, world_v_pos.z + delta);

        vec3 v_right = vec3(delta, h_right - h, 0.0);
        vec3 v_forward = vec3(0.0, h_forward - h, delta);
        v_normal = normalize(cross(v_forward, v_right));
    } else {
        v_normal = vec3(0.0, 1.0, 0.0);
    }
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

    if (surface_shading_mode == 1) {
        NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
    }

    ALBEDO = base * 0.5;

    // Base emission + Night luminescence
    // Luminescence is 0.4 at night, 0.05 during day
    float lum = mix(0.05, 0.4, night_factor);
    vec3 final_emission = base * lum;

    // Only apply the lines rendering for zeta (at x = 0, x = 5.0, x = 10.0)
    // which corresponds to Re = 0.0, Re = 0.5, Re = 1.0
    if (show_critical_stripe && function_type == 0) {
        // Periodic glow factor
        float glow = 0.5 + 0.5 * sin(TIME * 2.0);
        float line_width = 0.05;

        // Critical line at x = 5.0 (HUD x = 0.5)
        float dist_to_critical = abs(world_pos.x - 5.0);
        float core_critical = 1.0 - smoothstep(0.0, line_width, dist_to_critical);
        float glow_critical = 1.0 - smoothstep(0.0, 0.15, dist_to_critical);
        vec3 line_color = vec3(1.0, 1.0, 0.0); // Yellow

        // Critical stripe boundaries at x = 0.0 and x = 10.0
        float dist_to_0 = abs(world_pos.x - 0.0);
        float core_0 = 1.0 - smoothstep(0.0, line_width, dist_to_0);
        float glow_0 = 1.0 - smoothstep(0.0, 0.15, dist_to_0);

        float dist_to_10 = abs(world_pos.x - 10.0);
        float core_10 = 1.0 - smoothstep(0.0, line_width, dist_to_10);
        float glow_10 = 1.0 - smoothstep(0.0, 0.15, dist_to_10);

        vec3 white_line_color = vec3(1.0, 1.0, 1.0);

        // Combine core (sharp, steady) and glow (wide, oscillating) using additive blending
        // to prevent dark shadows when glow is low.
        final_emission += line_color * (core_critical * 4.0 + glow_critical * glow * 2.0);
        final_emission += white_line_color * (core_0 * 4.0 + glow_0 * glow * 2.0);
        final_emission += white_line_color * (core_10 * 4.0 + glow_10 * glow * 2.0);
    }

    float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
    final_emission += fresnel * 0.03;

    EMISSION = final_emission;
	ROUGHNESS = 0.05;
	METALLIC = 0.4;
	SPECULAR = 0.2;
}

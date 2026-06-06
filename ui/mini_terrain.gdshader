shader_type canvas_item;

#include "res://math/complex_field.gdshaderinc"

uniform vec2 player_pos_world;
uniform float view_radius = 20.0;
uniform int color_scheme = 0;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
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

    COLOR = vec4(base_color, 1.0);
}

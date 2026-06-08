shader_type canvas_item;

uniform vec2 current_f; // Current value of f(x,z)
uniform int color_scheme = 0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.3, 1.0) = 0.85;
uniform float albedo : hint_range(0.0, 1.0) = 0.15;
uniform float emission : hint_range(0.0, 1.0) = 0.1;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    float current_phase = atan(current_f.y, current_f.x);

    // UV.x maps from 0 to 1.
    // We want the center (UV.x = 0.5) to correspond to the current phase.
    // So for a given UV.x, what is its phase?
    // Let offset be from -PI to PI
    float phase_offset = (UV.x - 0.5) * 2.0 * PI;

    float phase = current_phase + phase_offset;

    // Background color based on phase
    float hue = (phase + PI) / (2.0 * PI);
    if (color_scheme == 1) {
        hue = fract(hue + 0.5);
    }
    vec3 base = hsv2rgb(vec3(hue, saturation, brightness));

    if (color_scheme == 2) {
        float v = 0.5 + 0.5 * cos(phase);
        base = vec3(v) * brightness;
    }

    vec3 color = base * (albedo + emission ) * 2.0;

    // Draw white line indicator at the center
    float line_mask = smoothstep(0.015, 0.01, abs(UV.x - 0.5));

    // Draw magnitude string based on current_f
    float f_mag = length(current_f);
    if (f_mag > 0.001) {
        color = mix(color, vec3(1.0), line_mask);
    }

    COLOR = vec4(color, 1.0);
}

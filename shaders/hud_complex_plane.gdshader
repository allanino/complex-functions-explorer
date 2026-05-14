shader_type canvas_item;

uniform vec2 current_f; // Current value of f(x,z)
uniform float scale = 2.0; // Current scale of the complex plane view

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Distance to a line segment
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void fragment() {
    // Map UV to complex plane [-scale, scale]
    vec2 z = (UV - 0.5) * 2.0 * scale;

    // Calculate phase and magnitude
    float phase = atan(z.y, z.x);
    float mag = length(z);

    // Background color based on phase
    float hue = (phase + PI) / (2.0 * PI);
    vec3 color = hsv2rgb(vec3(hue, 0.6, 0.7)); // Brighter background

    // Draw unit circle
    float unit_circle = abs(mag - 1.0);
    float circle_mask = smoothstep(0.02 * scale, 0.0, unit_circle);
    color = mix(color, vec3(0.0), circle_mask);

    // Draw arrow for phase
    float f_mag = length(current_f);
    if (f_mag > 0.001) {
        vec2 dir = current_f / f_mag;
        vec2 tip = dir; // Pointing to unit circle

        // Shaft
        float d = sdSegment(z, vec2(0.0), tip);

        // Arrow head
        vec2 perp = vec2(-dir.y, dir.x);
        vec2 head_base = tip - 0.15 * dir * (scale / 2.0); // Adjust size by scale
        d = min(d, sdSegment(z, tip, head_base + 0.08 * perp * (scale / 2.0)));
        d = min(d, sdSegment(z, tip, head_base - 0.08 * perp * (scale / 2.0)));

        float arrow_mask = smoothstep(0.02 * scale, 0.0, d);
        color = mix(color, vec3(1.0), arrow_mask);
    }

    COLOR = vec4(color, 0.5);
}

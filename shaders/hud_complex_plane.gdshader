shader_type canvas_item;

uniform vec2 current_f; // Current value of f(x,z)
uniform float scale = 2.0; // Current scale of the complex plane view

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
    // Map UV to complex plane [-scale, scale]
    vec2 z = (UV - 0.5) * 2.0 * scale;

    // Calculate phase and magnitude
    float phase = atan(z.y, z.x);
    float mag = length(z);

    // Background color based on phase
    float hue = (phase + PI) / (2.0 * PI);
    vec3 color = hsv2rgb(vec3(hue, 0.6, 0.4)); // Darker background

    // Draw unit circle
    float unit_circle = abs(mag - 1.0);
    float circle_mask = smoothstep(0.02 * scale, 0.0, unit_circle);
    color = mix(color, vec3(0.0), circle_mask);

    // Draw current f(x,z) position
    float dist_to_f = length(z - current_f);
    float f_mask = smoothstep(0.05 * scale, 0.0, dist_to_f);
    color = mix(color, vec3(1.0), f_mask);

    COLOR = vec4(color, 0.8);
}

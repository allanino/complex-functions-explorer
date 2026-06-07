shader_type canvas_item;

uniform vec2 current_f; // Current value of f(x,z)
uniform int color_scheme = 0;
uniform float scale = 2.0; // Current scale of the complex plane view
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

// Distance to a line segment
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdTriangle(vec2 p, vec2 p0, vec2 p1, vec2 p2)
{
    vec2 e0 = p1 - p0;
    vec2 e1 = p2 - p1;
    vec2 e2 = p0 - p2;

    vec2 v0 = p - p0;
    vec2 v1 = p - p1;
    vec2 v2 = p - p2;

    vec2 pq0 = v0 - e0 * clamp(dot(v0,e0)/dot(e0,e0), 0.0, 1.0);
    vec2 pq1 = v1 - e1 * clamp(dot(v1,e1)/dot(e1,e1), 0.0, 1.0);
    vec2 pq2 = v2 - e2 * clamp(dot(v2,e2)/dot(e2,e2), 0.0, 1.0);

    float s = sign(e0.x*e2.y - e0.y*e2.x);

    vec2 d = min(
        min(vec2(dot(pq0,pq0), s*(v0.x*e0.y - v0.y*e0.x)),
            vec2(dot(pq1,pq1), s*(v1.x*e1.y - v1.y*e1.x))),
        vec2(dot(pq2,pq2), s*(v2.x*e2.y - v2.y*e2.x))
    );

    return -sqrt(d.x) * sign(d.y);
}

void fragment() {
    // Map UV to complex plane [-scale, scale]
    // Invert Y so that positive imaginary values are at the top
    vec2 z = (vec2(UV.x, 1.0 - UV.y) - 0.5) * 2.0 * scale;

    // Calculate phase and magnitude
    float phase = atan(z.y, z.x);
    float mag = length(z);

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

    // Draw unit circle
    float unit_circle = abs(mag - 1.0);
    float circle_mask = smoothstep(0.02 * scale + fwidth(unit_circle), 0.0, unit_circle);
    color = mix(color, vec3(0.9), circle_mask);

    // Draw arrow for phase
    float f_mag = length(current_f);
    if (f_mag > 0.001) {
        vec2 dir = current_f / f_mag;
        vec2 tip = dir; // Pointing to unit circle

        // Shaft
        float d = sdSegment(z, vec2(0.0), tip);
        // The base arrow thickness is 0.02 * scale, adding fwidth(d) thickens by 1px
        float arrow_thickness = 0.02 * scale + fwidth(d);

        // Arrow head
        vec2 perp = vec2(-dir.y, dir.x);
        vec2 head_base = tip - 0.15 * dir * (scale / 2.0); // Adjust size by scale
        float d_head = sdTriangle(z, tip, head_base + 0.08 * perp * (scale / 2.0), head_base - 0.08 * perp * (scale / 2.0));

        d = min(d - arrow_thickness, d_head);

        float arrow_mask = 1.0 - smoothstep(0.0, fwidth(d), d);
        color = mix(color, vec3(1.0), arrow_mask);
    }

    COLOR = vec4(color, 1.0);
}

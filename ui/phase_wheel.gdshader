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
    // Map UV to centered [-1, 1] range. Invert Y for math coords.
    vec2 z = (vec2(UV.x, 1.0 - UV.y) - 0.5) * 2.0;

    float mag = length(z);
    float phase = atan(z.y, z.x);

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
    vec3 color_hsv = base * (albedo + emission) * 2.0;

    // Radius of the main track
    float track_radius = 0.90;

    // Draw the glowing track ring
    float track_dist = abs(mag - track_radius);

    // Create an emissive neon-like glow bleeding effect
    float track_glow = exp(-track_dist * 10.0) * 0.4;
    // Core of the ring
    float track_core = smoothstep(0.0225 + fwidth(track_dist), 0.0, track_dist);

    // Base composition is a transparent background + colored glowing ring
    vec3 color = vec3(0.0);
    float alpha = 0.0;

    // Add colored ring. The color depends on the phase at that point on the ring.
    vec3 ring_color = color_hsv;
    color += ring_color * track_glow;
    alpha += track_glow;
    color = mix(color, ring_color * 1.5, track_core); // Make the core bright
    alpha = max(alpha, track_core);

    // Calculate phase and magnitude of current_f
    float f_mag = length(current_f);
    if (f_mag > 0.001) {
        vec2 dir = current_f / f_mag;
        vec2 tip = dir * track_radius; // Pointing precisely to the track

        // Dynamic minimum line thickness
        float fw = fwidth(z.x);

        // Shaft
        // Start the shaft partway out to avoid crossing the central text
        vec2 shaft_start = dir * 0.45;
        float d_shaft = sdSegment(z, shaft_start, tip);
        float arrow_thickness = 0.008 + fw;
        float shaft_mask = smoothstep(arrow_thickness + fw, arrow_thickness - fw, d_shaft);

        // Arrow head
        vec2 perp = vec2(-dir.y, dir.x);
        vec2 head_base = tip - 0.1 * dir;
        float d_head = sdTriangle(z, tip, head_base + 0.05 * perp, head_base - 0.05 * perp);
        float head_mask = smoothstep(fw, -fw, d_head);

        // Arrow dot/bead precisely on the track
        float d_bead = length(z - tip) - 0.025;
        float bead_mask = smoothstep(fw, -fw, d_bead);

        // Combine arrow elements
        float arrow_mask = max(shaft_mask, max(head_mask, bead_mask));

        // Overlay sharp stark white arrow
        color = mix(color, vec3(1.0), arrow_mask);
        alpha = max(alpha, arrow_mask);
    }

    // Draw tick marks inside the ring
    // 72 ticks (every 5 degrees)
    float tick_count = 72.0;
    float tick_phase = fract((phase + PI) / (2.0 * PI) * tick_count);
    float tick_mask = step(abs(tick_phase - 0.5), 0.05); // tick width
    float tick_dist = step(mag, track_radius - 0.02) * step(track_radius - 0.06, mag);
    float ticks = tick_mask * tick_dist;

    // Subtle off-white ticks
    color = mix(color, vec3(0.5), ticks * 0.5);
    alpha = max(alpha, ticks * 0.5);

    COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}

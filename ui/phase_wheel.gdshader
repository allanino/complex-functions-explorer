shader_type canvas_item;

uniform vec2 current_f; // Current value of f(x,z)
uniform int color_scheme = 0;
uniform vec3 re_plus = vec3(1.0, 0.0, 0.0);
uniform vec3 re_minus = vec3(0.0, 1.0, 1.0);
uniform vec3 im_plus = vec3(0.0, 1.0, 0.0);
uniform vec3 im_minus = vec3(1.0, 1.0, 0.0);
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
    } else if (color_scheme == 3) {
        float c = cos(phase);
        float s = sin(phase);
        float w_re_plus = max(0.0, c);
        float w_re_minus = max(0.0, -c);
        float w_im_plus = max(0.0, s);
        float w_im_minus = max(0.0, -s);

        float norm = abs(c) + abs(s);

        base = ((w_re_plus * re_plus + w_re_minus * re_minus +
                w_im_plus * im_plus + w_im_minus * im_minus) / norm) * brightness;
    }
    vec3 color_hsv = base * (albedo + emission) * 2.0;

    // Radius of the main track
    float track_radius = 0.85;

    // Draw the glowing track ring
    float track_dist = abs(mag - track_radius);

    // Core of the ring
    float ring_half_width = 0.05;
    float aa = fwidth(track_dist) * 0.8;

    float track_core = smoothstep(ring_half_width + aa, ring_half_width - aa, track_dist);

    // Base composition is a transparent background + colored glowing ring
    vec3 color = vec3(0.0);
    float alpha = 0.0;

    // Add colored ring. The color depends on the phase at that point on the ring.
    vec3 ring_color = color_hsv;

    color = mix(color, ring_color * 1.15, track_core); // Make the core bright
    alpha = max(alpha, pow(track_core, 1.4));

    // Calculate arrow mask (deferred compositing so it renders on top of ticks)
    float arrow_mask = 0.0;
    float bead_core_mask_val = 0.0;
    float bead_outline_mask = 0.0;
    float f_mag = length(current_f);
    if (f_mag > 0.00001) {
        vec2 dir = current_f / f_mag;
        float arrow_gap = 0.12; // gap between arrowhead tip and the color ring
        vec2 tip = dir * (track_radius - arrow_gap);

    
        float ring_thickness = 0.003; // tune visually
        vec2 bead_pos = dir * (track_radius - ring_thickness * 0.5);

        // vec2 bead_pos = dir * track_radius; // bead stays on the ring

        // Dynamic minimum line thickness
        float fw_arrow = fwidth(z.x);

        // Shaft - start partway out to avoid crossing the central text, end at arrowhead base
        vec2 shaft_start = dir * 0.45;
        vec2 head_base = tip - 0.1 * dir;
        float d_shaft = sdSegment(z, shaft_start, head_base);
        float arrow_thickness = 0.015;
        
        float arrow_aa = fw_arrow * 0.9;

        float shaft_mask = smoothstep(
            arrow_thickness + arrow_aa,
            arrow_thickness - arrow_aa,
            d_shaft
        );

        
        // Arrow head
        vec2 perp = vec2(-dir.y, dir.x);
        float d_head = sdTriangle(z, tip, head_base + 0.06 * perp, head_base - 0.06 * perp);
        float head_mask = smoothstep(fw_arrow, -fw_arrow, d_head);

        // Arrow dot/bead pinned to the track ring (with outline for scientific instrumentation contrast)
        float bead_radius = 0.025;
        float dist_bead = length(z - bead_pos);
        bead_core_mask_val = smoothstep(fw_arrow, -fw_arrow, dist_bead - bead_radius);
        
        float outline_width = fw_arrow * 1.0;
        bead_outline_mask = smoothstep(fw_arrow, -fw_arrow, dist_bead - (bead_radius + outline_width));

        // arrow_mask is just shaft and head (bead is rendered separately for transparency)
        arrow_mask = max(shaft_mask, head_mask);
    }

    // Draw tick marks as true radial line segments (AA, angle-aligned)
    float fw = fwidth(mag);
    float tick_count = 16.0; // one tick every 10 degrees

    float pixel_angle = phase;
    float step_rad = 2.0 * PI / tick_count;
    float nearest_tick_index = round(pixel_angle / step_rad);

    // Check the three nearest ticks (for pixels near a tick boundary)
    float best_minor = 0.0;
    float best_cardinal = 0.0;
    for (int i = -1; i <= 1; i++) {
        float tick_angle = (nearest_tick_index + float(i)) * step_rad;
        vec2 tick_dir = vec2(cos(tick_angle), sin(tick_angle));

        // Cardinal tick (0, 90, 180, 270 degrees)?
        float cardinal_check = mod(abs(tick_angle), PI * 0.5);
        bool is_cardinal = (cardinal_check < 0.001 || cardinal_check > PI * 0.5 - 0.001);

        // Radial extent of the tick segment: just inside the track
        float tick_inner = is_cardinal ? track_radius - 0.1 : track_radius - 0.08;
        float tick_outer = track_radius - 0.05;
        float tick_half_width = is_cardinal ? 0.008 : 0.006;

        vec2 p0 = tick_dir * tick_inner;
        vec2 p1 = tick_dir * tick_outer;
        float d = sdSegment(z, p0, p1);
       
        float tick_aa = fw * 0.45;

        float tick_mask = smoothstep(
            tick_half_width + tick_aa,
            tick_half_width - tick_aa,
            d
        );

        if (is_cardinal) {
            best_cardinal = max(best_cardinal, tick_mask * 1.0);
        } else {
            best_minor = max(best_minor, tick_mask * 0.6);
        }
    }

    // Composite: ticks first, then arrow on top
    vec3 brighter_gold = vec3(1.0, 0.84, 0.3);
    vec3 darker_gold = vec3(0.784, 0.663, 0.431);
    color = mix(color, darker_gold, best_minor);
    alpha = max(alpha, best_minor);
    color = mix(color, brighter_gold, best_cardinal);
    alpha = max(alpha, best_cardinal);

    // Overlay dark outline for the bead with reduced opacity (contrast outline)
    float bead_opacity = 0.8; // reduce opacity of the bead a little
    color = mix(color, vec3(0.0), bead_outline_mask * bead_opacity);
    alpha = max(alpha, bead_outline_mask * bead_opacity);

    // Overlay bead core with reduced opacity
    color = mix(color, darker_gold, bead_core_mask_val * bead_opacity);
    alpha = max(alpha, bead_core_mask_val * bead_opacity);

    // Overlay sharp stark white arrow on top of everything
    color = mix(color, darker_gold, arrow_mask);
    alpha = max(alpha, arrow_mask);

    COLOR = vec4(color, clamp(alpha, 0.0, 0.8));
}

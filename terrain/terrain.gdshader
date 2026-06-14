shader_type spatial;
render_mode cull_disabled;

#include "res://math/complex_field.gdshaderinc"

varying vec3 world_pos;
varying vec3 v_normal;
varying vec2 field_val;
varying vec2 v_f_dir;
varying float v_nan;
varying float v_h_clamped;

instance uniform int lod_level = 0;
instance uniform ivec4 neighbor_lods = ivec4(-1, -1, -1, -1);

uniform float lod_segments[7];
uniform float chunk_size;

uniform float real_level_curves_highlighted[10];
uniform float imag_level_curves_highlighted[10];

uniform vec2 newton_path[50];
uniform int newton_path_size;
uniform vec4 newton_path_bbox; // x_min, x_max, y_min, y_max

uniform int color_scheme = 0;
uniform bool show_curves = true;
uniform bool show_critical_stripe = true;
uniform bool show_flow = false;
uniform bool show_position_marker = true;

uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.3, 1.0) = 0.85;
uniform float albedo : hint_range(0.0, 1.0) = 0.15;
uniform float emission : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.7;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float surface_texture : hint_range(0.0, 1.0) = 0.0;
uniform float morph : hint_range(0.0, 1.0) = 1.0;
uniform int morph_style = 1;
uniform float portal_height = 50.0;
uniform float portal_width = 100.0;
uniform float portal_min_height = -50.0;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float max_world_height = 1000.0;

uniform float self_illumination = 0.0;
uniform float fog_density = 0.0;
uniform vec3 player_position_world = vec3(0.0);



// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float matrix_hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

// Simple 3D noise for surface texture
float hash3(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yxz + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise3(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash3(p + vec3(0,0,0)), hash3(p + vec3(1,0,0)), f.x),
                   mix(hash3(p + vec3(0,1,0)), hash3(p + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash3(p + vec3(0,0,1)), hash3(p + vec3(1,0,1)), f.x),
                   mix(hash3(p + vec3(0,1,1)), hash3(p + vec3(1,1,1)), f.x), f.y), f.z);
}

float fbm3(vec3 p) {
    float f = 0.0;
    float w = 0.5;
    for (int i = 0; i < 4; i++) {
        f += w * noise3(p);
        p *= 2.0;
        w *= 0.5;
    }
    return f;
}

float sdLine(vec2 p, vec2 a, vec2 b) {
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
        min(
            vec2(dot(pq0,pq0), s*(v0.x*e0.y - v0.y*e0.x)),
            vec2(dot(pq1,pq1), s*(v1.x*e1.y - v1.y*e1.x))
        ),
        vec2(dot(pq2,pq2), s*(v2.x*e2.y - v2.y*e2.x))
    );

    return -sqrt(d.x) * sign(d.y);
}



vec3 apply_lod_snapping(vec3 vertex_pos, float half_size) {
    float eps = 0.01;

    bool on_left = vertex_pos.x < -half_size + eps;
    bool on_right = vertex_pos.x > half_size - eps;
    bool on_top = vertex_pos.z < -half_size + eps;
    bool on_bottom = vertex_pos.z > half_size - eps;

    int n_lod = -1;
    bool horizontal_edge = false; // edge along X (Top/Bottom)

    if (on_left && neighbor_lods.x > lod_level) {
        n_lod = neighbor_lods.x;
        horizontal_edge = false;
    } else if (on_right && neighbor_lods.y > lod_level) {
        n_lod = neighbor_lods.y;
        horizontal_edge = false;
    } else if (on_top && neighbor_lods.z > lod_level) {
        n_lod = neighbor_lods.z;
        horizontal_edge = true;
    } else if (on_bottom && neighbor_lods.w > lod_level) {
        n_lod = neighbor_lods.w;
        horizontal_edge = true;
    }

    vec3 snap_v = vertex_pos;
    if (n_lod != -1) {
        float segments = lod_segments[n_lod];
        float s = chunk_size / segments;
        if (horizontal_edge) {
            float t = (vertex_pos.x + half_size) / s;
            snap_v.x = floor(t + 0.5) * s - half_size;
        } else {
            float t = (vertex_pos.z + half_size) / s;
            snap_v.z = floor(t + 0.5) * s - half_size;
        }
    }
    return snap_v;
}


int calculate_branch_offset(vec3 world_v_pos, vec3 cam_pos, out bool in_portal) {
    int branch_offset = 0;
    in_portal = false;
    if (cam_pos.z * world_v_pos.z < 0.0 || (cam_pos.z != 0.0 && world_v_pos.z == 0.0)) {
        float denom = cam_pos.z - world_v_pos.z;
        if (denom == 0.0) {
            denom = 1e-9;
        }
        float r = cam_pos.z / denom;
        float px = cam_pos.x + r * (world_v_pos.x - cam_pos.x);
        float py = cam_pos.y + r * (world_v_pos.y - cam_pos.y);

        if (function_type == MULTIVALUED_ASIN || function_type == MULTIVALUED_ACOS) {
            float threshold = 10.0 * zoom_factor;
            if ((px >= threshold && px < threshold + portal_width) ||
                (px <= -threshold && px > -threshold - portal_width)) {
                if (py > portal_min_height && py < portal_height) {
                    in_portal = true;
                }
            }
        } else {
            if (px < 0.0 && px > -portal_width && py > portal_min_height && py < portal_height) {
                in_portal = true;
            }
        }

        if (in_portal) {
            if (function_type == MULTIVALUED_ASIN || function_type == MULTIVALUED_ACOS) { // ASIN or ACOS
                bool is_even = (current_branch % 2 == 0);
                if (px >= 0.0) {
                    branch_offset = is_even ? 1 : -1;
                } else {
                    branch_offset = is_even ? -1 : 1;
                }
            } else {
                // For negative branch cuts (Log and Power functions),
                // the branch offset signs are inverted relative to positive cuts.
                branch_offset = (cam_pos.z > 0.0) ? -1 : 1;
            }
        }
    }
    return branch_offset;
}


vec3 apply_branch_cut_perturbation(vec3 world_v_pos, vec3 cam_pos, bool in_portal) {
    // Perturb boundary vertices exactly on/near the branch cut (world_v_pos.z == 0.0)
    // to resolve the exact-zero branch discontinuity in atan(y, x).
    // - If viewed through the portal (in_portal is true), the vertex belongs to the
    //   opposite side of the camera, so we nudge it in the direction opposite to cam_pos.z.
    // - If viewed outside the portal (in_portal is false), the vertex belongs to the
    //   same side as the camera, so we nudge it in the direction of cam_pos.z.
    if (abs(world_v_pos.z) < 1e-5) {
        float side_sign = in_portal ? -sign(cam_pos.z) : sign(cam_pos.z);
        if (side_sign == 0.0) side_sign = 1.0;
        world_v_pos.z = side_sign * 1e-5;
    }
    return world_v_pos;
}


void compute_matrix_effect(vec2 world_xz, vec3 base_color, vec3 head_color, out vec3 out_albedo, out vec3 out_emission, out float rgh, out float mtl, out float spec) {
    out_albedo = vec3(0.0);

    // Matrix Effect
    vec2 grid = world_xz * 5.0;
    vec2 ipos = floor(grid);
    vec2 fpos = fract(grid);

    float col_rand = matrix_hash(vec2(ipos.x, 0.0));
    float speed = 2.0 + col_rand * 4.0;
    float y_offset = TIME * speed;

    // Flow downwards (in Z)
    float row = ipos.y + y_offset;
    float irow = floor(row);

    float char_rand = matrix_hash(vec2(ipos.x, irow));

    // Droplet trail
    float trail = fract(-grid.y * 0.15 + TIME * speed * 0.05 + col_rand * 10.0);
    trail = pow(trail, 4.0) * 2.5;

    // Character flickering/selection
    float char_vis = step(0.997, char_rand);

    // Character shape (simple blocky approximation)
    float char_shape = smoothstep(0.1, 0.2, fpos.x) * smoothstep(0.9, 0.8, fpos.x) *
                       smoothstep(0.1, 0.2, fpos.y) * smoothstep(0.9, 0.8, fpos.y);

    vec3 matrix_color = base_color;

    // Glowy head of the trail
    if (trail > 2.0) {
        matrix_color = head_color;
    }

    out_emission = matrix_color * trail * char_shape * char_vis;
    rgh = 1.0;
    mtl = 0.0;
    spec = 0.0;
}


void compute_curves_highlight(vec2 f, float raw_w_re, float raw_w_im, inout vec3 base, out float highlight_re_glow, out float highlight_im_glow) {
    highlight_re_glow = 0.0;
    highlight_im_glow = 0.0;

    // 1. Define a density threshold where curves should completely disappear.
    // Adjust this value: lower means it fades out sooner/farther away.
    float max_density_threshold = 0.2;

    // 2. Compute contour lines using your padded width for rendering stability
    float d_re = abs(f.x - round(f.x));

    bool is_real_highlighted = false;
    for (int i = 0; i < 10; i++) {
        if (abs(round(f.x) - real_level_curves_highlighted[i]) < 0.1) {
            is_real_highlighted = true;
            break;
        }
    }

    float w_re = clamp(raw_w_re, 0.000005, 0.001) + (is_real_highlighted ? 0.06 : 0.02);
    float line_re = smoothstep(w_re, 0.0, d_re);

    // Smoothly fade to 0.0 as raw_w_re approaches the threshold
    float density_re = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_re);
    line_re *= density_re;

    base *= 1.0 - line_re * (is_real_highlighted ? 0.8 : 0.3);
    if (is_real_highlighted) {
        highlight_re_glow = line_re;
    }

    // 4. Compute contour lines for f.y
    float d_im = abs(f.y - round(f.y));

    bool is_imag_highlighted = false;
    for (int i = 0; i < 10; i++) {
        if (abs(round(f.y) - imag_level_curves_highlighted[i]) < 0.1) {
            is_imag_highlighted = true;
            break;
        }
    }

    float w_im = clamp(raw_w_im, 0.000005, 0.001) + (is_imag_highlighted ? 0.06 : 0.02);
    float line_im = smoothstep(w_im, 0.0, d_im);

    // Smoothly fade to 0.0 as raw_w_im approaches the threshold
    float density_im = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_im);
    line_im *= density_im;

    base *= 1.0 + line_im * (is_imag_highlighted ? 0.8 : 0.3);
    if (is_imag_highlighted) {
        highlight_im_glow = line_im;
    }
}


void compute_multivalued_highlight(vec3 w_pos, inout vec3 final_emission) {
    // Highlight the branch cut portal area
    float dist_to_cut = abs(w_pos.z);
    bool in_cut = false;

    if (function_type == MULTIVALUED_ASIN || function_type == MULTIVALUED_ACOS) {
        float threshold = 10.0 * zoom_factor;
        if ((w_pos.x >= threshold && w_pos.x < threshold + portal_width) ||
            (w_pos.x <= -threshold && w_pos.x > -threshold - portal_width)) {
            in_cut = true;
        }
    } else {
        if (w_pos.x < 0.0 && w_pos.x > -portal_width) {
            in_cut = true;
        }
    }

    if (in_cut) {
        float cut_glow = 1.0 - smoothstep(0.0, 0.1 * zoom_factor, dist_to_cut);
        final_emission += vec3(0.0, 0.8, 1.0) * cut_glow * 0.4;
    }
}


void compute_critical_stripe_highlight(vec3 w_pos, vec3 nrm, inout vec3 final_emission, out float core_critical_out) {
    float zoom = zoom_factor;

    // Pulsing glow intensity
    float glow = 0.35 + 0.65 * (0.5 + 0.5 * sin(TIME * 2.0));

    // Thin analytic-looking core
    float line_width = 0.015 * zoom;

    // Slope correction
    float slope_scale = max(abs(nrm.y), 0.15);

    // Screen-space anti-aliasing
    float aa = fwidth(w_pos.x) * 1.5 / slope_scale;

    vec3 critical_color = vec3(1.0, 0.655, 0.0);
    vec3 boundary_color = vec3(1.0);

    // =========================================================
    // Critical line (Re = 0.5)
    // =========================================================

    float d_critical = abs(w_pos.x - 5.0 * zoom) / slope_scale;

    float core_critical =
        1.0 - smoothstep(
            line_width - aa,
            line_width + aa,
            d_critical
        );

    // Compact exponential glow
    float glow_critical =
        exp(-d_critical / (0.02 * zoom));

    // =========================================================
    // Left boundary (Re = 0)
    // =========================================================

    float d0 = abs(w_pos.x) / slope_scale;

    float core_0 =
        1.0 - smoothstep(
            line_width - aa,
            line_width + aa,
            d0
        );

    float glow_0 =
        exp(-d0 / (0.02 * zoom));

    // =========================================================
    // Right boundary (Re = 1)
    // =========================================================

    float d10 = abs(w_pos.x - 10.0 * zoom) / slope_scale;

    float core_10 =
        1.0 - smoothstep(
            line_width - aa,
            line_width + aa,
            d10
        );

    float glow_10 =
        exp(-d10 / (0.02 * zoom));

    // =========================================================
    // Final emission
    // =========================================================

    // Bright sharp core + animated compact glow

    final_emission += critical_color *
        (
            core_critical * 1.4 +
            glow_critical * glow * 0.9
        );

    final_emission += boundary_color *
        (
            core_0 * 1.1 +
            glow_0 * glow * 0.5
        );

    final_emission += boundary_color *
        (
            core_10 * 1.1 +
            glow_10 * glow * 0.5
        );

    core_critical_out = core_critical;
}


void compute_flow_effect(vec3 w_pos, vec3 nrm, vec3 camera_position_world, inout vec3 out_albedo, inout vec3 final_emission) {
    float dist_to_camera = length(w_pos - camera_position_world);
    float flow_fade = 1.0 - smoothstep(30.0, 80.0, dist_to_camera);

    if (flow_fade > 0.001) {
        float g_size = 0.75;
        vec2 cell_id = floor(w_pos.xz / g_size);
        vec2 grid_uv = fract(w_pos.xz / g_size) - 0.5;

        // Get gradient from normal (change the sign to change flow direction)
        vec2 grad = nrm.xz;
        float grad_mag = length(grad);

        if (grad_mag > 0.001) {
            vec2 dir = grad / grad_mag;

            float arrow_mask = 0.0;
            float pulse_intensity = 0.0;

            for (float dx = -1.0; dx <= 1.0; dx += 1.0) {
                for (float dy = -1.0; dy <= 1.0; dy += 1.0) {
                    vec2 offset = vec2(dx, dy);
                    vec2 local_grid_uv = grid_uv - offset;
                    vec2 cell_local = local_grid_uv * g_size;

                    // Rotate to align with gradient (pointing along +X)
                    vec2 p = vec2(cell_local.x * dir.x + cell_local.y * dir.y, -cell_local.x * dir.y + cell_local.y * dir.x);

                    float arrow_len = clamp(
                        grad_mag * g_size * 2.2,
                        0.3 * g_size,
                        0.85 * g_size
                    );
                    float thickness = 0.015 * g_size;
                    float head_size = arrow_len * 0.2;

                    float half_len = arrow_len * 0.5;
                    vec2 tip = vec2(half_len, 0.0);
                    vec2 head_base = vec2(half_len - head_size, 0.0);
                    vec2 tail = vec2(-half_len, 0.0);

                    // Body
                    float d_body = sdLine(p, tail, head_base);

                    // Triangle head
                    float d_head = sdTriangle(
                        p,
                        tip,
                        head_base + vec2(0.0,  head_size * 0.45),
                        head_base + vec2(0.0, -head_size * 0.45)
                    );

                    float d_arrow = min(d_body - thickness, d_head);

                    float cell_mask = 1.0 - smoothstep(0.0, thickness, d_arrow);

                    if (cell_mask > 0.0) {
                        float pulse_time = fract(TIME * 0.8);
                        float p_coord = (p.x / arrow_len) + 0.5; // 0 to 1
                        float cell_pulse = smoothstep(pulse_time - 0.3, pulse_time, p_coord) *
                                           smoothstep(pulse_time + 0.05, pulse_time, p_coord);

                        arrow_mask = max(arrow_mask, cell_mask);
                        pulse_intensity = max(pulse_intensity, cell_mask * cell_pulse);
                    }
                }
            }

            vec3 flow_color = vec3(1.0) * arrow_mask * (0.1 + 0.5 * pulse_intensity) * flow_fade;
            final_emission += flow_color * 0.5;
            out_albedo = mix(out_albedo, vec3(1.0), arrow_mask * 0.25 * flow_fade);
        }
    }
}


void compute_surface_texture_effect(vec3 w_pos, vec3 camera_position_world, inout vec3 nrm, out float roughness_variation) {
    roughness_variation = 0.0;
    vec3 scaled_world_pos = w_pos /  zoom_factor;

    float dist_to_camera = length(scaled_world_pos - camera_position_world);
    // Fade the texture effect beyond 50 units, reaching 0 at 100 units
    float fade = 1.0 - smoothstep(20.0, 100.0, dist_to_camera);
    fade = mix(0.15, 1.0, fade);

    if (fade > 0.001) {
        // High frequency for fine texture
        float freq = mix(2.0, 10.0, fade);
        vec3 noise_pos = scaled_world_pos * freq;
        float noise_val = fbm3(noise_pos);

        // Approximate tangent and bitangent based on the normal
        vec3 t = normalize(cross(nrm, vec3(0.0, 1.0, 0.0)));
        if (length(t) < 0.1) {
            t = normalize(cross(nrm, vec3(1.0, 0.0, 0.0)));
        }
        vec3 b = normalize(cross(nrm, t));

        // Derive normal perturbation by sampling nearby points
        float eps = 0.05;
        float nx = fbm3(noise_pos + t * eps) - noise_val;
        float nz = fbm3(noise_pos + b * eps) - noise_val;

        vec3 perturbed = normalize(
            nrm + vec3(nx, 0.0, nz) * surface_texture * fade * 2.0
        );

        nrm = perturbed;

        // Remap noise_val from [0, 1] to [-0.5, 0.5] for roughness
        roughness_variation = (noise_val - 0.5) * surface_texture * fade * 0.2;
    }
}


void compute_self_illumination_effect(vec3 w_pos, vec3 camera_position_world, vec3 out_albedo, inout vec3 final_emission) {
    // Position slightly below the camera
    vec3 light_pos = camera_position_world - vec3(0.0, 0.2 / zoom_factor, 0.0);

    float dist_to_camera = length(w_pos - light_pos) * 0.1;

    // Exponent decay
    float glow_factor = exp(-dist_to_camera);

    // Fog Transmittance
    if (fog_density > 0.0) {
        float actual_dist = length(w_pos - camera_position_world);
        float fog_transmittance = exp(-actual_dist * fog_density * 0.05);
        glow_factor *= fog_transmittance;
    }

    // Gentle pulsing
    float pulse = 1.0 + 0.03 * sin(TIME * 0.7);

    vec3 warm_glow = vec3(1.0, 0.88, 0.72) * self_illumination * glow_factor * pulse * 5.0;
    final_emission += out_albedo * warm_glow;
}


void compute_newton_path(vec3 w_pos, inout vec3 out_albedo, inout vec3 final_emission) {
    if (newton_path_size <= 0) return;

    vec2 pos_xz = w_pos.xz;
    float scale = clamp(0.5 / zoom_factor, 0.2, 0.5) * 2.0;

    // Expand bounding box a bit to account for line width and interpolation
    float expand = 2.0;
    float x_min = newton_path_bbox.x * 10.0 * zoom_factor - expand;
    float x_max = newton_path_bbox.y * 10.0 * zoom_factor + expand;
    float z_min = -newton_path_bbox.w * 10.0 * zoom_factor - expand;
    float z_max = -newton_path_bbox.z * 10.0 * zoom_factor + expand;

    float total_intensity = 0.0;

    if (pos_xz.x >= x_min && pos_xz.x <= x_max && pos_xz.y >= z_min && pos_xz.y <= z_max) {
        for (int i = 0; i < newton_path_size - 1; i++) {
            vec2 p1 = vec2(newton_path[i].x * 10.0 * zoom_factor, -newton_path[i].y * 10.0 * zoom_factor);
            vec2 p2 = vec2(newton_path[i+1].x * 10.0 * zoom_factor, -newton_path[i+1].y * 10.0 * zoom_factor);

            float seg_len = length(p2 - p1);
            if (seg_len < 0.0001) continue;

            float local_thickness = max(0.005 * scale, min(0.02 * scale, seg_len * 0.05));
            float d_seg = sdLine(pos_xz, p1, p2);
            float core = 1.0 - step(local_thickness, d_seg);
            float glow = (1.0 - smoothstep(local_thickness, local_thickness * 2.0, d_seg)) * 0.5;
            total_intensity = max(total_intensity, core + glow);

            // Add an arrow pointing from p1 to p2
            vec2 dir = (p2 - p1) / seg_len;
            vec2 perp = vec2(-dir.y, dir.x);
            vec2 mid = (p1 + p2) * 0.5;

            // Scale arrow size with zoom and local segment length
            float path_arrow_len = min(0.16 * scale, seg_len * 0.4);
            float path_arrow_width = min(0.08 * scale, seg_len * 0.2);
            float local_arr_thickness = max(0.005 * scale, min(0.02 * scale, path_arrow_len * 0.15));

            float d_arr = min(
                sdLine(pos_xz, mid + dir * path_arrow_len * 0.5, mid - dir * path_arrow_len * 0.5 + perp * path_arrow_width),
                sdLine(pos_xz, mid + dir * path_arrow_len * 0.5, mid - dir * path_arrow_len * 0.5 - perp * path_arrow_width)
            );

            float arr_core = 1.0 - step(local_arr_thickness, d_arr);
            float arr_glow = (1.0 - smoothstep(local_arr_thickness, local_arr_thickness * 2.0, d_arr)) * 0.5;
            total_intensity = max(total_intensity, arr_core + arr_glow);
        }
    }

    if (total_intensity > 0.0) {
        vec3 marker_color = vec3(0.4);
        out_albedo = mix(out_albedo, marker_color, clamp(total_intensity, 0.0, 1.0));
        final_emission += marker_color * total_intensity * 2.0; // Glow emission
    }
}

void compute_position_marker(vec3 w_pos, vec3 nrm, inout vec3 out_albedo, inout vec3 final_emission) {
    vec2 player_xz = player_position_world.xz;
    vec2 pos_xz = w_pos.xz;

    float scale = clamp(0.4 / zoom_factor, 0.2, 0.7);

    float length_arms = 0.6 * scale;
    float thickness = 0.02 * scale;
    float glow_thickness = 0.04 * scale;
    float dot_radius = 0.07 * scale;
    float arrow_len = 0.08 * scale;
    float arrow_width = 0.04 * scale;

    // Slope correction: on steep terrain the XZ footprint is larger than the
    // actual surface extent. Scaling sample coordinates by the normal's Y
    // component (cosine of slope angle) compensates, keeping the marker a
    // consistent shape regardless of incline.
    float slope_scale = max(abs(nrm.y), 0.15);
    vec2 rel = (pos_xz - player_xz) / slope_scale;
    vec2 origin = vec2(0.0);

    float d_line1 = sdLine(rel, origin, vec2(length_arms, 0.0));
    float d_line2 = sdLine(rel, origin, -vec2(0.0, length_arms));

    float d_cross = min(d_line1, d_line2);
    float d_dot = length(rel) - dot_radius;

    // Arrowheads at the tips of the cross arms
    vec2 tip_right = vec2(length_arms, 0.0);
    float d_arr_right = min(
        sdLine(rel, tip_right, tip_right - vec2(arrow_len, arrow_width)),
        sdLine(rel, tip_right, tip_right - vec2(arrow_len, -arrow_width))
    );

    vec2 tip_upward = -vec2(0.0, length_arms);
    float d_arr_upward = min(
        sdLine(rel, tip_upward, tip_upward + vec2(-arrow_width, arrow_len)),
        sdLine(rel, tip_upward, tip_upward + vec2(arrow_width, arrow_len))
    );

    float d_arrows = min(d_arr_right, d_arr_upward);
    float d_marker = min(min(d_cross, d_dot), d_arrows);

    if (d_marker < glow_thickness) {
        // Crisp core
        float core = 1.0 - step(thickness, d_marker);
        // Slight glow
        float glow = (1.0 - smoothstep(thickness, glow_thickness, d_marker)) * 0.5;

        vec3 marker_color = vec3(0.4);
        float intensity = core + glow;

        // Draw just above terrain means we just render it directly on the terrain surface.
        out_albedo = mix(out_albedo, marker_color, clamp(intensity, 0.0, 1.0));
        final_emission += marker_color * intensity * 2.0; // Glow emission
    }
}


void vertex() {
    vec3 local_pos = VERTEX;
    if (performance_protection_active) {
        VERTEX = local_pos;
        world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
        v_normal = vec3(0.0, 1.0, 0.0);
        NORMAL = (MODEL_NORMAL_MATRIX * v_normal);
        v_nan = 0.0;
        field_val = vec2(0.0);
    } else {
        float half_size = chunk_size * 0.5;
        vec3 snap_v = apply_lod_snapping(VERTEX, half_size);
        vec3 world_v_pos = (MODEL_MATRIX * vec4(snap_v, 1.0)).xyz;

        int branch_offset = 0;
        if (is_multivalued) {
            vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
            bool in_portal = false;
            branch_offset = calculate_branch_offset(world_v_pos, cam_pos, in_portal);
            world_v_pos = apply_branch_cut_perturbation(world_v_pos, cam_pos, in_portal);
        }

        ComplexFieldData final_fd = get_field_with_derivatives(world_v_pos.x, world_v_pos.z, branch_offset);

        bool is_invalid = any(isnan(final_fd.value)) || any(isinf(final_fd.value)) ||
                any(isnan(final_fd.dx)) || any(isinf(final_fd.dx)) ||
                any(isnan(final_fd.dy)) || any(isinf(final_fd.dy));

        if (is_invalid) {
            v_nan = 1.0;
            field_val = vec2(0.0);
            v_f_dir = vec2(0.0);
            v_normal = vec3(0.0, 1.0, 0.0);
            local_pos = vec3(snap_v.x, 0.0, snap_v.z);
            v_h_clamped = 0.0;
        } else {
            v_nan = 0.0;

            // Original function value f(z)
            vec2 fz = final_fd.value;

            // Identity map
            vec2 z_id = vec2(0.1 * world_v_pos.x, -0.1 * world_v_pos.z);

            float blend = 1.0;
            if (morph_style == 0) {
                blend = 1.0;
                field_val = fz;
            } else if (morph_style == 1) {
                blend = 0.5 - 0.5 * cos(PI * morph);
                field_val = mix(z_id, fz, blend);
            } else if (morph_style == 2) {
                blend = 0.5 - 0.5 * cos(PI * morph);
                vec2 exp_val = complex_exp(((fz - z_id) * blend).x, ((fz - z_id) * blend).y);
                field_val = complex_mul(z_id, exp_val);
            }

            if (length(field_val) > 0.0) {
                v_f_dir = normalize(field_val);
            } else {
                v_f_dir = vec2(0.0);
            }

            bool h_clamped = false;
            float h = get_complex_height(fz, field_val, h_clamped);
            v_h_clamped = h_clamped ? 1.0 : 0.0;

            h *= blend * zoom_factor;

            local_pos = vec3(snap_v.x, snap_v.y + h, snap_v.z);

            vec2 dh_d_world = get_complex_height_derivatives(fz, field_val, z_id, final_fd.dx, final_fd.dy, blend, h_clamped, morph_style);
            float dh_dx = dh_d_world.x;
            float dh_dz = dh_d_world.y;

            v_normal = normalize(vec3(-dh_dx, 1.0, -dh_dz));
        }

        VERTEX = local_pos;
        world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
        NORMAL = (MODEL_NORMAL_MATRIX * v_normal);
    }
}


void fragment() {
    // Get raw pixel derivatives unconditionally before any divergent branches
    float raw_w_re = fwidth(field_val.x);
    float raw_w_im = fwidth(field_val.y);

    if (performance_protection_active) {
        ALBEDO = vec3(0.01, 0.02, 0.03);
        ROUGHNESS = 1.0;
        METALLIC = 0.0;
    } else if (v_nan > 0.5) {
        vec3 local_albedo, local_emission;
        float rgh, mtl, spec;
        compute_matrix_effect(world_pos.xz, vec3(0.0, 0.8, 0.2), vec3(0.7, 1.0, 0.7), local_albedo, local_emission, rgh, mtl, spec);
        ALBEDO = local_albedo;
        EMISSION = local_emission;
        ROUGHNESS = rgh;
        METALLIC = mtl;
        SPECULAR = spec;
    } else {
        float x = world_pos.x;
        float z = world_pos.z;

        vec2 f = field_val;
        float phase;
        if (length(v_f_dir) > 0.0) {
            phase = atan(v_f_dir.y, v_f_dir.x);
        } else {
            phase = atan(f.y, f.x);
        }
        float hue = (phase + PI) / (2.0 * PI);
        if (color_scheme == 1) {
            hue = fract(hue + 0.5);
        }

        // Anti-alias high-frequency phase oscillation (Moiré suppression)
        float f_mag = length(f);
        float phase_change = length(vec2(raw_w_re, raw_w_im)) / (f_mag + 1e-12);
        float moire_suppression = smoothstep(0.5, 3.0, phase_change);

        float eff_sat = mix(saturation, 0.0, moire_suppression * 0.8);
        float eff_bri = mix(brightness, brightness * 0.5, moire_suppression * 0.5);

        vec3 base = hsv2rgb(vec3(hue, eff_sat, eff_bri));
        float highlight_re_glow = 0.0;
        float highlight_im_glow = 0.0;

        if (color_scheme == 2) {
            float v = 0.5 + 0.5 * cos(phase);
            // Suppress the Moiré in grayscale by washing it towards a solid gray 0.5
            v = mix(v, 0.5, moire_suppression);
            base = vec3(v) * eff_bri;
        }

        // Apply smooth decay for large heights, just like minimap
        float h_abs = abs(world_pos.y);
        float fade_factor = 1.0;
        if (v_h_clamped > 0.5) {
            fade_factor = 0.3;
        } else if (h_abs > max_world_height) {
            float excess = h_abs - max_world_height;
            float decay_rate = 0.0005;
            float exp_fade = exp(-decay_rate * excess);
            fade_factor = 0.3 + 0.7 * exp_fade;
        }
        base *= fade_factor;

        if (show_curves) {
            compute_curves_highlight(f, raw_w_re, raw_w_im, base, highlight_re_glow, highlight_im_glow);
        }

        ALBEDO = base * albedo;
        vec3 final_emission = base * emission;
        if (show_curves) {
            final_emission += vec3(0.0, 0.6, 1.0) * highlight_re_glow * 0.8;
            final_emission += vec3(1.0, 0.0, 0.549) * highlight_im_glow * 0.8;
        }

        if (is_multivalued) {
            compute_multivalued_highlight(world_pos, final_emission);
        }

        float core_critical = 0.0;
        if (show_critical_stripe && is_dirichlect) {
            compute_critical_stripe_highlight(world_pos, v_normal, final_emission, core_critical);
            ALBEDO = mix(ALBEDO, vec3(1.0, 0.655, 0.0), core_critical);
        }

        if (show_flow) {
            compute_flow_effect(world_pos, v_normal, CAMERA_POSITION_WORLD, ALBEDO, final_emission);
        }

        float roughness_variation = 0.0;
        if (surface_texture > 0.0) {
            compute_surface_texture_effect(world_pos, CAMERA_POSITION_WORLD, NORMAL, roughness_variation);
        }

        if (self_illumination > 0.0 && !performance_protection_active) {
            compute_self_illumination_effect(world_pos, CAMERA_POSITION_WORLD, ALBEDO, final_emission);
        }

        if (show_position_marker) {
            compute_position_marker(world_pos, v_normal, ALBEDO, final_emission);
        }

        compute_newton_path(world_pos, ALBEDO, final_emission);

        // Reinhard Tone Mapping to keep high emissions from blowing out to absolute white
        final_emission = final_emission / (final_emission + vec3(1.0));

        EMISSION = final_emission;

        ROUGHNESS = mix(clamp(roughness + roughness_variation, 0.0, 1.0), 0.1, core_critical);
        METALLIC = mix(metallic, 0.8, core_critical);
        SPECULAR = specular_intensity;
    }
}

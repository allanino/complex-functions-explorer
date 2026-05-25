shader_type spatial;

#include "res://shaders/field.gdshaderinc"

varying vec3 world_pos;
varying vec3 v_normal;
varying vec2 field_val;
varying float v_nan;

instance uniform int lod_level = 0;
instance uniform int neighbor_lod_left = -1;
instance uniform int neighbor_lod_right = -1;
instance uniform int neighbor_lod_top = -1;
instance uniform int neighbor_lod_bottom = -1;

uniform float lod_segments[6];
uniform float chunk_size;

uniform int color_scheme = 0;
uniform bool show_curves = true;
uniform bool show_critical_stripe = true;
uniform bool show_flow = false;

uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.3, 1.0) = 0.85;
uniform float albedo : hint_range(0.0, 1.0) = 0.15;
uniform float emission : hint_range(0.0, 1.0) = 0.1;
uniform float metallic : hint_range(0.0, 1.0) = 0.7;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform float surface_texture : hint_range(0.0, 1.0) = 0.0;
uniform float morph : hint_range(0.0, 1.0) = 1.0;
uniform float portal_height = 50.0;
uniform float portal_width = 100.0;
uniform float self_illumination = 0.0;
uniform float time = 0.0;

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
        float eps = 0.01;

        bool on_left = VERTEX.x < -half_size + eps;
        bool on_right = VERTEX.x > half_size - eps;
        bool on_top = VERTEX.z < -half_size + eps;
        bool on_bottom = VERTEX.z > half_size - eps;

        int n_lod = -1;
        bool horizontal_edge = false; // edge along X (Top/Bottom)

        if (on_left && neighbor_lod_left > lod_level) {
            n_lod = neighbor_lod_left;
            horizontal_edge = false;
        } else if (on_right && neighbor_lod_right > lod_level) {
            n_lod = neighbor_lod_right;
            horizontal_edge = false;
        } else if (on_top && neighbor_lod_top > lod_level) {
            n_lod = neighbor_lod_top;
            horizontal_edge = true;
        } else if (on_bottom && neighbor_lod_bottom > lod_level) {
            n_lod = neighbor_lod_bottom;
            horizontal_edge = true;
        }

        vec3 snap_v = VERTEX;
        if (n_lod != -1) {
            float segments = lod_segments[n_lod];
            float s = chunk_size / segments;
            if (horizontal_edge) {
                float t = (VERTEX.x + half_size) / s;
                snap_v.x = floor(t + 0.5) * s - half_size;
            } else {
                float t = (VERTEX.z + half_size) / s;
                snap_v.z = floor(t + 0.5) * s - half_size;
            }
        }

        vec3 world_v_pos = (MODEL_MATRIX * vec4(snap_v, 1.0)).xyz;

        int branch_offset = 0;
        if (is_multivalued && multivalued_mode == 1) {
            vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
            if (cam_pos.z * world_v_pos.z < 0.0) {
                float r = cam_pos.z / (cam_pos.z - world_v_pos.z);
                float px = cam_pos.x + r * (world_v_pos.x - cam_pos.x);
                float py = cam_pos.y + r * (world_v_pos.y - cam_pos.y);
                // Portal is at z=0, 0 < x < portal_width, with dynamic height py < portal_height
                if (px > 0.0 && px < portal_width && py > -10.0 && py < portal_height) {
                    branch_offset = (cam_pos.z > 0.0) ? 1 : -1;
                }
            }
        }

        FieldData final_fd = get_field_with_derivatives(world_v_pos.x, world_v_pos.z, branch_offset);

        bool is_invalid = any(isnan(final_fd.value)) || any(isinf(final_fd.value)) ||
                        any(isnan(final_fd.d_sigma)) || any(isinf(final_fd.d_sigma)) ||
                        any(isnan(final_fd.d_t)) || any(isinf(final_fd.d_t));

        if (is_invalid) {
            v_nan = 1.0;
            field_val = vec2(0.0);
            v_normal = vec3(0.0, 1.0, 0.0);
            local_pos = vec3(snap_v.x, 0.0, snap_v.z);
        } else {
            v_nan = 0.0;
            
            // Here we have some code to allow the morphing terrain
            // feature. We can use final_fd directly if we want
            // to remove this feature later on. 
 
            // When running usually, morph = 1.0, s = 1.0, blend = 1.0

            // Blend parameter in [0, 1]
            float s = 0.5 - 0.5 * cos(PI * morph);
            float blend = log(1.0 + 8.0 * s) / log(9.0);

            // Original function value f(z)
            vec2 fz = final_fd.value;

            // Identity map
            vec2 z_id = vec2(world_v_pos.x, world_v_pos.z);

            // Blended map:
            // g(z, blend) = (1 - blend) * z + blend * f(z)
            field_val = mix(z_id, fz, blend);

            float mag = length(fz);
            float h = 0.0;

            if (height_type == 0) {
                h = height_a * log(height_epsilon + mag);
            } else {
                h = mag;
            }

            h *= blend;

            local_pos = vec3(snap_v.x, snap_v.y + h, snap_v.z);

            float u = field_val.x;
            float v = field_val.y;

            // Derivatives of f(z)
            vec2 df_dsigma = final_fd.d_sigma; // (du/dsigma, dv/dsigma)
            vec2 df_dt     = final_fd.d_t;     // (du/dt, dv/dt)

            // Derivatives of identity map z = sigma + i t
            vec2 dz_dsigma = vec2(1.0, 0.0);
            vec2 dz_dt     = vec2(0.0, 1.0);

            // Chain rule for g = (1-blend) z + blend f(z)
            vec2 dg_dsigma = (1.0 - blend) * dz_dsigma + blend * df_dsigma;
            vec2 dg_dt     = (1.0 - blend) * dz_dt     + blend * df_dt;

            // Convert from (sigma, t) derivatives to world (x, z) derivatives
            // sigma = 0.1 * x * (1/zoom)
            // t     = -0.1 * z * (1/zoom)
            float zoom = 1.0 / zoom_factor;
            float d_sigma_dx = 0.1 * zoom;
            float d_t_dx     = 0.0;
            float d_sigma_dz = 0.0;
            float d_t_dz     = -0.1 * zoom;

            float du_dx = dg_dsigma.x * d_sigma_dx + dg_dt.x * d_t_dx;
            float dv_dx = dg_dsigma.y * d_sigma_dx + dg_dt.y * d_t_dx;

            float du_dz = dg_dsigma.x * d_sigma_dz + dg_dt.x * d_t_dz;
            float dv_dz = dg_dsigma.y * d_sigma_dz + dg_dt.y * d_t_dz;

            float safe_mag = max(mag, 1e-12);
            float dmag_dx = (u * du_dx + v * dv_dx) / safe_mag;
            float dmag_dz = (u * du_dz + v * dv_dz) / safe_mag;

            float dh_dx = (height_type == 0) ? (height_a / (height_epsilon + mag)) * dmag_dx : dmag_dx;
            float dh_dz = (height_type == 0) ? (height_a / (height_epsilon + mag)) * dmag_dz : dmag_dz;

            v_normal = normalize(vec3(-dh_dx, 1.0, -dh_dz));
        }

        VERTEX = local_pos;
        world_pos = (MODEL_MATRIX * vec4(local_pos, 1.0)).xyz;
        NORMAL = (MODEL_NORMAL_MATRIX * v_normal);
    }
}

void fragment() {
    if (performance_protection_active) {
        ALBEDO = vec3(0.01, 0.02, 0.03);
        ROUGHNESS = 1.0;
        METALLIC = 0.0;
    } else if (v_nan > 0.5) {
        ALBEDO = vec3(0.0);

        // Matrix Effect
        vec2 grid = world_pos.xz * 5.0;
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

        vec3 matrix_color = vec3(0.0, 0.8, 0.2);

        // Glowy head of the trail
        if (trail > 2.0) {
            matrix_color = vec3(0.7, 1.0, 0.7);
        }

        EMISSION = matrix_color * trail * char_shape * char_vis;
        ROUGHNESS = 1.0;
        METALLIC = 0.0;
        SPECULAR = 0.0;
    } else {
        float x = world_pos.x;
        float z = world_pos.z;
        
        vec2 f = field_val;
        float phase = atan(f.y, f.x);
        float hue = (phase + PI) / (2.0 * PI);
        if (color_scheme == 1) {
            hue = fract(hue + 0.5);
        }
        vec3 base = hsv2rgb(vec3(hue, saturation, brightness));

        if (show_curves) {
            // 1. Get raw pixel derivatives (true density indicators)
            float raw_w_re = fwidth(f.x);
            float raw_w_im = fwidth(f.y);

            // 2. Define a density threshold where curves should completely disappear.
            // Adjust this value: lower means it fades out sooner/farther away.
            float max_density_threshold = 0.2; 

            // 3. Compute contour lines using your padded width for rendering stability
            float d_re = abs(f.x - round(f.x));
            float w_re = clamp(raw_w_re, 0.000005, 0.001) + 0.02;
            float line_re = smoothstep(w_re, 0.0, d_re);

            // Smoothly fade to 0.0 as raw_w_re approaches the threshold
            float density_re = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_re);
            line_re *= density_re;

            base *= 1.0 - line_re * 0.3;

            // 4. Compute contour lines for f.y
            float d_im = abs(f.y - round(f.y));
            float w_im = clamp(raw_w_im, 0.000005, 0.001) + 0.02;
            float line_im = smoothstep(w_im, 0.0, d_im);

            // Smoothly fade to 0.0 as raw_w_im approaches the threshold
            float density_im = smoothstep(max_density_threshold, max_density_threshold * 0.7, raw_w_im);
            line_im *= density_im;

            base *= 1.0 + line_im * 0.3; 
        }


        ALBEDO = base * albedo;
        vec3 final_emission = base * emission;

        if (is_multivalued && multivalued_mode == 1) {
            // Highlight the branch cut portal area
            float dist_to_cut = abs(world_pos.z);
            if (world_pos.x > 0.0 && world_pos.x < portal_width) {
                float cut_glow = 1.0 - smoothstep(0.0, 0.1 * zoom_factor, dist_to_cut);
                final_emission += vec3(0.0, 0.8, 1.0) * cut_glow * 0.4;
            }
        }

        // Only apply the lines rendering for zeta (at x = 0, x = 5.0, x = 10.0)
        // which corresponds to Re = 0.0, Re = 0.5, Re = 1.0
        if (show_critical_stripe && is_dirichlect) {
            float zoom = zoom_factor;
            // Periodic glow factor
            float glow = 0.5 + 0.5 * sin(TIME * 2.0);
            float line_width = 0.05 * zoom;

            // Critical line at x = 5.0 * zoom (HUD x = 0.5)
            float dist_to_critical = abs(world_pos.x - 5.0 * zoom);
            float core_critical = 1.0 - smoothstep(0.0, line_width, dist_to_critical);
            float glow_critical = 1.0 - smoothstep(0.0, 0.1 * zoom, dist_to_critical);
            vec3 line_color = vec3(1.0, 1.0, 0.0); // Yellow

            // Critical stripe boundaries at x = 0.0 and x = 10.0 * zoom
            float dist_to_0 = abs(world_pos.x - 0.0);
            float core_0 = 1.0 - smoothstep(0.0, line_width, dist_to_0);
            float glow_0 = 1.0 - smoothstep(0.0, 0.1 * zoom, dist_to_0);

            float dist_to_10 = abs(world_pos.x - 10.0 * zoom);
            float core_10 = 1.0 - smoothstep(0.0, line_width, dist_to_10);
            float glow_10 = 1.0 - smoothstep(0.0, 0.1 * zoom, dist_to_10);

            vec3 white_line_color = vec3(1.0, 1.0, 1.0);

            // Combine core (sharp, steady) and glow (wide, oscillating) using additive blending
            // to prevent dark shadows when glow is low.
            final_emission += line_color * (core_critical * 0.5 + glow_critical * glow * 1.0);
            final_emission += white_line_color * (core_0 * 0.5 + glow_0 * glow * 1.0);
            final_emission += white_line_color * (core_10 * 0.5 + glow_10 * glow * 1.0);
        }

        if (show_flow) {
            float g_size = 1.25;
            vec2 cell_id = floor(world_pos.xz / g_size);
            vec2 grid_uv = fract(world_pos.xz / g_size) - 0.5;

            // Get gradient from normal (change the sign to change flow direction)
            vec2 grad = v_normal.xz;
            float grad_mag = length(grad);

            if (grad_mag > 0.001) {
                vec2 dir = grad / grad_mag;

                // Rotate grid_uv to align with gradient (pointing along +X)
                vec2 p = vec2(grid_uv.x * dir.x + grid_uv.y * dir.y, -grid_uv.x * dir.y + grid_uv.y * dir.x);

                float arrow_len = clamp(grad_mag * g_size * 2.0, 0.1 * g_size, 0.7 * g_size);
                float thickness = 0.02 * g_size;

                // Body
                float d_body = sdLine(p, vec2(-arrow_len * 0.5, 0.0), vec2(arrow_len * 0.5, 0.0));

                // Head
                vec2 head_base = vec2(arrow_len * 0.5, 0.0);
                float head_size = clamp(arrow_len * 0.2, 0.0075 * g_size, 0.1 * g_size);
                float d_head = sdLine(p, head_base, head_base + vec2(-head_size, head_size * 0.6));
                d_head = min(d_head, sdLine(p, head_base, head_base + vec2(-head_size, -head_size * 0.6)));

                float arrow_dist = min(d_body, d_head);
                float arrow_mask = smoothstep(thickness, thickness * 0.5, arrow_dist);

                // Pulse emission: sync across all arrows
                float pulse_time = fract(TIME * 1.2);
                float p_coord = (p.x / arrow_len) + 0.5; // 0 (tail) to 1 (tip)
                float pulse = smoothstep(pulse_time - 0.3, pulse_time, p_coord) * smoothstep(pulse_time + 0.05, pulse_time, p_coord);

                vec3 flow_color = vec3(1.0) * arrow_mask * (0.1 + 0.9 * pulse);
                final_emission += flow_color * 0.5;
                ALBEDO = mix(ALBEDO, vec3(1.0), arrow_mask * 0.15);
            }
        }

        // Procedural micro-normal perturbation and roughness variation
        float noise_val = 0.0;
        float roughness_variation = 0.0;
        if (surface_texture > 0.0) {
            vec3 scaled_world_pos = world_pos /  zoom_factor;

            float dist_to_camera = length(scaled_world_pos - CAMERA_POSITION_WORLD);
            // Fade the texture effect beyond 50 units, reaching 0 at 100 units
            float fade = 1.0 - smoothstep(20.0, 100.0, dist_to_camera);
            fade = mix(0.15, 1.0, fade);


            if (fade > 0.001) {
                // High frequency for fine texture
                float freq = mix(2.0, 10.0, fade);
                vec3 noise_pos = scaled_world_pos * freq;
                noise_val = fbm3(noise_pos);

                // Approximate tangent and bitangent based on the normal
                vec3 t = normalize(cross(v_normal, vec3(0.0, 1.0, 0.0)));
                if (length(t) < 0.1) {
                    t = normalize(cross(v_normal, vec3(1.0, 0.0, 0.0)));
                }
                vec3 b = normalize(cross(v_normal, t));

                // Derive normal perturbation by sampling nearby points
                float eps = 0.05;
                float nx = fbm3(noise_pos + t * eps) - noise_val;
                float nz = fbm3(noise_pos + b * eps) - noise_val;

                /* vec3 normal_offset = (t * nx + b * nz) * surface_texture * fade * 2.0; */
                vec3 perturbed = normalize(
                    NORMAL + vec3(nx, 0.0, nz) * surface_texture * fade * 2.0
                );

                NORMAL = perturbed;

                // Remap noise_val from [0, 1] to [-0.5, 0.5] for roughness
                roughness_variation = (noise_val - 0.5) * surface_texture * fade * 0.2;
            }
        }

        // Reinhard Tone Mapping to keep high emissions from blowing out to absolute white
        final_emission = final_emission / (final_emission + vec3(1.0));

        EMISSION = final_emission;
    // Self-Illumination Glow around camera
    if (self_illumination > 0.0 && !performance_protection_active) {
        float dist_to_camera = length(world_pos - CAMERA_POSITION_WORLD);
        float scaled_dist = dist_to_camera / (10.0 * zoom_factor);

        // Exponent decay
        float glow_factor = exp(-scaled_dist);

        // Gentle pulsing
        float pulse = 1.0 + 0.03 * sin(time * 0.7);

        vec3 warm_glow = vec3(1.0, 0.88, 0.72) * self_illumination * glow_factor * pulse;
        EMISSION += warm_glow;
    }

        ROUGHNESS = clamp(roughness + roughness_variation, 0.0, 1.0);
        METALLIC = metallic;
        SPECULAR = 0.1;
    }
}

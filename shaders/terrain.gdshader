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
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.1;

uniform float self_illumination = 0.0;
uniform float fog_density = 0.0;


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
        if (is_multivalued) {
            vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
            bool in_portal = false;
            if (cam_pos.z * world_v_pos.z < 0.0 || (cam_pos.z != 0.0 && world_v_pos.z == 0.0)) {
                float denom = cam_pos.z - world_v_pos.z;
                if (denom == 0.0) {
                    denom = 1e-9;
                }
                float r = cam_pos.z / denom;
                float px = cam_pos.x + r * (world_v_pos.x - cam_pos.x);
                float py = cam_pos.y + r * (world_v_pos.y - cam_pos.y);

                if (function_type == 18 || function_type == 19) {
                    float threshold = 10.0 * zoom_factor;
                    if ((px >= threshold && px < threshold + portal_width) ||
                        (px <= -threshold && px > -threshold - portal_width)) {
                        if (py > -10.0 && py < portal_height) {
                            in_portal = true;
                        }
                    }
                } else {
                    if (px < 0.0 && px > -portal_width && py > -10.0 && py < portal_height) {
                        in_portal = true;
                    }
                }

                if (in_portal) {
                    if (function_type == 18 || function_type == 19) { // ASIN or ACOS
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
        }

        FieldData final_fd = get_field_with_derivatives(world_v_pos.x, world_v_pos.z, branch_offset);

        bool is_invalid = any(isnan(final_fd.value)) || any(isinf(final_fd.value)) ||
                any(isnan(final_fd.dx)) || any(isinf(final_fd.dx)) ||
                any(isnan(final_fd.dy)) || any(isinf(final_fd.dy));

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
            float blend = 0.5 - 0.5 * cos(PI * morph);

            // Original function value f(z)
            vec2 fz = final_fd.value;

            // Identity map
            vec2 z_id = vec2(0.1 * world_v_pos.x, -0.1 * world_v_pos.z);

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

            h *= blend * zoom_factor;

            local_pos = vec3(snap_v.x, snap_v.y + h, snap_v.z);

            float u = field_val.x;
            float v = field_val.y;

            // Derivatives of f(z)
            vec2 df_dx = final_fd.dx; // (du/dx, dv/dx)
            vec2 df_dy = final_fd.dy;     // (du/dy, dv/dy)

            // Derivatives of identity map z = x + i y
            vec2 dz_dx = vec2(1.0, 0.0);
            vec2 dz_dy = vec2(0.0, 1.0);

            // Chain rule for g = (1-blend) z + blend f(z)
            vec2 dg_dx = (1.0 - blend) * dz_dx + blend * df_dx;
            vec2 dg_dy = (1.0 - blend) * dz_dy + blend * df_dy;

            // Convert from (x, y) derivatives to world (wx, wz) derivatives
            // x = 0.1 * wx * (1/zoom)
            // y     = -0.1 * wz * (1/zoom)
            // Since we scale the final height h by zoom_factor, the zoom_factor cancels out
            // of the dh_dx and dh_dz derivatives entirely.
            float dx_d_wx = 0.1;
            float dy_d_wx = 0.0;
            float dx_d_wz = 0.0;
            float dy_d_wz = -0.1;

            float du_dx = dg_dx.x * dx_d_wx + dg_dy.x * dy_d_wx;
            float dv_dx = dg_dx.y * dx_d_wx + dg_dy.y * dy_d_wx;

            float du_dz = dg_dx.x * dx_d_wz + dg_dy.x * dy_d_wz;
            float dv_dz = dg_dx.y * dx_d_wz + dg_dy.y * dy_d_wz;

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

        if (is_multivalued) {
            // Highlight the branch cut portal area
            float dist_to_cut = abs(world_pos.z);
            bool in_cut = false;

            if (function_type == 18 || function_type == 19) {
                float threshold = 10.0 * zoom_factor;
                if ((world_pos.x >= threshold && world_pos.x < threshold + portal_width) ||
                    (world_pos.x <= -threshold && world_pos.x > -threshold - portal_width)) {
                    in_cut = true;
                }
            } else {
                if (world_pos.x < 0.0 && world_pos.x > -portal_width) {
                    in_cut = true;
                }
            }

            if (in_cut) {
                float cut_glow = 1.0 - smoothstep(0.0, 0.1 * zoom_factor, dist_to_cut);
                final_emission += vec3(0.0, 0.8, 1.0) * cut_glow * 0.4;
            }
        }

        // Only apply the lines rendering for zeta (at x = 0, x = 5.0, x = 10.0)
        // which corresponds to Re = 0.0, Re = 0.5, Re = 1.0
        if (show_critical_stripe && is_dirichlect) {

            float zoom = zoom_factor;

            // Pulsing glow intensity
            float glow = 0.35 + 0.65 * (0.5 + 0.5 * sin(TIME * 2.0));

            // Thin analytic-looking core
            float line_width = 0.015 * zoom;

            // Screen-space anti-aliasing
            float aa = fwidth(world_pos.x) * 1.5;

            vec3 critical_color = vec3(0.9, 0.9, 0.0);
            vec3 boundary_color = vec3(1.0);

            // =========================================================
            // Critical line (Re = 0.5)
            // =========================================================

            float d_critical = abs(world_pos.x - 5.0 * zoom);

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

            float d0 = abs(world_pos.x);

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

            float d10 = abs(world_pos.x - 10.0 * zoom);

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

        // Self-Illumination Glow around camera
        if (self_illumination > 0.0 && !performance_protection_active) {
            // Position slightly below the camera
            vec3 light_pos = CAMERA_POSITION_WORLD - vec3(0.0, 0.2 / zoom_factor, 0.0);

            float dist_to_camera = length(world_pos - light_pos) * 0.1;

            // Exponent decay
            float glow_factor = exp(-dist_to_camera);

            // Fog Transmittance
            if (fog_density > 0.0) {
                float actual_dist = length(world_pos - CAMERA_POSITION_WORLD);
                float fog_transmittance = exp(-actual_dist * fog_density * 0.05);
                glow_factor *= fog_transmittance;
            }

            // Gentle pulsing
            float pulse = 1.0 + 0.03 * sin(TIME * 0.7);

            vec3 warm_glow = vec3(1.0, 0.88, 0.72) * self_illumination * glow_factor * pulse * 5.0;
            final_emission += ALBEDO * warm_glow;
        }

        // Reinhard Tone Mapping to keep high emissions from blowing out to absolute white
        final_emission = final_emission / (final_emission + vec3(1.0));

        EMISSION = final_emission;

        ROUGHNESS = clamp(roughness + roughness_variation, 0.0, 1.0);
        METALLIC = metallic;
        SPECULAR = specular_intensity;
    }
}

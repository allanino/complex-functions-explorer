shader_type canvas_item;

#include "res://math/glsl/color_utils.gdshaderinc"

uniform vec3 current_point = vec3(0.0, -1.0, 0.0);
uniform bool has_valid_point = true;

uniform vec3 trail[32];
uniform int trail_count = 0;

uniform float cam_yaw = 0.55;
uniform float cam_pitch = 0.36;

uniform int color_scheme = 0;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float saturation : hint_range(0.3, 1.0) = 0.85;
uniform float albedo : hint_range(0.0, 1.0) = 0.15;
uniform float emission : hint_range(0.0, 1.0) = 0.1;

// Shortest distance from ray (ro + t * rd, t >= 0) to 3D line segment [a, b],
// also returning the ray parameter t_ray at closest approach.
float ray_segment_distance(vec3 ro, vec3 rd, vec3 a, vec3 b, out float t_ray) {
	vec3 u = rd;
	vec3 v = b - a;
	vec3 w = ro - a;
	float a_dot = dot(u, u);
	float b_dot = dot(u, v);
	float c_dot = dot(v, v);
	float d_dot = dot(u, w);
	float e_dot = dot(v, w);
	float denom = a_dot * c_dot - b_dot * b_dot;

	float s_c;
	float t_c;
	if (denom < 1e-6) {
		s_c = 0.0;
		t_c = clamp(e_dot / max(c_dot, 1e-6), 0.0, 1.0);
	} else {
		s_c = (b_dot * e_dot - c_dot * d_dot) / denom;
		t_c = (a_dot * e_dot - b_dot * d_dot) / denom;
		if (t_c < 0.0) {
			t_c = 0.0;
			s_c = -d_dot / a_dot;
		} else if (t_c > 1.0) {
			t_c = 1.0;
			s_c = (b_dot - d_dot) / a_dot;
		}
	}
	t_ray = max(s_c, 0.0);
	vec3 p_ray = ro + u * t_ray;
	vec3 p_seg = a + v * t_c;
	return length(p_ray - p_seg);
}

// Phase color matching terrain.gdshader and phase_wheel.gdshader.
vec3 phase_to_color(float phase) {
	float hue = (phase + PI) / (2.0 * PI);
	if (color_scheme == 1) {
		hue = fract(hue + 0.5);
	}
	vec3 base = hsv2rgb(vec3(hue, saturation, brightness));
	if (color_scheme == 2) {
		float v = 0.5 + 0.5 * cos(phase);
		base = vec3(v) * brightness;
	}
	return base;
}

// Evaluates the surface color and alpha at unit point p on the target Riemann sphere.
// Convention: (0, +1, 0) = infinity, (0, -1, 0) = 0, (1, 0, 0) = +1, (0, 0, -1) = +i.
vec4 shade_sphere_point(vec3 p, vec3 rd, bool is_front, float px_size) {
	float phase = atan(-p.z, p.x);
	vec3 p_col = phase_to_color(phase);

	// Latitude tinting: dark near 0 (south pole), vivid on |w|=1 (equator), pale near infinity (north pole).
	float lat = p.y; // [-1, 1]
	float eq_band = exp(-lat * lat * 3.5);
	vec3 south_tint = vec3(0.03, 0.05, 0.10);
	vec3 north_tint = vec3(0.85, 0.87, 0.92);
	vec3 surface_col = p_col * (0.45 + 0.55 * eq_band);
	surface_col = mix(surface_col, south_tint, smoothstep(0.0, -0.92, lat) * 0.65);
	surface_col = mix(surface_col, north_tint, smoothstep(0.0, 0.92, lat) * 0.55);

	// Subtle directional lighting + Fresnel rim on the front hemisphere.
	vec3 n = is_front ? p : -p;
	vec3 light_dir = normalize(vec3(0.55, 0.75, 0.45));
	float ndl = max(dot(n, light_dir), 0.0);
	float ndv = abs(dot(p, -rd));
	float fresnel = pow(1.0 - ndv, 2.6);

	float base_alpha = is_front ? (0.16 + 0.24 * fresnel) : 0.08;
	vec3 col = surface_col * (0.55 + 0.45 * ndl);

	// Specular glass highlight on front hemisphere
	if (is_front) {
		vec3 half_vec = normalize(light_dir - rd);
		float spec = pow(max(dot(n, half_vec), 0.0), 48.0);
		col += vec3(0.95, 0.96, 1.0) * spec * 0.35;
	}

	float alpha = base_alpha;

	// --- Graticule: Equator, Parallels, Meridians ---
	vec3 gold_dim = vec3(0.784, 0.663, 0.431);
	vec3 gold_bright = vec3(1.0, 0.86, 0.45);
	float aa = max(px_size * 1.4, 0.006);

	// Equator (|w| = 1, p.y = 0) with phase-colored glow
	float d_eq = abs(p.y);
	float eq_mask = 1.0 - smoothstep(0.012, 0.012 + aa * 1.3, d_eq);
	vec3 eq_color = mix(p_col * 1.15, gold_bright, 0.22);
	col = mix(col, eq_color, eq_mask * (is_front ? 0.90 : 0.35));
	alpha = max(alpha, eq_mask * (is_front ? 0.82 : 0.28));

	// Parallels at |w| = 0.5 (y = -0.6) and |w| = 2.0 (y = +0.6)
	float d_par = min(abs(p.y - 0.6), abs(p.y + 0.6));
	float par_mask = 1.0 - smoothstep(0.005, 0.005 + aa, d_par);
	col = mix(col, gold_dim, par_mask * (is_front ? 0.42 : 0.18));
	alpha = max(alpha, par_mask * (is_front ? 0.36 : 0.14));

	// Meridians every 45 deg (cardinal axes slightly stronger)
	float rho = length(p.xz);
	if (rho > 0.02) {
		float step_ang = PI * 0.25;
		float nearest_mer = round(phase / step_ang) * step_ang;
		float ang_diff = abs(phase - nearest_mer);
		// Arc distance on the sphere scales with rho = cos(latitude)
		float d_mer = ang_diff * rho;
		bool is_cardinal = mod(abs(round(phase / step_ang)), 2.0) < 0.5;
		float w_mer = is_cardinal ? 0.008 : 0.0045;
		float mer_mask = 1.0 - smoothstep(w_mer, w_mer + aa, d_mer);
		float mer_str = is_cardinal ? (is_front ? 0.52 : 0.20) : (is_front ? 0.28 : 0.10);
		col = mix(col, is_cardinal ? gold_bright : gold_dim, mer_mask * mer_str);
		alpha = max(alpha, mer_mask * mer_str * 0.85);
	}

	// Pole markers: North (infinity) and South (0)
	float d_north = length(p - vec3(0.0, 1.0, 0.0));
	float north_ring = 1.0 - smoothstep(0.032, 0.032 + aa, abs(d_north - 0.055));
	float north_dot = 1.0 - smoothstep(0.028, 0.028 + aa, d_north);
	float north_vis = max(north_dot, north_ring * 0.7) * (is_front ? 0.9 : 0.35);
	col = mix(col, vec3(0.98, 0.96, 0.90), north_vis);
	alpha = max(alpha, north_vis);

	float d_south = length(p - vec3(0.0, -1.0, 0.0));
	float south_ring = 1.0 - smoothstep(0.016, 0.016 + aa, abs(d_south - 0.055));
	float south_dot = 1.0 - smoothstep(0.030, 0.030 + aa, d_south);
	float south_vis = south_ring * (is_front ? 0.85 : 0.35);
	col = mix(col, vec3(0.05, 0.07, 0.12), south_dot * (is_front ? 0.85 : 0.35));
	col = mix(col, gold_dim, south_vis);
	alpha = max(alpha, max(south_vis, south_dot * (is_front ? 0.75 : 0.25)));

	// --- Trail on sphere surface ---
	if (trail_count >= 2) {
		float trail_mask = 0.0;
		float trail_age = 0.0;
		int segs = min(trail_count - 1, 31);
		for (int i = 0; i < segs; i++) {
			vec3 a = trail[i];
			vec3 b = trail[i + 1];
			vec3 ab = b - a;
			float ab_len2 = dot(ab, ab);
			if (ab_len2 < 1e-6 || ab_len2 > 2.0) {
				continue;
			}
			float t = clamp(dot(p - a, ab) / ab_len2, 0.0, 1.0);
			vec3 closest = normalize(mix(a, b, t));
			float d = length(p - closest);
			float progress = (float(i) + t) / float(segs);
			float w = mix(0.006, 0.020, progress);
			float m = (1.0 - smoothstep(w, w + aa * 1.1, d)) * smoothstep(0.0, 0.25, progress);
			if (m > trail_mask) {
				trail_mask = m;
				trail_age = progress;
			}
		}
		if (trail_mask > 0.001) {
			vec3 t_col = mix(gold_dim, gold_bright, trail_age);
			float t_str = trail_mask * (is_front ? 0.9 : 0.32);
			col = mix(col, t_col, t_str);
			alpha = max(alpha, t_str);
		}
	}

	// --- Current f(z) point marker ---
	if (has_valid_point) {
		float d_pt = length(p - current_point);
		float halo = exp(-d_pt * 9.0) * (is_front ? 0.55 : 0.22);
		float outline = 1.0 - smoothstep(0.075, 0.075 + aa, d_pt);
		float core = 1.0 - smoothstep(0.052, 0.052 + aa, d_pt);

		float cur_phase = atan(-current_point.z, current_point.x);
		vec3 cur_col = mix(phase_to_color(cur_phase), gold_bright, 0.45);

		col += cur_col * halo;
		alpha = max(alpha, halo * 0.7);

		col = mix(col, vec3(0.04, 0.05, 0.08), outline * (is_front ? 0.92 : 0.35));
		alpha = max(alpha, outline * (is_front ? 0.92 : 0.35));

		col = mix(col, mix(gold_bright, vec3(1.0), 0.35), core * (is_front ? 1.0 : 0.45));
		alpha = max(alpha, core * (is_front ? 1.0 : 0.45));
	}

	// Subtle outer glass rim highlight on front hemisphere
	if (is_front) {
		col += mix(gold_dim, vec3(0.85, 0.9, 1.0), 0.5) * fresnel * 0.45;
		alpha = max(alpha, fresnel * 0.65);
	}

	return vec4(col, clamp(alpha, 0.0, 0.96));
}

void fragment() {
	// Map UV to [-1, 1] with +Y upward
	vec2 uv = (vec2(UV.x, 1.0 - UV.y) - 0.5) * 2.0;
	float px_size = max(fwidth(uv.x), fwidth(uv.y));

	// Perspective camera orbiting the unit sphere
	float cam_dist = 2.75;
	vec3 ro = cam_dist * vec3(
		cos(cam_pitch) * sin(cam_yaw),
		sin(cam_pitch),
		cos(cam_pitch) * cos(cam_yaw)
	);
	vec3 forward = normalize(-ro);
	vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
	vec3 up = cross(right, forward);
	float fov_scale = 0.48;
	vec3 rd = normalize(forward + (uv.x * right + uv.y * up) * fov_scale);

	// Analytical ray-sphere intersection with unit sphere at origin
	float b = dot(ro, rd);
	float c = dot(ro, ro) - 1.0;
	float disc = b * b - c;

	if (disc < 0.0) {
		// Soft outer silhouette glow
		float miss = sqrt(max(-disc, 0.0));
		float rim_glow = exp(-miss * 16.0) * 0.18;
		vec3 glow_col = vec3(0.784, 0.663, 0.431);
		COLOR = vec4(glow_col, rim_glow);
	} else {
		float sqrt_disc = sqrt(disc);
		float t_near = -b - sqrt_disc;
		float t_far = -b + sqrt_disc;

		vec3 p_front = normalize(ro + rd * t_near);
		vec3 p_back = normalize(ro + rd * t_far);

		// 1. Back hemisphere
		vec4 back_col = shade_sphere_point(p_back, rd, false, px_size);
		vec3 accum_rgb = back_col.rgb;
		float accum_a = back_col.a;

		// 2. Interior polar axis (0 -> infinity) and radial vector (origin -> current_point)
		float t_axis;
		float d_axis = ray_segment_distance(ro, rd, vec3(0.0, -1.0, 0.0), vec3(0.0, 1.0, 0.0), t_axis);
		if (t_axis > t_near && t_axis < t_far) {
			float axis_mask = (1.0 - smoothstep(0.005, 0.005 + px_size * 1.2, d_axis)) * 0.22;
			vec3 axis_col = vec3(0.784, 0.663, 0.431);
			accum_rgb = mix(accum_rgb, axis_col, axis_mask);
			accum_a = max(accum_a, axis_mask);
		}

		if (has_valid_point) {
			float t_vec;
			float d_vec = ray_segment_distance(ro, rd, vec3(0.0), current_point, t_vec);
			if (t_vec > t_near && t_vec < t_far) {
				float vec_mask = (1.0 - smoothstep(0.009, 0.009 + px_size * 1.2, d_vec)) * 0.55;
				vec3 vec_col = vec3(1.0, 0.86, 0.45);
				accum_rgb = mix(accum_rgb, vec_col, vec_mask);
				accum_a = max(accum_a, vec_mask);
			}
		}

		// 3. Front hemisphere composited over back + interior
		vec4 front_col = shade_sphere_point(p_front, rd, true, px_size);
		vec3 final_rgb = mix(accum_rgb, front_col.rgb, front_col.a);
		float final_a = front_col.a + accum_a * (1.0 - front_col.a);

		// Smooth anti-aliasing at the outer sphere silhouette
		float edge_aa = smoothstep(0.0, max(px_size * 2.5, 0.015), sqrt_disc);
		COLOR = vec4(final_rgb, clamp(final_a * edge_aa, 0.0, 0.95));
	}
}


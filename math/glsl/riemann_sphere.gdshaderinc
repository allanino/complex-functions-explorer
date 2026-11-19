// Riemann Sphere helpers.
//
// The player stands on top of the sphere (local +Y is "up"); the sphere rotates under the player.
// A flat chart offset c = (x, z) around the player (world units) is mapped to the sphere with an
// azimuthal-equidistant projection, rotated by sphere_basis into the inertial sphere frame and then
// projected stereographically (from the south pole) to the complex plane:
//   (0, 1, 0) -> z = 0,   (0, -1, 0) -> z = infinity,   Re = u.x / (1 + u.y),   Im = -u.z / (1 + u.y)
// This mirrors Config.sphere_world_to_complex / GameState.sphere_unit_to_complex in GDScript.

uniform bool sphere_mode = false;
uniform float sphere_radius = 50.0;   // effective radius in world units (already scaled by zoom)
uniform bool sphere_height = true;    // radial displacement by the function height
uniform mat3 sphere_basis;            // local player frame -> inertial sphere frame

// Stereographic magnification thresholds (complex units per world unit) for fading radial height
// where the mesh vertices can no longer resolve the terrain. Mirrors Config.SPHERE_HEIGHT_FADE_*.
const float SPHERE_HEIGHT_FADE_START = 2.0;
const float SPHERE_HEIGHT_FADE_END = 6.0;

struct SphereChartFrame {
    vec3 l;        // unit direction in the player frame
    vec3 dl_dcx;   // derivative of l with respect to chart x
    vec3 dl_dcz;   // derivative of l with respect to chart z
};

SphereChartFrame sphere_chart_frame(vec2 c, float radius) {
    float r = length(c);
    float max_r = PI * radius;
    if (r > max_r) {
        c *= max_r / r;
        r = max_r;
    }
    float d = r / radius;

    // a = sin(d) / r  and  g = a'(r) / r, with series expansions near the origin.
    float a;
    float g;
    if (d < 1e-3) {
        a = (1.0 - d * d / 6.0) / radius;
        g = -1.0 / (3.0 * radius * radius * radius);
    } else {
        a = sin(d) / r;
        g = (cos(d) / (radius * r) - sin(d) / (r * r)) / r;
    }

    SphereChartFrame f;
    f.l = vec3(c.x * a, cos(d), c.y * a);
    f.dl_dcx = vec3(a + c.x * c.x * g, -a * c.x / radius, c.x * c.y * g);
    f.dl_dcz = vec3(c.x * c.y * g, -a * c.y / radius, a + c.y * c.y * g);
    return f;
}

// Fast chart-to-complex projection (without chart derivatives) for per-pixel evaluation.
// Also returns local stereographic magnification lambda = |dz|/ds = 1 / (radius * w).
vec2 sphere_chart_to_complex(vec2 c, float radius, out float out_lambda) {
    float r = length(c);
    float max_r = PI * radius;
    if (r > max_r) {
        c *= max_r / r;
        r = max_r;
    }
    float d = r / radius;
    float a = (d < 1e-3) ? (1.0 - d * d / 6.0) / radius : sin(d) / r;
    vec3 u = sphere_basis * vec3(c.x * a, cos(d), c.y * a);
    float w = max(1.0 + u.y, 1e-5);
    out_lambda = 1.0 / (radius * w);
    return vec2(u.x, -u.z) / w;
}

// Stereographic projection. Also returns the gradients of Re and Im with respect to u.
vec2 sphere_unit_to_complex(vec3 u, out vec3 dre_du, out vec3 dim_du) {
    float w = max(1.0 + u.y, 1e-5);
    dre_du = vec3(1.0 / w, -u.x / (w * w), 0.0);
    dim_du = vec3(0.0, u.z / (w * w), -1.0 / w);
    return vec2(u.x, -u.z) / w;
}

float sphere_height_fade(float lambda) {
    return 1.0 - smoothstep(SPHERE_HEIGHT_FADE_START, SPHERE_HEIGHT_FADE_END, lambda);
}

float sphere_height_fade_deriv(float lambda) {
    float span = SPHERE_HEIGHT_FADE_END - SPHERE_HEIGHT_FADE_START;
    float t = clamp((lambda - SPHERE_HEIGHT_FADE_START) / span, 0.0, 1.0);
    return -6.0 * t * (1.0 - t) / span;
}

// Evaluates the function on the Riemann Sphere at the chart offset c (world units around the player).
// Returns the displaced surface position in world space (player frame) and its normal.
// When skip_field_if_flat is true (per-pixel chunks), skips vertex-stage function evaluation if the
// surface is already flat at this point (sphere_height off or height faded to zero).
void compute_sphere_surface(vec2 c, bool skip_field_if_flat, out vec3 p_world, out vec3 nrm, out vec2 f_val, out bool invalid, out bool h_clamped_out, out float h_func_out) {
    float radius = sphere_radius;
    SphereChartFrame sf = sphere_chart_frame(c, radius);
    vec3 u = sphere_basis * sf.l;
    float w = max(1.0 + u.y, 1e-5);
    float lambda = 1.0 / (radius * w);
    float h_fade = sphere_height ? sphere_height_fade(lambda) : 0.0;

    f_val = vec2(0.0);
    invalid = false;
    h_clamped_out = false;
    h_func_out = 0.0;

    if (skip_field_if_flat && h_fade <= 0.0) {
        p_world = sf.l * radius - vec3(0.0, radius, 0.0);
        nrm = sf.l;
        return;
    }

    vec3 dre_du;
    vec3 dim_du;
    vec2 zc = sphere_unit_to_complex(u, dre_du, dim_du);

    ComplexFieldData fd = get_field_with_derivatives_complex(zc.x, zc.y, 0);
    invalid = any(isnan(fd.value)) || any(isinf(fd.value)) ||
            any(isnan(fd.dx)) || any(isinf(fd.dx));

    float h = 0.0;
    vec2 dh = vec2(0.0); // derivatives of h_func with respect to (Re z, Im z)
    bool floor_clamped = false;

    if (!invalid) {
        f_val = fd.value;
        bool hc = false;
        float h_raw = get_complex_height(fd.value, fd.value, hc);
        h_clamped_out = hc;
        h_func_out = h_raw * zoom_factor;
        if (h_fade > 0.0) {
            vec2 dh_w = get_complex_height_derivatives(fd.value, fd.value, vec2(0.0), fd.dx, fd.dy, 1.0, hc, 0);
            dh = zoom_factor * vec2(dh_w.x * 10.0, -dh_w.y * 10.0);
            h = h_func_out * h_fade;
            if (h < -0.9 * radius) {
                h = -0.9 * radius;
                dh = vec2(0.0);
                floor_clamped = true;
            }
        }
    }

    vec3 du_dcx = sphere_basis * sf.dl_dcx;
    vec3 du_dcz = sphere_basis * sf.dl_dcz;
    float dre_dcx = dot(dre_du, du_dcx);
    float dre_dcz = dot(dre_du, du_dcz);
    float dim_dcx = dot(dim_du, du_dcx);
    float dim_dcz = dot(dim_du, du_dcz);

    float dh_dcx = (dh.x * dre_dcx + dh.y * dim_dcx) * h_fade;
    float dh_dcz = (dh.x * dre_dcz + dh.y * dim_dcz) * h_fade;
    if (!floor_clamped && h_fade > 0.0 && h_fade < 1.0) {
        // Product-rule term: h_func * d(h_fade)/dc, keeping normals exact across the fade zone.
        float dfade_duy = sphere_height_fade_deriv(lambda) * (-lambda / w);
        dh_dcx += h_func_out * dfade_duy * du_dcx.y;
        dh_dcz += h_func_out * dfade_duy * du_dcz.y;
    }

    vec3 ds_dcx = dh_dcx * sf.l + (radius + h) * sf.dl_dcx;
    vec3 ds_dcz = dh_dcz * sf.l + (radius + h) * sf.dl_dcz;
    nrm = normalize(cross(ds_dcz, ds_dcx));
    p_world = sf.l * (radius + h) - vec3(0.0, radius, 0.0);
}

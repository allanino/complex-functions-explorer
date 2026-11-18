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

// Stereographic projection. Also returns the gradients of Re and Im with respect to u.
vec2 sphere_unit_to_complex(vec3 u, out vec3 dre_du, out vec3 dim_du) {
    float w = max(1.0 + u.y, 1e-5);
    dre_du = vec3(1.0 / w, -u.x / (w * w), 0.0);
    dim_du = vec3(0.0, u.z / (w * w), -1.0 / w);
    return vec2(u.x, -u.z) / w;
}

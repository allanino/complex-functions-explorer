1. Add `float sdLine3D(vec3 p, vec3 a, vec3 b)` to `terrain.gdshader`.
2. Update `compute_position_marker` to take `vec3 normal` as well.
Wait, `compute_position_marker` doesn't currently take `NORMAL`, but `NORMAL` is available in `fragment()`. We can either pass `NORMAL` or `v_normal`.
Let's see how `compute_position_marker` is called in `fragment()`:
```glsl
if (show_position_marker) {
    compute_position_marker(world_pos, NORMAL, ALBEDO, final_emission); // Add NORMAL
}
```
3. Inside `compute_position_marker`:
```glsl
void compute_position_marker(vec3 w_pos, vec3 norm, inout vec3 out_albedo, inout vec3 final_emission) {
    vec3 player_pos = player_position_world;

    float scale = clamp(0.4 / zoom_factor, 0.2, 0.7);

    float length_arms = 0.6 * scale;
    float thickness = 0.02 * scale;
    float glow_thickness = 0.04 * scale;
    float dot_radius = 0.07 * scale;
    float arrow_len = 0.08 * scale;
    float arrow_width = 0.04 * scale;

    // Project X and -Z axes onto the surface tangent plane
    vec3 t_right = normalize(vec3(1.0, 0.0, 0.0) - norm * norm.x);
    vec3 t_upward = normalize(vec3(0.0, 0.0, -1.0) - norm * (-norm.z));

    vec3 tip_right = player_pos + t_right * length_arms;
    vec3 tip_upward = player_pos + t_upward * length_arms;

    float d_line1 = sdLine3D(w_pos, player_pos, tip_right);
    float d_line2 = sdLine3D(w_pos, player_pos, tip_upward);
    float d_cross = min(d_line1, d_line2);

    float d_dot = length(w_pos - player_pos) - dot_radius;

    // Arrowheads
    vec3 right_perp = normalize(cross(norm, t_right)); // Points forward/backward
    float d_arr_right = min(
        sdLine3D(w_pos, tip_right, tip_right - t_right * arrow_len + right_perp * arrow_width),
        sdLine3D(w_pos, tip_right, tip_right - t_right * arrow_len - right_perp * arrow_width)
    );

    vec3 upward_perp = normalize(cross(norm, t_upward)); // Points left/right
    float d_arr_upward = min(
        sdLine3D(w_pos, tip_upward, tip_upward - t_upward * arrow_len + upward_perp * arrow_width),
        sdLine3D(w_pos, tip_upward, tip_upward - t_upward * arrow_len - upward_perp * arrow_width)
    );

    float d_arrows = min(d_arr_right, d_arr_upward);
    float d_marker = min(min(d_cross, d_dot), d_arrows);
...
```
Wait, we need to be careful with `cross(norm, t_right)`.
`t_right` points in +X. `norm` points up (+Y roughly).
`cross(norm, t_right)` -> `cross(Y, X) = -Z`. So it points forward. This is fine.
`t_upward` points in -Z.
`cross(norm, t_upward)` -> `cross(Y, -Z) = -X`. So it points left. This is fine.

4. Also pre commit steps.

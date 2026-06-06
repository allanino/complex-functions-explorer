# If we define the marker in the local tangent plane of the player...
# We only have `vec3 player_position_world` and `vec3 w_pos`.
# And we have `vec3 NORMAL`.

# Can we project the 3D displacement `w_pos - player_position_world` onto the XZ plane,
# but scale it based on the surface slope?
# The displacement is `D = w_pos - player_position_world`.
# The 3D distance from player to w_pos is `length(D)`.
# So the dot is `length(D) - dot_radius`. This gives a circle in 3D!

# For lines:
# Line 1 (Right arm): direction in 3D. We want it to point roughly right (+X), but lie on the surface.
# We can project +X onto the surface tangent plane:
# T_x = vec3(1, 0, 0)
# T_x_surf = normalize(cross(NORMAL, vec3(0, 0, 1)))  # points along +X on the surface
# T_z_surf = normalize(cross(vec3(1, 0, 0), NORMAL))  # points along -Z on the surface

# Actually, simply taking `w_pos - player_position_world` and computing `sdLine` in 3D.

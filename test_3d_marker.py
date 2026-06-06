import math

def length(v):
    return math.sqrt(v[0]**2 + v[1]**2 + v[2]**2)

# If we calculate 3D distance between player pos on surface and w_pos on surface
# Does it look right from above?
# w_pos = (x, h(x,z), z)
# player_pos = (px, h(px,pz), pz)

# Actually, the user says "it can stretch and alongate oddly in highly vertical terrain.
# I want it to keep the same basic size it has on flat terrain."

# The issue is that the marker is defined purely in XZ plane (using pos_xz and player_xz).
# So on steep slopes, a small XZ distance corresponds to a large 3D distance.
# As a result, when rendered on the surface, the marker looks stretched out along the steep axis.
# To fix this, we should NOT define the SDF in XZ space. We should define the SDF in the local tangent plane!

# Let N be the normal vector at player_pos.
# Tangent plane axes:
# Wait, player_position_world has a varying normal. But we don't have it in the shader.
# But we DO have the world normal of the CURRENT pixel (NORMAL or v_normal).

# Even simpler: we can use the 3D distance to the axes.
# Instead of pos_xz, player_xz:
# Let displacement be D = w_pos - player_position_world.
# To make it look like a cross on the surface, we want a cross aligned with the X and Z axes, but projected onto the surface.
# If we project D onto the tangent plane at w_pos...

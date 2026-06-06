import math

def length(v):
    return math.sqrt(v[0]**2 + v[1]**2)

# If we have a vector V in XZ plane, what is its actual length on the 3D surface?
# Let surface normal be N = (nx, ny, nz)
# Vector is (vx, vy, vz). Since it's on the surface, dot(V, N) = 0
# vx*nx + vy*ny + vz*nz = 0 => vy = -(vx*nx + vz*nz)/ny
# Length on surface = sqrt(vx^2 + vz^2 + (-(vx*nx + vz*nz)/ny)^2)
# To make a marker draw as a circle on the surface instead of an ellipse,
# we should calculate the 3D distance between pos_xz and player_xz, mapped onto the tangent plane.

# Or simpler:
# We just take w_pos and player_pos in 3D!
# BUT w_pos is the point on the surface. We don't have player_pos on the surface directly.
# Wait, player_position_world IS the 3D player position.
# It should include the height!

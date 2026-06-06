import math

# Current code:
# d_line1 = sdLine(pos_xz, player_xz, player_xz + vec2(length_arms, 0.0));
# This is a line along the X axis.
# The 3D distance between w_pos and the line (player_x, y, player_z) -> (player_x + length, y, player_z)?
# We want the marker to have a consistent 3D size.
# If we calculate 3D distance from w_pos to the line.

# Wait, if we use 3D distance, the thickness will be consistent.
# But what about the length of the arms? If the arm goes from X=0 to X=L, its XZ length is L.
# On a slope, its 3D length is L * sqrt(1 + slope^2).
# So the arms will be longer in 3D!
# We want the 3D length of the arms to be `length_arms`.
# To do this, we can define the local axes on the surface.

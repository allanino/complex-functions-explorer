extends Control

var angle_deg: float = 0.0
var color: Color = Color.WHITE

func _draw():
	var center = size / 2.0

	# The length of the arrow
	var length = min(size.x, size.y) * 0.4

	# Direction vector
	var angle_rad = deg_to_rad(-angle_deg) # Negative because y is down in 2D
	var dir = Vector2(cos(angle_rad), sin(angle_rad))

	var tip = center + dir * length
	var base = center - dir * length
	var head_base = tip - dir * (length * 0.6)

	var perp = Vector2(-dir.y, dir.x)
	var head_left = head_base + perp * (length * 0.4)
	var head_right = head_base - perp * (length * 0.4)

	# Draw line
	draw_line(base, head_base, color, 2.0, true)

	# Draw arrowhead
	var points = PackedVector2Array([tip, head_left, head_right])
	var colors = PackedColorArray([color, color, color])
		# Draw polygon fill
	draw_polygon(points, colors)

	# Draw polyline outline for anti-aliasing the edges
	var outline_points = PackedVector2Array([tip, head_left, head_right, tip])
	draw_polyline(outline_points, color, 1.0, true)

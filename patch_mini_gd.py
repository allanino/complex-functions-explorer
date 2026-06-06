with open("ui/mini_terrain.gd", "r") as f:
    content = f.read()

# Add uniforms for level curves and critical stripe
updates = """		mat.set_shader_parameter("current_branch", GameState.current_branch)
		mat.set_shader_parameter("draw_level_curves", Config.draw_level_curves)
		mat.set_shader_parameter("draw_critical_stripe", Config.draw_critical_stripe)
"""

if "draw_level_curves" not in content:
    content = content.replace('		mat.set_shader_parameter("current_branch", GameState.current_branch)', updates)

sync_updates = """	if key in ["iterations", "zoom_factor", "function_type", "input_function_type", "color_scheme", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n", "draw_level_curves", "draw_critical_stripe"]:
"""

content = content.replace('	if key in ["iterations", "zoom_factor", "function_type", "input_function_type", "color_scheme", "rational_num_coeffs", "rational_den_coeffs", "input_rational_num_coeffs", "input_rational_den_coeffs", "multivalued_n"]:', sync_updates)

with open("ui/mini_terrain.gd", "w") as f:
    f.write(content)

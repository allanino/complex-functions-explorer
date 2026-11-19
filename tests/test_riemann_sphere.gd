extends BaseTest

func before_each():
	Config.riemann_sphere_mode = false
	Config.riemann_sphere_height = true
	Config.riemann_sphere_radius = 50.0
	GameState.sphere_basis = Basis.IDENTITY
	GameState.effective_zoom = 1.0

func after_each():
	Config.riemann_sphere_mode = false
	Config.riemann_sphere_height = true
	Config.riemann_sphere_radius = 50.0
	GameState.sphere_basis = Basis.IDENTITY

func test_stereographic_round_trip():
	for z in [Vector2(0, 0), Vector2(1, 0), Vector2(0.3, -2.0), Vector2(-5, 7)]:
		var u = GameState.complex_to_sphere_unit(z)
		assert_almost_eq(u.length(), 1.0, 1e-5)
		var back = GameState.sphere_unit_to_complex(u)
		assert_almost_eq(back.x, z.x, 1e-4)
		assert_almost_eq(back.y, z.y, 1e-4)

func test_origin_is_under_player_initially():
	var z = Config.sphere_world_to_complex(0.0, 0.0)
	assert_almost_eq(z.length(), 0.0, 1e-6)

func test_set_sphere_position_places_player_on_complex_point():
	for z in [Vector2(0.5, 0.0), Vector2(-2.0, 3.0), Vector2(10.0, -4.0)]:
		GameState.set_sphere_position(z)
		var got = Config.sphere_world_to_complex(0.0, 0.0)
		assert_almost_eq(got.x, z.x, 1e-3)
		assert_almost_eq(got.y, z.y, 1e-3)
		assert_almost_eq(GameState.sphere_basis.determinant(), 1.0, 1e-4)

func test_chart_round_trip():
	GameState.set_sphere_position(Vector2(0.4, 0.7))
	var c = Vector2(12.0, -30.0)
	var z = Config.sphere_world_to_complex(c.x, c.y)
	var back = Config.sphere_complex_to_world(z.x, z.y)
	assert_almost_eq(back.x, c.x, 1e-2)
	assert_almost_eq(back.y, c.y, 1e-2)

func test_walking_forward_increases_imaginary_part():
	var start = Config.sphere_world_to_complex(0.0, 0.0)
	GameState.advance_on_sphere(Vector2(0.0, -10.0), Config.get_sphere_radius())
	var now = Config.sphere_world_to_complex(0.0, 0.0)
	assert_gt(now.y, start.y)
	assert_almost_eq(now.x, start.x, 1e-4)

func test_walking_keeps_basis_orthonormal():
	for i in range(2000):
		GameState.advance_on_sphere(Vector2(0.3, -0.7), Config.get_sphere_radius())
	assert_almost_eq(GameState.sphere_basis.determinant(), 1.0, 1e-4)
	assert_almost_eq(GameState.sphere_basis.x.length(), 1.0, 1e-4)

func test_walking_half_circumference_reaches_infinity_side():
	GameState.advance_on_sphere(Vector2(PI * Config.get_sphere_radius() * 0.999, 0.0), Config.get_sphere_radius())
	assert_gt(Config.sphere_world_to_complex(0.0, 0.0).length(), 100.0)

func test_zoom_scales_radius():
	Config.riemann_sphere_radius = 50.0
	GameState.effective_zoom = 2.0
	assert_almost_eq(Config.get_sphere_radius(), 100.0, 1e-4)

func test_mode_disables_multivalued():
	Config.function_type = Config.ComplexFunc.MULTIVALUED_ASIN
	assert_true(Config.is_multivalued_active())
	Config.riemann_sphere_mode = true
	assert_false(Config.is_multivalued_active())

func test_world_to_complex_dispatch():
	GameState.set_sphere_position(Vector2(1.0, 1.0))
	var flat = Config.world_to_complex(10.0, -10.0)
	assert_almost_eq(flat.x, 1.0, 1e-5)
	Config.riemann_sphere_mode = true
	var sph = Config.world_to_complex(0.0, 0.0)
	assert_almost_eq(sph.x, 1.0, 1e-3)
	assert_almost_eq(sph.y, 1.0, 1e-3)

func test_settings_keys_registered():
	for key in ["riemann_sphere_mode", "riemann_sphere_radius", "riemann_sphere_height"]:
		assert_true(key in Config.PRESET_KEYS)

func test_sphere_shader_compiles_with_material():
	var shader := load("res://terrain/terrain.gdshader") as Shader
	assert_true(shader.code.contains("sphere_mode"))
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("sphere_mode", true)
	mat.set_shader_parameter("sphere_basis", Basis.IDENTITY)
	assert_eq(mat.get_shader_parameter("sphere_mode"), true)

func test_sphere_height_disabled_follows_sphere_surface():
	Config.riemann_sphere_mode = true
	Config.riemann_sphere_height = false
	Config.riemann_sphere_radius = 50.0
	Config.height_type = 0
	GameState.effective_zoom = 1.0

	var f_val = Vector2(3.0, 4.0)
	var player_scene := load("res://player/player.tscn") as PackedScene
	var player = autofree(player_scene.instantiate())

	# At the top of the sphere (x=0, z=0), the sphere surface is at y=0
	assert_almost_eq(player.get_terrain_height(0.0, 0.0, f_val), 0.0, 1e-5)

	# Off-center at distance d * R, the surface follows the curvature R * (cos(d) - 1)
	var dist = 10.0
	var expected_y = 50.0 * (cos(dist / 50.0) - 1.0)
	assert_almost_eq(player.get_terrain_height(dist, 0.0, f_val), expected_y, 1e-4)

	# get_terrain_height stays on the smooth sphere even for INF/NAN, while get_plane_height
	# returns the complex-plane function height so the shadow area (> MAX_WORLD_HEIGHT) is still detected.
	assert_almost_eq(player.get_terrain_height(0.0, 0.0, Vector2(INF, INF)), 0.0, 1e-5)
	assert_almost_eq(player.get_terrain_height(dist, 0.0, Vector2(NAN, NAN)), expected_y, 1e-4)
	assert_almost_eq(player.get_plane_height(0.0, 0.0, f_val), 5.0, 1e-4)
	assert_gt(player.get_plane_height(0.0, 0.0, Vector2(2000.0, 0.0)), GameState.MAX_WORLD_HEIGHT)

func test_minimap_view_radius_scales_with_stereographic_factor():
	var minimap_scene := load("res://ui/minimap.tscn") as PackedScene
	var minimap = autofree(minimap_scene.instantiate())
	add_child_autofree(minimap)

	Config.riemann_sphere_mode = true
	Config.riemann_sphere_radius = 50.0
	GameState.set_sphere_position(Vector2(0.0, 0.0))
	var r_at_zero = minimap._get_effective_view_radius()

	# Far from the origin (e.g. z = 0 - 50i, like in the critical strip),
	# stereographic projection magnifies |dz/ds| by (1 + |z|^2) / 2, so the minimap
	# view_radius must expand proportionally so the map doesn't fly past.
	GameState.set_sphere_position(Vector2(0.5, -50.0))
	var r_at_50 = minimap._get_effective_view_radius()
	assert_gt(r_at_50, r_at_zero * 500.0)

func test_sphere_lambda_and_height_fade_match_shader_formula():
	Config.riemann_sphere_mode = true
	Config.riemann_sphere_radius = 50.0
	GameState.effective_zoom = 1.0

	for z in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(3.0, -4.0), Vector2(-12.0, 44.0)]:
		var u = GameState.complex_to_sphere_unit(z)
		var w = maxf(1.0 + u.y, 1e-5)
		var expected_lam = 1.0 / (Config.get_sphere_radius() * w)
		assert_almost_eq(Config.sphere_lambda(z), expected_lam, maxf(1e-4, expected_lam * 1e-4))

	# Well-resolved region near origin: fade == 1.0
	assert_almost_eq(Config.sphere_height_fade(Vector2(0.0, 0.0)), 1.0, 1e-6)
	# Under-resolved region near infinity: fade == 0.0
	assert_almost_eq(Config.sphere_height_fade(Vector2(-12.0, 44.0)), 0.0, 1e-6)

func test_player_height_matches_sphere_height_fade():
	Config.riemann_sphere_mode = true
	Config.riemann_sphere_height = true
	Config.riemann_sphere_radius = 50.0
	Config.height_type = 0
	GameState.effective_zoom = 1.0

	var player_scene := load("res://player/player.tscn") as PackedScene
	var player = autofree(player_scene.instantiate())
	var f_val = Vector2(3.0, 4.0) # |f| = 5.0

	# Near z = 0: smoothly compressed radial height h_max * tanh(h / h_max)
	GameState.set_sphere_position(Vector2(0.0, 0.0))
	var expected_5 = RiemannSphere.compress_height(5.0, 50.0)
	assert_almost_eq(player.get_terrain_height(0.0, 0.0, f_val), expected_5, 1e-4)
	# Poles (INF / -INF) saturate smoothly to +/- MAX_HEIGHT_RATIO * R instead of NaN
	assert_almost_eq(RiemannSphere.compress_height(INF, 50.0), 50.0 * RiemannSphere.MAX_HEIGHT_RATIO, 1e-4)
	assert_almost_eq(RiemannSphere.compress_height(-INF, 50.0), -50.0 * RiemannSphere.MAX_HEIGHT_RATIO, 1e-4)

	# Far from origin (lambda >> SPHERE_HEIGHT_FADE_END): radial height fades to 0
	GameState.set_sphere_position(Vector2(-12.0, 44.0))
	assert_almost_eq(player.get_terrain_height(0.0, 0.0, f_val), 0.0, 1e-4)

func test_per_pixel_flag_hysteresis():
	var terrain_scene := load("res://terrain/terrain.tscn") as PackedScene
	var terrain = autofree(terrain_scene.instantiate())
	Config.riemann_sphere_mode = true
	Config.terrain_detail = 1 # Medium: LOD_SUBS[0] = 127 -> spacing = 16 / 128 = 0.125
	terrain._update_lod_subs()

	var coord = Vector2i(0, 0)
	var spacing = terrain.chunk_size / float(terrain.LOD_SUBS[0] + 1)
	var turn_on_lam = (RiemannSphere.PER_PIXEL_THRESHOLD / spacing) + 0.05
	var mid_lam = (RiemannSphere.PER_PIXEL_THRESHOLD * 0.9 / spacing)
	var turn_off_lam = (RiemannSphere.PER_PIXEL_THRESHOLD * RiemannSphere.PER_PIXEL_HYSTERESIS / spacing) - 0.05

	# Starts off; mid_lam should NOT turn it on
	assert_false(terrain._should_resolve_per_pixel(coord, mid_lam))
	# Crossing above threshold turns it on
	assert_true(terrain._should_resolve_per_pixel(coord, turn_on_lam))
	terrain._chunk_per_pixel[coord] = true
	# Hysteresis keeps it on at mid_lam
	assert_true(terrain._should_resolve_per_pixel(coord, mid_lam))
	# Dropping below hysteresis floor turns it off
	assert_false(terrain._should_resolve_per_pixel(coord, turn_off_lam))

func test_teleport_to_complex_and_oob_reset_in_sphere_mode():
	Config.riemann_sphere_mode = true
	Config.riemann_sphere_height = false
	Config.riemann_sphere_radius = 50.0
	Config.function_type = Config.ComplexFunc.ZETA_CONTINUATION
	GameState.effective_zoom = 1.0

	var player_scene := load("res://player/player.tscn") as PackedScene
	var player = autofree(player_scene.instantiate())
	add_child_autofree(player)

	# Teleport directly to a complex coordinate
	player.teleport_to_complex(Vector2(0.5, 14.134))
	var landed = Config.world_to_complex(player.global_position.x, player.global_position.z)
	assert_almost_eq(landed.x, 0.5, 1e-3)
	assert_almost_eq(landed.y, 14.134, 1e-2)
	assert_almost_eq(player.global_position.x, 0.0, 1e-6)
	assert_almost_eq(player.global_position.z, 0.0, 1e-6)

	# Non-finite teleport resets to the function's initial position
	GameState.out_of_bounds_teleport_active = false
	player.teleport_to_complex(Vector2(INF, 0.0))
	assert_true(GameState.out_of_bounds_teleport_active)
	var reset_z = Config.world_to_complex(player.global_position.x, player.global_position.z)
	var expected_init = Config.plane_world_to_complex(player.get_initial_position().x, player.get_initial_position().z)
	assert_almost_eq(reset_z.x, expected_init.x, 1e-2)
	assert_almost_eq(reset_z.y, expected_init.y, 1e-2)

func test_minimap_forward_matches_stereographic_heading():
	var minimap_scene := load("res://ui/minimap.tscn") as PackedScene
	var minimap = autofree(minimap_scene.instantiate())
	add_child_autofree(minimap)

	Config.riemann_sphere_mode = true
	Config.riemann_sphere_radius = 50.0

	# At z = 0 with identity basis, yaw = 0 looks along -Z -> +Im -> minimap up (0, -1)
	GameState.sphere_basis = Basis.IDENTITY
	var f0 = minimap._get_minimap_forward(0.0)
	assert_almost_eq(f0.x, 0.0, 1e-5)
	assert_almost_eq(f0.y, -1.0, 1e-5)

	# After walking in a curved path (holonomy), _get_minimap_forward should match the actual
	# finite-difference complex direction of stepping forward along yaw = 0.
	GameState.advance_on_sphere(Vector2(30.0, 0.0), 50.0)
	GameState.advance_on_sphere(Vector2(0.0, -30.0), 50.0)
	GameState.advance_on_sphere(Vector2(-30.0, 0.0), 50.0)
	var z_here = Config.sphere_world_to_complex(0.0, 0.0)
	var z_ahead = Config.sphere_world_to_complex(0.0, -0.05)
	var dz = z_ahead - z_here
	var expected_dir = Vector2(dz.x, -dz.y).normalized()
	var got_dir = minimap._get_minimap_forward(0.0)
	assert_almost_eq(got_dir.x, expected_dir.x, 1e-3)
	assert_almost_eq(got_dir.y, expected_dir.y, 1e-3)

func test_compute_chunk_lambda_range_matches_acos_formula():
	var terrain_scene := load("res://terrain/terrain.tscn") as PackedScene
	var terrain = autofree(terrain_scene.instantiate())
	var r_sphere = 50.0
	var chunk_ang = (terrain.chunk_size * terrain.CHUNK_HALF_DIAG_RATIO) / r_sphere
	var pole_local = Vector3(0.3, -0.8, 0.5).normalized()

	for l_center in [Vector3(0, 1, 0), Vector3(0.4, 0.7, -0.5).normalized(), pole_local, -pole_local]:
		var got = terrain._compute_chunk_lambda_range(l_center, pole_local, r_sphere, cos(chunk_ang), sin(chunk_ang))
		var theta = acos(clampf(l_center.dot(pole_local), -1.0, 1.0))
		var exp_max = 1.0 / (r_sphere * maxf(1.0 - cos(maxf(0.0, theta - chunk_ang)), 1e-5))
		var exp_min = 1.0 / (r_sphere * maxf(1.0 - cos(minf(PI, theta + chunk_ang)), 1e-5))
		assert_almost_eq(got.x, exp_min, maxf(1e-4, exp_min * 1e-4))
		assert_almost_eq(got.y, exp_max, maxf(1e-4, exp_max * 1e-4))

func test_ui_formatters_handle_inf_and_nan():
	var main_ui_scene := load("res://ui/main_ui.tscn") as PackedScene
	var main_ui = autofree(main_ui_scene.instantiate())
	assert_eq(main_ui._format_float(INF), "∞")
	assert_eq(main_ui._format_float(-INF), "-∞")
	assert_eq(main_ui._format_float(NAN), "NaN")

	var minimap_scene := load("res://ui/minimap.tscn") as PackedScene
	var minimap = autofree(minimap_scene.instantiate())
	assert_eq(minimap._format_coordinate(INF), "∞")
	assert_eq(minimap._format_coordinate(-INF), "-∞")
	assert_eq(minimap._format_coordinate(NAN), "NaN")







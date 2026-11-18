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
	GameState.effective_zoom = 1.0

	# ComplexField.get_height_from_field should return 0.0 (un-displaced radius) when sphere_height is disabled,
	# even for a non-zero function value.
	var f_val = Vector2(3.0, 4.0)
	assert_almost_eq(ComplexField.get_height_from_field(f_val), 0.0, 1e-6)

	var player_scene := load("res://player/player.tscn") as PackedScene
	var player = autofree(player_scene.instantiate())

	# At the top of the sphere (x=0, z=0), the sphere surface is at y=0
	assert_almost_eq(player.get_terrain_height(0.0, 0.0, f_val), 0.0, 1e-5)

	# Off-center at distance d * R, the surface follows the curvature R * (cos(d) - 1)
	var dist = 10.0
	var expected_y = 50.0 * (cos(dist / 50.0) - 1.0)
	assert_almost_eq(player.get_terrain_height(dist, 0.0, f_val), expected_y, 1e-4)

	# Even when f_val is INF or NAN (e.g., at a pole or infinity on the sphere),
	# height remains finite on the sphere surface when sphere_height is disabled.
	assert_almost_eq(ComplexField.get_height_from_field(Vector2(INF, INF)), 0.0, 1e-6)
	assert_almost_eq(ComplexField.get_height_from_field(Vector2(NAN, NAN)), 0.0, 1e-6)
	assert_almost_eq(player.get_terrain_height(0.0, 0.0, Vector2(INF, INF)), 0.0, 1e-5)
	assert_almost_eq(player.get_terrain_height(dist, 0.0, Vector2(NAN, NAN)), expected_y, 1e-4)



extends BaseTest

func test_sky_shader_loads():
	var shader := load("res://environment/sky.gdshader")

	assert_not_null(shader)
	assert_true(shader is Shader)

	# Optional: ensure it has code
	assert_ne(shader.code.length(), 0)

func test_sky_shader_material_creation():
	var shader := load("res://environment/sky.gdshader")
	var material := ShaderMaterial.new()

	material.shader = shader

	assert_not_null(material.shader)

func test_terrain_shader_loads():
	var shader := load("res://terrain/terrain.gdshader")

	assert_not_null(shader)
	assert_true(shader is Shader)

	# Optional: ensure it has code
	assert_ne(shader.code.length(), 0)

func test_terrain_shader_material_creation():
	var shader := load("res://terrain/terrain.gdshader")
	var material := ShaderMaterial.new()

	material.shader = shader

	assert_not_null(material.shader)

extends BaseTest

var _visited_zeros_emits: int = 0

func _on_state_changed(key: String):
	if key == "visited_zeros":
		_visited_zeros_emits += 1

func before_each():
	Config.function_type = Config.ComplexFunc.ZETA_CONTINUATION
	Config.input_function_type = Config.ComplexFunc.IDENTITY
	GameState.visited_zeros.clear()
	GameState.visited_zeros.append(Vector2(0.5, 14.1347))
	GameState.visited_zeros.append(Vector2(0.5, 21.0220))
	GameState.total_zeros_found = 2
	_visited_zeros_emits = 0
	GameState.state_changed.connect(_on_state_changed)

func after_each():
	if GameState.state_changed.is_connected(_on_state_changed):
		GameState.state_changed.disconnect(_on_state_changed)

func _assert_cleared():
	assert_eq(GameState.visited_zeros.size(), 0)
	assert_eq(GameState.total_zeros_found, 0)
	assert_eq(GameState.accented_zero_index, -1)
	assert_gt(_visited_zeros_emits, 0, "visited_zeros should be emitted so HUD/minimap refresh")

func _assert_not_cleared():
	assert_eq(GameState.visited_zeros.size(), 2)
	assert_eq(GameState.total_zeros_found, 2)
	assert_eq(_visited_zeros_emits, 0)

func test_clear_zeros_emits_and_resets():
	GameState.clear_zeros()
	_assert_cleared()

func test_function_type_change_clears():
	Config.function_type = Config.ComplexFunc.SIN
	_assert_cleared()

func test_same_function_type_does_not_clear():
	Config.function_type = Config.ComplexFunc.ZETA_CONTINUATION
	_assert_not_cleared()

func test_input_function_type_change_clears():
	Config.input_function_type = Config.ComplexFunc.SIN
	_assert_cleared()

func test_rational_coeffs_change_clears():
	var c = Config.rational_num_coeffs.duplicate()
	c[0] = c[0] + Vector2(1, 0)
	Config.rational_num_coeffs = c
	_assert_cleared()

func test_rational_den_coeffs_change_clears():
	var c = Config.rational_den_coeffs.duplicate()
	c[1] = c[1] + Vector2(1, 0)
	Config.rational_den_coeffs = c
	_assert_cleared()

func test_input_rational_coeffs_change_clears():
	var c = Config.input_rational_num_coeffs.duplicate()
	c[0] = c[0] + Vector2(0, 1)
	Config.input_rational_num_coeffs = c
	_assert_cleared()

func test_input_rational_den_coeffs_change_clears():
	var c = Config.input_rational_den_coeffs.duplicate()
	c[1] = c[1] + Vector2(0, 1)
	Config.input_rational_den_coeffs = c
	_assert_cleared()

func test_height_change_does_not_clear():
	Config.height_type = (Config.height_type + 1) % 3
	Config.height_a = Config.height_a + 1.0
	_assert_not_cleared()


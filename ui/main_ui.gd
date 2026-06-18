extends CanvasLayer
const ZERO_LIST_ITEM_SCENE = preload("res://ui/components/zero_list_item.tscn")
const NEON_FONT = preload("res://ui/theme/font_neon.tres")
@export var player: Node3D
@export var polynomial_debug: bool = false
@onready var hud_columns = %MainUIColumns
@onready var hud_stack_left = %MainUIStackLeft
@onready var hud_stack_right = %MainUIStackRight
@onready var minimap_panel = %MinimapPanel
@onready var minimap = %MinimapAspect
@onready var phase_wheel = %PhaseWheel
@onready var position_panel = %PositionPanel
@onready var monitor_panel = %MonitorPanel
@onready var monitor_rt_label = %MonitorRichTextLabel
@onready var world_manager = get_node_or_null("../WorldManager")
@onready var domain_val = %DomainVal
@onready var target_val = %TargetVal
@onready var phase_branch_val = %PhaseBranchVal
@onready var branch_label = %BranchLabel
@onready var phase_abs_val = %PhaseAbsVal
@onready var zeros_panel = %ZerosPanel
@onready var zeros_count_label = %CountLabel
@onready var rvm_hbox = %RvmHBox
@onready var rvm_n_label = %RvmNLabel
@onready var rvm_delta_label = %RvmDeltaLabel
@onready var zeros_list_label = %ListLabelContainer
@onready var zeros_scroll = %ZerosScroll
@onready var menu_overlay = %MenuOverlay
var portal_flash: ColorRect

var polynomial_debug_str: String = ""

@onready var tooltip_manager = %TooltipManager
@onready var detach_controller = %DetachOverlay
@onready var preset_controller = %PresetController
@onready var position_arg_label = %PositionArgLabel
@onready var position_arg_val = %PositionArgVal
@onready var position_arg_arrow = %PositionArgArrow
@onready var position_arg_container = %PositionArgContainer
@onready var mobile_controls = $Control/MobileControls
@onready var mobile_settings_btn = $Control/MobileControls/SettingsButton
@onready var target_label = %TargetLabel
@onready var abs_label = %AbsLabel

@export var show_hud_chunks: bool = false

var _height_protection_timer: float = 0.0
var _out_of_bounds_timer: float = 0.0
var _unstable_zeta_timer: float = 0.0

# New UI Node Paths
var current_scale = 2.0
const BASE_HUD_PANEL_SIZE: float = 240.0


# Wraps a numeric string in BBCode: dims a leading '-' sign, colors the rest.
func _bb_re(value: String, color: String) -> String:
	if value.begins_with("-"):
		return "[color=%s]-[/color][color=%s]%s[/color]" % [ThemeColors.CLR_DIM, color, value.substr(1)]
	return "[color=%s]%s[/color]" % [color, value]

# Formats an imaginary value as "± number i" with a dim operator separator.
func _bb_im(im: String) -> String:
	if im.begins_with("-"):
		return "[color=%s] - [/color][color=%s]%s[/color][color=%s]i[/color]" % [ThemeColors.CLR_DIM, ThemeColors.CLR_IMAGINARY, im.substr(1), ThemeColors.CLR_IMAGINARY_DIM]
	return "[color=%s] + [/color][color=%s]%s[/color][color=%s]i[/color]" % [ThemeColors.CLR_DIM, ThemeColors.CLR_IMAGINARY, im, ThemeColors.CLR_IMAGINARY_DIM]

func update_arg_val(f: Vector2):
	var angle_rad: float
	if f.length() > 1e-12:
		var f_dir = f.normalized()
		angle_rad = atan2(f_dir.y, f_dir.x)
	else:
		angle_rad = atan2(f.y, f.x)

	var angle_deg = rad_to_deg(angle_rad)
	if angle_deg < 0:
		angle_deg += 360.0

	position_arg_val.text = "%5.1f°" % angle_deg

	# Compute matching color
	var hue = (angle_rad + PI) / (2.0 * PI)
	if Config.color_scheme == 1:
		hue = wrapf(hue + 0.5, 0.0, 1.0)

	var saturation = clamp(Config.terrain_saturation, 0.3, 1.0) * 0.5
	var brightness = Config.terrain_brightness

	var hsv_color = Color.from_hsv(hue, saturation, min(brightness, 1.0))
	if Config.color_scheme == 2:
		var v = 0.5 + 0.5 * cos(angle_rad)
		hsv_color = Color(v, v, v) * brightness

	var final_color = hsv_color * (Config.terrain_albedo + Config.terrain_emission) * 2.0
	final_color.r = clamp(final_color.r, 0.0, 1.0)
	final_color.g = clamp(final_color.g, 0.0, 1.0)
	final_color.b = clamp(final_color.b, 0.0, 1.0)
	final_color.a = 1.0

	position_arg_val.add_theme_color_override("font_color", final_color)

	position_arg_arrow.angle_deg = angle_deg
	position_arg_arrow.color = final_color
	position_arg_arrow.queue_redraw()

func _setup_branch_data():
	if Config.function.get("is_multivalued", false):
		phase_branch_val.visible = true
		branch_label.visible = true
	else:
		phase_branch_val.visible = false
		branch_label.visible = false

func _process(delta: float) -> void:
	var needs_update = false
	if _height_protection_timer > 0.0:
		_height_protection_timer -= delta
		if _height_protection_timer <= 0.0:
			GameState.height_protection_active = false
			needs_update = true

	if _out_of_bounds_timer > 0.0:
		_out_of_bounds_timer -= delta
		if _out_of_bounds_timer <= 0.0:
			GameState.out_of_bounds_teleport_active = false
			needs_update = true

	if _unstable_zeta_timer > 0.0:
		_unstable_zeta_timer -= delta
		if _unstable_zeta_timer <= 0.0:
			GameState.unstable_zeta_computation = false
			needs_update = true

	if needs_update:
		_update_monitor_label()

	# Performance: Suspend _process when no timers are active
	if _height_protection_timer <= 0.0 and _out_of_bounds_timer <= 0.0 and _unstable_zeta_timer <= 0.0:
		set_process(false)

func _ready():
	# Performance: Start with _process disabled since no timers are active initially
	set_process(false)

	get_viewport().scaling_3d_scale = Config.rendering_scale
	Config.config_changed.connect(_on_config_changed)
	_update_function_labels()

	if not mobile_settings_btn.pressed.is_connected(toggle_menu.bind(false)):
		mobile_settings_btn.pressed.connect(toggle_menu.bind(false))

	portal_flash = ColorRect.new()
	portal_flash.name = "PortalFlash"
	portal_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portal_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portal_flash.color = Color(0.0, 0.8, 1.0, 0.0) # Transparent cyan
	portal_flash.visible = false
	$Control.add_child(portal_flash)

	phase_wheel.resized.connect(_on_complex_aspect_resized)

	minimap.resized.connect(_on_minimap_resized)

	hud_columns.offset_top = -1000

	menu_overlay.apply_aa_signal.connect(apply_aa)
	menu_overlay.update_hud_layout_signal.connect(_update_hud_layout)

	GameState.state_changed.connect(_on_game_state_changed)
	
	# Monitor card don't need high frequency update
	var monitor_timer = Timer.new()
	monitor_timer.autostart = true
	monitor_timer.wait_time = 0.5
	monitor_timer.timeout.connect(_on_monitor_timer_timeout)
	add_child(monitor_timer)

	var values_timer = Timer.new()
	values_timer.autostart = true
	values_timer.wait_time = 0.04
	values_timer.timeout.connect(_on_values_timer_timeout)
	add_child(values_timer)

	var update_layout_timer = Timer.new()
	update_layout_timer.autostart = true
	update_layout_timer.wait_time = 0.1
	update_layout_timer.timeout.connect(_update_hud_layout)
	add_child(update_layout_timer)

	position_arg_container.visible = !Config.show_hud_phase_wheel and Config.show_hud_navigation

	menu_overlay.player = player
	menu_overlay.detach_controller = detach_controller
	menu_overlay.preset_controller = preset_controller
	menu_overlay.world_manager = world_manager
	menu_overlay.tooltip_manager = tooltip_manager

	zeros_panel.visible = Config.show_hud_zeros
	minimap_panel.visible = Config.show_minimap
	phase_wheel.get_parent().visible = Config.show_hud_phase_wheel and Config.show_hud_navigation
	phase_wheel.visible = Config.show_hud_phase_wheel and Config.show_hud_navigation
	if phase_wheel.visible:
		_on_complex_aspect_resized()
	phase_wheel.update_minimum_size()
	phase_wheel.get_parent().update_minimum_size()
	position_panel.update_minimum_size()
	position_panel.visible = Config.show_hud_navigation

	_setup_branch_data()
	_update_monitor_label()
	_update_zeros_list()

	_update_hud_layout()

func _on_values_timer_timeout():
	if player == null:
		return
	var z = player.global_position.z

	if Config.show_hud_zeros:
		if Config.show_rvm and Config.function.get("has_von_mangoldt", false):
			var T = abs(Config.world_to_complex(0.0, z).y)
			var rvm_val = _get_rvm_n(T) - _get_rvm_n(GameState.rvm_start_t)
			rvm_val = max(0.0, rvm_val)
			var delta_val = GameState.total_zeros_found - rvm_val
			var delta_sign = "+" if delta_val >= 0 else ""

			if player.auto_walk_state == 1 or player.auto_walk_state == 2:
				if (T <= 5000.0 and abs(delta_val) >= 2.0) or abs(delta_val) >= 3.0:
					GameState.missed_zeta_zero = true
			else:
				GameState.missed_zeta_zero = false

			rvm_n_label.text = "[color=gray]N(t) ≈ [/color][color=#c8a96e]%.2f[/color]" % rvm_val
			if GameState.missed_zeta_zero:
				rvm_delta_label.text = "[right]Δ = %s[color=red]%.2f[/color][/right]" % [delta_sign, delta_val]
			else:
				rvm_delta_label.text = "[right]Δ = %s[color=#E8E4DC80]%.2f[/color][/right]" % [delta_sign, delta_val]

			rvm_hbox.visible = true
		else:
			rvm_hbox.visible = false

	var x = player.global_position.x
	var f = player.current_f

	# Update phase wheel
	phase_wheel.update_data(f)

	if position_arg_val.visible:
		update_arg_val(f)

	var complex_pos = Config.world_to_complex(x, z)
	var val_re = complex_pos.x
	var val_im = complex_pos.y
	var val_fx = f.x
	var val_fy = f.y

	var target_re = _format_float_3(val_fx)
	var target_im = _format_float_3(val_fy)

	var domain_re = _format_float_3(val_re)
	var domain_im = _format_float_3(val_im)

	target_val.text = _bb_re(target_re, ThemeColors.CLR_REAL) + _bb_im(target_im)
	domain_val.text = _bb_re(domain_re, ThemeColors.CLR_REAL) + _bb_im(domain_im)

	phase_abs_val.text = _format_float_3(f.length())


func _on_monitor_timer_timeout():
	if polynomial_debug:
		_update_polynomial_debug_str()

	if Config.show_hud_monitor_fps or show_hud_chunks or polynomial_debug:
		_update_monitor_label()

func _on_game_state_changed(key: String):
	if key in ["performance_protection_active", "height_protection_active", "out_of_bounds_teleport_active", "found_off_critical_line", "missed_zeta_zero", "unstable_zeta_computation"]:
		if key == "height_protection_active" and GameState.height_protection_active:
			_height_protection_timer = 5.0
			set_process(true)
		if key == "out_of_bounds_teleport_active" and GameState.out_of_bounds_teleport_active:
			_out_of_bounds_timer = 5.0
			set_process(true)
		if key == "unstable_zeta_computation" and GameState.unstable_zeta_computation:
			_unstable_zeta_timer = 5.0
			set_process(true)
		_update_monitor_label()
	elif key in ["visited_zeros", "total_zeros_found"]:
		_update_zeros_list()
	elif key == "current_branch":
		phase_branch_val.text = str(GameState.current_branch)
	elif key == "eta_patches":
		_update_polynomial_debug_str()
		_update_monitor_label()

func _update_polynomial_debug_str():
	if not polynomial_debug or not player or not Config.function_type in [Config.ComplexFunc.DIRICHLET_ETA_POWER_SERIES, Config.ComplexFunc.ZETA_POWER_SERIES] or ComplexField.eta_patches.is_empty():
		polynomial_debug_str = ""
		return

	var frame_z = Config.world_to_complex(player.global_position.x, player.global_position.z)
	var closest_patch = null
	var min_dist = 1e9

	for patch in ComplexField.eta_patches:
		var dist = (frame_z - patch["center"]).length()
		if dist < min_dist:
			min_dist = dist
			closest_patch = patch

	if closest_patch:
		var coeffs: Array = closest_patch["coeffs"]
		var new_str = "Patch center = (%.5f, %.5f)\n" % [closest_patch["center"].x, closest_patch["center"].y]
		for k in range(coeffs.size()):
			new_str += "%d: %.5f\n" % [k, coeffs[k].length()]
		polynomial_debug_str = new_str.strip_edges()
	else:
		polynomial_debug_str = ""

func _update_monitor_label():
	var show_height_protection = _height_protection_timer > 0.0
	var show_out_of_bounds = _out_of_bounds_timer > 0.0
	var show_unstable_zeta = _unstable_zeta_timer > 0.0

	var old_visible = monitor_panel.visible
	monitor_panel.visible = Config.show_hud_monitor_fps or show_hud_chunks or GameState.performance_protection_active or show_height_protection or show_out_of_bounds or show_unstable_zeta or GameState.found_off_critical_line or GameState.missed_zeta_zero or polynomial_debug

	if old_visible != monitor_panel.visible:
		_update_hud_layout()
	if monitor_panel.visible and monitor_rt_label:
		var bbcode = ""

		if polynomial_debug and polynomial_debug_str != "":
			bbcode += "[color=#e8e4dc73][font_size=14]%s[/font_size][/color]\n" % polynomial_debug_str

		if GameState.performance_protection_active:
			bbcode += "[color=#ffcc00][font_size=14]Performance protection activated, adjust settings.[/font_size][/color]\n"

		if show_height_protection:
			bbcode += "[color=#ffcc00][font_size=14]Max world height reached, return to safe heights.[/font_size][/color]\n"

		if show_out_of_bounds:
			bbcode += "[color=#ffcc00][font_size=14]Could not travel to out-of-bounds area.[/font_size][/color]\n"

		if GameState.found_off_critical_line:
			var off_z = GameState.found_off_critical_line_val
			var re_str = _format_float_3(off_z.x)
			var im_str = _format_float_3(off_z.y)
			var zero_str = _bb_re(re_str, ThemeColors.CLR_REAL) + _bb_im(im_str)
			bbcode += "[color=#ffcc00][font_size=14]Zero found off critical line (" + zero_str + "[color=#ffcc00]). Increase zeta iterations.[/color][/font_size]\n"

		if GameState.missed_zeta_zero:
			bbcode += "[color=#ffcc00][font_size=14]Zeta zeros diverging from Riemann-von Mangoldt.[/font_size][/color]\n"

		if show_unstable_zeta:
			bbcode += "[color=#ffcc00][font_size=14]Zeta computation is unstable at current iterations.[/font_size][/color]\n"

		if Config.show_hud_monitor_fps:
			bbcode += "[color=#ffffff]%d[/color] [color=#e8e4dc73][font_size=15]FPS[/font_size][/color]\n" % Engine.get_frames_per_second()

		if show_hud_chunks and world_manager:
			var chunks_text = "[color=#e8e4dc73][font_size=15]Chunks[/font_size][/color]"
			var num_lods = world_manager.LOD_SUBS.size()
			var lod_counts = []
			lod_counts.resize(num_lods)
			lod_counts.fill(0)

			for chunk in world_manager.chunks.values():
				var lod_val = chunk.get_instance_shader_parameter("lod_level")
				var lod = lod_val if lod_val != null else 0
				if lod >= 0 and lod < num_lods:
					lod_counts[lod] += 1

			for i in range(num_lods):
				if lod_counts[i] > 0:
					chunks_text += "\n[color=#e8e4dc73][font_size=15]%d: %d[/font_size][/color]" % [world_manager.LOD_SUBS[i], lod_counts[i]]
			bbcode += chunks_text + "\n"

		monitor_rt_label.text = bbcode.strip_edges()

func _update_function_labels():
	var symbol = Config.function.get("symbol", "f")
	if symbol.length() > 0:
		symbol = symbol[0]
	else:
		symbol = "f"
	target_label.text = symbol + "(s)"
	position_arg_label.text = "arg(" + symbol + ")"
	abs_label.text = "|" + symbol + "|"

func _update_zeros_list():
	var f_data = Config.function
	var total_count = GameState.total_zeros_found
	var current_size = GameState.visited_zeros.size()

	zeros_count_label.text = str(total_count)

	GameState.accented_zero_index = current_size - 1

	var actual_hud_scale = Config.hud_scale
	var children = zeros_list_label.get_children()
	var child_idx = 0

	var is_dirichlet = f_data.get("is_dirichlet", false)

	for i in range(current_size - 1, max(-1, current_size - 101), -1):
		var zero = GameState.visited_zeros[i]

		var item
		if child_idx < children.size():
			item = children[child_idx]
			item.visible = true
		else:
			item = ZERO_LIST_ITEM_SCENE.instantiate()
			zeros_list_label.add_child(item)
			item.clicked.connect(_on_zero_item_clicked)

		item.zero_index = i

		var needs_update = false
		if not item.has_meta("cached_zero") or item.get_meta("cached_zero") != zero:
			needs_update = true
		elif not item.has_meta("is_dirichlet") or item.get_meta("is_dirichlet") != is_dirichlet:
			needs_update = true

		if needs_update:
			var re_str = _format_float_3(zero[0])
			var im_str = _format_float_3(zero[1])
			item.set_values(re_str, im_str, is_dirichlet)
			item.set_meta("cached_zero", zero)
			item.set_meta("is_dirichlet", is_dirichlet)

		_rescale_card(item, actual_hud_scale)
		item.is_active = (i == GameState.accented_zero_index)

		child_idx += 1

	# Hide remaining unused items
	for i in range(child_idx, children.size()):
		children[i].visible = false

func _on_complex_aspect_resized():
	if phase_wheel.custom_minimum_size.y != phase_wheel.size.x:
		phase_wheel.custom_minimum_size.y = phase_wheel.size.x

func _on_minimap_resized():
	if minimap.custom_minimum_size.y != minimap.size.x:
		minimap.custom_minimum_size.y = minimap.size.x

func apply_aa():
	var vp = get_viewport()
	# Reset both
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	vp.use_taa = false
	vp.use_debanding = false

	match Config.antialiasing_mode:
		1: vp.msaa_3d = Viewport.MSAA_2X
		2: vp.msaa_3d = Viewport.MSAA_4X
		3: vp.msaa_3d = Viewport.MSAA_8X
		4: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		5: vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA

func toggle_menu(applied: bool = false):
	menu_overlay.toggle_menu(applied)

func _format_float_3(val: float) -> String:
	return "%.3f" % snappedf(val, 0.001)

func _get_rvm_n(T: float) -> float:
	if T <= 0.1:
		return 0.0

	# L-function for Dirichlet Beta has character modulo q = 4
	if Config.function_type == Config.ComplexFunc.DIRICHLET_BETA:
		# Riemann-von Mangoldt formula for Dirichlet L-functions:
		# N(T, chi) ≈ (T/2π) * log(qT/2πe)
		return (T / (2.0 * PI)) * (log((4.0 * T) / (2.0 * PI)) - 1.0)

	# Riemann-von Mangoldt formula for Zeta: N(T) ≈ (T/2π) log(T/2πe) + 7/8
	return (T / (2.0 * PI)) * (log(T / (2.0 * PI)) - 1.0) + 7.0 / 8.0

var _last_hud_state = {}

func _update_hud_layout():
	if not hud_columns: return

	var cards = [minimap_panel, position_panel, zeros_panel, monitor_panel]

	var actual_hud_scale = Config.hud_scale

	var scale_factor = get_viewport().size.x / 1920.0
	var available_height = get_viewport().size.y / scale_factor - 50.0

	if mobile_controls.visible and mobile_settings_btn.visible:
		available_height -= (mobile_settings_btn.position.y + mobile_settings_btn.size.y)

	var f_data = Config.function
	
	# Ensure elements are proactively rescaled BEFORE minimum heights are requested
	# This fixes the jitter during dynamic layout reflows when fonts and boxes haven't settled
	for card in cards:
		_rescale_card(card, actual_hud_scale)

	if hud_stack_right.custom_minimum_size.x != BASE_HUD_PANEL_SIZE * actual_hud_scale:
		hud_stack_right.custom_minimum_size.x = BASE_HUD_PANEL_SIZE * actual_hud_scale
		hud_stack_left.custom_minimum_size.x = BASE_HUD_PANEL_SIZE * actual_hud_scale

	var current_state = {
		"size": get_viewport().size,
		"scale": Config.hud_scale,
		"visibility": cards.map(func(c): return c.visible),
		"available_height": available_height,
		"zeros_count": GameState.visited_zeros.size(),
		"show_rvm": Config.show_rvm and f_data.get("has_von_mangoldt", false),
		"show_fps": Config.show_hud_monitor_fps,
		"show_chunks": show_hud_chunks,
		"is_multivalued": f_data.get("is_multivalued", false),
		"cards_heights": cards.map(func(c): return c.get_combined_minimum_size().y if c.visible else 0.0)
	}

	if current_state.hash() == _last_hud_state.hash():
		return

	_last_hud_state = current_state

	var current_height = 0.0
	var separation = 10.0

	var right_cards = []
	var left_cards = []
	var right_stack_full = false

	for card in cards:
		if not card.visible: continue
		var card_height = card.get_combined_minimum_size().y
		if not right_stack_full and current_height + card_height <= available_height:
			right_cards.push_back(card)
			current_height += card_height + separation
		else:
			right_stack_full = true
			left_cards.push_back(card)

	_apply_stack_layout(hud_stack_right, right_cards)
	_apply_stack_layout(hud_stack_left, left_cards)

	hud_stack_right.add_theme_constant_override("separation", 10)
	hud_stack_left.add_theme_constant_override("separation", 10)

	for card in cards:
		card.reset_size()
	hud_stack_right.reset_size()
	hud_stack_left.reset_size()

func _apply_stack_layout(stack: VBoxContainer, desired_cards: Array):
	for child in stack.get_children():
		if not child in desired_cards:
			stack.remove_child(child)
			add_child(child)

	for i in range(desired_cards.size()):
		var target_index = i
		var card = desired_cards[desired_cards.size() - 1 - i]
		if card.get_parent() != stack:
			if card.get_parent():
				card.get_parent().remove_child(card)
			stack.add_child(card)

		if card.get_index() != target_index:
			stack.move_child(card, target_index)

func _rescale_card(card: Control, _scale: float):
	if card == null: return

	if card.has_meta("last_applied_scale") and card.get_meta("last_applied_scale") == _scale:
		return
	card.set_meta("last_applied_scale", _scale)

	var stack = [card]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is Label:
			if not node.has_meta("base_font_size"):
				var fs = node.get("theme_override_font_sizes/font_size")
				if fs == null or fs == 0:
					fs = node.get_theme_font_size("font_size")
				node.set_meta("base_font_size", fs)
			node.add_theme_font_size_override("font_size", int(round(node.get_meta("base_font_size") * _scale)))
		elif node is RichTextLabel:
			if not node.has_meta("base_font_size"):
				var fs = node.get("theme_override_font_sizes/normal_font_size")
				if fs == null or fs == 0:
					fs = node.get_theme_font_size("normal_font_size")
				node.set_meta("base_font_size", fs)
			node.add_theme_font_size_override("normal_font_size", int(round(node.get_meta("base_font_size") * _scale)))

		if node is Control:
			# Only scale custom minimum size for specific panels to maintain layout proportions
			if node.name == "ComplexAspect" or node.name == "MinimapAspect" or node.name == "PhaseWheel":
				pass
			elif node.name == "PositionPanel":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", node.custom_minimum_size)
				node.custom_minimum_size.y = node.get_meta("base_min_size").y * _scale
			elif node.name == "ZerosScroll":
				var font_size = int(round(14.0 * _scale))
				var font_height = NEON_FONT.get_height(font_size)
				# StyleBoxFlat margins: content_margin_top (4.0) + content_margin_bottom (4.0) = 8.0
				var item_height = font_height + 8.0
				var separation = 2.0
				node.custom_minimum_size.y = 5.0 * item_height + 4.0 * separation
			elif node.name.begins_with("ZeroListItem"):
				pass
			elif node.name == "RvmNLabel" or node.name == "RvmDeltaLabel":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", node.custom_minimum_size)
				node.custom_minimum_size.x = node.get_meta("base_min_size").x * _scale

			# Keep container separations and margins constant at their original design values
			if node is BoxContainer:
				if not node.has_meta("base_separation"):
					node.set_meta("base_separation", node.get_theme_constant("separation"))
				node.add_theme_constant_override("separation", node.get_meta("base_separation"))
			elif node is MarginContainer:
				for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
					if not node.has_meta("base_" + margin):
						var val = node.get("theme_override_constants/" + margin)
						if val == null:
							val = node.get_theme_constant(margin)
						node.set_meta("base_" + margin, val)
					node.add_theme_constant_override(margin, node.get_meta("base_" + margin))

		for child in node.get_children():
			if child is Control:
				stack.push_back(child)


func play_portal_flash():
	if not portal_flash:
		return
	
	# Stop any running tween on portal_flash
	var active_tween = portal_flash.get_meta("tween", null)
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		
	portal_flash.visible = true
	portal_flash.color = Color(0.0, 0.8, 1.0, 0.25) # Start with 25% opacity cyan
	
	var tween = create_tween()
	portal_flash.set_meta("tween", tween)
	
	# Fade out over 0.25 seconds
	tween.tween_property(portal_flash, "color:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): portal_flash.visible = false)


func _format_time(total_seconds: float) -> String:
	var hours = int(total_seconds) / 3600.0
	var minutes = (int(total_seconds) % 3600) / 60.0
	var seconds = int(total_seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]


func _slider_to_zoom(value: float) -> float:
	var min_zoom = 0.01
	var max_zoom = 200.0
	var b = (log(max_zoom) - log(min_zoom)) / 100.0
	return exp(log(min_zoom) + value * b)


func _zoom_to_slider(zoom: float) -> float:
	var min_zoom = 0.01
	var max_zoom = 200.0
	var b = (log(max_zoom) - log(min_zoom)) / 100.0
	return (log(zoom) - log(min_zoom)) / b

func _on_config_changed(key: String):
	if key == "rendering_scale":
		get_viewport().scaling_3d_scale = Config.rendering_scale
	if key == "function_type":
		_update_zeros_list()
		_setup_branch_data()
		_update_function_labels()
	if key == "show_hud_navigation":
		position_panel.visible = Config.show_hud_navigation
	if key == "show_minimap":
		minimap_panel.visible = Config.show_minimap
	if key == "show_hud_zeros":
		zeros_panel.visible = Config.show_hud_zeros
		_update_zeros_list()
	if key in ["show_hud_monitor_fps", "show_hud_chunks"]:
		_update_monitor_label()
	if key == "show_hud_phase_wheel":
		position_arg_container.visible = !Config.show_hud_phase_wheel
		phase_wheel.visible = Config.show_hud_phase_wheel
		if phase_wheel.visible:
			_on_complex_aspect_resized()
		phase_wheel.update_minimum_size()
		phase_wheel.get_parent().update_minimum_size()
		position_panel.update_minimum_size()
		position_panel.queue_sort()

	if key in ["function_type", "show_hud_navigation", "show_hud_phase_wheel", "show_minimap", "show_hud_zeros", "show_hud_monitor_fps", "show_hud_chunks"]:
		_update_hud_layout()

	if key == "zoom_factor":
		if abs(menu_overlay._slider_to_zoom(menu_overlay.zoom_slider.value) - Config.zoom_factor) > 0.001:
			menu_overlay.zoom_slider.value = menu_overlay._zoom_to_slider(Config.zoom_factor)
	if key == "day_time" and not Config.freeze_time:
		menu_overlay.day_time_slider.set_value_no_signal(Config.day_time)
		menu_overlay.day_time_slider.value_text = menu_overlay._format_time(Config.day_time)
		
func _on_zero_item_clicked(index: int):
	GameState.accented_zero_index = index
	for item in zeros_list_label.get_children():
		if item.visible:
			item.is_active = (item.zero_index == index)

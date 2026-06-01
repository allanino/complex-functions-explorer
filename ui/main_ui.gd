extends CanvasLayer
@export var player: Node3D
@onready var hud_columns = %MainUIColumns
@onready var hud_stack_left = %MainUIStackLeft
@onready var hud_stack_right = %MainUIStackRight
@onready var complex_panel = %ComplexAspect
@onready var info_panel = %InfoPanel
@onready var monitor_panel = %MonitorPanel
@onready var fps_label = %FpsLabel
@onready var complex_rect = %ComplexPlane
@onready var world_manager = get_node_or_null("../WorldManager")
@onready var domain_label = %DomainLabel
@onready var target_label = %TargetLabel
@onready var zeros_panel = %ZerosPanel
@onready var zeros_count_label = %CountLabel
@onready var rvm_label = %RvmLabel
@onready var zeros_list_label = %ListLabel
@onready var menu_overlay = %MenuOverlay
var portal_flash: ColorRect
@onready var tooltip_manager = %TooltipManager
@onready var detach_controller = %DetachOverlay
@onready var preset_controller = %PresetController
# New UI Node Paths
var current_scale = 2.0
var _last_zeros_visible: bool = false
const BASE_HUD_PANEL_SIZE: float = 190.0

func _ready():
	portal_flash = ColorRect.new()
	portal_flash.name = "PortalFlash"
	portal_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portal_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portal_flash.color = Color(0.0, 0.8, 1.0, 0.0) # Transparent cyan
	portal_flash.visible = false
	$Control.add_child(portal_flash)

	hud_columns.offset_top = -1000

	menu_overlay.apply_aa_signal.connect(apply_aa)
	menu_overlay.update_hud_layout_signal.connect(_update_hud_layout)


	if menu_overlay:
			menu_overlay.player = player
	menu_overlay.detach_controller = detach_controller
	menu_overlay.preset_controller = preset_controller
	menu_overlay.world_manager = world_manager
	menu_overlay.tooltip_manager = tooltip_manager

	_last_zeros_visible = Config.show_hud_zeros


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

func _process(_delta):
	if Config.show_hud_zeros and not _last_zeros_visible:
		Config.rvm_start_t = abs(player.global_position.z * 0.1 / Config.effective_zoom)
	_last_zeros_visible = Config.show_hud_zeros


	if menu_overlay.visible:
		if abs(menu_overlay._slider_to_zoom(menu_overlay.zoom_slider.value) - Config.zoom_factor) > 0.001:
			menu_overlay.zoom_slider.value = menu_overlay._zoom_to_slider(Config.zoom_factor)

		# Live update speed and height inputs as they change smoothly with zoom
		if not menu_overlay._speed_modified and not menu_overlay.speed_input.has_focus():
			var formatted_speed = "%.1f" % (Config.movement_speed * 0.1)
			if menu_overlay.speed_input.text != formatted_speed:
				menu_overlay.speed_input.text = formatted_speed

		if not menu_overlay._camera_height_modified and not menu_overlay.camera_height_input.has_focus():
			var formatted_height = _format_float_3(Config.camera_height)
			if menu_overlay.camera_height_input.text != formatted_height:
				menu_overlay.camera_height_input.text = formatted_height

		# Live update time slider if time is flowing
		if not Config.freeze_time:
			menu_overlay.day_time_slider.value = Config.day_time
			menu_overlay.day_time_slider.value_text = menu_overlay._format_time(Config.day_time)

	menu_overlay.perf_label.visible = Config.performance_protection_active

	if not player:
		return

	var x = player.global_position.x
	var z = player.global_position.z

	var f = player.current_f

	# Update Zeta Zeros display
	var f_data = Config.function
	zeros_panel.visible = Config.show_hud_zeros

	if Config.show_hud_zeros:
		var total_count = Config.visited_zeros.size()
		var last_zeros_text = ""
		var zero = Vector2(0.0, 0.0)

		# Show all visited zeros in the scrolling list
		for i in range(total_count - 1, -1, -1):
			zero = Config.visited_zeros[i]
			last_zeros_text += "(%s, %s)\n" % [_format_float_3(zero[0]), _format_float_3(zero[1])]

		zeros_count_label.text = "Count: %d" % total_count

		# Riemann-von Mangoldt formula: N(T) ≈ (T/2π) log(T/2πe) + 7/8
		if Config.show_rvm and f_data.get("has_von_mangoldt", false):
			var T = abs(z * 0.1 / Config.effective_zoom)
			var val = _get_rvm_n(T) - _get_rvm_n(Config.rvm_start_t)
			val = max(0.0, val)
			rvm_label.text = "N(t) ≈ %.2f" % val
			rvm_label.visible = true
		else:
			rvm_label.visible = false

		zeros_list_label.text = last_zeros_text

	# Update shader uniforms
	var material = complex_rect.material as ShaderMaterial
	material.set_shader_parameter("current_f", f)
	material.set_shader_parameter("multivalued_n", Config.multivalued_n)
	material.set_shader_parameter("function_type", Config.function_type)
	material.set_shader_parameter("color_scheme", Config.color_scheme)
	material.set_shader_parameter("scale", current_scale)
	material.set_shader_parameter("performance_protection_active", Config.performance_protection_active)
	material.set_shader_parameter("brightness", Config.terrain_brightness)
	material.set_shader_parameter("saturation", Config.terrain_saturation)
	material.set_shader_parameter("albedo", Config.terrain_albedo)
	material.set_shader_parameter("emission", Config.terrain_emission)

	var scale_factor = 1.0 / Config.effective_zoom
	var val_re = x * 0.1 * scale_factor
	var val_im = -z * 0.1 * scale_factor
	var val_fx = f.x
	var val_fy = f.y

	domain_label.text = "Re = %s\nIm = %s" % [_format_float_3(val_re), _format_float_3(val_im)]
	var target_text = "Re = %s\nIm = %s\n|f| = %s" % [_format_float_3(val_fx), _format_float_3(val_fy), _format_float_3(f.length())]
	if f_data.get("is_multivalued", false):
		target_text += "\nBranch k = %d" % Config.current_branch
	target_label.text = target_text

	complex_panel.visible = Config.show_hud_complex
	info_panel.visible = Config.show_hud_navigation
	monitor_panel.visible = Config.show_hud_monitor_fps or Config.show_hud_monitor_chunks
	if monitor_panel.visible:
		var parts = []
		if Config.show_hud_monitor_fps:
			parts.append("FPS: %d" % Engine.get_frames_per_second())
		if Config.show_hud_monitor_chunks and world_manager:
			var chunks_text = "Chunks"
			var num_lods = world_manager.LOD_SUBS.size()
			var lod_counts = []
			lod_counts.resize(num_lods)
			lod_counts.fill(0)

			for chunk in world_manager.chunks.values():
				var lod = chunk.get_meta("lod_level", 0)
				if lod >= 0 and lod < num_lods:
					lod_counts[lod] += 1

			for i in range(num_lods):
				if lod_counts[i] > 0:
					chunks_text += "\n%d: %d" % [world_manager.LOD_SUBS[i], lod_counts[i]]
			parts.append(chunks_text)

		fps_label.text = "\n\n".join(parts)

	_update_hud_layout()

var _last_hud_state = {}

func _update_hud_layout():
	if not hud_columns: return

	var cards = [complex_panel, info_panel, monitor_panel, zeros_panel, menu_overlay.perf_label]

	var actual_hud_scale = Config.hud_scale

	# Always rescale all cards to ensure their combined_minimum_size is correct for height check
	for card in cards:
		_rescale_card(card, actual_hud_scale)

	var current_state = {
		"size": get_viewport().size,
		"scale": Config.hud_scale,
		"visibility": cards.map(func(c): return c.visible)
	}

	if current_state.hash() == _last_hud_state.hash():
		return
	_last_hud_state = current_state

	# Scale stack widths to accommodate wider fonts
	hud_stack_right.custom_minimum_size.x = BASE_HUD_PANEL_SIZE * actual_hud_scale
	hud_stack_left.custom_minimum_size.x = BASE_HUD_PANEL_SIZE * actual_hud_scale

	var available_height = get_viewport().size.y - 40
	var current_height = 0.0
	var separation = 10.0

	var right_cards = []
	var left_cards = []

	for card in cards:
		if not card.visible: continue
		var card_height = card.get_combined_minimum_size().y
		if current_height + card_height <= available_height:
			right_cards.push_back(card)
			current_height += card_height + separation
		else:
			left_cards.push_back(card)

	_apply_stack_layout(hud_stack_right, right_cards)
	_apply_stack_layout(hud_stack_left, left_cards)

	hud_stack_right.add_theme_constant_override("separation", 10)
	hud_stack_left.add_theme_constant_override("separation", 10)

func _apply_stack_layout(stack: VBoxContainer, desired_cards: Array):
	for child in stack.get_children():
		if not child in desired_cards:
			stack.remove_child(child)
			add_child(child)

	# Optimization: The original code moved each card to index 0 in forward order,
	# which inverted the final display order. By iterating backwards through the
	# desired_cards array, we can safely target absolute indices (0 to N-1) as we build
	# the stack from top to bottom. This ensures `move_child` operates within valid
	# index bounds even when new cards are being added, and eliminates redundant moves.
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
				node.set_meta("base_font_size", node.get_theme_font_size("font_size"))
			node.add_theme_font_size_override("font_size", int(round(node.get_meta("base_font_size") * _scale)))
		elif node is RichTextLabel:
			if not node.has_meta("base_font_size"):
				node.set_meta("base_font_size", node.get_theme_font_size("normal_font_size"))
			node.add_theme_font_size_override("normal_font_size", int(round(node.get_meta("base_font_size") * _scale)))

		if node is Control:
			# Only scale custom minimum size for specific panels to maintain layout proportions
			if node.name == "ComplexAspect":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", Vector2(BASE_HUD_PANEL_SIZE, BASE_HUD_PANEL_SIZE))
				node.custom_minimum_size = node.get_meta("base_min_size") * _scale
			elif node.name == "ZerosPanel" or node.name == "InfoPanel":
				if not node.has_meta("base_min_size"):
					node.set_meta("base_min_size", node.custom_minimum_size)
				node.custom_minimum_size.y = node.get_meta("base_min_size").y * _scale

			# Keep container separations and margins constant at their original design values
			if node is BoxContainer:
				if not node.has_meta("base_separation"):
					node.set_meta("base_separation", node.get_theme_constant("separation"))
				node.add_theme_constant_override("separation", node.get_meta("base_separation"))
			elif node is MarginContainer:
				for margin in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
					if not node.has_meta("base_" + margin):
						node.set_meta("base_" + margin, node.get_theme_constant(margin))
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

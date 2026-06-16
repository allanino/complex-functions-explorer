extends Node

@onready var main_ui = get_parent()

@onready var preset_button = %MenuOverlay/%PresetButton
@onready var preset_update_button = %MenuOverlay/%PresetUpdateButton
@onready var preset_delete_button = %MenuOverlay/%PresetDeleteButton
@onready var preset_new_button = %MenuOverlay/%PresetNewButton
@onready var preset_restore_button = %MenuOverlay/%PresetRestoreButton

@onready var new_preset_dialog = %MenuOverlay/%NewPresetDialog
@onready var new_preset_input = %MenuOverlay/%NewPresetInput
@onready var new_preset_save = %MenuOverlay/%NewPresetSave
@onready var new_preset_cancel = %MenuOverlay/%NewPresetCancel

@onready var delete_preset_dialog = %MenuOverlay/%DeletePresetDialog
@onready var delete_preset_cancel = %MenuOverlay/%DeletePresetCancel
@onready var delete_preset_confirm = %MenuOverlay/%DeletePresetConfirm
@onready var delete_message_label = %MenuOverlay/%DeleteMessageLabel

func _ready():
	_populate_preset_button()
	preset_button.item_selected.connect(_on_preset_selected)
	Config.preset_applied.connect(_on_preset_applied)

	preset_update_button.pressed.connect(_on_preset_update_pressed)
	preset_delete_button.pressed.connect(_on_preset_delete_pressed)
	preset_new_button.pressed.connect(_on_preset_new_pressed)
	preset_restore_button.pressed.connect(_on_preset_restore_pressed)

	new_preset_save.pressed.connect(_on_new_preset_save_pressed)
	new_preset_cancel.pressed.connect(_on_new_preset_cancel_pressed)
	delete_preset_cancel.pressed.connect(_on_delete_preset_cancel_pressed)
	delete_preset_confirm.pressed.connect(_on_delete_preset_confirm_pressed)

	if not main_ui.is_node_ready():
		await main_ui.ready

	_connect_preset_dirtiers()
	update_preset_button_text()

func _on_preset_update_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	if preset_name in ["Default", "Mysterious"]:
		new_preset_dialog.visible = true
		new_preset_input.text = preset_name + " Copy"
		new_preset_input.grab_focus()
	else:
		Config.update_preset(preset_name)
		Config.current_preset = preset_name
		update_preset_button_text()

func _on_preset_delete_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	if preset_name in ["Default", "Mysterious"]:
		return
	delete_message_label.text = "Are you sure you want to delete the\npreset '" + preset_name + "'?"
	delete_preset_dialog.visible = true

func _on_delete_preset_cancel_pressed():
	delete_preset_dialog.visible = false

func _on_delete_preset_confirm_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	if Config.PRESETS.has(preset_name):
		Config.delete_preset(preset_name)

		_populate_preset_button()

		if Config.PRESETS.size() > 0:
			var new_preset = Config.PRESETS.keys()[0]
			Config.apply_preset(new_preset)
		else:
			Config.current_preset = "Custom"
			update_preset_button_text()
	delete_preset_dialog.visible = false

func _on_preset_new_pressed():
	new_preset_dialog.visible = true
	new_preset_input.text = ""
	new_preset_input.grab_focus()

func _on_new_preset_cancel_pressed():
	new_preset_dialog.visible = false

func _on_new_preset_save_pressed():
	var preset_name = new_preset_input.text.strip_edges()
	if preset_name != "":
		Config.update_preset(preset_name)
		_populate_preset_button()
		Config.apply_preset(preset_name)
	new_preset_dialog.visible = false

func _populate_preset_button():
	var built_in_keys = Config.PRESET_DEFAULTS.PRESETS.keys()
	preset_button.clear()
	for p_name in Config.PRESETS.keys():
		if not built_in_keys.has(p_name):
			preset_button.add_item(p_name)
	for p_name in Config.PRESETS.keys():
		if built_in_keys.has(p_name):
			preset_button.add_item(p_name)

func _on_preset_selected(index: int):
	var preset_name = preset_button.get_item_text(index).trim_suffix("*")
	Config.apply_preset(preset_name)

func _on_preset_applied():
	main_ui.menu_overlay._sync_ui_to_config()
	update_preset_button_text()

func _on_preset_restore_pressed():
	var preset_name = Config.current_preset.trim_suffix("*")
	Config.restore_preset(preset_name)
	main_ui.menu_overlay._on_set_pos_pressed(false)

func _connect_preset_dirtiers():
	var on_changed = func(_val = null):
		if not main_ui.menu_overlay._syncing_ui:
			update_preset_button_text()

	# Connect sliders
	for slider in [
		main_ui.menu_overlay.iter_slider, main_ui.menu_overlay.zero_proximity_nav_slider, main_ui.menu_overlay.zoom_slider, main_ui.menu_overlay.zero_speed_slider,
		main_ui.menu_overlay.view_distance_slider, main_ui.menu_overlay.day_duration_slider, main_ui.menu_overlay.day_time_slider, main_ui.menu_overlay.sunrise_slider,
		main_ui.menu_overlay.sky_luminosity_slider, main_ui.menu_overlay.sun_luminosity_slider, main_ui.menu_overlay.self_illumination_slider,
		main_ui.menu_overlay.fog_density_slider, main_ui.menu_overlay.hud_scale_slider, main_ui.menu_overlay.master_volume_slider, main_ui.menu_overlay.bg_music_slider,
		main_ui.menu_overlay.drone_slider, main_ui.menu_overlay.brightness_slider, main_ui.menu_overlay.saturation_slider, main_ui.menu_overlay.albedo_slider,
		main_ui.menu_overlay.emission_slider, main_ui.menu_overlay.metallic_slider, main_ui.menu_overlay.roughness_slider, main_ui.menu_overlay.surface_texture_slider, main_ui.menu_overlay.ao_slider, main_ui.menu_overlay.rim_slider, main_ui.menu_overlay.rim_tint_slider,
		main_ui.menu_overlay.multivalued_slider, main_ui.menu_overlay.camera_height_slider, main_ui.menu_overlay.speed_slider
	]:
		if slider and slider.has_signal("value_changed"):
			slider.value_changed.connect(on_changed)

	# Connect checkboxes
	for cb in [
		main_ui.menu_overlay.curves_checkbox, main_ui.menu_overlay.critical_checkbox, main_ui.menu_overlay.flow_checkbox, main_ui.menu_overlay.hud_phase_wheel_checkbox,
		main_ui.menu_overlay.hud_position_checkbox, main_ui.menu_overlay.hud_zeros_checkbox, main_ui.menu_overlay.rvm_checkbox,
		main_ui.menu_overlay.hud_monitor_fps_checkbox, main_ui.menu_overlay.shadows_checkbox,
		main_ui.menu_overlay.auto_walk_checkbox, main_ui.menu_overlay.freeze_time_checkbox
	]:
		if cb and cb.has_signal("toggled"):
			cb.toggled.connect(on_changed)

	# Connect buttons/option buttons
	for ob in [main_ui.menu_overlay.func_button, main_ui.menu_overlay.height_button, main_ui.menu_overlay.terrain_detail_button, main_ui.menu_overlay.aa_button, main_ui.menu_overlay.color_scheme_button]:
		if ob and ob.has_signal("item_selected"):
			ob.item_selected.connect(on_changed)

	# Connect line edits
	for le in [main_ui.menu_overlay.height_a_input, main_ui.menu_overlay.height_eps_input]:
		if le and le.has_signal("text_submitted"):
			le.text_submitted.connect(on_changed)

func update_preset_button_text():
	var preset_name = Config.current_preset.trim_suffix("*")
	var is_dirty = Config.is_preset_dirty()

	Config.current_preset = preset_name + "*" if is_dirty else preset_name

	for i in range(preset_button.item_count):
		var item_clean_name = preset_button.get_item_text(i).trim_suffix("*")
		var item_dirty = Config.is_preset_dirty_by_name(item_clean_name)
		if item_dirty:
			preset_button.set_item_text(i, item_clean_name + "*")
		else:
			preset_button.set_item_text(i, item_clean_name)

	var selected_idx = -1
	for i in range(preset_button.item_count):
		var item_clean_name = preset_button.get_item_text(i).trim_suffix("*")
		if item_clean_name == preset_name:
			selected_idx = i
			break

	if selected_idx != -1:
		preset_button.select(selected_idx)

	preset_update_button.disabled = not is_dirty
	preset_restore_button.disabled = not is_dirty

	if preset_name in ["Default", "Mysterious"]:
		preset_delete_button.disabled = true
	else:
		preset_delete_button.disabled = false

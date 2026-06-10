extends Node

signal state_changed(key: String)

# Session state (not saved)
var visited_zeros: Array[Vector2] = []
var total_zeros_found: int = 0:
	set(v):
		if total_zeros_found == v: return
		total_zeros_found = v
		state_changed.emit("total_zeros_found")
var accented_zero_index: int = -1:
	set(v):
		if accented_zero_index == v: return
		accented_zero_index = v
		state_changed.emit("accented_zero_index")

var rvm_start_t: float = 0.0
var performance_protection_active: bool = false:
	set(v):
		if performance_protection_active == v: return
		performance_protection_active = v
		state_changed.emit("performance_protection_active")
var is_menu_open: bool = false
var height_protection_active: bool = false:
	set(v):
		if height_protection_active == v: return
		height_protection_active = v
		state_changed.emit("height_protection_active")
var missed_zeta_zero: bool = false:
	set(v):
		if missed_zeta_zero == v: return
		missed_zeta_zero = v
		state_changed.emit("missed_zeta_zero")
var found_off_critical_line: bool = false:
	set(v):
		if found_off_critical_line == v: return
		found_off_critical_line = v
		state_changed.emit("found_off_critical_line")
var found_off_critical_line_val: Vector2 = Vector2.ZERO:
	set(v):
		if found_off_critical_line_val == v: return
		found_off_critical_line_val = v
		state_changed.emit("found_off_critical_line_val")
var effective_zoom: float = 1.0:
	set(v):
		if effective_zoom == v: return
		effective_zoom = v
		state_changed.emit("effective_zoom")
var morph_value: float = 1.0:
	set(v):
		if morph_value == v: return
		morph_value = v
		state_changed.emit("morph_value")
var newton_path: PackedVector2Array = PackedVector2Array():
	set(v):
		newton_path = v
		state_changed.emit("newton_path")
var newton_path_bbox: Vector4 = Vector4(0, 0, 0, 0):
	set(v):
		if newton_path_bbox == v: return
		newton_path_bbox = v
		state_changed.emit("newton_path_bbox")
var current_branch: int = 0:
	set(v):
		if current_branch == v: return
		current_branch = v
		state_changed.emit("current_branch") # Session state for Portals mode

var real_level_curves_highlighted: Array[float] = []:
	set(v):
		real_level_curves_highlighted = v
		state_changed.emit("real_level_curves_highlighted")
var imag_level_curves_highlighted: Array[float] = []:
	set(v):
		imag_level_curves_highlighted = v
		state_changed.emit("imag_level_curves_highlighted")

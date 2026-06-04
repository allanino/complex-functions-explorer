extends Node

signal state_changed(key: String)

func _set_state(field_name: String, value: Variant):
	var current = get(field_name)
	if typeof(current) == TYPE_ARRAY or typeof(current) >= TYPE_PACKED_BYTE_ARRAY and typeof(current) <= TYPE_PACKED_COLOR_ARRAY:
		set(field_name, value)
		state_changed.emit(field_name)
		return

	if current == value:
		return
	set(field_name, value)
	state_changed.emit(field_name)

# Session state (not saved)
var visited_zeros: Array[Vector2] = []
var total_zeros_found: int = 0
var rvm_start_t: float = 0.0
var performance_protection_active: bool = false
var effective_zoom: float = 1.0
var morph_value: float = 1.0: set(v): _set_state("morph_value", v)
var newton_path: PackedVector2Array = PackedVector2Array(): set(v): _set_state("newton_path", v)
var newton_path_bbox: Vector4 = Vector4(0, 0, 0, 0): set(v): _set_state("newton_path_bbox", v)
var current_branch: int = 0: set(v): _set_state("current_branch", v) # Session state for Portals mode

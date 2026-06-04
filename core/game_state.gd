extends Node

signal state_changed(key: String, value: Variant)

# Session state (not saved)
var visited_zeros: Array[Vector2] = []:
	set(v):
		visited_zeros = v
		state_changed.emit("visited_zeros", v)
var total_zeros_found: int = 0:
	set(v):
		total_zeros_found = v
		state_changed.emit("total_zeros_found", v)
var rvm_start_t: float = 0.0:
	set(v):
		rvm_start_t = v
		state_changed.emit("rvm_start_t", v)
var performance_protection_active: bool = false:
	set(v):
		performance_protection_active = v
		state_changed.emit("performance_protection_active", v)
var effective_zoom: float = 1.0:
	set(v):
		effective_zoom = v
		state_changed.emit("effective_zoom", v)
var morph_value: float = 1.0:
	set(v):
		morph_value = v
		state_changed.emit("morph_value", v)
var newton_path: PackedVector2Array = PackedVector2Array():
	set(v):
		newton_path = v
		state_changed.emit("newton_path", v)
var newton_path_bbox: Vector4 = Vector4(0, 0, 0, 0):
	set(v):
		newton_path_bbox = v
		state_changed.emit("newton_path_bbox", v)
var current_branch: int = 0 # Session state for Portals mode:
	set(v):
		current_branch = v
		state_changed.emit("current_branch", v)

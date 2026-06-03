extends Node

# Session state (not saved)
var visited_zeros: Array[Vector2] = []
var total_zeros_found: int = 0
var rvm_start_t: float = 0.0
var performance_protection_active: bool = false
var effective_zoom: float = 1.0
var morph_value: float = 1.0
var newton_path: PackedVector2Array = PackedVector2Array()
var newton_path_bbox: Vector4 = Vector4(0, 0, 0, 0)
var current_branch: int = 0 # Session state for Portals mode

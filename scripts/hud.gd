extends CanvasLayer

@export var player: Node3D
@onready var complex_rect = $Control/ComplexPlane
@onready var pos_label = $Control/PosLabel

var current_scale = 2.0

func _process(_delta):
	if not player:
		return

	var x = player.global_position.x
	var z = player.global_position.z

	# Calculate f(x,z)
	var theta1 = 0.15 * x + 0.12 * z
	var theta2 = 0.31 * x - 0.27 * z

	var re = cos(theta1) + 0.5 * cos(theta2)
	var im = sin(theta1) + 0.5 * sin(theta2)

	var f = Vector2(re, im)

	# Update shader uniforms
	var material = complex_rect.material as ShaderMaterial
	material.set_shader_parameter("current_f", f)
	material.set_shader_parameter("scale", current_scale)

	pos_label.text = "Pos: (%.2f, %.2f)" % [x, z]

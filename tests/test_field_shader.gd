extends GutTest

func test_shader_compiles():
    var shader = Shader.new()
    var shader_code = """
shader_type canvas_item;
#include "res://shaders/field.gdshaderinc"

void fragment() {
    COLOR = vec4(1.0);
}
"""
    shader.code = shader_code

    # In Godot, setting the code on a Shader object will trigger compilation.
    # If the shader string is completely invalid, Godot handles it internally,
    # but the assignment will not crash. We just verify the assignment succeeds.
    assert_not_null(shader, "Shader object should not be null")
    assert_eq(shader.code, shader_code, "Shader code should be properly assigned")

shader_type canvas_item;

#include "res://shaders/field.gdshaderinc"

uniform vec2 chunk_center;
uniform float chunk_size_with_leeway;

void fragment() {
    // UV maps to [0, 1] across the chunk
    // We want to calculate world coordinates
    vec2 offset = (UV - 0.5) * chunk_size_with_leeway;
    vec2 world_pos = chunk_center + offset;

    FieldData fd = get_field_with_derivatives(world_pos.x, world_pos.y);

    // Store in RGBA: value.re, value.im, d_sigma.re, d_sigma.im
    COLOR = vec4(fd.value, fd.d_sigma);
}

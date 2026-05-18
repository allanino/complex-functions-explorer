shader_type canvas_item;

#include "res://shaders/field.gdshaderinc"

uniform vec2 chunk_min;
uniform vec2 chunk_max;

void fragment() {
    vec2 world_xz = mix(chunk_min, chunk_max, UV);
    // Note: get_field_with_derivatives expects world x and z.
    FieldData fd = get_field_with_derivatives(world_xz.x, world_xz.y);

    // We store value in RG and d_sigma in BA.
    // d_t can be reconstructed as vec2(-d_sigma.y, d_sigma.x) for holomorphic functions.
    COLOR = vec4(fd.value, fd.d_sigma);
}

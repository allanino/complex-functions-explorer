shader_type spatial;

#include "res://shaders/field.gdshaderinc"

varying vec3 world_pos;
varying vec3 normal;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    float h = get_height(world_pos.x, world_pos.z);
    VERTEX.y += h;

    // Calculate normals using finite differences
    float delta = 0.01;
    float h_right = get_height(world_pos.x + delta, world_pos.z);
    float h_forward = get_height(world_pos.x, world_pos.z + delta);

    vec3 v_right = vec3(delta, h_right - h, 0.0);
    vec3 v_forward = vec3(0.0, h_forward - h, delta);

    // Normal is the cross product of two tangent vectors
    normal = normalize(cross(v_forward, v_right));
    NORMAL = (MODEL_NORMAL_MATRIX * normal);
}

void fragment() {
    float x = world_pos.x;
    float z = world_pos.z;

    vec2 f = get_field(x, z);

    float phase = atan(f.y, f.x);
    float hue = (phase + PI) / (2.0 * PI);

    vec3 base = hsv2rgb(vec3(hue, 0.7, 0.8));

    ALBEDO = base * 0.15;

    EMISSION = base * 0.25;
	ROUGHNESS = 0.12;
	METALLIC = 0.95;
	SPECULAR = 1.0;
}

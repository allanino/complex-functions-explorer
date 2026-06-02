shader_type fog;

uniform vec3 fog_color : source_color = vec3(0.5);
uniform float fog_density = 0.05;
uniform float fog_distance = 0.0;
uniform vec3 camera_pos = vec3(0.0);

void fog() {
    float dist = length(WORLD_POSITION - camera_pos);
    if (dist >= fog_distance) {
        DENSITY = fog_density;
    } else {
        DENSITY = 0.0;
    }
    ALBEDO = fog_color;
    EMISSION = fog_color * 0.1;
}

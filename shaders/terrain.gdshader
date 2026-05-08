shader_type spatial;

varying vec3 world_pos;
varying vec3 normal;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Function to calculate height at a given (x, z) coordinate
float get_height(float x, float z) {
    float theta1 = 0.15 * x + 0.12 * z;
    float theta2 = 0.31 * x - 0.27 * z;

    float re = cos(theta1) + 0.5 * cos(theta2);
    float im = sin(theta1) + 0.5 * sin(theta2);

    float mag = sqrt(re * re + im * im);
    return log(1.0 + mag);
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

    float theta1 = 0.15 * x + 0.12 * z;
    float theta2 = 0.31 * x - 0.27 * z;

    float re = cos(theta1) + 0.5 * cos(theta2);
    float im = sin(theta1) + 0.5 * sin(theta2);

    float phase = atan(im, re);
    float hue = (phase + PI) / (2.0 * PI);

    vec3 hsv = vec3(hue, 0.8, 0.9);
    ALBEDO = hsv2rgb(hsv);

    // Shining plastic look
    ROUGHNESS = 0.15;
    SPECULAR = 0.5;
    METALLIC = 0.0;
}

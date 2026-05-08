// Shared field and height functions for shaders

vec2 get_field(float x, float z) {
    float theta1 = 0.15 * x + 0.12 * z;
    float theta2 = 0.31 * x - 0.27 * z;

    float re = cos(theta1) + 0.5 * cos(theta2);
    float im = sin(theta1) + 0.5 * sin(theta2);

    return vec2(re, im);
}

float get_height(float x, float z) {
    vec2 f = get_field(x, z);
    float mag = length(f);
    return log(1.0 + mag);
}

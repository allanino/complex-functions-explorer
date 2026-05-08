shader_type spatial;

varying vec3 world_pos;

// Helper function to convert HSV to RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void vertex() {
    // world_pos is used to calculate the field consistently across chunks
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    float x = world_pos.x;
    float z = world_pos.z;

    // Mathematical field:
    // f(x,z) = exp(i*(0.15*x + 0.12*z)) + 0.5*exp(i*(0.31*x - 0.27*z))
    // Using Euler's formula: exp(i*theta) = cos(theta) + i*sin(theta)

    float theta1 = 0.15 * x + 0.12 * z;
    float theta2 = 0.31 * x - 0.27 * z;

    // Real and Imaginary parts of f(x,z)
    float re = cos(theta1) + 0.5 * cos(theta2);
    float im = sin(theta1) + 0.5 * sin(theta2);

    // Magnitude |f| = sqrt(re^2 + im^2)
    float mag = sqrt(re * re + im * im);

    // Height = log(1 + |f|)
    float height = log(1.0 + mag);

    // Apply displacement
    VERTEX.y += height;
}

void fragment() {
    float x = world_pos.x;
    float z = world_pos.z;

    float theta1 = 0.15 * x + 0.12 * z;
    float theta2 = 0.31 * x - 0.27 * z;

    float re = cos(theta1) + 0.5 * cos(theta2);
    float im = sin(theta1) + 0.5 * sin(theta2);

    // Complex phase (argument) of f(x,z)
    // atan2(im, re) returns phase in range [-PI, PI]
    float phase = atan(im, re);

    // Map phase to [0, 1] for HSV hue
    float hue = (phase + PI) / (2.0 * PI);

    // Color based on complex phase
    vec3 hsv = vec3(hue, 0.8, 0.9);
    ALBEDO = hsv2rgb(hsv);
    ROUGHNESS = 0.5;
}

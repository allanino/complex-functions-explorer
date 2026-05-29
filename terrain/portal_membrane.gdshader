shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled;

void fragment() {
    float fresnel = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
    float fresnel_pow = pow(fresnel, 3.0);

    float phase = fresnel * 5.0 + TIME * 1.5;
    vec3 color = vec3(
        0.6 + 0.4 * sin(phase),
        0.6 + 0.4 * sin(phase + 2.094),
        0.6 + 0.4 * sin(phase + 4.188)
    );

    // Very subtle
    float alpha = fresnel_pow * 0.3;

    ALBEDO = color;
    ALPHA = alpha;
}

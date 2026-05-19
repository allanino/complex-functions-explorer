shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, billboard_keep_scale;

uniform vec3 sun_direction = vec3(0.0, -1.0, 0.0); // World space Sun -> World
uniform float player_height = 0.0;

void vertex() {
    // Size variation at sunset
    float sunset = clamp(1.0 + sun_direction.y, 0.0, 1.0);
    float size_mult = mix(1.0, 2.0, sunset);
    MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(size_mult, 0.0, 0.0, 0.0), vec4(0.0, size_mult, 0.0, 0.0), vec4(0.0, 0.0, size_mult, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
    // Procedural soft circle
    float dist = length(UV - 0.5);
    float circle = smoothstep(0.5, 0.1, dist);

    // Forward scattering (glow when looking toward sun)
    vec3 sun_view = (VIEW_MATRIX * vec4(sun_direction, 0.0)).xyz;
    // VIEW is pixel to camera. Look direction is -VIEW.
    // sun_view is Sun to World. Direction to sun is -sun_view.
    // We want dot(-VIEW, -sun_view) = dot(VIEW, sun_view)
    float scattering = pow(max(dot(VIEW, sun_view), 0.0), 8.0);

    // Height-based density: more dust in valleys
    float density = exp(-player_height * 0.02);

    // Sunset factor: increase atmospheric thickness at golden hour
    // sun_direction.y is -1.0 at noon, 0.0 at horizon
    float sunset = clamp(1.0 + sun_direction.y, 0.0, 1.0);
    float sunset_alpha_mult = mix(0.3, 1.0, sunset);

    ALBEDO = vec3(1.0, 0.95, 0.9);
    // Base opacity is very low
    ALPHA = circle * scattering * 0.08 * density * sunset_alpha_mult;
}

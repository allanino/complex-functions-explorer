shader_type fog;

void fog() {
	float x = WORLD_POSITION.x;
	float d = 0.0;

	if (x <= 0.0) {
		d = 1.0;
	} else if (x >= 10.0) {
		d = 0.2;
	}

	// Simple height falloff
	float height_fade = clamp(1.0 - (WORLD_POSITION.y - 10.0) * 0.1, 0.0, 1.0);

	DENSITY = d * height_fade;
	ALBEDO = vec3(0.2, 0.2, 0.25);
}

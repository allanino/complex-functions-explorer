shader_type fog;

uniform vec3 player_pos;

void fog() {
	if (WORLD_POSITION.x > 0.0) {
		DENSITY = 0.0;
	} else {
		// Base density for the entire x <= 0 region
		float d = 0.15;

		// Localized density around the player
		float dist = distance(WORLD_POSITION, player_pos);
		d += exp(-dist * 0.04) * 0.85;

		// Soft height falloff to keep the extreme upper sky clear
		float height_fade = smoothstep(500.0, 100.0, WORLD_POSITION.y);

		DENSITY = d * height_fade;
	}
	ALBEDO = vec3(0.2, 0.2, 0.25);
}

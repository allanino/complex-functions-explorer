shader_type fog;

uniform float start_dist = 100.0;
uniform float end_dist = 250.0;
uniform float max_density = 2.0;
uniform vec3 albedo : source_color = vec3(1.0);
uniform vec3 emission : source_color = vec3(0.0);

void fog() {
	// RELATIVE_POSITION is position relative to the FogVolume's center.
	// If we move the FogVolume with the player, this is distance from the player.
	float dist = length(RELATIVE_POSITION.xz);
	float d = smoothstep(start_dist, end_dist, dist);

	// Increase density as we get further away to hide chunk edges
	DENSITY = d * max_density;
	ALBEDO = albedo;
	EMISSION = emission;
}

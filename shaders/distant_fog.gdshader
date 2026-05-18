shader_type fog;

uniform float start_dist = 100.0;
uniform float end_dist = 250.0;
uniform float max_density = 2.0;
uniform vec3 albedo : source_color = vec3(1.0);
uniform vec3 emission : source_color = vec3(0.0);

void fog() {
	// UVW is the 3D texture coordinate within the FogVolume (0.0 to 1.0).
	// SIZE is the size of the FogVolume.
	// (UVW - 0.5) * SIZE gives the position relative to the volume center.
	vec3 rel_pos = (UVW - 0.5) * SIZE;
	float dist = length(rel_pos.xz);
	float d = smoothstep(start_dist, end_dist, dist);

	// Increase density as we get further away to hide chunk edges
	DENSITY = d * max_density;
	ALBEDO = albedo;
	EMISSION = emission;
}

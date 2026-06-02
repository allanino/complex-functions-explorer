extends Node3D

@onready var sun = $DirectionalLight3D
@onready var moon = $MoonLight
@onready var world_environment = $WorldEnvironment
@onready var fog_volume = $FogVolume

# Day night cycle variables
var _golden_hour_transition: float = 0.0
var _sun_color = Color("#fc9500")

func _process(delta):
	# Environment logic
	var night_factor = 0.0
	var sunrise_rad = deg_to_rad(Config.sunrise_direction - 180.0)
	# Orbit axis is perpendicular to sunrise vector (cos, 0, sin) and zenith (0, 1, 0)
	var orbit_axis = Vector3(sin(sunrise_rad), 0, -cos(sunrise_rad))

	var progress = 0.0
	if not Config.freeze_time: # Dynamic
		# Increment day time based on day duration
		# 86400 seconds in a day / day_duration = speed multiplier
		Config.day_time += delta * (86400.0 / Config.day_duration)
		if Config.day_time >= 86400.0:
			Config.day_time -= 86400.0

	progress = Config.day_time / 86400.0

	# angle = PI is Midnight (progress 0.0), angle = 0.0 is Noon (progress 0.5)
	var angle = (progress + 0.5) * TAU

	# Sun direction: rotate Noon (0, -1, 0) around orbit axis
	var sun_dir = Quaternion(orbit_axis, angle) * Vector3.DOWN
	var moon_dir = - sun_dir

	var sun_elevation = - sun_dir.y
	_golden_hour_transition = clamp((0.5 - sun_elevation) / 0.5, 0.0, 1.0)

	if sun_elevation < 0.0:
		night_factor = clamp(-sun_elevation / 0.3, 0.0, 1.0)
	else:
		night_factor = 0.0

	if sun:
		sun.basis = Basis.looking_at(sun_dir, Vector3.UP if abs(sun_dir.y) < 0.99 else Vector3.FORWARD)
		sun.light_energy = smoothstep(-0.02, 0.02, sun_elevation) * Config.sun_luminosity
		sun.light_color = lerp(_sun_color, Color(1.0, 0.5, 0.2), _golden_hour_transition)
		sun.shadow_enabled = Config.shadows_enabled and sun_elevation > 0.01
		sun.light_volumetric_fog_energy = 4.0 # Make volumetric rays shine beautifully

	if moon:
		moon.basis = Basis.looking_at(moon_dir, Vector3.UP if abs(moon_dir.y) < 0.99 else Vector3.FORWARD)
		var moon_elevation = - moon_dir.y
		moon.light_energy = smoothstep(-0.02, 0.02, moon_elevation) * 0.4 * Config.sun_luminosity
		moon.shadow_enabled = Config.shadows_enabled and moon_elevation > 0.01
		moon.light_volumetric_fog_energy = 2.0

	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("golden_hour_factor", _golden_hour_transition)
			sky_mat.set_shader_parameter("night_factor", night_factor)
			sky_mat.set_shader_parameter("sky_luminosity", Config.sky_luminosity)

		# Setup fog	
		var env = world_environment.environment
	
		var fog_color = lerp(Color(0.3, 0.4, 0.5), Color(1.0, 0.4, 0.1), _golden_hour_transition)
		fog_color = lerp(fog_color, Color(0.01, 0.02, 0.05), night_factor)

		env.fog_enabled = false
		env.volumetric_fog_enabled = Config.fog_density > 0.0
		env.volumetric_fog_density = 0.0 # Density provided by FogVolume
		env.volumetric_fog_albedo = fog_color
		env.volumetric_fog_sky_affect = (1.0 - Config.fog_density)
		env.volumetric_fog_length = 1000.0 # Make sure fog reaches far
		env.volumetric_fog_ambient_inject = 0.2 # So it's not pitch black in shadows

		if fog_volume and fog_volume.material:
			var mat = fog_volume.material as ShaderMaterial
			mat.set_shader_parameter("fog_color", fog_color)
			mat.set_shader_parameter("fog_density", Config.fog_density * 0.05)
			mat.set_shader_parameter("fog_distance", Config.fog_distance)
			var cam = get_viewport().get_camera_3d()
			if cam:
				mat.set_shader_parameter("camera_pos", cam.global_position)

func set_performance_protection(active: bool):
	if world_environment and world_environment.environment and world_environment.environment.sky:
		var sky_mat = world_environment.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("performance_protection_active", active)

extends Node3D

# --- CONSTANTS ---
const ZERO_PITCH_BOOST = 1.5
const BASE_FREQUENCY = 130.8 # C3 (Standard drone)
const REVERB_AMOUNT = 0.5
const PITCH_DEADZONE = 0.01
const TARGET_FILL = 4096

# --- SYNTHESIS STATE ---
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var _background_music_player: AudioStreamPlayer
@onready var _audio_stream_player = $AudioStreamPlayer
var phase: float = 0.0
var mod_phase: float = 0.0
var lfo_phase: float = 0.0
var pulse_phase: float = 0.0
var target_pulse_rate: float = 0.0
var current_pulse_rate: float = 0.0
var audio_fm_index: float = 0.0
var audio_pulse_presence: float = 0.0
var last_pitch: float = 10.0

# --- INTERPOLATED PARAMETERS ---
var target_volume: float = 0.3
var current_volume: float = 0.2
var target_frequency: float = BASE_FREQUENCY
var current_frequency: float = BASE_FREQUENCY
var target_pan: float = 0.0
var current_pan: float = 0.0
var target_harmonic_intensity: float = 0.0
var current_harmonic_intensity: float = 0.0
var target_fm_index: float = 0.0
var current_fm_index: float = 0.0
var pulse_presence: float = 0.0
var current_amp_l: float = 0.0
var current_amp_r: float = 0.0

var current_pitch_scale: float = 1.0
var current_reverb_wet: float = REVERB_AMOUNT
var current_lpf_cutoff: float = 800.0

# --- TELEPORT FADE STATE ---
var last_audio_player_pos := Vector3.ZERO
var has_last_pos := false
var teleport_fade: float = 1.0
var is_teleporting: bool = false

# --- STARTUP ENVELOPE ---
var startup_time := 0.0
var startup_duration := 5.0

# --- FPS GUARD ---
var low_fps_counter: int = 0
var stable_fps_counter: int = 0
var is_suppressed: bool = false

# --- EFFECT REFS ---
var pitch_shift_effect: AudioEffectPitchShift
var reverb_effect: AudioEffectReverb
var lpf_effect: AudioEffectLowPassFilter

var portal_sfx_player: AudioStreamPlayer
@onready var player: Node3D = get_tree().get_first_node_in_group("player")
var math_bus_index: int = -1
var master_bus_index: int = -1

# --- BUFFER DEBUG ---
var buffer_min_available := 999999
var buffer_max_available := 0

func _ready():
	Config.config_changed.connect(_on_config_changed)

	setup_audio_bus_and_effects()

	var stream_player = _audio_stream_player

	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.15

	stream_player.stream = generator

	# Get playback BEFORE starting
	stream_player.play()
	playback = stream_player.get_stream_playback()
	sample_rate = generator.mix_rate

	# Prefill silence
	var frames_to_fill = int(sample_rate * 0.15)

	for i in frames_to_fill:
		playback.push_frame(Vector2.ZERO)

	# Small delay lets audio thread stabilize
	await get_tree().process_frame

	setup_background_music()
	setup_portal_sfx()

	_process_audio_toggles()

func play_portal_crossing():
	if portal_sfx_player and not is_suppressed:
		portal_sfx_player.play()

func setup_portal_sfx():
	portal_sfx_player = AudioStreamPlayer.new()
	portal_sfx_player.name = "PortalSfx"
	add_child(portal_sfx_player)

	var sfx_path = "res://audio/assets/portal-crossing.mp3"
	var sfx_stream = load(sfx_path)
	if sfx_stream:
		portal_sfx_player.stream = sfx_stream
		portal_sfx_player.volume_db = -20.0

func setup_background_music():
	var music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	add_child(music_player)
	_background_music_player = music_player

	var music_path = "res://audio/assets/Shore Contemplation.mp3"
	var music_stream = load(music_path)

	if music_stream:
		music_player.stream = music_stream
		if music_player.stream is AudioStreamMP3:
			music_player.stream.loop = true
		music_player.volume_db = -12.0
		music_player.play()

func setup_audio_bus_and_effects():
	master_bus_index = AudioServer.get_bus_index("Master")

	var bus_name = "MathematicalSoundscape"

	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		bus_index = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_index)
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, &"Master")
	else:
		# Clear existing effects to ensure a clean state
		while AudioServer.get_bus_effect_count(bus_index) > 0:
			AudioServer.remove_bus_effect(bus_index, 0)

	# Index 0: PitchShift
	pitch_shift_effect = AudioEffectPitchShift.new()
	pitch_shift_effect.fft_size = AudioEffectPitchShift.FFT_SIZE_2048
	AudioServer.add_bus_effect(bus_index, pitch_shift_effect)

	# Index 1: Low Pass Filter
	lpf_effect = AudioEffectLowPassFilter.new()
	lpf_effect.cutoff_hz = 800.0
	lpf_effect.resonance = 0.2
	AudioServer.add_bus_effect(bus_index, lpf_effect)

	# Index 2: Reverb (conservative — large room + high wet caused dropouts here)
	reverb_effect = AudioEffectReverb.new()
	reverb_effect.room_size = 0.8
	reverb_effect.damping = 0.72
	reverb_effect.spread = 0.6
	reverb_effect.hipass = 0.08
	reverb_effect.dry = 1.0
	reverb_effect.wet = REVERB_AMOUNT
	AudioServer.add_bus_effect(bus_index, reverb_effect)

	_audio_stream_player.bus = bus_name
	math_bus_index = bus_index

func _physics_process(delta):
	startup_time += delta

	if playback == null:
		var stream_player = _audio_stream_player
		if stream_player.playing:
			playback = stream_player.get_stream_playback()
		if playback == null: return

	# --- TELEPORT DETECTION ---
	if player:
		var player_pos = player.global_position
		if not has_last_pos:
			last_audio_player_pos = player_pos
			has_last_pos = true
		elif last_audio_player_pos.distance_to(player_pos) > 10.0 * GameState.effective_zoom:
			trigger_teleport_fade()
		last_audio_player_pos = player_pos

	# Sample complex field
	var f = player.current_f

	# --- NAN SAFETY ---
	if not is_finite(f.x) or not is_finite(f.y):
		f = Vector2.ZERO

	var mag = f.length()
	if not is_finite(mag): mag = 0.0

	# --- MAPPINGS ---

	# 1. MAGNITUDE |f|
	target_volume = clamp(0.20 - mag * 0.01, 0.0, 0.2)

	# 2. PROXIMITY TO ZERO
	var proximity = 1.0 / (0.05 + mag)
	if not is_finite(proximity): proximity = 20.0

	# --- ZERO-LOCALIZED PULSE ---

	# Gaussian localization around zeros
	# Pulse only exists very near zeros
	pulse_presence = exp(-pow(mag, 3.0))

	# Stable breathing speed
	target_pulse_rate = lerp(1.5, 6.0, pulse_presence)
	target_harmonic_intensity = clamp(proximity * 0.08, 0.0, 0.4)
	target_fm_index = clamp(proximity * 0.15, 0.0, 1.5)

	# 3. PHASE arg(f)
	var arg = atan2(f.y, f.x)
	target_pan = clamp(cos(arg), -1.0, 1.0)

	# --- FINITE CHECKS BEFORE LERP ---
	if not is_finite(target_frequency): target_frequency = BASE_FREQUENCY
	if not is_finite(target_pan): target_pan = 0.0

	# --- SMOOTHING ---
	if is_teleporting:
		# Snap parameters instantly to avoid slow sweep sound artifacts during teleport
		current_volume = target_volume
		current_frequency = target_frequency
		current_pulse_rate = target_pulse_rate
		current_pan = target_pan
		current_harmonic_intensity = target_harmonic_intensity
		current_fm_index = target_fm_index
		
		# Teleport fade recovery
		teleport_fade = move_toward(teleport_fade, 1.0, delta * 3.0)
		if teleport_fade >= 1.0:
			is_teleporting = false
	else:
		current_volume = lerp(current_volume, target_volume, delta * 10.0)
		current_frequency = lerp(current_frequency, target_frequency, delta * 10.0)
		current_pulse_rate = lerp(current_pulse_rate, target_pulse_rate, delta * 10.0)
		current_pan = lerp(current_pan, target_pan, delta * 3.0)
		current_harmonic_intensity = lerp(current_harmonic_intensity, target_harmonic_intensity, delta * 10.0)
		current_fm_index = lerp(current_fm_index, target_fm_index, delta * 10.0)

	# Final safety clamp
	current_frequency = max(0.8, current_frequency)

	# --- EFFECT MODULATION ---
	if pitch_shift_effect:
		var target_ps = 1.0 + current_harmonic_intensity * 0.02
		if abs(target_ps - 1.0) < PITCH_DEADZONE:
			target_ps = 1.0

		target_ps = clamp(target_ps, 0.5, 2.0)
		current_pitch_scale = lerp(current_pitch_scale, target_ps, delta * 15.0)

		if abs(current_pitch_scale - last_pitch) > 0.001:
			pitch_shift_effect.pitch_scale = current_pitch_scale
			last_pitch = current_pitch_scale

	if reverb_effect:
		var target_rv = clamp(REVERB_AMOUNT + (proximity * 0.01), 0.0, 0.9)
		if is_finite(target_rv):
			current_reverb_wet = lerp(current_reverb_wet, target_rv, delta * 4.0)
			reverb_effect.wet = current_reverb_wet

	if lpf_effect:
		var target_cut = lerp(600.0, 4500.0, clamp(mag * 0.05, 0.0, 1.0))
		if is_finite(target_cut):
			current_lpf_cutoff = lerp(current_lpf_cutoff, target_cut, delta * 4.0)
			lpf_effect.cutoff_hz = clamp(current_lpf_cutoff, 100.0, 20000.0)

	fill_buffer()

func fill_buffer():
	if playback == null: return

	var available = playback.get_frames_available()
	var capacity = int(sample_rate * 0.15) # 6615
	var to_fill = TARGET_FILL - (capacity - available)
	# Fill only enough to keep stable occupancy
	if to_fill <= 0:
		return

	to_fill = min(to_fill, 1024)

	var drone_vol_scale = Config.drone_volume / 100.0
	if drone_vol_scale <= 0.0 or is_suppressed:
		# If muted/suppressed, just push silent frames quickly without synthesis math
		for i in range(to_fill):
			playback.push_frame(Vector2.ZERO)
		return

	buffer_min_available = min(buffer_min_available, available)
	buffer_max_available = max(buffer_max_available, available)

	var startup_gain = clamp(startup_time / startup_duration, 0.0, 1.0)
	startup_gain = startup_gain * startup_gain # smoother fade-in

	# Hoist invariant gains and multipliers outside the loop
	var amp_base = current_volume * drone_vol_scale * startup_gain * teleport_fade
	
	# Constant-power panning to maintain volume sum and create highly perceptible separation.
	# current_pan is in [-1.0, 1.0]. Map it to angle in [0, PI/2].
	var pan_angle = (current_pan + 1.0) * (PI / 4.0)
	var pan_l = cos(pan_angle)
	var pan_r = sin(pan_angle)
	
	# Pre-calculate LFO phase value once for the frame since 0.12 Hz LFO changes 
	# negligibly (< 0.002%) over 1024 samples (23ms)
	lfo_phase = fmod(lfo_phase + (0.12 * to_fill) / sample_rate, 1.0)
	var lfo_val = sin(lfo_phase * TAU)
	var jitter = lfo_val * 0.008

	var freq = current_frequency * (1.0 + jitter)
	var increment = freq / sample_rate
	var mod_increment = freq / sample_rate # simplified (freq * 1.0 / sample_rate)

	# Hoist slowly converging lerps to their target or intermediate values
	audio_fm_index = lerp(audio_fm_index, current_fm_index, 0.1)
	audio_pulse_presence = lerp(audio_pulse_presence, pulse_presence, 0.1)

	# Hoist pulse wave calculation
	pulse_phase = fmod(pulse_phase + (current_pulse_rate * to_fill) / sample_rate, 1.0)
	var pulse_wave = 0.75 + 0.25 * sin(pulse_phase * TAU)
	var pulse_multiplier = lerp(1.0, pulse_wave, audio_pulse_presence)
	
	var target_amp_l = amp_base * pulse_multiplier * pan_l
	var target_amp_r = amp_base * pulse_multiplier * pan_r
	var shape = 0.25 + 0.1 * lfo_val

	while to_fill > 0:
		phase = fmod(phase + increment, 1.0)
		mod_phase = fmod(mod_phase + mod_increment, 1.0)

		# Modulator
		var modulator = sin(mod_phase * TAU) * audio_fm_index

		# Carrier + Fifth
		var sample = sin(phase * TAU + modulator)
		sample += 0.15 * sin(phase * TAU * 1.5 + modulator * 0.3)

		# Non-linear saturation (Cubic soft-clipper)
		sample = clamp(sample * 1.1, -1.1, 1.1)
		sample = sample - (sample * sample * sample * shape)

		# Smoothly interpolate amplitude sample-by-sample to prevent any clicks or discontinuities
		current_amp_l = lerp(current_amp_l, target_amp_l, 0.01)
		current_amp_r = lerp(current_amp_r, target_amp_r, 0.01)

		# Push frame
		playback.push_frame(Vector2(sample * current_amp_l, sample * current_amp_r))
		to_fill -= 1

func _process_audio_toggles():
	# 0. Global Master Volume
	var master_vol = Config.master_volume / 100.0
	if is_suppressed:
		master_vol = 0.0

	if master_bus_index != -1:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_vol))

	# 1. Background Music
	if _background_music_player:
		if Config.bg_music_volume > 0 and not is_suppressed:
			_background_music_player.process_mode = Node.PROCESS_MODE_INHERIT
			if not _background_music_player.playing:
				_background_music_player.play()
			# Map 0-100 to dB. 100 -> -12dB (original), 1 -> -52dB, 0 -> stop
			var volume_linear = Config.bg_music_volume / 100.0
			_background_music_player.volume_db = linear_to_db(volume_linear) - 12.0
		else:
			if _background_music_player.playing:
				_background_music_player.stop()
			_background_music_player.process_mode = Node.PROCESS_MODE_DISABLED

	# 2. Topographic Drone
	var drone = _audio_stream_player
	if Config.drone_volume > 0 and not is_suppressed:
		drone.process_mode = Node.PROCESS_MODE_INHERIT
		if math_bus_index != -1:
			AudioServer.set_bus_bypass_effects(math_bus_index, false)
		if not drone.playing:
			drone.play()
			# When resuming, we might need to re-fetch playback
			playback = drone.get_stream_playback()
	else:
		if drone.playing:
			drone.stop()
			playback = null
		drone.process_mode = Node.PROCESS_MODE_DISABLED
		if math_bus_index != -1:
			AudioServer.set_bus_bypass_effects(math_bus_index, true)

func set_performance_protection(active: bool):
	if is_suppressed != active:
		is_suppressed = active
		_process_audio_toggles()

func _on_config_changed(key: String):
	if key in ["master_volume", "bg_music_volume", "drone_volume"]:
		_process_audio_toggles()

func _exit_tree():
	if _audio_stream_player and _audio_stream_player.playing:
		_audio_stream_player.stop()
	if _background_music_player and _background_music_player.playing:
		_background_music_player.stop()

func trigger_teleport_fade() -> void:
	teleport_fade = 0.0
	is_teleporting = true

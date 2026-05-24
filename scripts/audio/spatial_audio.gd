extends Node3D

# --- CONSTANTS ---
const ZERO_PITCH_BOOST = 1.5
const BASE_FREQUENCY = 130.8 # C3 (Standard drone)
const REVERB_AMOUNT = 0.5
const PHASE_PAN_STRENGTH = 1.0

# --- SYNTHESIS STATE ---
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var phase: float = 0.0
var mod_phase: float = 0.0
var lfo_phase: float = 0.0
var noise_state: float = 0.0
var pulse_phase: float = 0.0
var target_pulse_rate: float = 0.0
var current_pulse_rate: float = 0.0
var audio_fm_index: float = 0.0
var audio_pulse_presence: float = 0.0

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

# --- STARTUP ENVELOPE ---
var startup_time := 0.0
var startup_duration := 3.0

# --- FPS GUARD ---
var low_fps_counter: int = 0
var stable_fps_counter: int = 0
var is_suppressed: bool = false

# --- EFFECT REFS ---
var pitch_shift_effect: AudioEffectPitchShift
var reverb_effect: AudioEffectReverb
var lpf_effect: AudioEffectLowPassFilter

var portal_sfx_player: AudioStreamPlayer
var player: Node3D

func _ready():
	# Finding the player to sample position
	player = get_tree().root.find_child("Player", true, false)

	setup_audio_bus_and_effects()

	var stream_player = $AudioStreamPlayer

	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.05

	stream_player.stream = generator

	# Get playback BEFORE starting
	stream_player.play()
	playback = stream_player.get_stream_playback()
	sample_rate = generator.mix_rate

	# Prefill silence
	var frames_to_fill = int(sample_rate)

	for i in frames_to_fill:
		playback.push_frame(Vector2.ZERO)

	# Small delay lets audio thread stabilize
	await get_tree().process_frame

	setup_background_music()
	setup_portal_sfx()

func play_portal_crossing():
	if portal_sfx_player and not is_suppressed:
		portal_sfx_player.play()

func setup_portal_sfx():
	portal_sfx_player = AudioStreamPlayer.new()
	portal_sfx_player.name = "PortalSfx"
	add_child(portal_sfx_player)

	var sfx_path = "res://assets/portal-crossing.mp3"
	var sfx_stream = load(sfx_path)
	if sfx_stream:
		portal_sfx_player.stream = sfx_stream
		portal_sfx_player.volume_db = -20.0
	else:
		print("Warning: Portal SFX not found at ", sfx_path)

func setup_background_music():
	var music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	add_child(music_player)

	var music_path = "res://assets/Shore Contemplation.mp3"
	var music_stream = load(music_path)

	if music_stream:
		music_player.stream = music_stream
		if music_player.stream is AudioStreamMP3:
			music_player.stream.loop = true
		music_player.volume_db = -12.0
		music_player.play()
	else:
		print("Warning: Background music not found at ", music_path)

func setup_audio_bus_and_effects():
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

	$AudioStreamPlayer.bus = bus_name

func _process(delta):
	# --- PERFORMANCE GUARD ---
	var frame_time_ms = delta * 1000.0
	if frame_time_ms > 66.67: # < 15 FPS
		low_fps_counter += 1
		stable_fps_counter = 0
		if low_fps_counter >= 2:
			is_suppressed = true
	elif frame_time_ms <= 50.0: # >= 20 FPS
		stable_fps_counter += 1
		low_fps_counter = 0
		if stable_fps_counter >= 60:
			is_suppressed = false
	else:
		low_fps_counter = 0
		stable_fps_counter = 0

	startup_time += delta

	if Config.performance_protection_active:
		is_suppressed = true

	_process_audio_toggles()

	if playback == null:
		var stream_player = $AudioStreamPlayer
		if stream_player.playing:
			playback = stream_player.get_stream_playback()
		if playback == null: return

	var pos = Vector3.ZERO
	if player:
		pos = player.global_position
	else:
		player = get_tree().root.find_child("Player", true, false)
		if player: pos = player.global_position

	# Sample complex field
	var f = Field.get_field(pos.x, pos.z)

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
	pulse_presence = exp(-pow(mag, 2.0))

	# Stable breathing speed
	target_pulse_rate = lerp(1.5, 4.5, pulse_presence)

	# Store for synthesis stage
	target_harmonic_intensity = clamp(proximity * 0.08, 0.0, 0.4)
	target_fm_index = clamp(proximity * 0.15, 0.0, 1.5)

	# 3. PHASE arg(f)
	var arg = atan2(f.y, f.x)
	target_pan = cos(arg) * PHASE_PAN_STRENGTH

	# --- FINITE CHECKS BEFORE LERP ---
	if not is_finite(target_frequency): target_frequency = BASE_FREQUENCY
	if not is_finite(target_pan): target_pan = 0.0

	# --- SMOOTHING ---
	# Significantly increased interpolation weights for instantaneous response
	current_volume = lerp(current_volume, target_volume, delta * 20.0)
	current_frequency = lerp(current_frequency, target_frequency, delta * 30.0)
	current_pulse_rate = lerp(current_pulse_rate, target_pulse_rate, delta * 5.0)
	current_pan = lerp(current_pan, target_pan, delta * 16.0)
	current_harmonic_intensity = lerp(current_harmonic_intensity, target_harmonic_intensity, delta * 24.0)
	current_fm_index = lerp(current_fm_index, target_fm_index, delta * 10.0)

	# Final safety clamp
	current_frequency = max(0.8, current_frequency)

	# --- EFFECT MODULATION ---
	if pitch_shift_effect:
		var ps = clamp(1.0 + (target_harmonic_intensity * 0.02), 0.5, 2.0)
		if is_finite(ps): pitch_shift_effect.pitch_scale = ps

	if reverb_effect:
		var rv = clamp(REVERB_AMOUNT + (proximity * 0.01), 0.0, 0.9)
		if is_finite(rv): reverb_effect.wet = rv

	if lpf_effect:
		var cut = lerp(600.0, 4500.0, clamp(mag * 0.05, 0.0, 1.0))
		if is_finite(cut): lpf_effect.cutoff_hz = clamp(cut, 100.0, 20000.0)

	fill_buffer()

func fill_buffer():
	if playback == null: return

	var to_fill = playback.get_frames_available()
	# Safety cap to prevent execution spikes
	to_fill = min(to_fill, 4410)

	var startup_gain = clamp(startup_time / startup_duration, 0.0, 1.0)
	startup_gain = startup_gain * startup_gain # smoother fade-in

	while to_fill > 0:
		# --- PHASE INCREMENTS ---

		# LFO for organic drift (0.12 Hz)
		lfo_phase = fmod(lfo_phase + 0.12 / sample_rate, 1.0)
		var jitter = sin(lfo_phase * TAU) * 0.008

		var freq = current_frequency * (1.0 + jitter)
		var increment = freq / sample_rate
		if not is_finite(increment): increment = 0.001
		phase = fmod(phase + increment, 1.0)

		# Modulator phase (harmonic ratio 1.0 or 2.0)
		var mod_increment = freq * 1.0 / sample_rate
		mod_phase = fmod(mod_phase + mod_increment, 1.0)

		# --- FM SYNTHESIS ---

		# Modulator
		audio_fm_index = lerp(audio_fm_index, current_fm_index, 0.001)
		var modulator = sin(mod_phase * TAU) * audio_fm_index

		# Carrier
		var sample = sin(phase * TAU + modulator)

		# Non-linear saturation (Cubic soft-clipper)
		sample = clamp(sample * 1.1, -1.1, 1.1)
		sample = sample - (sample * sample * sample / 3.0)

		if not is_finite(sample): sample = 0.0

		# --- LOCALIZED ZERO PULSE ---

		pulse_phase = fmod(
			pulse_phase + current_pulse_rate / sample_rate,
			1.0
		)

		# Gentle breathing curve
		var pulse_wave = 0.75 + 0.25 * sin(pulse_phase * TAU)

		# Pulse only appears near zeros
		audio_pulse_presence = lerp(audio_pulse_presence, pulse_presence, 0.001)

		sample *= lerp(1.0, pulse_wave, audio_pulse_presence)

		var drone_vol_scale = Config.drone_volume / 100.0
		var frame = Vector2.ONE * sample * current_volume * drone_vol_scale * startup_gain

		# Apply Stereo Panning
		var pan_l = clamp(1.0 - current_pan, 0.0, 1.0)
		var pan_r = clamp(1.0 + current_pan, 0.0, 1.0)
		frame.x *= pan_l
		frame.y *= pan_r

		if is_finite(frame.x) and is_finite(frame.y):
			playback.push_frame(frame)
		else:
			playback.push_frame(Vector2.ZERO)

		to_fill -= 1

func _process_audio_toggles():
	# 0. Global Master Volume
	var master_vol = Config.master_volume / 100.0
	if is_suppressed:
		master_vol = 0.0

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_vol))

	# 1. Background Music
	var music = get_node_or_null("BackgroundMusic")
	if music:
		if Config.bg_music_volume > 0 and not is_suppressed:
			if not music.playing:
				music.play()
			# Map 0-100 to dB. 100 -> -12dB (original), 1 -> -52dB, 0 -> stop
			var volume_linear = Config.bg_music_volume / 100.0
			music.volume_db = linear_to_db(volume_linear) - 12.0
		else:
			if music.playing:
				music.stop()

	# 2. Topographic Drone
	var drone = $AudioStreamPlayer
	if Config.drone_volume > 0 and not is_suppressed:
		if not drone.playing:
			drone.play()
			# When resuming, we might need to re-fetch playback
			playback = drone.get_stream_playback()
	else:
		if drone.playing:
			drone.stop()
			playback = null

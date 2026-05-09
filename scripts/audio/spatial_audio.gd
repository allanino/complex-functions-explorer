extends Node3D

# --- CONSTANTS ---
const ZERO_PITCH_BOOST = 1.5
const BASE_FREQUENCY = 65.4 # C2
const REVERB_AMOUNT = 0.5
const PHASE_PAN_STRENGTH = 0.7

# --- SYNTHESIS STATE ---
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var phase: float = 0.0

# --- INTERPOLATED PARAMETERS ---
var target_volume: float = 0.3
var current_volume: float = 0.2
var target_frequency: float = BASE_FREQUENCY
var current_frequency: float = BASE_FREQUENCY
var target_pan: float = 0.0
var current_pan: float = 0.0
var target_harmonic_intensity: float = 0.0
var current_harmonic_intensity: float = 0.0
var target_resonance: float = 0.0
var current_resonance: float = 0.0

# --- EFFECT REFS ---
var pitch_shift_effect: AudioEffectPitchShift
var reverb_effect: AudioEffectReverb
var lpf_effect: AudioEffectLowPassFilter

var player: Node3D

func _ready():
	# Finding the player to sample position
	player = get_tree().root.find_child("Player", true, false)

	setup_audio_bus_and_effects()

	var stream_player = $AudioStreamPlayer
	# Ensure the generator is correctly configured
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.5 # Increased buffer length to prevent underruns
	stream_player.stream = generator

	# Start playing
	stream_player.play()
	# MUST get playback AFTER play()
	playback = stream_player.get_stream_playback()
	sample_rate = stream_player.stream.mix_rate

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
		AudioServer.clear_bus_effects(bus_index)

	# Index 0: PitchShift
	pitch_shift_effect = AudioEffectPitchShift.new()
	pitch_shift_effect.fft_size = AudioEffectPitchShift.FFT_SIZE_2048 # Better quality for low freq
	AudioServer.add_bus_effect(bus_index, pitch_shift_effect)

	# Index 1: Reverb
	reverb_effect = AudioEffectReverb.new()
	reverb_effect.room_size = 0.8
	reverb_effect.damping = 0.5
	reverb_effect.wet = REVERB_AMOUNT
	AudioServer.add_bus_effect(bus_index, reverb_effect)

	# Index 2: Low Pass Filter
	lpf_effect = AudioEffectLowPassFilter.new()
	lpf_effect.cutoff_hz = 800.0
	lpf_effect.resonance = 0.2
	AudioServer.add_bus_effect(bus_index, lpf_effect)

	$AudioStreamPlayer.bus = bus_name

func _process(delta):
	# Ensure we have a playback object
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
		if player:
			pos = player.global_position

	# Sample Zeta field at player world coordinates
	var f = Field.get_field(pos.x, pos.z)
	var mag = f.length()
	var arg = atan2(f.y, f.x)
	var sigma = pos.x * 0.1

	# --- MAPPINGS ---

	# 1. MAGNITUDE |f|
	target_volume = clamp(0.2 + mag * 0.05, 0.1, 0.5)

	# 2. PROXIMITY TO ZERO
	var proximity = 1.0 / (0.05 + mag)
	target_frequency = BASE_FREQUENCY * (1.0 + log(1.0 + proximity) * ZERO_PITCH_BOOST)
	target_harmonic_intensity = clamp(proximity * 0.08, 0.0, 0.7)

	# 3. PHASE arg(f)
	target_pan = sin(arg) * PHASE_PAN_STRENGTH

	# 4. CRITICAL LINE (sigma = 0.5)
	var dist_to_critical = abs(sigma - 0.5)
	var critical_factor = exp(-dist_to_critical * 25.0)
	target_resonance = critical_factor

	# --- SMOOTHING ---
	current_volume = lerp(current_volume, target_volume, delta * 1.2)
	current_frequency = lerp(current_frequency, target_frequency, delta * 0.8)
	current_pan = lerp(current_pan, target_pan, delta * 0.4)
	current_harmonic_intensity = lerp(current_harmonic_intensity, target_harmonic_intensity, delta * 1.5)
	current_resonance = lerp(current_resonance, target_resonance, delta * 2.0)

	# --- EFFECT MODULATION ---
	# Modulate effects through stored references for better stability
	if pitch_shift_effect:
		pitch_shift_effect.pitch_scale = 1.0 + (target_harmonic_intensity * 0.02)

	if reverb_effect:
		reverb_effect.wet = clamp(REVERB_AMOUNT + current_resonance * 0.15 + (proximity * 0.01), 0.0, 0.8)

	if lpf_effect:
		lpf_effect.cutoff_hz = lerp(600.0, 4500.0, clamp(mag * 0.05 + current_resonance * 0.8, 0.0, 1.0))
		lpf_effect.resonance = 0.2 + current_resonance * 0.3

	fill_buffer()

func fill_buffer():
	if playback == null: return

	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		var increment = current_frequency / sample_rate
		phase = fmod(phase + increment, 1.0)

		# --- PROCEDURAL SYNTHESIS ---

		# Fundamental drone (sine)
		var sample = sin(phase * TAU)

		# Second voice for richness
		sample += 0.5 * sin(phase * TAU * 2.0)

		# Deep sub-resonance, fades slightly near zeros for "thinner" sound
		var sub_strength = 0.7 * (1.0 - clamp(current_harmonic_intensity * 0.5, 0.0, 0.6))
		sample += sub_strength * sin(phase * TAU * 0.5)

		# Harmonic beating and tension near zeros
		if current_harmonic_intensity > 0.01:
			# High-pitched tension
			sample += current_harmonic_intensity * 0.6 * sin(phase * TAU * 3.001)
			sample += current_harmonic_intensity * 0.3 * sin(phase * TAU * 4.998)

		# Critical line richness (glassy/Metallic overtones)
		if current_resonance > 0.01:
			sample += current_resonance * 0.3 * sin(phase * TAU * 7.0)
			sample += current_resonance * 0.15 * sin(phase * TAU * 11.0)

		# Non-linear saturation for warmth/smoothness
		sample = atan(sample * 1.5) / (PI / 2.0)

		var frame = Vector2.ONE * sample * current_volume

		# Apply Stereo Panning
		var pan_l = clamp(1.0 - current_pan, 0.0, 1.0)
		var pan_r = clamp(1.0 + current_pan, 0.0, 1.0)
		frame.x *= pan_l
		frame.y *= pan_r

		playback.push_frame(frame)
		to_fill -= 1

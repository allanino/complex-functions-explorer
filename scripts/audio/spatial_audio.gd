extends Node3D

# --- CONSTANTS ---
const ZERO_PITCH_BOOST = 1.5
const BASE_FREQUENCY = 45.0 # Deep G1/A1 range
const REVERB_AMOUNT = 0.45
const PHASE_PAN_STRENGTH = 0.6

# --- SYNTHESIS STATE ---
var playback: AudioStreamGeneratorPlayback
var sample_rate: float
var phase: float = 0.0

# --- INTERPOLATED PARAMETERS ---
var target_volume: float = 0.1
var current_volume: float = 0.0
var target_frequency: float = BASE_FREQUENCY
var current_frequency: float = BASE_FREQUENCY
var target_pan: float = 0.0
var current_pan: float = 0.0
var target_harmonic_intensity: float = 0.0
var current_harmonic_intensity: float = 0.0
var target_resonance: float = 0.0
var current_resonance: float = 0.0

var player: Node3D

func _ready():
	# Finding the player to sample position
	player = get_tree().root.find_child("Player", true, false)

	setup_audio_bus()

	var stream_player = $AudioStreamPlayer
	if not stream_player.stream is AudioStreamGenerator:
		var generator = AudioStreamGenerator.new()
		generator.mix_rate = 44100
		generator.buffer_length = 0.1
		stream_player.stream = generator

	# Start playing before getting playback
	stream_player.play()
	playback = stream_player.get_stream_playback()
	sample_rate = stream_player.stream.mix_rate

func setup_audio_bus():
	var bus_name = "MathematicalSoundscape"

	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		bus_index = AudioServer.get_bus_count()
		AudioServer.add_bus(bus_index)
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, &"Master")

		# Create effects requested by the requirements

		# Index 0: PitchShift
		var pitch_shift = AudioEffectPitchShift.new()
		AudioServer.add_bus_effect(bus_index, pitch_shift)

		# Index 1: Reverb
		var reverb = AudioEffectReverb.new()
		reverb.room_size = 0.8
		reverb.damping = 0.5
		reverb.wet = REVERB_AMOUNT
		AudioServer.add_bus_effect(bus_index, reverb)

		# Index 2: Low Pass Filter
		var lpf = AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = 800.0
		lpf.resonance = 0.2
		AudioServer.add_bus_effect(bus_index, lpf)

	$AudioStreamPlayer.bus = bus_name

func _process(delta):
	if not player:
		player = get_tree().root.find_child("Player", true, false)
		if not player: return

	var pos = player.global_position
	# Sample Zeta field at player world coordinates
	var f = Field.get_field(pos.x, pos.z)
	var mag = f.length()
	var arg = atan2(f.y, f.x)
	var sigma = pos.x * 0.1

	# --- MAPPINGS ---

	# 1. MAGNITUDE |f|
	# Controls overall drone volume and reverb intensity.
	# High magnitude = fuller, louder drone.
	target_volume = clamp(0.1 + mag * 0.04, 0.05, 0.35)

	# 2. PROXIMITY TO ZERO
	var proximity = 1.0 / (0.05 + mag)
	# As |f| -> 0, proximity increases.
	# Pitch rises smoothly near zeros.
	target_frequency = BASE_FREQUENCY * (1.0 + log(1.0 + proximity) * ZERO_PITCH_BOOST)
	# Harmonic intensity increases (thinner sound, subtle beating).
	target_harmonic_intensity = clamp(proximity * 0.08, 0.0, 0.7)

	# 3. PHASE arg(f)
	# Stereo panning: sound orbits as phase rotates.
	target_pan = sin(arg) * PHASE_PAN_STRENGTH

	# 4. CRITICAL LINE (sigma = 0.5)
	var dist_to_critical = abs(sigma - 0.5)
	var critical_factor = exp(-dist_to_critical * 25.0) # Very narrow focus
	target_resonance = critical_factor

	# --- SMOOTHING ---
	current_volume = lerp(current_volume, target_volume, delta * 1.2)
	current_frequency = lerp(current_frequency, target_frequency, delta * 0.8)
	current_pan = lerp(current_pan, target_pan, delta * 0.4)
	current_harmonic_intensity = lerp(current_harmonic_intensity, target_harmonic_intensity, delta * 1.5)
	current_resonance = lerp(current_resonance, target_resonance, delta * 2.0)

	# --- EFFECT MODULATION ---
	var bus_idx = AudioServer.get_bus_index("MathematicalSoundscape")

	# PitchShift: subtle detune for "eerie" feeling near zeros
	var ps = AudioServer.get_bus_effect(bus_idx, 0) as AudioEffectPitchShift
	ps.pitch_scale = 1.0 + (target_harmonic_intensity * 0.02)

	# Reverb: increases subtly near critical line and zeros
	var rb = AudioServer.get_bus_effect(bus_idx, 1) as AudioEffectReverb
	rb.wet = clamp(REVERB_AMOUNT + current_resonance * 0.15 + (proximity * 0.01), 0.0, 0.8)

	# LPF: opens up for "harmonic richness" on critical line
	var lp = AudioServer.get_bus_effect(bus_idx, 2) as AudioEffectLowPassFilter
	lp.cutoff_hz = lerp(600.0, 4500.0, clamp(mag * 0.05 + current_resonance * 0.8, 0.0, 1.0))
	lp.resonance = 0.2 + current_resonance * 0.3

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

		# Deep sub-resonance, fades slightly near zeros for "thinner" sound
		var sub_strength = 0.8 * (1.0 - clamp(current_harmonic_intensity * 0.5, 0.0, 0.6))
		sample += sub_strength * sin(phase * TAU * 0.5)

		# Harmonic beating and tension near zeros
		if current_harmonic_intensity > 0.01:
			# High-pitched tension
			sample += current_harmonic_intensity * sin(phase * TAU * 2.001)
			sample += current_harmonic_intensity * 0.4 * sin(phase * TAU * 3.998)

		# Critical line richness (glassy/Metallic overtones)
		if current_resonance > 0.01:
			# Glassy/Metallic overtones (higher primes or odd harmonics)
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

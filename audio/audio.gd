extends Node3D

# --- CONSTANTS ---
const PHASE_PAN_STRENGTH = 1.0

# --- STATE ---
var _background_music_player: AudioStreamPlayer
@onready var _audio_stream_player = $AudioStreamPlayer

# --- INTERPOLATED PARAMETERS ---
var target_volume: float = 0.3
var current_volume: float = 0.2
var target_pan: float = 0.0
var current_pan: float = 0.0
var target_cutoff: float = 20000.0
var current_cutoff: float = 20000.0

# --- FPS GUARD ---
var is_suppressed: bool = false

# --- BUS INDICES ---
var math_bus_index: int = -1
var master_bus_index: int = -1

var portal_sfx_player: AudioStreamPlayer
@onready var player: Node3D = get_tree().get_first_node_in_group("player")

func _ready():
	Config.config_changed.connect(_on_config_changed)

	setup_audio_bus_and_effects()

	var stream_player = _audio_stream_player

	var stream = load("res://audio/assets/drone.wav")
	if stream:
		stream_player.stream = stream
		stream_player.volume_db = 0.0
		stream_player.finished.connect(func(): if _audio_stream_player: _audio_stream_player.play())
		stream_player.play()

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

	# Index 0: Panner
	var panner = AudioEffectPanner.new()
	AudioServer.add_bus_effect(bus_index, panner)

	# Index 1: Low Pass Filter — start fully open
	var lpf = AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 20000.0
	lpf.resonance = 0.05
	AudioServer.add_bus_effect(bus_index, lpf)

	_audio_stream_player.bus = bus_name
	math_bus_index = bus_index

func _physics_process(delta):
	# Sample complex field
	var f = player.current_f

	# --- NAN SAFETY ---
	if not is_finite(f.x) or not is_finite(f.y):
		f = Vector2.ZERO

	var mag = f.length()
	if not is_finite(mag): mag = 0.0

	# --- MAPPINGS ---

	# 1. MAGNITUDE |f| -> Volume + LPF brightness
	#    Low mag  = open filter (bright), higher volume
	#    High mag = closed filter (dark),  lower volume
	target_volume = clamp(0.8 - mag * 0.05, 0.1, 0.8)
	# Floor at 800 Hz to avoid low-frequency resonance ringing
	target_cutoff = lerp(20000.0, 800.0, clamp(mag * 0.1, 0.0, 1.0))

	# 2. PHASE arg(f) -> Pan
	var arg = atan2(f.y, f.x)
	target_pan = cos(arg) * PHASE_PAN_STRENGTH

	# --- FINITE CHECKS BEFORE LERP ---
	if not is_finite(target_pan): target_pan = 0.0
	if not is_finite(target_cutoff): target_cutoff = 20000.0

	# --- SMOOTHING ---
	# Extremely gentle interpolation speeds to prevent any zipper noise or metallic sweeps
	current_volume = lerp(current_volume, target_volume, delta * 2.0)
	current_pan = lerp(current_pan, target_pan, delta * 1.5)
	current_cutoff = lerp(current_cutoff, target_cutoff, delta * 0.8)

	# --- EFFECT MODULATION ---
	# Must fetch the LIVE effect instances from AudioServer each frame
	# (add_bus_effect duplicates the object, stored refs are dead copies)
	if math_bus_index != -1:
		var effect_count = AudioServer.get_bus_effect_count(math_bus_index)
		if effect_count > 0:
			var live_panner = AudioServer.get_bus_effect(math_bus_index, 0)
			if live_panner is AudioEffectPanner:
				live_panner.pan = current_pan
		if effect_count > 1:
			var live_lpf = AudioServer.get_bus_effect(math_bus_index, 1)
			if live_lpf is AudioEffectLowPassFilter:
				live_lpf.cutoff_hz = current_cutoff

	# Update stream volume
	var drone_vol_scale = Config.drone_volume / 100.0
	if _audio_stream_player:
		var vol_db = linear_to_db(current_volume * drone_vol_scale)
		_audio_stream_player.volume_db = vol_db

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
	else:
		if drone.playing:
			drone.stop()
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

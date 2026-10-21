# res://src/autoload/audio_manager.gd
extends Node

## Centralized audio manager handling polyphonic SFX playback and seamless looping BGM

var _bgm_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 12

var _sound_cache: Dictionary = {}

const SFX_PATHS := {
	"laser": "res://assets/audio/sfx/laser_player.wav",
	"explosion_small": "res://assets/audio/sfx/explosion_small.wav",
	"explosion_heavy": "res://assets/audio/sfx/explosion_heavy.wav",
	"bullet_absorb": "res://assets/audio/sfx/bullet_absorb.wav",
	"graze": "res://assets/audio/sfx/graze.wav",
	"scrap": "res://assets/audio/sfx/scrap_pickup.wav",
	"powerup": "res://assets/audio/sfx/powerup_pickup.wav",
	"emp": "res://assets/audio/sfx/emp_detonate.wav",
	"missile": "res://assets/audio/sfx/missile_launch.wav",
	"beam": "res://assets/audio/sfx/hyper_beam.wav"
}

const BGM_PATHS := {
	"title": "res://assets/audio/bgm/bgm_title.wav",
	"stage1": "res://assets/audio/bgm/bgm_stage1.wav"
}

var sfx_enabled: bool = true
var bgm_enabled: bool = true
var sfx_volume: float = 1.0 # 0.0 to 1.0
var bgm_volume: float = 0.8 # 0.0 to 1.0
var _current_bgm_key: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Load initial settings from GameState if present
	if has_node("/root/GameState"):
		sfx_enabled = GameState.sfx_enabled
		bgm_enabled = GameState.bgm_enabled
		sfx_volume = GameState.sfx_volume
		bgm_volume = GameState.bgm_volume
	
	# Create BGM audio player
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	
	# Create polyphonic SFX audio pool
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)
		
	_preload_audio()
	_connect_event_bus()

func _preload_audio() -> void:
	for sfx_name in SFX_PATHS.keys():
		var path: String = SFX_PATHS[sfx_name]
		if ResourceLoader.exists(path):
			_sound_cache[sfx_name] = load(path)
			
	for bgm_name in BGM_PATHS.keys():
		var path: String = BGM_PATHS[bgm_name]
		if ResourceLoader.exists(path):
			_sound_cache[bgm_name] = load(path)

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	if has_node("/root/GameState"):
		GameState.sfx_enabled = enabled
		GameState.save_data()
	if not enabled:
		for p in _sfx_players:
			if p.playing:
				p.stop()

func set_bgm_enabled(enabled: bool) -> void:
	bgm_enabled = enabled
	if has_node("/root/GameState"):
		GameState.bgm_enabled = enabled
		GameState.save_data()
	if not enabled:
		if _bgm_player and _bgm_player.playing:
			_bgm_player.stop()
	else:
		if not _current_bgm_key.is_empty():
			play_bgm(_current_bgm_key)

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)
	if has_node("/root/GameState"):
		GameState.sfx_volume = sfx_volume
		GameState.save_data()

func set_bgm_volume(val: float) -> void:
	bgm_volume = clampf(val, 0.0, 1.0)
	if has_node("/root/GameState"):
		GameState.bgm_volume = bgm_volume
		GameState.save_data()
	if _bgm_player:
		_bgm_player.volume_db = linear_to_db(maxf(bgm_volume, 0.0001)) - 4.0

func play_sfx(sfx_key: String, randomize_pitch: bool = true) -> void:
	if not sfx_enabled or sfx_volume <= 0.001:
		return
	if not _sound_cache.has(sfx_key):
		return
	var stream: AudioStream = _sound_cache[sfx_key]
	if not stream:
		return
		
	# Find an available player or borrow the oldest
	var player: AudioStreamPlayer = null
	for p in _sfx_players:
		if not p.playing:
			player = p
			break
	if not player:
		player = _sfx_players[0]
		
	player.stream = stream
	player.volume_db = linear_to_db(maxf(sfx_volume, 0.0001))
	player.pitch_scale = randf_range(0.92, 1.08) if randomize_pitch else 1.0
	player.play()

func play_bgm(bgm_key: String, base_volume_db: float = -4.0) -> void:
	_current_bgm_key = bgm_key
	if not bgm_enabled or bgm_volume <= 0.001 or not _sound_cache.has(bgm_key) or not _bgm_player:
		return
	var stream: AudioStream = _sound_cache[bgm_key]
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
		
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(maxf(bgm_volume, 0.0001)) + base_volume_db
	_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()

func _connect_event_bus() -> void:
	EventBus.player_grazed.connect(func(_pos): play_sfx("graze", true))
	EventBus.scrap_collected.connect(func(_val): play_sfx("scrap", true))
	EventBus.powerup_picked.connect(func(_t): play_sfx("powerup", false))
	EventBus.special_attack_triggered.connect(func(): play_sfx("emp", false))
	EventBus.hit_stop_triggered.connect(func(_dur): play_sfx("explosion_heavy", false))
	EventBus.enemy_destroyed.connect(func(type, _pos, _val):
		if "heavy" in type.to_lower() or "boss" in type.to_lower() or "elite" in type.to_lower():
			play_sfx("explosion_heavy", false)
		else:
			play_sfx("explosion_small", true)
	)
	EventBus.secondary_weapon_fired.connect(func(type):
		match type:
			"SWARM_MISSILES":
				play_sfx("missile", true)
			"HYPER_BEAM":
				play_sfx("beam", false)
			_:
				play_sfx("missile", true)
	)

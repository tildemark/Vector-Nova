# res://src/managers/spawner_manager.gd
class_name SpawnerManager
extends Node2D

@export var enemy_bullet_pool: ObjectPool

var scout_scene: PackedScene = preload("res://src/entities/enemies/enemy_scout.tscn")
var interceptor_scene: PackedScene = preload("res://src/entities/enemies/enemy_interceptor.tscn")
var boss_scene: PackedScene = preload("res://src/entities/enemies/boss/boss_dreadnought.tscn")

var current_wave: int = 1
var _wave_timer: float = 2.0 # Delay before first wave
var _is_spawning_wave: bool = false
var _wave_active: bool = false
var _boss_active: bool = false

func _ready() -> void:
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated() -> void:
	_boss_active = false
	_wave_active = false
	_wave_timer = 4.0 # Respite after epic boss victory

func _process(delta: float) -> void:
	if _boss_active:
		return
		
	if not _wave_active and not _is_spawning_wave:
		_wave_timer -= delta
		if _wave_timer <= 0:
			_start_next_wave()
	elif _wave_active:
		# Check if all enemies in current wave are destroyed
		var active_enemies := get_tree().get_nodes_in_group("enemies")
		if active_enemies.is_empty():
			_wave_active = false
			_wave_timer = 2.5 # Intermission before next wave

func _start_next_wave() -> void:
	_is_spawning_wave = true
	
	match current_wave:
		1:
			EventBus.wave_started.emit(current_wave)
			await _spawn_scout_line(5, 0.4)
		2:
			EventBus.wave_started.emit(current_wave)
			await _spawn_interceptor_escort()
		3:
			# WAVE 3: FLAGSHIP BOSS ENCOUNTER
			_boss_active = true
			EventBus.wave_started.emit(3)
			await get_tree().create_timer(1.2).timeout
			_spawn_boss()
		_:
			# Dynamic scaling wave
			EventBus.wave_started.emit(current_wave)
			var scout_count := 4 + (current_wave * 2)
			var interceptor_count := maxi(1, current_wave - 2)
			await _spawn_mixed_assault(scout_count, interceptor_count)
			
	current_wave += 1
	_is_spawning_wave = false
	if not _boss_active:
		_wave_active = true

func _spawn_boss() -> void:
	if not boss_scene:
		return
	var boss := boss_scene.instantiate() as BossDreadnought
	boss.enemy_bullet_pool = enemy_bullet_pool
	get_parent().add_child(boss)

func _get_spawn_x() -> float:
	var vp_size := get_viewport_rect().size
	var width := vp_size.x if vp_size.x > 0 else 1280.0
	return width + 80.0

func _spawn_scout_line(count: int, interval: float) -> void:
	var spawn_y := randf_range(160.0, 560.0)
	for i in range(count):
		if not is_inside_tree():
			return
		_spawn_enemy(scout_scene, Vector2(_get_spawn_x(), spawn_y))
		await get_tree().create_timer(interval).timeout

func _spawn_scout_v_formation() -> void:
	var center_y := randf_range(260.0, 460.0)
	var x := _get_spawn_x()
	# Lead ship
	_spawn_enemy(scout_scene, Vector2(x, center_y))
	await get_tree().create_timer(0.35).timeout
	# Wing pairs
	_spawn_enemy(scout_scene, Vector2(x + 50, center_y - 70))
	_spawn_enemy(scout_scene, Vector2(x + 50, center_y + 70))
	await get_tree().create_timer(0.35).timeout
	_spawn_enemy(scout_scene, Vector2(x + 100, center_y - 140))
	_spawn_enemy(scout_scene, Vector2(x + 100, center_y + 140))

func _spawn_interceptor_escort() -> void:
	var x := _get_spawn_x()
	# Top and bottom heavy interceptors
	_spawn_enemy(interceptor_scene, Vector2(x, 220))
	_spawn_enemy(interceptor_scene, Vector2(x, 500))
	await get_tree().create_timer(0.5).timeout
	# Center scout wave
	_spawn_enemy(scout_scene, Vector2(x + 80, 360))
	await get_tree().create_timer(0.3).timeout
	_spawn_enemy(scout_scene, Vector2(x + 140, 310))
	_spawn_enemy(scout_scene, Vector2(x + 140, 410))

func _spawn_mixed_assault(scout_count: int, interceptor_count: int) -> void:
	var x := _get_spawn_x()
	for i in range(interceptor_count):
		var y := randf_range(180.0, 540.0)
		_spawn_enemy(interceptor_scene, Vector2(x + (i * 120), y))
	
	for i in range(scout_count):
		var y := randf_range(140.0, 580.0)
		_spawn_enemy(scout_scene, Vector2(x + (i * 70), y))
		await get_tree().create_timer(0.3).timeout

func _spawn_enemy(scene: PackedScene, spawn_pos: Vector2) -> Node2D:
	if not scene:
		return null
	var enemy := scene.instantiate() as BaseEnemy
	enemy.global_position = spawn_pos
	enemy.enemy_bullet_pool = enemy_bullet_pool
	get_parent().add_child(enemy)
	return enemy

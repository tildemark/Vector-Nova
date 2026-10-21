# res://src/managers/spawner_manager.gd
class_name SpawnerManager
extends Node2D

@export var enemy_bullet_pool: ObjectPool

var scout_scene: PackedScene = preload("res://src/entities/enemies/enemy_scout.tscn")
var interceptor_scene: PackedScene = preload("res://src/entities/enemies/enemy_interceptor.tscn")
var elite_scene: PackedScene = preload("res://src/entities/enemies/enemy_heavy_elite.tscn")
var boss_scene: PackedScene = preload("res://src/entities/enemies/boss/boss_dreadnought.tscn")
var powerup_scene: PackedScene = preload("res://src/entities/items/powerup_item.tscn")
var obstacle_scene: PackedScene = preload("res://src/entities/environment/obstacle_debris.tscn")

var current_wave: int = 1
var _wave_timer: float = 2.0 # Initial launch delay
var _wave_duration: float = 0.0
var _is_spawning_wave: bool = false
var _wave_active: bool = false
var _boss_active: bool = false

# Red Squadron Formation tracking (Classic 1942 / Aero Fighters 100% kill reward)
var _red_formation_total: int = 5
var _red_formation_killed: int = 0
var _red_formation_dropped: bool = false
var _stage_powerups_spawned: int = 0

func _ready() -> void:
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated() -> void:
	_boss_active = false
	_wave_active = false
	_wave_timer = 5.0 # Victorious respite

func _process(delta: float) -> void:
	if _boss_active:
		return
		
	if not _wave_active and not _is_spawning_wave:
		_wave_timer -= delta
		if _wave_timer <= 0:
			_start_next_wave()
	elif _wave_active:
		_wave_duration += delta
		# Check if all enemies in current wave are destroyed
		var active_enemies := get_tree().get_nodes_in_group("enemies")
		if active_enemies.is_empty() or _wave_duration >= 32.0:
			_wave_active = false
			_wave_timer = 2.2 # Arcade intermission before next wave

func _start_next_wave() -> void:
	_is_spawning_wave = true
	_wave_duration = 0.0
	
	match current_wave:
		1:
			# WAVE 1 (00:00 - 00:25): Red Squadron Formation + Scout Line
			EventBus.wave_started.emit(1)
			await _spawn_red_squadron()
			await get_tree().create_timer(1.5).timeout
			await _spawn_scout_line(3, 0.45)
		2:
			# WAVE 2 (00:25 - 00:50): Asteroid Drift & Interceptor Crossfire
			EventBus.wave_started.emit(2)
			_spawn_asteroid_drift(3)
			await _spawn_wave_2()
		3:
			# WAVE 3 (00:50 - 01:20): Mid-Boss Heavy Elite Cruiser
			EventBus.wave_started.emit(3)
			await _spawn_wave_3()
		4:
			# WAVE 4 (01:20 - 01:40): Megastructure Girders & Pre-Boss Gauntlet
			EventBus.wave_started.emit(4)
			_spawn_girder_corridor()
			await _spawn_wave_4()
		5:
			# WAVE 5 (01:40 - 02:40): Flagship Dreadnought Nova (60s countdown)
			_boss_active = true
			EventBus.wave_started.emit(5)
			await get_tree().create_timer(1.5).timeout
			_spawn_boss()
		_:
			# Dynamic Scaling Endless Assault (Waves 6+)
			await _spawn_endless_wave(current_wave)
			
	current_wave += 1
	_is_spawning_wave = false
	if not _boss_active:
		_wave_active = true

func _spawn_red_squadron() -> void:
	_red_formation_total = 5
	_red_formation_killed = 0
	_red_formation_dropped = false
	
	var spawn_y := randf_range(220.0, 500.0)
	var x := _get_spawn_x()
	
	for i in range(_red_formation_total):
		if not is_inside_tree():
			return
		var scout := scout_scene.instantiate() as EnemyScout
		scout.global_position = Vector2(x, spawn_y)
		scout.enemy_bullet_pool = enemy_bullet_pool
		# Visual arcade red squadron tint
		scout.modulate = Color(2.8, 0.45, 0.45, 1.0)
		
		# Hook defeated signal to track 100% destruction
		scout.defeated.connect(func(dead_scout: BaseEnemy):
			_red_formation_killed += 1
			if _red_formation_killed >= _red_formation_total and not _red_formation_dropped:
				_red_formation_dropped = true
				_on_red_formation_cleared(dead_scout.global_position)
		)
		
		get_parent().add_child(scout)
		await get_tree().create_timer(0.4).timeout

func _on_red_formation_cleared(pos: Vector2) -> void:
	EventBus.formation_completed.emit("RED_SQUADRON")
	# Scouts and interceptors never drop powerups per design specification

func _spawn_wave_2() -> void:
	var x := _get_spawn_x()
	# Top and bottom interceptors
	_spawn_enemy(interceptor_scene, Vector2(x, 200))
	_spawn_enemy(interceptor_scene, Vector2(x + 40, 520))
	await get_tree().create_timer(1.0).timeout
	# Scout pincer
	_spawn_scout_v_formation()

func _spawn_wave_3() -> void:
	var x := _get_spawn_x()
	# 2 Escort scouts
	_spawn_enemy(scout_scene, Vector2(x, 180))
	_spawn_enemy(scout_scene, Vector2(x, 540))
	await get_tree().create_timer(0.8).timeout
	
	# Mid-boss Heavy Elite Cruiser
	var elite := elite_scene.instantiate() as BaseEnemy
	elite.global_position = Vector2(x + 80, 360)
	elite.enemy_bullet_pool = enemy_bullet_pool
	
	# Mid-Boss Heavy Elite Cruiser: sole powerup source in Stage 1 (strictly 1 guaranteed drop, no extra drops)
	elite.defeated.connect(func(e: BaseEnemy):
		if powerup_scene and _stage_powerups_spawned < 1:
			_stage_powerups_spawned += 1
			var p := powerup_scene.instantiate() as Node2D
			p.global_position = e.global_position
			get_parent().call_deferred("add_child", p)
	)
	
	get_parent().add_child(elite)

func _spawn_wave_4() -> void:
	var x := _get_spawn_x()
	_spawn_enemy(interceptor_scene, Vector2(x, 260))
	_spawn_enemy(interceptor_scene, Vector2(x, 460))
	await get_tree().create_timer(0.8).timeout
	await _spawn_scout_line(4, 0.35)

func _spawn_endless_wave(wave_num: int) -> void:
	EventBus.wave_started.emit(wave_num)
	var scout_count := 4 + (wave_num * 2)
	var interceptor_count := maxi(1, wave_num - 4)
	await _spawn_mixed_assault(scout_count, interceptor_count)
	if wave_num % 3 == 0:
		var x := _get_spawn_x()
		var elite := elite_scene.instantiate() as BaseEnemy
		elite.global_position = Vector2(x + 80, 360)
		elite.enemy_bullet_pool = enemy_bullet_pool
		get_parent().add_child(elite)

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
	_spawn_enemy(scout_scene, Vector2(x, center_y))
	await get_tree().create_timer(0.35).timeout
	_spawn_enemy(scout_scene, Vector2(x + 50, center_y - 70))
	_spawn_enemy(scout_scene, Vector2(x + 50, center_y + 70))
	await get_tree().create_timer(0.35).timeout
	_spawn_enemy(scout_scene, Vector2(x + 100, center_y - 140))
	_spawn_enemy(scout_scene, Vector2(x + 100, center_y + 140))

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

func _spawn_asteroid_drift(count: int) -> void:
	if not obstacle_scene:
		return
	var x := _get_spawn_x()
	for i in range(count):
		if not is_inside_tree():
			return
		var ast := obstacle_scene.instantiate() as ObstacleDebris
		ast.obstacle_type = "asteroid"
		ast.global_position = Vector2(x + (i * 180.0), randf_range(120.0, 600.0))
		get_parent().call_deferred("add_child", ast)

func _spawn_girder_corridor() -> void:
	if not obstacle_scene:
		return
	var x := _get_spawn_x()
	# Top hanging girder
	var top_girder := obstacle_scene.instantiate() as ObstacleDebris
	top_girder.obstacle_type = "girder"
	top_girder.global_position = Vector2(x + 100.0, 110.0)
	get_parent().call_deferred("add_child", top_girder)
	
	# Bottom rising girder creating a narrow middle flight corridor
	var bot_girder := obstacle_scene.instantiate() as ObstacleDebris
	bot_girder.obstacle_type = "girder"
	bot_girder.global_position = Vector2(x + 280.0, 610.0)
	get_parent().call_deferred("add_child", bot_girder)

# res://src/entities/enemies/boss/boss_dreadnought.gd
class_name BossDreadnought
extends Node2D

enum BossPhase { ENTERING, SHIELDED_TURRETS, ENRAGED_CORE, DEFEATED }

@export var max_health: int = 1400
@export var current_health: int = 1400

var enemy_bullet_pool: ObjectPool = null
var current_phase: BossPhase = BossPhase.ENTERING

@onready var shield_sprite: Sprite2D = $ShieldSprite
@onready var hull_sprite: Sprite2D = $HullSprite
@onready var core_hitbox: Area2D = $CoreHitbox
@onready var weakpoints_container: Node2D = $WeakPoints

var _active_turrets: int = 0
var _time_alive: float = 0.0
var _target_x: float = 1000.0
var _center_y: float = 360.0
var _enraged_attack_timer: float = 0.0
var _radial_angle_offset: float = 0.0

var _scrap_scene: PackedScene = preload("res://src/entities/items/scrap_item.tscn")
var _powerup_scene: PackedScene = preload("res://src/entities/items/powerup_item.tscn")

var boss_timer: float = 60.0 # 60-second arcade boss timer
var _timer_tick: float = 0.0

func _ready() -> void:
	add_to_group("boss")
	current_health = max_health
	
	# Compute responsive target position on right side
	var vp_size := get_viewport_rect().size
	var width := vp_size.x if vp_size.x > 0 else 1280.0
	_target_x = width - 220.0
	_center_y = (vp_size.y if vp_size.y > 0 else 720.0) / 2.0
	position.x = width + 260.0
	position.y = _center_y
	
	# Connect core hitbox
	if core_hitbox:
		core_hitbox.set_deferred("monitoring", false)
		core_hitbox.set_deferred("monitorable", false)
		core_hitbox.add_to_group("enemies")
		core_hitbox.add_to_group("boss_weakspots")
		
	# Setup child turrets
	var weakpoints := weakpoints_container.get_children()
	_active_turrets = weakpoints.size()
	for wp in weakpoints:
		if wp is BossWeakspot:
			wp.enemy_bullet_pool = enemy_bullet_pool
			wp.destroyed.connect(_on_weakpoint_destroyed)
			
	EventBus.boss_spawned.emit("Dreadnought Nova", max_health)

func _process(delta: float) -> void:
	_time_alive += delta
	
	# Boss combat countdown timer
	if current_phase != BossPhase.ENTERING and current_phase != BossPhase.DEFEATED:
		boss_timer -= delta
		_timer_tick += delta
		if _timer_tick >= 1.0:
			_timer_tick = 0.0
			EventBus.boss_timer_updated.emit(maxi(0, int(boss_timer)))
			
		if boss_timer <= 0.0 and current_phase == BossPhase.SHIELDED_TURRETS:
			_transition_to_enraged()
	
	match current_phase:
		BossPhase.ENTERING:
			# Slow majestic entry
			position.x = move_toward(position.x, _target_x, 150.0 * delta)
			if position.x <= _target_x + 2.0:
				position.x = _target_x
				current_phase = BossPhase.SHIELDED_TURRETS
				EventBus.boss_timer_updated.emit(int(boss_timer))
				
		BossPhase.SHIELDED_TURRETS:
			# Vertical floating drift
			position.y = _center_y + sin(_time_alive * 0.9) * 85.0
			# Shield breathing pulse
			if shield_sprite:
				var pulse := 1.0 + sin(_time_alive * 4.0) * 0.08
				shield_sprite.scale = Vector2(pulse, pulse)
				
		BossPhase.ENRAGED_CORE:
			# Aggressive vertical sweep
			position.y = _center_y + sin(_time_alive * 1.5) * 120.0
			
			# Bullet hell attack loop
			_enraged_attack_timer += delta
			if _enraged_attack_timer >= 1.6:
				_enraged_attack_timer = 0.0
				_execute_bullet_hell_pattern()
				
		BossPhase.DEFEATED:
			pass

func _on_weakpoint_destroyed() -> void:
	_active_turrets -= 1
	if _active_turrets <= 0 and current_phase == BossPhase.SHIELDED_TURRETS:
		_transition_to_enraged()

func _transition_to_enraged() -> void:
	current_phase = BossPhase.ENRAGED_CORE
	
	# Shield shatter animation
	if shield_sprite:
		var tween := create_tween()
		tween.tween_property(shield_sprite, "modulate:a", 0.0, 0.4)
		tween.tween_callback(shield_sprite.hide)
		
	# Enable core vulnerability
	if core_hitbox:
		core_hitbox.set_deferred("monitoring", true)
		core_hitbox.set_deferred("monitorable", true)
		
	# Hull flash
	if hull_sprite:
		var ht := create_tween()
		ht.tween_property(hull_sprite, "modulate", Color(2.5, 1.0, 1.0, 1.0), 0.2)
		ht.tween_property(hull_sprite, "modulate", Color.WHITE, 0.3)

func _execute_bullet_hell_pattern() -> void:
	if not enemy_bullet_pool:
		return
		
	var core_pos := global_position + Vector2(-60, 0)
	
	# 10-Way radial spiral ring
	_radial_angle_offset += 0.2
	var bullet_count := 10
	for i in range(bullet_count):
		var angle := _radial_angle_offset + (i * TAU / bullet_count)
		var dir := Vector2.from_angle(angle)
		# Only shoot towards the left hemisphere (towards player)
		if dir.x < 0.2:
			enemy_bullet_pool.spawn(core_pos, dir, 460.0, 12, true, false)
			
	# Forward high-speed central plasma spear
	enemy_bullet_pool.spawn(core_pos, Vector2.LEFT, 700.0, 18, true, false)

func take_damage(amount: int) -> void:
	if current_phase != BossPhase.ENRAGED_CORE:
		return
		
	current_health = maxi(current_health - amount, 0)
	EventBus.boss_health_updated.emit(current_health)
	_flash_core()
	
	if current_health <= 0:
		_die()

func _flash_core() -> void:
	if hull_sprite:
		var tween := create_tween()
		hull_sprite.modulate = Color(3.0, 1.5, 1.5, 1.0)
		tween.tween_property(hull_sprite, "modulate", Color.WHITE, 0.1)

func _die() -> void:
	if current_phase == BossPhase.DEFEATED:
		return
	current_phase = BossPhase.DEFEATED
	
	if core_hitbox:
		core_hitbox.set_deferred("monitoring", false)
		core_hitbox.set_deferred("monitorable", false)
		
	# Bullet cancel and hit-stop crunch
	EventBus.bullet_cancel_triggered.emit()
	EventBus.hit_stop_triggered.emit(60.0)
	EventBus.boss_defeated.emit()
	
	# Cascading explosion sequence
	var death_tween := create_tween()
	death_tween.tween_property(self, "modulate", Color(3.0, 2.0, 2.0, 1.0), 0.5)
	death_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	death_tween.tween_callback(func():
		_spawn_boss_rewards()
		queue_free()
	)

func _spawn_boss_rewards() -> void:
	var parent_node := get_parent()
	if not parent_node:
		return
		
	# Massive explosion of 18 scrap crystals
	for i in range(18):
		if _scrap_scene:
			var scrap := _scrap_scene.instantiate() as Node2D
			scrap.global_position = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
			parent_node.call_deferred("add_child", scrap)
			
	# Guaranteed 2 Power-up capsules
	for i in range(2):
		if _powerup_scene:
			var p_item := _powerup_scene.instantiate() as Node2D
			p_item.global_position = global_position + Vector2(randf_range(-60, 60), randf_range(-40, 40))
			parent_node.call_deferred("add_child", p_item)

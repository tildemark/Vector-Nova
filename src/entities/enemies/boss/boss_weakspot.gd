# res://src/entities/enemies/boss/boss_weakspot.gd
class_name BossWeakspot
extends Area2D

signal destroyed()
signal health_changed(current: int, max_val: int)

enum WeakpointType { TURRET, WING }

@export var weakpoint_type: WeakpointType = WeakpointType.TURRET
@export var max_health: int = 850
@export var current_health: int = 850
@export var shoot_interval: float = 1.6
@export var enables_tracking: bool = true

var enemy_bullet_pool: ObjectPool = null
var is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var collision_poly: CollisionPolygon2D = get_node_or_null("CollisionPolygon2D")

var _hit_flash_timer: float = 0.0
var _original_pos: Vector2 = Vector2.ZERO
var _shoot_timer: float = 0.5
var _target_player: Node2D = null
var _scrap_scene: PackedScene = preload("res://src/entities/items/scrap_item.tscn")

func _ready() -> void:
	add_to_group("boss_weakspots")
	add_to_group("enemies")
	current_health = max_health
	_original_pos = position
	
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target_player = players[0]

func _process(delta: float) -> void:
	if is_destroyed:
		return
		
	# Hit flash decay
	if _hit_flash_timer > 0.0:
		_hit_flash_timer -= delta
		if _hit_flash_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE
		
	# Subtle tracking tilt toward player (turrets aim, wings remain fixed or subtle sway)
	if enables_tracking:
		if not _target_player or not is_instance_valid(_target_player):
			var players := get_tree().get_nodes_in_group("player")
			if not players.is_empty():
				_target_player = players[0]
				
		if _target_player and is_instance_valid(_target_player):
			var target_angle := (_target_player.global_position - global_position).angle()
			# Allow full leftward targeting arc (from upper-left to lower-left: PI +- 1.1 rad (~125 degrees))
			var clamped_angle := clampf(target_angle, PI - 1.1, PI + 1.1)
			rotation = lerp_angle(rotation, clamped_angle, 5.0 * delta)
		
	# Shooting loop
	_shoot_timer += delta
	if _shoot_timer >= shoot_interval:
		_shoot_timer = 0.0
		_fire()

func _fire() -> void:
	if not enemy_bullet_pool:
		# Fallback: find EnemyBulletPool from root or parent boss
		var cur: Node = get_parent()
		while cur != null:
			if "enemy_bullet_pool" in cur and cur.enemy_bullet_pool:
				enemy_bullet_pool = cur.enemy_bullet_pool
				break
			cur = cur.get_parent()
			
		if not enemy_bullet_pool:
			var pools := get_tree().get_nodes_in_group("bullet_pools")
			for p in pools:
				if p.name == "EnemyBulletPool":
					enemy_bullet_pool = p
					break
	if not enemy_bullet_pool:
		return
		
	if weakpoint_type == WeakpointType.TURRET:
		var dir := Vector2.from_angle(rotation)
		# Dual heavy plasma cannon barrels firing BIG plasma orbs (scale_mult = 1.4, high damage)
		var perp := Vector2(-dir.y, dir.x)
		var spawn_pos := global_position + dir * 65.0
		enemy_bullet_pool.spawn(spawn_pos + perp * 16.0, dir, 520.0, 20, true, false, 1.4, "enemy_heavy")
		enemy_bullet_pool.spawn(spawn_pos - perp * 16.0, dir, 520.0, 20, true, false, 1.4, "enemy_heavy")
	else:
		# Wing missile/flak battery: fires a broad 3-projectile salvo forward to the left
		var forward_dir := Vector2.LEFT
		var spawn_pos := global_position + forward_dir * 30.0
		enemy_bullet_pool.spawn(spawn_pos, forward_dir, 460.0, 14, true, false, 1.1, "enemy_pellet")
		enemy_bullet_pool.spawn(spawn_pos + Vector2(0, -18), forward_dir.rotated(0.18), 440.0, 14, true, false, 1.1, "enemy_pellet")
		enemy_bullet_pool.spawn(spawn_pos + Vector2(0, 18), forward_dir.rotated(-0.18), 440.0, 14, true, false, 1.1, "enemy_pellet")

func take_damage(amount: int) -> void:
	if is_destroyed:
		return
		
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	_flash_hit()
	
	if current_health <= 0:
		_destroy()

func _flash_hit() -> void:
	_hit_flash_timer = 0.12
	if sprite:
		# Brilliant white/gold hit flash
		sprite.modulate = Color(3.5, 3.2, 2.5, 1.0)
		
	# Subtle mechanical recoil/impact shake
	var shake_offset := Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0))
	position = _original_pos + shake_offset
	var recoil_tween := create_tween()
	recoil_tween.tween_property(self, "position", _original_pos, 0.08)
	
	# Spawn impact spark burst at hit location
	_spawn_hit_sparks()

func _spawn_hit_sparks() -> void:
	var parent_scene := get_parent()
	if not parent_scene:
		return
		
	var spark_count := 4
	for i in range(spark_count):
		var spark := Line2D.new()
		spark.width = randf_range(2.0, 3.5)
		spark.default_color = Color(3.0, 2.4, 0.8, 1.0) # Intense incandescent spark
		var spark_dir := Vector2.from_angle(randf_range(0, TAU))
		var start_pt := global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		var end_pt := start_pt + spark_dir * randf_range(16.0, 32.0)
		spark.points = PackedVector2Array([start_pt, end_pt])
		spark.top_level = true
		parent_scene.add_child(spark)
		
		var spark_tween := create_tween()
		spark_tween.set_parallel(true)
		spark_tween.tween_property(spark, "points", PackedVector2Array([start_pt + spark_dir * 12.0, end_pt + spark_dir * 24.0]), 0.16)
		spark_tween.tween_property(spark, "modulate:a", 0.0, 0.16)
		spark_tween.chain().tween_callback(spark.queue_free)

func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if collision_poly:
		collision_poly.set_deferred("disabled", true)
		
	# Turn wrecked/dark
	if sprite:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(0.25, 0.25, 0.3, 0.7), 0.3)
		
	# Trigger Varth-style bullet cancel and Hit-Stop crunch
	EventBus.bullet_cancel_triggered.emit()
	EventBus.hit_stop_triggered.emit(35.0)
	
	# Spawn big destruction explosion
	var main_scene := get_tree().current_scene
	if main_scene:
		ExplosionEffect.create(main_scene, global_position, ExplosionEffect.ExplosionSize.BIG)
	
	# Drop burst of scrap
	for i in range(4):
		if _scrap_scene:
			var scrap := _scrap_scene.instantiate() as Node2D
			scrap.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			get_parent().get_parent().call_deferred("add_child", scrap)
			
	destroyed.emit()

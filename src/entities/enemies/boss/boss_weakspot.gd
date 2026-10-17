# res://src/entities/enemies/boss/boss_weakspot.gd
class_name BossWeakspot
extends Area2D

signal destroyed()

@export var max_health: int = 180
@export var current_health: int = 180
@export var shoot_interval: float = 1.6

var enemy_bullet_pool: ObjectPool = null
var is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _shoot_timer: float = 0.5
var _target_player: Node2D = null
var _scrap_scene: PackedScene = preload("res://src/entities/items/scrap_item.tscn")

func _ready() -> void:
	add_to_group("boss_weakspots")
	add_to_group("enemies")
	current_health = max_health
	
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target_player = players[0]

func _process(delta: float) -> void:
	if is_destroyed:
		return
		
	# Subtle tracking tilt toward player
	if _target_player and is_instance_valid(_target_player):
		var target_angle := (_target_player.global_position - global_position).angle()
		# Clamp turret rotation to face leftwards
		rotation = lerp_angle(rotation, clampf(target_angle, PI - 0.5, PI + 0.5), 4.0 * delta)
		
	# Shooting loop
	_shoot_timer += delta
	if _shoot_timer >= shoot_interval:
		_shoot_timer = 0.0
		_fire_turret()

func _fire_turret() -> void:
	if not enemy_bullet_pool:
		return
		
	var dir := Vector2.from_angle(rotation)
	var spawn_pos := global_position + dir * 25.0
	enemy_bullet_pool.spawn(spawn_pos + Vector2(0, -6), dir, 520.0, 12, true, false)
	enemy_bullet_pool.spawn(spawn_pos + Vector2(0, 6), dir, 520.0, 12, true, false)

func take_damage(amount: int) -> void:
	if is_destroyed:
		return
		
	current_health = maxi(current_health - amount, 0)
	_flash_hit()
	
	if current_health <= 0:
		_destroy()

func _flash_hit() -> void:
	if not sprite:
		return
	var tween := create_tween()
	sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	# Turn wrecked/dark
	if sprite:
		var t := create_tween()
		t.tween_property(sprite, "modulate", Color(0.25, 0.25, 0.3, 0.7), 0.3)
		
	# Trigger Varth-style bullet cancel and Hit-Stop crunch
	EventBus.bullet_cancel_triggered.emit()
	EventBus.hit_stop_triggered.emit(35.0)
	
	# Drop burst of scrap
	for i in range(4):
		if _scrap_scene:
			var scrap := _scrap_scene.instantiate() as Node2D
			scrap.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			get_parent().get_parent().call_deferred("add_child", scrap)
			
	destroyed.emit()

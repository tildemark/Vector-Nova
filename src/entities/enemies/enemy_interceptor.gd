# res://src/entities/enemies/enemy_interceptor.gd
class_name EnemyInterceptor
extends BaseEnemy

@export var shoot_interval: float = 2.2

var _shoot_timer: float = 0.5
var _target_player: Node2D = null

func _ready() -> void:
	max_health = 70
	scrap_reward = 35
	ram_damage = 40
	speed = 130.0
	super._ready()
	
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target_player = players[0]

func _process(delta: float) -> void:
	if _is_dead:
		return
		
	# Move steadily leftwards
	position.x -= speed * delta
	
	# Slight tracking drift towards player Y
	if _target_player and is_instance_valid(_target_player):
		position.y = move_toward(position.y, _target_player.position.y, 40.0 * delta)
	
	# Dual plasma cannon firing loop
	_shoot_timer += delta
	if _shoot_timer >= shoot_interval:
		_shoot_timer = 0.0
		_fire_dual_plasma()
		
	# Despawn when past left screen edge
	if global_position.x < -100.0:
		queue_free()

var _powerup_scene: PackedScene = preload("res://src/entities/items/powerup_item.tscn")

func _die() -> void:
	# 70% chance to drop powerup capsule
	if randf() <= 0.70 and _powerup_scene:
		var p_item := _powerup_scene.instantiate() as Node2D
		p_item.global_position = global_position
		get_parent().call_deferred("add_child", p_item)
	super._die()

func _fire_dual_plasma() -> void:
	if not enemy_bullet_pool:
		return
		
	var offset_top := Vector2(-30, -14)
	var offset_bot := Vector2(-30, 14)
	var dir := Vector2.LEFT
	
	# Aim slightly toward player if in range
	if _target_player and is_instance_valid(_target_player):
		dir = (Vector2(_target_player.global_position.x, _target_player.global_position.y) - global_position).normalized()
		# Keep firing generally to the left
		if dir.x > -0.3:
			dir = Vector2.LEFT
	
	enemy_bullet_pool.spawn(global_position + offset_top, dir, 520.0, 15, true)
	enemy_bullet_pool.spawn(global_position + offset_bot, dir, 520.0, 15, true)

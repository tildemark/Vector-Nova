# res://src/entities/enemies/enemy_heavy_elite.gd
class_name EnemyHeavyElite
extends BaseEnemy

@export var fire_interval: float = 1.4

var _fire_timer: float = 0.0
var _time_alive: float = 0.0
var _hover_base_y: float = 360.0
var _target_x: float = 980.0
var _attack_step: int = 0

func _ready() -> void:
	max_health = 480
	current_health = 480
	scrap_reward = 80
	ram_damage = 45
	super._ready()
	add_to_group("enemies")
	add_to_group("elites")
	_hover_base_y = global_position.y
	_fire_timer = 0.8

func _process(delta: float) -> void:
	_time_alive += delta
	
	# Entry move into position, then sine hover
	if global_position.x > _target_x:
		global_position.x -= 220.0 * delta
	else:
		global_position.y = _hover_base_y + sin(_time_alive * 2.2) * 110.0
		
	# Attack cycle
	_fire_timer -= delta
	if _fire_timer <= 0:
		_fire_timer = fire_interval
		_execute_attack()

func _execute_attack() -> void:
	if not enemy_bullet_pool:
		return
		
	var players := get_tree().get_nodes_in_group("player")
	var target_pos := global_position + Vector2.LEFT * 500.0
	if not players.is_empty() and is_instance_valid(players[0]):
		target_pos = players[0].global_position
		
	var aim_dir := (target_pos - global_position).normalized()
	
	if _attack_step % 2 == 0:
		# 3-way aimed fan shot with high-density plasma pellets
		enemy_bullet_pool.spawn(global_position, aim_dir, 460.0, 15, true, false, 1.1, "enemy_pellet")
		enemy_bullet_pool.spawn(global_position, aim_dir.rotated(deg_to_rad(18)), 460.0, 15, true, false, 1.1, "enemy_pellet")
		enemy_bullet_pool.spawn(global_position, aim_dir.rotated(deg_to_rad(-18)), 460.0, 15, true, false, 1.1, "enemy_pellet")
	else:
		# Radial 8-bullet ring of glowing orbs
		for i in range(8):
			var angle := (PI * 2.0 / 8.0) * i + (_time_alive * 1.5)
			var dir := Vector2.from_angle(angle)
			enemy_bullet_pool.spawn(global_position, dir, 380.0, 12, true, false, 1.0, "enemy_orb")
			
	_attack_step += 1

func take_damage(amount: int) -> void:
	current_health = maxi(current_health - amount, 0)
	_flash_hit()
	
	if current_health <= 0:
		_die_as_elite()

func _die_as_elite() -> void:
	defeated.emit(self)
	# Trigger Varth-style Bullet Canceling!
	EventBus.bullet_cancel_triggered.emit()
	
	# Trigger Hit-Stop crunch!
	EventBus.hit_stop_triggered.emit(40.0)
	
	# Spawn scrap & energy drops
	EventBus.enemy_destroyed.emit("heavy_elite", global_position, scrap_reward)
	_spawn_scrap_drops()
	
	queue_free()

func _spawn_scrap_drops() -> void:
	var scrap_scene: PackedScene = load("res://src/entities/items/scrap_item.tscn")
	var parent_node := get_parent()
	if not scrap_scene or not parent_node:
		return
		
	for i in range(5):
		var scrap := scrap_scene.instantiate() as Node2D
		scrap.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		parent_node.call_deferred("add_child", scrap)

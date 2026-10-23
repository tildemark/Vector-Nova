# res://src/pools/projectile.gd
class_name Projectile
extends Area2D

@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 1200.0
var damage: int = 10
var is_enemy_bullet: bool = false
var is_homing: bool = false
var turn_speed: float = 8.0

var _pool_ref: Node = null
var _time_alive: float = 0.0
var _homing_target: Node2D = null

const LASER_TEX = preload("res://assets/sprites/projectiles/laser.png")
const HELIX_TEX = preload("res://assets/sprites/projectiles/helix.png")
const MISSILE_TEX = preload("res://assets/sprites/projectiles/micro_missile.png")
const PLASMA_TEX = preload("res://assets/sprites/projectiles/plasma_cannon.png")
const QUAD_FLAK_TEX = preload("res://assets/sprites/projectiles/quad_flak.png")
const ENEMY_BULLET_ORB_TEX = preload("res://assets/sprites/projectiles/enemy_bullet_orb.png")
const ENEMY_BULLET_LANCE_TEX = preload("res://assets/sprites/projectiles/enemy_bullet_lance.png")
const ENEMY_BULLET_PELLET_TEX = preload("res://assets/sprites/projectiles/enemy_bullet_pellet.png")
const ENEMY_BULLET_HEAVY_TEX = preload("res://assets/sprites/projectiles/enemy_bullet_heavy.png")

@onready var sprite: Sprite2D = $Sprite2D

var projectile_type: String = "laser"
var _base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if sprite:
		_base_scale = sprite.scale

func initialize(p_direction: Vector2, p_speed: float, p_damage: int, p_pool: Node, p_is_enemy: bool = false, p_is_homing: bool = false, scale_mult: float = 1.0, p_type: String = "") -> void:
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	_pool_ref = p_pool
	is_enemy_bullet = p_is_enemy
	is_homing = p_is_homing
	_homing_target = null
	_time_alive = 0.0
	rotation = direction.angle()
	scale = Vector2(scale_mult, scale_mult)
	
	if p_type.is_empty():
		projectile_type = "enemy_orb" if is_enemy_bullet else ("missile" if is_homing else "laser")
	else:
		projectile_type = p_type
		
	_apply_visuals()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

func _apply_visuals() -> void:
	if not sprite:
		return
	match projectile_type:
		"laser":
			sprite.texture = LASER_TEX
			sprite.scale = Vector2(0.16, 0.16)
			sprite.modulate = Color.WHITE
		"helix":
			sprite.texture = HELIX_TEX
			sprite.scale = Vector2(0.15, 0.15)
			sprite.modulate = Color(0.8, 1.3, 1.1, 1.0)
		"missile":
			sprite.texture = MISSILE_TEX
			sprite.scale = Vector2(0.18, 0.18)
			sprite.modulate = Color.WHITE
		"plasma":
			sprite.texture = PLASMA_TEX
			sprite.scale = Vector2(0.14, 0.14)
			sprite.modulate = Color(1.2, 1.0, 1.2, 1.0)
		"quad_flak":
			sprite.texture = QUAD_FLAK_TEX
			sprite.scale = Vector2(0.15, 0.15)
			sprite.modulate = Color(1.2, 1.1, 0.8, 1.0)
		"enemy_orb":
			sprite.texture = ENEMY_BULLET_ORB_TEX
			sprite.scale = Vector2(0.18, 0.18)
			sprite.modulate = Color(1.3, 1.1, 1.1, 1.0)
		"enemy_lance":
			sprite.texture = ENEMY_BULLET_LANCE_TEX
			sprite.scale = Vector2(0.20, 0.16)
			sprite.modulate = Color(1.4, 1.1, 1.0, 1.0)
		"enemy_pellet":
			sprite.texture = ENEMY_BULLET_PELLET_TEX
			sprite.scale = Vector2(0.18, 0.18)
			sprite.modulate = Color(1.3, 1.0, 1.0, 1.0)
		"enemy_heavy":
			sprite.texture = ENEMY_BULLET_HEAVY_TEX
			sprite.scale = Vector2(0.22, 0.22)
			sprite.modulate = Color(1.5, 1.2, 1.0, 1.0)
		_:
			if is_enemy_bullet:
				sprite.texture = ENEMY_BULLET_ORB_TEX
				sprite.scale = Vector2(0.18, 0.18)
				sprite.modulate = Color(1.3, 1.1, 1.1, 1.0)
			else:
				sprite.texture = LASER_TEX
				sprite.scale = Vector2(0.16, 0.16)
				sprite.modulate = Color.WHITE

func _process(delta: float) -> void:
	# Optional homing tracking toward nearest enemy in front
	if is_homing and not is_enemy_bullet:
		if _homing_target == null or not is_instance_valid(_homing_target):
			_find_nearest_enemy()
		elif is_instance_valid(_homing_target):
			var target_angle := (_homing_target.global_position - global_position).angle()
			rotation = lerp_angle(rotation, target_angle, turn_speed * delta)
			direction = Vector2.from_angle(rotation)

	global_position += direction * speed * delta
	_time_alive += delta
	
	# Recycle when off-screen or lifetime exceeded
	var viewport_rect := get_viewport_rect()
	var margin := 80.0
	if _time_alive >= lifetime or \
	   global_position.x < -margin or global_position.x > viewport_rect.size.x + margin or \
	   global_position.y < -margin or global_position.y > viewport_rect.size.y + margin:
		recycle()

func _on_area_entered(other: Area2D) -> void:
	if is_enemy_bullet:
		if other.is_in_group("player") and other.has_method("take_damage"):
			other.take_damage(damage)
			recycle()
	else:
		if (other.is_in_group("enemies") or other.is_in_group("boss_weakspots")) and other.has_method("take_damage"):
			other.take_damage(damage)
			recycle()

func recycle() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	_homing_target = null
	if _pool_ref and _pool_ref.has_method("recycle"):
		_pool_ref.recycle(self)
	else:
		hide()
		set_process(false)

func _find_nearest_enemy() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest_dist: float = 800.0
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var node := enemy as Node2D
			var diff: Vector2 = node.global_position - global_position
			if diff.x > -50.0:
				var dist: float = diff.length()
				if dist < closest_dist:
					closest_dist = dist
					_homing_target = node

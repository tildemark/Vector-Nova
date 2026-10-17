# res://src/effects/grav_vortex.gd
class_name GravVortex
extends Area2D

@export var duration: float = 2.8
@export var travel_speed: float = 380.0
@export var vortex_radius: float = 160.0
@export var tick_damage: int = 42

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _time_alive: float = 0.0
var _tick_timer: float = 0.0
var _rotation_angle: float = 0.0

func _ready() -> void:
	add_to_group("player_weapons")
	monitoring = true
	
	scale = Vector2(0.1, 0.1)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_time_alive += delta
	_tick_timer += delta
	_rotation_angle += delta * 6.0
	
	# Drift forward
	global_position.x += travel_speed * delta
	
	# Gravitational attraction loop
	_pull_nearby_entities(delta)
	
	# Damage ticks
	if _tick_timer >= 0.15:
		_tick_timer = 0.0
		_deal_vortex_damage()
		
	queue_redraw()
	
	# Implosion sequence
	if _time_alive >= duration - 0.3:
		scale = scale.move_toward(Vector2.ZERO, 3.5 * delta)
		
	if _time_alive >= duration:
		_implode()

func _pull_nearby_entities(delta: float) -> void:
	var main := get_parent()
	if not main:
		return
		
	# 1. Swallow and delete enemy bullets
	if main.has_node("EnemyBulletPool"):
		var bullet_pool = main.get_node("EnemyBulletPool")
		for bullet in bullet_pool.get_children():
			if bullet.visible and bullet.global_position.distance_to(global_position) <= vortex_radius:
				if bullet.has_method("recycle"):
					bullet.recycle()
					
	# 2. Gravitational pull on enemies
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node2D and is_instance_valid(enemy):
			var dist: float = global_position.distance_to(enemy.global_position)
			if dist <= vortex_radius:
				var pull_dir: Vector2 = (global_position - (enemy as Node2D).global_position).normalized()
				enemy.global_position += pull_dir * 180.0 * delta

func _deal_vortex_damage() -> void:
	var overlapping := get_overlapping_areas()
	for area in overlapping:
		if (area.is_in_group("enemies") or area.is_in_group("boss_weakspots")) and area.has_method("take_damage"):
			area.take_damage(tick_damage)

func _implode() -> void:
	var main := get_parent()
	if main and main.has_method("shake_camera"):
		main.shake_camera(8.0, 0.25)
	queue_free()

func _draw() -> void:
	# Draw swirling accretion disk rings
	for i in range(4):
		var r := vortex_radius * (0.25 * (i + 1))
		var col := Color(0.6, 0.2, 1.0, 0.35 - (i * 0.07))
		draw_arc(Vector2.ZERO, r, _rotation_angle + (i * 1.2), _rotation_angle + (i * 1.2) + PI * 1.5, 32, col, 3.0)
	# Center singularity event horizon
	draw_circle(Vector2.ZERO, 22.0, Color(0.04, 0.01, 0.1, 0.95))
	draw_circle(Vector2.ZERO, 10.0, Color(0.2, 0.8, 1.0, 0.9))

# res://src/effects/pulse_mortar.gd
class_name PulseMortar
extends Area2D

@export var flight_speed: float = 680.0
@export var max_flight_dist: float = 520.0
@export var blast_damage: int = 280
@export var blast_radius: float = 140.0

@onready var visual_shell: Node2D = $VisualShell
@onready var blast_area: Area2D = $BlastArea
@onready var blast_shape: CollisionShape2D = $BlastArea/CollisionShape2D

var _start_x: float = 0.0
var _is_detonated: bool = false

func _ready() -> void:
	add_to_group("player_weapons")
	_start_x = global_position.x
	area_entered.connect(_on_impact)

func _process(delta: float) -> void:
	if _is_detonated:
		return
		
	global_position.x += flight_speed * delta
	
	# Detonate if traveled max distance or screen boundary
	if absf(global_position.x - _start_x) >= max_flight_dist or global_position.x > 1200.0:
		detonate()

func _on_impact(other: Area2D) -> void:
	if _is_detonated:
		return
	if other.is_in_group("enemies") or other.is_in_group("boss_weakspots"):
		detonate()

func detonate() -> void:
	_is_detonated = true
	set_process(false)
	
	if visual_shell:
		visual_shell.hide()
		
	# Screen shake punch
	var main := get_parent()
	if main and main.has_method("shake_camera"):
		main.shake_camera(14.0, 0.35)
		
	# Clear active enemy bullets inside blast radius
	if main and main.has_node("EnemyBulletPool"):
		var bullet_pool = main.get_node("EnemyBulletPool")
		for child in bullet_pool.get_children():
			if child.visible and child.global_position.distance_to(global_position) <= blast_radius:
				if child.has_method("recycle"):
					child.recycle()
					
	# Damage all enemies in blast area
	if blast_area:
		blast_area.monitoring = true
		await get_tree().process_frame
		var overlapping := blast_area.get_overlapping_areas()
		for area in overlapping:
			if (area.is_in_group("enemies") or area.is_in_group("boss_weakspots")) and area.has_method("take_damage"):
				area.take_damage(blast_damage)
				
	# Animate expanding plasma sphere explosion
	var blast_fx := Node2D.new()
	add_child(blast_fx)
	blast_fx.draw.connect(func():
		blast_fx.draw_circle(Vector2.ZERO, blast_radius, Color(1.0, 0.6, 0.1, 0.35))
		blast_fx.draw_circle(Vector2.ZERO, blast_radius * 0.7, Color(1.0, 0.85, 0.2, 0.7))
		blast_fx.draw_circle(Vector2.ZERO, blast_radius * 0.3, Color(1.0, 1.0, 1.0, 0.95))
	)
	blast_fx.scale = Vector2(0.2, 0.2)
	
	var tween := create_tween()
	tween.tween_property(blast_fx, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(blast_fx, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)

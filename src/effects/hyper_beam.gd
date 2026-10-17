# res://src/effects/hyper_beam.gd
class_name HyperBeam
extends Area2D

@export var beam_duration: float = 2.0
@export var tick_interval: float = 0.12
@export var damage_per_tick: int = 32
@export var beam_length: float = 1200.0

@onready var line_2d: Line2D = $Line2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _time_alive: float = 0.0
var _tick_timer: float = 0.0
var _parent_ship: Node2D = null

func _ready() -> void:
	add_to_group("player_weapons")
	monitoring = true
	monitorable = false
	
	if line_2d:
		line_2d.points = PackedVector2Array([Vector2.ZERO, Vector2(beam_length, 0)])
	
	# Initial entrance flare
	scale.y = 0.2
	var tween := create_tween()
	tween.tween_property(self, "scale:y", 1.0, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup(parent: Node2D) -> void:
	_parent_ship = parent
	if _parent_ship:
		global_position = _parent_ship.global_position + Vector2(30, 0)

func _process(delta: float) -> void:
	_time_alive += delta
	_tick_timer += delta
	
	# Follow player position smoothly
	if _parent_ship and is_instance_valid(_parent_ship):
		global_position = _parent_ship.global_position + Vector2(32, 0)
	
	# Beam intensity jitter
	if line_2d:
		line_2d.width = 18.0 + randf_range(-3.0, 3.0)
		
	# Damage tick loop
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_apply_beam_damage()
		
	# Fade out at end of duration
	if _time_alive >= beam_duration - 0.25:
		scale.y = lerpf(scale.y, 0.0, 12.0 * delta)
		
	if _time_alive >= beam_duration:
		queue_free()

func _apply_beam_damage() -> void:
	var overlapping := get_overlapping_areas()
	for area in overlapping:
		if (area.is_in_group("enemies") or area.is_in_group("boss_weakspots")) and area.has_method("take_damage"):
			area.take_damage(damage_per_tick)
			_spawn_hit_spark(area.global_position)

func _spawn_hit_spark(pos: Vector2) -> void:
	# Quick flash on hit
	var main := get_parent()
	if main and main.has_method("shake_camera"):
		main.shake_camera(2.0, 0.08)

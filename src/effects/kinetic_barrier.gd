# res://src/effects/kinetic_barrier.gd
class_name KineticBarrier
extends Area2D

@export var duration: float = 4.0
@export var ram_damage: int = 140

@onready var shield_arc: Line2D = $ShieldArc
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _time_alive: float = 0.0
var _parent_ship: Node2D = null
var _pulse_phase: float = 0.0

func _ready() -> void:
	add_to_group("player_weapons")
	area_entered.connect(_on_area_entered)
	
	# Entrance scale up
	scale = Vector2(0.1, 0.1)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup(parent: Node2D) -> void:
	_parent_ship = parent
	if _parent_ship:
		global_position = _parent_ship.global_position

func _process(delta: float) -> void:
	_time_alive += delta
	_pulse_phase += delta * 8.0
	
	# Stick to parent ship position
	if _parent_ship and is_instance_valid(_parent_ship):
		global_position = _parent_ship.global_position
	
	# Pulsing barrier effect
	if shield_arc:
		shield_arc.width = 12.0 + sin(_pulse_phase) * 2.5
		
	# Check expiration
	if _time_alive >= duration - 0.4:
		modulate.a = lerpf(modulate.a, 0.0, 8.0 * delta)
		
	if _time_alive >= duration:
		queue_free()

func _on_area_entered(other: Area2D) -> void:
	# 1. Deflect/absorb enemy projectiles
	if other.has_method("recycle") and other.get("is_enemy_bullet") == true:
		other.recycle()
		_spawn_deflect_spark(other.global_position)
		
	# 2. Ram damage to enemy hulls
	elif (other.is_in_group("enemies") or other.is_in_group("boss_weakspots")) and other.has_method("take_damage"):
		other.take_damage(ram_damage)
		_spawn_deflect_spark(other.global_position)

func _spawn_deflect_spark(pos: Vector2) -> void:
	var main := get_parent()
	if main and main.has_method("shake_camera"):
		main.shake_camera(3.0, 0.1)

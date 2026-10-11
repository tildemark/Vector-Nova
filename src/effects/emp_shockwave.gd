# res://src/effects/emp_shockwave.gd
class_name EmpShockwave
extends Node2D

var _radius: float = 10.0
var _max_radius: float = 1400.0
var _alpha: float = 1.0

func _ready() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "_radius", _max_radius, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_alpha", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if _alpha <= 0.01:
		return
	var main_color := Color(0.0, 0.9, 1.0, _alpha * 0.9)
	var glow_color := Color(0.4, 1.0, 1.0, _alpha * 0.4)
	var core_color := Color(1.0, 1.0, 1.0, _alpha * 0.95)
	
	# Expanding shockwave rings
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, glow_color, 24.0)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, main_color, 8.0)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, core_color, 3.0)
